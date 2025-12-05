// Example 5: Container Reuse with clearRetainingCapacity
// 04 Collections Containers
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    std.debug.print("=== Reusing Containers Across Iterations ===\n\n", .{});

    var buffer = std.ArrayList(u8).empty;
    defer buffer.deinit(allocator);

    // Pre-allocate reasonable capacity
    try buffer.ensureTotalCapacity(allocator, 1024);

    const requests = [_][]const u8{ "request1", "request2", "request3" };

    for (requests, 0..) |request, i| {
        // Clear contents but keep capacity
        buffer.clearRetainingCapacity();

        std.debug.print("Iteration {}: ", .{i});
        std.debug.print("Length: {}, Capacity: {}\n", .{ buffer.items.len, buffer.capacity });

        // Build response using existing capacity
        try buffer.appendSlice(allocator, "Response to ");
        try buffer.appendSlice(allocator, request);

        std.debug.print("  Built: {s}\n", .{buffer.items});
        std.debug.print("  Final length: {}, Capacity: {}\n\n", .{ buffer.items.len, buffer.capacity });
    }

    std.debug.print("No reallocations occurred - capacity stayed constant\n", .{});

    // HashMap example
    std.debug.print("\n=== HashMap Reset Pattern ===\n\n", .{});

    var cache = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer cache.deinit(allocator);

    try cache.ensureTotalCapacity(allocator, 100);

    for (0..3) |batch| {
        std.debug.print("Batch {}: ", .{batch});

        // Populate cache
        for (0..10) |i| {
            try cache.put(allocator, @intCast(i), "data");
        }

        std.debug.print("Count: {}, Capacity: {}\n", .{ cache.count(), cache.capacity() });

        // Reset for next batch
        cache.clearRetainingCapacity();
    }

    std.debug.print("\nCache reused across batches without reallocation\n", .{});
}