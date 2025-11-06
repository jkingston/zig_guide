// Example 1: Example 1
// 09 Packages Dependencies
//
// Extracted from chapter content.md

// src/mathlib.zig
const std = @import("std");

pub const version = "2.0.0";

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn mul(a: i32, b: i32) i32 {
    return a * b;
}

test "arithmetic operations" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, 6), mul(2, 3));
}