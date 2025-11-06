// Example: Resource Cleanup with defer
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates pairing resource acquisition with deferred cleanup

const std = @import("std");

fn processFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Process content here
    std.debug.print("Read {} bytes from {s}\n", .{ content.len, path });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a test file
    const test_path = "test_file.txt";
    {
        const file = try std.fs.cwd().createFile(test_path, .{});
        defer file.close();
        try file.writeAll("Hello, Zig!\n");
    }
    defer std.fs.cwd().deleteFile(test_path) catch {};

    try processFile(allocator, test_path);
}
