# Testing, Benchmarking & Profiling

## Overview

Testing, benchmarking, and profiling form the foundation of reliable, performant software development. Zig's approach to these practices reflects its core philosophy: simplicity, explicitness, and zero hidden costs. Unlike many languages that require external testing frameworks, Zig provides testing capabilities directly in the language and compiler.

The `zig test` command discovers and executes test blocks automatically, providing immediate feedback without configuration. The `std.testing` module supplies essential assertions and utilities, including automatic memory leak detection through `testing.allocator`. This integrated approach eliminates dependency management overhead while ensuring tests remain maintainable and deterministic.

Testing in Zig emphasizes reproducibility. Every test runs with a deterministic random seed, enabling consistent reproduction of failures. The `builtin.is_test` flag allows conditional compilation of test-only code without bloating production binaries. Memory safety testing is first-class—`testing.allocator` fails tests that leak memory, enforcing cleanup discipline from day one.

Benchmarking requires manual instrumentation using `std.time.Timer`, providing full control over measurement methodology. This design philosophy prioritizes accuracy over convenience. Developers explicitly manage warm-up iterations, statistical sampling, and optimization barriers using `std.mem.doNotOptimizeAway` to prevent the compiler from invalidating benchmarks through dead code elimination.

Profiling integrates with industry-standard tools: Linux perf for sampling, Valgrind Callgrind for instruction-level analysis, and Massif for heap profiling. Zig's build system configures debug symbols and optimization flags, enabling production-realistic profiling without sacrificing observability. The `-Dstrip=false` flag preserves symbols while `-Doptimize=ReleaseFast` ensures representative performance.

Production codebases demonstrate sophisticated testing patterns. TigerBeetle's deterministic time simulation and network fault injection enable testing distributed consensus algorithms without flakiness. Ghostty's platform-specific test organization handles cross-platform GUI code cleanly. ZLS's custom assertion framework provides semantic comparison through JSON serialization, generating human-readable diffs for complex data structures.

This chapter equips readers with practical knowledge for testing, measuring, and optimizing Zig code. Examples progress from fundamental test blocks to advanced patterns including table-driven tests, allocator testing, comprehensive benchmarking suites, and profiling workflows. Production patterns from real-world projects illustrate scaling these techniques to complex systems.

Understanding these tools enables developers to write correct, performant code with confidence. Zig's integrated testing catches bugs early, benchmarking quantifies optimization impact, and profiling identifies bottlenecks precisely. Together, these capabilities support building robust systems from prototype through production deployment.

## Core Concepts

### zig test and Test Discovery

The `zig test` command compiles a source file and its dependencies, discovers all `test` blocks, and executes them sequentially. Each test runs in isolation—failures in one test do not affect others. This design prioritizes determinism over parallel execution for reproducible results.[^1]

**Basic Usage:**

```bash
# Test a single file
zig test src/main.zig

# Test with specific optimization level
zig test -O ReleaseFast src/main.zig

# Filter tests by name
zig test src/main.zig --test-filter "allocator"

# Verbose output with all results
zig test src/main.zig --summary all
```

**Test Discovery Mechanism:**

The compiler scans for `test "name" { ... }` or anonymous `test { ... }` blocks at file scope. Tests in imported modules are automatically included unless the import is guarded by `if (!builtin.is_test)`. This transitive discovery ensures comprehensive test coverage without explicit registration.

**Test Block Syntax:**

```zig
const std = @import("std");
const testing = std.testing;

// Named test - appears in output
test "arithmetic operations" {
    const result = 2 + 2;
    try testing.expectEqual(4, result);
}

// Anonymous test - identified by file and line
test {
    try testing.expect(true);
}
```

Named tests provide descriptive failure messages, while anonymous tests suit quick validation. Both forms support error returns via `try`, which propagates assertion failures upward.

**Execution Model:**

Tests execute sequentially in source order. This guarantees deterministic behavior but precludes parallel execution. The test runner:

1. Discovers all tests in the module graph
2. Initializes `std.testing.allocator` and `std.testing.random_seed`
3. Executes each test in a separate stack frame
4. Checks for memory leaks after each test
5. Aggregates results and prints a summary

**Exit Codes:**

- `0`: All tests passed
- Non-zero: At least one test failed (typically `1`)

**The builtin.is_test Flag:**

The `builtin.is_test` constant enables conditional compilation for test-only code:

```zig
const builtin = @import("builtin");

pub const Database = struct {
    data: []u8,

    pub fn query(self: *Database, sql: []const u8) !Result {
        // Production implementation
    }

    // Test-only helper - not compiled in release builds
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

This pattern appears extensively in production codebases. TigerBeetle's snapshot testing module uses comptime assertions to enforce test-only usage:[^2]

```zig
pub const Snap = struct {
    comptime {
        assert(builtin.is_test);
    }
    // Snapshot testing implementation
};
```

**Test Filtering:**

Filters run only tests matching a substring pattern:

```bash
# Run tests containing "allocator"
zig test src/main.zig --test-filter "allocator"

# Multiple filters are OR'd
zig test src/main.zig --test-filter "allocator" --test-filter "hashmap"
```

Filtering enables rapid iteration on specific functionality during development without running the entire suite.

**Error Reporting:**

When tests fail, Zig provides detailed diagnostics:

```
Test [3/10] test.basic arithmetic... FAIL (TestExpectedEqual)
expected 5, found 4
/home/user/src/main.zig:10:5: 0x103c1a0 in test.basic arithmetic (test)
    try testing.expectEqual(5, result);
    ^
```

Output includes:
- Test name and index (3/10)
- Error type (`TestExpectedEqual`)
- Expected vs actual values
- File path, line number, and column
- Stack trace showing failure location

### std.testing Module and Assertions

The `std.testing` module provides all core testing utilities without external dependencies. It includes assertions, allocators for memory testing, and utilities for reproducible randomness.[^3]

**Core Assertions:**

**expect(ok: bool) !void**

The fundamental assertion—fails if the condition is false.

```zig
try testing.expect(value > 0);
try testing.expect(list.items.len == 5);
```

Returns `error.TestUnexpectedResult` on failure. Use for boolean conditions where simple pass/fail suffices.

**expectEqual(expected: anytype, actual: anytype) !void**

Compares two values for equality using peer type resolution to coerce both to a common type. Provides detailed diagnostics showing expected and actual values.

```zig
try testing.expectEqual(42, computeAnswer());
try testing.expectEqual(@as(u32, 100), counter);
```

Works with structs, unions, arrays, and most Zig types via recursive comparison using `std.meta.eql` internally. This is the most commonly used assertion in production code.

**expectError(expected_error: anyerror, actual_error_union: anytype) !void**

Asserts that an error union contains a specific error.

```zig
const result = parseNumber("invalid");
try testing.expectError(error.InvalidFormat, result);
```

Fails if:
- The error union contains a value (not an error)
- The error differs from expected

Critical for testing error paths and ensuring functions fail correctly.

**expectEqualSlices(comptime T: type, expected: []const T, actual: []const T) !void**

Compares two slices element-by-element, reporting the index of the first mismatch.

```zig
const expected = [_]u8{ 1, 2, 3 };
const actual = list.items;
try testing.expectEqualSlices(u8, &expected, actual);
```

**expectEqualStrings(expected: []const u8, actual: []const u8) !void**

String-specific comparison semantically equivalent to `expectEqualSlices(u8, ...)` but clearer for string contexts.

```zig
try testing.expectEqualStrings("hello", result);
```

**Floating Point Assertions:**

**expectApproxEqAbs(expected: anytype, actual: anytype, tolerance: anytype) !void**

Absolute tolerance comparison for floating-point values. Checks `|expected - actual| <= tolerance`.

```zig
const result = computeCircleArea(5.0);
try testing.expectApproxEqAbs(78.54, result, 0.01);
```

**expectApproxEqRel(expected: anytype, actual: anytype, tolerance: anytype) !void**

Relative tolerance comparison—better for values with large magnitude. Checks `|expected - actual| / max(|expected|, |actual|) <= tolerance`.

```zig
try testing.expectApproxEqRel(1000000.0, result, 0.0001); // 0.01% tolerance
```

Relative comparison avoids absolute tolerance issues on large or small numbers.

**Memory Testing:**

**testing.allocator**

A `GeneralPurposeAllocator` configured specifically for test use. Automatically detects:
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

If `deinit()` is omitted, the test fails with a memory leak report detailing the allocation site and amount leaked.

Configuration includes stack traces for allocation sites:

```zig
pub var allocator_instance: std.heap.GeneralPurposeAllocator(.{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0,
    .resize_stack_traces = true,
    .canary = @truncate(0x2731e675c3a701ba),
}) = .init;
```

The canary value ensures accidentally using a default-constructed GPA instead of `testing.allocator` triggers a panic.

**FailingAllocator**

A wrapper allocator that probabilistically fails allocations to test error paths. Essential for verifying allocation failure handling.[^4]

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

ZLS provides an enhanced `FailingAllocator` with probabilistic failures:[^5]

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

This provides more flexible failure patterns for comprehensive error path testing.

**Additional Utilities:**

**testing.random_seed**

A deterministic seed initialized at test startup, enabling reproducible randomness:

```zig
var prng = std.Random.DefaultPrng.init(testing.random_seed);
const random = prng.random();
const value = random.int(u32);
```

The seed is printed at test start. Failed tests can be reproduced using the same seed, critical for debugging intermittent failures.

**expectFmt(expected: []const u8, comptime template: []const u8, args: anytype) !void**

Asserts formatted output matches expected string:

```zig
try testing.expectFmt("value: 42", "value: {d}", .{42});
```

Useful for testing formatting logic without manual string construction.

### Test Organization Patterns

Effective test organization balances discoverability, maintainability, and separation of concerns. Zig's testing model enables multiple organizational approaches, each with specific trade-offs.

**Colocated vs Separate Test Files:**

**Colocated Tests (Recommended):** Tests live in the same file as implementation.

```zig
// src/queue.zig
pub const Queue = struct {
    items: []i32,

    pub fn push(self: *Queue, value: i32) !void {
        // Implementation
    }
};

test "Queue: basic operations" {
    var queue = Queue.init(testing.allocator);
    defer queue.deinit();

    try queue.push(42);
    try testing.expectEqual(1, queue.len());
}

test "Queue: edge cases" {
    // More tests
}
```

Advantages:
- Tests stay synchronized with implementation
- Easy to find relevant tests
- Encourages testing as part of development
- `zig test src/queue.zig` runs all relevant tests
- Reduces cognitive overhead from file switching

**Separate Test Files:** Less common in Zig but used for integration tests.

```
src/
  queue.zig
  tests/
    queue_integration_test.zig
```

Separate files suit integration tests requiring complex setup or multiple module interactions.

**Test Directory Conventions:**

**Standard Library Pattern:** Colocated tests with test-only modules in `testing/`:

```
std/
  array_list.zig           # Implementation + tests
  hash_map.zig             # Implementation + tests
  testing.zig              # Main testing module
  testing/
    FailingAllocator.zig   # Reusable test utilities
```

**TigerBeetle Pattern:** Extensive `testing/` infrastructure for reusable components:[^6]

```
src/
  vsr.zig                  # Implementation
  state_machine.zig        # Implementation
  testing/
    fuzz.zig               # Fuzzing utilities
    time.zig               # Deterministic time simulation
    fixtures.zig           # Test fixtures and helpers
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

**Shared Test Utilities:**

Extract common test setup into dedicated modules:

```zig
// testing/fixtures.zig
pub fn initStorage(allocator: std.mem.Allocator, options: StorageOptions) !Storage {
    return try Storage.init(allocator, options);
}

pub fn initGrid(allocator: std.mem.Allocator, superblock: *SuperBlock) !Grid {
    return try Grid.init(allocator, .{ .superblock = superblock });
}
```

TigerBeetle's fixture pattern centralizes initialization with sensible defaults:[^7]

```zig
pub const cluster: u128 = 0;
pub const replica: u8 = 0;
pub const replica_count: u8 = 6;

pub fn initTime(options: struct {
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

Benefits:
- Provides defaults for most options
- Requires passing `.{}` at call sites (makes customization explicit)
- Centralizes complex initialization logic
- Ensures consistent test setup across the codebase

**Test Fixtures and Setup/Teardown:**

Zig lacks built-in setup/teardown hooks. Instead, use explicit initialization with `defer`:

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

**Arena Allocator Pattern for Complex Tests:**

```zig
test "complex test with multiple allocations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    // All allocations from arena freed at once
    const data1 = try arena.allocator().alloc(u8, 100);
    const data2 = try arena.allocator().alloc(u32, 50);
    // No individual free() needed
}
```

Arena allocators simplify cleanup when tests allocate multiple resources. A single `defer arena.deinit()` frees everything.

**Build System Integration:**

Integrate tests with `build.zig`:[^8]

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

Run tests with `zig build test`. This integrates seamlessly with CI/CD pipelines.

**Test Naming Conventions:**

Use descriptive names for clarity:

```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}

test "HashMap: remove decrements count" {
    var map = std.AutoHashMap(u32, u32).init(testing.allocator);
    defer map.deinit();

    try map.put(1, 100);
    _ = map.remove(1);
    try testing.expectEqual(0, map.count());
}
```

Include the type or module name followed by the specific behavior being tested. This convention aids filtering and provides self-documenting test names.

### Advanced Testing Techniques

Advanced testing techniques enable comprehensive validation of complex functionality while maintaining readability and maintainability.

**Parameterized and Table-Driven Tests:**

Parameterized tests use comptime iteration to generate test cases from data tables:

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

The `inline for` loop unrolls at compile time, generating separate assertions for each case. This provides granular failure reporting—failures identify exactly which case failed.

**Advanced: Comptime Type Generation:**

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

This pattern tests identical logic across multiple types without code duplication, ensuring generic implementations work correctly for all supported types.

**Comptime Test Generation:**

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

Real-world applications include testing parsers against multiple formats, validating serialization for different types, or verifying compile-time computations.

**Testing with Allocators:**

**Memory Leak Detection:**

```zig
test "no memory leaks" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Required - test fails without this

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

Omitting `list.deinit()` causes `testing.allocator` to report:

```
Test [1/1] test.no memory leaks... FAIL (error.MemoryLeakDetected)
Memory leak detected: 40 bytes not freed
```

**FailingAllocator for Error Paths:**

```zig
test "handle allocation failure gracefully" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    const result = std.ArrayList(u32).initCapacity(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

This ensures error handling code is exercised. Comprehensive error path testing uses multiple failure indices:

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

This exhaustively tests failure at each allocation point, ensuring robust error handling.

**Testing Error Paths:**

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

Testing both success and error paths ensures functions behave correctly under all conditions.

**Testing Concurrent Code:**

Zig 0.15+ has simplified async handling. Concurrent tests require explicit synchronization:

```zig
test "concurrent atomic counter" {
    var counter = std.atomic.Value(u32).init(0);

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *std.atomic.Value(u32)) void {
                for (0..1000) |_| {
                    _ = c.fetchAdd(1, .monotonic);
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| {
        t.join();
    }

    try testing.expectEqual(4000, counter.load(.monotonic));
}
```

Use atomics or mutexes for shared state to avoid race conditions.

**Deterministic Concurrency Testing:**

TigerBeetle demonstrates controlled time for deterministic distributed testing:[^9]

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

By controlling time explicitly, distributed consensus algorithms can be tested deterministically without race conditions or timeout flakiness.

### Benchmarking Best Practices

Benchmarking in Zig is manual—no built-in framework like Go's `testing.B` exists. This provides full control but requires understanding measurement pitfalls to obtain accurate results.

**std.time.Timer API:**

`std.time.Timer` provides monotonic, high-precision timing:[^10]

```zig
const std = @import("std");

pub fn main() !void {
    var timer = try std.time.Timer.start();

    // Code to measure
    expensiveOperation();

    const elapsed_ns = timer.read();
    std.debug.print("Elapsed: {d} ns\n", .{elapsed_ns});
}
```

**Key Methods:**
- `start() !Timer`: Initialize timer (may fail if no monotonic clock available)
- `read() u64`: Read elapsed nanoseconds since start/reset
- `reset()`: Reset timer to zero
- `lap() u64`: Read elapsed time and reset in one operation

Timer implementation uses platform-specific monotonic clocks:
- Linux: `CLOCK_BOOTTIME` (includes suspend time)
- macOS: `CLOCK_UPTIME_RAW`
- Windows: `QueryPerformanceCounter`

**std.mem.doNotOptimizeAway:**

Critical function preventing compiler optimizations from eliminating benchmarked code:[^11]

```zig
pub fn doNotOptimizeAway(value: anytype) void {
    asm volatile ("" :: [_]"r,m" (value));
}
```

**Why It's Needed:**

Without `doNotOptimizeAway`:
```zig
// ❌ Compiler may optimize away the entire loop
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

The inline assembly with memory/register constraint forces the compiler to treat the value as used, preventing:
1. Dead code elimination (removing unused results)
2. Constant folding (computing results at compile time)
3. Loop elimination (removing the entire loop)

**Warm-up Iterations:**

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

Warm-up stabilizes:
- CPU frequency (modern CPUs scale based on load)
- L1/L2 cache state (loads hot paths into cache)
- Branch predictor state (trains the predictor)
- TLB (translation lookaside buffer)

**Statistical Measurement:**

Never rely on single measurements. Collect samples and compute statistics:

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

Multiple samples:
- Identify outliers (context switches, interrupts)
- Measure consistency (variance)
- Increase confidence in the mean

**Build Modes for Benchmarking:**

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

Debug vs ReleaseFast can differ by 10-100x in performance.

**Build.zig Configuration:**

```zig
const benchmark = b.addExecutable(.{
    .name = "benchmark",
    .root_source_file = b.path("src/benchmark.zig"),
    .target = target,
    .optimize = .ReleaseFast,  // Force release mode
});
```

**Common Benchmarking Mistakes:**

**❌ Mistake 1: Not using doNotOptimizeAway**
```zig
// Entire loop may be optimized away
for (0..1000) |_| {
    const result = compute();
}
```

**✅ Correct:**
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

**✅ Correct:**
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

**✅ Correct:**
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
```bash
# zig build-exe benchmark.zig
# Results meaningless due to lack of optimization
```

**✅ Correct:**
```bash
# zig build-exe -O ReleaseFast benchmark.zig
# Realistic performance numbers
```

### Profiling Integration

Profiling requires external tools. Zig provides necessary build flags and symbol information for effective profiling with industry-standard tools.[^12]

**Build Configuration for Profiling:**

Effective profiling requires:
1. **Optimization**: Realistic performance (`-O ReleaseFast`)
2. **Debug symbols**: For function names and line numbers
3. **No stripping**: Preserve symbols for profilers

```bash
# Command-line profiling build
zig build-exe -O ReleaseFast -Dcpu=baseline src/main.zig

# Or via build.zig
zig build -Doptimize=ReleaseFast -Dstrip=false
```

**Build.zig Configuration:**

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

**Why baseline CPU?**: `-Dcpu=baseline` ensures the binary runs on any CPU of that architecture, avoiding CPU-specific optimizations that might not transfer across machines.

**Callgrind (Valgrind) Integration:**

Callgrind provides function-level profiling with call graphs.[^13]

**Running Callgrind:**

```bash
# Build with symbols
zig build -Doptimize=ReleaseFast

# Profile
valgrind --tool=callgrind ./zig-out/bin/myapp

# Generates callgrind.out.<pid>
```

**Analyzing Results:**

```bash
# View in KCachegrind (GUI)
kcachegrind callgrind.out.12345

# Or command-line summary
callgrind_annotate callgrind.out.12345
```

**Callgrind Output Example:**

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

**Advantages:**
- Exact instruction counts (deterministic)
- Function-level and line-level detail
- Call graph visualization

**Disadvantages:**
- Very slow (10-100x slowdown)
- Not real-time profiling

**Linux perf:**

`perf` is a powerful sampling profiler with hardware counter support.[^14]

**Basic Profiling:**

```bash
# Record profile
perf record -F 999 -g ./zig-out/bin/myapp

# View results
perf report
```

**Flame Graph Generation:**

```bash
# Record with call graphs
perf record -F 999 -g ./zig-out/bin/myapp

# Convert to flame graph format
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**perf Options:**
- `-F 999`: Sample at 999Hz (odd number reduces aliasing)
- `-g`: Record call graphs
- `--call-graph dwarf`: Use DWARF for better stack traces (larger data)

**Advantages:**
- Low overhead (typically <5%)
- Real-time profiling
- Hardware counters (cache misses, branch mispredictions)

**Disadvantages:**
- Statistical (not deterministic)
- Requires root or `perf_event_paranoid` adjustment

**Massif (Heap Profiling):**

Massif tracks heap allocations over time.[^15]

**Running Massif:**

```bash
# Profile heap usage
valgrind --tool=massif ./zig-out/bin/myapp

# Generates massif.out.<pid>
```

**Analyzing:**

```bash
# Text summary
ms_print massif.out.12345

# GUI (if available)
massif-visualizer massif.out.12345
```

**Massif Output Example:**

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

**Advantages:**
- Shows allocation patterns over time
- Identifies memory leaks and bloat
- Snapshots show detailed heap state

**Disadvantages:**
- Significant slowdown
- Requires Valgrind-compatible system

**Flame Graph Generation:**

Flame graphs visualize profiling data as interactive SVGs.[^16]

**Setup:**

```bash
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph
```

**From perf:**

```bash
perf record -F 999 -g ./zig-out/bin/myapp
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**Reading Flame Graphs:**
- X-axis: Alphabetical sort (not time)
- Y-axis: Stack depth (bottom = entry, top = leaf)
- Width: Time spent in function (or descendants)
- Color: Typically random (or categorized by module)

Wide plateaus at the bottom indicate hot paths consuming most time.

**Profiling Overhead Considerations:**

**Callgrind:**
- Overhead: 10-100x slowdown
- Impact: Totally changes performance characteristics
- Use for: Instruction counts, relative comparisons

**perf:**
- Overhead: <5% typically
- Impact: Minimal on real-world performance
- Use for: Production-like profiling

**Massif:**
- Overhead: 5-20x slowdown
- Impact: Slows allocation-heavy code significantly
- Use for: Memory analysis, not performance

**Build Mode Impact:**
- Debug: 10-100x slower than ReleaseFast
- ReleaseSafe: ~2x slower due to safety checks
- ReleaseFast: Baseline for profiling
- ReleaseSmall: Similar to ReleaseFast but optimized for size

## Code Examples

This section demonstrates practical testing, benchmarking, and profiling patterns through six complete examples. Each builds on Core Concepts, showing real-world usage.

### Example 1: Testing Fundamentals

This example demonstrates fundamental test blocks, assertions, and error handling. It shows colocated tests alongside implementation, basic and advanced assertions, and testing both success and error paths.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/01_testing_fundamentals/`

**Key Code Snippet (math.zig):**

```zig
const std = @import("std");
const testing = std.testing;

/// Divide two integers, returning an error on division by zero.
pub fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

/// Calculate factorial (iterative version).
/// Returns error on negative input or overflow.
pub fn factorial(n: i32) !i64 {
    if (n < 0) return error.NegativeInput;
    if (n == 0 or n == 1) return 1;

    var result: i64 = 1;
    var i: i32 = 2;
    while (i <= n) : (i += 1) {
        const old_result = result;
        result = @as(i64, @intCast(i)) * result;
        if (@divTrunc(result, @as(i64, @intCast(i))) != old_result) {
            return error.Overflow;
        }
    }
    return result;
}

test "divide: successful division" {
    try testing.expectEqual(@as(i32, 5), try divide(10, 2));
    try testing.expectEqual(@as(i32, 1), try divide(7, 5));
    try testing.expectEqual(@as(i32, -2), try divide(-10, 5));
}

test "divide: division by zero" {
    try testing.expectError(error.DivisionByZero, divide(10, 0));
    try testing.expectError(error.DivisionByZero, divide(0, 0));
    try testing.expectError(error.DivisionByZero, divide(-10, 0));
}

test "factorial: basic cases" {
    try testing.expectEqual(@as(i64, 1), try factorial(0));
    try testing.expectEqual(@as(i64, 1), try factorial(1));
    try testing.expectEqual(@as(i64, 6), try factorial(3));
    try testing.expectEqual(@as(i64, 120), try factorial(5));
}

test "factorial: error cases" {
    try testing.expectError(error.NegativeInput, factorial(-1));
    try testing.expectError(error.NegativeInput, factorial(-10));
}
```

**Patterns Demonstrated:**
- Colocated tests alongside implementation
- Basic assertions (`expectEqual`, `expectError`)
- Testing both success and error paths
- Error handling with `!` return types
- Named tests with descriptive names
- Type coercion with `@as` for clarity

The complete example includes string utilities testing, prime number checking, and Fibonacci sequence validation. Run with `zig test src/main.zig`.

### Example 2: Test Organization

This example demonstrates project organization for tests, including test utilities, fixtures, and the `builtin.is_test` flag for conditional compilation.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/02_test_organization/`

**Project Structure:**

```
src/
  main.zig              # Main entry point
  data_structures.zig   # Implementation with tests
  testing/
    test_helpers.zig    # Shared test utilities
    fixtures.zig        # Test fixtures and data
```

**Key Code Snippet (test_helpers.zig):**

```zig
const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

// Only compile this module in test mode
comptime {
    if (!builtin.is_test) {
        @compileError("test_helpers module is only for tests");
    }
}

/// Helper to create a test allocator with tracking
pub fn TestAllocator() type {
    return struct {
        gpa: std.heap.GeneralPurposeAllocator(.{}),

        pub fn init() @This() {
            return .{ .gpa = .{} };
        }

        pub fn allocator(self: *@This()) std.mem.Allocator {
            return self.gpa.allocator();
        }

        pub fn deinit(self: *@This()) !void {
            const leaked = self.gpa.deinit();
            if (leaked == .leak) {
                return error.MemoryLeak;
            }
        }
    };
}
```

**Key Code Snippet (fixtures.zig):**

```zig
const std = @import("std");

/// Standard test data for numeric operations
pub const test_numbers = [_]i32{ 1, 2, 3, 4, 5, 10, 42, 100, 1000 };

/// Standard test strings
pub const test_strings = [_][]const u8{
    "",
    "a",
    "hello",
    "Hello, World!",
    "The quick brown fox jumps over the lazy dog",
};

/// Create a test arena allocator
pub fn createTestArena(backing: std.mem.Allocator) std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(backing);
}
```

**Patterns Demonstrated:**
- Separating test utilities into dedicated modules
- Using `builtin.is_test` for compile-time guards
- Centralized test fixtures and data
- Test-only helper functions
- Arena allocator pattern for test cleanup
- Organized project structure for maintainability

The complete example shows importing and using test helpers across multiple test files. Run with `zig build test`.

### Example 3: Parameterized Tests

This example demonstrates table-driven tests, comptime test generation, and testing across multiple types using inline loops.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests/`

**Key Code Snippet:**

```zig
const std = @import("std");
const testing = std.testing;

/// Test arithmetic operations with multiple test cases
test "add: parameterized cases" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .a = 0, .b = 0, .expected = 0 },
        .{ .a = 1, .b = 2, .expected = 3 },
        .{ .a = -5, .b = 5, .expected = 0 },
        .{ .a = 100, .b = -50, .expected = 50 },
        .{ .a = 2147483647, .b = 0, .expected = 2147483647 },
    };

    inline for (cases) |case| {
        const result = case.a + case.b;
        try testing.expectEqual(case.expected, result);
    }
}

/// Test string operations across multiple inputs
test "string length: table-driven" {
    const cases = [_]struct {
        input: []const u8,
        expected: usize,
    }{
        .{ .input = "", .expected = 0 },
        .{ .input = "a", .expected = 1 },
        .{ .input = "hello", .expected = 5 },
        .{ .input = "Hello, World!", .expected = 13 },
    };

    inline for (cases) |case| {
        try testing.expectEqual(case.expected, case.input.len);
    }
}

/// Test generic operations across multiple types
test "ArrayList: generic type testing" {
    const types = [_]type{ u8, u16, u32, u64, i8, i16, i32, i64 };

    inline for (types) |T| {
        var list = std.ArrayList(T).init(testing.allocator);
        defer list.deinit();

        const test_value: T = 42;
        try list.append(test_value);

        try testing.expectEqual(@as(usize, 1), list.items.len);
        try testing.expectEqual(test_value, list.items[0]);
    }
}

/// Comptime test generation for powers of two
test "powers of two: comptime generation" {
    const powers = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 };

    inline for (powers, 0..) |expected, i| {
        const result = std.math.pow(u32, 2, i);
        try testing.expectEqual(expected, result);
    }
}
```

**Patterns Demonstrated:**
- Table-driven tests with struct arrays
- `inline for` for comptime test case expansion
- Generic type testing across multiple types
- Comptime iteration with enumeration
- Granular failure reporting per case
- Zero runtime overhead from test generation

The inline for loop unrolls at compile time, generating separate assertions for each case. Failures identify exactly which case and type failed. Run with `zig test src/main.zig`.

### Example 4: Allocator Testing

This example demonstrates memory leak detection, using `FailingAllocator` to test error paths, and comprehensive allocator testing patterns.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing/`

**Key Code Snippet:**

```zig
const std = @import("std");
const testing = std.testing;

test "memory leak detection" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Required - test fails without this

    try list.append(42);
    try list.append(43);

    try testing.expectEqual(@as(usize, 2), list.items.len);
    // testing.allocator automatically checks for leaks when test completes
}

test "allocation failure handling" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    // This allocation should fail immediately
    const result = allocator.alloc(u8, 100);
    try testing.expectError(error.OutOfMemory, result);
}

test "robust error path testing" {
    // Test allocation failure at different points
    var fail_index: u32 = 0;
    while (fail_index < 5) : (fail_index += 1) {
        var failing = testing.FailingAllocator.init(testing.allocator, .{
            .fail_index = fail_index
        });
        const allocator = failing.allocator();

        const result = createDataStructure(allocator);

        if (result) |structure| {
            defer structure.deinit(allocator);
            // Verify structure is valid
            try testing.expect(structure.isValid());
        } else |err| {
            // Should only fail with OutOfMemory
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}

fn createDataStructure(allocator: std.mem.Allocator) !DataStructure {
    var ds = DataStructure{};

    // Multiple allocations - test failure at each point
    ds.buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(ds.buffer1);

    ds.buffer2 = try allocator.alloc(u32, 50);
    errdefer allocator.free(ds.buffer2);

    ds.buffer3 = try allocator.alloc(i64, 25);
    errdefer allocator.free(ds.buffer3);

    return ds;
}

const DataStructure = struct {
    buffer1: []u8 = undefined,
    buffer2: []u32 = undefined,
    buffer3: []i64 = undefined,

    pub fn isValid(self: DataStructure) bool {
        return self.buffer1.len == 100 and
               self.buffer2.len == 50 and
               self.buffer3.len == 25;
    }

    pub fn deinit(self: DataStructure, allocator: std.mem.Allocator) void {
        allocator.free(self.buffer1);
        allocator.free(self.buffer2);
        allocator.free(self.buffer3);
    }
};

test "arena allocator pattern" {
    // Arena simplifies cleanup for multiple allocations
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Multiple allocations
    const data1 = try allocator.alloc(u8, 100);
    const data2 = try allocator.alloc(u32, 50);
    const data3 = try allocator.alloc(i64, 25);

    // Use the data
    data1[0] = 42;
    data2[0] = 100;
    data3[0] = -50;

    // No individual free() needed - arena.deinit() frees everything
}
```

**Patterns Demonstrated:**
- Memory leak detection with `testing.allocator`
- Using `FailingAllocator` to test error paths
- Systematic testing of allocation failure at different points
- `errdefer` for cleanup on error paths
- Arena allocator pattern for simplified cleanup
- Testing both success and failure scenarios

The complete example shows complex data structure testing with multiple allocation points and proper cleanup. Run with `zig test src/main.zig`.

### Example 5: Benchmarking Patterns

This example demonstrates comprehensive benchmarking with warm-up iterations, statistical measurement, `doNotOptimizeAway`, and comparison utilities.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/`

**Key Code Snippet (benchmark.zig excerpt):**

```zig
const std = @import("std");

pub const BenchmarkResult = struct {
    iterations: u64,
    total_ns: u64,
    avg_ns: u64,
    min_ns: u64,
    max_ns: u64,
    variance_ns: u64,

    pub fn speedupVs(self: BenchmarkResult, other: BenchmarkResult) f64 {
        return @as(f64, @floatFromInt(other.avg_ns)) / @as(f64, @floatFromInt(self.avg_ns));
    }
};

pub fn benchmark(
    comptime Func: type,
    func: Func,
    iterations: u64,
) !BenchmarkResult {
    // Warm-up phase: stabilizes CPU frequency, cache, branch predictor
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    // Collect multiple samples for statistical analysis
    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func();
            // Critical: doNotOptimizeAway prevents dead code elimination
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    // Calculate statistics: min, max, mean, variance
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    // Variance: sum of squared differences from mean
    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_ns / iterations_per_sample,
        .min_ns = min_ns / iterations_per_sample,
        .max_ns = max_ns / iterations_per_sample,
        .variance_ns = variance_ns / (iterations_per_sample * iterations_per_sample),
    };
}
```

**Key Code Snippet (main.zig):**

```zig
const std = @import("std");
const benchmark_mod = @import("benchmark.zig");

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
    const stdout = std.io.getStdOut().writer();
    const iterations = 1_000_000;
    const n = 1000;

    try stdout.print("Benchmarking sum algorithms ({d} iterations)...\n\n", .{iterations});

    // Benchmark iterative approach
    const iterative_result = try benchmark_mod.benchmarkWithArg(
        @TypeOf(sumIterative),
        sumIterative,
        n,
        iterations,
    );

    // Benchmark formula approach
    const formula_result = try benchmark_mod.benchmarkWithArg(
        @TypeOf(sumFormula),
        sumFormula,
        n,
        iterations,
    );

    // Compare results
    try benchmark_mod.compareBenchmarks(
        stdout,
        "Formula",
        formula_result,
        "Iterative",
        iterative_result,
    );
}
```

**Patterns Demonstrated:**
- Warm-up iterations before measurement
- Multiple sample collection for statistics
- `std.mem.doNotOptimizeAway` to prevent optimization
- Computing min, max, mean, and variance
- Human-readable result formatting
- Comparison utilities with speedup calculation
- Coefficient of variation for consistency measurement

The complete example includes sorting algorithm benchmarks and slice operation timing. Build with `zig build -Doptimize=ReleaseFast` and run with `./zig-out/bin/benchmarking-demo`.

### Example 6: Profiling Integration

This example demonstrates build configuration for profiling, integration with Callgrind, perf, Massif, and flame graph generation.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/`

**Build Configuration (build.zig):**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "profiling-demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,  // Keep symbols for profiling
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the profiling demo");
    run_step.dependOn(&run_cmd.step);
}
```

**Profiling Script (scripts/profile_perf.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile with perf
echo "Recording profile with perf..."
perf record -F 999 -g ./zig-out/bin/profiling-demo

# Generate report
echo "Generating perf report..."
perf report --stdio > perf_report.txt

# Generate flame graph (if FlameGraph tools available)
if [ -d "FlameGraph" ]; then
    echo "Generating flame graph..."
    perf script > out.perf
    ./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
    ./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
    echo "Flame graph saved to flamegraph.svg"
fi

echo "Done! View perf_report.txt or flamegraph.svg"
```

**Profiling Script (scripts/profile_callgrind.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile with callgrind
echo "Running callgrind..."
valgrind --tool=callgrind \
         --callgrind-out-file=callgrind.out \
         ./zig-out/bin/profiling-demo

# Annotate results
echo "Generating annotated output..."
callgrind_annotate callgrind.out > callgrind_report.txt

echo "Done! View callgrind_report.txt or open callgrind.out with kcachegrind"
```

**Profiling Script (scripts/profile_massif.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile heap with massif
echo "Running massif..."
valgrind --tool=massif \
         --massif-out-file=massif.out \
         ./zig-out/bin/profiling-demo

# Print report
echo "Generating massif report..."
ms_print massif.out > massif_report.txt

echo "Done! View massif_report.txt"
```

**Patterns Demonstrated:**
- Build configuration with symbols preserved
- Integration with multiple profiling tools
- Automation scripts for profiling workflows
- Flame graph generation from perf data
- Callgrind for deterministic profiling
- Massif for heap profiling
- Practical profiling workflow

The complete example includes a demo application with computation, allocation, and I/O operations suitable for profiling. Run scripts from the project root: `./scripts/profile_perf.sh`.

## Common Pitfalls

This section documents frequent testing and benchmarking errors with incorrect and correct examples.

### Pitfall 1: Forgetting to Free Allocations

Memory leaks fail tests when using `testing.allocator`.

❌ **Incorrect:**
```zig
test "memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    // Forgot list.deinit()

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
// Test fails: memory leak detected
```

✅ **Correct:**
```zig
test "no memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit();  // Always defer cleanup

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

**Pattern:** Always pair allocation with `defer` cleanup immediately after initialization.

### Pitfall 2: Not Testing Error Paths

Testing only success paths leaves error handling unvalidated.

❌ **Incorrect:**
```zig
// Only tests happy path
test "parseNumber works" {
    const result = try parseNumber("42");
    try testing.expectEqual(42, result);
}
// What if input is invalid? Untested!
```

✅ **Correct:**
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

**Pattern:** Test both success and failure cases. Use `FailingAllocator` for allocation failures.

### Pitfall 3: Benchmarking Without doNotOptimizeAway

The compiler may optimize away entire benchmarks as dead code.

❌ **Incorrect:**
```zig
// Compiler may optimize away the entire loop
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    // result unused - dead code elimination
}
const elapsed = timer.read();
```

✅ **Correct:**
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);  // Force compiler to keep it
}
const elapsed = timer.read();
```

**Pattern:** Always use `std.mem.doNotOptimizeAway` on benchmark results.

### Pitfall 4: Single Benchmark Measurement

Single measurements are unreliable due to context switches and cache state.

❌ **Incorrect:**
```zig
// Unreliable - affected by context switches
var timer = try std.time.Timer.start();
expensiveOperation();
const elapsed = timer.read();
std.debug.print("Took {d} ns\n", .{elapsed});
```

✅ **Correct:**
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
std.debug.print("Min: {d} ns, Max: {d} ns, Avg: {d} ns\n", .{min, max, avg});
```

**Pattern:** Always collect multiple samples and report statistics.

### Pitfall 5: Benchmarking in Debug Mode

Debug mode results are meaningless—10-100x slower than release mode.

❌ **Incorrect:**
```bash
# Compiled with: zig build-exe benchmark.zig
# Results are 10-100x slower than release mode
```

✅ **Correct:**
```bash
# Always benchmark in release mode
zig build-exe -O ReleaseFast benchmark.zig
```

**Pattern:** Use `ReleaseFast` for benchmarks. Verify mode in build.zig.

### Pitfall 6: No Warm-up Phase

First iterations are slow due to cold caches and throttled CPU.

❌ **Incorrect:**
```zig
// First iterations are slow (cold cache, CPU throttled)
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    compute();
}
const elapsed = timer.read();
```

✅ **Correct:**
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

**Pattern:** Always warm up before measurement.

### Pitfall 7: Profiling Without Debug Symbols

Stripped binaries lose function names, making profiling output useless.

❌ **Incorrect:**
```bash
# Stripped binary loses function names
zig build -Doptimize=ReleaseFast -Dstrip=true
perf record ./zig-out/bin/myapp
perf report
# Shows only addresses, no function names
```

✅ **Correct:**
```bash
# Keep symbols for profiling
zig build -Doptimize=ReleaseFast -Dstrip=false
perf record ./zig-out/bin/myapp
perf report
# Shows function names and line numbers
```

**Pattern:** Always build with symbols for profiling (`-Dstrip=false`).

### Pitfall 8: Testing Implementation Details

Testing internal implementation is fragile—tests break when refactoring.

❌ **Incorrect:**
```zig
test "ArrayList internal capacity" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    // Testing internal implementation detail
    try testing.expect(list.capacity == 0);
    try list.append(1);
    try testing.expect(list.capacity >= 1);  // Fragile
}
```

✅ **Correct:**
```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try testing.expectEqual(@as(usize, 0), list.items.len);
    try list.append(1);
    try testing.expectEqual(@as(usize, 1), list.items.len);
    try testing.expectEqual(@as(u32, 1), list.items[0]);
}
```

**Pattern:** Test behavior, not implementation. Focus on public API.

### Pitfall 9: Race Conditions in Concurrent Tests

Concurrent tests without synchronization produce random failures.

❌ **Incorrect:**
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

    try testing.expectEqual(@as(u32, 4000), counter);  // May fail randomly
}
```

✅ **Correct:**
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

    try testing.expectEqual(@as(u32, 4000), counter.load(.monotonic));
}
```

**Pattern:** Use atomics or mutexes for shared state in concurrent tests.

### Pitfall 10: Comparing Floats with expectEqual

Floating-point arithmetic introduces rounding errors.

❌ **Incorrect:**
```zig
test "float equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectEqual(@as(f64, 2.0), result);  // May fail
}
```

✅ **Correct:**
```zig
test "float approximate equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}
```

**Pattern:** Use `expectApproxEqAbs` or `expectApproxEqRel` for floating-point comparisons.

### Pitfall 11: Hardcoded Test Data Paths

Hardcoded paths break in different environments.

❌ **Incorrect:**
```zig
test "load config file" {
    const config = try loadConfig("/home/user/test/config.json");  // Hardcoded
    try testing.expect(config.valid);
}
```

✅ **Correct:**
```zig
test "load config file" {
    const config_content =
        \\{ "setting": "value" }
    ;

    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{ .sub_path = "config.json", .data = config_content });

    const path = try tmp.dir.realpathAlloc(testing.allocator, ".");
    defer testing.allocator.free(path);

    const file_path = try std.fs.path.join(testing.allocator, &.{path, "config.json"});
    defer testing.allocator.free(file_path);

    const config = try loadConfig(file_path);
    try testing.expect(config.valid);
}
```

**Pattern:** Use relative paths or create temporary files for tests.

### Pitfall 12: Over-reliance on Random Tests

Random tests without deterministic seeds produce unreproducible failures.

❌ **Incorrect:**
```zig
test "random behavior" {
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = prng.random();

    const value = random.int(u32);
    // Test logic based on random value...
    // Hard to reproduce failures
}
```

✅ **Correct:**
```zig
test "deterministic random behavior" {
    var prng = std.Random.DefaultPrng.init(testing.random_seed);  // Deterministic
    const random = prng.random();

    const value = random.int(u32);
    // Test logic...
    // Failures are reproducible with same seed
}
```

**Pattern:** Use `testing.random_seed` for reproducible randomness.

## In Practice

This section examines production patterns from real-world Zig projects, demonstrating how testing scales to complex systems.

### TigerBeetle: Sophisticated Testing Infrastructure

TigerBeetle, a distributed financial database, demonstrates advanced testing patterns for distributed systems.[^17]

**Deterministic Time Simulation:**

TigerBeetle's `TimeSim` enables testing distributed consensus without flakiness:[^18]

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

Key patterns:
- Controlled time advancement via `tick()`
- Multiple offset types (linear drift, periodic, step jumps)
- Simulates clock skew and NTP adjustments
- Deterministic testing of time-dependent logic

**Network Simulation and Fault Injection:**

TigerBeetle's `PacketSimulator` tests distributed systems under realistic network conditions:[^19]

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

This enables comprehensive testing of consensus algorithms under adversarial conditions.

**Snapshot Testing:**

TigerBeetle's `snaptest.zig` provides auto-updating snapshot assertions:[^20]

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

Running with `SNAP_UPDATE=1` automatically updates source code snapshots on mismatch, drastically reducing refactoring friction.

**Fixture Pattern:**

Centralized initialization with sensible defaults:[^21]

```zig
pub const cluster: u128 = 0;
pub const replica: u8 = 0;
pub const replica_count: u8 = 6;

pub fn initStorage(allocator: std.mem.Allocator, options: Storage.Options) !Storage {
    return try Storage.init(allocator, options);
}

pub fn storageFormat(
    allocator: std.mem.Allocator,
    storage: *Storage,
    options: struct {
        cluster: u128 = cluster,
        replica: u8 = replica,
        replica_count: u8 = replica_count,
    },
) !void {
    // Complex initialization logic centralized
}
```

Benefits:
- Reduces test boilerplate
- Ensures consistent setup
- Single source of truth for defaults

### Ghostty: Cross-Platform Testing

Ghostty, a GPU-accelerated terminal emulator, demonstrates platform-specific testing patterns.[^22]

**Platform-Specific Tests:**

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

Pattern: Environmental assertions adapt to host system capabilities.

**Cleanup Patterns with errdefer:**

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

### ZLS: Custom Testing Utilities

ZLS (Zig Language Server) provides enhanced testing utilities.[^23]

**Custom Equality Comparison:**

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

**Probabilistic FailingAllocator:**

ZLS's enhanced `FailingAllocator`:[^24]

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

More flexible than Zig's built-in `FailingAllocator`, enabling probabilistic failure patterns for comprehensive error testing.

### Zig Standard Library Patterns

The standard library demonstrates idiomatic testing patterns.

**Colocated Tests:**

```zig
// std/array_list.zig
pub const ArrayList = struct {
    // Implementation...
};

test "init" {
    const list = ArrayList(u32).init(testing.allocator);
    defer list.deinit();
    try testing.expectEqual(@as(usize, 0), list.items.len);
}

test "basic" {
    var list = ArrayList(i32).init(testing.allocator);
    defer list.deinit();

    // Test basic operations...
}
```

**Generic Testing Across Types:**

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

## Summary

Zig's integrated approach to testing, benchmarking, and profiling provides developers with powerful tools for building reliable, performant software. This chapter covered the complete spectrum from basic test blocks to advanced production patterns.

**Core Mental Models:**

1. **Built-in Testing Integration**: Tests are first-class language features, not external dependencies. The `zig test` command discovers and executes tests automatically, providing immediate feedback without configuration overhead.

2. **Memory Safety as Default**: `testing.allocator` automatically detects memory leaks, enforcing cleanup discipline from the start. Tests fail on leaks, making memory safety violations immediately visible.

3. **Determinism Over Convenience**: Zig prioritizes reproducible results. Sequential test execution, deterministic random seeds, and explicit benchmarking control ensure consistent behavior across runs and environments.

4. **Manual Instrumentation for Accuracy**: Benchmarking requires explicit measurement using `std.time.Timer`, warm-up iterations, and `std.mem.doNotOptimizeAway`. This design prevents subtle measurement errors common in automatic frameworks.

5. **Tool Integration Not Replacement**: Profiling leverages industry-standard tools (perf, Valgrind) rather than custom solutions. Zig's build system configures symbols and optimization flags for effective profiling.

6. **Test Organization Flexibility**: Colocated tests keep implementation and validation synchronized. Separate test utilities handle reusable infrastructure. The `builtin.is_test` flag conditionally compiles test-only code without production overhead.

**When to Use What:**

| Use Case | Approach | Key Considerations |
|----------|----------|-------------------|
| Unit testing | Colocated test blocks | Use `testing.allocator`, test error paths |
| Integration testing | Separate test files | Setup fixtures, use arena allocators |
| Memory testing | `testing.allocator` + `FailingAllocator` | Test both success and failure paths |
| Parameterized testing | Table-driven with `inline for` | Comptime test generation for types |
| Benchmarking | Manual `Timer` + statistics | Warm-up, `doNotOptimizeAway`, multiple samples |
| Performance profiling | perf for sampling | Low overhead, production-realistic |
| Detailed profiling | Callgrind for instructions | Deterministic, high overhead |
| Memory profiling | Massif for heap analysis | Track allocations over time |

**Best Practices Recap:**

1. Always use `defer` for cleanup immediately after allocation
2. Test both success and error paths systematically
3. Use `testing.allocator` for automatic leak detection
4. Employ `FailingAllocator` to test allocation failure paths
5. Structure tests with descriptive names and clear assertions
6. Organize reusable test infrastructure in dedicated modules
7. Include warm-up iterations in benchmarks
8. Use `std.mem.doNotOptimizeAway` to prevent optimization
9. Collect multiple samples and compute statistics
10. Always benchmark in `ReleaseFast` mode
11. Build with symbols (`-Dstrip=false`) for profiling
12. Use `inline for` for parameterized tests across types

**Common Mistakes to Avoid:**

- Forgetting to free allocations in tests
- Testing only success paths without error handling
- Benchmarking without `doNotOptimizeAway`
- Single measurements without statistical analysis
- Benchmarking in Debug mode
- No warm-up phase before measurement
- Profiling without debug symbols
- Testing implementation details instead of behavior
- Race conditions in concurrent tests
- Using `expectEqual` for floating-point comparisons
- Hardcoded test data paths
- Random tests without deterministic seeds

**Production Patterns:**

Real-world projects demonstrate scaling these techniques:

- **TigerBeetle**: Deterministic time simulation, network fault injection, snapshot testing, comprehensive fixture patterns
- **Ghostty**: Platform-specific testing, cross-platform assertions, robust cleanup with `errdefer`
- **ZLS**: Custom equality comparison, enhanced `FailingAllocator`, semantic diff generation
- **Zig stdlib**: Colocated tests, generic type testing, consistent naming conventions

These patterns show Zig's testing philosophy in action: simplicity, explicitness, and zero hidden costs. Tests integrate seamlessly with development workflow. Benchmarking provides accurate measurements without magic. Profiling leverages proven tools with proper build configuration.

The manual nature of benchmarking and profiling in Zig might seem verbose compared to automatic frameworks. However, this explicitness prevents subtle errors and ensures developers understand what they're measuring. The cost is initial setup; the benefit is confidence in results.

Testing in Zig enforces good practices through the type system and memory model. Memory leak detection isn't optional—it's automatic. Error handling isn't suggested—the type system requires it. This design guides developers toward correct, maintainable code.

For developers new to Zig, start with basic test blocks and `testing.allocator`. Progress to table-driven tests for comprehensive validation. Add benchmarking when optimization matters. Integrate profiling when performance analysis requires detailed insights. The tools grow with project complexity.

The testing, benchmarking, and profiling capabilities in Zig enable building robust systems with confidence. From prototype through production, these integrated tools support the complete development lifecycle. Understanding and applying these patterns equips developers to write correct, performant Zig code.

## References

1. [Zig Language Reference: Testing](https://ziglang.org/documentation/master/#Testing)
2. [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76)
3. [Zig Standard Library: std.testing](https://ziglang.org/documentation/master/std/#std.testing)
4. [Zig stdlib: FailingAllocator](https://github.com/ziglang/zig/blob/master/lib/std/testing/FailingAllocator.zig)
5. [ZLS Custom FailingAllocator](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)
6. [TigerBeetle testing/ directory](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing)
7. [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig#L33-L52)
8. [Zig Build System Guide](https://ziglang.org/learn/build-system/)
9. [TigerBeetle time.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98)
10. [Zig stdlib: std.time.Timer](https://github.com/ziglang/zig/blob/master/lib/std/time.zig#L216-L268)
11. [Zig stdlib: std.mem.doNotOptimizeAway](https://github.com/ziglang/zig/blob/master/lib/std/mem.zig)
12. [Example 06: Profiling](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling)
13. [Valgrind Callgrind Documentation](https://valgrind.org/docs/manual/cl-manual.html)
14. [Linux perf Tutorial](https://perf.wiki.kernel.org/index.php/Tutorial)
15. [Valgrind Massif Documentation](https://valgrind.org/docs/manual/ms-manual.html)
16. [Brendan Gregg's Flame Graphs](https://www.brendangregg.com/flamegraphs.html)
17. [TigerBeetle GitHub Repository](https://github.com/tigerbeetle/tigerbeetle)
18. [TigerBeetle time.zig deterministic simulation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig)
19. [TigerBeetle packet_simulator.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig#L11-L42)
20. [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig)
21. [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig)
22. [Ghostty fontconfig test.zig](https://github.com/ghostty-org/ghostty/blob/main/pkg/fontconfig/test.zig)
23. [ZLS testing.zig](https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26)
24. [ZLS FailingAllocator](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)
25. [Zig Standard Library array_list.zig](https://github.com/ziglang/zig/blob/master/lib/std/array_list.zig)
26. [Zig Standard Library hash_map.zig](https://github.com/ziglang/zig/blob/master/lib/std/hash_map.zig)
27. [FlameGraph GitHub Repository](https://github.com/brendangregg/FlameGraph)
28. [Example 01: Testing Fundamentals](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/01_testing_fundamentals)
29. [Example 02: Test Organization](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/02_test_organization)
30. [Example 03: Parameterized Tests](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests)
31. [Example 04: Allocator Testing](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing)
32. [Example 05: Benchmarking](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking)
33. [TigerBeetle fuzz.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig)
34. [TigerBeetle storage.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/storage.zig)
35. [Zig 0.15 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
36. [Wasmtime Documentation](https://docs.wasmtime.dev/)
37. [WASI Tutorial](https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-tutorial.md)
38. [KCachegrind Documentation](https://kcachegrind.github.io/html/Home.html)
39. [Perf Wiki](https://perf.wiki.kernel.org/)
40. [Massif Visualizer](https://github.com/KDE/massif-visualizer)
41. [Hotspot Profiler](https://github.com/KDAB/hotspot)
42. [Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/)
43. [Zig Community: Testing Best Practices](https://github.com/ziglang/zig/wiki/Testing-Best-Practices)
44. [TigerBeetle state_machine_tests.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine_tests.zig)
45. [Ghostty freetype test.zig](https://github.com/ghostty-org/ghostty/blob/main/pkg/freetype/test.zig)

[^1]: https://ziglang.org/documentation/master/#Testing
[^2]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76
[^3]: https://ziglang.org/documentation/master/std/#std.testing
[^4]: https://github.com/ziglang/zig/blob/master/lib/std/testing/FailingAllocator.zig
[^5]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141
[^6]: https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing
[^7]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig#L33-L52
[^8]: https://ziglang.org/learn/build-system/
[^9]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98
[^10]: https://github.com/ziglang/zig/blob/master/lib/std/time.zig#L216-L268
[^11]: https://github.com/ziglang/zig/blob/master/lib/std/mem.zig
[^12]: file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling
[^13]: https://valgrind.org/docs/manual/cl-manual.html
[^14]: https://perf.wiki.kernel.org/index.php/Tutorial
[^15]: https://valgrind.org/docs/manual/ms-manual.html
[^16]: https://www.brendangregg.com/flamegraphs.html
[^17]: https://github.com/tigerbeetle/tigerbeetle
[^18]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig
[^19]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig#L11-L42
[^20]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig
[^21]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig
[^22]: https://github.com/ghostty-org/ghostty/blob/main/pkg/fontconfig/test.zig
[^23]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26
[^24]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141
