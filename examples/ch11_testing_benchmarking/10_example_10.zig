// Example 10: Example 10
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

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
    var stdout_buf: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);
    const iterations = 1_000_000;
    const n = 1000;

    try stdout.interface.print("Benchmarking sum algorithms ({d} iterations)...\n\n", .{iterations});

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
        &stdout.interface,
        "Formula",
        formula_result,
        "Iterative",
        iterative_result,
    );

    try stdout.interface.flush();
}