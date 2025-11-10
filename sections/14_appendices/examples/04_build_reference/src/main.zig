const std = @import("std");
const config = @import("config");

pub fn main() !void {
    std.debug.print("Build config demo\n", .{});
    std.debug.print("Version: {s}\n", .{config.version});
    std.debug.print("Logging: {}\n", .{config.enable_logging});
}
