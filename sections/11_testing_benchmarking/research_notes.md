# Chapter 12: Testing & Benchmarking - Research Notes

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Testing Framework Fundamentals](#testing-framework-fundamentals)
3. [std.testing API Reference](#stdtesting-api-reference)
4. [Test Organization Patterns](#test-organization-patterns)
5. [Advanced Testing Techniques](#advanced-testing-techniques)
6. [Benchmarking Best Practices](#benchmarking-best-practices)
7. [Profiling Integration](#profiling-integration)
8. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
9. [Production Patterns](#production-patterns)
10. [Version Differences](#version-differences)
11. [References](#references)

---

## Executive Summary

Zig's testing framework is built directly into the language and compiler, providing a cohesive, integrated approach to testing without external dependencies. The testing paradigm emphasizes simplicity, determinism, and compile-time correctness.

### Key Characteristics

**Built-in Test Discovery**: Tests are defined using the `test` keyword and automatically discovered by the compiler. Running `zig test` compiles and executes all tests in a source file and its dependencies.

**No External Framework Required**: Unlike many languages that require third-party testing libraries (JUnit, pytest, mocha), Zig's testing is first-class. The `std.testing` module provides all essential assertions and utilities.

**Deterministic Testing**: The `std.testing.random_seed` provides reproducible randomness across test runs. TigerBeetle demonstrates advanced deterministic testing with controlled time simulation and fault injection.

**Memory Safety Integration**: The `std.testing.allocator` (GeneralPurposeAllocator) automatically detects memory leaks. Tests fail if allocations aren't properly freed, enforcing memory safety at the test level.

**Compile-Time Testing**: Zig can run tests at compile time using `comptime`, enabling validation of compile-time logic and type-level programming.

### Key Findings from Research

From analyzing production codebases (TigerBeetle, Ghostty, Bun, ZLS) and Zig's standard library, several patterns emerge:

1. **Colocated Tests**: Most projects place tests in the same file as implementation code, using `builtin.is_test` to conditionally include test-only code without bloating production builds.

2. **Test Utilities Pattern**: Production projects extract reusable test infrastructure into dedicated `testing/` directories (e.g., TigerBeetle's extensive `src/testing/` with fixtures, simulators, and checkers).

3. **Deterministic Simulation**: TigerBeetle's `TimeSim` and `PacketSimulator` demonstrate advanced patterns for testing distributed systems with controlled time, network partitions, and fault injection.

4. **Snapshot Testing**: TigerBeetle's `snaptest.zig` implements expect-style testing where snapshots can auto-update via `SNAP_UPDATE=1`, drastically reducing refactoring friction.

5. **Benchmarking Best Practices**: Manual benchmarking using `std.time.Timer` with warm-up iterations, statistical sampling, and `std.mem.doNotOptimizeAway` to prevent compiler optimizations from invalidating results.

### Main Testing Patterns Discovered

- **Table-Driven Tests**: Comptime iteration over test cases enables concise, comprehensive testing
- **Allocator Testing**: `testing.allocator` and `FailingAllocator` for both leak detection and error path testing
- **Parameterized Tests**: Inline for loops with comptime parameters generate test variations
- **Fixtures Pattern**: Centralized initialization helpers reduce boilerplate (TigerBeetle's `fixtures.zig`)
- **Test-Only Code**: `if (builtin.is_test)` conditionally includes test harnesses without runtime cost

### Benchmarking Best Practices Summary

Key principles from Example 05 and production code:

1. **Warm-up Phase**: Always include warm-up iterations to stabilize CPU frequency, cache state, and branch prediction
2. **Statistical Measurement**: Collect multiple samples and report min/max/mean/variance
3. **doNotOptimizeAway**: Critical to prevent dead code elimination and constant folding
4. **Build Modes**: Use `ReleaseFast` or `ReleaseSmall` for realistic performance metrics
5. **Isolation**: Benchmark in isolation; avoid running alongside other intensive processes

### Profiling Integration Summary

Profiling requires specific build flags and external tools:

- **Debug Symbols**: `-Dcpu=baseline -Doptimize=ReleaseFast -Dstrip=false` for profiling
- **Linux perf**: System-wide profiling with hardware counters
- **Valgrind Callgrind**: Function-level profiling with call graphs
- **Massif**: Heap profiling to track memory allocation patterns
- **Flame Graphs**: Visual representation of profiling data (via FlameGraph or hotspot)

---

## Testing Framework Fundamentals

### The `zig test` Command

The `zig test` command compiles a source file and all its dependencies, discovers all `test` blocks, and executes them sequentially. Each test runs in isolation—failures in one test don't affect others.

```bash
# Test a single file
zig test src/main.zig

# Test with specific build mode
zig test -O ReleaseFast src/main.zig

# Filter tests by name
zig test src/main.zig --test-filter "specific test"

# Run tests with verbose output
zig test src/main.zig --summary all
```

**Exit Codes**:
- `0`: All tests passed
- Non-zero: At least one test failed (typically `1`)

**Test Discovery**: The Zig compiler scans for `test "name" { ... }` or `test { ... }` blocks at file scope. Tests in imported modules are also included unless the import is guarded by `if (!builtin.is_test)`.

### Test Block Syntax

Tests are top-level declarations using the `test` keyword:

```zig
const std = @import("std");
const testing = std.testing;

// Named test - appears in output
test "arithmetic operations" {
    const result = 2 + 2;
    try testing.expectEqual(4, result);
}

// Anonymous test - identified by location
test {
    try testing.expect(true);
}

// Test can be async (but typically aren't in 0.15+)
test "async example" {
    var value: i32 = 42;
    try testing.expectEqual(42, value);
}
```

Tests can return an error, which causes the test to fail. The `try` keyword propagates errors, which is how assertion failures propagate upward.

### Test Execution Model

Tests execute sequentially in the order they appear in source files. This is intentional—Zig prioritizes determinism over parallel execution for reproducibility.

**Execution Flow**:
1. Compiler discovers all tests in the module graph
2. Test runner initializes `std.testing.allocator` and `std.testing.random_seed`
3. Each test executes in isolation
4. After each test, the allocator checks for leaks
5. Results accumulate; summary printed at the end

**Isolation**: Each test has its own stack frame but shares the same process. Memory allocations via `std.testing.allocator` are tracked per-test.

### The `builtin.is_test` Flag

The `builtin.is_test` constant enables conditional compilation for test-only code:

```zig
const builtin = @import("builtin");

pub const MyStruct = struct {
    data: []const u8,

    // Production code
    pub fn process(self: MyStruct) void {
        // Implementation
    }

    // Test-only helper - not compiled in release builds
    pub fn testHelper(self: MyStruct) void {
        if (!builtin.is_test) @compileError("testHelper only for tests");
        // Test-specific logic
    }
};

test "use test helper" {
    const s = MyStruct{ .data = "test" };
    s.testHelper(); // OK in tests
}
```

This pattern is used extensively in Zig's standard library and production codebases to include test infrastructure without bloating production binaries.

**TigerBeetle Example**: Their `snaptest.zig` uses comptime assertions:
```zig
pub const Snap = struct {
    comptime {
        assert(builtin.is_test);
    }
    // ... snapshot testing implementation
};
```
[Source: tigerbeetle/src/stdx/testing/snaptest.zig#L74-L76](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76)

### Test Filtering

Test filtering allows running a subset of tests matching a pattern:

```bash
# Run only tests with "allocator" in the name
zig test src/main.zig --test-filter "allocator"

# Multiple filters are OR'd
zig test src/main.zig --test-filter "allocator" --test-filter "hashmap"
```

This is invaluable for iterating on specific test cases during development without running the entire suite.

### Error Reporting

When a test fails, Zig provides detailed diagnostics:

```
Test [1/5] test.basic arithmetic... FAIL (TestExpectedEqual)
expected 5, found 4
/home/user/src/main.zig:10:5: 0x... in test.basic arithmetic (test)
    try testing.expectEqual(5, result);
    ^
```

The output includes:
- Test name and index
- Error type (e.g., `TestExpectedEqual`)
- Expected vs actual values
- File, line, and column of the failure
- Stack trace showing the call path

### Citations: Testing Fundamentals

- [Zig Language Reference: Testing](https://ziglang.org/documentation/master/#Testing) - Official documentation on test blocks
- [Zig Build System Documentation](https://ziglang.org/learn/build-system/) - Integration with build.zig
- [zig-0.15.2/lib/std/testing.zig#L1-L30](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L1-L30) - Testing module initialization
- [TigerBeetle: Testing Documentation](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing) - Production test infrastructure

---

## std.testing API Reference

The `std.testing` module provides all core testing utilities. It's part of the standard library and doesn't require external dependencies.

### Core Assertions

#### `expect(ok: bool) !void`

The most basic assertion—fails if the condition is false.

```zig
try testing.expect(value > 0);
try testing.expect(list.items.len == 5);
```

Returns `error.TestUnexpectedResult` on failure.

[zig-0.15.2/lib/std/testing.zig#L367-L374](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L367-L374)

#### `expectEqual(expected: anytype, actual: anytype) !void`

Compares two values for equality. Uses peer type resolution to coerce both to a common type.

```zig
try testing.expectEqual(42, computeAnswer());
try testing.expectEqual(@as(u32, 100), counter);
```

Provides detailed diagnostics showing both expected and actual values. Works with structs, unions, arrays, and most Zig types via deep comparison.

**Implementation Detail**: Uses `std.meta.eql` for recursive equality checking on complex types.

[zig-0.15.2/lib/std/testing.zig#L73-L218](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L73-L218)

#### `expectError(expected_error: anyerror, actual_error_union: anytype) !void`

Asserts that an error union contains a specific error.

```zig
const result = parseNumber("invalid");
try testing.expectError(error.InvalidFormat, result);
```

Fails if:
- The error union is not an error (contains a value)
- The error is different from expected

[zig-0.15.2/lib/std/testing.zig#L54-L67](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L54-L67)

#### `expectEqualSlices(comptime T: type, expected: []const T, actual: []const T) !void`

Compares two slices element-by-element.

```zig
const expected = [_]u8{ 1, 2, 3 };
const actual = list.items;
try testing.expectEqualSlices(u8, &expected, actual);
```

Reports the index of the first mismatch if slices differ.

[zig-0.15.2/lib/std/testing.zig#L377-L404](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L377-L404)

#### `expectEqualStrings(expected: []const u8, actual: []const u8) !void`

String-specific comparison with helpful diagnostics.

```zig
try testing.expectEqualStrings("hello", result);
```

Equivalent to `expectEqualSlices(u8, ...)` but semantically clearer for strings.

[zig-0.15.2/lib/std/testing.zig#L406-L419](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L406-L419)

### Floating Point Assertions

#### `expectApproxEqAbs(expected: anytype, actual: anytype, tolerance: anytype) !void`

Absolute tolerance comparison for floating-point values.

```zig
const result = computeCircleArea(5.0);
try testing.expectApproxEqAbs(78.54, result, 0.01);
```

Checks: `|expected - actual| <= tolerance`

[zig-0.15.2/lib/std/testing.zig#L289-L305](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L289-L305)

#### `expectApproxEqRel(expected: anytype, actual: anytype, tolerance: anytype) !void`

Relative tolerance comparison—better for values with large magnitude.

```zig
try testing.expectApproxEqRel(1000000.0, result, 0.0001); // 0.01% tolerance
```

Checks: `|expected - actual| / max(|expected|, |actual|) <= tolerance`

Relative comparison avoids issues with absolute tolerances on large or small numbers.

[zig-0.15.2/lib/std/testing.zig#L325-L341](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L325-L341)

### Memory Testing

#### `testing.allocator`

A `GeneralPurposeAllocator` configured for test use. Automatically detects:
- Memory leaks (allocations not freed)
- Double-frees
- Use-after-free (when safety checks enabled)

```zig
test "allocator usage" {
    const list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Essential - test fails without this

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

If `deinit()` is omitted, the test fails with a leak report.

**Configuration**:
```zig
pub var allocator_instance: std.heap.GeneralPurposeAllocator(.{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0,
    .resize_stack_traces = true,
    .canary = @truncate(0x2731e675c3a701ba),
}) = .init;
```

The canary value ensures that using a default-constructed GPA in place of `testing.allocator` triggers a panic.

[zig-0.15.2/lib/std/testing.zig#L17-L29](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L17-L29)

#### `FailingAllocator`

A wrapper allocator that probabilistically fails allocations to test error paths.

```zig
const std = @import("std");
const testing = std.testing;

test "handle allocation failure" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 3 });
    const allocator = failing.allocator();

    // First 2 allocations succeed, 3rd fails
    const a1 = try allocator.alloc(u8, 10);
    defer allocator.free(a1);

    const a2 = try allocator.alloc(u8, 10);
    defer allocator.free(a2);

    const a3 = allocator.alloc(u8, 10);
    try testing.expectError(error.OutOfMemory, a3);
}
```

Essential for testing error handling in allocation-heavy code.

[zig-0.15.2/lib/std/testing/FailingAllocator.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig)

**ZLS Custom Implementation**: ZLS has a custom `FailingAllocator` with probabilistic failures:

```zig
pub const FailingAllocator = struct {
    internal_allocator: std.mem.Allocator,
    random: std.Random.DefaultPrng,
    likelihood: u32,

    /// the chance that an allocation will fail is `1/likelihood`
    pub fn init(internal_allocator: std.mem.Allocator, likelihood: u32) FailingAllocator {
        return .{
            .internal_allocator = internal_allocator,
            .random = .init(std.crypto.random.int(u64)),
            .likelihood = likelihood,
        };
    }

    fn shouldFail(self: *FailingAllocator) bool {
        if (self.likelihood == std.math.maxInt(u32)) return false;
        return 0 == self.random.random().intRangeAtMostBiased(u32, 0, self.likelihood);
    }
};
```

[zls/src/testing.zig#L67-L141](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)

### Additional Utilities

#### `testing.random_seed`

A deterministic seed initialized at test startup. Useful for reproducible randomness:

```zig
var prng = std.Random.DefaultPrng.init(testing.random_seed);
const random = prng.random();
const value = random.int(u32);
```

The seed is printed at test start, allowing reproduction of failures.

[zig-0.15.2/lib/std/testing.zig#L6-L8](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L6-L8)

#### `expectFmt(expected: []const u8, comptime template: []const u8, args: anytype) !void`

Asserts that formatted output matches expected string:

```zig
try testing.expectFmt("value: 42", "value: {d}", .{42});
```

[zig-0.15.2/lib/std/testing.zig#L269-L281](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig#L269-L281)

### Production Testing Utilities

**TigerBeetle Snapshot Testing**: TigerBeetle's `snaptest.zig` provides auto-updating snapshot assertions:

```zig
const Snap = @import("snaptest.zig").Snap;
const snap = Snap.snap_fn("src");

test "addition" {
    const result = 2 + 2;
    try snap(@src(),
        \\4
    ).diff_fmt("{}", .{result});
}
```

Running with `SNAP_UPDATE=1` automatically updates the source code snapshot on mismatch.

[tigerbeetle/src/stdx/testing/snaptest.zig#L1-L100](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L1-L100)

**ZLS Custom Assertions**: ZLS provides JSON-based comparison for semantic equality:

```zig
pub fn expectEqual(expected: anytype, actual: anytype) error{TestExpectedEqual}!void {
    const expected_json = std.json.Stringify.valueAlloc(allocator, expected, .{
        .whitespace = .indent_2,
    }) catch @panic("OOM");
    defer allocator.free(expected_json);

    const actual_json = std.json.Stringify.valueAlloc(allocator, actual, .{
        .whitespace = .indent_2,
    }) catch @panic("OOM");
    defer allocator.free(actual_json);

    if (std.mem.eql(u8, expected_json, actual_json)) return;
    renderLineDiff(allocator, expected_json, actual_json);
    return error.TestExpectedEqual;
}
```

[zls/src/testing.zig#L9-L26](https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26)

### Citations: std.testing API

- [zig-0.15.2/lib/std/testing.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig) - Complete testing module
- [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig) - Snapshot testing implementation
- [ZLS testing.zig](https://github.com/zigtools/zls/blob/master/src/testing.zig) - Custom testing utilities

---

## Test Organization Patterns

### Colocated vs Separate Test Files

**Colocated Tests** (Recommended): Tests live in the same file as implementation:

```zig
// src/queue.zig
pub const Queue = struct {
    // Implementation
};

test "Queue: basic operations" {
    // Test implementation
}

test "Queue: edge cases" {
    // More tests
}
```

**Advantages**:
- Tests stay synchronized with implementation
- Easy to find relevant tests
- Encourages testing as part of development
- `zig test src/queue.zig` runs all relevant tests

**Separate Test Files**: Some projects use dedicated test files:

```
src/
  queue.zig
  queue_test.zig    # or tests/queue_test.zig
```

Less common in Zig due to the seamless integration of colocated tests.

### Test Directory Conventions

**Standard Library Pattern**: Tests colocated, with test-only modules in `testing/`:

```
std/
  array_list.zig           # Implementation + tests
  hash_map.zig             # Implementation + tests
  testing.zig              # Main testing module
  testing/
    FailingAllocator.zig   # Reusable test utilities
```

**TigerBeetle Pattern**: Extensive `testing/` infrastructure for reusable components:

```
src/
  vsr.zig                  # Implementation
  state_machine.zig        # Implementation
  testing/
    fuzz.zig               # Fuzzing utilities
    time.zig               # TimeSim for deterministic time
    fixtures.zig           # Test fixtures and initialization helpers
    storage.zig            # Storage simulator
    packet_simulator.zig   # Network simulation
    cluster/
      message_bus.zig      # Cluster testing infrastructure
      state_checker.zig    # State invariant checkers
```

This pattern separates:
- **Production code**: Core implementation
- **Test code**: Colocated test blocks
- **Test infrastructure**: Reusable testing utilities

[tigerbeetle/src/testing/](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing)

### Shared Test Utilities

Extract common test setup into dedicated modules:

```zig
// testing/fixtures.zig
pub fn init_storage(allocator: std.mem.Allocator, options: StorageOptions) !Storage {
    return try Storage.init(allocator, options);
}

pub fn init_grid(allocator: std.mem.Allocator, superblock: *SuperBlock) !Grid {
    return try Grid.init(allocator, .{ .superblock = superblock });
}
```

**TigerBeetle Fixtures**: Centralized initialization with sensible defaults:

```zig
pub const cluster: u128 = 0;
pub const replica: u8 = 0;
pub const replica_count: u8 = 6;

pub fn init_time(options: struct {
    resolution: u64 = constants.tick_ms * std.time.ns_per_ms,
    offset_type: OffsetType = .linear,
    offset_coefficient_A: i64 = 0,
    offset_coefficient_B: i64 = 0,
}) TimeSim {
    return .{
        .resolution = options.resolution,
        .offset_type = options.offset_type,
        .offset_coefficient_A = options.offset_coefficient_A,
        .offset_coefficient_B = options.offset_coefficient_B,
    };
}
```

This design:
- Provides defaults for most options
- Requires passing `.{}` at call sites (making customization explicit)
- Centralizes complex initialization logic

[tigerbeetle/src/testing/fixtures.zig#L33-L52](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig#L33-L52)

### Test Fixtures and Setup/Teardown

Zig doesn't have built-in setup/teardown hooks. Instead, use explicit initialization:

```zig
test "with setup and teardown" {
    // Setup
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit(); // Teardown

    const allocator = arena.allocator();

    // Test body
    const list = try std.ArrayList(u32).initCapacity(allocator, 10);
    try list.append(42);
    try testing.expectEqual(1, list.items.len);

    // Arena deinit handles cleanup automatically
}
```

**Pattern: Arena Allocator for Tests**:
```zig
test "complex test with multiple allocations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    // All allocations from arena.allocator() are freed at once
    const data1 = try arena.allocator().alloc(u8, 100);
    const data2 = try arena.allocator().alloc(u32, 50);
    // No individual free() needed
}
```

### Using `builtin.is_test` for Test-Only Code

The `builtin.is_test` flag conditionally compiles test-specific code:

```zig
const builtin = @import("builtin");

pub const Database = struct {
    // ... production fields

    pub fn query(self: *Database, sql: []const u8) !Result {
        // Production implementation
    }

    // Test-only method
    pub fn seedTestData(self: *Database) !void {
        if (!builtin.is_test) @compileError("seedTestData is test-only");
        // Insert test fixtures
    }
};

test "database with test data" {
    var db = try Database.init(testing.allocator);
    defer db.deinit();

    try db.seedTestData(); // OK in tests

    const result = try db.query("SELECT * FROM users");
    try testing.expect(result.rows.len > 0);
}
```

**Production Build Guarantee**: Test-only code doesn't exist in release builds, ensuring zero runtime cost.

**TigerBeetle Example**: Snaptest uses comptime assertion:

```zig
pub const Snap = struct {
    comptime {
        assert(builtin.is_test);
    }
    // ...
};
```

This ensures `Snap` can only be used in test contexts.

[tigerbeetle/src/stdx/testing/snaptest.zig#L74-L76](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76)

### Build System Integration

Integrate tests with `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Test executable
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
```

Run tests with: `zig build test`

**Test Filtering in Build System**:
```zig
const test_filter = b.option([]const u8, "test-filter", "Filter tests by name");
if (test_filter) |filter| {
    tests.filters = &.{filter};
}
```

### Test Naming Conventions

**Descriptive Names**: Use full sentences for clarity:

```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}

test "HashMap: remove decrements count" {
    // ...
}
```

**Stdlib Pattern**: Often includes the type/module name:

```zig
test "init" {
    const list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();
    try testing.expectEqual(0, list.items.len);
}
```

[zig-0.15.2/lib/std/array_list.zig#L1428](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig#L1428)

**TigerBeetle State Machine Tests**: Descriptive scenario-based names:

```zig
test "TestContext: basic operations" {
    // ...
}
```

[tigerbeetle/src/state_machine_tests.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine_tests.zig)

### Citations: Test Organization

- [Zig Build System Guide](https://ziglang.org/learn/build-system/) - Test integration
- [TigerBeetle testing/ directory](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing) - Production test infrastructure
- [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig) - Fixture pattern
- [zig-0.15.2/lib/std/array_list.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig) - Colocated test examples

---

## Advanced Testing Techniques

### Parameterized and Table-Driven Tests

Parameterized tests use comptime iteration to generate test cases:

```zig
test "integer parsing: multiple cases" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .input = "0", .expected = 0 },
        .{ .input = "42", .expected = 42 },
        .{ .input = "-10", .expected = -10 },
        .{ .input = "2147483647", .expected = 2147483647 },
    };

    inline for (cases) |case| {
        const result = try std.fmt.parseInt(i32, case.input, 10);
        try testing.expectEqual(case.expected, result);
    }
}
```

**Inline for**: The `inline for` loop unrolls at compile time, generating a separate assertion for each case. This provides granular failure reporting—if one case fails, you know exactly which one.

**Advanced: Comptime Type Generation**:

```zig
test "generic list operations" {
    const types = [_]type{ u8, u16, u32, u64 };

    inline for (types) |T| {
        var list = std.ArrayList(T).init(testing.allocator);
        defer list.deinit();

        try list.append(1);
        try testing.expectEqual(@as(T, 1), list.items[0]);
    }
}
```

This pattern tests the same logic across multiple types without code duplication.

**See Example**: [03_parameterized_tests](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests)

### Comptime Test Generation

Generate tests programmatically at compile time:

```zig
fn makeTest(comptime value: i32) type {
    return struct {
        test {
            try testing.expectEqual(value, value);
        }
    };
}

test {
    _ = makeTest(1);
    _ = makeTest(2);
    _ = makeTest(3);
}
```

**Real-World Use**: Testing a parser against multiple input formats, testing serialization for different types, or validating compile-time computations.

### Testing with Allocators

**Memory Leak Detection**:

```zig
test "no memory leaks" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Required - test fails without this

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

If `list.deinit()` is omitted, `testing.allocator` reports a leak:

```
Test [1/1] test.no memory leaks... FAIL (error.MemoryLeakDetected)
Memory leak detected: 40 bytes not freed
```

**FailingAllocator for Error Paths**:

```zig
test "handle allocation failure gracefully" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    const result = std.ArrayList(u32).initCapacity(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

This ensures error handling code is actually exercised.

**TigerBeetle Storage Allocator**: Custom allocator for storage simulation:

```zig
pub const Storage = struct {
    allocator: std.mem.Allocator,
    // ...

    pub fn init(allocator: std.mem.Allocator, options: Options) !Storage {
        return Storage{
            .allocator = allocator,
            // ...
        };
    }
};
```

[tigerbeetle/src/testing/storage.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/storage.zig)

**See Example**: [04_allocator_testing](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing)

### Testing Concurrent Code

Zig 0.15+ has simplified async handling, but concurrency testing still requires care:

```zig
test "concurrent access to shared state" {
    const Worker = struct {
        fn run(counter: *std.atomic.Value(u32)) void {
            for (0..1000) |_| {
                _ = counter.fetchAdd(1, .monotonic);
            }
        }
    };

    var counter = std.atomic.Value(u32).init(0);

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, Worker.run, .{&counter});
    }

    for (threads) |t| {
        t.join();
    }

    try testing.expectEqual(4000, counter.load(.monotonic));
}
```

**Deterministic Concurrency Testing**: TigerBeetle's approach using controlled time:

```zig
pub const TimeSim = struct {
    resolution: u64,
    ticks: u64 = 0,

    pub fn tick(self: *TimeSim) void {
        self.ticks += 1;
    }

    fn monotonic(context: *anyopaque) u64 {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        return self.ticks * self.resolution;
    }
};
```

By controlling time explicitly, TigerBeetle tests distributed consensus deterministically.

[tigerbeetle/src/testing/time.zig#L12-L98](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98)

### Testing Error Paths

Use `expectError` to validate error handling:

```zig
test "parseNumber: handles invalid input" {
    const result = parseNumber("not a number");
    try testing.expectError(error.InvalidFormat, result);
}

test "File.open: handles missing file" {
    const result = std.fs.cwd().openFile("nonexistent.txt", .{});
    try testing.expectError(error.FileNotFound, result);
}
```

**Comprehensive Error Testing with FailingAllocator**:

```zig
test "robustness under allocation failures" {
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = i });
        const allocator = failing.allocator();

        const result = createComplexStructure(allocator);

        // Either succeeds or fails with OutOfMemory
        if (result) |value| {
            defer value.deinit(allocator);
            try testing.expect(value.isValid());
        } else |err| {
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}
```

This exhaustively tests failure at each allocation point.

### Integration Testing Patterns

Integration tests verify interactions between components:

```zig
test "HTTP server: end-to-end request handling" {
    // Start server
    var server = try Server.init(testing.allocator, .{ .port = 0 });
    defer server.deinit();

    const address = try server.start();
    defer server.stop();

    // Make request
    var client = std.http.Client{ .allocator = testing.allocator };
    defer client.deinit();

    const response = try client.get(address);
    defer response.deinit();

    try testing.expectEqual(.ok, response.status);
}
```

**Ghostty FontConfig Integration Test**:

```zig
test "fc-match" {
    var cfg = fontconfig.initLoadConfigAndFonts();
    defer cfg.destroy();

    var pat = fontconfig.Pattern.create();
    errdefer pat.destroy();
    try testing.expect(cfg.substituteWithPat(pat, .pattern));
    pat.defaultSubstitute();

    const result = cfg.fontSort(pat, false, null);
    errdefer result.fs.destroy();

    // Verify fonts were matched
    const fonts = result.fs.fonts();
    try testing.expect(fonts.len > 0);
}
```

[ghostty/pkg/fontconfig/test.zig#L24-L66](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig#L24-L66)

### Fuzzing and Property-Based Testing

TigerBeetle demonstrates advanced fuzzing utilities:

```zig
/// Returns an integer with exponential distribution of rate `avg`
pub fn random_int_exponential(prng: *PRNG, comptime T: type, avg: T) T {
    const random = std.Random.init(prng, PRNG.fill);
    const exp = random.floatExp(f64) * @as(f64, @floatFromInt(avg));
    return std.math.lossyCast(T, exp);
}

/// Swarm testing: some variants disabled, rest have wildly different probabilities
pub fn random_enum_weights(prng: *PRNG, comptime Enum: type) PRNG.EnumWeightsType(Enum) {
    const fields = comptime std.meta.fieldNames(Enum);

    var combination = PRNG.Combination.init(.{
        .total = fields.len,
        .sample = prng.range_inclusive(u32, 1, fields.len),
    });

    var weights: PRNG.EnumWeightsType(Enum) = undefined;
    inline for (fields) |field| {
        @field(weights, field) = if (combination.take(prng))
            prng.range_inclusive(u64, 1, 100)
        else
            0;
    }

    return weights;
}
```

These utilities enable sophisticated randomized testing with controlled distributions.

[tigerbeetle/src/testing/fuzz.zig#L14-L55](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig#L14-L55)

### Citations: Advanced Testing

- [Example 03: Parameterized Tests](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests)
- [Example 04: Allocator Testing](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing)
- [TigerBeetle fuzz.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig) - Fuzzing utilities
- [TigerBeetle time.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig) - Deterministic time simulation
- [Ghostty test.zig](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig) - Integration test example

---

## Benchmarking Best Practices

Benchmarking in Zig is manual—there's no built-in benchmark framework like Go's `testing.B`. This provides full control but requires understanding of measurement pitfalls.

### std.time.Timer API

`std.time.Timer` provides monotonic, high-precision timing:

```zig
const std = @import("std");

pub fn main() !void {
    var timer = try std.time.Timer.start();

    // Code to measure
    expensiveOperation();

    const elapsed_ns = timer.read();
    std.debug.print("Elapsed: {} ns\n", .{elapsed_ns});
}
```

**Key Methods**:
- `start() !Timer`: Initialize timer (may fail if no monotonic clock available)
- `read() u64`: Read elapsed nanoseconds since start/reset
- `reset()`: Reset timer to zero
- `lap() u64`: Read elapsed time and reset in one operation

**Timer Implementation**: Uses platform-specific monotonic clocks:
- Linux: `CLOCK_BOOTTIME` (includes suspend time)
- macOS: `CLOCK_UPTIME_RAW`
- Windows: `QueryPerformanceCounter`

[zig-0.15.2/lib/std/time.zig#L216-L268](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/time.zig#L216-L268)

### Manual Timing Techniques

**Basic Timing**:

```zig
const std = @import("std");

fn benchmarkSort() !void {
    var data = [_]u32{5, 2, 8, 1, 9};

    var timer = try std.time.Timer.start();
    std.mem.sort(u32, &data, {}, comptime std.sort.asc(u32));
    const elapsed = timer.read();

    std.debug.print("Sort took {} ns\n", .{elapsed});
}
```

**Problem**: Single measurements are unreliable due to:
- CPU frequency scaling
- Cache effects (cold vs warm)
- OS scheduling
- Background processes

**Solution**: Multiple iterations with statistical analysis (see Example 05).

### std.mem.doNotOptimizeAway

Critical function to prevent compiler optimizations from eliminating benchmarked code:

```zig
pub fn doNotOptimizeAway(value: anytype) void {
    asm volatile ("" :: [_]"r,m" (value));
}
```

**Why it's needed**:

Without `doNotOptimizeAway`:
```zig
// ❌ Compiler may optimize this away entirely
for (0..1000) |_| {
    const result = expensiveFunction();
    // result unused - dead code elimination
}
```

With `doNotOptimizeAway`:
```zig
// ✅ Compiler must keep the function call
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}
```

The inline assembly with a memory/register constraint forces the compiler to treat the value as "used".

**Example from Benchmark Module**:

```zig
pub fn benchmark(comptime Func: type, func: Func, iterations: u64) !BenchmarkResult {
    var iter: u64 = 0;
    var timer = try std.time.Timer.start();

    while (iter < iterations) : (iter += 1) {
        const result = func();
        std.mem.doNotOptimizeAway(&result);  // Critical!
    }

    const elapsed = timer.read();
    return BenchmarkResult{ .avg_ns = elapsed / iterations };
}
```

[Example 05: benchmark.zig#L82-L86](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/src/benchmark.zig#L82-L86)

### Warm-up Iterations

Cold starts skew results. Always include a warm-up phase:

```zig
// Warm-up: 10% of iterations or max 100
const warmup_iterations = @min(iterations / 10, 100);
for (0..warmup_iterations) |_| {
    const result = func();
    std.mem.doNotOptimizeAway(&result);
}

// Now measure with warm caches and stable CPU frequency
var timer = try std.time.Timer.start();
for (0..iterations) |_| {
    const result = func();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
```

**What warm-up stabilizes**:
- CPU frequency (modern CPUs scale based on load)
- L1/L2 cache state (loads hot paths into cache)
- Branch predictor state (trains the predictor)
- TLB (translation lookaside buffer)

[Example 05: benchmark.zig#L52-L60](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/src/benchmark.zig#L52-L60)

### Statistical Measurement

Never rely on a single measurement. Collect samples and compute statistics:

```zig
const num_samples = 10;
const iterations_per_sample = iterations / num_samples;

var samples: [10]u64 = undefined;

for (0..num_samples) |i| {
    var timer = try std.time.Timer.start();

    for (0..iterations_per_sample) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    samples[i] = timer.read();
}

// Compute min, max, mean, variance
var min_ns: u64 = std.math.maxInt(u64);
var max_ns: u64 = 0;
var total_ns: u64 = 0;

for (samples) |sample| {
    min_ns = @min(min_ns, sample);
    max_ns = @max(max_ns, sample);
    total_ns += sample;
}

const avg_ns = total_ns / num_samples;

// Variance
var variance_sum: u128 = 0;
for (samples) |sample| {
    const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
    variance_sum += @as(u128, diff) * @as(u128, diff);
}
const variance = variance_sum / num_samples;
```

**Why multiple samples**:
- Identify outliers (context switches, interrupts)
- Measure consistency (variance)
- Increase confidence in the mean

[Example 05: benchmark.zig#L93-L112](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/src/benchmark.zig#L93-L112)

### Build Modes for Benchmarking

Always benchmark in release mode:

```bash
# ❌ Debug mode (slow, includes safety checks)
zig build-exe benchmark.zig

# ✅ ReleaseFast (maximum speed)
zig build-exe -O ReleaseFast benchmark.zig

# ✅ ReleaseSmall (optimized for size, still fast)
zig build-exe -O ReleaseSmall benchmark.zig

# ❌ ReleaseSafe (includes runtime safety, slower)
zig build-exe -O ReleaseSafe benchmark.zig
```

**Debug vs ReleaseFast**: Can differ by 10-100x in performance.

**Build.zig Configuration**:
```zig
const benchmark = b.addExecutable(.{
    .name = "benchmark",
    .root_source_file = b.path("src/benchmark.zig"),
    .target = target,
    .optimize = .ReleaseFast,  // Force release mode
});
```

### Common Benchmarking Mistakes

**❌ Mistake 1: Not using doNotOptimizeAway**
```zig
// Entire loop may be optimized away
for (0..1000) |_| {
    const result = compute();
}
```

**✅ Correct**:
```zig
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
```

**❌ Mistake 2: No warm-up phase**
```zig
// First iterations will be slow (cold cache)
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    compute();
}
```

**✅ Correct**:
```zig
// Warm up first
for (0..100) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}

// Then measure
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
```

**❌ Mistake 3: Single measurement**
```zig
var timer = try std.time.Timer.start();
compute();
const elapsed = timer.read();
// Unreliable - could be affected by context switch
```

**✅ Correct**:
```zig
// Take multiple samples
const samples = 10;
var times: [10]u64 = undefined;
for (&times) |*t| {
    var timer = try std.time.Timer.start();
    compute();
    t.* = timer.read();
}
// Compute statistics from samples
```

**❌ Mistake 4: Measuring in Debug mode**
```zig
// zig build-exe benchmark.zig
// Results meaningless due to lack of optimization
```

**✅ Correct**:
```zig
// zig build-exe -O ReleaseFast benchmark.zig
// Realistic performance numbers
```

### Real-World Benchmark Example

From Example 05:

```zig
const std = @import("std");
const benchmark = @import("benchmark.zig");

fn sumIterative(n: u64) u64 {
    var sum: u64 = 0;
    var i: u64 = 1;
    while (i <= n) : (i += 1) {
        sum += i;
    }
    return sum;
}

fn sumFormula(n: u64) u64 {
    return (n * (n + 1)) / 2;
}

pub fn main() !void {
    const iterations = 1_000_000;
    const n = 1000;

    // Benchmark iterative
    const iterative_result = try benchmark.benchmarkWithArg(
        @TypeOf(sumIterative),
        sumIterative,
        n,
        iterations,
    );

    // Benchmark formula
    const formula_result = try benchmark.benchmarkWithArg(
        @TypeOf(sumFormula),
        sumFormula,
        n,
        iterations,
    );

    // Compare
    const stdout = std.io.getStdOut().writer();
    try benchmark.compareBenchmarks(
        stdout,
        "Formula",
        formula_result,
        "Iterative",
        iterative_result,
    );
}
```

[Example 05: main.zig](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/src/main.zig)

### Citations: Benchmarking

- [zig-0.15.2/lib/std/time.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/time.zig) - Timer implementation
- [Example 05: Benchmarking](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking) - Complete benchmark suite
- [zig-0.15.2/lib/std/mem.zig - doNotOptimizeAway](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/mem.zig) - Optimization barrier

---

## Profiling Integration

Profiling requires external tools. Zig provides the necessary build flags and symbol information.

### Build Configuration for Profiling

To profile effectively, you need:
1. **Optimization**: Realistic performance (`-O ReleaseFast`)
2. **Debug symbols**: For function names and line numbers
3. **No stripping**: Preserve symbols for profilers

```bash
# Command-line profiling build
zig build-exe -O ReleaseFast -Dcpu=baseline src/main.zig

# Or via build.zig
zig build -Doptimize=ReleaseFast -Dstrip=false
```

**Build.zig Configuration**:
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,  // Keep symbols for profiling
    });

    b.installArtifact(exe);
}
```

**Why baseline CPU?**: `-Dcpu=baseline` ensures the binary runs on any CPU of that architecture (avoids CPU-specific optimizations that might not transfer).

[Example 06: build.zig](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/build.zig)

### Callgrind (Valgrind) Integration

Callgrind provides function-level profiling with call graphs.

**Running Callgrind**:
```bash
# Build with symbols
zig build -Doptimize=ReleaseFast

# Profile
valgrind --tool=callgrind ./zig-out/bin/myapp

# Generates callgrind.out.<pid>
```

**Analyzing Results**:
```bash
# View in KCachegrind (GUI)
kcachegrind callgrind.out.12345

# Or command-line summary
callgrind_annotate callgrind.out.12345
```

**Callgrind Output Example**:
```
Profile data file 'callgrind.out.12345' (creator: callgrind-3.19.0)
Total instructions: 1,234,567,890

Function                        Instructions  %
-----------------------------------------------
compute                          500,000,000  40.5%
std.ArrayList.append             200,000,000  16.2%
std.mem.copy                     150,000,000  12.2%
...
```

**Advantages**:
- Exact instruction counts (deterministic)
- Function-level and line-level detail
- Call graph visualization

**Disadvantages**:
- Very slow (10-100x slowdown)
- Not real-time profiling

[Example 06: profile_callgrind.sh](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/scripts/profile_callgrind.sh)

### Linux perf

`perf` is a powerful sampling profiler with hardware counter support.

**Basic Profiling**:
```bash
# Record profile
perf record -F 999 -g ./zig-out/bin/myapp

# View results
perf report
```

**Flame Graph Generation**:
```bash
# Record with call graphs
perf record -F 999 -g ./zig-out/bin/myapp

# Convert to flame graph format
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**perf Options**:
- `-F 999`: Sample at 999Hz (odd number reduces aliasing)
- `-g`: Record call graphs
- `--call-graph dwarf`: Use DWARF for better stack traces (larger data)

**Advantages**:
- Low overhead (typically <5%)
- Real-time profiling
- Hardware counters (cache misses, branch mispredictions)

**Disadvantages**:
- Statistical (not deterministic)
- Requires root or `perf_event_paranoid` adjustment

[Example 06: profile_perf.sh](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/scripts/profile_perf.sh)

### Massif (Heap Profiling)

Massif tracks heap allocations over time.

**Running Massif**:
```bash
# Profile heap usage
valgrind --tool=massif ./zig-out/bin/myapp

# Generates massif.out.<pid>
```

**Analyzing**:
```bash
# Text summary
ms_print massif.out.12345

# GUI (if available)
massif-visualizer massif.out.12345
```

**Massif Output Example**:
```
    MB
3.0 |                                                            #
    |                                                           :#
    |                                                          @:#
    |                                                         :@:#
2.0 |                                                        ::@:#
    |                                                       :::@:#
    |                                              @       @:::@:#
    |                                             :@      @@:::@:#
1.0 |                                            ::@     :@@:::@:#
    |                                    @      :::@    ::@@:::@:#
    |                            @      :@     ::::@   :::@@:::@:#
    |                           :@     ::@    :::::@  ::::@@:::@:#
0.0 +-----------------------------------------------------------------------
      0                                                              1000 ms
```

**Advantages**:
- Shows allocation patterns over time
- Identifies memory leaks and bloat
- Snapshots show detailed heap state

**Disadvantages**:
- Significant slowdown
- Requires Valgrind-compatible system

[Example 06: profile_massif.sh](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/scripts/profile_massif.sh)

### Flame Graph Generation

Flame graphs visualize profiling data as interactive SVGs.

**Setup**:
```bash
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph
```

**From perf**:
```bash
perf record -F 999 -g ./zig-out/bin/myapp
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**From Callgrind** (via custom converter):
```bash
valgrind --tool=callgrind ./zig-out/bin/myapp
# Use callgrind_annotate or custom scripts to convert
```

**Reading Flame Graphs**:
- X-axis: Alphabetical sort (not time)
- Y-axis: Stack depth (bottom = entry, top = leaf)
- Width: Time spent in function (or descendants)
- Color: Typically random (or categorized by module)

**Example**: Wide plateau at bottom = hot path consuming most time.

[FlameGraph GitHub](https://github.com/brendangregg/FlameGraph)

### Profiling Overhead Considerations

**Callgrind**:
- Overhead: 10-100x slowdown
- Impact: Totally changes performance characteristics
- Use for: Instruction counts, relative comparisons

**perf**:
- Overhead: <5% typically
- Impact: Minimal on real-world performance
- Use for: Production-like profiling

**Massif**:
- Overhead: 5-20x slowdown
- Impact: Slows allocation-heavy code significantly
- Use for: Memory analysis, not performance

**Build Mode Impact**:
- Debug: 10-100x slower than ReleaseFast
- ReleaseSafe: ~2x slower due to safety checks
- ReleaseFast: Baseline for profiling
- ReleaseSmall: Similar to ReleaseFast but optimized for size

### Example Profiling Workflow

From Example 06:

```bash
# 1. Build optimized with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# 2. Profile with perf
perf record -F 999 -g ./zig-out/bin/profiling-demo

# 3. Generate flame graph
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg

# 4. Open flamegraph.svg in browser

# 5. For detailed analysis, use callgrind
valgrind --tool=callgrind ./zig-out/bin/profiling-demo
kcachegrind callgrind.out.*

# 6. For memory analysis
valgrind --tool=massif ./zig-out/bin/profiling-demo
ms_print massif.out.*
```

[Example 06: Profiling](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling)

### Citations: Profiling

- [Valgrind Callgrind Documentation](https://valgrind.org/docs/manual/cl-manual.html)
- [Linux perf Tutorial](https://perf.wiki.kernel.org/index.php/Tutorial)
- [Brendan Gregg's Flame Graphs](https://www.brendangregg.com/flamegraphs.html)
- [Valgrind Massif Documentation](https://valgrind.org/docs/manual/ms-manual.html)
- [Example 06: Profiling](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling)

---

## Common Pitfalls and Solutions

### Pitfall 1: Forgetting to Free Allocations

**❌ Problem**:
```zig
test "memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    // Forgot list.deinit()

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
// Test fails: memory leak detected
```

**✅ Solution**:
```zig
test "no memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit();  // Always defer cleanup

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

**Pattern**: Always pair allocation with `defer` cleanup immediately.

---

### Pitfall 2: Not Testing Error Paths

**❌ Problem**:
```zig
// Only tests happy path
test "parseNumber works" {
    const result = try parseNumber("42");
    try testing.expectEqual(42, result);
}
// What if input is invalid? Untested!
```

**✅ Solution**:
```zig
test "parseNumber: valid input" {
    const result = try parseNumber("42");
    try testing.expectEqual(42, result);
}

test "parseNumber: invalid input" {
    const result = parseNumber("not a number");
    try testing.expectError(error.InvalidFormat, result);
}

test "parseNumber: overflow" {
    const result = parseNumber("999999999999999999999");
    try testing.expectError(error.Overflow, result);
}
```

**Pattern**: Test both success and failure cases. Use `FailingAllocator` to test allocation failures.

---

### Pitfall 3: Benchmarking Without doNotOptimizeAway

**❌ Problem**:
```zig
// Compiler may optimize away the entire loop
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    // result unused - dead code elimination
}
const elapsed = timer.read();
```

**✅ Solution**:
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);  // Force compiler to keep it
}
const elapsed = timer.read();
```

**Pattern**: Always use `std.mem.doNotOptimizeAway` in benchmarks.

---

### Pitfall 4: Single Benchmark Measurement

**❌ Problem**:
```zig
// Unreliable - affected by context switches, cache state
var timer = try std.time.Timer.start();
expensiveOperation();
const elapsed = timer.read();
std.debug.print("Took {} ns\n", .{elapsed});
```

**✅ Solution**:
```zig
// Take multiple samples and compute statistics
const num_samples = 10;
var samples: [10]u64 = undefined;

for (&samples) |*sample| {
    var timer = try std.time.Timer.start();
    expensiveOperation();
    sample.* = timer.read();
}

// Compute min, max, mean
var min: u64 = std.math.maxInt(u64);
var max: u64 = 0;
var sum: u64 = 0;

for (samples) |s| {
    min = @min(min, s);
    max = @max(max, s);
    sum += s;
}

const avg = sum / num_samples;
std.debug.print("Min: {} ns, Max: {} ns, Avg: {} ns\n", .{min, max, avg});
```

**Pattern**: Always collect multiple samples and report statistics.

---

### Pitfall 5: Benchmarking in Debug Mode

**❌ Problem**:
```zig
// Compiled with: zig build-exe benchmark.zig
// Results are 10-100x slower than release mode
```

**✅ Solution**:
```bash
# Always benchmark in release mode
zig build-exe -O ReleaseFast benchmark.zig
```

**Pattern**: Use `ReleaseFast` for benchmarks. Verify mode in build.zig.

---

### Pitfall 6: No Warm-up Phase

**❌ Problem**:
```zig
// First iterations are slow (cold cache, CPU throttled)
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    compute();
}
const elapsed = timer.read();
```

**✅ Solution**:
```zig
// Warm-up phase
for (0..100) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}

// Now measure with warm cache and stable CPU
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
```

**Pattern**: Always warm up before measurement.

---

### Pitfall 7: Profiling Without Debug Symbols

**❌ Problem**:
```bash
# Stripped binary loses function names
zig build -Doptimize=ReleaseFast -Dstrip=true
perf record ./zig-out/bin/myapp
perf report
# Shows only addresses, no function names
```

**✅ Solution**:
```bash
# Keep symbols for profiling
zig build -Doptimize=ReleaseFast -Dstrip=false
perf record ./zig-out/bin/myapp
perf report
# Shows function names and line numbers
```

**Pattern**: Always build with symbols for profiling (`-Dstrip=false`).

---

### Pitfall 8: Testing Implementation Details

**❌ Problem**:
```zig
test "ArrayList internal capacity" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    // Testing internal implementation detail
    try testing.expect(list.capacity == 0);
    try list.append(1);
    try testing.expect(list.capacity >= 1);  // Fragile - implementation may change
}
```

**✅ Solution**:
```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try testing.expectEqual(0, list.items.len);
    try list.append(1);
    try testing.expectEqual(1, list.items.len);
    try testing.expectEqual(1, list.items[0]);
}
```

**Pattern**: Test behavior, not implementation. Focus on public API.

---

### Pitfall 9: Race Conditions in Concurrent Tests

**❌ Problem**:
```zig
test "concurrent counter" {
    var counter: u32 = 0;  // No synchronization

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *u32) void {
                for (0..1000) |_| {
                    c.* += 1;  // Race condition
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| t.join();

    try testing.expectEqual(4000, counter);  // May fail randomly
}
```

**✅ Solution**:
```zig
test "concurrent atomic counter" {
    var counter = std.atomic.Value(u32).init(0);

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *std.atomic.Value(u32)) void {
                for (0..1000) |_| {
                    _ = c.fetchAdd(1, .monotonic);  // Atomic operation
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| t.join();

    try testing.expectEqual(4000, counter.load(.monotonic));
}
```

**Pattern**: Use atomics or mutexes for shared state in concurrent tests.

---

### Pitfall 10: Ignoring Test Allocator Failures

**❌ Problem**:
```zig
test "list operations" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = try std.ArrayList(u32).initCapacity(allocator, 10);
    try list.append(42);
    list.deinit();

    // Forgot to check for leaks!
}
```

**✅ Solution**:
```zig
test "list operations" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    var list = try std.ArrayList(u32).initCapacity(allocator, 10);
    defer list.deinit();

    try list.append(42);
}

// Or just use testing.allocator which checks automatically
test "list operations (better)" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit();

    try list.append(42);
    // testing.allocator automatically checks for leaks
}
```

**Pattern**: Use `testing.allocator` which automatically detects leaks.

---

### Pitfall 11: Hardcoded Test Data Paths

**❌ Problem**:
```zig
test "load config file" {
    const config = try loadConfig("/home/user/test/config.json");  // Hardcoded path
    try testing.expect(config.valid);
}
```

**✅ Solution**:
```zig
test "load config file" {
    const config_content =
        \\{ "setting": "value" }
    ;

    // Use testing.tmpDir or write to temp file
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const path = try tmp.dir.realpathAlloc(testing.allocator, ".");
    defer testing.allocator.free(path);

    const file_path = try std.fs.path.join(testing.allocator, &.{path, "config.json"});
    defer testing.allocator.free(file_path);

    try tmp.dir.writeFile(.{ .sub_path = "config.json", .data = config_content });

    const config = try loadConfig(file_path);
    try testing.expect(config.valid);
}
```

**Pattern**: Use relative paths or create temporary files in tests.

---

### Pitfall 12: Not Handling Async Cleanup

**❌ Problem**:
```zig
test "async resource leak" {
    const resource = try acquireResource();
    // Test logic...
    // Forgot to release resource
}
```

**✅ Solution**:
```zig
test "async resource cleanup" {
    const resource = try acquireResource();
    defer releaseResource(resource);  // Guaranteed cleanup

    // Test logic...
}
```

**Pattern**: Always use `defer` for cleanup, especially with async operations.

---

### Pitfall 13: Comparing Floats with expectEqual

**❌ Problem**:
```zig
test "float equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectEqual(2.0, result);  // May fail due to floating-point precision
}
```

**✅ Solution**:
```zig
test "float approximate equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectApproxEqAbs(2.0, result, 1e-10);  // Tolerance for rounding
}
```

**Pattern**: Use `expectApproxEqAbs` or `expectApproxEqRel` for floating-point comparisons.

---

### Pitfall 14: Over-reliance on Random Tests

**❌ Problem**:
```zig
test "random behavior" {
    var prng = std.Random.DefaultPrng.init(std.time.timestamp());
    const random = prng.random();

    const value = random.int(u32);
    // Test logic based on random value...
    // Hard to reproduce failures
}
```

**✅ Solution**:
```zig
test "deterministic random behavior" {
    var prng = std.Random.DefaultPrng.init(testing.random_seed);  // Deterministic
    const random = prng.random();

    const value = random.int(u32);
    // Test logic...
    // Failures are reproducible with same seed
}
```

**Pattern**: Use `testing.random_seed` for reproducible randomness.

---

### Pitfall 15: Ignoring Test Failure Context

**❌ Problem**:
```zig
test "complex scenario" {
    // Multiple operations without context
    try operation1();
    try operation2();
    try operation3();
    // Which one failed?
}
```

**✅ Solution**:
```zig
test "complex scenario with context" {
    std.debug.print("Starting operation1\n", .{});
    try operation1();

    std.debug.print("Starting operation2\n", .{});
    try operation2();

    std.debug.print("Starting operation3\n", .{});
    try operation3();
}

// Or use descriptive error messages
test "complex scenario with better errors" {
    operation1() catch |err| {
        std.debug.print("operation1 failed: {}\n", .{err});
        return err;
    };

    operation2() catch |err| {
        std.debug.print("operation2 failed: {}\n", .{err});
        return err;
    };
}
```

**Pattern**: Add diagnostic output to help identify failure points.

---

### Pitfall 16: Mixing Test and Production Imports

**❌ Problem**:
```zig
// production_module.zig
const testing_utils = @import("testing/utils.zig");  // Test code in production!

pub fn productionFunction() void {
    if (testing_utils.isTestMode()) {
        // ...
    }
}
```

**✅ Solution**:
```zig
// production_module.zig
const builtin = @import("builtin");

pub fn productionFunction() void {
    if (builtin.is_test) {
        // Test-specific behavior, compiled out in production
    } else {
        // Production behavior
    }
}

// Or separate test imports entirely
test "production function behavior" {
    const testing_utils = @import("testing/utils.zig");
    // Use testing_utils only in test blocks
}
```

**Pattern**: Guard test imports with `if (builtin.is_test)` or only import in test blocks.

---

## Production Patterns

### TigerBeetle Testing Infrastructure

TigerBeetle demonstrates sophisticated, production-grade testing patterns for distributed systems.

#### Deterministic Time Simulation

```zig
pub const TimeSim = struct {
    resolution: u64,
    offset_type: OffsetType,
    offset_coefficient_A: i64,
    offset_coefficient_B: i64,
    ticks: u64 = 0,
    epoch: i64 = 0,

    pub fn time(self: *TimeSim) Time {
        return .{
            .context = self,
            .vtable = &.{
                .monotonic = monotonic,
                .realtime = realtime,
                .tick = tick,
            },
        };
    }

    fn monotonic(context: *anyopaque) u64 {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        return self.ticks * self.resolution;
    }

    fn tick(context: *anyopaque) void {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        self.ticks += 1;
    }
};
```

**Key Patterns**:
- Controlled time advancement via `tick()`
- Multiple offset types (linear drift, periodic, step jumps)
- Simulates clock skew and NTP adjustments

[tigerbeetle/src/testing/time.zig#L12-L98](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98)

#### Network Simulation and Fault Injection

```zig
pub const PacketSimulatorOptions = struct {
    one_way_delay_mean: Duration,
    one_way_delay_min: Duration,
    packet_loss_probability: Ratio = Ratio.zero(),
    packet_replay_probability: Ratio = Ratio.zero(),
    partition_mode: PartitionMode = .none,
    partition_probability: Ratio = Ratio.zero(),
    path_maximum_capacity: u8,
    path_clog_duration_mean: Duration,
    path_clog_probability: Ratio,
};
```

Simulates:
- Variable network delays
- Packet loss and replay attacks
- Network partitions (split-brain scenarios)
- Path congestion

[tigerbeetle/src/testing/packet_simulator.zig#L11-L42](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig#L11-L42)

#### Fuzzing Utilities

```zig
/// Exponential distribution for realistic value generation
pub fn random_int_exponential(prng: *PRNG, comptime T: type, avg: T) T {
    const random = std.Random.init(prng, PRNG.fill);
    const exp = random.floatExp(f64) * @as(f64, @floatFromInt(avg));
    return std.math.lossyCast(T, exp);
}

/// Swarm testing: randomly disable some enum variants
pub fn random_enum_weights(prng: *PRNG, comptime Enum: type) PRNG.EnumWeightsType(Enum) {
    // Randomly select subset of enum values to enable
    // Assign random weights to each
}
```

These utilities create realistic, biased randomness for stress testing.

[tigerbeetle/src/testing/fuzz.zig#L14-L55](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig#L14-L55)

#### Snapshot Testing

```zig
const Snap = @import("snaptest.zig").Snap;
const snap = Snap.snap_fn("src");

test "complex output" {
    const result = complexComputation();
    try snap(@src(),
        \\Expected output line 1
        \\Expected output line 2
    ).diff_fmt("{}", .{result});
}
```

Running with `SNAP_UPDATE=1` auto-updates source code on mismatch. Drastically reduces refactoring friction.

[tigerbeetle/src/stdx/testing/snaptest.zig#L1-L100](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L1-L100)

#### Fixture Pattern

Centralized initialization helpers with sensible defaults:

```zig
pub fn init_storage(allocator: std.mem.Allocator, options: Storage.Options) !Storage {
    return try Storage.init(allocator, options);
}

pub fn storage_format(
    allocator: std.mem.Allocator,
    storage: *Storage,
    options: struct {
        cluster: u128 = cluster,
        replica: u8 = replica,
        replica_count: u8 = replica_count,
    },
) !void {
    // Complex initialization logic centralized here
}
```

Benefits:
- Reduces test boilerplate
- Ensures consistent setup
- Single source of truth for defaults

[tigerbeetle/src/testing/fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig)

### Ghostty Testing Patterns

Ghostty focuses on cross-platform GUI and font handling.

#### Platform-Specific Tests

```zig
test "fc-list" {
    const testing = std.testing;

    var cfg = fontconfig.initLoadConfigAndFonts();
    defer cfg.destroy();

    var pat = fontconfig.Pattern.create();
    defer pat.destroy();

    var fs = cfg.fontList(pat, os);
    defer fs.destroy();

    // Environmental check: expect at least one font
    try testing.expect(fs.fonts().len > 0);
}
```

Pattern: Environmental assertions that adapt to host system.

[ghostty/pkg/fontconfig/test.zig#L4-L22](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig#L4-L22)

#### Cleanup Patterns with errdefer

```zig
test "fc-match" {
    var cfg = fontconfig.initLoadConfigAndFonts();
    defer cfg.destroy();

    var pat = fontconfig.Pattern.create();
    errdefer pat.destroy();  // Cleanup on error

    try testing.expect(cfg.substituteWithPat(pat, .pattern));
    pat.defaultSubstitute();

    const result = cfg.fontSort(pat, false, null);
    errdefer result.fs.destroy();  // Cleanup on error

    // Success path cleanup
    result.fs.destroy();
    pat.destroy();
}
```

Pattern: `defer` for success cleanup, `errdefer` for error paths.

[ghostty/pkg/fontconfig/test.zig#L24-L50](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig#L24-L50)

### Bun Testing Patterns

Bun (JavaScript runtime) has limited Zig test exposure, but demonstrates integration testing.

**Note**: Bun's test infrastructure is primarily in JavaScript/TypeScript, with Zig tests for low-level components.

### ZLS Testing Patterns

ZLS (Zig Language Server) provides custom testing utilities.

#### Custom Equality Comparison

```zig
pub fn expectEqual(expected: anytype, actual: anytype) error{TestExpectedEqual}!void {
    const expected_json = std.json.Stringify.valueAlloc(allocator, expected, .{
        .whitespace = .indent_2,
        .emit_null_optional_fields = false,
    }) catch @panic("OOM");
    defer allocator.free(expected_json);

    const actual_json = std.json.Stringify.valueAlloc(allocator, actual, .{
        .whitespace = .indent_2,
        .emit_null_optional_fields = false,
    }) catch @panic("OOM");
    defer allocator.free(actual_json);

    if (std.mem.eql(u8, expected_json, actual_json)) return;
    renderLineDiff(allocator, expected_json, actual_json);
    return error.TestExpectedEqual;
}
```

Benefits:
- Semantic comparison via JSON serialization
- Human-readable diffs for complex structures
- Better diagnostics than default `expectEqual`

[zls/src/testing.zig#L9-L26](https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26)

#### FailingAllocator with Probabilistic Failures

```zig
pub const FailingAllocator = struct {
    likelihood: u32,

    /// Chance of failure is 1/likelihood
    pub fn init(internal_allocator: std.mem.Allocator, likelihood: u32) FailingAllocator {
        return .{
            .internal_allocator = internal_allocator,
            .random = .init(std.crypto.random.int(u64)),
            .likelihood = likelihood,
        };
    }

    fn shouldFail(self: *FailingAllocator) bool {
        if (self.likelihood == std.math.maxInt(u32)) return false;
        return 0 == self.random.random().intRangeAtMostBiased(u32, 0, self.likelihood);
    }
};
```

More flexible than Zig's built-in `FailingAllocator` (which fails at a specific index).

[zls/src/testing.zig#L67-L141](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)

### Zig Standard Library Patterns

The standard library demonstrates idiomatic testing patterns.

#### Colocated Tests

```zig
// std/array_list.zig
pub const ArrayList = struct {
    // Implementation...
};

test "init" {
    const list = ArrayList(u32).init(testing.allocator);
    defer list.deinit();
    try testing.expectEqual(0, list.items.len);
}

test "basic" {
    var list = ArrayList(i32).init(testing.allocator);
    defer list.deinit();

    // Test basic operations...
}
```

[zig-0.15.2/lib/std/array_list.zig#L1428-L1606](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig#L1428-L1606)

#### Generic Testing Across Types

```zig
test "HashMap: basic usage" {
    inline for ([_]type{ u32, i32, u64 }) |K| {
        inline for ([_]type{ u32, []const u8 }) |V| {
            var map = std.AutoHashMap(K, V).init(testing.allocator);
            defer map.deinit();

            // Test operations with K, V
        }
    }
}
```

Pattern: `inline for` over types generates separate tests for each combination.

[zig-0.15.2/lib/std/hash_map.zig#L1543](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/hash_map.zig#L1543)

### Citations: Production Patterns

- [TigerBeetle testing/ infrastructure](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing)
- [TigerBeetle time.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig)
- [TigerBeetle packet_simulator.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig)
- [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig)
- [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig)
- [Ghostty fontconfig test.zig](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig)
- [ZLS testing.zig](https://github.com/zigtools/zls/blob/master/src/testing.zig)
- [zig-0.15.2/lib/std/array_list.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig)
- [zig-0.15.2/lib/std/hash_map.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/hash_map.zig)

---

## Version Differences

### Zig 0.14.x vs 0.15+

#### Build System Changes

**0.14.x**: `std.build.Builder` API
```zig
// build.zig (0.14.x)
pub fn build(b: *std.build.Builder) void {
    const tests = b.addTest("src/main.zig");
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
```

**0.15+**: `std.Build` API with path resolution
```zig
// build.zig (0.15+)
pub fn build(b: *std.Build) void {
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),  // Changed from string
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
```

Key changes:
- `Builder` → `Build`
- String paths → `b.path()` wrapper
- Test execution via `addRunArtifact()`

#### std.testing API Evolution

**0.14.x to 0.15**: Minimal changes to `std.testing` API. Core assertions remain stable:
- `expect()`
- `expectEqual()`
- `expectError()`
- `expectEqualSlices()`

**Additions in 0.15**:
- Improved `FailingAllocator` with more configuration options
- Better diagnostics in failure messages

#### std.time API Changes

**0.14.x**: `std.time.Timer` similar but with minor method differences

**0.15+**: Refined `Timer` API with better documentation
- `start()` remains the same
- `read()`, `reset()`, `lap()` stabilized

**Instant API**: Introduced in 0.15 for lower-level timing:
```zig
const instant1 = try std.time.Instant.now();
// ... operation ...
const instant2 = try std.time.Instant.now();
const elapsed = instant2.since(instant1);
```

[zig-0.15.2/lib/std/time.zig#L116-L214](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/time.zig#L116-L214)

### Migration Guidance

**Build System Migration (0.14 → 0.15)**:

1. Replace `std.build.Builder` with `std.Build`
2. Wrap paths: `"src/main.zig"` → `b.path("src/main.zig")`
3. Update test execution: add `addRunArtifact(tests)` step
4. Review `target` and `optimize` options (now required in most places)

**Testing Code**: Minimal changes required. Most tests written for 0.14 work in 0.15 without modification.

**Benchmarking**: `std.time.Timer` API remains compatible. Code using `Timer` should work across versions.

### Version Compatibility Markers

When documenting or writing examples:

- ✅ **0.15+**: Indicates feature available in 0.15 and later
- 🕐 **0.14.x**: Indicates feature specific to 0.14.x
- ⚠️ **Changed in 0.15**: Indicates API change between versions

Example:
```zig
// ✅ 0.15+ - Use b.path() for paths
const tests = b.addTest(.{
    .root_source_file = b.path("src/main.zig"),
});

// 🕐 0.14.x - Direct string paths
const tests = b.addTest("src/main.zig");
```

### Citations: Version Differences

- [Zig 0.15 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
- [Zig Build System Documentation](https://ziglang.org/learn/build-system/)
- [zig-0.15.2/lib/std/Build.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/Build.zig)
- [zig-0.14.1/lib/std/build.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/build.zig)

---

## References

### Official Documentation
1. [Zig Language Reference: Testing](https://ziglang.org/documentation/master/#Testing) - Official test block documentation
2. [Zig Build System Guide](https://ziglang.org/learn/build-system/) - Test integration with build system
3. [Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/) - std.testing module reference
4. [Zig 0.15 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html) - Breaking changes and new features
5. [Zig Community: Testing Best Practices](https://github.com/ziglang/zig/wiki/Testing-Best-Practices) - Community guidelines

### Zig Standard Library Source
6. [zig-0.15.2/lib/std/testing.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig) - Complete testing module implementation
7. [zig-0.15.2/lib/std/time.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/time.zig) - Timer and time utilities
8. [zig-0.15.2/lib/std/array_list.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig) - Example of colocated tests
9. [zig-0.15.2/lib/std/hash_map.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/hash_map.zig) - Generic testing patterns
10. [zig-0.15.2/lib/std/testing/FailingAllocator.zig](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing/FailingAllocator.zig) - Allocator failure testing
11. [zig-0.15.2/lib/std/mem.zig - doNotOptimizeAway](file:///home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/mem.zig) - Optimization barrier for benchmarks

### TigerBeetle Production Patterns
12. [TigerBeetle: src/testing/ directory](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing) - Comprehensive test infrastructure
13. [TigerBeetle: testing/fuzz.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig) - Fuzzing utilities and distributions
14. [TigerBeetle: testing/time.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig) - Deterministic time simulation
15. [TigerBeetle: testing/fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig) - Fixture pattern implementation
16. [TigerBeetle: testing/packet_simulator.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig) - Network simulation and fault injection
17. [TigerBeetle: stdx/testing/snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig) - Snapshot testing implementation
18. [TigerBeetle: state_machine_tests.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine_tests.zig) - State machine testing example
19. [TigerBeetle: testing/storage.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/storage.zig) - Storage simulator

### Ghostty Testing Patterns
20. [Ghostty: pkg/fontconfig/test.zig](https://github.com/mitchellh/ghostty/blob/main/pkg/fontconfig/test.zig) - Cross-platform font testing
21. [Ghostty: pkg/freetype/test.zig](https://github.com/mitchellh/ghostty/blob/main/pkg/freetype/test.zig) - FreeType integration tests

### ZLS Testing Patterns
22. [ZLS: src/testing.zig](https://github.com/zigtools/zls/blob/master/src/testing.zig) - Custom testing utilities
23. [ZLS: Custom FailingAllocator](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141) - Probabilistic allocation failures

### Profiling Tools Documentation
24. [Valgrind Callgrind Manual](https://valgrind.org/docs/manual/cl-manual.html) - Function-level profiling
25. [Linux perf Tutorial](https://perf.wiki.kernel.org/index.php/Tutorial) - System-wide performance analysis
26. [Brendan Gregg's Flame Graphs](https://www.brendangregg.com/flamegraphs.html) - Visualization techniques
27. [FlameGraph GitHub Repository](https://github.com/brendangregg/FlameGraph) - Flame graph generation tools
28. [Valgrind Massif Manual](https://valgrind.org/docs/manual/ms-manual.html) - Heap profiling

### Example Code References
29. [Example 01: Testing Fundamentals](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/01_testing_fundamentals) - Basic test patterns
30. [Example 02: Test Organization](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/02_test_organization) - Project structure
31. [Example 03: Parameterized Tests](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests) - Table-driven testing
32. [Example 04: Allocator Testing](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing) - Memory testing patterns
33. [Example 05: Benchmarking](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking) - Complete benchmark suite
34. [Example 06: Profiling](file:///home/jack/workspace/zig_guide/sections/12_testing_benchmarking/examples/06_profiling) - Profiling workflow

---

## Research Metadata

**Research Date**: November 4, 2025
**Zig Version Analyzed**: 0.15.2
**Total Lines**: 1,267
**Total Citations**: 34
**Reference Projects Analyzed**:
- TigerBeetle (distributed database)
- Ghostty (terminal emulator)
- Bun (JavaScript runtime)
- ZLS (Zig Language Server)
- Zig Standard Library (0.15.2)

**Key Findings**:
1. Zig's testing framework is minimalist but powerful, focusing on language integration over external tooling
2. Production codebases emphasize deterministic testing, especially for distributed systems
3. Manual benchmarking provides full control but requires discipline to avoid common pitfalls
4. Profiling relies on standard Linux/Unix tools (perf, Valgrind) with proper build configuration
5. Memory safety testing via `testing.allocator` is a unique strength of Zig's ecosystem

**Research Limitations**:
- Bun's Zig test coverage is limited (primarily JavaScript/TypeScript tests)
- Profiling examples focus on Linux tooling (less coverage for macOS/Windows)
- Async testing patterns are less developed in 0.15+ due to async evolution

**Future Research Areas**:
- Advanced async testing patterns as Zig's async evolves
- Integration with CI/CD systems
- Cross-platform profiling tool coverage
- Benchmark result visualization tools
