# Memory & Allocators

## Overview

Memory management in Zig is explicit, deterministic, and designed to eliminate an entire class of bugs common in other systems languages. Unlike languages with garbage collection or hidden allocations, Zig requires every memory allocation to specify an allocator explicitly. This philosophy—"no hidden memory allocations"—forces clarity about ownership, lifetime, and resource cleanup throughout the codebase.

This chapter explains the allocator interface, common allocator patterns, ownership semantics, and cleanup idioms that underpin containers, I/O, and concurrency in Zig. Understanding these patterns is essential for writing correct, maintainable systems software.

## Core Concepts

### The Allocator Interface

Zig's `std.mem.Allocator` provides a uniform interface for all memory allocation strategies. This vtable-based design enables compile-time polymorphism—callers can switch allocator implementations without code changes, making it trivial to use an arena for request handling or a debug allocator for leak detection.

The interface defines four primary operations:

- **`alloc(T, count)`** — Allocates a slice of type `[]T` with `count` elements
- **`free(slice)`** — Deallocates a previously allocated slice
- **`create(T)`** — Allocates a single item of type `T`, returning `*T`
- **`destroy(pointer)`** — Deallocates a single item

All allocation methods return error unions (`![]T` or `!*T`), with `error.OutOfMemory` as the primary failure mode. For performance-critical scenarios, `alignedAlloc()` ensures specific alignment requirements, such as cache-line alignment for buffers.[^1]

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // Slice allocation
    const numbers = try allocator.alloc(u32, 5);
    defer allocator.free(numbers);

    // Single item allocation
    const single = try allocator.create(u32);
    defer allocator.destroy(single);
    single.* = 42;

    // Aligned allocation (16-byte boundary)
    const aligned = try allocator.alignedAlloc(u8, 16, 64);
    defer allocator.free(aligned);
}
```

This example demonstrates the core interface with leak detection. The `GeneralPurposeAllocator` reports leaks at `deinit()`, catching forgotten frees during development.

### Allocator Types and Selection

Zig's standard library provides specialized allocators for different use cases. Choosing the right allocator improves performance, safety, and code clarity.

**ArenaAllocator** — Optimized for request-scoped allocations where all memory is freed together. Individual `free()` calls are no-ops; a single `deinit()` releases everything. This simplifies cleanup for HTTP handlers, parsers, or temporary data structures. TigerBeetle and ZLS use arenas extensively for configuration parsing and request handling.[^2][^3]

**FixedBufferAllocator** — Allocates from a pre-provided buffer, typically on the stack. Because it requires no system calls, it offers predictable performance and automatic cleanup when the buffer goes out of scope. Ideal for known maximum sizes or performance-critical code paths. The Zig test runner uses this for command-line argument processing.[^4]

**GeneralPurposeAllocator** — Thread-safe allocator with safety features: prevents double-free and use-after-free, detects leaks with stack traces. Recommended for development and applications prioritizing safety over raw performance. The allocator never reuses addresses, helping catch use-after-free bugs.

**c_allocator** — Wrapper around C's `malloc/free`. Offers high performance with minimal overhead, but requires linking libc and provides no safety features. Suitable for release builds where performance is critical.

**std.testing.allocator** — Fails tests automatically if allocations are not freed, with stack traces for leak locations. Essential for all test code.

| Scenario | Recommended Allocator | Rationale |
|----------|----------------------|-----------|
| Testing | `std.testing.allocator` | Automatic leak detection |
| Development | `GeneralPurposeAllocator` | Safety features, debugging |
| Request handling | `ArenaAllocator` | Bulk cleanup, scoped lifetime |
| Known max size | `FixedBufferAllocator` | No syscalls, bounded |
| Release builds | `c_allocator` | Performance |

### Allocator Propagation

Allocators flow through Zig codebases as explicit parameters. The standard convention places the allocator as the first parameter, ordered from most general to most specific dependencies.[^5]

```zig
fn processData(allocator: std.mem.Allocator, data: []const u8) !Result {
    const buffer = try allocator.alloc(u8, data.len * 2);
    defer allocator.free(buffer);
    // Process data...
}
```

For long-lived structs, allocators may be stored as fields to simplify cleanup:

```zig
const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator) !Parser {
        return .{
            .allocator = allocator,
            .tokens = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.tokens.deinit();
        // Allocator stored for cleanup
    }
};
```

The trade-off: storing the allocator increases struct size but eliminates the need to pass it to `deinit()`. TigerBeetle recommends meaningful allocator parameter names—`gpa` for general-purpose allocators requiring explicit cleanup, `arena` for bulk cleanup contexts—to communicate ownership semantics.[^5]

### Ownership Semantics

Ownership in Zig is explicit and documented by convention. Three patterns dominate production codebases:

**Caller-Owns Pattern** — Caller allocates and retains ownership; the function uses but does not free the memory.

```zig
/// Processes data into caller-provided buffer.
/// Caller retains ownership of `buffer`.
fn processInPlace(buffer: []u8, data: []const u8) void {
    @memcpy(buffer[0..data.len], data);
}
```

**Callee-Returns-Owned Pattern** — Function allocates and returns memory; caller must free it.

```zig
/// Allocates and returns a buffer. Caller owns returned memory
/// and must free it with the same allocator.
fn allocateResult(allocator: std.mem.Allocator, size: usize) ![]u8 {
    return try allocator.alloc(u8, size);
}

// Usage
const result = try allocateResult(allocator, 100);
defer allocator.free(result); // Caller must free
```

**Init/Deinit Pairs** — RAII-like pattern where `init()` allocates and `deinit()` releases. This is the dominant pattern for structs managing resources.

```zig
const Resource = struct {
    allocator: std.mem.Allocator,
    data: []u8,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Resource {
        return .{
            .allocator = allocator,
            .data = try allocator.alloc(u8, size),
        };
    }

    pub fn deinit(self: *Resource) void {
        self.allocator.free(self.data);
    }
};

// Usage
var resource = try Resource.init(allocator, 1024);
defer resource.deinit();
```

TigerBeetle also uses an "out-pointer" style for performance-critical code, where `init()` takes `self: *Resource` and modifies it in place, eliminating intermediate copies and ensuring pointer stability.[^5]

### Cleanup Idioms

Zig's `defer` and `errdefer` keywords provide deterministic cleanup without runtime overhead.

**defer** executes cleanup code when leaving scope, regardless of how the scope exits (return, break, or fall-through). Defer statements execute in LIFO order. Best practice: place `defer` immediately after allocation.

```zig
const data = try allocator.alloc(u8, 100);
defer allocator.free(data); // Executes when scope exits

const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();
```

**errdefer** executes cleanup only when the scope exits via error return. This is essential for multi-step initialization where later steps might fail.

```zig
fn createResources(allocator: std.mem.Allocator) !Resources {
    const buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(buffer1); // Only on error

    const buffer2 = try allocator.alloc(u8, 200);
    errdefer allocator.free(buffer2); // Only on error

    return .{ .buf1 = buffer1, .buf2 = buffer2 };
    // Success: both buffers returned, no cleanup
}
```

TigerBeetle's manifest initialization demonstrates cascading errdefer for nested structures: if level initialization fails midway, all previously initialized levels are cleaned up automatically.[^6]

**Arena vs Manual Cleanup** — Use arenas for request-scoped allocations where all memory is freed together. Use manual cleanup (defer/errdefer) when individual allocations have different lifetimes or memory must be reclaimed incrementally.

## Code Examples

### Arena Pattern for Request Handling

```zig
const std = @import("std");

fn handleRequest(allocator: std.mem.Allocator, req_id: u32, data: []const u8) ![]u8 {
    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();

    try parts.append("Processing request ");
    const id_str = try std.fmt.allocPrint(allocator, "{}", .{req_id});
    defer allocator.free(id_str);
    try parts.append(id_str);

    // Concatenate parts
    var total_len: usize = 0;
    for (parts.items) |part| total_len += part.len;

    const result = try allocator.alloc(u8, total_len);
    var offset: usize = 0;
    for (parts.items) |part| {
        @memcpy(result[offset..][0..part.len], part);
        offset += part.len;
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    // Process multiple requests
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        defer _ = arena.reset(.{ .retain_with_limit = 4096 });
        const response = try handleRequest(arena.allocator(), i, "data");
        std.debug.print("{s}\n", .{response});
        // No individual frees needed—arena handles it
    }
}
```

This demonstrates arena reuse with `reset()`, retaining small allocations for performance. Ghostty uses this pattern for configuration parsing, while ZLS uses it for argument processing.[^2][^3]

### FixedBufferAllocator for Stack-Based Operations

```zig
const std = @import("std");

fn formatMessage(buffer: []u8, name: []const u8, value: i32) ![]const u8 {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    const allocator = fba.allocator();

    return try std.fmt.allocPrint(
        allocator,
        "User: {s}, Score: {}",
        .{ name, value }
    );
}

pub fn main() !void {
    var stack_buffer: [256]u8 = undefined;

    const msg1 = try formatMessage(&stack_buffer, "Alice", 100);
    std.debug.print("{s}\n", .{msg1});

    // Reuse same buffer (overwrites previous content)
    const msg2 = try formatMessage(&stack_buffer, "Bob", 200);
    std.debug.print("{s}\n", .{msg2});
}
```

FixedBufferAllocator eliminates heap allocations entirely, offering predictable performance with no system calls. The Zig test runner uses this pattern for command-line processing.[^4]

### Error-Path Cleanup with errdefer

```zig
const std = @import("std");

const Database = struct {
    connection: []u8,
    buffer: []u8,
    cache: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, conn_str: []const u8) !Database {
        const connection = try allocator.alloc(u8, conn_str.len);
        errdefer allocator.free(connection);
        @memcpy(connection, conn_str);

        const buffer = try allocator.alloc(u8, 1024);
        errdefer allocator.free(buffer);

        const cache = try allocator.alloc(u8, 2048);
        errdefer allocator.free(cache);

        if (conn_str.len > 100) {
            return error.ConnectionFailed; // Automatic cleanup via errdefer
        }

        return .{
            .connection = connection,
            .buffer = buffer,
            .cache = cache,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        self.allocator.free(self.cache);
        self.allocator.free(self.buffer);
        self.allocator.free(self.connection);
    }
};
```

If initialization fails after allocating `connection` and `buffer`, both are automatically freed by their respective `errdefer` statements. TigerBeetle's state machine initialization uses this cascading pattern for complex multi-step setup.[^7]

## Common Pitfalls

### Forgetting to Free Allocations

```zig
// ❌ WRONG: Leak on early return
fn leakyFunction(allocator: std.mem.Allocator) !void {
    const data = try allocator.alloc(u8, 100);
    if (someCondition) return error.Failed; // Leak!
}

// ✅ CORRECT: defer ensures cleanup
fn fixedFunction(allocator: std.mem.Allocator) !void {
    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);
    if (someCondition) return error.Failed; // No leak
}
```

**Prevention:** Place `defer allocator.free(data)` immediately after allocation. TigerBeetle's style guide recommends grouping allocations with their defer statements using newlines to make leaks visible during code review.[^5]

### Freeing with the Wrong Allocator

```zig
// ❌ WRONG: Wrong allocator
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
const data = try arena.allocator().alloc(u8, 100);
gpa.allocator().free(data); // Wrong allocator!

// ✅ CORRECT: Use same allocator
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
const allocator = arena.allocator();
const data = try allocator.alloc(u8, 100);
// Rely on arena.deinit() or use same allocator
```

**Prevention:** Store the allocator in a local variable and use it consistently. For arenas, rely on bulk cleanup via `deinit()`.

### Use-After-Free

```zig
// ❌ WRONG: Use after free
var data = try allocator.alloc(u8, 100);
allocator.free(data);
data[0] = 42; // Use after free!

// ✅ CORRECT: defer delays free until end of scope
var data = try allocator.alloc(u8, 100);
defer allocator.free(data);
data[0] = 42; // Still valid
```

**Detection:** Use `GeneralPurposeAllocator` during development—it never reuses memory addresses, helping catch use-after-free bugs.

### Returning Pointers to Stack Memory

```zig
// ❌ WRONG: Dangling pointer
fn createData() *u8 {
    var data: u8 = 42;
    return &data; // Pointer to stack memory!
}

// ✅ CORRECT: Heap allocation, caller owns
fn createData(allocator: std.mem.Allocator) !*u8 {
    const data = try allocator.create(u8);
    data.* = 42;
    return data; // Caller must destroy()
}
```

**Prevention:** Use heap allocation for any data outliving the function scope. Document ownership clearly.

## In Practice

Production codebases demonstrate these patterns at scale:

**TigerBeetle** enforces static allocation: all memory must be allocated at startup, with no dynamic allocation during operation.[^5] This prevents runtime surprises and forces upfront memory planning, critical for financial database correctness. Their manifest initialization shows cascading errdefer cleanup for complex nested structures.[^6]

**Ghostty** uses `ArenaAllocator` for terminal configuration parsing, simplifying cleanup for temporary parsing state.[^2]

**Bun** implements custom allocators for JavaScript runtime performance, demonstrating zero-sized type optimization for nullable allocators and atomic operations for thread-safe allocation.[^8]

**ZLS** (Zig Language Server) conditionally selects debug vs release allocators based on build configuration, balancing safety and performance.[^3]

These exemplars share common patterns: allocator-first parameter ordering, meaningful allocator names (`gpa`, `arena`), immediate defer placement, and comprehensive errdefer for multi-step initialization.

## Summary

Zig's explicit memory management model eliminates hidden allocations, making ownership and lifetime visible in the code. The uniform `Allocator` interface enables compile-time polymorphism, allowing seamless switching between allocators for different use cases.

Key principles:
- **Allocators are explicit parameters**—no hidden allocations
- **Choose allocators by use case**—arena for request scoping, fixed-buffer for bounded performance, GPA for safety
- **Ownership is documented**—caller-owns, callee-returns-owned, or init/deinit pairs
- **Cleanup is deterministic**—defer for guaranteed cleanup, errdefer for error paths
- **Memory is either managed or unmanaged** (✅ 0.15+)—unmanaged containers require explicit allocator passing

Understanding these patterns provides the foundation for containers, I/O, and concurrency covered in subsequent chapters.

## References

1. [Learning Zig - Heap Memory & Allocators](https://www.openmymind.net/learning_zig/heap_memory/)
2. [Ghostty Config.zig - ArenaAllocator usage](https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig#L17)
3. [ZLS main.zig - Arena for argument parsing](https://github.com/zigtools/zls/blob/master/src/main.zig#L233-238)
4. [Zig test runner - FixedBufferAllocator](https://github.com/ziglang/zig/blob/master/lib/compiler/test_runner.zig)
5. [TigerBeetle TIGER_STYLE.md - Memory conventions](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
6. [TigerBeetle manifest.zig - errdefer cleanup](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/manifest.zig#L178-192)
7. [TigerBeetle state_machine.zig - Cascading cleanup](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1052-1057)
8. [Bun allocators.zig - Custom allocators](https://github.com/oven-sh/bun/blob/main/src/allocators.zig)
9. [zig.guide - Allocators](https://zig.guide/standard-library/allocators/)
10. [Leveraging Zig's Allocators](https://www.openmymind.net/Leveraging-Zigs-Allocators/)
11. [Introduction to Zig - Memory and Allocators](https://pedropark99.github.io/zig-book/Chapters/01-memory.html)
12. [Defeating Memory Leaks With Zig Allocators](https://tgmatos.github.io/defeating-memory-leaks-with-zig-allocators/)
13. [Zig 0.14.0 Release Notes](https://ziglang.org/download/0.14.0/release-notes.html)

[^1]: [TigerBeetle state_machine.zig - Aligned allocation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1051)
[^2]: [Ghostty Config.zig](https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig#L17)
[^3]: [ZLS main.zig](https://github.com/zigtools/zls/blob/master/src/main.zig#L233-238)
[^4]: [zig.guide - Allocators](https://zig.guide/standard-library/allocators/)
[^5]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^6]: [TigerBeetle manifest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/manifest.zig#L178-192)
[^7]: [TigerBeetle state_machine.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1052-1057)
[^8]: [Bun allocators.zig](https://github.com/oven-sh/bun/blob/main/src/allocators.zig)
