const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;

/// A simple string key-value cache with proper memory management.
/// Demonstrates managing both keys and values that may need duplication.
pub const Cache = struct {
    map: StringHashMap([]const u8),
    allocator: Allocator,
    owns_keys: bool,
    owns_values: bool,

    /// Initialize a cache.
    /// If owns_keys is true, the cache will duplicate and own all keys.
    /// If owns_values is true, the cache will duplicate and own all values.
    pub fn init(allocator: Allocator, owns_keys: bool, owns_values: bool) Cache {
        return Cache{
            .map = StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
            .owns_keys = owns_keys,
            .owns_values = owns_values,
        };
    }

    /// Free all memory used by the cache.
    pub fn deinit(self: *Cache) void {
        // Free all keys and values if we own them
        var iter = self.map.iterator();
        while (iter.next()) |entry| {
            if (self.owns_keys) {
                self.allocator.free(entry.key_ptr.*);
            }
            if (self.owns_values) {
                self.allocator.free(entry.value_ptr.*);
            }
        }
        self.map.deinit();
    }

    /// Put a key-value pair in the cache.
    /// If owns_keys or owns_values is true, the cache will duplicate them.
    pub fn put(self: *Cache, key: []const u8, value: []const u8) !void {
        // Check if key already exists to free old values
        const old_entry = if (self.map.fetchRemove(key)) |kv| kv else null;

        const final_key = if (self.owns_keys)
            try self.allocator.dupe(u8, key)
        else
            key;
        errdefer if (self.owns_keys) self.allocator.free(final_key);

        const final_value = if (self.owns_values)
            try self.allocator.dupe(u8, value)
        else
            value;
        errdefer if (self.owns_values) self.allocator.free(final_value);

        // If put fails, errdefer will clean up what we allocated
        try self.map.put(final_key, final_value);

        // If there was an old entry, free it
        if (old_entry) |old| {
            if (self.owns_keys) self.allocator.free(old.key);
            if (self.owns_values) self.allocator.free(old.value);
        }
    }

    /// Get a value from the cache. Returns null if not found.
    pub fn get(self: *const Cache, key: []const u8) ?[]const u8 {
        return self.map.get(key);
    }

    /// Check if a key exists in the cache.
    pub fn contains(self: *const Cache, key: []const u8) bool {
        return self.map.contains(key);
    }

    /// Remove a key-value pair from the cache.
    pub fn remove(self: *Cache, key: []const u8) bool {
        if (self.map.fetchRemove(key)) |entry| {
            if (self.owns_keys) self.allocator.free(entry.key);
            if (self.owns_values) self.allocator.free(entry.value);
            return true;
        }
        return false;
    }

    /// Clear all entries from the cache.
    pub fn clear(self: *Cache) void {
        var iter = self.map.iterator();
        while (iter.next()) |entry| {
            if (self.owns_keys) self.allocator.free(entry.key_ptr.*);
            if (self.owns_values) self.allocator.free(entry.value_ptr.*);
        }
        self.map.clearRetainingCapacity();
    }

    /// Get the number of entries in the cache.
    pub fn count(self: *const Cache) usize {
        return self.map.count();
    }
};

// ============================================================================
// TESTS: Complex memory management with keys and values
// ============================================================================

test "Cache: basic initialization and cleanup (no ownership)" {
    var cache = Cache.init(testing.allocator, false, false);
    defer cache.deinit();

    try testing.expectEqual(@as(usize, 0), cache.count());
}

test "Cache: basic initialization with ownership" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try testing.expectEqual(@as(usize, 0), cache.count());
}

test "Cache: put and get without ownership" {
    var cache = Cache.init(testing.allocator, false, false);
    defer cache.deinit();

    const key = "name";
    const value = "Alice";

    try cache.put(key, value);
    try testing.expectEqual(@as(usize, 1), cache.count());

    const result = cache.get("name");
    try testing.expect(result != null);
    try testing.expectEqualSlices(u8, "Alice", result.?);
}

test "Cache: put and get with ownership" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    // These string literals are safe to use even with ownership
    // because the cache will duplicate them
    try cache.put("key1", "value1");
    try cache.put("key2", "value2");

    try testing.expectEqual(@as(usize, 2), cache.count());

    const v1 = cache.get("key1");
    const v2 = cache.get("key2");

    try testing.expect(v1 != null);
    try testing.expect(v2 != null);
    try testing.expectEqualSlices(u8, "value1", v1.?);
    try testing.expectEqualSlices(u8, "value2", v2.?);
}

test "Cache: contains check" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("exists", "yes");

    try testing.expect(cache.contains("exists"));
    try testing.expect(!cache.contains("not_exists"));
}

test "Cache: get non-existent key" {
    var cache = Cache.init(testing.allocator, false, false);
    defer cache.deinit();

    const result = cache.get("nonexistent");
    try testing.expect(result == null);
}

test "Cache: update existing key" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key", "value1");
    try testing.expectEqualSlices(u8, "value1", cache.get("key").?);

    try cache.put("key", "value2");
    try testing.expectEqualSlices(u8, "value2", cache.get("key").?);
    try testing.expectEqual(@as(usize, 1), cache.count());
}

test "Cache: remove entry" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key", "value");
    try testing.expectEqual(@as(usize, 1), cache.count());

    const removed = cache.remove("key");
    try testing.expect(removed);
    try testing.expectEqual(@as(usize, 0), cache.count());
    try testing.expect(cache.get("key") == null);
}

test "Cache: remove non-existent entry" {
    var cache = Cache.init(testing.allocator, false, false);
    defer cache.deinit();

    const removed = cache.remove("nonexistent");
    try testing.expect(!removed);
}

test "Cache: clear all entries" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key1", "value1");
    try cache.put("key2", "value2");
    try cache.put("key3", "value3");
    try testing.expectEqual(@as(usize, 3), cache.count());

    cache.clear();
    try testing.expectEqual(@as(usize, 0), cache.count());
    try testing.expect(cache.get("key1") == null);
}

test "Cache: clear and reuse" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key1", "value1");
    cache.clear();

    try cache.put("key2", "value2");
    try testing.expectEqual(@as(usize, 1), cache.count());
    try testing.expectEqualSlices(u8, "value2", cache.get("key2").?);
}

test "Cache: multiple entries" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("name", "Alice");
    try cache.put("age", "30");
    try cache.put("city", "NYC");

    try testing.expectEqual(@as(usize, 3), cache.count());
    try testing.expectEqualSlices(u8, "Alice", cache.get("name").?);
    try testing.expectEqualSlices(u8, "30", cache.get("age").?);
    try testing.expectEqualSlices(u8, "NYC", cache.get("city").?);
}

test "Cache: ownership combinations" {
    // Test all four ownership combinations

    // 1. No ownership
    {
        var cache = Cache.init(testing.allocator, false, false);
        defer cache.deinit();
        const k = "key";
        const v = "value";
        try cache.put(k, v);
    }

    // 2. Own keys only
    {
        var cache = Cache.init(testing.allocator, true, false);
        defer cache.deinit();
        try cache.put("key", "value");
    }

    // 3. Own values only
    {
        var cache = Cache.init(testing.allocator, false, true);
        defer cache.deinit();
        try cache.put("key", "value");
    }

    // 4. Own both
    {
        var cache = Cache.init(testing.allocator, true, true);
        defer cache.deinit();
        try cache.put("key", "value");
    }
}

test "Cache: using dynamically allocated strings" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    // Allocate strings that will be freed
    const key = try testing.allocator.dupe(u8, "dynamic_key");
    defer testing.allocator.free(key);

    const value = try testing.allocator.dupe(u8, "dynamic_value");
    defer testing.allocator.free(value);

    // Cache will duplicate these
    try cache.put(key, value);

    // Original strings can be freed, cache has its own copies
    const result = cache.get("dynamic_key");
    try testing.expectEqualSlices(u8, "dynamic_value", result.?);
}

test "Cache: multiple caches independent" {
    var cache1 = Cache.init(testing.allocator, true, true);
    defer cache1.deinit();

    var cache2 = Cache.init(testing.allocator, true, true);
    defer cache2.deinit();

    try cache1.put("key", "cache1");
    try cache2.put("key", "cache2");

    try testing.expectEqualSlices(u8, "cache1", cache1.get("key").?);
    try testing.expectEqualSlices(u8, "cache2", cache2.get("key").?);
}

test "Cache: allocation failure on put (key duplication)" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });
    const allocator = failing.allocator();

    var cache = Cache.init(allocator, true, true);
    defer cache.deinit();

    const result = cache.put("key", "value");
    try testing.expectError(error.OutOfMemory, result);
}

test "Cache: allocation failure on put (value duplication)" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 1, // Fail on second allocation (value)
    });
    const allocator = failing.allocator();

    var cache = Cache.init(allocator, true, true);
    defer cache.deinit();

    const result = cache.put("key", "value");
    try testing.expectError(error.OutOfMemory, result);
}

test "Cache: stress test many entries" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    var key_buf: [32]u8 = undefined;
    var value_buf: [32]u8 = undefined;
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const key = try std.fmt.bufPrint(&key_buf, "key_{d}", .{i});
        const value = try std.fmt.bufPrint(&value_buf, "value_{d}", .{i});
        try cache.put(key, value);
    }

    try testing.expectEqual(@as(usize, 100), cache.count());
}

test "Cache: using with ArenaAllocator" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var cache = Cache.init(allocator, true, true);
    // No need to call cache.deinit() with arena

    try cache.put("key1", "value1");
    try cache.put("key2", "value2");

    try testing.expectEqual(@as(usize, 2), cache.count());
}

test "Cache: remove and re-add same key" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key", "value1");
    _ = cache.remove("key");
    try cache.put("key", "value2");

    try testing.expectEqualSlices(u8, "value2", cache.get("key").?);
}

test "Cache: empty cache operations" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try testing.expectEqual(@as(usize, 0), cache.count());
    try testing.expect(cache.get("anything") == null);
    try testing.expect(!cache.contains("anything"));
    try testing.expect(!cache.remove("anything"));

    cache.clear(); // Should be safe on empty cache
}

// ============================================================================
// INTENTIONALLY FAILING TESTS (commented out)
// ============================================================================

// test "Cache: LEAK DEMO - forgot deinit (WILL FAIL)" {
//     var cache = Cache.init(testing.allocator, true, true);
//     // Missing: defer cache.deinit();
//
//     try cache.put("key1", "value1");
//     try cache.put("key2", "value2");
//
//     // All duplicated keys and values will leak, plus the HashMap itself!
// }

// test "Cache: LEAK DEMO - forgot to free removed entry (no ownership)" {
//     var cache = Cache.init(testing.allocator, false, false);
//     defer cache.deinit();
//
//     const key = try testing.allocator.dupe(u8, "key");
//     // Missing: defer testing.allocator.free(key);
//
//     const value = try testing.allocator.dupe(u8, "value");
//     // Missing: defer testing.allocator.free(value);
//
//     try cache.put(key, value);
//
//     // Since cache doesn't own these, we need to free them ourselves
//     // But we forgot the defers above!
// }

// test "Cache: LEAK DEMO - partial cleanup (WILL FAIL)" {
//     var cache = Cache.init(testing.allocator, true, true);
//     defer cache.deinit();
//
//     try cache.put("key1", "value1");
//
//     // Manually remove the entry
//     _ = cache.remove("key1");
//
//     // Add it again
//     try cache.put("key2", "value2");
//
//     // Now intentionally forget to clean up
//     cache.deinit();
//     cache.* = undefined;
//
//     // Create another cache without cleanup
//     var cache2 = Cache.init(testing.allocator, true, true);
//     // Missing: defer cache2.deinit();
//     try cache2.put("leak", "yes");
// }
