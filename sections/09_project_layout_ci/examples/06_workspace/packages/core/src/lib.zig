//! Core library providing shared functionality.

const std = @import("std");

pub const Version = struct {
    major: u32,
    minor: u32,
    patch: u32,

    pub fn format(
        self: Version,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d}.{d}.{d}", .{ self.major, self.minor, self.patch });
    }
};

pub const version = Version{ .major = 1, .minor = 0, .patch = 0 };

pub fn greet(writer: anytype, name: []const u8) !void {
    try writer.print("Hello from core, {s}!\n", .{name});
}

pub fn calculate(a: i32, b: i32) i32 {
    return a * 2 + b;
}

test "calculate" {
    try std.testing.expectEqual(@as(i32, 7), calculate(2, 3));
}

test "version format" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "{}", .{version});
    try std.testing.expectEqualStrings("1.0.0", result);
}
