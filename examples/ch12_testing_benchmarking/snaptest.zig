// Stub snaptest module for Ch12 examples

const std = @import("std");

pub const Snap = struct {
    source_location: []const u8,

    pub fn snap_fn(comptime dir: []const u8) fn (std.builtin.SourceLocation, []const u8) Snap {
        _ = dir;
        return struct {
            fn init(src: std.builtin.SourceLocation, expected: []const u8) Snap {
                _ = src;
                return Snap{
                    .source_location = expected,
                };
            }
        }.init;
    }

    pub fn diff_fmt(self: Snap, comptime fmt: []const u8, args: anytype) !void {
        _ = self;
        _ = fmt;
        _ = args;
        // Mock implementation - in real code would compare formatted output with snapshot
    }
};
