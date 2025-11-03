// Buffered I/O Example
// Demonstrates: BufferedWriter, flushing, performance patterns

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Fixed buffer stream (no allocation)
    {
        var buf: [256]u8 = undefined;
        var writer: std.Io.Writer = .fixed(&buf);

        try writer.writeAll("Fixed buffer: ");
        try writer.print("number = {d}\n", .{123});

        const written = writer.buffered();
        std.debug.print("{s}", .{written});
    }

    // 2. ArrayList as dynamic buffer
    {
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        var list_writer = list.writer();
        try list_writer.writeAll("ArrayList buffer: ");
        try list_writer.print("hex = 0x{x}\n", .{42});

        std.debug.print("{s}", .{list.items});
    }

    // 3. Buffered file writing
    {
        const file = try std.fs.cwd().createFile("buffered.txt", .{});
        defer file.close();

        // Create buffer for file writer
        var buf: [4096]u8 = undefined;
        var file_writer = file.writer(&buf);

        // Multiple writes are buffered
        try file_writer.writeAll("Line 1\n");
        try file_writer.writeAll("Line 2\n");
        try file_writer.print("Line {d}\n", .{3});

        // Explicit flush ensures all data is written
        try file_writer.interface.flush();
    }

    // 4. Performance comparison demonstration
    {
        const iterations = 1000;

        // Unbuffered writing (slower)
        const file1 = try std.fs.cwd().createFile("unbuffered.txt", .{});
        defer file1.close();

        var timer = try std.time.Timer.start();
        var unbuffered_writer = file1.writer(&.{});
        for (0..iterations) |i| {
            try unbuffered_writer.print("Line {d}\n", .{i});
        }
        const unbuffered_time = timer.read();

        // Buffered writing (faster)
        const file2 = try std.fs.cwd().createFile("buffered_perf.txt", .{});
        defer file2.close();

        var buf: [4096]u8 = undefined;
        var buffered_writer = file2.writer(&buf);

        timer.reset();
        for (0..iterations) |i| {
            try buffered_writer.print("Line {d}\n", .{i});
        }
        try buffered_writer.interface.flush();
        const buffered_time = timer.read();

        std.debug.print("Unbuffered: {d}ns\n", .{unbuffered_time});
        std.debug.print("Buffered: {d}ns\n", .{buffered_time});
        std.debug.print("Speedup: {d:.2}x\n", .{
            @as(f64, @floatFromInt(unbuffered_time)) / @as(f64, @floatFromInt(buffered_time)),
        });
    }

    // Cleanup
    try std.fs.cwd().deleteFile("buffered.txt");
    try std.fs.cwd().deleteFile("unbuffered.txt");
    try std.fs.cwd().deleteFile("buffered_perf.txt");
}
