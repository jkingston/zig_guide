// Example: defer Execution Order
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates LIFO (last-in-first-out) execution order of defer statements

const std = @import("std");

fn demonstrateDeferOrder() void {
    defer std.debug.print("3. Third (executed first)\n", .{});
    defer std.debug.print("2. Second\n", .{});
    defer std.debug.print("1. First (executed last)\n", .{});
    std.debug.print("0. Function body\n", .{});
}

pub fn main() void {
    std.debug.print("Demonstrating defer execution order:\n", .{});
    demonstrateDeferOrder();
    std.debug.print("\nExpected output:\n", .{});
    std.debug.print("0. Function body\n", .{});
    std.debug.print("1. First (executed last)\n", .{});
    std.debug.print("2. Second\n", .{});
    std.debug.print("3. Third (executed first)\n", .{});
}
