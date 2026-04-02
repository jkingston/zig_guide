// Example 3: stdout Writer Changes in 0.15
// 01 Introduction
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const stdout = std.Io.File.stdout();
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(init.io, &buf);
    try writer.interface.print("Hello from 0.15!\n", .{});
    try writer.interface.flush();
}
