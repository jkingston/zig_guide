// Example 1: I/O Migration
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var stdout_buf: [256]u8 = undefined;
    var stderr_buf: [256]u8 = undefined;

    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);
    var stderr = std.Io.File.stderr().writer(init.io, &stderr_buf);

    try stdout.interface.print("Regular output\n", .{});
    try stdout.interface.print("Value: {d}\n", .{42});
    try stdout.interface.flush();

    try stderr.interface.print("Error message\n", .{});
    try stderr.interface.flush();
}
