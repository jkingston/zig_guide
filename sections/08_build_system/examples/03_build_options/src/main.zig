const std = @import("std");
const build_options = @import("build_options");

pub fn main() void {
    std.debug.print("Server version: {s}\n", .{build_options.version});
    std.debug.print("Max connections: {}\n", .{build_options.max_connections});

    if (build_options.enable_logging) {
        std.debug.print("[DEBUG] Logging enabled\n", .{});
        std.debug.print("[DEBUG] Starting server...\n", .{});
    }

    std.debug.print("Server started successfully\n", .{});
}
