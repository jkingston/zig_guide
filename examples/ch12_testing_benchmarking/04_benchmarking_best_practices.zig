// Example 4: Benchmarking Best Practices
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");

fn expensiveOperation() void {
    // Mock expensive operation
    var sum: u64 = 0;
    var i: u32 = 0;
    while (i < 1000000) : (i += 1) {
        sum +%= i;
    }
    std.mem.doNotOptimizeAway(&sum);
}

pub fn main() !void {
    var timer = try std.time.Timer.start();

    // Code to measure
    expensiveOperation();

    const elapsed_ns = timer.read();
    std.debug.print("Elapsed: {d} ns\n", .{elapsed_ns});
}