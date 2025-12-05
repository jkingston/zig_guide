// Example 6: HashMap vs ArrayHashMap Performance
// 04 Collections Containers
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

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

    // Iterate HashMap
    var timer = try std.time.Timer.start();
    var sum1: u64 = 0;
    for (0..iterations) |_| {
        var it1 = hash_map.iterator();
        while (it1.next()) |entry| {
            sum1 += entry.value_ptr.*;
        }
    }
    const hash_map_time = timer.read();

    // Iterate ArrayHashMap
    timer.reset();
    var sum2: u64 = 0;
    for (0..iterations) |_| {
        var it2 = array_hash_map.iterator();
        while (it2.next()) |entry| {
            sum2 += entry.value_ptr.*;
        }
    }
    const array_hash_map_time = timer.read();

    std.debug.print("HashMap iteration: {} ns (sum: {})\n", .{ hash_map_time, sum1 });
    std.debug.print("ArrayHashMap iteration: {} ns (sum: {})\n", .{ array_hash_map_time, sum2 });

    if (array_hash_map_time > 0) {
        const speedup = @as(f64, @floatFromInt(hash_map_time)) / @as(f64, @floatFromInt(array_hash_map_time));
        std.debug.print("ArrayHashMap is {d:.2}x faster for iteration\n", .{speedup});
    }
}