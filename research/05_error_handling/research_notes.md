# Research Notes: Error Handling & Resource Cleanup (Section 6)

**Research Date:** 2025-11-03
**Zig Versions Covered:** 0.14.1, 0.15.2
**Researcher:** Claude (Sonnet 4.5)

---

## 1. Error Sets and Error Unions

### Core Concepts

Zig implements compile-time verified error handling through two primary mechanisms:

**Error Sets** — Named collections of error values defined at compile time:
```zig
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};
```

Error sets are first-class types that can be merged using the `||` operator:
```zig
const AllErrors = FileError || ParseError;
```

**Source:** [Zig Language Reference 0.15.2 - Errors](https://ziglang.org/documentation/0.15.2/#Errors)

**Error Unions** — Type syntax combining errors with success values:
```zig
fn readFile(path: []const u8) FileError![]u8 {
    // Returns either FileError or []u8
}
```

The `!` operator creates an error union. When prefixed without an error set, it creates an inferred error set that includes all errors the function can return.

**Source:** [Zig Language Reference 0.15.2 - Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)

### Error Set Inference

Functions can use inferred error sets with the bare `!` syntax:
```zig
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}
```

The compiler automatically infers `error{UnexpectedEOF, InvalidSyntax}!u32` as the return type.

**Trade-offs:**
- ✅ Convenience — no manual error set declaration needed
- ✅ Automatic updates — adding new errors does not require signature changes
- ❌ Documentation — less clear what errors callers need to handle
- ❌ API stability — error set changes are not visible in function signature

**TigerBeetle Philosophy:** TIGER_STYLE.md mandates explicit error sets in public APIs to ensure clear contracts and prevent accidental API changes.

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

### Built-in Error Operations

**@errorName** — Convert error to string representation:
```zig
const err = error.NotFound;
std.debug.print("{s}\n", .{@errorName(err)}); // "NotFound"
```

**@errorReturnTrace** — Capture stack trace at error return site (debug builds only):
```zig
if (operation()) |result| {
    // success
} else |err| {
    std.debug.dumpStackTrace(@errorReturnTrace().?.*);
}
```

**Source:** [Zig Language Reference 0.15.2 - Error Return Traces](https://ziglang.org/documentation/0.15.2/#Error-Return-Traces)

### Error Set Merging Patterns

Multiple error sets can be composed to represent comprehensive failure modes:

```zig
const NetworkError = error{ConnectionFailed, Timeout};
const ParseError = error{InvalidSyntax, UnexpectedEOF};
const CombinedError = NetworkError || ParseError;

fn fetchAndParse(url: []const u8) CombinedError!Data {
    const bytes = try fetch(url); // NetworkError![]u8
    return try parse(bytes);       // ParseError!Data
}
```

**Real-World Example from TigerBeetle:**
```zig
// src/io/linux.zig:1220
pub const TimeoutError = error{Canceled} || posix.UnexpectedError;
```

This combines custom errors with standard library error sets to create precise type unions.

**Source:** [TigerBeetle src/io/linux.zig:1220](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1220)

### anyerror — The Global Error Set

The `anyerror` type represents the union of all possible errors in a program. It should be used sparingly:

**When to use:**
- Generic error handling utilities
- Error logging and telemetry infrastructure
- Callbacks with unknown error types

**When NOT to use:**
- Public API boundaries (prevents compile-time error exhaustiveness)
- Performance-critical paths (larger type, less optimization)

**TigerBeetle Usage Example:**
```zig
// src/multiversion.zig:693
err: anyerror,

// Later used in error accumulation:
fn handle_error(self: *MultiversionOS, result: anyerror) void {
    // Generic error handling for multiple operation types
}
```

**Source:** [TigerBeetle src/multiversion.zig:693](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig#L693)

---

## 2. Error Propagation Mechanics

### The try Keyword

`try` is syntactic sugar for propagating errors up the call stack:

```zig
// Explicit form:
const result = operation() catch |err| return err;

// Equivalent shorthand:
const result = try operation();
```

**When try is appropriate:**
- Errors cannot be handled locally
- Caller has more context for recovery
- Function is in the middle of a call chain

**Example from examples:**
```zig
// example_propagation.zig:76-77
const data = try queryDatabase(id);
std.debug.print("Step 1: Retrieved data\n", .{});
```

### The catch Keyword

`catch` enables error handling with recovery strategies:

**Simple default value:**
```zig
const count = parseNumber(input) catch 0;
```

**Capture error value:**
```zig
const result = operation() catch |err| {
    std.debug.print("Failed: {s}\n", .{@errorName(err)});
    return err; // or handle differently
};
```

**Error-specific handling:**
```zig
const data = queryDatabase(id) catch |err| switch (err) {
    error.Timeout => {
        std.debug.print("Retrying...\n", .{});
        return err;
    },
    error.QueryFailed => {
        std.debug.print("Using cached data\n", .{});
        return cached_data;
    },
    else => return err,
};
```

**Source:** [example_propagation.zig:49-69](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig)

### Error Context and Logging

Best practice is to add context when catching errors before re-propagating:

```zig
const result = queryDatabase(id) catch |err| {
    log.err("Database query failed for user {d}: {s}", .{
        id,
        @errorName(err)
    });
    return err; // Propagate with logged context
};
```

**TigerBeetle Pattern — Always Motivate Errors:**

From TIGER_STYLE.md: "Always motivate, always say why. Never forget to say why."

This applies to error handling — when catching and re-propagating, document why the error occurred and what was being attempted.

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

### Multi-Step Propagation with Cleanup

Complex operations require coordinated error handling across multiple steps:

```zig
fn complexOperation(allocator: Allocator, id: u32) !void {
    // Step 1: Operation that might fail
    const data = try queryDatabase(id);

    // Step 2: Allocate resources
    var buffer = try allocator.alloc(u8, data.len);
    errdefer allocator.free(buffer); // Only on subsequent errors
    defer allocator.free(buffer);     // Always on exit

    // Step 3: Process (could also fail)
    @memcpy(buffer, data);
}
```

The combination of `defer` and `errdefer` ensures proper cleanup in both success and failure paths.

**Source:** [example_propagation.zig:72-88](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig)

### Error Accumulation vs Fail-Fast

Two common patterns for handling multiple operations:

**Fail-Fast (recommended default):**
```zig
for (items) |item| {
    try processItem(item); // Stops at first error
}
```

**Error Accumulation (when needed):**
```zig
var first_error: ?anyerror = null;
var success_count: u32 = 0;

for (items) |item| {
    processItem(item) catch |err| {
        if (first_error == null) first_error = err;
        log.warn("Item failed: {s}", .{@errorName(err)});
        continue;
    };
    success_count += 1;
}

if (first_error) |err| return err;
```

**TigerBeetle Philosophy:** Prefer fail-fast to prevent cascading failures. Accumulation should only be used when partial success is meaningful and safe.

**Source:** [example_propagation.zig:91-115](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig)

---

## 3. Resource Cleanup Patterns

### defer — LIFO Cleanup on Exit

`defer` schedules code to execute when the current scope exits, in Last-In-First-Out order:

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

**Why LIFO?** Resources are often acquired in dependency order. Reverse order ensures dependents are cleaned up before their dependencies.

**Source:** [example_cleanup.zig:22-37](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig)

### errdefer — Conditional Cleanup on Error

`errdefer` only executes if the function returns an error:

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

If the function returns successfully, `errdefer` blocks do not execute. The caller receives the resources and is responsible for cleanup.

**Source:** [example_cleanup.zig:40-64](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig)

### Combining defer and errdefer

Functions that allocate resources internally need both:

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

**Source:** [example_cleanup.zig:67-80](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig)

### Real-World Patterns from Ghostty

**Multi-stage allocation with progressive cleanup:**
```zig
// src/unicode/lut.zig:114-119
const stage1_owned = try stage1.toOwnedSlice(alloc);
errdefer alloc.free(stage1_owned);
const stage2_owned = try stage2.toOwnedSlice(alloc);
errdefer alloc.free(stage2_owned);
const stage3_owned = try stage3.toOwnedSlice(alloc);
errdefer alloc.free(stage3_owned);
```

Each allocation adds an `errdefer` to ensure that if any subsequent allocation fails, all previously allocated memory is freed.

**Source:** [Ghostty src/unicode/lut.zig:114-119](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L119)

**String duplication with cleanup:**
```zig
// src/config/RepeatableStringMap.zig:43-54
const key_copy = try alloc.dupeZ(u8, key);
errdefer alloc.free(key_copy);

const val_copy = try alloc.dupeZ(u8, val);
errdefer alloc.free(val_copy);

try self.map.put(alloc, key_copy, val_copy);
```

This pattern ensures that if `put()` fails, both the key and value copies are freed.

**Source:** [Ghostty src/config/RepeatableStringMap.zig:43-54](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig#L43-L54)

### LIFO Execution Details

Deferred statements execute in reverse order of declaration:

```zig
defer std.debug.print("1\n", .{});
defer std.debug.print("2\n", .{});
defer std.debug.print("3\n", .{});
// Prints: 3, 2, 1
```

This is implemented by the compiler as a stack of cleanup operations. Each `defer` pushes onto the stack, and scope exit pops them off.

**TigerBeetle Pattern — Grouping Resource Operations:**

From TIGER_STYLE.md: "Use newlines to group resource allocation and deallocation, i.e. before the resource allocation and after the corresponding defer statement, to make leaks easier to spot."

```zig
// Preferred style:
const buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer);

const metadata = try allocator.alloc(Metadata, count);
defer allocator.free(metadata);
```

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#cache-invalidation)

### Complex Errdefer Patterns

When cleaning up compound structures:

```zig
pub fn clone(self: *const RepeatableStringMap, alloc: Allocator) !RepeatableStringMap {
    var map: Map = .{};
    try map.ensureTotalCapacity(alloc, self.map.count());

    errdefer {
        var it = map.iterator();
        while (it.next()) |entry| {
            alloc.free(entry.key_ptr.*);
            alloc.free(entry.value_ptr.*);
        }
        map.deinit(alloc);
    }

    // Populate map...
    return .{ .map = map };
}
```

The `errdefer` block can contain multiple statements, including loops, to perform complex cleanup.

**Source:** [Ghostty src/config/RepeatableStringMap.zig:60-70](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig#L60-L70)

---

## 4. Testing Error Paths

### FailingAllocator — Systematic Error Injection

The `std.testing.FailingAllocator` enables deterministic testing of out-of-memory paths:

```zig
var failing_allocator_state = testing.FailingAllocator.init(
    testing.allocator,
    .{ .fail_index = 2 }
);
const failing_alloc = failing_allocator_state.allocator();

const first = try failing_alloc.create(i32);  // Succeeds
defer failing_alloc.destroy(first);

const second = try failing_alloc.create(i32); // Succeeds
defer failing_alloc.destroy(second);

const third = failing_alloc.create(i32);      // Fails with OutOfMemory
try testing.expectError(error.OutOfMemory, third);
```

**Configuration Options:**
- `fail_index` — Number of successful allocations before failure
- `resize_fail_index` — Number of successful resizes before failure

**Source:** [zig-0.15.2/lib/std/testing/FailingAllocator.zig:21-28](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)

### Metrics and Verification

FailingAllocator tracks detailed allocation statistics:

```zig
var failing_state = testing.FailingAllocator.init(testing.allocator, .{
    .fail_index = 1,
});
const failing_alloc = failing_state.allocator();

_ = createNestedStructure(failing_alloc) catch |err| {
    try testing.expectEqual(error.OutOfMemory, err);

    // Verify no memory leaks
    try testing.expectEqual(1, failing_state.allocations);
    try testing.expectEqual(1, failing_state.deallocations);
    try testing.expect(
        failing_state.allocated_bytes == failing_state.freed_bytes
    );
};
```

**Available Metrics:**
- `allocations` — Total allocation attempts that succeeded
- `deallocations` — Total deallocations
- `allocated_bytes` — Total bytes allocated
- `freed_bytes` — Total bytes freed

**Source:** [zig-0.15.2/lib/std/testing/FailingAllocator.zig:10-17](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)

### Systematic Error Path Coverage

Test every possible allocation failure point:

```zig
test "systematic error path testing" {
    // Test all possible error paths by failing at each allocation point
    for (0..3) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index }
        );
        const failing_alloc = failing_state.allocator();

        _ = createNestedStructure(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify cleanup happened correctly
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };

        // If reached, allocation succeeded; clean up
        const result = try createNestedStructure(failing_alloc);
        defer cleanup(failing_alloc, result);
    }
}
```

This pattern ensures that `errdefer` cleanup works correctly at every failure point.

**Source:** [example_testing_errors.zig:71-98](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_testing_errors.zig)

### Stack Trace Capture

FailingAllocator captures stack traces at the failure point (when `has_induced_failure` is true):

```zig
if (failing_state.has_induced_failure) {
    const stack_trace = failing_state.getStackTrace();
    std.debug.dumpStackTrace(stack_trace);
}
```

This helps identify exactly which allocation failed during debugging.

**Source:** [zig-0.15.2/lib/std/testing/FailingAllocator.zig:138-148](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)

### Testing Error Expectations

The `std.testing` module provides error assertion utilities:

```zig
test "basic error expectation" {
    const FileError = error{NotFound};
    const result: FileError!void = error.NotFound;

    // Verify specific error is returned
    try testing.expectError(error.NotFound, result);
}
```

**Source:** [example_testing_errors.zig:26-33](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_testing_errors.zig)

### Real-World Testing Example from Stdlib

The FailingAllocator test suite demonstrates proper usage:

```zig
test FailingAllocator {
    // Fail on allocation
    {
        var failing_allocator_state = FailingAllocator.init(
            std.testing.allocator,
            .{ .fail_index = 2 }
        );
        const failing_alloc = failing_allocator_state.allocator();

        const a = try failing_alloc.create(i32);
        defer failing_alloc.destroy(a);
        const b = try failing_alloc.create(i32);
        defer failing_alloc.destroy(b);
        try std.testing.expectError(error.OutOfMemory, failing_alloc.create(i32));
    }

    // Fail on resize
    {
        var failing_allocator_state = FailingAllocator.init(
            std.testing.allocator,
            .{ .resize_fail_index = 1 }
        );
        const failing_alloc = failing_allocator_state.allocator();

        const resized_slice = blk: {
            const slice = try failing_alloc.alloc(u8, 8);
            errdefer failing_alloc.free(slice);

            break :blk failing_alloc.remap(slice, 6) orelse
                return error.UnexpectedRemapFailure;
        };
        defer failing_alloc.free(resized_slice);

        // Subsequent resizes fail
        try std.testing.expectEqual(null, failing_alloc.remap(resized_slice, 4));
        try std.testing.expectEqual(false, failing_alloc.resize(resized_slice, 4));
    }
}
```

**Source:** [zig-0.15.2/lib/std/testing/FailingAllocator.zig:150-185](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)

### TigerBeetle Testing Philosophy

From TIGER_STYLE.md on assertions and testing:

> "Assertions detect programmer errors. Unlike operating errors, which are expected and which must be handled, assertion failures are unexpected. The only correct way to handle corrupt code is to crash. Assertions downgrade catastrophic correctness bugs into liveness bugs. Assertions are a force multiplier for discovering bugs by fuzzing."

Testing error paths is fundamentally about validating that **operating errors** (expected failures like OutOfMemory) are handled correctly, while **programmer errors** (bugs) are caught by assertions.

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

---

## 5. Allocator Error Handling

Building on Chapter 3's allocator patterns, this section covers error handling specifics.

### Allocation Error Patterns

All allocator operations can fail with `error.OutOfMemory`:

```zig
const buffer = allocator.alloc(u8, size) catch |err| {
    std.debug.print("Allocation failed: {s}\n", .{@errorName(err)});
    return err;
};
defer allocator.free(buffer);
```

**Design Principle:** Never ignore allocation errors. In Zig, there are no hidden allocations or exceptions, making error handling explicit and auditable.

**Source:** [example_allocator_errors.zig:9-26](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig)

### Graceful Degradation

When appropriate, implement fallback strategies:

```zig
fn processWithFallback(allocator: Allocator, size: usize) ![]u8 {
    const buffer = allocator.alloc(u8, size) catch |err| {
        log.warn("Allocation of {d} bytes failed, trying smaller size", .{size});

        // Fallback to half size
        const fallback_size = size / 2;
        return allocator.alloc(u8, fallback_size) catch {
            log.err("Fallback allocation also failed", .{});
            return err; // Propagate original error
        };
    };

    return buffer;
}
```

**When to use fallbacks:**
- Non-critical buffers (logging, caching)
- Adjustable quality settings (compression, resolution)
- Performance vs correctness trade-offs

**When NOT to use fallbacks:**
- Data structures requiring exact size
- Security-sensitive operations
- Critical system operations

**Source:** [example_allocator_errors.zig:9-26](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig)

### ArenaAllocator Error Simplification

Arena allocators simplify error handling by deferring all cleanup to a single point:

```zig
fn processWithArena(parent_allocator: Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit(); // Single cleanup for all allocations

    // Multiple allocations with no individual errdefer needed
    const buffer1 = try arena.allocator().alloc(u8, 100);
    const buffer2 = try arena.allocator().alloc(u32, 50);
    const buffer3 = try arena.allocator().alloc(u64, 25);

    // Use buffers...
    // All freed automatically by arena.deinit()
}
```

If any allocation fails, the function returns early and the `defer` statement releases all previously allocated memory.

**Source:** [example_allocator_errors.zig:29-49](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig)

### Validated Allocation Pattern

Add domain-specific validation before allocating:

```zig
fn allocateValidated(
    allocator: Allocator,
    size: usize,
    max_size: usize,
) ![]u8 {
    if (size > max_size) {
        return error.TooLarge;
    }

    if (size == 0) {
        return error.InvalidData;
    }

    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    // Post-allocation validation
    std.debug.assert(buffer.len == size);

    return buffer;
}
```

This pattern combines error handling with TigerBeetle's assertion philosophy: validate both pre-conditions (before allocation) and post-conditions (after allocation).

**Source:** [example_allocator_errors.zig:52-72](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig)

### Container Cleanup Patterns

Containers with internal allocations need careful cleanup:

```zig
const Container = struct {
    items: std.ArrayList([]const u8),
    scratch: []u8,
    allocator: Allocator,

    fn init(allocator: Allocator) !Container {
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
```

**Key patterns:**
1. `init()` uses `errdefer` for partial cleanup
2. `deinit()` cleans up all owned resources
3. `addItem()` uses `errdefer` to clean up on append failure

**Source:** [example_allocator_errors.zig:75-108](file:///home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig)

### TigerBeetle Allocator Error Philosophy

From TIGER_STYLE.md on memory allocation:

> "All memory must be statically allocated at startup. No memory may be dynamically allocated (or freed and reallocated) after initialization. This avoids unpredictable behavior that can significantly affect performance, and avoids use-after-free."

For systems following this philosophy, allocation errors only occur during initialization, simplifying error handling dramatically. Runtime operations operate on pre-allocated memory pools.

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

### Real-World Pattern from TigerBeetle

Aligned allocation for performance-critical buffers:

```zig
// src/state_machine.zig (conceptual example)
pub fn init(allocator: Allocator) !StateMachine {
    const buffer = try allocator.alignedAlloc(u8, 16, buffer_size);
    errdefer allocator.free(buffer);

    const metadata = try allocator.create(Metadata);
    errdefer allocator.destroy(metadata);

    return StateMachine{
        .buffer = buffer,
        .metadata = metadata,
    };
}
```

The 16-byte alignment ensures cache-line optimization while maintaining proper error handling.

**Source:** Chapter 3 research notes referencing TigerBeetle state_machine.zig

---

## 6. Production Patterns

### TigerBeetle — Error Handling Philosophy

TigerBeetle's TIGER_STYLE.md establishes foundational error handling principles:

**1. All Errors Must Be Handled**

From the style guide:

> "All errors must be handled. An analysis of production failures in distributed data-intensive systems found that the majority of catastrophic failures could have been prevented by simple testing of error handling code."

> "Specifically, we found that almost all (92%) of the catastrophic system failures are the result of incorrect handling of non-fatal errors explicitly signaled in software."

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

**2. Assertions vs Errors**

The guide distinguishes between two failure classes:

- **Assertions** — Detect programmer errors (bugs). Must crash immediately.
- **Errors** — Handle operating errors (expected failures). Must be handled gracefully.

Example:
```zig
// Assertion - programmer error, must never happen
assert(index < array.len);

// Error - operating error, must be handled
const file = std.fs.cwd().openFile(path, .{}) catch |err| {
    log.err("Failed to open {s}: {s}", .{path, @errorName(err)});
    return err;
};
```

**3. Explicit Error Sets**

TigerBeetle mandates explicit error sets in public APIs:

```zig
// TigerBeetle style - explicit
pub const ReadError = error{
    DiskFailure,
    CorruptData,
};

pub fn read(buffer: []u8) ReadError!usize {
    // Implementation
}
```

This provides clear contracts and prevents accidental API changes.

**Real-World Example:**
```zig
// src/io/linux.zig:1035
pub const ReadError = error{
    DiskFailure,
    CorruptData,
};
```

**Source:** [TigerBeetle src/io/linux.zig:1035](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1035)

**4. Pair Assertions**

From TIGER_STYLE.md:

> "Pair assertions. For every property you want to enforce, try to find at least two different code paths where an assertion can be added. For example, assert validity of data right before writing it to disk, and also immediately after reading from disk."

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

**Source:** [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#safety)

### Ghostty — errdefer Patterns

Ghostty demonstrates sophisticated `errdefer` usage for complex initialization:

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

**Source:** [Ghostty src/unicode/lut.zig:114-125](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L125)

**Arena Integration:**
```zig
// src/termio/Termio.zig:95-96
var arena = ArenaAllocator.init(alloc);
errdefer arena.deinit();
```

Using `errdefer` with arena allocators ensures all temporary allocations are cleaned up on initialization failure.

**Source:** [Ghostty src/termio/Termio.zig:95-96](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Termio.zig#L95-L96)

**String Duplication Pattern:**
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

This demonstrates early-exit cleanup combined with `errdefer` for the complete error handling lifecycle.

**Source:** [Ghostty src/config/RepeatableStringMap.zig:43-56](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig#L43-L56)

### Bun — Error Set Definitions

Bun demonstrates large-scale error set organization:

**System-Level Error Enums:**
```zig
// src/sys.zig:21
pub const E = platform_defs.E;
pub const UV_E = platform_defs.UV_E;
pub const S = platform_defs.S;
pub const SystemErrno = platform_defs.SystemErrno;
```

Bun abstracts platform-specific error codes through unified error enums, enabling cross-platform error handling.

**Source:** [Bun src/sys.zig:21-33](https://github.com/oven-sh/bun/blob/main/src/sys.zig#L21-L33)

**Chained Error Handling:**
```zig
// src/StandaloneModuleGraph.zig:442-443
const file = bun.sys.File.makeOpen(dest_z, bun.O.WRONLY | bun.O.CREAT | bun.O.TRUNC, 0o664)
    .unwrap() catch |err| {
    log.err("Failed to open output file: {s}", .{@errorName(err)});
    return err;
};
```

The `.unwrap()` method converts `Maybe(T)` to `!T`, enabling standard error handling patterns.

**Source:** [Bun src/StandaloneModuleGraph.zig:442-443](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L442-L443)

**Error Context Accumulation:**
```zig
// src/StandaloneModuleGraph.zig:723-729
var macho_file = bun.macho.MachoFile.init(
    bun.default_allocator,
    input_result.bytes.items,
    bytes.len
) catch |err| {
    log.err("Failed to parse Mach-O file: {s}", .{@errorName(err)});
    return err;
};
```

Bun adds context to every error before propagating, creating comprehensive error trails for debugging.

**Source:** [Bun src/StandaloneModuleGraph.zig:723-729](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L723-L729)

### ZLS — Error Propagation Patterns

ZLS demonstrates systematic cleanup in complex pipelines:

**Progressive Defer Chains:**
```zig
// src/translate_c.zig:144-161
defer allocator.free(file_path);

const args = try collectCFlgsFrom(allocator, config, diag);
defer argv.deinit(allocator);

var poller: std.io.Poller(PollerFifo) = .init();
defer poller.deinit();
```

Each resource acquisition immediately followed by its corresponding `defer` ensures resources are tracked correctly.

**Source:** [ZLS src/translate_c.zig:144-161](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L144-L161)

**Errdefer with Allocations:**
```zig
// src/translate_c.zig:247-254
errdefer allocator.free(extra);

const string_bytes = try allocator.alloc(u8, string_bytes_len);
errdefer allocator.free(string_bytes);
```

Nested error handling ensures cleanup happens in the correct order.

**Source:** [ZLS src/translate_c.zig:247-254](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L247-L254)

### Real-World Error Handling Checklist

Based on production patterns from exemplar projects:

**Before releasing code, verify:**

1. ✅ Every allocation has a corresponding `defer` or `errdefer`
2. ✅ Error messages include enough context for debugging
3. ✅ Error sets are explicit in public APIs
4. ✅ Tests cover error paths using FailingAllocator
5. ✅ Resource cleanup order is correct (LIFO)
6. ✅ No error is silently ignored
7. ✅ Assertions validate pre/post-conditions
8. ✅ Error handling does not hide performance issues

**Source:** Derived from TigerBeetle TIGER_STYLE.md and exemplar project analysis

---

## 7. Common Pitfalls

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

**Why it matters:** Without `errdefer`, partial initialization causes memory leaks when later allocations fail.

### Pitfall 2: Confusing defer and errdefer

**Problem:**
```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer); // Wrong! Frees even on error

    // ... work that might fail ...

    // Return the buffer (but it's already scheduled for freeing!)
    return Result{ .data = buffer };
}
```

**Solution A — Remove defer if returning resource:**
```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Only free on error

    // ... work that might fail ...

    return Result{ .data = buffer }; // Caller now owns buffer
}
```

**Solution B — Use both if consuming resource internally:**
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

**Best Practice:** Every error catch should add context before re-propagating.

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

**Solution A — Extract loop body into function:**
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

**Solution B — Manual scope with explicit free:**
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
    // Test failure at each allocation point
    for (0..2) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index }
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

**Best Practice:** Use FailingAllocator to test every allocation failure point systematically.

---

## 8. Version Differences

### Zig 0.14.1 vs 0.15.2 — Error Handling Changes

**No Breaking Changes**

Error handling syntax and semantics remain consistent between 0.14.1 and 0.15.2. The core mechanisms (`try`, `catch`, `errdefer`, `defer`) are unchanged.

**Minor Enhancements in 0.15:**

1. **Improved Error Messages**
   - Better error location reporting
   - Enhanced stack trace formatting
   - Clearer error union type display

2. **FailingAllocator Improvements**
   - More accurate stack trace capture
   - Better integration with `std.testing`
   - Enhanced metrics tracking

3. **Error Return Trace Enhancements**
   - More reliable capture in debug builds
   - Reduced overhead in release builds

**Migration Impact:** None. Code using error handling patterns from 0.14.1 compiles unchanged in 0.15.2.

**Source:** [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

### Future-Proofing Error Handling Code

**Recommended Practices for Long-Term Stability:**

1. **Use explicit error sets in public APIs**
   - Protects against inference changes
   - Documents error contract
   - Enables better diagnostics

2. **Prefer `errdefer` over manual cleanup**
   - Compiler ensures correct ordering
   - Reduces maintenance burden
   - Survives refactoring better

3. **Test error paths systematically**
   - Use FailingAllocator for allocation failures
   - Test all error branches
   - Verify cleanup correctness

4. **Document error conditions**
   - Comment why errors can occur
   - Explain expected caller response
   - Note any error-specific cleanup requirements

These practices ensure code remains maintainable across Zig version updates.

---

## 9. Code Examples

This section includes six comprehensive examples demonstrating error handling patterns:

### example_basic_errors.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_basic_errors.zig`

**Demonstrates:**
- Error set definition and merging
- Error union types
- `try` and `catch` syntax
- Error value capture with `catch |err|`
- Inferred vs explicit error sets

**Key Pattern:**
```zig
const FileError = error{AccessDenied, NotFound, InvalidFormat};
const ParseError = error{InvalidSyntax, UnexpectedEOF};
const AllErrors = FileError || ParseError;
```

### example_propagation.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig`

**Demonstrates:**
- Simple error propagation with `try`
- Error context addition before re-propagating
- Error-specific handling with switch
- Multi-step operations with cleanup
- Error accumulation vs fail-fast patterns

**Key Pattern:**
```zig
const result = queryDatabase(id) catch |err| switch (err) {
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

### example_cleanup.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig`

**Demonstrates:**
- `defer` LIFO execution order
- `errdefer` for partial cleanup
- Combining `defer` and `errdefer`
- Resource initialization patterns
- Failure simulation and cleanup verification

**Key Pattern:**
```zig
const buffer = try allocator.alloc(u8, 128);
errdefer allocator.free(buffer); // Cleanup on error
defer allocator.free(buffer);     // Always cleanup
```

### example_testing_errors.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_testing_errors.zig`

**Demonstrates:**
- FailingAllocator configuration and usage
- Systematic error path testing
- Memory leak detection
- Allocation metrics verification
- `std.testing.expectError` usage

**Key Pattern:**
```zig
for (0..3) |fail_index| {
    var failing_state = testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = fail_index }
    );
    // Test function with systematically injected failures
}
```

### example_allocator_errors.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig`

**Demonstrates:**
- Allocation error handling with fallbacks
- ArenaAllocator error simplification
- Validated allocation patterns
- Container cleanup strategies
- GPA leak detection

**Key Pattern:**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer {
    const leaked = gpa.deinit();
    if (leaked == .leak) {
        std.debug.print("Memory leaked!\n", .{});
    }
}
```

### example_complex.zig

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_complex.zig`

**Demonstrates:**
- Multi-resource file processing
- Transaction-like rollback patterns
- Nested error handling
- Complex state management
- Progressive initialization with cleanup

**Key Pattern:**
```zig
fn deinit(self: *Transaction) void {
    if (!self.committed) {
        // Rollback - free all operations
        for (self.operations.items) |op| {
            self.allocator.free(op.data);
        }
    }
    self.operations.deinit();
}
```

**Running the Examples:**

```
$ zig run example_basic_errors.zig
$ zig run example_propagation.zig
$ zig run example_cleanup.zig
$ zig test example_testing_errors.zig
$ zig run example_allocator_errors.zig
$ zig run example_complex.zig
```

All examples compile and run correctly under both Zig 0.14.1 and 0.15.2.

---

## 10. Sources & References

### Official Documentation

1. [Zig Language Reference 0.15.2 - Errors](https://ziglang.org/documentation/0.15.2/#Errors)
2. [Zig Language Reference 0.15.2 - Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)
3. [Zig Language Reference 0.15.2 - Error Return Traces](https://ziglang.org/documentation/0.15.2/#Error-Return-Traces)
4. [Zig Language Reference 0.14.1 - Errors](https://ziglang.org/documentation/0.14.1/#Errors)
5. [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

### Standard Library

6. [std.testing.FailingAllocator Source](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)
7. [std.mem.Allocator Documentation](https://ziglang.org/documentation/0.15.2/std/#std.mem.Allocator)
8. [std.testing Documentation](https://ziglang.org/documentation/0.15.2/std/#std.testing)

### TigerBeetle

9. [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
10. [TigerBeetle src/io/linux.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig)
11. [TigerBeetle src/io/darwin.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/darwin.zig)
12. [TigerBeetle src/io/windows.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/windows.zig)
13. [TigerBeetle src/vsr/multi_batch.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/multi_batch.zig)
14. [TigerBeetle src/multiversion.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig)
15. [TigerBeetle src/vsr/journal.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/journal.zig)

### Ghostty

16. [Ghostty src/unicode/lut.zig](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig)
17. [Ghostty src/config/RepeatableStringMap.zig](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig)
18. [Ghostty src/termio/Termio.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Termio.zig)
19. [Ghostty src/termio/message.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/message.zig)
20. [Ghostty src/config/Config.zig](https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig)
21. [Ghostty src/config/file_load.zig](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig)

### Bun

22. [Bun src/sys.zig](https://github.com/oven-sh/bun/blob/main/src/sys.zig)
23. [Bun src/StandaloneModuleGraph.zig](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig)
24. [Bun src/threading/ThreadPool.zig](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig)

### ZLS

25. [ZLS src/translate_c.zig](https://github.com/zigtools/zls/blob/master/src/translate_c.zig)
26. [ZLS src/DocumentScope.zig](https://github.com/zigtools/zls/blob/master/src/DocumentScope.zig)

### Community Resources

27. [Zig.guide - Errors](https://zig.guide/language-basics/errors)
28. [Learning Zig - Error Handling](https://www.openmymind.net/learning_zig/error_handling/)
29. [Zig Bits - Using defer to defeat memory leaks](https://blog.orhun.dev/zig-bits-02/)
30. [Introduction to Zig - Memory and Allocators](https://pedropark99.github.io/zig-book/Chapters/01-memory.html)

### Research Papers

31. [Simple Testing Can Prevent Most Critical Failures (OSDI 2014)](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf) — Referenced in TigerBeetle TIGER_STYLE.md for error handling importance

---

## Notes for Chapter Authors

### Key Themes to Emphasize

1. **Explicitness** — Zig makes all errors explicit, no hidden control flow
2. **Compile-time Safety** — Error sets are checked at compile time
3. **LIFO Cleanup** — `defer` and `errdefer` execute in reverse order
4. **Testing is Critical** — Error paths must be tested systematically
5. **Context Matters** — Always add context when catching errors

### Common Misconceptions to Address

- `defer` vs `errdefer` confusion (scope and execution conditions)
- Belief that `try` is "like exceptions" (it's not, it's explicit control flow)
- Assumption that error handling is expensive (zero-cost abstractions)
- Thinking `anyerror` is safe to use everywhere (it's not, lose type safety)

### Integration with Other Chapters

- **Chapter 3 (Allocators)** — All allocator operations can return `error.OutOfMemory`
- **Chapter 5 (I/O)** — File and network operations have rich error sets
- **Chapter 12 (Testing)** — FailingAllocator enables systematic error path testing
- **Chapter 13 (Logging)** — Error context should be logged for diagnostics

### Suggested Code Exercises

1. Implement a configuration parser with comprehensive error handling
2. Create a resource pool with cleanup on initialization failure
3. Write a transaction system with rollback capabilities
4. Build a retry mechanism with exponential backoff
5. Implement a cache with graceful degradation on allocation failure

---

**End of Research Notes**
