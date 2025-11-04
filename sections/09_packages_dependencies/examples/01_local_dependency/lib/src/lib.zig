const std = @import("std");

pub const version = "1.0.0";

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

test "add function" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
}
