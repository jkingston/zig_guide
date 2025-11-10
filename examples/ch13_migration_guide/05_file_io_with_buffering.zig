// Example 5: File I/O with Buffering
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);

    try writer.interface.print("Writing to file\n", .{});
    for (0..100) |i| {
        try writer.interface.print("Line {d}\n", .{i});
    }
    try writer.interface.flush();
}