const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ArrayList
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();
    try list.append(42);

    // HashMap
    var map = std.AutoHashMap([]const u8, i32).init(allocator);
    defer map.deinit();
    try map.put("answer", 42);

    // String operations
    const str = "hello";
    const copy = try allocator.dupe(u8, str);
    defer allocator.free(copy);

    // Formatting
    var buf: [100]u8 = undefined;
    const formatted = try std.fmt.bufPrint(&buf, "Value: {d}", .{42});
    std.debug.print("{s}\n", .{formatted});

    // Time
    const timestamp = std.time.timestamp();
    _ = timestamp;

    std.debug.print("Stdlib APIs demonstrated\n", .{});
}
