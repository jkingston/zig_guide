// Example 1: Example 1
// 07 Async Concurrency
//
// Extracted from chapter content.md

const std = @import("std");

fn workerThread(id: u32, iterations: u32) void {
    std.debug.print("Worker {d} starting\n", .{id});

    var sum: u64 = 0;
    for (0..iterations) |i| {
        sum += i;
    }

    std.debug.print("Worker {d} sum: {d}\n", .{id, sum});
}

pub fn main() !void {
    // Spawn thread with arguments
    const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });

    // Wait for completion (required!)
    thread.join();
}