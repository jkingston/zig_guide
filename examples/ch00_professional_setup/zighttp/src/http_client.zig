const std = @import("std");
const args_mod = @import("args.zig");
const Args = args_mod.Args;
const Method = args_mod.Method;

/// HTTP response structure
pub const Response = struct {
    status_code: u16,
    body: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Response) void {
        self.allocator.free(self.body);
    }
};

/// Make an HTTP request with the given arguments
pub fn request(allocator: std.mem.Allocator, request_args: Args) !Response {
    // Parse the URL
    const uri = try std.Uri.parse(request_args.url);

    // Create HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Prepare request
    const method: std.http.Method = switch (request_args.method) {
        .GET => .GET,
        .POST => .POST,
        .PUT => .PUT,
        .DELETE => .DELETE,
    };

    // Build request headers
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("User-Agent", "zighttp/0.1.0");
    try headers.append("Accept", "*/*");

    // Create server header buffer
    var server_header_buffer: [8192]u8 = undefined;

    // Make request
    var req = try client.open(method, uri, .{
        .server_header_buffer = &server_header_buffer,
        .headers = headers,
    });
    defer req.deinit();

    // Send request
    try req.send();

    // Add body if provided (for POST, PUT)
    if (request_args.body) |body| {
        try req.writeAll(body);
    }

    try req.finish();
    try req.wait();

    // Read response
    const status_code = @intFromEnum(req.response.status);

    // Read all response body
    var response_body = std.ArrayList(u8).init(allocator);
    defer response_body.deinit();

    var buf: [4096]u8 = undefined;
    while (true) {
        const bytes_read = try req.readAll(&buf);
        if (bytes_read == 0) break;
        try response_body.appendSlice(buf[0..bytes_read]);
    }

    return Response{
        .status_code = @intCast(status_code),
        .body = try response_body.toOwnedSlice(),
        .allocator = allocator,
    };
}

// Unit tests
test "response structure" {
    const allocator = std.testing.allocator;

    const body = try allocator.dupe(u8, "test body");
    var response = Response{
        .status_code = 200,
        .body = body,
        .allocator = allocator,
    };
    defer response.deinit();

    try std.testing.expectEqual(@as(u16, 200), response.status_code);
    try std.testing.expectEqualStrings("test body", response.body);
}
