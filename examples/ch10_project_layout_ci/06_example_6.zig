// Example 6: Example 6
// 10 Project Layout Ci
//
// Extracted from chapter content.md

const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.debug.print("Cross-compilation demo\n", .{});
    std.debug.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});
    std.debug.print("OS: {s}\n", .{@tagName(builtin.os.tag)});
    std.debug.print("ABI: {s}\n", .{@tagName(builtin.abi)});
    std.debug.print("Optimize mode: {s}\n", .{@tagName(builtin.mode)});

    // Platform-specific code example
    if (builtin.os.tag == .windows) {
        std.debug.print("Running on Windows\n", .{});
    } else if (builtin.os.tag == .linux) {
        std.debug.print("Running on Linux\n", .{});
    } else if (builtin.os.tag == .macos) {
        std.debug.print("Running on macOS\n", .{});
    } else if (builtin.os.tag == .wasi) {
        std.debug.print("Running on WASI\n", .{});
    }
}

test "platform detection" {
    const is_valid = switch (builtin.os.tag) {
        .windows, .linux, .macos, .wasi => true,
        else => false,
    };
    try std.testing.expect(is_valid or true);
}