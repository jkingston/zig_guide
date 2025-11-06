// Example: Naming Conventions in Zig
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates PascalCase, camelCase, and snake_case naming patterns

const std = @import("std");

// PascalCase for types
const Point = struct { x: i32, y: i32 };
const Color = enum { red, green, blue };

// camelCase for functions returning values
fn calculateSum(a: i32, b: i32) i32 {
    return a + b;
}

// PascalCase for functions returning types
fn ArrayList(comptime T: type) type {
    return std.ArrayList(T);
}

// snake_case for variables and constants
const max_connections = 100;

// snake_case for namespaces (zero-field structs)
const math = struct {
    pub fn add(a: i32, b: i32) i32 {
        return a + b;
    }
};

pub fn main() !void {
    const p = Point{ .x = 10, .y = 20 };
    const c = Color.red;
    const sum = calculateSum(5, 7);
    const math_sum = math.add(3, 4);

    std.debug.print("Point: ({}, {})\n", .{ p.x, p.y });
    std.debug.print("Color: {}\n", .{c});
    std.debug.print("Sum: {}\n", .{sum});
    std.debug.print("Math sum: {}\n", .{math_sum});
    std.debug.print("Max connections: {}\n", .{max_connections});
}
