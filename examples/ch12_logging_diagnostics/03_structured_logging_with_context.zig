// Example 3: Structured Logging with Context
// 13 Logging Diagnostics
//
// Extracted from chapter content.md

const std = @import("std");

pub const LogContext = struct {
    correlation_id: []const u8,
    user_id: ?u32 = null,
    request_path: ?[]const u8 = null,

    pub fn logInfo(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.info, format, args);
    }

    pub fn logError(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.err, format, args);
    }

    fn logWithLevel(
        self: LogContext,
        level: std.log.Level,
        comptime format: []const u8,
        args: anytype,
    ) void {
        var stderr_buf: [4096]u8 = undefined;
        var stderr = std.fs.File.stderr().writer(&stderr_buf);
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();

        var buf: [4096]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

        nosuspend {
            stderr.interface.writeAll("{") catch return;

            stderr.interface.writeAll("\"timestamp\":") catch return;
            stderr.interface.print("{d}", .{std.time.milliTimestamp()}) catch return;

            stderr.interface.writeAll(",\"level\":\"") catch return;
            const level_text = switch (level) {
                .err => "error",
                .warn => "warning",
                .info => "info",
                .debug => "debug",
            };
            stderr.interface.writeAll(level_text) catch return;
            stderr.interface.writeAll("\"") catch return;

            stderr.interface.writeAll(",\"correlation_id\":\"") catch return;
            stderr.interface.writeAll(self.correlation_id) catch return;
            stderr.interface.writeAll("\"") catch return;

            if (self.user_id) |uid| {
                stderr.interface.writeAll(",\"user_id\":") catch return;
                stderr.interface.print("{d}", .{uid}) catch return;
            }

            if (self.request_path) |path| {
                stderr.interface.writeAll(",\"path\":\"") catch return;
                stderr.interface.writeAll(path) catch return;
                stderr.interface.writeAll("\"") catch return;
            }

            stderr.interface.writeAll(",\"message\":\"") catch return;
            stderr.interface.writeAll(message) catch return;
            stderr.interface.writeAll("\"") catch return;

            stderr.interface.writeAll("}\n") catch return;
            stderr.interface.flush() catch return;
        }
    }
};

pub fn main() !void {
    // Simulate HTTP request handling
    const ctx = LogContext{
        .correlation_id = "req-12345-abcde",
        .user_id = 42,
        .request_path = "/api/users/42",
    };

    ctx.logInfo("Request started", .{});
    ctx.logInfo("Querying database for user {d}", .{42});
    ctx.logInfo("Request completed in {d}ms", .{123});
}