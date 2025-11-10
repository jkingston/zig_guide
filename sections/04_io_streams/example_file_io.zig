// File I/O Patterns Example
// Demonstrates: reading files, writing files, proper cleanup

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Writing to a file
    {
        const file = try std.fs.cwd().createFile("example.txt", .{});
        defer file.close();

        var file_writer = file.writer(&.{});
        try file_writer.writeAll("Hello, File!\n");
        try file_writer.print("Line {d}: {s}\n", .{ 2, "formatted content" });
    }

    // 2. Reading entire file into memory
    {
        const file = try std.fs.cwd().openFile("example.txt", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(allocator, 1024 * 1024); // 1MB limit
        defer allocator.free(contents);

        std.debug.print("File contents:\n{s}\n", .{contents});
    }

    // 3. Streaming file read (line by line)
    {
        const file = try std.fs.cwd().openFile("example.txt", .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        var file_reader = file.reader(&buf);

        std.debug.print("\nReading line by line:\n", .{});
        var line_num: u32 = 1;
        while (true) {
            const line = file_reader.readUntilDelimiterOrEof(&buf, '\n') catch |err| switch (err) {
                error.StreamTooLong => {
                    // Line too long, skip to next newline
                    try file_reader.skipUntilDelimiterOrEof('\n');
                    continue;
                },
                else => return err,
            } orelse break;

            std.debug.print("  {d}: {s}\n", .{ line_num, line });
            line_num += 1;
        }
    }

    // 4. Error-path cleanup with errdefer
    {
        const file = try std.fs.cwd().createFile("temp.txt", .{});
        errdefer file.close(); // Close on error

        var file_writer = file.writer(&.{});
        try file_writer.writeAll("Temporary content\n");

        file.close(); // Explicit close on success
    }

    // Cleanup
    try std.fs.cwd().deleteFile("example.txt");
    try std.fs.cwd().deleteFile("temp.txt");
}
