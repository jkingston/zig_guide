// Example: Resource Cleanup with defer
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates pairing resource acquisition with deferred cleanup

const std = @import("std");

fn processFile(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(io, path, .{});
    defer file.close(io);

    var buf: [4096]u8 = undefined;
    var reader = file.reader(io, &buf);
    const content = try reader.interface.allocRemaining(allocator, .limited(1024 * 1024));
    defer allocator.free(content);

    // Process content here
    std.debug.print("Read {} bytes from {s}\n", .{ content.len, path });
}

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    // Create a test file
    const test_path = "test_file.txt";
    {
        const file = try cwd.createFile(io, test_path, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "Hello, Zig!\n");
    }
    defer cwd.deleteFile(io, test_path) catch {};

    try processFile(io, allocator, test_path);
}
