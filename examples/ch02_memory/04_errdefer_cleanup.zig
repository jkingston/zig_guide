// Example: Error-Path Cleanup with errdefer
// Chapter 3: Memory & Allocators
//
// Demonstrates cascading errdefer for multi-step initialization

const std = @import("std");

const Database = struct {
    connection: []u8,
    buffer: []u8,
    cache: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, conn_str: []const u8) !Database {
        const connection = try allocator.alloc(u8, conn_str.len);
        errdefer allocator.free(connection);
        @memcpy(connection, conn_str);

        const buffer = try allocator.alloc(u8, 1024);
        errdefer allocator.free(buffer);

        const cache = try allocator.alloc(u8, 2048);
        errdefer allocator.free(cache);

        if (conn_str.len > 100) {
            return error.ConnectionFailed; // Automatic cleanup via errdefer
        }

        return .{
            .connection = connection,
            .buffer = buffer,
            .cache = cache,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        self.allocator.free(self.cache);
        self.allocator.free(self.buffer);
        self.allocator.free(self.connection);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Success case
    {
        var db = try Database.init(allocator, "localhost:5432");
        defer db.deinit();
        std.debug.print("✅ Database initialized successfully\n", .{});
        std.debug.print("   Connection: {} bytes\n", .{db.connection.len});
        std.debug.print("   Buffer: {} bytes\n", .{db.buffer.len});
        std.debug.print("   Cache: {} bytes\n", .{db.cache.len});
    }

    // Failure case - connection string too long
    {
        const long_conn = "x" ** 101; // 101 characters
        const result = Database.init(allocator, long_conn);
        if (result) |_| {
            std.debug.print("❌ Should have failed\n", .{});
        } else |err| {
            std.debug.print("✅ Failed as expected: {}\n", .{err});
            std.debug.print("   All allocations automatically cleaned up via errdefer\n", .{});
        }
    }
}
