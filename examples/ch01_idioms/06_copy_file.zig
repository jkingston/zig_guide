// Example 1: Combining defer with Error Handling
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates proper resource cleanup in reverse order of acquisition

const std = @import("std");

fn copyFile(
    allocator: std.mem.Allocator,
    src_path: []const u8,
    dst_path: []const u8,
) !void {
    const src = try std.fs.cwd().openFile(src_path, .{});
    defer src.close();

    const dst = try std.fs.cwd().createFile(dst_path, .{});
    defer dst.close();

    const buffer = try allocator.alloc(u8, 4096);
    defer allocator.free(buffer);

    while (true) {
        const bytes_read = try src.read(buffer);
        if (bytes_read == 0) break;
        try dst.writeAll(buffer[0..bytes_read]);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a test source file
    const src_path = "source.txt";
    const dst_path = "destination.txt";

    {
        const file = try std.fs.cwd().createFile(src_path, .{});
        defer file.close();
        try file.writeAll("This is test content for file copying.\n");
    }
    defer std.fs.cwd().deleteFile(src_path) catch {};
    defer std.fs.cwd().deleteFile(dst_path) catch {};

    try copyFile(allocator, src_path, dst_path);

    // Verify the copy
    const dst = try std.fs.cwd().openFile(dst_path, .{});
    defer dst.close();
    const content = try dst.readToEndAlloc(allocator, 1024);
    defer allocator.free(content);

    std.debug.print("Copied content: {s}", .{content});
}
