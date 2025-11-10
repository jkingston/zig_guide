const std = @import("std");

/// zighttp library - Simple HTTP client for Zig
///
/// This library provides a simple interface for making HTTP requests
/// and formatting JSON responses.
///
/// Example usage:
/// ```zig
/// const zighttp = @import("zighttp");
///
/// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
/// defer _ = gpa.deinit();
/// const allocator = gpa.allocator();
///
/// const request_args = zighttp.Args{
///     .url = "https://api.github.com/users/ziglang",
///     .method = .GET,
/// };
///
/// var response = try zighttp.request(allocator, request_args);
/// defer response.deinit();
/// ```

// Re-export public modules
pub const args = @import("args.zig");
pub const http_client = @import("http_client.zig");
pub const json_formatter = @import("json_formatter.zig");

// Re-export common types for convenience
pub const Args = args.Args;
pub const Method = args.Method;
pub const Response = http_client.Response;
pub const request = http_client.request;
pub const formatJson = json_formatter.format;
pub const isJson = json_formatter.isJson;

// Tests
test "import all modules" {
    const testing = std.testing;
    _ = testing;
    _ = args;
    _ = http_client;
    _ = json_formatter;
}

// Run all module tests
test {
    @import("std").testing.refAllDecls(@This());
}
