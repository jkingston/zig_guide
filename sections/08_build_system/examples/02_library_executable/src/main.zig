const std = @import("std");
const mathlib = @import("mathlib");

pub fn main() void {
    const a: i32 = 10;
    const b: i32 = 5;

    const sum = mathlib.add(a, b);
    const product = mathlib.multiply(a, b);

    std.debug.print("add({}, {}) = {}\n", .{ a, b, sum });
    std.debug.print("multiply({}, {}) = {}\n", .{ a, b, product });
}
