const std = @import("std");
const generated = @import("generated");

pub fn main() void {
    std.debug.print("Magic number: {}\n", .{generated.magic_number});
    std.debug.print("Message: {s}\n", .{generated.getMessage()});
}
