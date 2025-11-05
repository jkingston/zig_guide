const std = @import("std");
const compute = @import("compute.zig");
const memory = @import("memory.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Profiling Demo: CPU & Memory Intensive Operations ===\n\n", .{});

    // This program demonstrates various hot spots that will be visible in profilers:
    // 1. CPU-intensive computations (compute.zig)
    // 2. Memory-intensive operations (memory.zig)
    // 3. Nested function calls with different costs
    // 4. Mix of hot paths (frequently called) and cold paths (rarely called)

    const workload_size = 30; // Adjust for longer/shorter profiling runs

    // HOT PATH 1: Recursive computation (will show deep call stacks)
    std.debug.print("1. Computing Fibonacci...\n", .{});
    for (0..10) |_| {
        const fib_result = compute.fibonacci(workload_size);
        std.debug.print("   fib({d}) = {d}\n", .{ workload_size, fib_result });
    }

    // HOT PATH 2: Prime number generation (will show CPU time in loops)
    std.debug.print("\n2. Generating prime numbers...\n", .{});
    var primes = std.ArrayList(u32).init(allocator);
    defer primes.deinit();

    for (0..5) |_| {
        primes.clearRetainingCapacity();
        try compute.generatePrimes(allocator, 10000, &primes);
        std.debug.print("   Generated {d} primes\n", .{primes.items.len});
    }

    // HOT PATH 3: Matrix multiplication (nested loops, cache effects)
    std.debug.print("\n3. Matrix multiplication...\n", .{});
    const matrix_size = 200;
    var matrix_a = try compute.createMatrix(allocator, matrix_size);
    defer compute.destroyMatrix(allocator, matrix_a);
    var matrix_b = try compute.createMatrix(allocator, matrix_size);
    defer compute.destroyMatrix(allocator, matrix_b);

    for (0..3) |i| {
        var result = try compute.multiplyMatrices(allocator, matrix_a, matrix_b, matrix_size);
        defer compute.destroyMatrix(allocator, result);
        std.debug.print("   Iteration {d}: {d}x{d} matrix multiplication complete\n",
            .{ i + 1, matrix_size, matrix_size });
    }

    // HOT PATH 4: String processing (allocation + processing)
    std.debug.print("\n4. String processing...\n", .{});
    const text = "The quick brown fox jumps over the lazy dog. " ** 100;
    for (0..1000) |_| {
        const word_count = compute.countWords(text);
        _ = word_count;
    }
    std.debug.print("   Processed 1000 iterations of text\n", .{});

    // HOT PATH 5: Memory-intensive allocations
    std.debug.print("\n5. Memory allocations...\n", .{});

    // Large buffer allocation (shows in heap profiler)
    std.debug.print("   a. Large buffer allocation...\n", .{});
    for (0..5) |i| {
        var large_buffer = try memory.allocateLargeBuffer(allocator, 1024 * 1024 * 10); // 10MB
        defer memory.freeLargeBuffer(allocator, large_buffer);
        memory.fillBuffer(large_buffer, @intCast(i));
        std.debug.print("      Allocated and filled 10MB buffer\n", .{});
    }

    // Many small allocations (shows allocation patterns)
    std.debug.print("   b. Many small allocations...\n", .{});
    for (0..3) |i| {
        var chunks = try memory.allocateManySmall(allocator, 10000, 64);
        defer memory.freeManySmall(allocator, chunks);
        std.debug.print("      Created {d} small allocations (iteration {d})\n",
            .{ chunks.items.len, i + 1 });
    }

    // Data structure building (shows heap growth)
    std.debug.print("   c. Building data structures...\n", .{});
    for (0..2) |i| {
        var data = try memory.buildDataStructure(allocator, 5000);
        defer memory.destroyDataStructure(allocator, data);
        std.debug.print("      Built data structure with {d} entries (iteration {d})\n",
            .{ data.count(), i + 1 });
    }

    // COLD PATH: Rarely executed code (won't show much in profiler)
    if (shouldRunColdPath()) {
        std.debug.print("\n6. Cold path (rarely executed)...\n", .{});
        coldPathOperation();
    }

    // Mixed workload to demonstrate profiler call graphs
    std.debug.print("\n7. Mixed workload (demonstrates call graph)...\n", .{});
    try runMixedWorkload(allocator, 100);

    std.debug.print("\n=== Profiling Demo Complete ===\n", .{});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  1. Run ./scripts/profile_callgrind.sh for CPU profiling\n", .{});
    std.debug.print("  2. Run ./scripts/profile_perf.sh for sampling profiling\n", .{});
    std.debug.print("  3. Run ./scripts/profile_massif.sh for heap profiling\n", .{});
    std.debug.print("  4. Run ./scripts/generate_flamegraph.sh for flame graphs\n", .{});
}

// Cold path: rarely executed, won't show much in profiler
fn shouldRunColdPath() bool {
    // Only run 1% of the time
    return false;
}

fn coldPathOperation() void {
    std.debug.print("   This code is rarely executed\n", .{});
    var sum: u64 = 0;
    for (0..1000) |i| {
        sum += i;
    }
    std.debug.print("   Sum: {d}\n", .{sum});
}

// Mixed workload to demonstrate call graph in profilers
fn runMixedWorkload(allocator: std.mem.Allocator, iterations: usize) !void {
    for (0..iterations) |_| {
        // Mix of CPU and memory operations
        try cpuIntensiveWork();
        try memoryIntensiveWork(allocator);
    }
    std.debug.print("   Completed {d} iterations of mixed workload\n", .{iterations});
}

fn cpuIntensiveWork() !void {
    // Some CPU work
    const result = compute.fibonacci(15);
    _ = result;
}

fn memoryIntensiveWork(allocator: std.mem.Allocator) !void {
    // Some memory work
    var buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);
    @memset(buffer, 0);
}
