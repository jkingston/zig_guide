// Example 1: Combining defer with Error Handling
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates proper resource cleanup in reverse order of acquisition

const std = @import("std");

fn copyFile(
    io: std.Io,
    allocator: std.mem.Allocator,
    src_path: []const u8,
    dst_path: []const u8,
) !void {
    const cwd = std.Io.Dir.cwd();
    const src = try cwd.openFile(io, src_path, .{});
    defer src.close(io);

    const dst = try cwd.createFile(io, dst_path, .{});
    defer dst.close(io);

    const buffer = try allocator.alloc(u8, 4096);
    defer allocator.free(buffer);

    while (true) {
        const bytes_read = try src.readStreaming(io, &.{buffer});
        if (bytes_read == 0) break;
        try dst.writeStreamingAll(io, buffer[0..bytes_read]);
    }
}

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    // Create a test source file
    const src_path = "source.txt";
    const dst_path = "destination.txt";

    {
        const file = try cwd.createFile(io, src_path, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "This is test content for file copying.\n");
    }
    defer cwd.deleteFile(io, src_path) catch {};
    defer cwd.deleteFile(io, dst_path) catch {};

    try copyFile(io, allocator, src_path, dst_path);

    // Verify the copy
    const dst = try cwd.openFile(io, dst_path, .{});
    defer dst.close(io);
    var buf: [4096]u8 = undefined;
    var reader = dst.reader(io, &buf);
    const content = try reader.interface.allocRemaining(allocator, .limited(1024));
    defer allocator.free(content);

    std.debug.print("Copied content: {s}", .{content});
}
