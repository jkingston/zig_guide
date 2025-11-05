const std = @import("std");

pub fn main() !void {
    // 🕐 0.14.x: getStdOut() returns writer directly
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stdout.print("Regular output to stdout\n", .{});
    try stdout.print("Formatted value: {d}\n", .{42});
    try stdout.print("Multiple values: {d} + {d} = {d}\n", .{ 10, 32, 42 });

    try stderr.print("Error message to stderr\n", .{});
    try stderr.print("Warning: This is a test warning\n", .{});
}
