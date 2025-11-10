// Pitfall 1: defer in Loops (CORRECT)
// Chapter 2: Language Idioms & Core Patterns
//
// ✅ This example demonstrates CORRECT usage of defer in loops
// Using a nested block ensures defer executes at block end, not function end

const std = @import("std");

fn processFilesCorrect(paths: []const []const u8) !void {
    for (paths) |path| {
        { // ✅ Nested block for proper scoping
            const file = try std.fs.cwd().createFile(path, .{});
            defer file.close(); // Executes at block end, after each iteration

            try file.writeAll("test content\n");
            std.debug.print("Processed: {s}\n", .{path});
        } // File closes here, at block end
        std.debug.print("  File handle closed immediately\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const paths = [_][]const u8{ "file1.txt", "file2.txt", "file3.txt" };

    _ = allocator;
    try processFilesCorrect(&paths);

    // Cleanup
    for (paths) |path| {
        std.fs.cwd().deleteFile(path) catch {};
    }
}
