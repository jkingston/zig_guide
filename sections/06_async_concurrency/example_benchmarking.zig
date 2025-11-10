const std = @import("std");

// Demonstrate performance measurement and benchmarking techniques

// Example algorithms to benchmark
fn fibonacci_recursive(n: u32) u64 {
    if (n <= 1) return n;
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2);
}

fn fibonacci_iterative(n: u32) u64 {
    if (n <= 1) return n;
    var a: u64 = 0;
    var b: u64 = 1;
    for (0..n - 1) |_| {
        const temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

// Sorting algorithms for comparison
fn bubbleSort(slice: []u32) void {
    if (slice.len < 2) return;
    var i: usize = 0;
    while (i < slice.len - 1) : (i += 1) {
        var j: usize = 0;
        while (j < slice.len - 1 - i) : (j += 1) {
            if (slice[j] > slice[j + 1]) {
                const temp = slice[j];
                slice[j] = slice[j + 1];
                slice[j + 1] = temp;
            }
        }
    }
}

fn quickSort(slice: []u32) void {
    if (slice.len < 2) return;
    const pivot = slice[slice.len / 2];
    var i: usize = 0;
    var j: usize = slice.len - 1;

    while (true) {
        while (slice[i] < pivot) i += 1;
        while (slice[j] > pivot) j -= 1;
        if (i >= j) break;

        const temp = slice[i];
        slice[i] = slice[j];
        slice[j] = temp;

        i += 1;
        if (j > 0) j -= 1;
    }

    if (j > 0) quickSort(slice[0 .. j + 1]);
    if (i < slice.len) quickSort(slice[i..]);
}

// Benchmark result structure
const BenchmarkResult = struct {
    iterations: usize,
    total_ns: u64,
    avg_ns: u64,
    min_ns: u64,
    max_ns: u64,

    fn format(
        self: BenchmarkResult,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d} iterations, avg: {d}ns, min: {d}ns, max: {d}ns", .{
            self.iterations,
            self.avg_ns,
            self.min_ns,
            self.max_ns,
        });
    }
};

// Simple benchmark runner
fn benchmark(
    comptime func: anytype,
    args: anytype,
    iterations: usize,
) !BenchmarkResult {
    var timer = try std.time.Timer.start();
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (0..iterations) |_| {
        timer.reset();
        _ = @call(.auto, func, args);
        const elapsed = timer.read();

        total_ns += elapsed;
        min_ns = @min(min_ns, elapsed);
        max_ns = @max(max_ns, elapsed);

        // Prevent compiler from optimizing away the call
        std.mem.doNotOptimizeAway(&args);
    }

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = total_ns / iterations,
        .min_ns = min_ns,
        .max_ns = max_ns,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Benchmarking Examples ===\n\n", .{});

    // Example 1: Basic Timer usage
    {
        std.debug.print("Example 1: Basic Timer usage\n", .{});

        var timer = try std.time.Timer.start();

        // Do some work
        var sum: u64 = 0;
        for (0..1_000_000) |i| {
            sum += i;
        }
        std.mem.doNotOptimizeAway(&sum);

        const elapsed = timer.read();
        std.debug.print("Computed sum in {d}ns ({d}µs)\n\n", .{ elapsed, elapsed / std.time.ns_per_us });
    }

    // Example 2: Timer lap() for multiple measurements
    {
        std.debug.print("Example 2: Using lap() for multiple measurements\n", .{});

        var timer = try std.time.Timer.start();

        // Phase 1
        std.Thread.sleep(10 * std.time.ns_per_ms);
        const phase1 = timer.lap();

        // Phase 2
        std.Thread.sleep(20 * std.time.ns_per_ms);
        const phase2 = timer.lap();

        // Phase 3
        std.Thread.sleep(15 * std.time.ns_per_ms);
        const phase3 = timer.lap();

        std.debug.print("Phase 1: {d}ms\n", .{phase1 / std.time.ns_per_ms});
        std.debug.print("Phase 2: {d}ms\n", .{phase2 / std.time.ns_per_ms});
        std.debug.print("Phase 3: {d}ms\n\n", .{phase3 / std.time.ns_per_ms});
    }

    // Example 3: Comparing algorithms
    {
        std.debug.print("Example 3: Fibonacci algorithms comparison\n", .{});

        const n: u32 = 30;

        // Benchmark recursive version
        const recursive_result = try benchmark(fibonacci_recursive, .{n}, 10);
        std.debug.print("Recursive: {}\n", .{recursive_result});

        // Benchmark iterative version
        const iterative_result = try benchmark(fibonacci_iterative, .{n}, 10);
        std.debug.print("Iterative: {}\n", .{iterative_result});

        const speedup = @as(f64, @floatFromInt(recursive_result.avg_ns)) /
            @as(f64, @floatFromInt(iterative_result.avg_ns));
        std.debug.print("Speedup: {d:.2}x faster\n\n", .{speedup});
    }

    // Example 4: Sorting algorithms with varying input sizes
    {
        std.debug.print("Example 4: Sorting algorithm scalability\n", .{});

        const sizes = [_]usize{ 100, 500, 1000 };

        for (sizes) |size| {
            std.debug.print("\nArray size: {d}\n", .{size});

            // Bubble sort
            {
                const data = try allocator.alloc(u32, size);
                defer allocator.free(data);

                var timer = try std.time.Timer.start();

                // Fill with random data
                var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
                const random = prng.random();
                for (data) |*item| {
                    item.* = random.int(u32);
                }

                // Exclude setup time
                timer.reset();
                bubbleSort(data);
                const bubble_time = timer.read();

                std.debug.print("  Bubble sort: {d}µs\n", .{bubble_time / std.time.ns_per_us});
            }

            // Quick sort
            {
                const data = try allocator.alloc(u32, size);
                defer allocator.free(data);

                var timer = try std.time.Timer.start();

                // Fill with same random seed for fair comparison
                var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
                const random = prng.random();
                for (data) |*item| {
                    item.* = random.int(u32);
                }

                timer.reset();
                quickSort(data);
                const quick_time = timer.read();

                std.debug.print("  Quick sort:  {d}µs\n", .{quick_time / std.time.ns_per_us});
            }
        }
        std.debug.print("\n", .{});
    }

    // Example 5: Measuring throughput
    {
        std.debug.print("Example 5: Throughput measurement\n", .{});

        const data_size = 100 * 1024 * 1024; // 100 MiB
        const buffer = try allocator.alloc(u8, data_size);
        defer allocator.free(buffer);

        // Fill buffer
        @memset(buffer, 42);

        var timer = try std.time.Timer.start();

        // Simulate processing
        var checksum: u64 = 0;
        for (buffer) |byte| {
            checksum +%= byte;
        }
        std.mem.doNotOptimizeAway(&checksum);

        const elapsed = timer.read();
        const elapsed_s = @as(f64, @floatFromInt(elapsed)) / @as(f64, std.time.ns_per_s);
        const throughput_mb = @as(f64, data_size) / (1024 * 1024) / elapsed_s;

        std.debug.print("Processed {d} MiB in {d}ms\n", .{
            data_size / (1024 * 1024),
            elapsed / std.time.ns_per_ms,
        });
        std.debug.print("Throughput: {d:.2} MiB/s\n\n", .{throughput_mb});
    }

    // Example 6: Warm-up iterations
    {
        std.debug.print("Example 6: Importance of warm-up\n", .{});

        const Worker = struct {
            fn expensive_operation(n: u32) u64 {
                var result: u64 = 1;
                for (0..n) |i| {
                    result +%= i * i;
                }
                return result;
            }
        };

        const n: u32 = 10_000;

        // Cold run (no warm-up)
        var timer = try std.time.Timer.start();
        var result = Worker.expensive_operation(n);
        std.mem.doNotOptimizeAway(&result);
        const cold_time = timer.read();

        // Warm up CPU cache
        for (0..100) |_| {
            result = Worker.expensive_operation(n);
            std.mem.doNotOptimizeAway(&result);
        }

        // Hot run (after warm-up)
        timer.reset();
        result = Worker.expensive_operation(n);
        std.mem.doNotOptimizeAway(&result);
        const hot_time = timer.read();

        std.debug.print("Cold run: {d}ns\n", .{cold_time});
        std.debug.print("Hot run:  {d}ns\n", .{hot_time});
        std.debug.print("Difference: {d:.1}%\n\n", .{
            (@as(f64, @floatFromInt(cold_time)) / @as(f64, @floatFromInt(hot_time)) - 1.0) * 100.0,
        });
    }

    // Example 7: Statistical analysis
    {
        std.debug.print("Example 7: Statistical analysis of timings\n", .{});

        const iterations = 1000;
        const measurements = try allocator.alloc(u64, iterations);
        defer allocator.free(measurements);

        // Collect measurements
        for (measurements) |*measurement| {
            var timer = try std.time.Timer.start();
            const result = fibonacci_iterative(20);
            std.mem.doNotOptimizeAway(&result);
            measurement.* = timer.read();
        }

        // Calculate statistics
        var sum: u64 = 0;
        var min: u64 = std.math.maxInt(u64);
        var max: u64 = 0;

        for (measurements) |m| {
            sum += m;
            min = @min(min, m);
            max = @max(max, m);
        }

        const mean = sum / iterations;

        // Calculate standard deviation
        var variance_sum: u128 = 0;
        for (measurements) |m| {
            const diff = if (m > mean) m - mean else mean - m;
            variance_sum += @as(u128, diff) * @as(u128, diff);
        }
        const variance = variance_sum / iterations;
        const std_dev = std.math.sqrt(@as(f64, @floatFromInt(variance)));

        // Calculate median
        std.mem.sort(u64, measurements, {}, std.sort.asc(u64));
        const median = measurements[iterations / 2];

        std.debug.print("Mean:   {d}ns\n", .{mean});
        std.debug.print("Median: {d}ns\n", .{median});
        std.debug.print("Std dev: {d:.2}ns\n", .{std_dev});
        std.debug.print("Min:    {d}ns\n", .{min});
        std.debug.print("Max:    {d}ns\n\n", .{max});
    }

    std.debug.print("=== All benchmarking examples completed ===\n", .{});
}
