// Custom Formatting Example
// Demonstrates: Implementing format() for custom types

const std = @import("std");

// Custom type with formatting support
const Point = struct {
    x: f32,
    y: f32,

    pub fn format(
        self: Point,
        comptime fmt_str: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt_str;
        _ = options;
        try writer.print("Point({d:.2}, {d:.2})", .{ self.x, self.y });
    }
};

// Custom type with multiple format options
const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn format(
        self: Color,
        comptime fmt_str: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        if (std.mem.eql(u8, fmt_str, "hex")) {
            try writer.print("#{x:0>2}{x:0>2}{x:0>2}", .{ self.r, self.g, self.b });
        } else if (std.mem.eql(u8, fmt_str, "rgb")) {
            try writer.print("rgb({d}, {d}, {d})", .{ self.r, self.g, self.b });
        } else {
            try writer.print("Color{{r={d}, g={d}, b={d}}}", .{ self.r, self.g, self.b });
        }
    }
};

pub fn main() !void {
    const stdout = std.Io.File.stdout();
    var writer = stdout.writer(&.{});

    // 1. Using custom format for Point
    const p = Point{ .x = 3.14, .y = 2.71 };
    try writer.print("Point: {}\n", .{p});
    try writer.print("Point: {any}\n", .{p});

    // 2. Using custom format with specifiers for Color
    const color = Color{ .r = 255, .g = 128, .b = 64 };
    try writer.print("Default: {}\n", .{color});
    try writer.print("Hex: {hex}\n", .{color});
    try writer.print("RGB: {rgb}\n", .{color});

    // 3. Format specifiers for built-in types
    const value: u32 = 42;
    try writer.print("Decimal: {d}\n", .{value});
    try writer.print("Hex: 0x{x}\n", .{value});
    try writer.print("Octal: 0o{o}\n", .{value});
    try writer.print("Binary: 0b{b}\n", .{value});

    // 4. Floating point formatting
    const pi = 3.14159265358979;
    try writer.print("Default: {d}\n", .{pi});
    try writer.print("2 decimals: {d:.2}\n", .{pi});
    try writer.print("Scientific: {e}\n", .{pi});

    // 5. String formatting with padding
    try writer.print("Left: '{s:<10}'\n", .{"hello"});
    try writer.print("Right: '{s:>10}'\n", .{"hello"});
    try writer.print("Center: '{s:^10}'\n", .{"hello"});
}
