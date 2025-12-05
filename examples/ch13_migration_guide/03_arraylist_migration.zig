// Example 3: ArrayList Migration
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var list = std.ArrayList(u32).empty;
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.appendSlice(allocator, &[_]u32{30, 40});

    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}