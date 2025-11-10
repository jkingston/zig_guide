// Example 2: Example 2
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

pub const Result = struct {
    rows: []const []const u8,
};

pub const Database = struct {
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Database {
        const data = try allocator.alloc(u8, 1024);
        return Database{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        self.allocator.free(self.data);
    }

    pub fn query(self: *Database, sql: []const u8) !Result {
        _ = self;
        _ = sql;
        // Mock implementation
        const rows = &[_][]const u8{"row1"};
        return Result{ .rows = rows };
    }

    // Test-only helper - not compiled in release builds
    pub fn seedTestData(self: *Database) !void {
        if (!builtin.is_test) @compileError("seedTestData is test-only");
        _ = self;
        // Insert test fixtures
    }
};

test "database with test data" {
    var db = try Database.init(testing.allocator);
    defer db.deinit();

    try db.seedTestData(); // OK in tests

    const result = try db.query("SELECT * FROM users");
    try testing.expect(result.rows.len > 0);
}