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

pub fn main(init: std.process.Init) !void {
    const clock: std.Io.Clock = .awake;
    const start = clock.now(init.io);

    // Code to measure
    expensiveOperation();

    const end = clock.now(init.io);
    const elapsed_ns: u64 = @intCast(@as(i64, @truncate(@divTrunc(start.durationTo(end).nanoseconds, 1))));
    std.debug.print("Elapsed: {d} ns\n", .{elapsed_ns});
}
