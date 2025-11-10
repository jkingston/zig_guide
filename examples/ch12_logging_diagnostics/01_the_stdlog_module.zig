// Example 1: The std.log Module
// 13 Logging Diagnostics
//
// Extracted from chapter content.md

const std = @import("std");
const log = std.log;

pub fn main() void {
    log.err("Error: critical failure", .{});
    log.warn("Warning: approaching limit", .{});
    log.info("Info: request completed", .{});
    log.debug("Debug: cache hit", .{});
}