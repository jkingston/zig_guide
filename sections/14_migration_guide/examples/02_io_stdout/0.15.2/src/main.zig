const std = @import("std");

pub fn main() !void {
    // ✅ 0.15+: stdout() requires explicit buffer, access via .interface
    // Buffered stdout for better performance
    var stdout_buf: [256]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    // Unbuffered stderr for immediate error visibility
    var stderr = std.fs.File.stderr().writer(&.{});

    try stdout.interface.print("Regular output to stdout\n", .{});
    try stdout.interface.print("Formatted value: {d}\n", .{42});
    try stdout.interface.print("Multiple values: {d} + {d} = {d}\n", .{ 10, 32, 42 });
    try stdout.interface.flush(); // Ensure output is visible

    try stderr.interface.print("Error message to stderr\n", .{});
    try stderr.interface.print("Warning: This is a test warning\n", .{});
}
