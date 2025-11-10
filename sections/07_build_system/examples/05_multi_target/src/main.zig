const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.debug.print("Platform: {s}-{s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
    });

    std.debug.print("Multi-target build example\n", .{});
}
