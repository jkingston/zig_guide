// Shared test utilities and fixtures for the test suite
// This module demonstrates the test fixture pattern and reusable test infrastructure

const std = @import("std");
const Database = @import("database").Database;
const ApiServer = @import("api").ApiServer;
const User = @import("api").User;

/// Test context that holds common test state
/// This implements the fixture pattern for setup/teardown
pub const TestContext = struct {
    allocator: std.mem.Allocator,
    db: Database,
    api: ApiServer,

    /// Setup a fresh test context
    /// Each test should create its own context for isolation
    /// Note: The api field will point to db, so the context must not be moved after init
    pub fn init(allocator: std.mem.Allocator) TestContext {
        return .{
            .allocator = allocator,
            .db = Database.init(allocator),
            .api = undefined, // Will be set in setup()
        };
    }

    /// Setup the API after the context is in its final location
    /// This must be called after init() because api holds a pointer to db
    pub fn setup(self: *TestContext) void {
        self.api = ApiServer.init(self.allocator, &self.db);
    }

    /// Clean up test context resources
    pub fn deinit(self: *TestContext) void {
        self.db.deinit();
    }
};

/// Create a test database with some initial data
pub fn createTestDatabase(allocator: std.mem.Allocator) !Database {
    var db = Database.init(allocator);
    errdefer db.deinit();

    try db.insert("key1", "value1");
    try db.insert("key2", "value2");
    try db.insert("key3", "value3");

    return db;
}

/// Create test users with predefined data
pub const TestUsers = struct {
    pub const alice = User{
        .id = "alice_123",
        .name = "Alice Test",
        .email = "alice@test.com",
    };

    pub const bob = User{
        .id = "bob_456",
        .name = "Bob Test",
        .email = "bob@test.com",
    };

    pub const charlie = User{
        .id = "charlie_789",
        .name = "Charlie Test",
        .email = "charlie@test.com",
    };

    pub const diana = User{
        .id = "diana_012",
        .name = "Diana Test",
        .email = "diana@test.com",
    };
};

/// Populate a database with test user data
pub fn populateTestUsers(api: *ApiServer) !void {
    try api.createUser(TestUsers.alice);
    try api.createUser(TestUsers.bob);
    try api.createUser(TestUsers.charlie);
}

/// Helper to verify a user matches expected values
pub fn expectUser(actual: User, expected: User) !void {
    try std.testing.expectEqualStrings(expected.id, actual.id);
    try std.testing.expectEqualStrings(expected.name, actual.name);
    try std.testing.expectEqualStrings(expected.email, actual.email);
}

/// Helper to verify database contains expected number of entries
pub fn expectDatabaseCount(db: *Database, expected: usize) !void {
    const actual = db.count();
    if (actual != expected) {
        std.debug.print("Expected {} entries, found {}\n", .{ expected, actual });
        return error.TestExpectedEqual;
    }
}

/// Helper to verify a key exists in the database
pub fn expectKeyExists(db: *Database, key: []const u8) !void {
    if (!db.exists(key)) {
        std.debug.print("Expected key '{s}' to exist\n", .{key});
        return error.TestExpectedEqual;
    }
}

/// Helper to verify a key does NOT exist in the database
pub fn expectKeyNotExists(db: *Database, key: []const u8) !void {
    if (db.exists(key)) {
        std.debug.print("Expected key '{s}' to NOT exist\n", .{key});
        return error.TestExpectedEqual;
    }
}

/// Helper to create a temporary test database, run a test, and clean up
/// This demonstrates a fixture function pattern
pub fn withTestDatabase(
    comptime testFn: fn (*Database) anyerror!void,
) !void {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try testFn(&db);
}

/// Helper to create a temporary test API server, run a test, and clean up
pub fn withTestApi(
    comptime testFn: fn (*ApiServer, *Database) anyerror!void,
) !void {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);
    try testFn(&api, &db);
}

/// Generate a unique test key with a prefix
/// Useful for tests that need unique identifiers
pub fn makeTestKey(allocator: std.mem.Allocator, prefix: []const u8, suffix: usize) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}_{}", .{ prefix, suffix });
}

/// Helper to verify two strings are equal with better error messages
pub fn expectStringEqual(expected: []const u8, actual: []const u8) !void {
    if (!std.mem.eql(u8, expected, actual)) {
        std.debug.print("\nExpected: '{s}'\nActual:   '{s}'\n", .{ expected, actual });
        return error.TestExpectedEqual;
    }
}
