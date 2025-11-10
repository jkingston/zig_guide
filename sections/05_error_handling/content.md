# Error Handling & Resource Cleanup

> **TL;DR for experienced developers:**
> - **Error unions:** `!T` syntax (e.g., `![]u8` = could return error or slice)
> - **Propagate errors:** `try operation()` (unwraps or returns error to caller)
> - **Handle errors:** `operation() catch |err| { ... }` or `catch default_value`
> - **Cleanup:** `defer cleanup()` runs at scope exit (LIFO order)
> - **Error-only cleanup:** `errdefer cleanup()` runs only if function returns error
> - **Definitive resource cleanup chapter** - other chapters reference this
> - **Jump to:** [Error sets §5.2](#error-sets-and-error-unions) | [try/catch §5.3](#error-propagation-with-try-and-catch) | [defer/errdefer §5.4](#resource-cleanup-with-defer)

## Overview

Zig approaches error handling and resource cleanup as inseparable concerns. Unlike languages that hide errors behind exceptions or implicit memory management, Zig makes failure modes explicit through compile-time verified error sets and provides deterministic cleanup through `defer` and `errdefer` statements.[^1] This design eliminates entire classes of bugs: uncaught exceptions become compile errors, resource leaks are visible in code review, and error paths are testable like any other code path.

This chapter demonstrates how Zig's error handling mechanisms integrate with resource management to create robust, maintainable systems. The patterns shown here build on Chapter 3's allocator concepts and appear throughout production codebases like TigerBeetle, Ghostty, and Bun.

Error handling in Zig serves three critical purposes:

1. **Compile-time safety** — All possible errors are tracked in function signatures, preventing silent failures
2. **Explicit control flow** — No hidden jumps or unwinding; error propagation is visible in source code
3. **Zero-cost abstraction** — Error handling compiles to simple branch instructions with no runtime overhead[^1]

The research backing TigerBeetle's error handling philosophy found that 92% of catastrophic system failures result from incorrect handling of explicitly signaled errors.[^2] Zig's design prevents these failures by making error handling mandatory and verifiable.

## Core Concepts

### Error Sets and Error Unions

Zig defines errors through **error sets** — named collections of error values defined at compile time:

```zig
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};
```

Error sets are first-class types that can be merged using the `||` operator:

```zig
const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

const AllErrors = FileError || ParseError;
```

Functions return **error unions** using the `!` syntax, which combines an error set with a success type:

```zig
fn readFile(path: []const u8) FileError![]u8 {
    // Returns either a FileError or []u8
}
```

The `!` operator creates an error union type. When used without an explicit error set, Zig infers all possible errors the function can return:

```zig
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}
```

The compiler automatically infers `error{UnexpectedEOF, InvalidSyntax}!u32` as the return type.[^1]

**Trade-offs of inferred error sets:**

- ✅ Convenience — no manual error set declaration needed
- ✅ Automatic updates — adding new errors does not require signature changes
- ❌ Documentation — less clear what errors callers need to handle
- ❌ API stability — error set changes are not visible in function signature

TigerBeetle's style guide mandates explicit error sets in public APIs to ensure clear contracts and prevent accidental API changes.[^3] For internal functions where the error set is obvious from context, inference provides convenient brevity.

### Error Propagation with try and catch

The `try` keyword propagates errors up the call stack:

```zig
// Explicit form:
const result = operation() catch |err| return err;

// Equivalent shorthand:
const result = try operation();
```

Use `try` when the current function cannot meaningfully handle the error and must delegate recovery to its caller. This is appropriate for functions in the middle of a call chain where higher-level code has more context for recovery decisions.

The `catch` keyword enables error handling with recovery strategies:

```zig
// Provide default value
const count = parseNumber(input) catch 0;

// Capture and log error
const file = openFile(path) catch |err| {
    log.err("Failed to open {s}: {s}", .{path, @errorName(err)});
    return err;
};

// Error-specific handling
const data = queryDatabase(id) catch |err| switch (err) {
    error.Timeout => {
        log.warn("Retrying after timeout", .{});
        return err;
    },
    error.QueryFailed => {
        log.info("Using cached data", .{});
        return cached_data;
    },
    else => return err,
};
```

The `@errorName` builtin converts error values to their string representation for logging and diagnostics.[^1]

**Best practice:** Add context when catching errors before re-propagating. TigerBeetle's style guide emphasizes: "Always motivate, always say why."[^3] When error handling code catches and re-throws an error, it should document why the error occurred and what was being attempted:

```zig
const result = queryDatabase(id) catch |err| {
    log.err("Database query failed for user {d}: {s}", .{id, @errorName(err)});
    return err; // Propagate with logged context
};
```

### Resource Cleanup with defer

The `defer` statement schedules code to execute when the current scope exits, in Last-In-First-Out (LIFO) order:

```zig
fn demonstrateDefer() void {
    var r1 = Resource.init(1);
    defer r1.deinit(); // Executes third (LIFO)

    var r2 = Resource.init(2);
    defer r2.deinit(); // Executes second

    var r3 = Resource.init(3);
    defer r3.deinit(); // Executes first

    // Do work...
    // Cleanup happens in order: r3, r2, r1
}
```

Why LIFO order? Resources are often acquired in dependency order — later resources depend on earlier ones. Reverse order ensures dependents are cleaned up before their dependencies, preventing use-after-free errors.

**TigerBeetle pattern** — Group resource operations visually:

```zig
// Preferred style from TIGER_STYLE.md:
const buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer);

const metadata = try allocator.alloc(Metadata, count);
defer allocator.free(metadata);
```

Use newlines to group allocation and deallocation, making leaks easier to spot in code review.[^3]

### Conditional Cleanup with errdefer

The `errdefer` statement only executes if the function returns an error:

```zig
fn allocateResource(allocator: Allocator) !Resource {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Only if subsequent errors occur

    const metadata = try allocator.alloc(Metadata, 10);
    errdefer allocator.free(metadata);

    return Resource{
        .buffer = buffer,
        .metadata = metadata,
    };
}
```

If the function returns successfully, `errdefer` blocks do not execute — the caller receives the resources and becomes responsible for cleanup. If any operation fails, all preceding `errdefer` statements run in LIFO order, ensuring partial initialization is properly cleaned up.

Functions that allocate resources internally often need both `defer` and `errdefer`:

```zig
fn processData(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u8, 128);
    errdefer allocator.free(buffer); // Cleanup if error occurs
    defer allocator.free(buffer);     // Cleanup on success too

    var resource = try Resource.init(allocator);
    errdefer resource.deinit();
    defer resource.deinit();

    // Use resources...
    // If error: errdefer runs, defer skipped
    // If success: defer runs, errdefer skipped
}
```

Both statements are necessary because:
- `errdefer` handles partial initialization failures
- `defer` handles normal cleanup at function exit

Ghostty demonstrates progressive cleanup for multi-stage allocations:

```zig
// src/unicode/lut.zig:114-119
const stage1_owned = try stage1.toOwnedSlice(alloc);
errdefer alloc.free(stage1_owned);
const stage2_owned = try stage2.toOwnedSlice(alloc);
errdefer alloc.free(stage2_owned);
const stage3_owned = try stage3.toOwnedSlice(alloc);
errdefer alloc.free(stage3_owned);
```

Each allocation adds an `errdefer` ensuring that if any subsequent allocation fails, all previously allocated memory is freed.[^4]

### The anyerror Type

The `anyerror` type represents the union of all possible errors in a program. It should be used sparingly:

**When to use:**
- Generic error handling utilities
- Error logging and telemetry infrastructure
- Callbacks with unknown error types

**When NOT to use:**
- Public API boundaries (prevents compile-time error exhaustiveness)
- Performance-critical paths (larger type, less optimization)

TigerBeetle uses `anyerror` for error accumulation across multiple operation types:

```zig
// src/multiversion.zig:693
err: anyerror,

fn handle_error(self: *MultiversionOS, result: anyerror) void {
    // Generic error handling for multiple operation types
}
```

This pattern is appropriate for internal error aggregation where the specific error set varies by operation.[^5]

### Allocator Error Handling

Building on Chapter 3's allocator patterns, all allocator operations can fail with `error.OutOfMemory`:

```zig
const buffer = allocator.alloc(u8, size) catch |err| {
    log.err("Allocation failed: {s}", .{@errorName(err)});
    return err;
};
defer allocator.free(buffer);
```

**Design principle:** Never ignore allocation errors. Zig has no hidden allocations or exceptions, making error handling explicit and auditable.

Arena allocators simplify error handling by deferring all cleanup to a single point:

```zig
fn processWithArena(parent_allocator: Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit(); // Single cleanup for all allocations

    const buffer1 = try arena.allocator().alloc(u8, 100);
    const buffer2 = try arena.allocator().alloc(u32, 50);
    const buffer3 = try arena.allocator().alloc(u64, 25);

    // Use buffers...
    // All freed automatically by arena.deinit()
}
```

If any allocation fails, the function returns early and the `defer` statement releases all previously allocated memory.[^1]

## Code Examples

### Example 1: Basic Error Sets and Propagation

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_basic_errors.zig`

This example demonstrates error set definition, merging, and basic propagation:

```zig
const std = @import("std");

// Define custom error sets
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};

const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

// Error sets can be merged
const AllErrors = FileError || ParseError;

// Function returning explicit error union
fn openFile(path: []const u8) FileError!void {
    if (std.mem.eql(u8, path, "")) {
        return error.InvalidFormat;
    }
    if (std.mem.eql(u8, path, "/forbidden")) {
        return error.AccessDenied;
    }
    if (std.mem.eql(u8, path, "/missing")) {
        return error.NotFound;
    }
    std.debug.print("File opened: {s}\n", .{path});
}

// Function with inferred error set
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}

pub fn main() !void {
    // Using try - propagates error if it occurs
    try openFile("/valid/path");

    // Using catch - provides default behavior on error
    openFile("/forbidden") catch {
        std.debug.print("Access denied, using default behavior\n", .{});
    };

    // Capturing the error value
    openFile("/missing") catch |err| {
        std.debug.print("Error occurred: {s}\n", .{@errorName(err)});
    };

    // Merged error sets
    const merged_fn = struct {
        fn process() AllErrors!void {
            try openFile("/valid");
            _ = try parseData("[1]");
        }
    }.process;
    try merged_fn();
}
```

Run with `zig run example_basic_errors.zig`.

**Key concepts demonstrated:**
- Explicit error set definition with domain-specific errors
- Error set merging to combine failure modes
- Inferred error sets for convenience
- Three error handling strategies: `try`, `catch`, and `catch |err|`
- Using `@errorName` for diagnostics

### Example 2: Error Propagation Patterns

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig`

This example shows practical error propagation strategies:

```zig
const std = @import("std");

const DatabaseError = error{
    ConnectionFailed,
    QueryFailed,
    Timeout,
};

fn queryDatabase(id: u32) DatabaseError![]const u8 {
    if (id == 0) return error.InvalidInput;
    if (id > 1000) return error.QueryFailed;
    return "result";
}

// Simple propagation
fn getUserData(user_id: u32) ![]const u8 {
    const data = try queryDatabase(user_id);
    return data;
}

// Catching and adding context
fn validateAndQuery(input: ?u32) ![]const u8 {
    const id = input orelse {
        std.debug.print("Validation failed: missing user ID\n", .{});
        return error.MissingField;
    };

    const result = queryDatabase(id) catch |err| {
        std.debug.print("Database query failed for user {d}: {s}\n",
            .{id, @errorName(err)});
        return err;
    };

    return result;
}

// Error-specific handling with switch
fn processRequest(user_id: u32) !void {
    const data = queryDatabase(user_id) catch |err| switch (err) {
        error.ConnectionFailed => {
            std.debug.print("Retrying after connection failure...\n", .{});
            return err;
        },
        error.Timeout => {
            std.debug.print("Request timed out, will retry later\n", .{});
            return err;
        },
        error.QueryFailed => {
            std.debug.print("Query failed, using cached data\n", .{});
            return; // Recovered with fallback
        },
        else => return err,
    };

    std.debug.print("Received data: {s}\n", .{data});
}
```

**Key concepts demonstrated:**
- Simple error propagation with `try`
- Adding context before re-propagating errors
- Error-specific handling with `switch`
- Recovery strategies vs fail-fast patterns
- Using optionals (`?T`) alongside error unions

### Example 3: Resource Cleanup with defer and errdefer

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig`

This example demonstrates deterministic resource cleanup:

```zig
const std = @import("std");

const Resource = struct {
    id: u32,
    name: []const u8,

    fn init(id: u32, name: []const u8) Resource {
        std.debug.print("Resource {d} ({s}) initialized\n", .{id, name});
        return Resource{ .id = id, .name = name };
    }

    fn deinit(self: *Resource) void {
        std.debug.print("Resource {d} ({s}) cleaned up\n", .{self.id, self.name});
    }
};

// Demonstrate defer - LIFO execution order
fn demonstrateDefer() void {
    var r1 = Resource.init(1, "first");
    defer r1.deinit(); // Executes last (LIFO)

    var r2 = Resource.init(2, "second");
    defer r2.deinit(); // Executes second

    var r3 = Resource.init(3, "third");
    defer r3.deinit(); // Executes first

    std.debug.print("All resources initialized\n", .{});
    // Cleanup happens in reverse order: r3, r2, r1
}

// Demonstrate errdefer - only executes on error
fn initializeWithErrorHandling(
    allocator: std.mem.Allocator,
    should_fail: bool,
) ![]Resource {
    var list = try allocator.alloc(Resource, 3);
    errdefer allocator.free(list);

    list[0] = Resource.init(10, "alpha");
    errdefer list[0].deinit();

    list[1] = Resource.init(11, "beta");
    errdefer list[1].deinit();

    if (should_fail) {
        std.debug.print("Simulating failure...\n", .{});
        return error.InitFailed;
    }

    list[2] = Resource.init(12, "gamma");
    errdefer list[2].deinit();

    return list;
}

// Both defer and errdefer
fn complexCleanup(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 128);
    errdefer allocator.free(buffer);
    defer allocator.free(buffer);

    var resource = Resource.init(20, "complex");
    errdefer resource.deinit();
    defer resource.deinit();

    std.debug.print("Resources allocated successfully\n", .{});
}
```

Run the full example to see LIFO cleanup order and error-triggered cleanup.

**Key concepts demonstrated:**
- LIFO execution order of `defer` statements
- `errdefer` executing only on error paths
- Combining both for complete cleanup coverage
- Progressive cleanup for multi-step initialization
- Cleanup on partial initialization failure

### Example 4: Testing Error Paths

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_testing_errors.zig`

This example shows systematic error path testing with `std.testing.FailingAllocator`:

```zig
const std = @import("std");
const testing = std.testing;

fn createNestedStructure(allocator: std.mem.Allocator) !struct {
    data: []u32,
    metadata: []u8,
} {
    const data = try allocator.alloc(u32, 10);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(u8, 5);
    errdefer allocator.free(metadata);

    return .{ .data = data, .metadata = metadata };
}

test "errdefer cleanup on partial initialization" {
    var failing_allocator_state = testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 1 },
    );
    const failing_alloc = failing_allocator_state.allocator();

    const result = createNestedStructure(failing_alloc);
    try testing.expectError(error.OutOfMemory, result);

    // First allocation should have been cleaned up by errdefer
    try testing.expectEqual(1, failing_allocator_state.allocations);
    try testing.expectEqual(1, failing_allocator_state.deallocations);
    try testing.expect(
        failing_allocator_state.allocated_bytes == failing_allocator_state.freed_bytes
    );
}

test "systematic error path testing" {
    // Test all possible error paths by failing at each allocation point
    for (0..3) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index },
        );
        const failing_alloc = failing_state.allocator();

        _ = createNestedStructure(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no memory leaks occurred
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };

        // If reached, allocation succeeded; clean up
        const result = try createNestedStructure(failing_alloc);
        defer {
            failing_alloc.free(result.data);
            failing_alloc.free(result.metadata);
        }
    }
}
```

Run with `zig test example_testing_errors.zig`.

**Key concepts demonstrated:**
- Using `FailingAllocator` to inject allocation failures
- Systematic testing of all error paths
- Verifying `errdefer` cleanup with allocation metrics
- Testing partial initialization scenarios
- Using `std.testing.expectError` for error assertions

**FailingAllocator configuration:**
- `fail_index` — Number of successful allocations before failure
- `resize_fail_index` — Number of successful resizes before failure
- Tracks `allocations`, `deallocations`, `allocated_bytes`, `freed_bytes`[^6]

### Example 5: Allocator Error Handling

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig`

This example demonstrates practical allocator error handling patterns:

```zig
const std = @import("std");

// Graceful degradation on allocation failure
fn processWithFallback(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const buffer = allocator.alloc(u8, size) catch |err| {
        std.debug.print("Allocation of {d} bytes failed\n", .{size});

        // Fall back to smaller allocation
        const fallback_size = size / 2;
        return allocator.alloc(u8, fallback_size) catch {
            std.debug.print("Fallback also failed\n", .{});
            return err;
        };
    };

    return buffer;
}

// Container with complex cleanup
const Container = struct {
    items: std.ArrayList([]const u8),
    scratch: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Container {
        var items = std.ArrayList([]const u8).init(allocator);
        errdefer items.deinit();

        const scratch = try allocator.alloc(u8, 1024);
        errdefer allocator.free(scratch);

        return Container{
            .items = items,
            .scratch = scratch,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Container) void {
        for (self.items.items) |item| {
            self.allocator.free(item);
        }
        self.items.deinit();
        self.allocator.free(self.scratch);
    }

    fn addItem(self: *Container, data: []const u8) !void {
        const copy = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(copy);

        try self.items.append(copy);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Memory leaked!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    var container = try Container.init(allocator);
    defer container.deinit();

    try container.addItem("first");
    try container.addItem("second");
    try container.addItem("third");
}
```

**Key concepts demonstrated:**
- Graceful degradation with fallback allocations
- Multi-resource container initialization
- Complex cleanup in `deinit` methods
- Using `errdefer` in methods that modify state
- GPA leak detection with `defer` block

### Example 6: Complex Error Handling

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_complex.zig`

This example shows transaction-like error handling with rollback:

```zig
const Transaction = struct {
    allocator: std.mem.Allocator,
    operations: std.ArrayList(Operation),
    committed: bool,

    const Operation = struct {
        id: u32,
        data: []u8,
    };

    fn init(allocator: std.mem.Allocator) Transaction {
        return Transaction{
            .allocator = allocator,
            .operations = std.ArrayList(Operation).init(allocator),
            .committed = false,
        };
    }

    fn deinit(self: *Transaction) void {
        if (!self.committed) {
            // Rollback - free all operations
            std.debug.print("Rolling back {d} operations\n",
                .{self.operations.items.len});
            for (self.operations.items) |op| {
                self.allocator.free(op.data);
            }
        }
        self.operations.deinit();
    }

    fn addOperation(self: *Transaction, id: u32, size: usize) !void {
        const data = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(data);

        const op = Operation{ .id = id, .data = data };
        try self.operations.append(op);
    }

    fn commit(self: *Transaction) !void {
        // Validate all operations
        for (self.operations.items) |op| {
            if (op.data.len == 0) return error.InvalidOperation;
        }

        self.committed = true;

        // Clean up operation data
        for (self.operations.items) |op| {
            self.allocator.free(op.data);
        }
        self.operations.clearRetainingCapacity();
    }
};
```

**Key concepts demonstrated:**
- Transaction pattern with commit/rollback semantics
- State-dependent cleanup in `deinit`
- Multi-step validation before commit
- Progressive resource accumulation with cleanup
- Using boolean flags to control cleanup behavior

## Common Pitfalls

### Pitfall 1: Missing errdefer in Multi-Allocation Functions

**Problem:**

```zig
fn createPair(allocator: Allocator) !Pair {
    const first = try allocator.alloc(u8, 100);
    const second = try allocator.alloc(u8, 200); // If this fails, first leaks!

    return Pair{ .first = first, .second = second };
}
```

**Solution:**

```zig
fn createPair(allocator: Allocator) !Pair {
    const first = try allocator.alloc(u8, 100);
    errdefer allocator.free(first); // Cleanup if subsequent allocations fail

    const second = try allocator.alloc(u8, 200);
    errdefer allocator.free(second);

    return Pair{ .first = first, .second = second };
}
```

**Why it matters:** Without `errdefer`, partial initialization causes memory leaks when later allocations fail. This is the most common source of leaks in Zig code.

### Pitfall 2: Confusing defer and errdefer Semantics

**Problem:**

```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer); // Wrong! Frees even when returning buffer

    // ... work that might fail ...

    return Result{ .data = buffer }; // Buffer already scheduled for freeing!
}
```

**Solution A** — Remove `defer` if returning resource to caller:

```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Only free on error

    // ... work that might fail ...

    return Result{ .data = buffer }; // Caller now owns buffer
}
```

**Solution B** — Use both if consuming resource internally:

```zig
fn process(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Free on error
    defer allocator.free(buffer);     // Free on success

    // ... work that might fail ...
    // Buffer is always freed before function returns
}
```

### Pitfall 3: Ignoring Error Context

**Problem:**

```zig
fn loadFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1024 * 1024);
}
```

If this fails, users see only "FileNotFound" without knowing which file was attempted.

**Solution:**

```zig
fn loadFile(path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        log.err("Failed to open file '{s}': {s}", .{path, @errorName(err)});
        return err;
    };
    defer file.close();

    return file.readToEndAlloc(allocator, 1024 * 1024) catch |err| {
        log.err("Failed to read file '{s}': {s}", .{path, @errorName(err)});
        return err;
    };
}
```

**Best practice:** Every `catch` should add context before re-propagating. This creates comprehensive error trails for debugging.

### Pitfall 4: Leaking Resources in Loops

**Problem:**

```zig
fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        const buffer = try allocator.alloc(u8, item.size);
        defer allocator.free(buffer); // Deferred until function exit, not loop iteration!

        try processItem(buffer, item);
    }
}
```

`defer` executes at function scope, not loop scope, causing accumulation of allocations.

**Solution A** — Extract loop body into function:

```zig
fn processOne(allocator: Allocator, item: Item) !void {
    const buffer = try allocator.alloc(u8, item.size);
    defer allocator.free(buffer); // Now properly scoped

    try processItem(buffer, item);
}

fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        try processOne(allocator, item);
    }
}
```

**Solution B** — Manual scope with explicit free:

```zig
fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        const buffer = try allocator.alloc(u8, item.size);
        errdefer allocator.free(buffer);

        try processItem(buffer, item);

        allocator.free(buffer); // Explicit cleanup within loop
    }
}
```

### Pitfall 5: Not Testing Error Paths

**Problem:**

```zig
fn createResource(allocator: Allocator) !Resource {
    const data = try allocator.alloc(u8, 1024);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(Metadata, 10);
    errdefer allocator.free(metadata); // This errdefer is NEVER TESTED

    return Resource{ .data = data, .metadata = metadata };
}
```

The second `errdefer` only executes if allocation succeeds then a subsequent operation fails. Without tests, this path may be broken.

**Solution:**

```zig
test "createResource handles allocation failure" {
    for (0..2) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index },
        );
        const failing_alloc = failing_state.allocator();

        _ = createResource(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no leaks
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };
    }
}
```

**Best practice:** Use `FailingAllocator` to test every allocation failure point systematically. TigerBeetle's philosophy: "Assertions are a force multiplier for discovering bugs by fuzzing."[^3]

## In Practice

### TigerBeetle — Explicit Error Sets and Safety

TigerBeetle's TIGER_STYLE.md establishes foundational error handling principles that inform the entire codebase.[^3]

**All Errors Must Be Handled**

Research on production failures found that 92% of catastrophic system failures result from incorrect handling of explicitly signaled errors.[^2] TigerBeetle mandates that all errors must be handled — no silent failures.

**Assertions vs Errors**

TigerBeetle distinguishes between two failure classes:

- **Assertions** — Detect programmer errors (bugs). Must crash immediately with `std.debug.assert`.
- **Errors** — Handle operating errors (expected failures). Must be handled gracefully.

Example from TigerBeetle:

```zig
// Assertion - programmer error, must never happen
assert(index < array.len);

// Error - operating error, must be handled
const file = std.fs.cwd().openFile(path, .{}) catch |err| {
    log.err("Failed to open {s}: {s}", .{path, @errorName(err)});
    return err;
};
```

**Explicit Error Sets in Public APIs**

TigerBeetle mandates explicit error sets to provide clear contracts and prevent accidental API changes:

```zig
// src/io/linux.zig:1220
pub const TimeoutError = error{Canceled} || posix.UnexpectedError;
```

This pattern combines custom errors with standard library error sets to create precise type unions.[^7]

**Pair Assertions**

From TIGER_STYLE.md: "Pair assertions. For every property you want to enforce, try to find at least two different code paths where an assertion can be added."[^3]

Applied to error handling:

```zig
fn writeData(data: []const u8) !void {
    assert(validate(data)); // Pre-condition
    try disk.write(data);
}

fn readData(buffer: []u8) !void {
    try disk.read(buffer);
    assert(validate(buffer)); // Post-condition
}
```

### Ghostty — Progressive Cleanup Patterns

Ghostty demonstrates sophisticated `errdefer` usage for complex initialization.[^4]

**Multi-Stage Resource Acquisition:**

```zig
// src/unicode/lut.zig:114-125
const stage1_owned = try stage1.toOwnedSlice(alloc);
errdefer alloc.free(stage1_owned);
const stage2_owned = try stage2.toOwnedSlice(alloc);
errdefer alloc.free(stage2_owned);
const stage3_owned = try stage3.toOwnedSlice(alloc);
errdefer alloc.free(stage3_owned);

return .{
    .stage1 = stage1_owned,
    .stage2 = stage2_owned,
    .stage3 = stage3_owned,
};
```

Each allocation adds progressive cleanup — if `stage3` allocation fails, both `stage1` and `stage2` are freed automatically.

**String Duplication with Early Exit:**

```zig
// src/config/RepeatableStringMap.zig:43-56
const key_copy = try alloc.dupeZ(u8, key);
errdefer alloc.free(key_copy);

if (val.len == 0) {
    _ = self.map.orderedRemove(key_copy);
    alloc.free(key_copy);
    return;
}

const val_copy = try alloc.dupeZ(u8, val);
errdefer alloc.free(val_copy);

try self.map.put(alloc, key_copy, val_copy);
```

This demonstrates early-exit cleanup combined with `errdefer` for complete lifecycle coverage.

**Complex Errdefer Blocks:**

```zig
// src/config/RepeatableStringMap.zig:60-70
errdefer {
    var it = map.iterator();
    while (it.next()) |entry| {
        alloc.free(entry.key_ptr.*);
        alloc.free(entry.value_ptr.*);
    }
    map.deinit(alloc);
}
```

The `errdefer` block can contain multiple statements, including loops, to perform complex cleanup.

### Bun — Cross-Platform Error Abstraction

Bun abstracts platform-specific error codes through unified error enums:

```zig
// src/sys.zig:21-33
pub const E = platform_defs.E;
pub const UV_E = platform_defs.UV_E;
pub const S = platform_defs.S;
pub const SystemErrno = platform_defs.SystemErrno;
```

This enables cross-platform error handling while maintaining type safety.[^8]

**Error Context Accumulation:**

```zig
// src/StandaloneModuleGraph.zig:723-729
var macho_file = bun.macho.MachoFile.init(
    bun.default_allocator,
    input_result.bytes.items,
    bytes.len,
) catch |err| {
    log.err("Failed to parse Mach-O file: {s}", .{@errorName(err)});
    return err;
};
```

Bun adds context to every error before propagating, creating comprehensive error trails for debugging.[^9]

### ZLS — Systematic Cleanup Chains

ZLS demonstrates progressive `defer` chains for complex pipelines:

```zig
// src/translate_c.zig:144-161
defer allocator.free(file_path);

const args = try collectCFlgsFrom(allocator, config, diag);
defer argv.deinit(allocator);

var poller: std.io.Poller(PollerFifo) = .init();
defer poller.deinit();
```

Each resource acquisition is immediately followed by its corresponding `defer`, ensuring resources are tracked correctly.[^10]

## Summary

Zig's error handling and resource cleanup mechanisms provide compile-time safety without runtime overhead. The key mental models are:

**Error Handling:**
1. **All errors are explicit** — Function signatures document all failure modes
2. **Errors are values** — No hidden control flow or exception unwinding
3. **Propagation is visible** — `try` and `catch` make error paths auditable
4. **Context is critical** — Add diagnostic information at each error boundary

**Resource Cleanup:**
1. **defer executes in LIFO order** — Resources cleaned up in reverse acquisition order
2. **errdefer only runs on error** — Enables proper cleanup of partial initialization
3. **Both may be needed** — Functions often need both `defer` and `errdefer`
4. **Scope matters** — `defer` runs at scope exit, not loop iteration

**Testing:**
1. **Error paths must be tested** — Use `FailingAllocator` to inject allocation failures
2. **Verify cleanup** — Check allocation metrics to detect leaks
3. **Test systematically** — Fail at each allocation point to verify `errdefer` chains

**Production Patterns:**
- Use explicit error sets in public APIs for clear contracts
- Add context when catching and re-propagating errors
- Group allocation and cleanup visually for code review
- Distinguish between programmer errors (assertions) and operating errors (error handling)
- Test error paths as thoroughly as success paths

When designing error handling:
- **For libraries:** Use explicit error sets to document contracts
- **For applications:** Balance explicitness with convenience using inferred error sets
- **For recovery:** Use `catch` with domain-specific logic
- **For propagation:** Use `try` when the caller has more context
- **For resources:** Always pair allocation with `defer` or `errdefer`

The combination of compile-time verified error sets and deterministic cleanup makes Zig programs robust by construction. Errors cannot be ignored, resources cannot be leaked unintentionally, and cleanup is auditable through code review. This design eliminates entire classes of production failures at compile time.

## References

1. [Zig Language Reference 0.15.2 — Errors](https://ziglang.org/documentation/0.15.2/#Errors)
2. Yuan, D., et al. "Simple Testing Can Prevent Most Critical Failures." OSDI 2014. [PDF](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf)
3. [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
4. [Ghostty src/unicode/lut.zig:114-125](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L125)
5. [TigerBeetle src/multiversion.zig:693](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig#L693)
6. [Zig Standard Library — std.testing.FailingAllocator](https://ziglang.org/documentation/0.15.2/std/#std.testing.FailingAllocator)
7. [TigerBeetle src/io/linux.zig:1220](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1220)
8. [Bun src/sys.zig:21-33](https://github.com/oven-sh/bun/blob/main/src/sys.zig#L21-L33)
9. [Bun src/StandaloneModuleGraph.zig:723-729](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L723-L729)
10. [ZLS src/translate_c.zig:144-161](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L144-L161)
11. [Zig Language Reference 0.15.2 — Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)
12. [Zig Language Reference 0.15.2 — Error Return Traces](https://ziglang.org/documentation/0.15.2/#Error-Return-Traces)
13. [Ghostty src/config/RepeatableStringMap.zig:43-56](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig#L43-L56)
14. [Ghostty src/termio/Termio.zig:95-96](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Termio.zig#L95-L96)
15. [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

[^1]: [Zig Language Reference 0.15.2 — Errors](https://ziglang.org/documentation/0.15.2/#Errors)
[^2]: Yuan, D., et al. "Simple Testing Can Prevent Most Critical Failures." OSDI 2014.
[^3]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^4]: [Ghostty src/unicode/lut.zig:114-125](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L125)
[^5]: [TigerBeetle src/multiversion.zig:693](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig#L693)
[^6]: [Zig Standard Library — std.testing.FailingAllocator](https://ziglang.org/documentation/0.15.2/std/#std.testing.FailingAllocator)
[^7]: [TigerBeetle src/io/linux.zig:1220](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1220)
[^8]: [Bun src/sys.zig:21-33](https://github.com/oven-sh/bun/blob/main/src/sys.zig#L21-L33)
[^9]: [Bun src/StandaloneModuleGraph.zig:723-729](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L723-L729)
[^10]: [ZLS src/translate_c.zig:144-161](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L144-L161)
