const std = @import("std");

/// Library version
pub const version = "2.0.0";

/// Add two integers
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Subtract two integers
pub fn sub(a: i32, b: i32) i32 {
    return a - b;
}

/// Multiply two integers
pub fn mul(a: i32, b: i32) i32 {
    return a * b;
}

/// Integer division (panics on division by zero)
pub fn div(a: i32, b: i32) i32 {
    return @divTrunc(a, b);
}

test "arithmetic operations" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, -1), sub(2, 3));
    try std.testing.expectEqual(@as(i32, 6), mul(2, 3));
    try std.testing.expectEqual(@as(i32, 3), div(7, 2));
}
