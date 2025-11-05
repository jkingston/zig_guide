// Unit tests for database.zig
// This file demonstrates comprehensive testing of a single module

const std = @import("std");
const Database = @import("database").Database;
const DatabaseError = @import("database").DatabaseError;
const helpers = @import("test_helpers");

// Use test_helpers for common utilities
const expectDatabaseCount = helpers.expectDatabaseCount;
const expectKeyExists = helpers.expectKeyExists;
const expectKeyNotExists = helpers.expectKeyNotExists;

// ============================================================================
// Basic Operations Tests
// ============================================================================

test "Database: init and deinit" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try expectDatabaseCount(&db, 0);
}

test "Database: insert single entry" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("key1", "value1");

    try expectDatabaseCount(&db, 1);
    try expectKeyExists(&db, "key1");
}

test "Database: insert multiple entries" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("key1", "value1");
    try db.insert("key2", "value2");
    try db.insert("key3", "value3");

    try expectDatabaseCount(&db, 3);
    try expectKeyExists(&db, "key1");
    try expectKeyExists(&db, "key2");
    try expectKeyExists(&db, "key3");
}

test "Database: insert returns DuplicateKey error" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("duplicate", "first");

    const result = db.insert("duplicate", "second");
    try std.testing.expectError(DatabaseError.DuplicateKey, result);

    // Verify original value is unchanged
    const value = try db.get("duplicate");
    try std.testing.expectEqualStrings("first", value);
}

test "Database: get existing entry" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("greeting", "Hello, World!");

    const value = try db.get("greeting");
    try std.testing.expectEqualStrings("Hello, World!", value);
}

test "Database: get returns KeyNotFound error" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    const result = db.get("nonexistent");
    try std.testing.expectError(DatabaseError.KeyNotFound, result);
}

test "Database: update existing entry" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("counter", "0");
    try db.update("counter", "1");

    const value = try db.get("counter");
    try std.testing.expectEqualStrings("1", value);
}

test "Database: update returns KeyNotFound error" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    const result = db.update("nonexistent", "value");
    try std.testing.expectError(DatabaseError.KeyNotFound, result);
}

test "Database: delete existing entry" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("temporary", "data");
    try expectKeyExists(&db, "temporary");

    try db.delete("temporary");

    try expectKeyNotExists(&db, "temporary");
    try expectDatabaseCount(&db, 0);
}

test "Database: delete returns KeyNotFound error" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    const result = db.delete("nonexistent");
    try std.testing.expectError(DatabaseError.KeyNotFound, result);
}

test "Database: exists returns true for existing key" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("present", "value");

    try std.testing.expect(db.exists("present"));
}

test "Database: exists returns false for missing key" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try std.testing.expect(!db.exists("absent"));
}

// ============================================================================
// State Management Tests
// ============================================================================

test "Database: count tracks entries correctly" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try expectDatabaseCount(&db, 0);

    try db.insert("a", "1");
    try expectDatabaseCount(&db, 1);

    try db.insert("b", "2");
    try expectDatabaseCount(&db, 2);

    try db.delete("a");
    try expectDatabaseCount(&db, 1);

    try db.delete("b");
    try expectDatabaseCount(&db, 0);
}

test "Database: clear removes all entries" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("key1", "value1");
    try db.insert("key2", "value2");
    try db.insert("key3", "value3");

    try expectDatabaseCount(&db, 3);

    db.clear();

    try expectDatabaseCount(&db, 0);
    try expectKeyNotExists(&db, "key1");
    try expectKeyNotExists(&db, "key2");
    try expectKeyNotExists(&db, "key3");
}

// ============================================================================
// Data Integrity Tests
// ============================================================================

test "Database: stores independent copies of keys and values" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var buffer: [100]u8 = undefined;

    // Use a mutable buffer for the key
    const key = try std.fmt.bufPrint(&buffer, "key", .{});

    // Insert with the buffer
    try db.insert(key, "original");

    // Modify the buffer
    @memcpy(buffer[0..3], "new");

    // Original key should still be accessible
    const value = try db.get("key");
    try std.testing.expectEqualStrings("original", value);
}

test "Database: handles empty keys and values" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    try db.insert("", "empty_key");
    try db.insert("empty_value", "");

    const value1 = try db.get("");
    try std.testing.expectEqualStrings("empty_key", value1);

    const value2 = try db.get("empty_value");
    try std.testing.expectEqualStrings("", value2);
}

test "Database: handles special characters in keys and values" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    const special_key = "key:with:colons";
    const special_value = "value\nwith\nnewlines";

    try db.insert(special_key, special_value);

    const retrieved = try db.get(special_key);
    try std.testing.expectEqualStrings(special_value, retrieved);
}

// ============================================================================
// Fixture Pattern Example
// ============================================================================

test "Database: using test fixture helper" {
    // This demonstrates using the fixture helper from test_helpers.zig
    try helpers.withTestDatabase(struct {
        fn testFn(db: *Database) !void {
            try expectDatabaseCount(db, 0);

            try db.insert("fixture_test", "value");
            try expectKeyExists(db, "fixture_test");
        }
    }.testFn);
    // Database is automatically cleaned up
}

// ============================================================================
// Complex Workflow Tests
// ============================================================================

test "Database: insert, update, delete workflow" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    // Create
    try db.insert("user:1", "Alice");
    try std.testing.expectEqualStrings("Alice", try db.get("user:1"));

    // Update
    try db.update("user:1", "Alice Smith");
    try std.testing.expectEqualStrings("Alice Smith", try db.get("user:1"));

    // Delete
    try db.delete("user:1");
    try expectKeyNotExists(&db, "user:1");
}

test "Database: multiple operations maintain consistency" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    // Insert multiple entries
    for (0..10) |i| {
        const key = try helpers.makeTestKey(std.testing.allocator, "key", i);
        defer std.testing.allocator.free(key);

        const value = try helpers.makeTestKey(std.testing.allocator, "value", i);
        defer std.testing.allocator.free(value);

        try db.insert(key, value);
    }

    try expectDatabaseCount(&db, 10);

    // Delete every other entry
    for (0..10) |i| {
        if (i % 2 == 0) {
            const key = try helpers.makeTestKey(std.testing.allocator, "key", i);
            defer std.testing.allocator.free(key);

            try db.delete(key);
        }
    }

    try expectDatabaseCount(&db, 5);

    // Verify remaining entries
    for (0..10) |i| {
        const key = try helpers.makeTestKey(std.testing.allocator, "key", i);
        defer std.testing.allocator.free(key);

        if (i % 2 == 0) {
            try expectKeyNotExists(&db, key);
        } else {
            try expectKeyExists(&db, key);
        }
    }
}
