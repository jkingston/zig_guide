// Example: Generic Functions with comptime
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates compile-time type parameters for zero-cost generics

const std = @import("std");

fn maximum(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "generic maximum" {
    try std.testing.expect(maximum(i32, 10, 20) == 20);
    try std.testing.expect(maximum(f64, 3.14, 2.71) == 3.14);
}

pub fn main() !void {
    const int_max = maximum(i32, 10, 20);
    const float_max = maximum(f64, 3.14, 2.71);

    std.debug.print("Maximum i32: {}\n", .{int_max});
    std.debug.print("Maximum f64: {d:.2}\n", .{float_max});
}
