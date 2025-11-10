const std = @import("std");
const build_options = @import("build_options");
const basic_math = @import("basic_math");

pub fn main() void {
    std.debug.print("Basic features:\n", .{});
    std.debug.print("  add(10, 5) = {}\n", .{basic_math.add(10, 5)});
    std.debug.print("  mul(10, 5) = {}\n", .{basic_math.mul(10, 5)});

    if (build_options.advanced_enabled) {
        const advanced_math = @import("advanced_math");
        std.debug.print("\nAdvanced features enabled:\n", .{});
        std.debug.print("  pow(2, 8) = {}\n", .{advanced_math.pow(2, 8)});
        std.debug.print("  factorial(5) = {}\n", .{advanced_math.factorial(5)});
    } else {
        std.debug.print("\nAdvanced features disabled (use -Dadvanced=true)\n", .{});
    }
}
