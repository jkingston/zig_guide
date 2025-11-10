// Stub benchmark module for Ch12 examples

const std = @import("std");

pub const BenchmarkResult = struct {
    total_ns: u64,
    iterations: u64,
    avg_ns: u64,
};

pub fn benchmarkWithArg(comptime FnType: type, func: FnType, arg: anytype, iterations: u64) !BenchmarkResult {
    var timer = try std.time.Timer.start();

    var i: u64 = 0;
    while (i < iterations) : (i += 1) {
        _ = func(arg);
    }

    const elapsed_ns = timer.read();
    return BenchmarkResult{
        .total_ns = elapsed_ns,
        .iterations = iterations,
        .avg_ns = elapsed_ns / iterations,
    };
}

pub fn compareBenchmarks(
    writer: anytype,
    name1: []const u8,
    result1: BenchmarkResult,
    name2: []const u8,
    result2: BenchmarkResult,
) !void {
    try writer.print("\n{s}: {d} ns avg ({d} total)\n", .{name1, result1.avg_ns, result1.total_ns});
    try writer.print("{s}: {d} ns avg ({d} total)\n", .{name2, result2.avg_ns, result2.total_ns});

    if (result1.avg_ns < result2.avg_ns) {
        const speedup = @as(f64, @floatFromInt(result2.avg_ns)) / @as(f64, @floatFromInt(result1.avg_ns));
        try writer.print("{s} is {d:.2}x faster\n", .{name1, speedup});
    } else {
        const speedup = @as(f64, @floatFromInt(result1.avg_ns)) / @as(f64, @floatFromInt(result2.avg_ns));
        try writer.print("{s} is {d:.2}x faster\n", .{name2, speedup});
    }
}
