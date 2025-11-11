# Async, Concurrency & Performance

> **TL;DR for experienced systems programmers:**
> - **Breaking change:** Language-level async/await removed in 0.15 → use library-based solutions
> - **CPU parallelism:** `std.Thread` for OS threads, `std.Thread.Pool` for work distribution
> - **I/O concurrency:** Use library event loops (libxev, zap) with io_uring/kqueue/IOCP
> - **Synchronization:** `std.Thread.Mutex`, `RwLock`, `Condition`, atomic operations
> - **Memory ordering:** `.seq_cst` (default), `.acquire`, `.release`, `.monotonic`
> - **Jump to:** [Threading §6.2](#stdthread-explicit-thread-management) | [Atomics §6.3](#atomic-operations) | [Thread pools §6.4](#thread-pools)

This chapter examines Zig's concurrency model, synchronization primitives, and performance measurement tools. Modern systems programming demands efficient handling of both CPU-bound parallelism and I/O-bound concurrency. Zig provides explicit, zero-cost abstractions for both through threading primitives and library-based event loops.

---

## Overview

Zig's approach to concurrency emphasizes explicitness and control. Unlike languages with hidden runtime schedulers or implicit async semantics, Zig makes concurrency visible and manageable at the source level.

### Concurrency Mechanisms

Zig provides explicit, low-level control over parallelism (CPU-bound) and concurrency (I/O-bound):

1. **std.Thread** — OS-level threading with explicit lifecycle management
2. **Atomic operations** — Configurable memory ordering for lock-free algorithms
3. **Synchronization primitives** — Mutex, RwLock, Condition (platform-optimal)
4. **Thread pools** — CPU-bound work distribution
5. **Library-based event loops** — libxev for I/O concurrency (io_uring, kqueue, IOCP)

### The Async Transition (0.14.x → 0.15.0)

**Breaking change:** Language-level `async`/`await` keywords removed in 0.15, replaced with library-based solutions (libxev, zap).[^1]

**Removed:** `async`, `await`, `suspend`, `resume` keywords, compiler-managed async frames
**Added:** Enhanced thread pool support, library event loop integration

**Rationale:** Reduced 15K lines of compiler complexity, enabled platform-specific optimizations (io_uring, kqueue, IOCP), aligned with "explicit over implicit" philosophy.[^2]

This chapter focuses on Zig 0.15+ library-based patterns.

---

## Core Concepts

### std.Thread: Explicit Thread Management

Zig provides direct access to OS threads through `std.Thread`. Every thread must be explicitly spawned, joined, or detached—there is no automatic cleanup.

#### Thread Lifecycle

**API Overview:**

```zig
pub const Thread = struct {
    /// Spawn a new thread
    pub fn spawn(config: SpawnConfig, comptime f: anytype, args: anytype) SpawnError!Thread

    /// Wait for thread completion and return result
    pub fn join(self: Thread) ReturnType

    /// Detach thread (runs independently)
    pub fn detach(self: Thread) void

    /// Yield CPU to other threads
    pub fn yield() void

    /// Sleep for specified nanoseconds
    pub fn sleep(nanoseconds: u64) void

    /// Get current thread ID
    pub fn getCurrentId() Id
};
```

**Configuration Options:**

```zig
pub const SpawnConfig = struct {
    stack_size: usize = default_stack_size,
    allocator: ?std.mem.Allocator = null,
};
```

Default stack sizes are platform-specific:
- Linux/Windows: 16 MiB
- macOS: Must be page-aligned (typically 4 MiB)
- WASM: Configurable (typically 1 MiB)

**Basic Usage:**

```zig
const std = @import("std");

fn workerThread(id: u32, iterations: u32) void {
    std.debug.print("Worker {d} starting\n", .{id});

    var sum: u64 = 0;
    for (0..iterations) |i| {
        sum += i;
    }

    std.debug.print("Worker {d} sum: {d}\n", .{id, sum});
}

pub fn main() !void {
    // Spawn thread with arguments
    const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });

    // Wait for completion (required!)
    thread.join();
}
```

**Multiple Threads:**

```zig
var threads: [4]std.Thread = undefined;

// Spawn workers
for (&threads, 0..) |*thread, i| {
    thread.* = try std.Thread.spawn(.{}, workerThread, .{
        @as(u32, @intCast(i)), 500
    });
}

// Join all
for (threads) |thread| {
    thread.join();
}
```

#### Passing Data to Threads

Threads can accept multiple arguments through tuples:

```zig
const WorkerData = struct {
    id: u32,
    message: []const u8,
    result: *u32,  // Shared state (needs synchronization)

    fn run(self: WorkerData) void {
        std.debug.print("{s}\n", .{self.message});
        self.result.* = self.id * 10;
    }
};

pub fn example() !void {
    var result: u32 = 0;
    const data = WorkerData{
        .id = 42,
        .message = "Processing...",
        .result = &result,
    };

    const thread = try std.Thread.spawn(.{}, WorkerData.run, .{data});
    thread.join();

    std.debug.print("Result: {d}\n", .{result});
}
```

#### Thread Information

```zig
// Get current thread ID
const thread_id = std.Thread.getCurrentId();

// Get available CPU cores
const cpu_count = try std.Thread.getCpuCount();
std.debug.print("CPU cores: {d}\n", .{cpu_count});
```

Full implementation available at: [lib/std/Thread.zig](https://github.com/ziglang/zig/blob/master/lib/std/Thread.zig)

### Synchronization Primitives

When multiple threads access shared data, synchronization prevents race conditions and ensures memory visibility.

#### std.Thread.Mutex

A mutual exclusion lock that allows only one thread to access protected data at a time.

**Platform-Optimized Implementation:**

Zig's Mutex automatically selects the best implementation for your platform:[^3]

```zig
const Impl = if (builtin.mode == .Debug and !builtin.single_threaded)
    DebugImpl      // Detects deadlocks
else if (builtin.single_threaded)
    SingleThreadedImpl  // No-op
else if (builtin.os.tag == .windows)
    WindowsImpl    // SRWLOCK
else if (builtin.os.tag.isDarwin())
    DarwinImpl     // os_unfair_lock (priority inheritance)
else
    FutexImpl;     // Linux futex
```

**Debug Mode Deadlock Detection:**

In debug builds, Mutex automatically detects self-deadlock:

```zig
const DebugImpl = struct {
    locking_thread: std.atomic.Value(Thread.Id),
    impl: ReleaseImpl,

    fn lock(self: *@This()) void {
        const current_id = Thread.getCurrentId();
        if (self.locking_thread.load(.unordered) == current_id) {
            @panic("Deadlock detected");  // Same thread trying to lock twice
        }
        self.impl.lock();
        self.locking_thread.store(current_id, .unordered);
    }
};
```

**API:**

```zig
pub fn lock(self: *Mutex) void       // Block until acquired
pub fn tryLock(self: *Mutex) bool    // Non-blocking attempt
pub fn unlock(self: *Mutex) void     // Release lock
```

**Usage Pattern with RAII:**

```zig
const SharedCounter = struct {
    mutex: std.Thread.Mutex = .{},
    value: u32 = 0,

    fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();  // Always unlocks, even on early return

        self.value += 1;
    }

    fn getValue(self: *SharedCounter) u32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.value;
    }
};
```

**Production Example from TigerBeetle:**

TigerBeetle uses Mutex to protect client API calls across thread boundaries:[^4]

```zig
// src/clients/c/tb_client/context.zig:62-83
pub fn submit(client: *ClientInterface, packet: *Packet.Extern) Error!void {
    client.locker.lock();
    defer client.locker.unlock();

    const context = client.context.ptr orelse return Error.ClientInvalid;
    client.vtable.ptr.submit_fn(context, packet);
}
```

Source: [TigerBeetle context.zig:62-126](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)

#### std.Thread.RwLock

A reader-writer lock optimized for read-heavy workloads. Multiple readers can hold the lock simultaneously, but writers require exclusive access.

**Semantics:**
- Multiple concurrent readers OR
- Single exclusive writer
- Writers block all readers and other writers
- Readers block only on writers

**API:**

```zig
// Writer operations
pub fn lock(rwl: *RwLock) void          // Exclusive access
pub fn tryLock(rwl: *RwLock) bool
pub fn unlock(rwl: *RwLock) void

// Reader operations
pub fn lockShared(rwl: *RwLock) void    // Shared access
pub fn tryLockShared(rwl: *RwLock) bool
pub fn unlockShared(rwl: *RwLock) void
```

**Usage Pattern:**

```zig
const Document = struct {
    lock: std.Thread.RwLock = .{},
    content: []const u8,
    version: u32 = 0,

    // Many readers can access simultaneously
    fn read(self: *Document) []const u8 {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.content;
    }

    // Writers require exclusive access
    fn update(self: *Document, new_content: []const u8) !void {
        self.lock.lock();
        defer self.lock.unlock();

        // Safe to modify: no readers or writers
        self.content = new_content;
        self.version += 1;
    }
};
```

**Production Example from ZLS:**

ZLS uses RwLock to protect its document store, allowing many concurrent autocompletion requests while serializing file changes:[^5]

```zig
// src/DocumentStore.zig:23
const DocumentStore = struct {
    lock: std.Thread.RwLock = .{},
    handles: Uri.ArrayHashMap(*Handle),

    pub fn getHandle(self: *DocumentStore, uri: Uri) ?*Handle {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.handles.get(uri);
    }

    pub fn createHandle(self: *DocumentStore, uri: Uri) !*Handle {
        self.lock.lock();
        defer self.lock.unlock();
        const handle = try self.allocator.create(Handle);
        try self.handles.put(uri, handle);
        return handle;
    }
};
```

Source: [ZLS DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)

**When to Use RwLock vs Mutex:**

| Use Case | Primitive | Reason |
|----------|-----------|--------|
| High read contention, rare writes | RwLock | Allows concurrent reads |
| Frequent writes | Mutex | Simpler, less overhead |
| Short critical sections | Mutex | RwLock overhead not justified |
| Simple counters/flags | Atomic | Lock-free |

#### std.Thread.Condition

Condition variables enable threads to wait for specific conditions without busy-waiting.

**API:**

```zig
pub const Condition = struct {
    pub fn wait(cond: *Condition, mutex: *Mutex) void
    pub fn signal(cond: *Condition) void      // Wake one waiter
    pub fn broadcast(cond: *Condition) void   // Wake all waiters
};
```

**Producer-Consumer Pattern:**

```zig
var mutex = std.Thread.Mutex{};
var condition = std.Thread.Condition{};
var queue = std.ArrayList(T).init(allocator);

fn producer() void {
    while (true) {
        const item = produceItem();

        mutex.lock();
        defer mutex.unlock();

        queue.append(item) catch unreachable;
        condition.signal();  // Wake one consumer
    }
}

fn consumer() void {
    while (true) {
        mutex.lock();
        defer mutex.unlock();

        // Wait while queue is empty
        while (queue.items.len == 0) {
            condition.wait(&mutex);  // Atomically unlock and sleep
        }

        const item = queue.orderedRemove(0);
        mutex.unlock();  // Release lock during processing

        processItem(item);
    }
}
```

**Critical Detail**: `condition.wait()` atomically unlocks the mutex and puts the thread to sleep. This prevents the race condition where a signal could be lost between checking the condition and sleeping.

### Atomic Operations and Memory Ordering

Atomic operations enable lock-free algorithms by ensuring operations complete without interruption, even across CPU cores.

#### std.atomic.Value

Generic atomic wrapper for thread-safe operations:

```zig
pub fn Value(comptime T: type) type {
    return struct {
        pub fn init(value: T) @This()
        pub fn load(self: *const @This(), ordering: Ordering) T
        pub fn store(self: *@This(), value: T, ordering: Ordering) void
        pub fn swap(self: *@This(), value: T, ordering: Ordering) T
        pub fn cmpxchg(self: *@This(), expected: T, new: T,
                       success: Ordering, failure: Ordering) ?T
        pub fn fetchAdd(self: *@This(), operand: T, ordering: Ordering) T
        pub fn fetchSub(self: *@This(), operand: T, ordering: Ordering) T
    };
}
```

**Supported Types:**
- All integer types (u8, i32, u64, etc.)
- Pointers
- Booleans
- Enums backed by integers
- Small structs (≤16 bytes on most platforms)

**Lock-Free Counter:**

```zig
const AtomicCounter = struct {
    value: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }

    fn getValue(self: *const AtomicCounter) u32 {
        return self.value.load(.monotonic);
    }
};
```

#### Memory Ordering Explained

Memory ordering controls visibility of memory operations across threads. Zig exposes these explicitly through the `Ordering` enum:[^6]

**Available Orderings (weakest to strongest):**

1. **`.unordered`** — No synchronization guarantees
   - Use when external synchronization exists
   - Example: Debug-only counters inside locked regions

2. **`.monotonic`** — Atomic operation only, no cross-thread synchronization
   - Use for simple counters where order does not matter
   - Example: Reference counting without dependencies

3. **`.acquire`** — Synchronize with release operations
   - Use when reading data published by another thread
   - Ensures all writes before the release are visible
   - Example: Consumer reading from queue

4. **`.release`** — Publish changes to acquire operations
   - Use when publishing data to other threads
   - Ensures all writes complete before the release is visible
   - Example: Producer publishing to queue

5. **`.acq_rel`** — Both acquire and release
   - Use for read-modify-write operations (swap, fetchAdd with dependencies)
   - Example: Atomic increment that establishes happens-before relationships

6. **`.seq_cst`** — Sequentially consistent (strongest, slowest)
   - Use when total ordering across all threads is required
   - Rarely needed; acquire/release usually suffices
   - Example: Rare; use only when debugging ordering issues

**Visual Guide: Producer/Consumer Synchronization:**

```zig
var data: u32 = undefined;
var ready = std.atomic.Value(bool).init(false);

// Producer thread
fn producer() void {
    data = 42;                      // (1) Normal store
    ready.store(true, .release);    // (2) Release: makes (1) visible
}

// Consumer thread
fn consumer() void {
    while (!ready.load(.acquire)) {}  // (3) Acquire: synchronizes with (2)
    const value = data;                // (4) Guaranteed to see 42
}
```

The acquire-release pair creates a **happens-before** relationship:
- Producer's write to `data` happens-before the release
- Release happens-before the acquire
- Acquire happens-before consumer's read of `data`
- Therefore: consumer sees `data == 42`

**Common Pattern: Compare-and-Swap (CAS):**

```zig
var value = std.atomic.Value(u32).init(100);

// Try to change 100 → 200
const result = value.cmpxchgStrong(100, 200, .seq_cst, .seq_cst);
if (result == null) {
    // Success: value was 100, now 200
} else {
    // Failure: value was not 100, result contains actual value
    std.debug.print("CAS failed, actual: {d}\n", .{result.?});
}
```

**Production Example from Bun:**

Bun's thread pool uses atomic CAS with acquire/release ordering to manage worker state:[^7]

```zig
// src/threading/ThreadPool.zig:374-379
sync = @bitCast(self.sync.cmpxchgWeak(
    @as(u32, @bitCast(sync)),
    @as(u32, @bitCast(new_sync)),
    .release,    // Success: publish state change
    .monotonic,  // Failure: just reload
) orelse { ... });
```

Source: [Bun ThreadPool.zig:374-379](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L374-L379)

**Production Example from TigerBeetle:**

TigerBeetle uses atomic state machines for cross-thread signaling:[^8]

```zig
// src/clients/c/tb_client/signal.zig:87-107
pub fn notify(self: *Signal) void {
    var state: @TypeOf(self.event_state.raw) = .waiting;
    while (self.event_state.cmpxchgStrong(
        state,
        .notified,
        .release,  // Publish notification
        .acquire,  // Reload current state
    )) |state_actual| {
        switch (state_actual) {
            .waiting, .running => state = state_actual,
            .notified => return,  // Already notified
            .shutdown => return,  // Ignore after shutdown
        }
    }

    if (state == .waiting) {
        self.io.event_trigger(self.event, &self.completion);
    }
}
```

Source: [TigerBeetle signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)

**Best Practices:**

99% of cases use:
- **`.monotonic`** for simple counters
- **`.acquire/.release`** for publishing/consuming data
- **`.seq_cst`** only when debugging or strict ordering required

Atomic operations compile to direct CPU instructions (LOCK XADD on x86, LDXR/STXR on ARM), making them extremely efficient.

### Thread Pools for CPU-Bound Parallelism

Thread pools amortize thread creation costs and limit concurrency to available CPU cores.

#### std.Thread.Pool (Standard Library)

Basic thread pool for parallel task execution:

```zig
pub const Pool = struct {
    pub fn init(options: InitOptions) Allocator.Error!Pool
    pub fn deinit(self: *Pool) void
    pub fn spawnWg(self: *Pool, wait_group: *WaitGroup,
                   comptime func: anytype, args: anytype) void
    pub fn waitAndWork(self: *Pool, wait_group: *WaitGroup) void
};

pub const InitOptions = struct {
    allocator: Allocator,
    n_jobs: ?u32 = null,  // Defaults to CPU count
};
```

**Basic Usage:**

```zig
var pool: std.Thread.Pool = undefined;
try pool.init(.{ .allocator = allocator });
defer pool.deinit();

var wait_group: std.Thread.WaitGroup = .{};

// Task function
fn processTask(task_id: usize) void {
    std.debug.print("Processing task {d}\n", .{task_id});
    // ... do work
}

// Spawn tasks
for (0..10) |i| {
    pool.spawnWg(&wait_group, processTask, .{i});
}

// Wait for all tasks to complete
pool.waitAndWork(&wait_group);
```

**With Shared State:**

```zig
var counter = std.atomic.Value(u32).init(0);

fn increment(c: *std.atomic.Value(u32), iterations: u32) void {
    for (0..iterations) |_| {
        _ = c.fetchAdd(1, .monotonic);
    }
}

// Spawn workers
for (0..num_workers) |_| {
    pool.spawnWg(&wait_group, increment, .{ &counter, 1000 });
}

pool.waitAndWork(&wait_group);

std.debug.print("Final count: {d}\n", .{counter.load(.monotonic)});
```

Full implementation: [lib/std/Thread/Pool.zig](https://github.com/ziglang/zig/blob/master/lib/std/Thread/Pool.zig)

#### Production Thread Pool: Bun's Work-Stealing Design

Bun implements a sophisticated work-stealing thread pool derived from kprotty's design:[^9]

**Architecture Overview:**

```zig
// src/threading/ThreadPool.zig:1-82
const ThreadPool = @This();

// Configuration
sleep_on_idle_network_thread: bool = true,
stack_size: u32,
max_threads: u32,

// State (packed atomic for cache efficiency)
sync: Atomic(u32) = .init(@as(u32, @bitCast(Sync{}))),

// Synchronization
idle_event: Event = .{},
join_event: Event = .{},

// Work queues
run_queue: Node.Queue = .{},         // Global MPMC queue
threads: Atomic(?*Thread) = .init(null),  // Thread stack

const Sync = packed struct {
    idle: u14 = 0,        // Idle threads
    spawned: u14 = 0,     // Total threads
    unused: bool = false,
    notified: bool = false,
    state: enum(u2) {
        pending = 0,
        signaled,
        waking,
        shutdown,
    } = .pending,
};
```

**Work-Stealing Algorithm:**

Each thread follows this priority order:[^10]

1. Check local buffer (fastest, lock-free)
2. Check local queue (SPMC)
3. Check global queue (MPMC)
4. Steal from other thread queues (work balancing)

```zig
// src/threading/ThreadPool.zig:600-644
pub fn pop(self: *Thread, thread_pool: *ThreadPool) ?Node.Buffer.Stole {
    // 1. Local buffer (L1 cache)
    if (self.run_buffer.pop()) |node| {
        return .{ .node = node, .pushed = false };
    }

    // 2. Local queue
    if (self.run_buffer.consume(&self.run_queue)) |stole| {
        return stole;
    }

    // 3. Global queue
    if (self.run_buffer.consume(&thread_pool.run_queue)) |stole| {
        return stole;
    }

    // 4. Work stealing from other threads
    var num_threads = @as(Sync, @bitCast(thread_pool.sync.load(.monotonic))).spawned;
    while (num_threads > 0) : (num_threads -= 1) {
        const target = self.target orelse thread_pool.threads.load(.acquire) orelse break;
        self.target = target.next;

        if (self.run_buffer.consume(&target.run_queue)) |stole| {
            return stole;
        }

        if (target == self) continue;

        if (self.run_buffer.steal(&target.run_buffer)) |stole| {
            return stole;
        }
    }

    return null;
}
```

Source: [Bun ThreadPool.zig:600-644](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644)

**Parallel Iteration Helper:**

Bun provides a high-level API for parallel data processing:[^11]

```zig
// src/threading/ThreadPool.zig:156-229
pub fn each(
    this: *ThreadPool,
    allocator: std.mem.Allocator,
    ctx: anytype,
    comptime run_fn: anytype,
    values: anytype,
) !void {
    // Spawns one task per value, distributes across thread pool
    // Waits for all to complete
}

// Usage:
const Context = struct {
    fn process(ctx: *Context, value: *Item, index: usize) void {
        // Process item
    }
};

var ctx = Context{};
try thread_pool.each(allocator, &ctx, Context.process, items);
```

Source: [Bun ThreadPool.zig:156-229](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L156-L229)

**Global Singleton Pattern:**

Bun uses a thread-safe singleton for its work pool:[^12]

```zig
// src/work_pool.zig:4-30
pub const WorkPool = struct {
    var pool: ThreadPool = undefined;

    var createOnce = bun.once(
        struct {
            pub fn create() void {
                pool = ThreadPool.init(.{
                    .max_threads = bun.getThreadCount(),
                    .stack_size = ThreadPool.default_thread_stack_size,
                });
            }
        }.create,
    );

    pub inline fn get() *ThreadPool {
        createOnce.call(.{});
        return &pool;
    }
};
```

Source: [Bun work_pool.zig:4-30](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)

Original design: [kprotty/zap thread_pool.zig](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)

#### When to Use Thread Pools

**Use Thread Pools When:**
- CPU-bound tasks (parsing, compression, cryptography)
- Parallelizable workloads with independent units
- Need to limit concurrent threads to CPU count
- Amortizing thread creation overhead matters

**Avoid Thread Pools When:**
- I/O-bound tasks (use event loops instead)
- Tasks have strict ordering requirements
- Single task execution
- Memory is severely constrained

### Event Loops for I/O-Bound Concurrency

Event loops enable handling thousands of concurrent I/O operations with a single thread by multiplexing over non-blocking operations.

#### Proactor vs Reactor Patterns

Modern event loops use either the **proactor** or **reactor** pattern:

| Pattern | Approach | Platforms | Example |
|---------|----------|-----------|---------|
| **Proactor** | Kernel completes I/O, app receives result | Linux (io_uring), Windows (IOCP) | libxev |
| **Reactor** | Kernel notifies readiness, app does I/O | Linux (epoll), BSD (kqueue) | libuv, Tokio |

**Proactor Benefits:**
- Simpler application code (kernel performs I/O)
- Better performance with modern interfaces (io_uring)
- Completion-based is more intuitive

**Reactor Benefits:**
- Wider platform support
- More mature ecosystem
- Fine-grained control over I/O operations

#### libxev: Library-Based Async I/O

**libxev** is Mitchell Hashimoto's event loop library for Zig, designed as a modern replacement for removed async/await.[^13]

**Key Characteristics:**
- **Zero Runtime Allocations**: All memory managed by caller
- **Platform-Optimized Backends**:
  - Linux: io_uring (5.1+ kernel) with epoll fallback
  - macOS/BSD: kqueue
  - Windows: IOCP (in development)
  - WASM: poll_oneoff
- **Proactor Pattern**: Kernel completes operations
- **Thread-Safe**: Loop can run in any thread
- **Zig 0.15.1+ Compatible**

Repository: [mitchellh/libxev](https://github.com/mitchellh/libxev)

**Installation:**

Add to `build.zig.zon`:

```zig
.dependencies = .{
    .libxev = .{
        .url = "https://github.com/mitchellh/libxev/archive/<commit>.tar.gz",
        .hash = "<hash>",
    },
},
```

**Core API:**

```zig
const xev = @import("xev");

// Initialize event loop
var loop = try xev.Loop.init(.{});
defer loop.deinit();

// Run modes:
try loop.run(.no_wait);      // Poll once and return
try loop.run(.once);          // Wait for one event
try loop.run(.until_done);    // Run until all completions finished
```

**Completion Pattern:**

All asynchronous operations use completions to track state and callbacks:

```zig
pub const Completion = struct {
    userdata: ?*anyopaque = null,  // User state
    callback: *const CallbackFn,    // Result handler
};

pub const CallbackFn = fn (
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: Result,
) xev.CallbackAction;
```

**Timer Example:**

```zig
fn timerCallback(
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    c: *xev.Completion,
    result: xev.Timer.RunError!void,
) xev.CallbackAction {
    _ = userdata;
    _ = loop;
    _ = c;
    _ = result catch unreachable;

    std.debug.print("Timer fired!\n", .{});
    return .disarm;  // Remove from event loop
}

pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    var timer = try xev.Timer.init();
    defer timer.deinit();

    var completion: xev.Completion = .{
        .callback = timerCallback,
    };

    timer.run(&loop, &completion, 1000, .{});  // 1000ms
    try loop.run(.until_done);
}
```

**Production Usage: Ghostty Terminal**

Ghostty uses libxev extensively with multiple event loops in separate threads:[^14]

**Architecture:**
- **Main thread**: Terminal I/O event loop (PTY reading/writing)
- **Renderer thread**: OpenGL/Metal rendering loop
- **CF release thread**: macOS Core Foundation cleanup

Each thread runs its own `xev.Loop`, coordinating through lock-free queues.

Source: [Ghostty repository](https://github.com/ghostty-org/ghostty)

Mitchell Hashimoto's announcement: [libxev: evented I/O for Zig](https://mitchellh.com/writing/libxev-evented-io-zig)

#### Event Loops vs Threads: Decision Matrix

| Workload Type | Best Choice | Reason |
|---------------|-------------|--------|
| Network I/O (1000+ connections) | Event loop | Low memory overhead, excellent scalability |
| File I/O (many small reads) | Event loop | Kernel-optimized batching (io_uring) |
| CPU computation | Thread pool | Utilize multiple cores |
| Mixed I/O + CPU | Both | Event loop for I/O, offload CPU to thread pool |
| Blocking operations | Thread pool | Event loop must never block |
| Simple concurrent tasks | Threads | Easier mental model |

**Anti-Pattern: Blocking Event Loops**

```zig
// ❌ BAD: Blocks entire event loop
fn badCallback(...) xev.CallbackAction {
    std.Thread.sleep(5 * std.time.ns_per_s);  // ❌ Blocks all I/O!
    expensive_computation();                   // ❌ Blocks all I/O!
    return .disarm;
}

// ✓ GOOD: Offload to thread pool
fn goodCallback(...) xev.CallbackAction {
    thread_pool.spawn(expensive_computation, .{});
    return .disarm;
}
```

### 🕐 Legacy async/await (0.14.x)

**⚠️ DEPRECATED: This section documents removed features for historical reference only.**

Zig 0.14.x included built-in `async`/`await` keywords for cooperative multitasking.

**Why It Was Removed:**

1. **Compiler Complexity**: Added ~15,000 lines of complex compiler code
2. **Limited Platform Support**: Stack unwinding issues on some platforms
3. **Function Coloring**: Forced distinction between sync and async functions
4. **Better Alternatives**: Library-based solutions (libxev, zap) offer more flexibility
5. **Maintenance Burden**: Conflicts with Zig's explicit philosophy

Andrew Kelley (paraphrased from GitHub discussions):
> "Async/await was an interesting experiment, but it added too much complexity to the compiler for a feature that can be better implemented in libraries. The future of async in Zig is library-based, not language-based."

**Legacy Syntax (0.14.x only, do not use):**

```zig
// 0.14.x - DO NOT USE IN 0.15+
fn asyncFunction() callconv(.async) !void {
    const result = await otherAsyncFunction();
    // ...
}

var frame = async asyncFunction();
const result = await frame;
```

**Migration Path:**

| 0.14.x Pattern | 0.15+ Alternative | Use Case |
|----------------|-------------------|----------|
| `async`/`await` file I/O | libxev event loop | I/O-bound server |
| `async` parallel computation | Thread pool | CPU-bound work |
| Blocking + `await` | Standard blocking I/O | Simple scripts |

See: [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html#async-functions)

---

## Code Examples

This section references the tested examples included with this chapter. All examples compile with Zig 0.15.1+.

### example_basic_threads.zig

Demonstrates thread lifecycle, data passing, and configuration:

**Key Concepts:**
- Thread creation with `spawn()`
- Joining and detaching threads
- Custom stack sizes
- Thread IDs and CPU count

**Run:**
```
zig run example_basic_threads.zig
```

**Highlights:**

```zig
// Spawn with arguments
const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });
thread.join();

// Multiple threads
var threads: [3]std.Thread = undefined;
for (&threads, 0..) |*thread, i| {
    thread.* = try std.Thread.spawn(.{}, workerThread, .{@intCast(i), 500});
}
for (threads) |thread| {
    thread.join();
}

// Detached thread
const thread = try std.Thread.spawn(.{}, workerThread, .{ 777, 50 });
thread.detach();  // Runs independently, cleans up automatically
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_basic_threads.zig`

### example_synchronization.zig

Covers Mutex, atomic operations, RwLock, Condition, and memory ordering:

**Key Concepts:**
- Mutex-protected shared counter
- Lock-free atomic counter
- Reader-writer lock for document store
- Acquire/release memory ordering
- Compare-and-swap (CAS)
- Producer-consumer with Condition

**Run:**
```
zig run example_synchronization.zig
```

**Highlights:**

```zig
// Mutex pattern
const SharedCounter = struct {
    mutex: std.Thread.Mutex = .{},
    value: u32 = 0,

    fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value += 1;
    }
};

// Atomic pattern
const AtomicCounter = struct {
    value: std.atomic.Value(u32) = .init(0),

    fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }
};

// Memory ordering
data.store(42, .monotonic);
flag.store(true, .release);  // Publish data

while (!flag.load(.acquire)) {}  // Synchronize
const value = data.load(.monotonic);  // Guaranteed to see 42
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_synchronization.zig`

### example_thread_pool.zig

Demonstrates `std.Thread.Pool` usage patterns:

**Key Concepts:**
- Basic thread pool with WaitGroup
- Shared state with atomic operations
- Results collection with Mutex
- Work distribution visualization
- Pool sizing recommendations

**Run:**
```
zig run example_thread_pool.zig
```

**Highlights:**

```zig
var pool: std.Thread.Pool = undefined;
try pool.init(.{ .allocator = allocator });
defer pool.deinit();

var wait_group: std.Thread.WaitGroup = .{};

// Spawn tasks
for (0..10) |i| {
    pool.spawnWg(&wait_group, processTask, .{i});
}

// Wait for completion
pool.waitAndWork(&wait_group);
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_thread_pool.zig`

### example_benchmarking.zig

Performance measurement techniques using `std.time.Timer`:

**Key Concepts:**
- Timer usage and lap measurements
- Preventing compiler optimizations
- Comparing algorithms
- Throughput calculation
- Warm-up iterations
- Statistical analysis (mean, median, std dev)

**Run:**
```
zig run example_benchmarking.zig
```

**Highlights:**

```zig
// Basic timing
var timer = try std.time.Timer.start();
expensiveOperation();
const elapsed = timer.read();  // nanoseconds

// Prevent optimization
std.mem.doNotOptimizeAway(&result);

// Lap measurements
const phase1 = timer.lap();
operation1();
const phase2 = timer.lap();
operation2();

// Throughput
const elapsed_s = @as(f64, @floatFromInt(elapsed)) / std.time.ns_per_s;
const throughput_mb = data_size_mb / elapsed_s;
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_benchmarking.zig`

### example_xev_concepts.zig

Conceptual demonstration of event loop patterns (does not require libxev):

**Key Concepts:**
- Event loop architecture
- Proactor vs Reactor patterns
- When to use event loops vs threads
- libxev API overview
- Backend selection (io_uring, kqueue, IOCP)
- Common anti-patterns

**Run:**
```
zig run example_xev_concepts.zig
```

**Note**: This example shows concepts without requiring libxev. For production libxev usage, see Ghostty source code.

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_xev_concepts.zig`

---

## Common Pitfalls

### Pitfall 1: Forgetting to Join Threads

**Problem**: Thread handles must be explicitly joined or detached. Dropping a thread handle leaks resources.

```zig
// ❌ BAD: Resource leak
fn processData(data: []const u8) void {
    _ = std.Thread.spawn(.{}, worker, .{data}) catch unreachable;
    // Thread handle lost! Leaks 16 MiB stack memory + thread descriptor
}
```

**Why It Matters:**
- Unjoined threads leak stack memory (16 MiB per thread on Linux)
- Process exit may crash if threads are still running
- Debug builds panic on program exit

**Solution:**

```zig
// ✓ GOOD: Always join or detach
fn processData(data: []const u8) !void {
    const thread = try std.Thread.spawn(.{}, worker, .{data});
    thread.join();  // Wait for completion
}

// OR detach if fire-and-forget is intended
fn processDataAsync(data: []const u8) !void {
    const thread = try std.Thread.spawn(.{}, worker, .{data});
    thread.detach();  // Explicitly allow independent execution
}
```

**Detection:**

Debug builds detect unjoined threads at program exit:

```zig
test "thread leak" {
    _ = std.Thread.spawn(.{}, worker, .{}) catch unreachable;
    // Test framework will fail: thread not joined
}
```

### Pitfall 2: Data Races on Non-Atomic Shared State

**Problem**: Non-atomic operations on shared data cause race conditions.

```zig
// ❌ BAD: Race condition
var counter: u64 = 0;

fn increment() void {
    counter += 1;  // NOT ATOMIC! Compiles to: load, add, store
}

pub fn main() !void {
    const t1 = try std.Thread.spawn(.{}, increment, .{});
    const t2 = try std.Thread.spawn(.{}, increment, .{});
    t1.join();
    t2.join();
    std.debug.print("Counter: {}\n", .{counter});  // Could be 1, not 2!
}
```

**Why It Fails:**

`counter += 1` compiles to three separate instructions:
1. Load current value into register
2. Add 1 to register
3. Store register back to memory

Thread interleaving can lose updates:

```
Time | Thread 1      | Thread 2      | Memory
-----|---------------|---------------|-------
  1  | Load 0        |               | 0
  2  |               | Load 0        | 0
  3  | Add 1 → 1     |               | 0
  4  |               | Add 1 → 1     | 0
  5  | Store 1       |               | 1
  6  |               | Store 1       | 1
```

Final result: 1 (should be 2)

**Solution 1: Atomic Operations**

```zig
// ✓ GOOD: Lock-free atomic
var counter = std.atomic.Value(u64).init(0);

fn increment() void {
    _ = counter.fetchAdd(1, .monotonic);
}
```

**Solution 2: Mutex Protection**

```zig
// ✓ GOOD: Mutex for complex updates
var counter: u64 = 0;
var mutex = std.Thread.Mutex{};

fn increment() void {
    mutex.lock();
    defer mutex.unlock();
    counter += 1;
}
```

**Detection:**

Use ThreadSanitizer (TSan):

```bash
zig build-exe -fsanitize=thread program.zig
./program
# TSan will report data races at runtime
```

### Pitfall 3: Deadlock from Inconsistent Lock Ordering

**Problem**: Acquiring locks in different orders across threads causes deadlock.

```zig
// ❌ BAD: Inconsistent lock ordering
var mutex_a = std.Thread.Mutex{};
var mutex_b = std.Thread.Mutex{};

fn thread1() void {
    mutex_a.lock();
    std.time.sleep(1 * std.time.ns_per_ms);  // Simulate work
    mutex_b.lock();  // ← Deadlock here!
    defer mutex_b.unlock();
    defer mutex_a.unlock();
}

fn thread2() void {
    mutex_b.lock();  // ← Opposite order!
    std.time.sleep(1 * std.time.ns_per_ms);
    mutex_a.lock();  // ← Deadlock here!
    defer mutex_a.unlock();
    defer mutex_b.unlock();
}
```

**Why It Deadlocks:**

```
Time | Thread 1       | Thread 2
-----|----------------|---------------
  1  | Lock A         |
  2  |                | Lock B
  3  | Wait for B...  |
  4  |                | Wait for A...
  ∞  | (deadlock)     | (deadlock)
```

**Solution: Consistent Lock Ordering**

```zig
// ✓ GOOD: Always acquire locks in same order
fn thread1() void {
    mutex_a.lock();  // Always A first
    defer mutex_a.unlock();
    mutex_b.lock();  // Then B
    defer mutex_b.unlock();
    // ... critical section
}

fn thread2() void {
    mutex_a.lock();  // Same order: A first
    defer mutex_a.unlock();
    mutex_b.lock();  // Then B
    defer mutex_b.unlock();
    // ... critical section
}
```

**Alternative: Lock Hierarchy**

Establish a global lock ordering and document it:

```zig
// Lock hierarchy (enforced by convention):
// 1. resource_lock
// 2. state_lock
// 3. cache_lock

// All code must acquire locks in this order
```

**Detection:**

Debug builds detect self-deadlock (same thread locking twice):

```zig
var mutex = std.Thread.Mutex{};

mutex.lock();
mutex.lock();  // Panic: "Deadlock detected"
```

For cross-thread deadlocks, use external tools:
- Helgrind (Valgrind)
- ThreadSanitizer with deadlock detection
- Manual code review

### Pitfall 4: Using .monotonic for Synchronization

**Problem**: `.monotonic` ordering does not synchronize memory across threads.

```zig
// ❌ BAD: Memory ordering violation
var data: u32 = 0;
var ready = std.atomic.Value(bool).init(false);

// Writer
fn writer() void {
    data = 42;
    ready.store(true, .monotonic);  // ❌ Does not publish data!
}

// Reader
fn reader() void {
    while (!ready.load(.monotonic)) {}  // ❌ Does not synchronize!
    const value = data;  // May see 0, not 42!
}
```

**Why It Fails:**

`.monotonic` ensures the atomic operation itself is atomic, but does not establish happens-before relationships. The reader may see `ready == true` but `data == 0` due to CPU reordering.

**Solution: Use .acquire/.release**

```zig
// ✓ GOOD: Proper synchronization
fn writer() void {
    data = 42;
    ready.store(true, .release);  // Publish data
}

fn reader() void {
    while (!ready.load(.acquire)) {}  // Synchronize with writer
    const value = data;  // Guaranteed to see 42
}
```

**When to Use Each Ordering:**

| Ordering | Use Case | Synchronizes? |
|----------|----------|---------------|
| `.monotonic` | Simple counters, no dependencies | No |
| `.acquire` | Reading published data | Yes (with release) |
| `.release` | Publishing data | Yes (with acquire) |
| `.acq_rel` | Read-modify-write with dependencies | Yes |
| `.seq_cst` | Debugging, total ordering | Yes (expensive) |

### Pitfall 5: Blocking Event Loops with CPU Work

**Problem**: Performing CPU-bound work in event loop callbacks blocks all I/O operations.

```zig
// ❌ BAD: Blocks entire event loop
fn httpRequestCallback(
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: anyerror!usize,
) xev.CallbackAction {
    const bytes = result catch return .disarm;

    // ❌ This blocks ALL other I/O operations!
    const processed = processImage(bytes);  // Takes 100ms

    sendResponse(processed);
    return .disarm;
}
```

**Why It Is a Problem:**

Event loops are single-threaded. Any blocking operation stops all other I/O from progressing:

```
Request 1 arrives → Process image (100ms, blocking)
  ↓ During this time:
  × Request 2 waits (cannot read)
  × Request 3 waits (cannot read)
  × Timer callbacks delayed
  × All I/O stalls
```

**Solution: Offload to Thread Pool**

```zig
// ✓ GOOD: Offload CPU work
fn httpRequestCallback(...) xev.CallbackAction {
    const bytes = result catch return .disarm;

    // Queue work to thread pool
    const task = allocator.create(ProcessTask) catch return .disarm;
    task.* = .{ .data = bytes, .loop = loop };
    thread_pool.spawn(processInBackground, .{task});

    return .disarm;
}

fn processInBackground(task: *ProcessTask) void {
    const processed = processImage(task.data);  // Runs on thread pool

    // Post result back to event loop
    task.loop.notify(.{ .callback = sendResponseCallback, .data = processed });
}
```

**Golden Rule:**

Event loop callbacks should:
- ✓ Perform I/O operations (read, write, accept)
- ✓ Schedule timers
- ✓ Update state quickly (< 1ms)
- ❌ Never block (sleep, CPU-intensive work)
- ❌ Never call blocking syscalls

---

## In Practice

This section links to production concurrency patterns in real-world Zig projects.

### TigerBeetle: Distributed Database

**Project**: High-performance distributed database for financial systems
**Concurrency Model**: Single-threaded event loop + thread-safe client API
**Repository**: [tigerbeetle/tigerbeetle](https://github.com/tigerbeetle/tigerbeetle)

**Key Patterns:**

1. **Thread-Safe Client Interface with Locker**[^4]
   - File: [context.zig:62-126](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)
   - Pattern: Mutex-protected extern struct for FFI boundary
   - Uses `defer` for automatic unlock

2. **Atomic State Machine for Cross-Thread Signaling**[^8]
   - File: [signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)
   - Pattern: Lock-free notification using atomic enum
   - Memory ordering: `.release` for publish, `.acquire` for reload

**Architectural Notes:**
- Main replica is single-threaded (uses io_uring on Linux)
- Client libraries are thread-safe, allowing multi-threaded apps
- Heavy use of assertions for invariant checking

### Bun: JavaScript Runtime

**Project**: All-in-one JavaScript runtime (Node.js alternative)
**Concurrency Model**: Work-stealing thread pool + event loop hybrid
**Repository**: [oven-sh/bun](https://github.com/oven-sh/bun)

**Key Patterns:**

1. **Work-Stealing Thread Pool**[^9]
   - File: [ThreadPool.zig:1-1055](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig)
   - Lines: [600-644](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644) (work stealing algorithm)
   - Derived from: [kprotty/zap](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)
   - Pattern: MPMC global queue + SPMC per-thread queues + work stealing

2. **Lock-Free Ring Buffer**
   - File: [ThreadPool.zig:849-1042](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L849-L1042)
   - Pattern: Bounded lock-free queue with atomic head/tail
   - Capacity: 256 tasks per buffer

3. **Thread Pool Singleton**[^12]
   - File: [work_pool.zig:4-30](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)
   - Pattern: Lazy initialization with `bun.once()`

**Architectural Notes:**
- Multiple thread pools: bundler, HTTP, SQLite
- Each JavaScript event loop runs in dedicated thread
- Pool size determined by CPU core count

### ZLS: Zig Language Server

**Project**: Official language server for Zig (IDE support)
**Concurrency Model**: Thread pool for analysis + main LSP thread
**Repository**: [zigtools/zls](https://github.com/zigtools/zls)

**Key Patterns:**

1. **RwLock for Document Store**[^5]
   - File: [DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)
   - Pattern: Reader-writer lock protecting document handles map
   - Use case: Many concurrent reads (autocomplete), rare writes (file changes)

2. **Thread Pool for Background Analysis**
   - Uses `std.Thread.Pool` for parallel semantic analysis
   - Analyze multiple files concurrently

3. **Atomic Build Counter**
   - Pattern: `std.atomic.Value(i32)` for tracking active builds
   - Prevents shutdown until builds complete

4. **Tracy Integration**[^15]
   - File: [tracy.zig:1-50](https://github.com/zigtools/zls/blob/master/src/tracy.zig)
   - Pattern: Conditional compilation for performance profiling

**Architectural Notes:**
- Main thread handles LSP protocol
- Thread pool analyzes Zig ASTs in parallel
- Build runner spawns processes, must be serialized

### Ghostty: Terminal Emulator

**Project**: High-performance GPU-accelerated terminal by Mitchell Hashimoto
**Concurrency Model**: Multiple libxev event loops in separate threads
**Repository**: [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty)

**Key Patterns:**

1. **Multi-Threaded Event Loop Architecture**[^14]
   - Main thread: Terminal I/O event loop (PTY reading/writing)
   - Renderer thread: OpenGL/Metal rendering loop
   - CF release thread: macOS Core Foundation cleanup
   - Each thread runs its own `xev.Loop`

2. **PTY I/O with libxev**
   - Pattern: Async reads from PTY using xev.File
   - Non-blocking terminal output processing

3. **Thread-Safe Command Queue**
   - Pattern: Lock-free queue for commands from main to renderer
   - Draw commands: text, cursor, etc.

**Architectural Notes:**
- Uses libxev for all I/O (PTY, signals, timers)
- Platform-specific event loop integration
- Rendering decoupled from terminal processing for 120+ FPS

### zap: HTTP Server Framework

**Project**: High-performance HTTP server framework for Zig
**Concurrency Model**: Event loop with connection pooling and worker threads
**Repository**: [zigzap/zap](https://github.com/zigzap/zap)

**Key Patterns:**

1. **Event Loop Integration with epoll/kqueue**
   - Pattern: Platform-specific event notification for non-blocking I/O
   - File: Event loop abstraction in core HTTP handling
   - Single-threaded event loop processes thousands of concurrent connections
   - Tight integration with OS primitives for minimal overhead

2. **Connection Pooling**
   - Pattern: Pre-allocated connection structures reused across requests
   - Reduces allocation pressure in hot path
   - Buffer reuse minimizes memory churn for request/response cycles

3. **Middleware Chain Architecture**
   - Pattern: Composable request handlers with explicit control flow
   - Zero-cost abstraction for handler dispatch
   - Clear ownership semantics for request/response lifecycle

4. **Zero-Copy Request Parsing**
   - Pattern: Parse HTTP headers in-place without copying
   - Slices reference connection buffers directly
   - Defers allocation until handler explicitly requires owned data

**Architectural Notes:**
- Single event loop handles I/O multiplexing (Linux: epoll, BSD: kqueue)
- Optional worker thread pool for CPU-bound request handlers
- Explicit flush control for streaming responses
- Production-grade performance: handles 100K+ requests/sec

**Comparison with libxev:**
- zap: HTTP-specific, optimized for web server workloads
- libxev: General-purpose event loop (files, sockets, timers, signals)
- Both demonstrate Zig's library-based async approach (no language keywords)

> **See also:** Chapter 4 (I/O Streams) for zap's buffered response writers and zero-copy request parsing patterns.

### Zig Compiler Self-Hosting

**Project**: Zig compiler itself (written in Zig)
**Concurrency Model**: Thread pool for parallel compilation
**Repository**: [ziglang/zig](https://github.com/ziglang/zig)

**Key Patterns:**

1. **WaitGroup for Parallel Compilation**
   - Pattern: Coordinate multiple compilation units
   - Parallel object file generation

2. **Lock-Free Job Queue**
   - Pattern: MPMC queue for distributing compilation tasks
   - Distribute semantic analysis across cores

3. **Atomic Reference Counting**
   - Track module dependencies with atomic refcounts
   - Safe concurrent access to shared AST nodes

Source: [main.zig](https://github.com/ziglang/zig/blob/master/src/main.zig)

### Production Patterns Summary

| Project | Concurrency Model | Key Pattern | Deep Link |
|---------|-------------------|-------------|-----------|
| TigerBeetle | Single-thread + thread-safe API | Atomic state machine | [signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107) |
| Bun | Work-stealing thread pool | Lock-free ring buffer | [ThreadPool.zig:849-1042](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L849-L1042) |
| ZLS | Thread pool + RwLock | Reader-writer document store | [DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36) |
| Ghostty | Multi-loop libxev | Per-thread event loops | [ghostty repository](https://github.com/ghostty-org/ghostty) |
| zap | Event loop + worker pool | Connection pooling + zero-copy parsing | [zap repository](https://github.com/zigzap/zap) |
| Zig Compiler | Parallel compilation | WaitGroup coordination | [main.zig](https://github.com/ziglang/zig/blob/master/src/main.zig) |

---

## Summary

Zig provides explicit, zero-cost concurrency primitives for both CPU-bound parallelism and I/O-bound concurrency.

### Mental Model

**Threads for CPU, Event Loops for I/O:**

- **Use std.Thread** when you need true parallelism across CPU cores
- **Use event loops (libxev)** when you need to handle thousands of concurrent I/O operations
- **Use both** for mixed workloads: event loop for I/O, thread pool for CPU

### Key Takeaways

1. **Explicitness Over Implicitness**: Zig requires explicit thread management (join/detach), explicit synchronization (Mutex/Atomic), and explicit memory ordering. This prevents hidden costs and unexpected behavior.

2. **Platform-Optimal Implementations**: Zig's synchronization primitives automatically select the best platform implementation (futex, SRWLOCK, os_unfair_lock) with zero overhead.

3. **Memory Ordering Matters**: Use `.acquire/.release` for publishing/consuming data, `.monotonic` for simple counters, and rarely `.seq_cst`. Wrong ordering causes subtle bugs.

4. **Library-Based Async**: With async/await removed, use library event loops (libxev) for I/O concurrency. This provides more flexibility and platform-specific optimizations.

5. **Benchmarking Best Practices**: Use `std.time.Timer`, prevent compiler optimizations with `doNotOptimizeAway`, include warm-up iterations, and report statistical measures (median, not just mean).

### Practical Guidelines

- Always join or detach threads
- Protect shared mutable state with Mutex or atomics
- Acquire locks in consistent order to prevent deadlock
- Never block event loop threads
- Use thread pools sized to CPU count for CPU-bound work
- Profile with Tracy or perf to find actual bottlenecks

Zig's concurrency model rewards careful design but provides the tools for building highly efficient, correct concurrent systems.

---

## References

[^1]: [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

[^2]: [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)

[^3]: [std.Thread.Mutex Implementation](https://github.com/ziglang/zig/blob/master/lib/std/Thread/Mutex.zig)

[^4]: [TigerBeetle context.zig (Locker implementation)](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)

[^5]: [ZLS DocumentStore.zig (RwLock usage)](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)

[^6]: [std.atomic.Value Implementation](https://github.com/ziglang/zig/blob/master/lib/std/atomic.zig)

[^7]: [Bun ThreadPool.zig (Atomic CAS)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L374-L379)

[^8]: [TigerBeetle signal.zig (Atomic state machine)](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)

[^9]: [Bun ThreadPool.zig (Full implementation)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig)

[^10]: [Bun ThreadPool.zig (Work stealing algorithm)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644)

[^11]: [Bun ThreadPool.zig (Parallel iteration)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L156-L229)

[^12]: [Bun work_pool.zig (Singleton pattern)](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)

[^13]: [libxev GitHub Repository](https://github.com/mitchellh/libxev)

[^14]: [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)

[^15]: [ZLS tracy.zig (Profiling integration)](https://github.com/zigtools/zls/blob/master/src/tracy.zig)

### Additional Resources

**Official Documentation:**
- [Zig Language Reference: Threads](https://ziglang.org/documentation/master/#Threads)
- [Zig Standard Library: std.Thread](https://github.com/ziglang/zig/blob/master/lib/std/Thread.zig)
- [Zig Standard Library: std.atomic](https://github.com/ziglang/zig/blob/master/lib/std/atomic.zig)

**Libraries:**
- [libxev: Event Loop for Zig](https://github.com/mitchellh/libxev)
- [zap: HTTP Server Framework](https://github.com/zigzap/zap) - Production event loop patterns for web services
- [kprotty/zap: Original Thread Pool Design](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)
- [Tracy Profiler](https://github.com/wolfpld/tracy)

**Blog Posts:**
- [Mitchell Hashimoto: libxev - Evented I/O for Zig](https://mitchellh.com/writing/libxev-evented-io-zig)

**Community Resources:**
- [Zig Guide: Concurrency](https://zig.guide/)
- [ZigLearn: Threads](https://ziglearn.org/)

**Performance Tools:**
- [Linux perf](https://perf.wiki.kernel.org/)
- [Valgrind (Helgrind, DRD)](https://valgrind.org/)
- [ThreadSanitizer (TSan)](https://github.com/google/sanitizers)

**Benchmark Code:**
- [std.crypto.benchmark](https://github.com/ziglang/zig/blob/master/lib/std/crypto/benchmark.zig)
- [std.hash.benchmark](https://github.com/ziglang/zig/blob/master/lib/std/hash/benchmark.zig)
