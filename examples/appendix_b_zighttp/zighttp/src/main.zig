const std = @import("std");
const args = @import("args.zig");
const http_client = @import("http_client.zig");
const json_formatter = @import("json_formatter.zig");

const version = "0.1.0";

fn printHelp() void {
    const help_text =
        \\zighttp v{s} - Simple HTTP client CLI
        \\
        \\Usage: zighttp [options] <url>
        \\
        \\Options:
        \\  -X, --method <METHOD>    HTTP method (GET, POST, PUT, DELETE) [default: GET]
        \\  -d, --data <DATA>        Request body data
        \\  --no-pretty              Disable JSON pretty-printing
        \\  -h, --help               Show this help message
        \\
        \\Examples:
        \\  zighttp https://api.github.com/users/ziglang
        \\  zighttp -X POST https://httpbin.org/post -d '{{"key":"value"}}'
        \\
    ;
    std.debug.print(help_text, .{version});
}

fn printError(err: anyerror) void {
    if (err == error.ShowHelp) {
        printHelp();
        return;
    }

    const msg = switch (err) {
        error.MissingUrl => "Error: Missing URL argument. Use -h for help.",
        error.InvalidMethod => "Error: Invalid HTTP method. Use GET, POST, PUT, or DELETE.",
        else => null,
    };

    if (msg) |message| {
        std.debug.print("{s}\n", .{message});
    } else {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
    }
}

pub fn main() !void {
    // Set up allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // Parse arguments
    const parsed_args = args.Args.parse(allocator) catch |err| {
        printError(err);
        std.process.exit(1);
    };
    defer parsed_args.deinit(allocator);

    // Make HTTP request
    var response = http_client.request(allocator, parsed_args) catch |err| {
        std.debug.print("HTTP request failed: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer response.deinit();

    // Get stdout
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Print status
    try stdout.print("HTTP {d}\n", .{response.status_code});
    try stdout.writeAll("---\n");

    // Format and print body
    if (parsed_args.pretty and json_formatter.isJson(response.body)) {
        const formatted = json_formatter.format(allocator, response.body) catch response.body;
        defer if (formatted.ptr != response.body.ptr) allocator.free(formatted);
        try stdout.writeAll(formatted);
    } else {
        try stdout.writeAll(response.body);
    }

    try stdout.writeAll("\n");
}
