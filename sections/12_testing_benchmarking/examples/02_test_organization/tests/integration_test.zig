// Integration tests that verify multiple modules working together
// These tests exercise the full stack: API -> Database

const std = @import("std");
const Database = @import("database").Database;
const ApiServer = @import("api").ApiServer;
const User = @import("api").User;
const helpers = @import("test_helpers");

const TestUsers = helpers.TestUsers;

// ============================================================================
// Full Stack Integration Tests
// ============================================================================

test "Integration: complete user lifecycle (create, read, update, delete)" {
    // Setup test context
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create a user
    try ctx.api.createUser(TestUsers.alice);
    try std.testing.expectEqual(1, ctx.db.count());

    // Read the user
    const retrieved = try ctx.api.getUser(TestUsers.alice.id);
    try helpers.expectUser(retrieved, TestUsers.alice);

    // Update the user
    const updated = User{
        .id = TestUsers.alice.id,
        .name = "Alice Modified",
        .email = "alice.modified@test.com",
    };
    try ctx.api.updateUser(updated);

    const after_update = try ctx.api.getUser(TestUsers.alice.id);
    try helpers.expectUser(after_update, updated);

    // Delete the user
    try ctx.api.deleteUser(TestUsers.alice.id);
    try std.testing.expectEqual(0, ctx.db.count());
}

test "Integration: multiple users coexist independently" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create multiple users
    try ctx.api.createUser(TestUsers.alice);
    try ctx.api.createUser(TestUsers.bob);
    try ctx.api.createUser(TestUsers.charlie);

    try std.testing.expectEqual(3, ctx.db.count());

    // Verify each user is correct
    const alice = try ctx.api.getUser(TestUsers.alice.id);
    try helpers.expectUser(alice, TestUsers.alice);

    const bob = try ctx.api.getUser(TestUsers.bob.id);
    try helpers.expectUser(bob, TestUsers.bob);

    const charlie = try ctx.api.getUser(TestUsers.charlie.id);
    try helpers.expectUser(charlie, TestUsers.charlie);

    // Delete one user, others remain
    try ctx.api.deleteUser(TestUsers.bob.id);
    try std.testing.expectEqual(2, ctx.db.count());

    try std.testing.expect(ctx.api.userExists(TestUsers.alice.id));
    try std.testing.expect(!ctx.api.userExists(TestUsers.bob.id));
    try std.testing.expect(ctx.api.userExists(TestUsers.charlie.id));
}

test "Integration: request handling end-to-end workflow" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create user via request
    const create_req = ApiServer.Request{
        .request_type = .create,
        .user = TestUsers.diana,
    };
    const create_resp = try ctx.api.handleRequest(create_req);
    try std.testing.expect(create_resp.success);

    // Get user via request
    const get_req = ApiServer.Request{
        .request_type = .get,
        .user = User{
            .id = TestUsers.diana.id,
            .name = "",
            .email = "",
        },
    };
    const get_resp = try ctx.api.handleRequest(get_req);
    try std.testing.expect(get_resp.success);
    try std.testing.expect(get_resp.user != null);

    // Update user via request
    const updated = User{
        .id = TestUsers.diana.id,
        .name = "Diana Modified",
        .email = "diana.modified@test.com",
    };
    const update_req = ApiServer.Request{
        .request_type = .update,
        .user = updated,
    };
    const update_resp = try ctx.api.handleRequest(update_req);
    try std.testing.expect(update_resp.success);

    // Verify update persisted
    const retrieved = try ctx.api.getUser(TestUsers.diana.id);
    try helpers.expectUser(retrieved, updated);

    // Delete user via request
    const delete_req = ApiServer.Request{
        .request_type = .delete,
        .user = User{
            .id = TestUsers.diana.id,
            .name = "",
            .email = "",
        },
    };
    const delete_resp = try ctx.api.handleRequest(delete_req);
    try std.testing.expect(delete_resp.success);

    try std.testing.expectEqual(0, ctx.db.count());
}

// ============================================================================
// Error Propagation Tests
// ============================================================================

test "Integration: database errors propagate through API" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create a user
    try ctx.api.createUser(TestUsers.alice);

    // Try to create duplicate - error should propagate
    const result = ctx.api.createUser(TestUsers.alice);
    try std.testing.expectError(error.UserAlreadyExists, result);

    // Try to get nonexistent user - error should propagate
    const get_result = ctx.api.getUser("nonexistent");
    try std.testing.expectError(error.UserNotFound, get_result);

    // Try to delete nonexistent user - error should propagate
    const delete_result = ctx.api.deleteUser("nonexistent");
    try std.testing.expectError(error.UserNotFound, delete_result);
}

test "Integration: request handling captures errors gracefully" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Try to get nonexistent user
    const get_req = ApiServer.Request{
        .request_type = .get,
        .user = User{
            .id = "nonexistent",
            .name = "",
            .email = "",
        },
    };
    const get_resp = try ctx.api.handleRequest(get_req);
    try std.testing.expect(!get_resp.success);
    try std.testing.expectEqualStrings("UserNotFound", get_resp.message);

    // Try to delete nonexistent user
    const delete_req = ApiServer.Request{
        .request_type = .delete,
        .user = User{
            .id = "nonexistent",
            .name = "",
            .email = "",
        },
    };
    const delete_resp = try ctx.api.handleRequest(delete_req);
    try std.testing.expect(!delete_resp.success);
    try std.testing.expectEqualStrings("UserNotFound", delete_resp.message);
}

// ============================================================================
// Data Consistency Tests
// ============================================================================

test "Integration: user data roundtrip preserves all fields" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    const original = User{
        .id = "test_123",
        .name = "Test User With Long Name",
        .email = "test.user.with.long.email@example.com",
    };

    // Create user
    try ctx.api.createUser(original);

    // Retrieve user
    const retrieved = try ctx.api.getUser(original.id);

    // Verify all fields match
    try helpers.expectUser(retrieved, original);
}

test "Integration: concurrent-like operations maintain consistency" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Simulate multiple operations happening in sequence
    // (In a real concurrent scenario, this would test race conditions)

    try ctx.api.createUser(TestUsers.alice);
    try ctx.api.createUser(TestUsers.bob);

    const count_after_creates = ctx.db.count();
    try std.testing.expectEqual(2, count_after_creates);

    try ctx.api.deleteUser(TestUsers.alice.id);

    const count_after_delete = ctx.db.count();
    try std.testing.expectEqual(1, count_after_delete);

    try ctx.api.createUser(TestUsers.charlie);

    const count_after_another_create = ctx.db.count();
    try std.testing.expectEqual(2, count_after_another_create);

    // Verify correct users exist
    try std.testing.expect(!ctx.api.userExists(TestUsers.alice.id));
    try std.testing.expect(ctx.api.userExists(TestUsers.bob.id));
    try std.testing.expect(ctx.api.userExists(TestUsers.charlie.id));
}

// ============================================================================
// Bulk Operations Tests
// ============================================================================

test "Integration: bulk user creation and retrieval" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create many users
    const user_count = 50;
    for (0..user_count) |i| {
        const id = try std.fmt.allocPrint(std.testing.allocator, "user_{}", .{i});
        defer std.testing.allocator.free(id);

        const name = try std.fmt.allocPrint(std.testing.allocator, "User {}", .{i});
        defer std.testing.allocator.free(name);

        const email = try std.fmt.allocPrint(std.testing.allocator, "user{}@test.com", .{i});
        defer std.testing.allocator.free(email);

        const user = User{
            .id = id,
            .name = name,
            .email = email,
        };

        try ctx.api.createUser(user);
    }

    try std.testing.expectEqual(user_count, ctx.db.count());

    // Verify random users
    for ([_]usize{ 0, 10, 25, 49 }) |i| {
        const id = try std.fmt.allocPrint(std.testing.allocator, "user_{}", .{i});
        defer std.testing.allocator.free(id);

        try std.testing.expect(ctx.api.userExists(id));
    }
}

test "Integration: stress test with create, update, delete cycles" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    ctx.setup();
    defer ctx.deinit();

    // Create several users
    try ctx.api.createUser(TestUsers.alice);
    try ctx.api.createUser(TestUsers.bob);
    try ctx.api.createUser(TestUsers.charlie);

    // Perform multiple update cycles
    for (0..5) |cycle| {
        const updated_alice = User{
            .id = TestUsers.alice.id,
            .name = "Alice",
            .email = try std.fmt.allocPrint(std.testing.allocator, "alice.cycle{}@test.com", .{cycle}),
        };
        defer std.testing.allocator.free(updated_alice.email);

        try ctx.api.updateUser(updated_alice);

        const retrieved = try ctx.api.getUser(TestUsers.alice.id);
        try std.testing.expectEqualStrings(updated_alice.email, retrieved.email);
    }

    // Delete and recreate
    try ctx.api.deleteUser(TestUsers.bob.id);
    try std.testing.expectEqual(2, ctx.db.count());

    try ctx.api.createUser(TestUsers.bob);
    try std.testing.expectEqual(3, ctx.db.count());

    const bob = try ctx.api.getUser(TestUsers.bob.id);
    try helpers.expectUser(bob, TestUsers.bob);
}
