// Example 1: Example 1
// 05 Io Streams
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const stdout = std.Io.File.stdout();  // 0.15+
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(init.io, &buf);

    try writer.interface.print("Hello from stdout! Number: {d}\n", .{42});
    try writer.interface.print("Hex: 0x{x}, Binary: 0b{b}\n", .{ 255, 5 });
    try writer.interface.flush();
}
