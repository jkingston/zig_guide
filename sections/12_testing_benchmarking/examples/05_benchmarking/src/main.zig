const std = @import("std");
const benchmark = @import("benchmark.zig");
const algorithms = @import("algorithms.zig");
const sorting = @import("sorting.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.debug;

    try stdout.print("\n", .{});
    try stdout.print("=" ** 80, .{});
    try stdout.print("\n  Zig Benchmarking Patterns Demo\n", .{});
    try stdout.print("=" ** 80, .{});
    try stdout.print("\n\n", .{});

    // Run all benchmarks
    try benchmarkSumAlgorithms(allocator, stdout);
    try benchmarkStringSearch(allocator, stdout);
    try benchmarkFibonacci(stdout);
    try benchmarkHashFunctions(allocator, stdout);
    try benchmarkStringBuilding(allocator, stdout);
    try benchmarkSortingAlgorithms(allocator, stdout);
    try benchmarkDataSizes(allocator, stdout);

    try stdout.print("\n", .{});
    try stdout.print("=" ** 80, .{});
    try stdout.print("\n  Benchmarking Complete\n", .{});
    try stdout.print("=" ** 80, .{});
    try stdout.print("\n\n", .{});
}

// ============================================================================
// Benchmark 1: Sum Algorithms
// ============================================================================

fn benchmarkSumAlgorithms(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 1: Sum Algorithms (Naive vs Optimized vs SIMD-style)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    // Generate test data
    const size = 10_000;
    const data = try allocator.alloc(i64, size);
    defer allocator.free(data);

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    for (data) |*value| {
        value.* = random.int(i64) % 1000;
    }

    // Create wrapper functions for benchmarking
    const SumNaiveWrapper = struct {
        fn call(d: []const i64) i64 {
            return algorithms.sumNaive(d);
        }
    };

    const SumOptimizedWrapper = struct {
        fn call(d: []const i64) i64 {
            return algorithms.sumOptimized(d);
        }
    };

    const SumSIMDWrapper = struct {
        fn call(d: []const i64) i64 {
            return algorithms.sumSIMD(d);
        }
    };

    // Run benchmarks
    const iterations = 10_000;
    const result_naive = try benchmark.benchmarkSliceOp(i64, *const fn ([]const i64) i64, SumNaiveWrapper.call, data, iterations);
    const result_optimized = try benchmark.benchmarkSliceOp(i64, *const fn ([]const i64) i64, SumOptimizedWrapper.call, data, iterations);
    const result_simd = try benchmark.benchmarkSliceOp(i64, *const fn ([]const i64) i64, SumSIMDWrapper.call, data, iterations);

    // Print results
    try benchmark.compareBenchmarks(writer, "Optimized (unrolled)", result_optimized, "Naive", result_naive);
    try writer.print("\n", .{});
    try benchmark.compareBenchmarks(writer, "SIMD-style", result_simd, "Naive", result_naive);

    try writer.print("\n\n", .{});
}

// ============================================================================
// Benchmark 2: String Search
// ============================================================================

fn benchmarkStringSearch(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 2: String Search (Naive vs Optimized)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    // Generate test data - a long string with pattern near the end
    const haystack_size = 10_000;
    const haystack = try allocator.alloc(u8, haystack_size);
    defer allocator.free(haystack);

    // Fill with random data
    var prng = std.Random.DefaultPrng.init(67890);
    const random = prng.random();
    for (haystack) |*byte| {
        byte.* = 'a' + random.uintLessThan(u8, 26);
    }

    // Place needle near the end
    const needle = "zyxwvu";
    @memcpy(haystack[haystack_size - 100 ..][0..needle.len], needle);

    // Wrapper for naive search
    const SearchNaiveWrapper = struct {
        const h = haystack;
        const n = needle;

        fn call() ?usize {
            return algorithms.searchNaive(h, n);
        }
    };

    // Wrapper for optimized search
    const SearchOptimizedWrapper = struct {
        const h = haystack;
        const n = needle;

        fn call() ?usize {
            return algorithms.searchOptimized(h, n);
        }
    };

    const iterations = 10_000;
    const result_naive = try benchmark.benchmark(*const fn () ?usize, SearchNaiveWrapper.call, iterations);
    const result_optimized = try benchmark.benchmark(*const fn () ?usize, SearchOptimizedWrapper.call, iterations);

    try benchmark.compareBenchmarks(writer, "Optimized", result_optimized, "Naive", result_naive);

    try writer.print("\n\n", .{});
}

// ============================================================================
// Benchmark 3: Fibonacci
// ============================================================================

fn benchmarkFibonacci(writer: anytype) !void {
    try writer.print("Benchmark 3: Fibonacci (Recursive vs Iterative vs Memoized)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    // For recursive, use smaller N (it's exponential!)
    const n_recursive: u32 = 20;
    const iterations_recursive = 1000;

    const FibRecursiveWrapper = struct {
        fn call() u64 {
            return algorithms.fibRecursive(n_recursive);
        }
    };

    const FibIterativeWrapper = struct {
        fn call() u64 {
            return algorithms.fibIterative(n_recursive);
        }
    };

    const result_recursive = try benchmark.benchmark(*const fn () u64, FibRecursiveWrapper.call, iterations_recursive);
    const result_iterative = try benchmark.benchmark(*const fn () u64, FibIterativeWrapper.call, iterations_recursive);

    try benchmark.compareBenchmarks(writer, "Iterative", result_iterative, "Recursive", result_recursive);

    // Now test memoized with larger N
    try writer.print("\n  Testing memoized with larger N (30):\n", .{});

    const n_large: u32 = 30;
    const iterations_large = 10_000;

    var fib_memo = algorithms.FibMemoized(50).init();

    const FibMemoizedWrapper = struct {
        var memo: *algorithms.FibMemoized(50) = undefined;

        fn call() u64 {
            return memo.fib(n_large);
        }
    };
    FibMemoizedWrapper.memo = &fib_memo;

    const FibIterativeLargeWrapper = struct {
        fn call() u64 {
            return algorithms.fibIterative(n_large);
        }
    };

    const result_memoized = try benchmark.benchmark(*const fn () u64, FibMemoizedWrapper.call, iterations_large);
    const result_iterative_large = try benchmark.benchmark(*const fn () u64, FibIterativeLargeWrapper.call, iterations_large);

    try benchmark.compareBenchmarks(writer, "Memoized", result_memoized, "Iterative", result_iterative_large);

    try writer.print("\n\n", .{});
}

// ============================================================================
// Benchmark 4: Hash Functions
// ============================================================================

fn benchmarkHashFunctions(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 4: Hash Functions (Simple vs FNV1a vs Optimized)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    // Generate test data
    const size = 1024;
    const data = try allocator.alloc(u8, size);
    defer allocator.free(data);

    var prng = std.Random.DefaultPrng.init(11111);
    const random = prng.random();
    for (data) |*byte| {
        byte.* = random.int(u8);
    }

    const HashSimpleWrapper = struct {
        fn call(d: []const u8) u64 {
            return algorithms.hashSimple(d);
        }
    };

    const HashFNV1aWrapper = struct {
        fn call(d: []const u8) u64 {
            return algorithms.hashFNV1a(d);
        }
    };

    const HashOptimizedWrapper = struct {
        fn call(d: []const u8) u64 {
            return algorithms.hashOptimized(d);
        }
    };

    const iterations = 100_000;
    const result_simple = try benchmark.benchmarkSliceOp(u8, *const fn ([]const u8) u64, HashSimpleWrapper.call, data, iterations);
    const result_fnv1a = try benchmark.benchmarkSliceOp(u8, *const fn ([]const u8) u64, HashFNV1aWrapper.call, data, iterations);
    const result_optimized = try benchmark.benchmarkSliceOp(u8, *const fn ([]const u8) u64, HashOptimizedWrapper.call, data, iterations);

    try benchmark.compareBenchmarks(writer, "FNV1a", result_fnv1a, "Simple", result_simple);
    try writer.print("\n", .{});
    try benchmark.compareBenchmarks(writer, "Optimized", result_optimized, "Simple", result_simple);

    try writer.print("\n\n", .{});
}

// ============================================================================
// Benchmark 5: String Building
// ============================================================================

fn benchmarkStringBuilding(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 5: String Building (Concatenation vs ArrayList)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    const count = 100;

    const ConcatWrapper = struct {
        var alloc: std.mem.Allocator = undefined;

        fn call() ![]u8 {
            return algorithms.buildStringConcat(alloc, count);
        }
    };
    ConcatWrapper.alloc = allocator;

    const ArrayListWrapper = struct {
        var alloc: std.mem.Allocator = undefined;

        fn call() ![]u8 {
            return algorithms.buildStringArrayList(alloc, count);
        }
    };
    ArrayListWrapper.alloc = allocator;

    // Time each approach
    var timer = try std.time.Timer.start();

    // Concat approach
    var concat_total: u64 = 0;
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        timer.reset();
        const result = try ConcatWrapper.call();
        concat_total += timer.read();
        allocator.free(result);
    }
    const concat_avg = concat_total / 100;

    // ArrayList approach
    var arraylist_total: u64 = 0;
    i = 0;
    while (i < 100) : (i += 1) {
        timer.reset();
        const result = try ArrayListWrapper.call();
        arraylist_total += timer.read();
        allocator.free(result);
    }
    const arraylist_avg = arraylist_total / 100;

    try writer.print("  Concatenation:\n", .{});
    try writer.print("    Average: {d} ns ({d:.3} µs)\n", .{ concat_avg, @as(f64, @floatFromInt(concat_avg)) / 1000.0 });

    try writer.print("\n  ArrayList:\n", .{});
    try writer.print("    Average: {d} ns ({d:.3} µs)\n", .{ arraylist_avg, @as(f64, @floatFromInt(arraylist_avg)) / 1000.0 });

    const speedup = @as(f64, @floatFromInt(concat_avg)) / @as(f64, @floatFromInt(arraylist_avg));
    try writer.print("\n  Result:\n", .{});
    try writer.print("    ArrayList is {d:.2}x faster than Concatenation\n", .{speedup});

    try writer.print("\n\n", .{});
}

// ============================================================================
// Benchmark 6: Sorting Algorithms
// ============================================================================

fn benchmarkSortingAlgorithms(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 6: Sorting Algorithms (Different Algorithms & Data)\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    const size = 1000;
    const seed: u64 = 42;

    // Test with random data
    try writer.print("  Random Data (size={d}):\n", .{size});
    const random_data = try sorting.generateRandomData(allocator, size, seed);
    defer allocator.free(random_data);

    const bubble_time = try sorting.benchmarkSort(allocator, sorting.bubbleSort, random_data);
    const insertion_time = try sorting.benchmarkSort(allocator, sorting.insertionSort, random_data);
    const insertion_binary_time = try sorting.benchmarkSort(allocator, sorting.insertionSortBinary, random_data);
    const quick_time = try sorting.benchmarkSort(allocator, sorting.quickSort, random_data);
    const merge_time = try sorting.benchmarkMergeSort(allocator, random_data);
    const heap_time = try sorting.benchmarkSort(allocator, sorting.heapSort, random_data);

    try printSortingResults(writer, bubble_time, insertion_time, insertion_binary_time, quick_time, merge_time, heap_time);

    // Test with sorted data
    try writer.print("\n  Sorted Data (size={d}):\n", .{size});
    const sorted_data = try sorting.generateSortedData(allocator, size);
    defer allocator.free(sorted_data);

    const bubble_sorted = try sorting.benchmarkSort(allocator, sorting.bubbleSort, sorted_data);
    const insertion_sorted = try sorting.benchmarkSort(allocator, sorting.insertionSort, sorted_data);
    const insertion_binary_sorted = try sorting.benchmarkSort(allocator, sorting.insertionSortBinary, sorted_data);
    const quick_sorted = try sorting.benchmarkSort(allocator, sorting.quickSort, sorted_data);
    const merge_sorted = try sorting.benchmarkMergeSort(allocator, sorted_data);
    const heap_sorted = try sorting.benchmarkSort(allocator, sorting.heapSort, sorted_data);

    try printSortingResults(writer, bubble_sorted, insertion_sorted, insertion_binary_sorted, quick_sorted, merge_sorted, heap_sorted);

    // Test with reverse-sorted data
    try writer.print("\n  Reverse-Sorted Data (size={d}):\n", .{size});
    const reverse_data = try sorting.generateReverseSortedData(allocator, size);
    defer allocator.free(reverse_data);

    const bubble_reverse = try sorting.benchmarkSort(allocator, sorting.bubbleSort, reverse_data);
    const insertion_reverse = try sorting.benchmarkSort(allocator, sorting.insertionSort, reverse_data);
    const insertion_binary_reverse = try sorting.benchmarkSort(allocator, sorting.insertionSortBinary, reverse_data);
    const quick_reverse = try sorting.benchmarkSort(allocator, sorting.quickSort, reverse_data);
    const merge_reverse = try sorting.benchmarkMergeSort(allocator, reverse_data);
    const heap_reverse = try sorting.benchmarkSort(allocator, sorting.heapSort, reverse_data);

    try printSortingResults(writer, bubble_reverse, insertion_reverse, insertion_binary_reverse, quick_reverse, merge_reverse, heap_reverse);

    try writer.print("\n\n", .{});
}

fn printSortingResults(
    writer: anytype,
    bubble: u64,
    insertion: u64,
    insertion_binary: u64,
    quick: u64,
    merge: u64,
    heap: u64,
) !void {
    const formatNs = struct {
        fn format(ns: u64) [100]u8 {
            var buf: [100]u8 = undefined;
            if (ns > 1_000_000) {
                const ms = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
                _ = std.fmt.bufPrint(&buf, "{d:.3} ms", .{ms}) catch unreachable;
            } else if (ns > 1_000) {
                const us = @as(f64, @floatFromInt(ns)) / 1_000.0;
                _ = std.fmt.bufPrint(&buf, "{d:.3} µs", .{us}) catch unreachable;
            } else {
                _ = std.fmt.bufPrint(&buf, "{d} ns", .{ns}) catch unreachable;
            }
            return buf;
        }
    }.format;

    try writer.print("    Bubble Sort:           {s}\n", .{std.mem.sliceTo(&formatNs(bubble), 0)});
    try writer.print("    Insertion Sort:        {s}\n", .{std.mem.sliceTo(&formatNs(insertion), 0)});
    try writer.print("    Insertion Binary:      {s}\n", .{std.mem.sliceTo(&formatNs(insertion_binary), 0)});
    try writer.print("    Quick Sort:            {s}\n", .{std.mem.sliceTo(&formatNs(quick), 0)});
    try writer.print("    Merge Sort:            {s}\n", .{std.mem.sliceTo(&formatNs(merge), 0)});
    try writer.print("    Heap Sort:             {s}\n", .{std.mem.sliceTo(&formatNs(heap), 0)});

    // Show speedup relative to bubble sort
    const bubble_f = @as(f64, @floatFromInt(bubble));
    try writer.print("\n    Speedup vs Bubble Sort:\n", .{});
    try writer.print("      Insertion Sort:      {d:.2}x\n", .{bubble_f / @as(f64, @floatFromInt(insertion))});
    try writer.print("      Insertion Binary:    {d:.2}x\n", .{bubble_f / @as(f64, @floatFromInt(insertion_binary))});
    try writer.print("      Quick Sort:          {d:.2}x\n", .{bubble_f / @as(f64, @floatFromInt(quick))});
    try writer.print("      Merge Sort:          {d:.2}x\n", .{bubble_f / @as(f64, @floatFromInt(merge))});
    try writer.print("      Heap Sort:           {d:.2}x\n", .{bubble_f / @as(f64, @floatFromInt(heap))});
}

// ============================================================================
// Benchmark 7: Performance vs Data Size
// ============================================================================

fn benchmarkDataSizes(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("Benchmark 7: Sum Performance vs Data Size\n", .{});
    try writer.print("-" ** 80, .{});
    try writer.print("\n\n", .{});

    const sizes = [_]usize{ 100, 1_000, 10_000, 100_000 };

    try writer.print("  Testing sumOptimized with different data sizes:\n\n", .{});

    for (sizes) |size| {
        const data = try allocator.alloc(i64, size);
        defer allocator.free(data);

        var prng = std.Random.DefaultPrng.init(12345);
        const random = prng.random();
        for (data) |*value| {
            value.* = random.int(i64) % 1000;
        }

        const SumWrapper = struct {
            fn call(d: []const i64) i64 {
                return algorithms.sumOptimized(d);
            }
        };

        const iterations = 10_000;
        const result = try benchmark.benchmarkSliceOp(i64, *const fn ([]const i64) i64, SumWrapper.call, data, iterations);

        try writer.print("    Size {d:>6}: {d:>8} ns", .{ size, result.avg_ns });
        if (result.avg_ns > 1_000) {
            const us = @as(f64, @floatFromInt(result.avg_ns)) / 1_000.0;
            try writer.print(" ({d:.3} µs)", .{us});
        }
        try writer.print("\n", .{});

        // Calculate ns per element
        const ns_per_elem = @as(f64, @floatFromInt(result.avg_ns)) / @as(f64, @floatFromInt(size));
        try writer.print("               ({d:.3} ns per element)\n", .{ns_per_elem});
    }

    try writer.print("\n\n", .{});
}
