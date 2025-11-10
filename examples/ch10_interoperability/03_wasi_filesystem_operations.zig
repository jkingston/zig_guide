// Example 3: WASI Filesystem Operations
// 11 Interoperability
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var stdout_buf: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    // Command-line arguments
    try stdout.interface.print("=== Command-line arguments ===\n", .{});
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var i: usize = 0;
    while (args.next()) |arg| {
        try stdout.interface.print("arg[{d}]: {s}\n", .{ i, arg });
        i += 1;
    }

    // Environment variables
    try stdout.interface.print("\n=== Environment variables ===\n", .{});
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    var iter = env_map.iterator();
    while (iter.next()) |entry| {
        try stdout.interface.print("{s}={s}\n", .{
            entry.key_ptr.*,
            entry.value_ptr.*
        });
    }

    // Filesystem operations (requires --dir capability)
    try stdout.interface.print("\n=== Filesystem operations ===\n", .{});
    const cwd = std.fs.cwd();

    // Create file
    const file = try cwd.createFile("wasi_test.txt", .{});
    defer file.close();

    try file.writeAll("Hello from WASI!\n");
    try stdout.interface.print("Created file: wasi_test.txt\n", .{});

    // Read file
    try file.seekTo(0);
    const contents = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(contents);

    try stdout.interface.print("Contents: {s}\n", .{contents});

    // Create directory
    try cwd.makeDir("wasi_dir");
    try stdout.interface.print("Created directory: wasi_dir\n", .{});

    try stdout.interface.flush();
}