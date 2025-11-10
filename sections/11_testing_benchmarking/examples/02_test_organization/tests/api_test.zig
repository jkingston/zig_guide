// Unit tests for api.zig
// This file demonstrates testing a module that depends on another module

const std = @import("std");
const Database = @import("database").Database;
const ApiServer = @import("api").ApiServer;
const ApiError = @import("api").ApiError;
const User = @import("api").User;
const helpers = @import("test_helpers");

// Import test utilities
const TestUsers = helpers.TestUsers;
const populateTestUsers = helpers.populateTestUsers;
const expectUser = helpers.expectUser;

// ============================================================================
// User Serialization Tests
// ============================================================================

test "User: serialize creates correct JSON-like format" {
    const user = TestUsers.alice;

    const serialized = try user.serialize(std.testing.allocator);
    defer std.testing.allocator.free(serialized);

    // Verify it contains expected fields
    try std.testing.expect(std.mem.indexOf(u8, serialized, "alice_123") != null);
    try std.testing.expect(std.mem.indexOf(u8, serialized, "Alice Test") != null);
    try std.testing.expect(std.mem.indexOf(u8, serialized, "alice@test.com") != null);
}

test "User: deserialize parses correct format" {
    const data = "{\"id\":\"user1\",\"name\":\"John Doe\",\"email\":\"john@example.com\"}";

    const user = try User.deserialize(data);

    try std.testing.expectEqualStrings("user1", user.id);
    try std.testing.expectEqualStrings("John Doe", user.name);
    try std.testing.expectEqualStrings("john@example.com", user.email);
}

test "User: deserialize returns error for invalid format" {
    const invalid_data = "incomplete:data";

    const result = User.deserialize(invalid_data);
    try std.testing.expectError(error.InvalidFormat, result);
}

// ============================================================================
// API Server Initialization Tests
// ============================================================================

test "ApiServer: init creates server with database" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    const api = ApiServer.init(std.testing.allocator, &db);

    try std.testing.expectEqual(0, api.getUserCount());
}

// ============================================================================
// User Creation Tests
// ============================================================================

test "ApiServer: createUser adds user to database" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.alice);

    try std.testing.expectEqual(1, api.getUserCount());
    try std.testing.expect(api.userExists(TestUsers.alice.id));
}

test "ApiServer: createUser returns error for duplicate user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.alice);

    const result = api.createUser(TestUsers.alice);
    try std.testing.expectError(ApiError.UserAlreadyExists, result);
}

test "ApiServer: createUser with multiple users" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.alice);
    try api.createUser(TestUsers.bob);
    try api.createUser(TestUsers.charlie);

    try std.testing.expectEqual(3, api.getUserCount());
}

// ============================================================================
// User Retrieval Tests
// ============================================================================

test "ApiServer: getUser returns correct user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.bob);

    const user = try api.getUser(TestUsers.bob.id);

    try expectUser(user, TestUsers.bob);
}

test "ApiServer: getUser returns error for nonexistent user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    const result = api.getUser("nonexistent_user");
    try std.testing.expectError(ApiError.UserNotFound, result);
}

test "ApiServer: getUser retrieves correct user from multiple" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try populateTestUsers(&api);

    const alice = try api.getUser(TestUsers.alice.id);
    try expectUser(alice, TestUsers.alice);

    const bob = try api.getUser(TestUsers.bob.id);
    try expectUser(bob, TestUsers.bob);

    const charlie = try api.getUser(TestUsers.charlie.id);
    try expectUser(charlie, TestUsers.charlie);
}

// ============================================================================
// User Update Tests
// ============================================================================

test "ApiServer: updateUser modifies existing user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.alice);

    const updated = User{
        .id = TestUsers.alice.id,
        .name = "Alice Updated",
        .email = "alice.updated@test.com",
    };

    try api.updateUser(updated);

    const retrieved = try api.getUser(TestUsers.alice.id);
    try expectUser(retrieved, updated);
}

test "ApiServer: updateUser returns error for nonexistent user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    const result = api.updateUser(TestUsers.diana);
    try std.testing.expectError(ApiError.UserNotFound, result);
}

// ============================================================================
// User Deletion Tests
// ============================================================================

test "ApiServer: deleteUser removes user from database" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.charlie);
    try std.testing.expectEqual(1, api.getUserCount());

    try api.deleteUser(TestUsers.charlie.id);

    try std.testing.expectEqual(0, api.getUserCount());
    try std.testing.expect(!api.userExists(TestUsers.charlie.id));
}

test "ApiServer: deleteUser returns error for nonexistent user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    const result = api.deleteUser("nonexistent_user");
    try std.testing.expectError(ApiError.UserNotFound, result);
}

test "ApiServer: deleteUser only removes specified user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try populateTestUsers(&api);
    try std.testing.expectEqual(3, api.getUserCount());

    try api.deleteUser(TestUsers.bob.id);

    try std.testing.expectEqual(2, api.getUserCount());
    try std.testing.expect(api.userExists(TestUsers.alice.id));
    try std.testing.expect(!api.userExists(TestUsers.bob.id));
    try std.testing.expect(api.userExists(TestUsers.charlie.id));
}

// ============================================================================
// User Existence Tests
// ============================================================================

test "ApiServer: userExists returns true for existing user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.diana);

    try std.testing.expect(api.userExists(TestUsers.diana.id));
}

test "ApiServer: userExists returns false for nonexistent user" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try std.testing.expect(!api.userExists("nobody"));
}

// ============================================================================
// Request Handling Tests
// ============================================================================

test "ApiServer: handleRequest processes create request" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    const request = ApiServer.Request{
        .request_type = .create,
        .user = TestUsers.alice,
    };

    const response = try api.handleRequest(request);

    try std.testing.expect(response.success);
    try std.testing.expectEqual(1, api.getUserCount());
}

test "ApiServer: handleRequest processes get request" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.bob);

    const request = ApiServer.Request{
        .request_type = .get,
        .user = User{
            .id = TestUsers.bob.id,
            .name = "",
            .email = "",
        },
    };

    const response = try api.handleRequest(request);

    try std.testing.expect(response.success);
    try std.testing.expect(response.user != null);
    if (response.user) |user| {
        try expectUser(user, TestUsers.bob);
    }
}

test "ApiServer: handleRequest processes update request" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.charlie);

    const updated = User{
        .id = TestUsers.charlie.id,
        .name = "Charlie Updated",
        .email = "charlie.updated@test.com",
    };

    const request = ApiServer.Request{
        .request_type = .update,
        .user = updated,
    };

    const response = try api.handleRequest(request);

    try std.testing.expect(response.success);

    const retrieved = try api.getUser(TestUsers.charlie.id);
    try expectUser(retrieved, updated);
}

test "ApiServer: handleRequest processes delete request" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.diana);

    const request = ApiServer.Request{
        .request_type = .delete,
        .user = User{
            .id = TestUsers.diana.id,
            .name = "",
            .email = "",
        },
    };

    const response = try api.handleRequest(request);

    try std.testing.expect(response.success);
    try std.testing.expectEqual(0, api.getUserCount());
}

test "ApiServer: handleRequest returns error response for failed create" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();

    var api = ApiServer.init(std.testing.allocator, &db);

    try api.createUser(TestUsers.alice);

    const request = ApiServer.Request{
        .request_type = .create,
        .user = TestUsers.alice,
    };

    const response = try api.handleRequest(request);

    try std.testing.expect(!response.success);
    try std.testing.expectEqualStrings("UserAlreadyExists", response.message);
}

// ============================================================================
// Fixture Pattern Example
// ============================================================================

test "ApiServer: using test fixture helper" {
    try helpers.withTestApi(struct {
        fn testFn(api: *ApiServer, db: *Database) !void {
            try api.createUser(TestUsers.alice);

            try std.testing.expectEqual(1, db.count());
            try std.testing.expect(api.userExists(TestUsers.alice.id));
        }
    }.testFn);
}
