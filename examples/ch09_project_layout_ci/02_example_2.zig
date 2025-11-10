// Example 2: Example 2
// 10 Project Layout Ci
//
// Extracted from chapter content.md

// src/root.zig
const std = @import("std");

/// Public API function
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "addition" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
}