// Pitfall 1: defer in Loops (CORRECT)
// Chapter 2: Language Idioms & Core Patterns
//
// This example demonstrates CORRECT usage of defer in loops
// Using a nested block ensures defer executes at block end, not function end

const std = @import("std");

fn processFilesCorrect(io: std.Io, paths: []const []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    for (paths) |path| {
        { // Nested block for proper scoping
            const file = try cwd.createFile(io, path, .{});
            defer file.close(io); // Executes at block end, after each iteration

            try file.writeStreamingAll(io, "test content\n");
            std.debug.print("Processed: {s}\n", .{path});
        } // File closes here, at block end
        std.debug.print("  File handle closed immediately\n", .{});
    }
}

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const paths = [_][]const u8{ "file1.txt", "file2.txt", "file3.txt" };

    _ = allocator;
    try processFilesCorrect(io, &paths);

    // Cleanup
    for (paths) |path| {
        cwd.deleteFile(io, path) catch {};
    }
}
