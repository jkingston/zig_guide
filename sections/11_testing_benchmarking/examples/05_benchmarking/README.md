# Example 5: Benchmarking Patterns

Comprehensive demonstration of micro-benchmarking techniques in Zig for comparing algorithm performance, preventing compiler optimization, and reporting results with statistical validity.

## Table of Contents

- [Learning Objectives](#learning-objectives)
- [Key Concepts](#key-concepts)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Benchmark Patterns](#benchmark-patterns)
- [Implementation Details](#implementation-details)
- [Common Pitfalls](#common-pitfalls)
- [Best Practices](#best-practices)
- [Build Mode Comparison](#build-mode-comparison)
- [Code Examples](#code-examples)
- [Running the Benchmarks](#running-the-benchmarks)
- [Interpreting Results](#interpreting-results)
- [Compatibility Notes](#compatibility-notes)

## Learning Objectives

After studying this example, you will understand:

1. **Manual Timing**: Using `std.time.Timer` for high-precision measurement
2. **Preventing Optimization**: How to use `std.mem.doNotOptimizeAway` to prevent dead code elimination
3. **Warm-up Iterations**: Why they matter for CPU cache and frequency stabilization
4. **Statistical Measurement**: Collecting multiple samples for min, max, mean, and variance
5. **Comparing Implementations**: How to fairly compare different algorithms
6. **Build Modes**: Impact of Debug vs ReleaseSafe vs ReleaseFast on performance
7. **Measurement Overhead**: Understanding and minimizing timer impact
8. **Algorithm Analysis**: Using benchmarks to validate theoretical complexity

## Key Concepts

### 1. std.time.Timer

Zig's high-precision timer for benchmarking:

```zig
var timer = try std.time.Timer.start();
// ... code to benchmark ...
const elapsed_ns = timer.read();
```

**Important**:
- Provides nanosecond precision
- Uses platform-specific high-resolution timers
- `start()` can fail on some platforms (returns error union)
- `read()` returns elapsed time in nanoseconds since start
- Can `reset()` to start timing again from zero

### 2. std.mem.doNotOptimizeAway

**Critical** for preventing compiler optimization:

```zig
const result = functionToTest(input);
std.mem.doNotOptimizeAway(&result);  // Prevent dead code elimination
```

**Why it matters**:
- The optimizer is very aggressive in release modes
- It will eliminate "unused" computations
- Without this, your entire benchmark might be optimized away
- The function takes a pointer, forcing the value to be materialized in memory

**Wrong** ❌:
```zig
for (0..1000) |_| {
    _ = expensiveFunction();  // Compiler might remove this!
}
```

**Right** ✅:
```zig
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}
```

### 3. Warm-up Phase

Stabilizes performance before measurement:

```zig
// Warm-up: 5-10% of total iterations
for (0..warmup_iterations) |_| {
    const result = functionToTest(input);
    std.mem.doNotOptimizeAway(&result);
}

// Now measure
var timer = try std.time.Timer.start();
for (0..iterations) |_| {
    const result = functionToTest(input);
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
```

**What warm-up does**:
- **CPU frequency scaling**: Modern CPUs boost frequency under load
- **Cache warming**: Loads hot code paths into L1/L2 cache
- **Branch predictor**: Trains branch prediction for loops
- **Memory prefetcher**: Trains hardware prefetcher patterns

**Without warm-up**: First iterations are slower, skewing average

### 4. Multiple Iterations

Why multiple iterations matter:

```zig
// Run multiple samples for statistics
var samples: [10]u64 = undefined;
for (&samples) |*sample| {
    var timer = try std.time.Timer.start();
    // ... benchmark code ...
    sample.* = timer.read();
}

// Calculate statistics
const min = std.mem.min(u64, &samples);
const max = std.mem.max(u64, &samples);
const mean = calculateMean(&samples);
const variance = calculateVariance(&samples, mean);
```

**Why statistics matter**:
- Individual runs have noise (context switches, interrupts)
- Outliers can skew single measurements
- Variance indicates consistency
- Confidence intervals help determine if differences are real

### 5. Build Modes

Performance varies dramatically by build mode:

| Mode | Safety Checks | Optimizations | Use Case |
|------|--------------|---------------|----------|
| **Debug** | Full | None | Never for benchmarks |
| **ReleaseSafe** | Full | Full | Good balance |
| **ReleaseFast** | Minimal | Maximum | Maximum speed |
| **ReleaseSmall** | Minimal | Size-focused | Code size, not speed |

**For benchmarking**: Use `ReleaseSafe` or `ReleaseFast`

**Performance difference**: Debug can be 10-100x slower!

### 6. Measurement Overhead

Timer overhead affects results:

```zig
// Overhead can be significant for fast operations
const single_call_ns = 50;
const timer_overhead_ns = 20;
const measured_ns = single_call_ns + timer_overhead_ns;  // 40% error!
```

**Solutions**:
1. **Amortize overhead**: Run many iterations per timing
2. **Subtract baseline**: Measure empty loop overhead
3. **Focus on relative comparisons**: Overhead cancels out

**Good practice**: Run at least 1000 iterations for operations under 1µs

### 7. Statistical Analysis

Understanding the numbers:

```zig
pub const BenchmarkResult = struct {
    iterations: u64,     // Total iterations run
    total_ns: u64,       // Total time across all samples
    avg_ns: u64,         // Average time per iteration
    min_ns: u64,         // Best case (least interruption)
    max_ns: u64,         // Worst case (most interruption)
    variance_ns: u64,    // Spread of measurements
};
```

**Key metrics**:
- **Mean**: Average performance (affected by outliers)
- **Min**: Best-case (shows pure algorithm speed)
- **Max**: Worst-case (shows stability)
- **Variance**: Consistency (low = predictable)
- **Coefficient of Variation (CV)**: stddev/mean, relative consistency

**Interpreting CV**:
- CV < 5%: Excellent consistency
- CV 5-10%: Good consistency
- CV 10-20%: Fair, may need more iterations
- CV > 20%: Poor, unreliable results

## Project Structure

```
05_benchmarking/
├── src/
│   ├── main.zig           # Main demo with benchmark runner
│   ├── algorithms.zig     # Algorithm implementations to compare
│   ├── benchmark.zig      # Reusable benchmark framework
│   └── sorting.zig        # Sorting algorithms comparison
├── build.zig              # Build configuration
└── README.md              # This file
```

### File Purposes

**src/benchmark.zig**:
- Reusable benchmarking framework
- `benchmark()`, `benchmarkWithArg()`, `benchmarkSliceOp()` functions
- Statistical result collection and comparison
- Pretty-printing utilities

**src/algorithms.zig**:
- Various algorithm implementations (naive vs optimized)
- Sum, string search, fibonacci, hashing
- Demonstrates optimization techniques

**src/sorting.zig**:
- Multiple sorting algorithm implementations
- Test data generation (random, sorted, reverse-sorted)
- Sorting-specific benchmark helpers

**src/main.zig**:
- Demonstrates using the benchmark framework
- Runs comprehensive benchmark suite
- Shows formatted output with comparisons

## Quick Start

### Build and Run

```bash
# Build with default optimization (ReleaseSafe)
zig build

# Run benchmarks
zig build run

# Build with maximum optimization (ReleaseFast)
zig build -Doptimize=ReleaseFast run

# Build in Debug mode (for comparison - very slow!)
zig build -Doptimize=Debug run
```

### Expected Output

```
================================================================================
  Zig Benchmarking Patterns Demo
================================================================================

Benchmark 1: Sum Algorithms (Naive vs Optimized vs SIMD-style)
--------------------------------------------------------------------------------

Comparison:
  Optimized (unrolled):
    Iterations: 10000
    Average:    245 ns
    Min:        240 ns
    Max:        267 ns
    Variance:   45 ns²
    CV:         2.74%

  Naive:
    Iterations: 10000
    Average:    389 ns
    Min:        385 ns
    Max:        412 ns
    Variance:   67 ns²
    CV:         2.10%

  Result:
    Optimized (unrolled) is 1.59x faster than Naive
    Difference: 144 ns (37.0%)

[... more benchmarks ...]
```

## Benchmark Patterns

### Pattern 1: Simple Function Benchmark

**Use case**: Benchmark a parameterless function

```zig
const MyFunction = struct {
    fn call() u64 {
        return expensiveCalculation();
    }
};

const result = try benchmark.benchmark(
    *const fn () u64,
    MyFunction.call,
    10_000  // iterations
);

try benchmark.printBenchmarkResult(stdout, "My Function", result);
```

**Key points**:
- Function must return a value (prevents optimization)
- Use high iteration count for accurate timing
- Wrapper struct for closure capture if needed

### Pattern 2: Function with Arguments

**Use case**: Benchmark with different input values

```zig
const result = try benchmark.benchmarkWithArg(
    *const fn (u32) u64,
    fibonacci,
    30,      // argument
    1_000    // iterations
);
```

**Key points**:
- Pass argument to function
- Useful for testing with different input sizes
- Can create multiple wrappers for different arguments

### Pattern 3: Slice Operations

**Use case**: Benchmark operations on arrays/slices

```zig
const data: []const i64 = ...;

const SumWrapper = struct {
    fn call(d: []const i64) i64 {
        return sumArray(d);
    }
};

const result = try benchmark.benchmarkSliceOp(
    i64,
    *const fn ([]const i64) i64,
    SumWrapper.call,
    data,
    10_000
);
```

**Key points**:
- Specialized for slice operations
- Prevents compiler from knowing array size at compile time
- Good for array/string processing benchmarks

### Pattern 4: Comparing Two Implementations

**Use case**: A/B testing algorithm variants

```zig
// Benchmark both versions
const result_v1 = try benchmark.benchmark(..., version1, ...);
const result_v2 = try benchmark.benchmark(..., version2, ...);

// Compare and print
try benchmark.compareBenchmarks(
    stdout,
    "Version 1", result_v1,
    "Version 2", result_v2
);
```

**Output shows**:
- Both benchmark results
- Speedup ratio (which is faster)
- Absolute and percentage difference

### Pattern 5: Scaling with Input Size

**Use case**: Understanding algorithm complexity

```zig
const sizes = [_]usize{ 100, 1_000, 10_000, 100_000 };

for (sizes) |size| {
    const data = try allocator.alloc(T, size);
    defer allocator.free(data);

    const result = try benchmark.benchmarkSliceOp(...);

    std.debug.print("Size {d}: {d} ns ({d:.3} ns/elem)\n", .{
        size,
        result.avg_ns,
        @as(f64, @floatFromInt(result.avg_ns)) / @as(f64, @floatFromInt(size)),
    });
}
```

**What to look for**:
- O(n): ns/elem stays constant
- O(n²): ns/elem grows linearly
- O(n log n): ns/elem grows slowly

## Implementation Details

### Benchmark Framework Architecture

The `benchmark.zig` framework is designed around these principles:

1. **Warm-up phase**: 10% of iterations (capped at 100)
2. **Multiple samples**: 10 samples (or iterations/100)
3. **Statistical analysis**: min, max, mean, variance
4. **Type safety**: Uses `comptime` for type parameters
5. **Prevention**: Always uses `doNotOptimizeAway`

### How benchmark() Works

```zig
pub fn benchmark(
    comptime Func: type,
    func: Func,
    iterations: u64,
) !BenchmarkResult {
    // 1. Warm-up phase
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    // 2. Collect samples
    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func();
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    // 3. Calculate statistics
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    // 4. Calculate variance
    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    // 5. Return per-iteration statistics
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

### Algorithm Implementations

#### Sum: Naive vs Optimized

**Naive** (baseline):
```zig
pub fn sumNaive(data: []const i64) i64 {
    var sum: i64 = 0;
    for (data) |value| {
        sum += value;
    }
    return sum;
}
```

**Optimized** (loop unrolling):
```zig
pub fn sumOptimized(data: []const i64) i64 {
    var sum: i64 = 0;
    var i: usize = 0;

    // Process 4 elements at a time
    while (i + 4 <= data.len) : (i += 4) {
        sum += data[i];
        sum += data[i + 1];
        sum += data[i + 2];
        sum += data[i + 3];
    }

    // Handle remainder
    while (i < data.len) : (i += 1) {
        sum += data[i];
    }

    return sum;
}
```

**Why optimized is faster**:
1. **Reduced loop overhead**: 4x fewer loop iterations
2. **Better CPU pipeline**: Multiple adds can execute in parallel
3. **Reduced branch mispredictions**: Fewer loop checks

**Expected speedup**: 1.3-2.0x depending on data size and CPU

#### Fibonacci: Recursive vs Iterative

**Recursive** (exponential time):
```zig
pub fn fibRecursive(n: u32) u64 {
    if (n <= 1) return n;
    return fibRecursive(n - 1) + fibRecursive(n - 2);
}
```

**Iterative** (linear time):
```zig
pub fn fibIterative(n: u32) u64 {
    if (n <= 1) return n;

    var a: u64 = 0;
    var b: u64 = 1;
    var i: u32 = 2;

    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }

    return b;
}
```

**Performance**:
- fib(20): Iterative is ~100-1000x faster
- fib(30): Iterative is ~10,000x faster
- fib(40): Iterative is millions of times faster

**Why**: Recursive is O(2^n), iterative is O(n)

#### Hash: Simple vs Optimized

**Simple** (byte-by-byte):
```zig
pub fn hashSimple(data: []const u8) u64 {
    var hash: u64 = 0;
    for (data) |byte| {
        hash = hash *% 31 +% byte;
    }
    return hash;
}
```

**Optimized** (8 bytes at a time):
```zig
pub fn hashOptimized(data: []const u8) u64 {
    const FNV_OFFSET: u64 = 14695981039346656037;
    const FNV_PRIME: u64 = 1099511628211;

    var hash: u64 = FNV_OFFSET;
    var i: usize = 0;

    // Process 8 bytes at a time
    while (i + 8 <= data.len) : (i += 8) {
        const chunk = std.mem.readInt(u64, data[i..][0..8], .little);
        hash ^= chunk;
        hash *%= FNV_PRIME;
    }

    // Process remaining bytes
    while (i < data.len) : (i += 1) {
        hash ^= data[i];
        hash *%= FNV_PRIME;
    }

    return hash;
}
```

**Why optimized is faster**:
- 8x fewer loop iterations
- Better memory access patterns
- Compiler can optimize 64-bit operations better

**Expected speedup**: 2-5x for large inputs

### Sorting Implementations

Three algorithms with different characteristics:

#### Bubble Sort (O(n²))
```zig
pub fn bubbleSort(data: []i32) void {
    var i: usize = 0;
    while (i < data.len - 1) : (i += 1) {
        var j: usize = 0;
        while (j < data.len - 1 - i) : (j += 1) {
            if (data[j] > data[j + 1]) {
                const temp = data[j];
                data[j] = data[j + 1];
                data[j + 1] = temp;
            }
        }
    }
}
```

**Characteristics**:
- Simple but slow
- O(n²) comparisons and swaps
- Good for tiny arrays (< 10 elements)
- Best case (sorted): O(n²) (can be optimized to O(n))
- Worst case (reverse): O(n²)

#### Insertion Sort (O(n²))
```zig
pub fn insertionSort(data: []i32) void {
    var i: usize = 1;
    while (i < data.len) : (i += 1) {
        const key = data[i];
        var j: usize = i;

        while (j > 0 and data[j - 1] > key) : (j -= 1) {
            data[j] = data[j - 1];
        }

        data[j] = key;
    }
}
```

**Characteristics**:
- O(n²) worst case, O(n) best case
- Adaptive: fast on nearly-sorted data
- Good for small arrays (< 50 elements)
- Stable sort (preserves order of equal elements)

#### Quick Sort (O(n log n))
```zig
pub fn quickSort(data: []i32) void {
    if (data.len <= 1) return;
    quickSortImpl(data, 0, data.len - 1);
}

fn quickSortImpl(data: []i32, low: usize, high: usize) void {
    if (low >= high) return;

    // Optimization: use insertion sort for small subarrays
    if (high - low < 10) {
        insertionSortRange(data, low, high + 1);
        return;
    }

    const pivot_idx = partition(data, low, high);

    if (pivot_idx > 0) {
        quickSortImpl(data, low, pivot_idx - 1);
    }
    if (pivot_idx < high) {
        quickSortImpl(data, pivot_idx + 1, high);
    }
}
```

**Characteristics**:
- O(n log n) average, O(n²) worst case
- In-place (low memory usage)
- Not stable
- Fast in practice (good cache locality)
- Hybrid approach: switches to insertion sort for small subarrays

**Performance on different data**:

| Data Type | Bubble Sort | Insertion Sort | Quick Sort |
|-----------|-------------|----------------|------------|
| Random | Very slow | Slow | Fast |
| Sorted | Very slow | Very fast | Medium |
| Reverse | Very slow | Very slow | Medium |
| Partial | Very slow | Fast | Fast |

## Common Pitfalls

### Pitfall 1: Compiler Optimizing Away Code

❌ **Wrong**:
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    _ = expensiveFunction();  // Might be optimized away!
}
const elapsed = timer.read();
```

✅ **Right**:
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);  // Prevent optimization
}
const elapsed = timer.read();
```

**Why**: In release modes, the compiler sees the result is unused and might eliminate the entire call.

### Pitfall 2: No Warm-up Iterations

❌ **Wrong**:
```zig
// Immediately start timing
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}
```

✅ **Right**:
```zig
// Warm-up first
for (0..100) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}

// Now time
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}
```

**Why**: First iterations are slower due to cold cache, low CPU frequency, untrained branch predictor.

### Pitfall 3: Insufficient Iterations

❌ **Wrong**:
```zig
// Only 10 iterations - too few!
var timer = try std.time.Timer.start();
for (0..10) |_| {
    const result = fastFunction();  // < 1µs
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
const avg = elapsed / 10;  // High error from timer overhead
```

✅ **Right**:
```zig
// Enough iterations to amortize timer overhead
var timer = try std.time.Timer.start();
for (0..10000) |_| {
    const result = fastFunction();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
const avg = elapsed / 10000;  // Low error
```

**Why**: Timer overhead (20-50ns) dominates measurement for fast functions.

**Rule of thumb**: Run enough iterations that total time > 1ms.

### Pitfall 4: Benchmarking in Debug Mode

❌ **Wrong**:
```bash
zig build run  # Might default to Debug!
```

✅ **Right**:
```bash
zig build -Doptimize=ReleaseSafe run
# or
zig build -Doptimize=ReleaseFast run
```

**Why**: Debug mode can be 10-100x slower! Results are meaningless.

**Always check**: `std.debug.print("Build mode: {s}\n", .{@import("builtin").mode});`

### Pitfall 5: Including Setup in Benchmark

❌ **Wrong**:
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const data = try allocator.alloc(u8, 1024);  // Setup!
    defer allocator.free(data);

    processData(data);  // Actual work
}
const elapsed = timer.read();
```

✅ **Right**:
```zig
// Setup once
const data = try allocator.alloc(u8, 1024);
defer allocator.free(data);

// Benchmark only the work
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    processData(data);
}
const elapsed = timer.read();
```

**Why**: You want to measure the algorithm, not allocation overhead.

### Pitfall 6: Not Using doNotOptimizeAway Correctly

❌ **Wrong**:
```zig
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(result);  // Missing &!
}
```

✅ **Right**:
```zig
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);  // Takes pointer!
}
```

**Why**: `doNotOptimizeAway` requires a pointer to force materialization.

### Pitfall 7: Measuring Too Fast Operations

❌ **Wrong**:
```zig
// Operation takes 5ns
var timer = try std.time.Timer.start();
const result = veryFastFunction();
const elapsed = timer.read();  // Might be 0 or inaccurate!
```

✅ **Right**:
```zig
// Run many iterations
var timer = try std.time.Timer.start();
for (0..100000) |_| {
    const result = veryFastFunction();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
const avg_ns = elapsed / 100000;
```

**Why**: Single-nanosecond operations are hard to time accurately. Amortize over many iterations.

### Pitfall 8: Not Accounting for Variance

❌ **Wrong**:
```zig
// Single measurement
var timer = try std.time.Timer.start();
// ... benchmark ...
const time = timer.read();
std.debug.print("Time: {d}ns\n", .{time});  // One sample!
```

✅ **Right**:
```zig
// Multiple samples
var samples: [10]u64 = undefined;
for (&samples) |*s| {
    var timer = try std.time.Timer.start();
    // ... benchmark ...
    s.* = timer.read();
}

const min = std.mem.min(u64, &samples);
const max = std.mem.max(u64, &samples);
const avg = calculateMean(&samples);
std.debug.print("Min: {d}ns, Avg: {d}ns, Max: {d}ns\n", .{min, avg, max});
```

**Why**: Single measurements can be outliers. Statistics give confidence.

## Best Practices

### 1. Always Use Release Modes

```bash
# Default to ReleaseSafe for good balance
zig build -Doptimize=ReleaseSafe run

# Use ReleaseFast for maximum speed
zig build -Doptimize=ReleaseFast run
```

**Never** use Debug mode for benchmarks.

### 2. Include Warm-up Iterations

```zig
const warmup = @min(iterations / 10, 100);
for (0..warmup) |_| {
    const result = func();
    std.mem.doNotOptimizeAway(&result);
}
```

**How many**: 5-10% of total iterations, capped at 100-1000.

### 3. Run Enough Iterations

```zig
// For fast operations (< 1µs): 10,000+ iterations
// For medium operations (1-100µs): 1,000-10,000 iterations
// For slow operations (> 100µs): 100-1,000 iterations

const iterations = if (expectedTimeNs < 1000)
    10_000
else if (expectedTimeNs < 100_000)
    1_000
else
    100;
```

**Goal**: Total benchmark time > 1ms for accurate measurement.

### 4. Use doNotOptimizeAway on Results

```zig
// Always prevent optimization
const result = func();
std.mem.doNotOptimizeAway(&result);
```

**For loops**: Accumulate results to prevent optimization:
```zig
var accumulator: u64 = 0;
for (0..iterations) |_| {
    accumulator +%= func();
}
std.mem.doNotOptimizeAway(&accumulator);
```

### 5. Measure Multiple Times

```zig
// Collect multiple samples
var samples: [10]u64 = undefined;
for (&samples) |*sample| {
    // ... benchmark and store time ...
}

// Report statistics
const min = std.mem.min(u64, &samples);
const max = std.mem.max(u64, &samples);
const mean = calculateMean(&samples);
```

**Why**: Gives confidence and detects outliers.

### 6. Separate Setup from Measurement

```zig
// Setup (outside timing)
const data = try allocator.alloc(T, size);
defer allocator.free(data);
initializeData(data);

// Warm-up
for (0..warmup) |_| {
    std.mem.doNotOptimizeAway(processData(data));
}

// Benchmark (only the operation)
var timer = try std.time.Timer.start();
for (0..iterations) |_| {
    std.mem.doNotOptimizeAway(processData(data));
}
const elapsed = timer.read();
```

### 7. Test on Representative Data

```zig
// Don't just test with zeros!
var prng = std.Random.DefaultPrng.init(seed);
const random = prng.random();

for (data) |*value| {
    value.* = random.int(T);
}
```

**Consider**:
- Random data
- Sorted data
- Reverse-sorted data
- Pathological cases
- Real-world data distribution

### 8. Report Units Clearly

```zig
if (time_ns > 1_000_000) {
    const ms = @as(f64, @floatFromInt(time_ns)) / 1_000_000.0;
    try writer.print("{d:.3} ms\n", .{ms});
} else if (time_ns > 1_000) {
    const us = @as(f64, @floatFromInt(time_ns)) / 1_000.0;
    try writer.print("{d:.3} µs\n", .{us});
} else {
    try writer.print("{d} ns\n", .{time_ns});
}
```

**Use human-readable units**: ns, µs, ms, not just nanoseconds.

### 9. Include Confidence Metrics

```zig
const stddev = std.math.sqrt(@as(f64, @floatFromInt(variance)));
const cv = (stddev / @as(f64, @floatFromInt(mean))) * 100.0;

try writer.print("CV: {d:.2}%\n", .{cv});
```

**Coefficient of Variation (CV)** indicates reliability:
- < 5%: Very reliable
- 5-10%: Reliable
- \> 10%: Consider more iterations

### 10. Compare Apples to Apples

```zig
// Same data for both algorithms
const data = generateTestData();

const result1 = benchmarkAlg1(data);
const result2 = benchmarkAlg2(data);

// Compare
const speedup = result1.speedupVs(result2);
```

**Ensure**:
- Same input data
- Same build mode
- Same system state
- Same number of iterations

## Build Mode Comparison

### Debug Mode

**Characteristics**:
- No optimizations
- Full safety checks (bounds, overflow, etc.)
- Debug symbols included
- Assertions enabled

**Performance**: **BASELINE (1x)** - This is the slowest

**Use for**: Development, debugging, never benchmarking

**Example**:
```bash
zig build -Doptimize=Debug run
```

**Typical slowdown vs ReleaseFast**: **10-100x slower**

### ReleaseSafe Mode

**Characteristics**:
- Full optimizations
- Full safety checks (bounds, overflow, etc.)
- No debug symbols
- Assertions disabled

**Performance**: **5-10x faster than Debug**

**Use for**:
- Default benchmarking (good balance)
- Production code where safety is critical
- Comparing "real-world" performance

**Example**:
```bash
zig build -Doptimize=ReleaseSafe run
```

**Tradeoff**: Slight overhead from safety checks (~10-20% slower than ReleaseFast)

### ReleaseFast Mode

**Characteristics**:
- Full optimizations
- **Minimal safety checks** (only critical ones)
- No debug symbols
- Assertions disabled
- No bounds checking
- No overflow checking

**Performance**: **8-100x faster than Debug, 1.1-1.5x faster than ReleaseSafe**

**Use for**:
- Maximum performance benchmarks
- Comparing "theoretical peak" performance
- Production code where maximum speed is critical

**Example**:
```bash
zig build -Doptimize=ReleaseFast run
```

**Warning**: Undefined behavior if safety checks would have triggered!

### ReleaseSmall Mode

**Characteristics**:
- Size optimizations (not speed)
- Minimal safety checks
- No debug symbols

**Performance**: **Unpredictable** - optimized for code size, not speed

**Use for**: Embedded systems, WebAssembly where size matters

**Example**:
```bash
zig build -Doptimize=ReleaseSmall run
```

**Don't use for**: Performance benchmarking (unless testing code size impact)

### Performance Comparison Table

Example benchmark results (summing 10,000 integers):

| Build Mode | Time | Relative | Safety Checks |
|------------|------|----------|---------------|
| Debug | 12,500 ns | 1.0x (baseline) | Full |
| ReleaseSafe | 350 ns | **35.7x faster** | Full |
| ReleaseFast | 245 ns | **51.0x faster** | Minimal |
| ReleaseSmall | 390 ns | 32.1x faster | Minimal |

**Key takeaways**:
1. Debug is **dramatically** slower
2. ReleaseSafe is excellent balance (only 30% slower than ReleaseFast)
3. ReleaseFast is maximum speed but less safe
4. ReleaseSmall is unpredictable for speed

### Recommendation for Benchmarking

**Default**: Use **ReleaseSafe**
- Representative of production performance
- Maintains safety guarantees
- Only slightly slower than ReleaseFast

**Maximum speed**: Use **ReleaseFast**
- Shows theoretical peak performance
- Useful for algorithm comparison
- Be aware of missing safety checks

**Never**: Use Debug
- Results are meaningless
- 10-100x slower than real performance

## Code Examples

### Example 1: Basic Benchmark

```zig
const std = @import("std");
const benchmark = @import("benchmark.zig");

fn fibonacci(n: u32) u64 {
    if (n <= 1) return n;
    var a: u64 = 0;
    var b: u64 = 1;
    var i: u32 = 2;
    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }
    return b;
}

pub fn main() !void {
    const FibWrapper = struct {
        fn call() u64 {
            return fibonacci(30);
        }
    };

    const result = try benchmark.benchmark(
        *const fn () u64,
        FibWrapper.call,
        10_000
    );

    const stdout = std.io.getStdOut().writer();
    try benchmark.printBenchmarkResult(stdout, "Fibonacci(30)", result);
}
```

### Example 2: Comparing Implementations

```zig
const std = @import("std");
const benchmark = @import("benchmark.zig");

fn sumNaive(data: []const i64) i64 {
    var sum: i64 = 0;
    for (data) |value| {
        sum += value;
    }
    return sum;
}

fn sumOptimized(data: []const i64) i64 {
    var sum: i64 = 0;
    var i: usize = 0;
    while (i + 4 <= data.len) : (i += 4) {
        sum += data[i] + data[i+1] + data[i+2] + data[i+3];
    }
    while (i < data.len) : (i += 1) {
        sum += data[i];
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Generate test data
    const data = try allocator.alloc(i64, 10_000);
    defer allocator.free(data);

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    for (data) |*value| {
        value.* = random.int(i64);
    }

    // Wrappers for benchmarking
    const NaiveWrapper = struct {
        fn call(d: []const i64) i64 {
            return sumNaive(d);
        }
    };

    const OptimizedWrapper = struct {
        fn call(d: []const i64) i64 {
            return sumOptimized(d);
        }
    };

    // Benchmark both
    const result_naive = try benchmark.benchmarkSliceOp(
        i64,
        *const fn ([]const i64) i64,
        NaiveWrapper.call,
        data,
        10_000
    );

    const result_optimized = try benchmark.benchmarkSliceOp(
        i64,
        *const fn ([]const i64) i64,
        OptimizedWrapper.call,
        data,
        10_000
    );

    // Compare
    const stdout = std.io.getStdOut().writer();
    try benchmark.compareBenchmarks(
        stdout,
        "Optimized", result_optimized,
        "Naive", result_naive
    );
}
```

### Example 3: Scaling with Input Size

```zig
const std = @import("std");
const benchmark = @import("benchmark.zig");

fn processData(data: []const u8) u64 {
    var hash: u64 = 0;
    for (data) |byte| {
        hash = hash *% 31 +% byte;
    }
    return hash;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Performance vs Input Size:\n", .{});

    const sizes = [_]usize{ 100, 1_000, 10_000, 100_000 };

    for (sizes) |size| {
        const data = try allocator.alloc(u8, size);
        defer allocator.free(data);

        // Initialize with random data
        var prng = std.Random.DefaultPrng.init(42);
        const random = prng.random();
        for (data) |*byte| {
            byte.* = random.int(u8);
        }

        const Wrapper = struct {
            fn call(d: []const u8) u64 {
                return processData(d);
            }
        };

        const result = try benchmark.benchmarkSliceOp(
            u8,
            *const fn ([]const u8) u64,
            Wrapper.call,
            data,
            10_000
        );

        const ns_per_elem = @as(f64, @floatFromInt(result.avg_ns)) /
                           @as(f64, @floatFromInt(size));

        try stdout.print("  Size {d:>6}: {d:>6} ns total, {d:.3} ns/elem\n",
            .{size, result.avg_ns, ns_per_elem});
    }
}
```

### Example 4: Custom Benchmark Loop

```zig
const std = @import("std");

fn customBenchmark(allocator: std.mem.Allocator) !void {
    const iterations = 1000;
    const warmup = 100;

    // Setup
    const data = try allocator.alloc(u8, 1024);
    defer allocator.free(data);

    // Warm-up
    var i: usize = 0;
    while (i < warmup) : (i += 1) {
        const result = processData(data);
        std.mem.doNotOptimizeAway(&result);
    }

    // Collect samples
    var samples: [10]u64 = undefined;
    for (&samples) |*sample| {
        var timer = try std.time.Timer.start();

        i = 0;
        while (i < iterations) : (i += 1) {
            const result = processData(data);
            std.mem.doNotOptimizeAway(&result);
        }

        sample.* = timer.read();
    }

    // Calculate statistics
    var min: u64 = std.math.maxInt(u64);
    var max: u64 = 0;
    var sum: u64 = 0;

    for (samples) |s| {
        min = @min(min, s);
        max = @max(max, s);
        sum += s;
    }

    const avg = sum / samples.len;
    const avg_per_iter = avg / iterations;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Average: {d} ns per iteration\n", .{avg_per_iter});
    try stdout.print("Min: {d} ns\n", .{min / iterations});
    try stdout.print("Max: {d} ns\n", .{max / iterations});
}
```

## Running the Benchmarks

### Basic Usage

```bash
# Build and run with default optimization (ReleaseSafe)
zig build run

# Build with maximum optimization
zig build -Doptimize=ReleaseFast run

# Build and install the executable
zig build
./zig-out/bin/benchmarking
```

### Expected Output

The benchmark suite runs 7 different benchmark scenarios:

```
================================================================================
  Zig Benchmarking Patterns Demo
================================================================================

Benchmark 1: Sum Algorithms (Naive vs Optimized vs SIMD-style)
--------------------------------------------------------------------------------

Comparison:
  Optimized (unrolled):
    Iterations: 10000
    Average:    245 ns
    Min:        240 ns
    Max:        267 ns
    Variance:   45 ns²
    CV:         2.74%

  Naive:
    Iterations: 10000
    Average:    389 ns
    Min:        385 ns
    Max:        412 ns
    Variance:   67 ns²
    CV:         2.10%

  Result:
    Optimized (unrolled) is 1.59x faster than Naive
    Difference: 144 ns (37.0%)

[... continues with more benchmarks ...]

Benchmark 2: String Search (Naive vs Optimized)
Benchmark 3: Fibonacci (Recursive vs Iterative vs Memoized)
Benchmark 4: Hash Functions (Simple vs FNV1a vs Optimized)
Benchmark 5: String Building (Concatenation vs ArrayList)
Benchmark 6: Sorting Algorithms (Different Algorithms & Data)
Benchmark 7: Sum Performance vs Data Size

================================================================================
  Benchmarking Complete
================================================================================
```

### Interpreting Output

Each benchmark shows:

1. **Iterations**: Total function calls
2. **Average**: Mean time per call (most important)
3. **Min**: Best-case performance (least noise)
4. **Max**: Worst-case performance (most noise)
5. **Variance**: Spread of measurements (consistency)
6. **CV (Coefficient of Variation)**: Relative consistency

**Speedup calculation**:
```
Speedup = Time_Baseline / Time_Optimized
```

Example: If baseline is 389ns and optimized is 245ns:
```
Speedup = 389 / 245 = 1.59x faster
```

## Interpreting Results

### Understanding Speedup Metrics

**What is speedup?**
- Ratio of baseline time to optimized time
- > 1.0 means optimized is faster
- < 1.0 means "optimized" is slower (oops!)

**Is a speedup significant?**
- < 1.1x (10%): Marginal, might be noise
- 1.1-1.5x (10-50%): Moderate improvement
- 1.5-3x (50-200%): Significant improvement
- \> 3x (200%+): Major improvement

**When to optimize**:
- Hot path (called frequently): Even 10% matters
- Cold path (rare): Only optimize if > 2x improvement
- Critical path (latency-sensitive): Any improvement helps

### Understanding Variance

**Low variance (CV < 5%)**:
```
Average: 245 ns
Min:     240 ns
Max:     250 ns
Variance: 16 ns²
CV:      1.63%
```
- Consistent performance
- Results are reliable
- CPU is stable

**High variance (CV > 10%)**:
```
Average: 245 ns
Min:     180 ns
Max:     450 ns
Variance: 3600 ns²
CV:      24.5%
```
- Inconsistent performance
- Possible causes:
  - System noise (background processes)
  - Thermal throttling
  - Cache conflicts
  - Context switches
- Solution: Run more iterations or close background apps

### Cache Effects

**Cache hit example**:
```
Size    100: 85 ns (0.85 ns/elem)
Size  1,000: 890 ns (0.89 ns/elem)
Size 10,000: 9,100 ns (0.91 ns/elem)  <- Linear scaling
```
- Performance scales linearly with size
- Data fits in cache
- Excellent locality

**Cache miss example**:
```
Size    100: 85 ns (0.85 ns/elem)
Size  1,000: 1,200 ns (1.20 ns/elem)
Size 10,000: 28,000 ns (2.80 ns/elem)  <- Superlinear!
```
- Performance degrades with size
- Data exceeds cache capacity
- Poor locality or eviction

### What to Optimize First

**Profile before optimizing!**

Priority by impact:
1. **Algorithm complexity**: O(n²) → O(n log n) can be 100x faster
2. **Hot loops**: Optimize inner loops first
3. **Memory allocation**: Reduce allocations in hot paths
4. **Cache locality**: Improve data access patterns
5. **Micro-optimizations**: Loop unrolling, SIMD (last resort)

**Example priority**:
```
function processAllData():
    for item in million_items:        <- #1: Optimize this (hot loop)
        data = allocate(1024)          <- #2: Reuse allocation
        result = bubbleSort(data)      <- #3: Use quicksort!
        x = x + 1                      <- #4: Don't bother
```

### Comparing Across Runs

**Same machine, same conditions**:
- Results should be reproducible (±5%)
- Compare directly

**Different machines**:
- Don't compare absolute times
- Compare speedup ratios instead
- Algorithm complexity should be consistent

**Before/after optimization**:
- Run both versions multiple times
- Report mean and confidence interval
- Ensure difference > measurement variance

## Compatibility Notes

### Zig Version

**Requires**: Zig 0.15.0 or later

**Key features used**:
- `std.time.Timer` (stable API)
- `std.mem.doNotOptimizeAway` (introduced in 0.11.0)
- `std.Random.DefaultPrng` (stable API)
- Build system with `b.path()` (0.15.0+)

**If using older Zig**:
- 0.13-0.14: Change `b.path()` to `.{ .path = "..." }`
- 0.11-0.12: Should work with minor tweaks
- < 0.11: Missing `doNotOptimizeAway`, use inline asm workarounds

### Platform Differences

**Linux/macOS**:
- High-precision timer: `clock_gettime(CLOCK_MONOTONIC)`
- Resolution: ~1-10 nanoseconds
- Very accurate

**Windows**:
- High-precision timer: `QueryPerformanceCounter`
- Resolution: ~100 nanoseconds
- Good accuracy

**WASM**:
- Limited timer support
- May not have high-precision timing
- Benchmarks may be less accurate

### CPU Differences

**Modern x86_64** (Intel/AMD):
- Out-of-order execution
- Branch prediction
- Large caches
- Optimal for these benchmarks

**ARM** (Apple Silicon, Raspberry Pi):
- Different instruction costs
- Different cache hierarchies
- May see different speedups

**Older CPUs**:
- Less sophisticated optimization
- Smaller caches
- May see smaller speedups from optimization

### Build System

**Zig 0.15.0+**:
```zig
const exe = b.addExecutable(.{
    .name = "benchmarking",
    .root_source_file = b.path("src/main.zig"),  // New API
    .target = target,
    .optimize = optimize,
});
```

**Zig 0.13-0.14**:
```zig
const exe = b.addExecutable(.{
    .name = "benchmarking",
    .root_source_file = .{ .path = "src/main.zig" },  // Old API
    .target = target,
    .optimize = optimize,
});
```

## Further Reading

### Zig Documentation

- [std.time.Timer](https://ziglang.org/documentation/master/std/#std.time.Timer)
- [std.mem.doNotOptimizeAway](https://ziglang.org/documentation/master/std/#std.mem.doNotOptimizeAway)
- [Build Modes](https://ziglang.org/documentation/master/#Build-Mode)

### Benchmarking Theory

- **"Systems Performance" by Brendan Gregg**: Comprehensive guide to performance analysis
- **"Computer Architecture: A Quantitative Approach" by Hennessy & Patterson**: Understanding CPU performance
- **"What Every Programmer Should Know About Memory" by Ulrich Drepper**: Cache effects and memory performance

### Related Topics

- **Profiling**: Use `perf` (Linux), `Instruments` (macOS), or `VTune` (Intel) for detailed profiling
- **Compiler Explorer**: See assembly output at [godbolt.org](https://godbolt.org)
- **Algorithm Analysis**: Study big-O notation and complexity analysis
- **CPU Architecture**: Learn about pipelining, caching, and branch prediction

### Online Resources

- [Zig Forums](https://ziggit.dev/): Community discussions
- [Zig Discord](https://discord.gg/zig): Real-time help
- [GitHub Issues](https://github.com/ziglang/zig): Report bugs or feature requests

---

## Summary

This example demonstrates:

1. **Benchmark Framework**: Reusable, statistically-sound benchmarking
2. **Algorithm Comparison**: Naive vs optimized implementations
3. **Prevention Techniques**: Using `doNotOptimizeAway` correctly
4. **Statistical Analysis**: Multiple samples, variance, confidence
5. **Real-world Patterns**: Sorting, hashing, string processing
6. **Performance Insights**: Cache effects, scaling behavior
7. **Best Practices**: Warm-up, iterations, build modes

**Key takeaways**:
- Always use release modes for benchmarking
- Prevent compiler optimization with `doNotOptimizeAway`
- Include warm-up iterations
- Collect multiple samples for statistics
- Compare fairly (same data, same conditions)
- Focus on relative performance (speedup ratios)
- Understand your CPU architecture

**Next steps**:
- Adapt the benchmark framework for your needs
- Profile your code to find hotspots
- Apply optimization techniques carefully
- Measure before and after each optimization
- Remember: "Premature optimization is the root of all evil" (but measurement isn't!)

Happy benchmarking!
