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

    // Prepare request method
    const method: std.http.Method = switch (request_args.method) {
        .GET => .GET,
        .POST => .POST,
        .PUT => .PUT,
        .DELETE => .DELETE,
    };

    // Build request headers
    const headers = &[_]std.http.Header{
        .{ .name = "User-Agent", .value = "zighttp/0.1.0" },
        .{ .name = "Accept", .value = "*/*" },
    };

    // Create writer for response
    var response_writer_obj = std.Io.Writer.Allocating.init(allocator);
    defer response_writer_obj.deinit();

    // Make request using fetch
    const fetch_result = try client.fetch(.{
        .method = method,
        .location = .{ .uri = uri },
        .extra_headers = headers,
        .payload = request_args.body,
        .response_writer = &response_writer_obj.writer,
    });

    // Get status code
    const status_code = @intFromEnum(fetch_result.status);

    return Response{
        .status_code = @intCast(status_code),
        .body = try response_writer_obj.toOwnedSlice(),
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
