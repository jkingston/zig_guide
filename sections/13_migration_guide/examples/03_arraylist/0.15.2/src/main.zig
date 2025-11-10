const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ✅ 0.15+: ArrayList is unmanaged (NO allocator stored)
    // Direct initialization instead of init()
    var list = std.ArrayList(u32).empty;
    defer list.deinit(allocator); // Must pass allocator to deinit

    // All mutation methods now require allocator parameter
    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);
    try list.appendSlice(allocator, &[_]u32{ 40, 50 });

    std.debug.print("List contents: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
    std.debug.print("List length: {d}\n", .{list.items.len});
    std.debug.print("List capacity: {d}\n", .{list.capacity});
}
