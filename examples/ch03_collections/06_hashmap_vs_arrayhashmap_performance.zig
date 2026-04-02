// Example 6: HashMap vs ArrayHashMap Performance
// 04 Collections Containers
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const iterations = 1000;

    // HashMap vs ArrayHashMap iteration performance
    std.debug.print("=== HashMap vs ArrayHashMap Iteration ===\n", .{});

    var hash_map = std.AutoHashMapUnmanaged(u32, u32){};
    defer hash_map.deinit(allocator);

    var array_hash_map = std.AutoArrayHashMapUnmanaged(u32, u32){};
    defer array_hash_map.deinit(allocator);

    // Populate both
    for (0..100) |i| {
        try hash_map.put(allocator, @intCast(i), @intCast(i * 2));
        try array_hash_map.put(allocator, @intCast(i), @intCast(i * 2));
    }

    const clock: std.Io.Clock = .awake;

    // Iterate HashMap
    const start1 = clock.now(init.io);
    var sum1: u64 = 0;
    for (0..iterations) |_| {
        var it1 = hash_map.iterator();
        while (it1.next()) |entry| {
            sum1 += entry.value_ptr.*;
        }
    }
    const end1 = clock.now(init.io);
    const hash_map_ns: i64 = @truncate(@divTrunc(start1.durationTo(end1).nanoseconds, 1));

    // Iterate ArrayHashMap
    const start2 = clock.now(init.io);
    var sum2: u64 = 0;
    for (0..iterations) |_| {
        var it2 = array_hash_map.iterator();
        while (it2.next()) |entry| {
            sum2 += entry.value_ptr.*;
        }
    }
    const end2 = clock.now(init.io);
    const array_hash_map_ns: i64 = @truncate(@divTrunc(start2.durationTo(end2).nanoseconds, 1));

    const hash_map_time: u64 = @intCast(hash_map_ns);
    const array_hash_map_time: u64 = @intCast(array_hash_map_ns);

    std.debug.print("HashMap iteration: {} ns (sum: {})\n", .{ hash_map_time, sum1 });
    std.debug.print("ArrayHashMap iteration: {} ns (sum: {})\n", .{ array_hash_map_time, sum2 });

    if (array_hash_map_time > 0) {
        const speedup = @as(f64, @floatFromInt(hash_map_time)) / @as(f64, @floatFromInt(array_hash_map_time));
        std.debug.print("ArrayHashMap is {d:.2}x faster for iteration\n", .{speedup});
    }
}
