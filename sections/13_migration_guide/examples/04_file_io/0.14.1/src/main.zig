const std = @import("std");

pub fn main() !void {
    // 🕐 0.14.x: Create file and write without explicit buffering
    const file = try std.fs.cwd().createFile("output_014.txt", .{});
    defer file.close();

    const writer = file.writer();

    try writer.print("File I/O Example - Zig 0.14.1\n", .{});
    try writer.print("Writing multiple lines:\n", .{});

    // Write 100 lines
    for (0..100) |i| {
        try writer.print("Line {d}: This is test data\n", .{i});
    }

    try writer.print("\nWrite complete!\n", .{});

    std.debug.print("File written successfully to output_014.txt\n", .{});
}
