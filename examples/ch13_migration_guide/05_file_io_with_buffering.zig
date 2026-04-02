// Example 5: File I/O with Buffering
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.createFile(io, "output.txt", .{});
    defer file.close(io);

    var buf: [4096]u8 = undefined;
    var writer = file.writer(io, &buf);

    try writer.interface.print("Writing to file\n", .{});
    for (0..100) |i| {
        try writer.interface.print("Line {d}\n", .{i});
    }
    try writer.interface.flush();
}
