// Example 1: Basic Error Sets and Propagation
// 06 Error Handling
//
// Extracted from chapter content.md

const std = @import("std");

// Define custom error sets
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};

const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

// Error sets can be merged
const AllErrors = FileError || ParseError;

// Function returning explicit error union
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
    std.debug.print("File opened: {s}\n", .{path});
}

// Function with inferred error set
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}

pub fn main() !void {
    // Using try - propagates error if it occurs
    try openFile("/valid/path");

    // Using catch - provides default behavior on error
    openFile("/forbidden") catch {
        std.debug.print("Access denied, using default behavior\n", .{});
    };

    // Capturing the error value
    openFile("/missing") catch |err| {
        std.debug.print("Error occurred: {s}\n", .{@errorName(err)});
    };

    // Merged error sets
    const merged_fn = struct {
        fn process() AllErrors!void {
            try openFile("/valid");
            _ = try parseData("[1]");
        }
    }.process;
    try merged_fn();
}