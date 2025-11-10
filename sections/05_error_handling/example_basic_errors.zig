const std = @import("std");

// Define a custom error set
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};

const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

// Error sets can be merged using ||
const AllErrors = FileError || ParseError;

// Function returning an error union
fn openFile(path: []const u8) FileError!void {
    if (std.mem.eql(u8, path, "")) {
        return error.InvalidFormat;
    }
    if (std.mem.eql(u8, path, "/forbidden")) {
        return error.AccessDenied;
    }
    if (std.mem.eql(u8, path, "/missing")) {
        return error.NotFound;
    }
    // Success case - no error
    std.debug.print("File opened: {s}\n", .{path});
}

// Function with inferred error set (using !)
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) {
        return error.UnexpectedEOF;
    }
    if (data[0] != '[') {
        return error.InvalidSyntax;
    }
    return 42;
}

pub fn main() !void {
    // Using try - propagates error if it occurs
    try openFile("/valid/path");

    // Using catch - provides default value on error
    const result1 = openFile("/forbidden") catch {
        std.debug.print("Access denied, using default behavior\n", .{});
    };
    _ = result1;

    // Capturing the error value with catch |err|
    openFile("/missing") catch |err| {
        std.debug.print("Error occurred: {s}\n", .{@errorName(err)});
    };

    // Error union can hold either error or value
    const value: FileError!u32 = 100;
    const unwrapped = value catch 0;
    std.debug.print("Unwrapped value: {d}\n", .{unwrapped});

    // Parsing with inferred error set
    const parsed = try parseData("[data]");
    std.debug.print("Parsed value: {d}\n", .{parsed});

    // Merged error sets
    const merged_fn = struct {
        fn process() AllErrors!void {
            try openFile("/valid");
            _ = try parseData("[1]");
        }
    }.process;
    try merged_fn();
}
