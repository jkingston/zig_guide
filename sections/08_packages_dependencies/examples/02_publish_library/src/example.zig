const std = @import("std");
const mathlib = @import("mathlib");

pub fn main() void {
    std.debug.print("mathlib version: {s}\n", .{mathlib.version});
    std.debug.print("add(10, 5) = {}\n", .{mathlib.add(10, 5)});
    std.debug.print("sub(10, 5) = {}\n", .{mathlib.sub(10, 5)});
    std.debug.print("mul(10, 5) = {}\n", .{mathlib.mul(10, 5)});
    std.debug.print("div(10, 5) = {}\n", .{mathlib.div(10, 5)});
}
