// Example 3: Example 3
// 10 Project Layout Ci
//
// Extracted from chapter content.md

// tests/math_tests.zig
const std = @import("std");
const math = @import("../src/math.zig");

test "comprehensive addition tests" {
    try std.testing.expectEqual(@as(i32, 0), math.add(0, 0));
    try std.testing.expectEqual(@as(i32, 100), math.add(50, 50));
    try std.testing.expectEqual(@as(i32, -10), math.add(-5, -5));
}