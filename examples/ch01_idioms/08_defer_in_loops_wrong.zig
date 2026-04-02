// Pitfall 1: defer in Loops (WRONG)
// Chapter 2: Language Idioms & Core Patterns
//
// This example demonstrates INCORRECT usage of defer in loops
// defer accumulates until function returns, leaking resources

const std = @import("std");

fn processFilesWrong(io: std.Io, paths: []const []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    for (paths) |path| {
        const file = try cwd.createFile(io, path, .{});
        defer file.close(io); // WRONG: Defers until function ends, not loop end

        try file.writeStreamingAll(io, "test content\n");
        std.debug.print("Processed: {s} (file handle still open!)\n", .{path});
    }
    // All files close here, at function end
    std.debug.print("All files closed at function end\n", .{});
}

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const paths = [_][]const u8{ "file1.txt", "file2.txt", "file3.txt" };

    _ = allocator;
    try processFilesWrong(io, &paths);

    // Cleanup
    for (paths) |path| {
        cwd.deleteFile(io, path) catch {};
    }
}
