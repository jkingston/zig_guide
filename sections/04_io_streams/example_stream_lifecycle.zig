// Stream Lifecycle Management Example
// Demonstrates: defer, errdefer, ownership, cleanup patterns

const std = @import("std");

// Helper function showing proper file handle lifecycle
fn processFile(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close(); // Ensures file is always closed

    return try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
}

// Function with multiple resources and error paths
fn complexOperation(allocator: std.mem.Allocator) !void {
    // Create first file
    const file1 = try std.fs.cwd().createFile("file1.txt", .{});
    errdefer file1.close(); // Close if subsequent operations fail

    var file1_writer = file1.writer(&.{});
    try file1_writer.writeAll("Content for file 1\n");

    // Create second file
    const file2 = try std.fs.cwd().createFile("file2.txt", .{});
    errdefer file2.close(); // Close if subsequent operations fail

    var file2_writer = file2.writer(&.{});
    try file2_writer.writeAll("Content for file 2\n");

    // Allocate buffer
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Free if subsequent operations fail

    // Do work...
    _ = buffer;

    // Success path: clean up in reverse order
    allocator.free(buffer);
    file2.close();
    file1.close();
}

// Arena pattern for bulk cleanup
fn arenaPattern() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // All allocations freed at once

    const allocator = arena.allocator();

    // Create temporary file
    const file = try std.fs.cwd().createFile("temp_arena.txt", .{});
    defer file.close();

    var buf: [256]u8 = undefined;
    var file_writer = file.writer(&buf);

    // Multiple allocations - all cleaned up by arena
    for (0..10) |i| {
        const line = try std.fmt.allocPrint(allocator, "Line {d}\n", .{i});
        try file_writer.writeAll(line);
        // No need to free 'line' - arena handles it
    }

    try file_writer.interface.flush();
}

// Proper ownership transfer pattern
const FileBuffer = struct {
    file: std.fs.File,
    buffer: []u8,
    allocator: std.mem.Allocator,

    pub fn init(path: []const u8, allocator: std.mem.Allocator) !FileBuffer {
        const file = try std.fs.cwd().openFile(path, .{});
        errdefer file.close();

        const buffer = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
        errdefer allocator.free(buffer);

        return FileBuffer{
            .file = file,
            .buffer = buffer,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FileBuffer) void {
        self.allocator.free(self.buffer);
        self.file.close();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Simple defer pattern
    {
        const file = try std.fs.cwd().createFile("simple.txt", .{});
        defer file.close();

        var file_writer = file.writer(&.{});
        try file_writer.writeAll("Hello, World!\n");
    }

    // 2. Complex operation with multiple resources
    try complexOperation(allocator);

    // 3. Arena allocator pattern
    try arenaPattern();

    // 4. Ownership transfer pattern
    {
        // Create test file first
        {
            const file = try std.fs.cwd().createFile("ownership.txt", .{});
            defer file.close();
            var file_writer = file.writer(&.{});
            try file_writer.writeAll("Ownership test content\n");
        }

        var fb = try FileBuffer.init("ownership.txt", allocator);
        defer fb.deinit();

        std.debug.print("Loaded: {s}", .{fb.buffer});
    }

    // Cleanup
    std.fs.cwd().deleteFile("file1.txt") catch {};
    std.fs.cwd().deleteFile("file2.txt") catch {};
    std.fs.cwd().deleteFile("simple.txt") catch {};
    std.fs.cwd().deleteFile("temp_arena.txt") catch {};
    std.fs.cwd().deleteFile("ownership.txt") catch {};
}
