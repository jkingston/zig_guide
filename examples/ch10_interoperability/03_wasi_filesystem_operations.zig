// Example 3: WASI Filesystem Operations
// 11 Interoperability
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buf: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &stdout_buf);

    // Command-line arguments
    try stdout.interface.print("=== Command-line arguments ===\n", .{});
    var args = std.process.Args.Iterator.init(init.minimal.args);

    var i: usize = 0;
    while (args.next()) |arg| {
        try stdout.interface.print("arg[{d}]: {s}\n", .{ i, arg });
        i += 1;
    }

    // Environment variables
    try stdout.interface.print("\n=== Environment variables ===\n", .{});
    var iter = init.environ_map.iterator();
    while (iter.next()) |entry| {
        try stdout.interface.print("{s}={s}\n", .{
            entry.key_ptr.*,
            entry.value_ptr.*
        });
    }

    // Filesystem operations (requires --dir capability)
    try stdout.interface.print("\n=== Filesystem operations ===\n", .{});
    const cwd = std.Io.Dir.cwd();

    // Create file
    const file = try cwd.createFile(io, "wasi_test.txt", .{});
    defer file.close(io);

    try file.writeStreamingAll(io, "Hello from WASI!\n");
    try stdout.interface.print("Created file: wasi_test.txt\n", .{});

    try stdout.interface.flush();
}
