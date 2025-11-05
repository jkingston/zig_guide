const std = @import("std");

pub fn main() !void {
    // ✅ 0.15+: Create file with explicit buffering for performance
    const file = try std.fs.cwd().createFile("output_015.txt", .{});
    defer file.close();

    // Use 4KB buffer for optimal file I/O performance
    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);

    try writer.interface.print("File I/O Example - Zig 0.15.2\n", .{});
    try writer.interface.print("Writing multiple lines:\n", .{});

    // Write 100 lines - buffering provides 5-10x performance improvement
    for (0..100) |i| {
        try writer.interface.print("Line {d}: This is test data\n", .{i});
    }

    try writer.interface.print("\nWrite complete!\n", .{});

    // CRITICAL: Flush buffer before closing file or data will be lost!
    try writer.interface.flush();

    std.debug.print("File written successfully to output_015.txt\n", .{});
}
