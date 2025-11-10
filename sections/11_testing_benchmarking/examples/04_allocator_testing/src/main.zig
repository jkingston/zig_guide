const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;
const StringBuilder = @import("string_builder.zig").StringBuilder;
const Cache = @import("cache.zig").Cache;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== Allocator Testing Demo ===\n\n", .{});

    // Demonstrate Buffer
    try demonstrateBuffer(allocator);

    // Demonstrate StringBuilder
    try demonstrateStringBuilder(allocator);

    // Demonstrate Cache
    try demonstrateCache(allocator);

    std.debug.print("\n=== All demos completed successfully ===\n", .{});
}

fn demonstrateBuffer(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Buffer Demo ---\n", .{});

    var buffer = try Buffer.init(allocator, 16);
    defer buffer.deinit();

    std.debug.print("Created buffer with capacity: {d}\n", .{buffer.capacity});

    try buffer.appendSlice("Hello, ");
    try buffer.appendSlice("World!");

    std.debug.print("Buffer contents: {s}\n", .{buffer.slice()});
    std.debug.print("Buffer length: {d}\n", .{buffer.len});

    // Demonstrate automatic growth
    var i: u8 = 0;
    while (i < 20) : (i += 1) {
        try buffer.append('x');
    }

    std.debug.print("After appending 20 'x's, capacity: {d}\n", .{buffer.capacity});
    std.debug.print("Buffer length: {d}\n\n", .{buffer.len});
}

fn demonstrateStringBuilder(allocator: std.mem.Allocator) !void {
    std.debug.print("--- StringBuilder Demo ---\n", .{});

    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    try builder.appendSlice("Name: ");
    try builder.appendSlice("Alice");
    try builder.print(", Age: {d}", .{30});

    std.debug.print("Built string: {s}\n", .{builder.toSlice()});
    std.debug.print("Length: {d}\n", .{builder.len()});

    // Get an owned copy
    const owned = try builder.toString();
    defer allocator.free(owned);

    std.debug.print("Owned copy: {s}\n", .{owned});

    // Clear and reuse
    builder.clear();
    try builder.print("Reused: {d} + {d} = {d}", .{ 10, 20, 30 });
    std.debug.print("After clear and reuse: {s}\n\n", .{builder.toSlice()});
}

fn demonstrateCache(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Cache Demo ---\n", .{});

    // Create a cache that owns both keys and values
    var cache = Cache.init(allocator, true, true);
    defer cache.deinit();

    try cache.put("user:1:name", "Alice");
    try cache.put("user:1:email", "alice@example.com");
    try cache.put("user:2:name", "Bob");
    try cache.put("user:2:email", "bob@example.com");

    std.debug.print("Cache size: {d}\n", .{cache.count()});

    if (cache.get("user:1:name")) |name| {
        std.debug.print("User 1 name: {s}\n", .{name});
    }

    if (cache.get("user:2:email")) |email| {
        std.debug.print("User 2 email: {s}\n", .{email});
    }

    // Update a value
    try cache.put("user:1:name", "Alice Smith");

    if (cache.get("user:1:name")) |name| {
        std.debug.print("Updated User 1 name: {s}\n", .{name});
    }

    // Remove an entry
    const removed = cache.remove("user:2:name");
    std.debug.print("Removed user:2:name: {}\n", .{removed});
    std.debug.print("Cache size after removal: {d}\n\n", .{cache.count()});
}
