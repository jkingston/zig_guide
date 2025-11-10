// Basic Writer/Reader Usage Example
// Demonstrates: stdout, stderr, formatting, and basic file I/O

const std = @import("std");

pub fn main() !void {
    // 1. Obtain stdout and stderr files
    // ✅ 0.15+
    const stdout = std.Io.File.stdout();
    const stderr = std.Io.File.stderr();

    var stdout_writer = stdout.writer(&.{});
    var stderr_writer = stderr.writer(&.{});

    // 2. Write formatted output
    try stdout_writer.print("Hello from stdout! Number: {d}\n", .{42});
    try stderr_writer.print("Warning from stderr! Hex: 0x{x}\n", .{255});

    // 3. Write plain text
    try stdout_writer.writeAll("Plain text output\n");

    // 4. Multiple format specifiers
    try stdout_writer.print("String: {s}, Bool: {}, Float: {d:.2}\n", .{
        "example",
        true,
        3.14159,
    });
}
