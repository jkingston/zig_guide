const std = @import("std");

// Demonstrate Mutex, atomic operations, and RwLock

// Example 1: Shared counter with Mutex protection
const SharedCounter = struct {
    mutex: std.Thread.Mutex = .{},
    value: u32 = 0,

    fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const old_value = self.value;
        self.value += 1;
        _ = old_value; // Demonstrate critical section
    }

    fn getValue(self: *SharedCounter) u32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.value;
    }
};

// Example 2: Atomic counter (lock-free)
const AtomicCounter = struct {
    value: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }

    fn getValue(self: *const AtomicCounter) u32 {
        return self.value.load(.monotonic);
    }
};

// Example 3: Reader-Writer Lock for read-heavy workload
const Document = struct {
    lock: std.Thread.RwLock = .{},
    content: []const u8,
    version: u32 = 0,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Document {
        const initial_content = try allocator.dupe(u8, "Initial content");
        return Document{
            .content = initial_content,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Document) void {
        self.allocator.free(self.content);
    }

    // Read operation (shared lock)
    fn read(self: *Document) []const u8 {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.content;
    }

    // Write operation (exclusive lock)
    fn update(self: *Document, new_content: []const u8) !void {
        self.lock.lock();
        defer self.lock.unlock();

        self.allocator.free(self.content);
        self.content = try self.allocator.dupe(u8, new_content);
        self.version += 1;
    }

    fn getVersion(self: *Document) u32 {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.version;
    }
};

// Example 4: Memory ordering demonstration
const MemoryOrderingDemo = struct {
    data: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    // Writer thread: stores data then sets flag with release
    fn writer(self: *MemoryOrderingDemo, value: u32) void {
        // Store data (visible to readers who see flag == true)
        self.data.store(value, .monotonic);

        // Set flag with release: guarantees all previous stores are visible
        self.flag.store(true, .release);

        std.debug.print("Writer: stored value {d}, set flag\n", .{value});
    }

    // Reader thread: waits for flag with acquire, then reads data
    fn reader(self: *MemoryOrderingDemo, expected: u32) void {
        // Wait for flag with acquire: synchronizes with release
        while (!self.flag.load(.acquire)) {
            std.Thread.yield() catch {};
        }

        // Now we can safely read data (guaranteed to see writer's stores)
        const value = self.data.load(.monotonic);
        std.debug.print("Reader: read value {d} (expected {d})\n", .{ value, expected });

        if (value != expected) {
            std.debug.print("ERROR: Memory ordering violation!\n", .{});
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Synchronization Examples ===\n\n", .{});

    // Example 1: Mutex-protected counter
    {
        std.debug.print("Example 1: Mutex-protected shared counter\n", .{});

        var counter = SharedCounter{};
        const thread_count = 4;
        const increments_per_thread = 1000;

        const Worker = struct {
            fn run(c: *SharedCounter, iterations: u32) void {
                for (0..iterations) |_| {
                    c.increment();
                }
            }
        };

        var threads: [thread_count]std.Thread = undefined;

        for (&threads) |*thread| {
            thread.* = try std.Thread.spawn(.{}, Worker.run, .{ &counter, increments_per_thread });
        }

        for (threads) |thread| {
            thread.join();
        }

        const final_value = counter.getValue();
        const expected = thread_count * increments_per_thread;
        std.debug.print("Final counter value: {d} (expected: {d})\n", .{ final_value, expected });
        if (final_value == expected) {
            std.debug.print("✓ No data races detected!\n\n", .{});
        } else {
            std.debug.print("✗ Data race occurred!\n\n", .{});
        }
    }

    // Example 2: Atomic counter (lock-free)
    {
        std.debug.print("Example 2: Atomic counter (lock-free)\n", .{});

        var counter = AtomicCounter{};
        const thread_count = 4;
        const increments_per_thread = 1000;

        const Worker = struct {
            fn run(c: *AtomicCounter, iterations: u32) void {
                for (0..iterations) |_| {
                    c.increment();
                }
            }
        };

        var threads: [thread_count]std.Thread = undefined;

        for (&threads) |*thread| {
            thread.* = try std.Thread.spawn(.{}, Worker.run, .{ &counter, increments_per_thread });
        }

        for (threads) |thread| {
            thread.join();
        }

        const final_value = counter.getValue();
        const expected = thread_count * increments_per_thread;
        std.debug.print("Final atomic value: {d} (expected: {d})\n", .{ final_value, expected });
        if (final_value == expected) {
            std.debug.print("✓ Atomics work correctly!\n\n", .{});
        } else {
            std.debug.print("✗ Atomic operation failed!\n\n", .{});
        }
    }

    // Example 3: Reader-Writer Lock
    {
        std.debug.print("Example 3: RwLock for read-heavy workload\n", .{});

        var doc = try Document.init(allocator);
        defer doc.deinit();

        const Reader = struct {
            fn run(d: *Document, reader_id: u32) void {
                for (0..3) |i| {
                    const content = d.read();
                    const version = d.getVersion();
                    std.debug.print("Reader {d} iteration {d}: \"{s}\" (v{d})\n", .{ reader_id, i, content, version });
                    std.Thread.sleep(10 * std.time.ns_per_ms);
                }
            }
        };

        const Writer = struct {
            fn run(d: *Document, alloc: std.mem.Allocator) void {
                std.Thread.sleep(20 * std.time.ns_per_ms);

                const new_content = std.fmt.allocPrint(alloc, "Updated at {d}ns", .{std.time.nanoTimestamp()}) catch return;
                defer alloc.free(new_content);

                d.update(new_content) catch return;
                std.debug.print("Writer: updated document\n", .{});
            }
        };

        const r1 = try std.Thread.spawn(.{}, Reader.run, .{ &doc, 1 });
        const r2 = try std.Thread.spawn(.{}, Reader.run, .{ &doc, 2 });
        const w = try std.Thread.spawn(.{}, Writer.run, .{ &doc, allocator });

        r1.join();
        r2.join();
        w.join();

        std.debug.print("Final version: {d}\n\n", .{doc.getVersion()});
    }

    // Example 4: Memory ordering (acquire/release)
    {
        std.debug.print("Example 4: Memory ordering with acquire/release\n", .{});

        var demo = MemoryOrderingDemo{};
        const test_value: u32 = 42;

        const writer_thread = try std.Thread.spawn(.{}, MemoryOrderingDemo.writer, .{ &demo, test_value });
        const reader_thread = try std.Thread.spawn(.{}, MemoryOrderingDemo.reader, .{ &demo, test_value });

        writer_thread.join();
        reader_thread.join();

        std.debug.print("✓ Acquire/release synchronization works!\n\n", .{});
    }

    // Example 5: Compare-and-swap (CAS) for lock-free data structures
    {
        std.debug.print("Example 5: Compare-and-swap (CAS)\n", .{});

        var value = std.atomic.Value(u32).init(100);

        // Try to change 100 -> 200
        const result1 = value.cmpxchgStrong(100, 200, .seq_cst, .seq_cst);
        if (result1 == null) {
            std.debug.print("CAS succeeded: 100 -> 200\n", .{});
        } else {
            std.debug.print("CAS failed, current value: {d}\n", .{result1.?});
        }

        // Try to change 100 -> 300 (will fail, value is now 200)
        const result2 = value.cmpxchgStrong(100, 300, .seq_cst, .seq_cst);
        if (result2 == null) {
            std.debug.print("CAS succeeded: 100 -> 300\n", .{});
        } else {
            std.debug.print("CAS failed, current value: {d}\n", .{result2.?});
        }

        std.debug.print("Final value: {d}\n\n", .{value.load(.seq_cst)});
    }

    // Example 6: Condition variable for producer-consumer
    {
        std.debug.print("Example 6: Condition variable (wait/signal)\n", .{});

        const Queue = struct {
            mutex: std.Thread.Mutex = .{},
            cond: std.Thread.Condition = .{},
            items: u32 = 0,
            max_items: u32 = 5,
        };

        var queue = Queue{};

        const Producer = struct {
            fn run(q: *Queue) void {
                for (0..10) |i| {
                    q.mutex.lock();
                    defer q.mutex.unlock();

                    // Wait if queue is full
                    while (q.items >= q.max_items) {
                        q.cond.wait(&q.mutex);
                    }

                    q.items += 1;
                    std.debug.print("Producer: added item (total: {d})\n", .{q.items});

                    // Signal consumer that item is available
                    q.cond.signal();

                    _ = i;
                }
            }
        };

        const Consumer = struct {
            fn run(q: *Queue) void {
                for (0..10) |i| {
                    std.Thread.sleep(20 * std.time.ns_per_ms);

                    q.mutex.lock();
                    defer q.mutex.unlock();

                    // Wait if queue is empty
                    while (q.items == 0) {
                        q.cond.wait(&q.mutex);
                    }

                    q.items -= 1;
                    std.debug.print("Consumer: took item (remaining: {d})\n", .{q.items});

                    // Signal producer that space is available
                    q.cond.signal();

                    _ = i;
                }
            }
        };

        const producer = try std.Thread.spawn(.{}, Producer.run, .{&queue});
        const consumer = try std.Thread.spawn(.{}, Consumer.run, .{&queue});

        producer.join();
        consumer.join();

        std.debug.print("\n", .{});
    }

    std.debug.print("=== All synchronization examples completed ===\n", .{});
}
