// Pitfall 1: defer in Loops (WRONG)
// Chapter 2: Language Idioms & Core Patterns
//
// ❌ This example demonstrates INCORRECT usage of defer in loops
// defer accumulates until function returns, leaking resources

const std = @import("std");

fn processFilesWrong(paths: []const []const u8) !void {
    for (paths) |path| {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close(); // ❌ WRONG: Defers until function ends, not loop end

        try file.writeAll("test content\n");
        std.debug.print("Processed: {s} (file handle still open!)\n", .{path});
    }
    // All files close here, at function end
    std.debug.print("All files closed at function end\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const paths = [_][]const u8{ "file1.txt", "file2.txt", "file3.txt" };

    _ = allocator;
    try processFilesWrong(&paths);

    // Cleanup
    for (paths) |path| {
        std.fs.cwd().deleteFile(path) catch {};
    }
}
