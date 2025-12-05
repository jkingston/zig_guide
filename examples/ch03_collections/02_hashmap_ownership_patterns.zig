// Example 2: HashMap Ownership Patterns
// 04 Collections Containers
//
// Extracted from chapter content.md

const std = @import("std");

const User = struct {
    id: u32,
    name: []u8,
    score: i32,

    pub fn init(allocator: std.mem.Allocator, id: u32, name: []const u8, score: i32) !User {
        return .{
            .id = id,
            .name = try allocator.dupe(u8, name),
            .score = score,
        };
    }

    pub fn deinit(self: *User, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // Pattern 1: Direct value storage
    std.debug.print("=== Pattern 1: Direct Value Storage ===\n", .{});
    var users_direct = std.AutoHashMapUnmanaged(u32, User){};
    defer {
        // Must clean up allocated fields within values
        var it = users_direct.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(allocator);
        }
        users_direct.deinit(allocator);
    }

    const user1 = try User.init(allocator, 1, "Alice", 100);
    try users_direct.put(allocator, user1.id, user1);

    if (users_direct.get(1)) |user| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user.name, user.score });
    }

    // Pattern 2: Pointer storage (detached lifetime)
    std.debug.print("=== Pattern 2: Pointer Storage ===\n", .{});
    var users_ptr = std.AutoHashMapUnmanaged(u32, *User){};
    defer {
        // Must free both the pointed-to objects AND the pointers
        var it = users_ptr.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit(allocator);
            allocator.destroy(entry.value_ptr.*);
        }
        users_ptr.deinit(allocator);
    }

    const user2 = try allocator.create(User);
    user2.* = try User.init(allocator, 2, "Bob", 200);
    try users_ptr.put(allocator, user2.id, user2);

    if (users_ptr.get(2)) |user_ptr| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user_ptr.name, user_ptr.score });
    }

    // Pattern 3: HashMap as Set (void value)
    std.debug.print("=== Pattern 3: HashMap as Set ===\n", .{});
    var seen_ids = std.AutoHashMapUnmanaged(u32, void){};
    defer seen_ids.deinit(allocator);

    try seen_ids.put(allocator, 42, {});
    try seen_ids.put(allocator, 100, {});

    std.debug.print("Contains 42? {}\n", .{seen_ids.contains(42)});
    std.debug.print("Contains 99? {}\n", .{seen_ids.contains(99)});
}