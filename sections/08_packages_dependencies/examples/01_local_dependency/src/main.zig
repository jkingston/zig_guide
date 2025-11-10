const std = @import("std");
const mylib = @import("mylib");

pub fn main() void {
    std.debug.print("App version: {s}\n", .{mylib.version});
    std.debug.print("Result: {}\n", .{mylib.add(10, 32)});
}
