// Root module for myproject library.
//! This file exposes the public API for consumers.

const std = @import("std");

/// Adds two integers.
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Multiplies two integers.
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

test "add function" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, 0), add(-1, 1));
}

test "multiply function" {
    try std.testing.expectEqual(@as(i32, 6), multiply(2, 3));
    try std.testing.expectEqual(@as(i32, -6), multiply(-2, 3));
}
