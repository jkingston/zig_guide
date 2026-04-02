// Example 2: Example 2
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Buffered stdout for better performance
    var stdout_buf: [256]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);

    // Unbuffered stderr for immediate error visibility
    var stderr_buf: [1]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(init.io, &stderr_buf);

    try stdout.interface.print("Regular output\n", .{});
    try stdout.interface.print("Value: {d}\n", .{42});
    try stdout.interface.flush();  // Ensure output is visible

    try stderr.interface.print("Error message\n", .{});
    try stderr.interface.flush();
}
