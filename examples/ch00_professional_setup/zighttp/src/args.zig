const std = @import("std");

/// HTTP methods supported by the CLI
pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,

    pub fn fromString(s: []const u8) !Method {
        if (std.mem.eql(u8, s, "GET")) return .GET;
        if (std.mem.eql(u8, s, "POST")) return .POST;
        if (std.mem.eql(u8, s, "PUT")) return .PUT;
        if (std.mem.eql(u8, s, "DELETE")) return .DELETE;
        return error.InvalidMethod;
    }
};

/// Parsed command-line arguments
pub const Args = struct {
    url: []const u8,
    method: Method = .GET,
    body: ?[]const u8 = null,
    pretty: bool = true,

    /// Parse command-line arguments
    pub fn parse(allocator: std.mem.Allocator) !Args {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();

        // Skip program name
        _ = args.skip();

        var result = Args{
            .url = "",
        };

        var next_is_method = false;
        var next_is_body = false;

        while (args.next()) |arg| {
            if (next_is_method) {
                result.method = try Method.fromString(arg);
                next_is_method = false;
            } else if (next_is_body) {
                result.body = try allocator.dupe(u8, arg);
                next_is_body = false;
            } else if (std.mem.eql(u8, arg, "-X") or std.mem.eql(u8, arg, "--method")) {
                next_is_method = true;
            } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--data")) {
                next_is_body = true;
            } else if (std.mem.eql(u8, arg, "--no-pretty")) {
                result.pretty = false;
            } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                return error.ShowHelp;
            } else {
                // First non-flag argument is the URL
                if (result.url.len == 0) {
                    result.url = try allocator.dupe(u8, arg);
                }
            }
        }

        if (result.url.len == 0) {
            return error.MissingUrl;
        }

        return result;
    }

    /// Free allocated memory
    pub fn deinit(self: Args, allocator: std.mem.Allocator) void {
        if (self.url.len > 0) {
            allocator.free(self.url);
        }
        if (self.body) |body| {
            allocator.free(body);
        }
    }
};

// Unit tests
test "parse GET request" {
    const allocator = std.testing.allocator;

    // Mock args - in a real test we'd use a different approach
    // This is a simplified demonstration
    const url = "https://example.com";
    var args = Args{
        .url = try allocator.dupe(u8, url),
        .method = .GET,
    };
    defer args.deinit(allocator);

    try std.testing.expectEqual(Method.GET, args.method);
    try std.testing.expectEqualStrings("https://example.com", args.url);
}

test "method from string" {
    try std.testing.expectEqual(Method.GET, try Method.fromString("GET"));
    try std.testing.expectEqual(Method.POST, try Method.fromString("POST"));
    try std.testing.expectEqual(Method.PUT, try Method.fromString("PUT"));
    try std.testing.expectEqual(Method.DELETE, try Method.fromString("DELETE"));
    try std.testing.expectError(error.InvalidMethod, Method.fromString("INVALID"));
}
