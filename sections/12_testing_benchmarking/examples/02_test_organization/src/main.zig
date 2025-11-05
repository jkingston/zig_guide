// Demo application showing the database and API modules working together
// This is NOT a test file - tests are in the tests/ directory

const std = @import("std");
const Database = @import("database").Database;
const ApiServer = @import("api").ApiServer;
const User = @import("api").User;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Database & API Demo ===\n\n", .{});

    // Initialize database
    var db = Database.init(allocator);
    defer db.deinit();

    std.debug.print("1. Database Operations:\n", .{});
    std.debug.print("   - Inserting key-value pairs...\n", .{});

    try db.insert("config:theme", "dark");
    try db.insert("config:language", "en");
    try db.insert("config:notifications", "enabled");

    std.debug.print("   - Database now has {} entries\n", .{db.count()});
    std.debug.print("   - config:theme = {s}\n", .{try db.get("config:theme")});
    std.debug.print("   - config:language = {s}\n", .{try db.get("config:language")});

    std.debug.print("   - Updating config:theme to 'light'...\n", .{});
    try db.update("config:theme", "light");
    std.debug.print("   - config:theme = {s}\n", .{try db.get("config:theme")});

    std.debug.print("   - Deleting config:notifications...\n", .{});
    try db.delete("config:notifications");
    std.debug.print("   - Database now has {} entries\n", .{db.count()});

    // Clear database for API demo
    db.clear();
    std.debug.print("\n2. API Server Operations:\n", .{});

    // Initialize API server
    var api = ApiServer.init(allocator, &db);

    std.debug.print("   - Creating users...\n", .{});

    const alice = User{
        .id = "1",
        .name = "Alice",
        .email = "alice@example.com",
    };

    const bob = User{
        .id = "2",
        .name = "Bob",
        .email = "bob@example.com",
    };

    const charlie = User{
        .id = "3",
        .name = "Charlie",
        .email = "charlie@example.com",
    };

    try api.createUser(alice);
    try api.createUser(bob);
    try api.createUser(charlie);

    std.debug.print("   - Created {} users\n", .{api.getUserCount()});

    std.debug.print("   - Retrieving user with ID '2'...\n", .{});
    const retrieved_user = try api.getUser("2");
    std.debug.print("   - User: {s} <{s}>\n", .{ retrieved_user.name, retrieved_user.email });

    std.debug.print("   - Updating user '1'...\n", .{});
    const updated_alice = User{
        .id = "1",
        .name = "Alice Cooper",
        .email = "alice.cooper@example.com",
    };
    try api.updateUser(updated_alice);

    const alice_after = try api.getUser("1");
    std.debug.print("   - User 1 is now: {s} <{s}>\n", .{ alice_after.name, alice_after.email });

    std.debug.print("   - Deleting user '3'...\n", .{});
    try api.deleteUser("3");
    std.debug.print("   - User count: {}\n", .{api.getUserCount()});

    std.debug.print("\n3. Request Handling Demo:\n", .{});

    const create_request = ApiServer.Request{
        .request_type = .create,
        .user = User{
            .id = "4",
            .name = "Diana",
            .email = "diana@example.com",
        },
    };

    const response = try api.handleRequest(create_request);
    std.debug.print("   - Create request: success={}, message={s}\n", .{
        response.success,
        response.message,
    });

    if (response.user) |user| {
        std.debug.print("   - Created user: {s} <{s}>\n", .{ user.name, user.email });
    }

    std.debug.print("\n=== Demo Complete ===\n", .{});
    std.debug.print("\nRun 'zig build test' to see the comprehensive test suite!\n", .{});
}
