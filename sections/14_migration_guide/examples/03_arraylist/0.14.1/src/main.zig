const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 🕐 0.14.x: ArrayList is managed (stores allocator internally)
    var list = std.ArrayList(u32).init(allocator);
    defer list.deinit();

    try list.append(10);
    try list.append(20);
    try list.append(30);
    try list.appendSlice(&[_]u32{ 40, 50 });

    std.debug.print("List contents: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
    std.debug.print("List length: {d}\n", .{list.items.len});
    std.debug.print("List capacity: {d}\n", .{list.capacity});
}
