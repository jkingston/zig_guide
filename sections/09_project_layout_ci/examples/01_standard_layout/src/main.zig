const std = @import("std");
const myproject = @import("myproject");

pub fn main() void {
    std.debug.print("My Project Demo\n", .{});

    const result = myproject.add(10, 32);
    std.debug.print("10 + 32 = {d}\n", .{result});

    const product = myproject.multiply(6, 7);
    std.debug.print("6 * 7 = {d}\n", .{product});
}

test "main functionality" {
    // Test that our main logic would work
    const result = myproject.add(10, 32);
    try std.testing.expectEqual(@as(i32, 42), result);
}
