const std = @import("std");
const clap = @import("clap");

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

    /// Parse command-line arguments using zig-clap
    pub fn parse(allocator: std.mem.Allocator) !Args {
        // Define CLI parameters at compile time
        const params = comptime clap.parseParamsComptime(
            \\-h, --help             Display this help and exit.
            \\-X, --method <STR>     HTTP method (GET, POST, PUT, DELETE)
            \\-d, --data <STR>       Request body data
            \\    --no-pretty        Disable JSON pretty-printing
            \\<STR>                  URL to request
            \\
        );

        // Parse arguments with diagnostic support
        var diag = clap.Diagnostic{};
        var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
            .diagnostic = &diag,
            .allocator = allocator,
        }) catch |err| {
            diag.report(std.io.getStdErr().writer(), err) catch {};
            return error.InvalidArguments;
        };
        defer res.deinit();

        // Show help if requested
        if (res.args.help != 0) {
            return error.ShowHelp;
        }

        // Extract URL (required positional argument)
        if (res.positionals.len == 0) {
            return error.MissingUrl;
        }

        var result = Args{
            .url = try allocator.dupe(u8, res.positionals[0]),
            .pretty = res.args.@"no-pretty" == 0,
        };

        // Parse method if provided
        if (res.args.method) |method_str| {
            result.method = try Method.fromString(method_str);
        }

        // Copy body if provided
        if (res.args.data) |data| {
            result.body = try allocator.dupe(u8, data);
        }

        return result;
    }

    /// Free allocated memory
    pub fn deinit(self: Args, allocator: std.mem.Allocator) void {
        allocator.free(self.url);
        if (self.body) |body| {
            allocator.free(body);
        }
    }
};

// Unit tests
test "method from string" {
    try std.testing.expectEqual(Method.GET, try Method.fromString("GET"));
    try std.testing.expectEqual(Method.POST, try Method.fromString("POST"));
    try std.testing.expectEqual(Method.PUT, try Method.fromString("PUT"));
    try std.testing.expectEqual(Method.DELETE, try Method.fromString("DELETE"));
    try std.testing.expectError(error.InvalidMethod, Method.fromString("INVALID"));
}
