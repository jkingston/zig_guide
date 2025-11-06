// Example 6: Example 6
// 14 Migration Guide
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    var buf: [4096]u8 = undefined;  // 4KB buffer for file I/O
    var writer = file.writer(&buf);

    try writer.interface.print("Writing to file\n", .{});
    for (0..100) |i| {
        try writer.interface.print("Line {d}\n", .{i});
    }
    try writer.interface.flush();  // CRITICAL: flush before close
}