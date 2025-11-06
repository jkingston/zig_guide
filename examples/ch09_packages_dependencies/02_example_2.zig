// Example 2: Example 2
// 09 Packages Dependencies
//
// Extracted from chapter content.md

// src/main.zig
const std = @import("std");
const build_options = @import("build_options");
const basic_math = @import("basic_math");

pub fn main() void {
    std.debug.print("Basic: add(10, 5) = {}\n", .{basic_math.add(10, 5)});

    if (build_options.advanced_enabled) {
        const advanced_math = @import("advanced_math");
        std.debug.print("Advanced: pow(2, 8) = {}\n", .{advanced_math.pow(2, 8)});
    } else {
        std.debug.print("Advanced features disabled (use -Dadvanced=true)\n", .{});
    }
}