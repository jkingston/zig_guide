const std = @import("std");

pub fn factorial(n: u32) u32 {
    if (n == 0) return 1;
    return n * factorial(n - 1);
}

pub fn fibonacci(n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "factorial" {
    try std.testing.expectEqual(@as(u32, 1), factorial(0));
    try std.testing.expectEqual(@as(u32, 1), factorial(1));
    try std.testing.expectEqual(@as(u32, 120), factorial(5));
}

test "fibonacci" {
    try std.testing.expectEqual(@as(u32, 0), fibonacci(0));
    try std.testing.expectEqual(@as(u32, 1), fibonacci(1));
    try std.testing.expectEqual(@as(u32, 55), fibonacci(10));
}
