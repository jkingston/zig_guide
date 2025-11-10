// Example 2: Example 2
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    // Buffered stdout for better performance
    var stdout_buf: [256]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    // Unbuffered stderr for immediate error visibility
    var stderr = std.fs.File.stderr().writer(&.{});

    try stdout.interface.print("Regular output\n", .{});
    try stdout.interface.print("Value: {d}\n", .{42});
    try stdout.interface.flush();  // Ensure output is visible

    try stderr.interface.print("Error message\n", .{});
}