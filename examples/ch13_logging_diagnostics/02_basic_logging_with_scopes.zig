// Example 2: Basic Logging with Scopes
// 13 Logging Diagnostics
//
// Extracted from chapter content.md

const std = @import("std");
const database = @import("database.zig");
const network = @import("network.zig");

pub fn main() !void {
    const log = std.log;

    // Default scope logging
    log.info("Application started", .{});
    log.debug("Debug mode enabled", .{});

    const port: u16 = 8080;
    log.info("Server listening on port {d}", .{port});

    // Demonstrate all log levels
    log.err("This is an error message", .{});
    log.warn("This is a warning message", .{});
    log.info("This is an info message", .{});
    log.debug("This is a debug message", .{});

    // Use scoped logging from other modules
    try database.connect();
    try database.query("SELECT * FROM users");

    try network.sendRequest("https://api.example.com/data");

    log.info("Application shutting down", .{});
}