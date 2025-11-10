// Example 1: Example 1
// 08 Build System
//
// Extracted from chapter content.md

const std = @import("std");
const build_options = @import("build_options");

pub fn main() void {
    if (build_options.enable_logging) {
        std.log.info("Version: {s}", .{build_options.version});
    }
}