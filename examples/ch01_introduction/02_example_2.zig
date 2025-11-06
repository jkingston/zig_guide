// Example 2: Example 2
// 01 Introduction
//
// Extracted from chapter content.md

const std = @import("std");

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "comptime execution" {
    const x = comptime fibonacci(10);
    try std.testing.expect(x == 55);
}