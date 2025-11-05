const std = @import("std");

/// Result of a benchmark run containing timing statistics
pub const BenchmarkResult = struct {
    iterations: u64,
    total_ns: u64,
    avg_ns: u64,
    min_ns: u64,
    max_ns: u64,
    variance_ns: u64,

    /// Calculate speedup relative to another benchmark result
    pub fn speedupVs(self: BenchmarkResult, other: BenchmarkResult) f64 {
        return @as(f64, @floatFromInt(other.avg_ns)) / @as(f64, @floatFromInt(self.avg_ns));
    }

    /// Format result as a human-readable string
    pub fn format(
        self: BenchmarkResult,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d} iterations, avg: {d} ns, min: {d} ns, max: {d} ns, variance: {d} ns²", .{
            self.iterations,
            self.avg_ns,
            self.min_ns,
            self.max_ns,
            self.variance_ns,
        });
    }
};

/// Benchmark a function with multiple iterations
/// Returns statistical results (average, min, max, variance)
///
/// Critical: This function uses doNotOptimizeAway to prevent the compiler
/// from optimizing away the function call. Without this, the compiler might
/// eliminate the entire benchmark as dead code.
///
/// The function pointer approach allows us to benchmark any function that
/// returns a value. We accumulate results to force the compiler to keep
/// the function calls.
pub fn benchmark(
    comptime Func: type,
    func: Func,
    iterations: u64,
) !BenchmarkResult {
    // Warm-up phase: This is critical for accurate benchmarking
    // It stabilizes:
    // - CPU frequency (modern CPUs scale frequency based on load)
    // - Cache state (loads hot paths into L1/L2 cache)
    // - Branch predictor state
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    // Collect multiple samples for statistical analysis
    // Running the benchmark multiple times helps identify:
    // - Outliers (context switches, interrupts)
    // - Variance (how consistent the performance is)
    // - Confidence in the average
    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        // Run iterations for this sample
        // We use a loop counter to prevent the compiler from unrolling
        // and optimizing away the loop
        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func();
            // Critical: doNotOptimizeAway prevents:
            // 1. Dead code elimination (compiler removing unused results)
            // 2. Constant folding (computing results at compile time)
            // 3. Loop elimination (removing the entire loop)
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    // Calculate statistics from samples
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    // Calculate variance: sum of squared differences from mean
    // This tells us how consistent the performance is
    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    // Calculate average time per iteration
    const avg_per_iter = avg_ns / iterations_per_sample;
    const min_per_iter = min_ns / iterations_per_sample;
    const max_per_iter = max_ns / iterations_per_sample;

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_per_iter,
        .min_ns = min_per_iter,
        .max_ns = max_per_iter,
        .variance_ns = variance_ns / (iterations_per_sample * iterations_per_sample),
    };
}

/// Benchmark a function that takes an argument
/// This is useful for benchmarking with different input sizes or types
pub fn benchmarkWithArg(
    comptime Func: type,
    func: Func,
    arg: anytype,
    iterations: u64,
) !BenchmarkResult {
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func(arg);
        std.mem.doNotOptimizeAway(&result);
    }

    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func(arg);
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    const avg_per_iter = avg_ns / iterations_per_sample;
    const min_per_iter = min_ns / iterations_per_sample;
    const max_per_iter = max_ns / iterations_per_sample;

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_per_iter,
        .min_ns = min_per_iter,
        .max_ns = max_per_iter,
        .variance_ns = variance_ns / (iterations_per_sample * iterations_per_sample),
    };
}

/// Print a formatted benchmark result
pub fn printBenchmarkResult(writer: anytype, name: []const u8, result: BenchmarkResult) !void {
    try writer.print("  {s}:\n", .{name});
    try writer.print("    Iterations: {d}\n", .{result.iterations});
    try writer.print("    Average:    {d} ns", .{result.avg_ns});

    // Add human-readable time units for larger values
    if (result.avg_ns > 1_000_000) {
        const ms = @as(f64, @floatFromInt(result.avg_ns)) / 1_000_000.0;
        try writer.print(" ({d:.3} ms)", .{ms});
    } else if (result.avg_ns > 1_000) {
        const us = @as(f64, @floatFromInt(result.avg_ns)) / 1_000.0;
        try writer.print(" ({d:.3} µs)", .{us});
    }
    try writer.print("\n", .{});

    try writer.print("    Min:        {d} ns\n", .{result.min_ns});
    try writer.print("    Max:        {d} ns\n", .{result.max_ns});
    try writer.print("    Variance:   {d} ns²\n", .{result.variance_ns});

    // Calculate coefficient of variation (stddev / mean)
    // This is useful for understanding relative consistency
    const stddev = std.math.sqrt(@as(f64, @floatFromInt(result.variance_ns)));
    const cv = (stddev / @as(f64, @floatFromInt(result.avg_ns))) * 100.0;
    try writer.print("    CV:         {d:.2}%\n", .{cv});
}

/// Compare two benchmark results and print comparison
pub fn compareBenchmarks(
    writer: anytype,
    name1: []const u8,
    result1: BenchmarkResult,
    name2: []const u8,
    result2: BenchmarkResult,
) !void {
    try writer.print("\nComparison:\n", .{});
    try printBenchmarkResult(writer, name1, result1);
    try writer.print("\n", .{});
    try printBenchmarkResult(writer, name2, result2);

    try writer.print("\n  Result:\n", .{});

    const speedup = result1.speedupVs(result2);
    if (speedup > 1.0) {
        try writer.print("    {s} is {d:.2}x faster than {s}\n", .{
            name1, speedup, name2
        });
    } else {
        try writer.print("    {s} is {d:.2}x slower than {s}\n", .{
            name1, 1.0 / speedup, name2
        });
    }

    // Calculate percentage difference
    const diff_ns = if (result1.avg_ns > result2.avg_ns)
        result1.avg_ns - result2.avg_ns
    else
        result2.avg_ns - result1.avg_ns;
    const percent = (@as(f64, @floatFromInt(diff_ns)) / @as(f64, @floatFromInt(result2.avg_ns))) * 100.0;
    try writer.print("    Difference: {d} ns ({d:.1}%)\n", .{diff_ns, percent});
}

/// Helper to benchmark a slice operation
/// This is useful for benchmarking operations on data structures
pub fn benchmarkSliceOp(
    comptime T: type,
    comptime Func: type,
    func: Func,
    data: []const T,
    iterations: u64,
) !BenchmarkResult {
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func(data);
        std.mem.doNotOptimizeAway(&result);
    }

    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func(data);
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    const avg_per_iter = avg_ns / iterations_per_sample;
    const min_per_iter = min_ns / iterations_per_sample;
    const max_per_iter = max_ns / iterations_per_sample;

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_per_iter,
        .min_ns = min_per_iter,
        .max_ns = max_per_iter,
        .variance_ns = variance_ns / (iterations_per_sample * iterations_per_sample),
    };
}

/// Time a single operation (useful for slow operations)
/// Returns the elapsed time in nanoseconds
pub fn timeOperation(comptime Func: type, func: Func) !u64 {
    var timer = try std.time.Timer.start();
    const result = func();
    std.mem.doNotOptimizeAway(&result);
    return timer.read();
}

/// Time a single operation with an argument
pub fn timeOperationWithArg(comptime Func: type, func: Func, arg: anytype) !u64 {
    var timer = try std.time.Timer.start();
    const result = func(arg);
    std.mem.doNotOptimizeAway(&result);
    return timer.read();
}
