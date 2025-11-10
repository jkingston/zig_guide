// Example 1: Example 1
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

// Named test - appears in output
test "arithmetic operations" {
    const result = 2 + 2;
    try testing.expectEqual(4, result);
}

// Anonymous test - identified by file and line
test {
    try testing.expect(true);
}