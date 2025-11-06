// Example 4: Example 4
// 01 Introduction
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(&buf);
    try writer.interface.print("Hello from 0.15!\n", .{});
    try writer.interface.flush();
}