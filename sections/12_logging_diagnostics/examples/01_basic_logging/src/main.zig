const std = @import("std");
const database = @import("database.zig");
const network = @import("network.zig");

pub fn main() !void {
    const log = std.log;

    // Default scope logging - all log levels
    log.info("Application started", .{});
    log.debug("Debug mode enabled", .{});

    // With formatted values
    const port: u16 = 8080;
    log.info("Server listening on port {d}", .{port});

    // Demonstrate different log levels
    log.err("This is an error message - something went wrong", .{});
    log.warn("This is a warning - potential issue detected", .{});
    log.info("This is an info message - general state info", .{});
    log.debug("This is a debug message - detailed diagnostics", .{});

    // Call other modules which use scoped logging
    try database.connect();
    try database.query("SELECT * FROM users");

    try network.sendRequest("https://api.example.com/data");

    // Simulate warning condition
    const memory_usage: f32 = 85.5;
    if (memory_usage > 80.0) {
        log.warn("Memory usage high: {d:.1}%", .{memory_usage});
    }

    // Simulate error
    const result = database.query("INVALID SQL");
    if (result) |_| {
        log.info("Query succeeded", .{});
    } else |err| {
        log.err("Query failed: {s}", .{@errorName(err)});
    }

    log.info("Application shutting down", .{});
}
