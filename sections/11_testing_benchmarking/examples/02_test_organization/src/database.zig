// Mock database module demonstrating a simple key-value store
// This module shows separation of concerns - business logic here, tests elsewhere

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const DatabaseError = error{
    KeyNotFound,
    DuplicateKey,
    OutOfMemory,
};

/// A simple in-memory key-value database using HashMap
pub const Database = struct {
    allocator: Allocator,
    data: std.StringHashMap([]const u8),

    /// Initialize a new database instance
    pub fn init(allocator: Allocator) Database {
        return .{
            .allocator = allocator,
            .data = std.StringHashMap([]const u8).init(allocator),
        };
    }

    /// Clean up database resources
    pub fn deinit(self: *Database) void {
        // Free all stored keys and values
        var it = self.data.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.data.deinit();
    }

    /// Insert a new key-value pair
    /// Returns error.DuplicateKey if key already exists
    pub fn insert(self: *Database, key: []const u8, value: []const u8) DatabaseError!void {
        if (self.data.contains(key)) {
            return DatabaseError.DuplicateKey;
        }

        // Allocate copies of key and value for storage
        const key_copy = self.allocator.dupe(u8, key) catch return DatabaseError.OutOfMemory;
        errdefer self.allocator.free(key_copy);

        const value_copy = self.allocator.dupe(u8, value) catch return DatabaseError.OutOfMemory;
        errdefer self.allocator.free(value_copy);

        self.data.put(key_copy, value_copy) catch return DatabaseError.OutOfMemory;
    }

    /// Update an existing key with a new value
    /// Returns error.KeyNotFound if key doesn't exist
    pub fn update(self: *Database, key: []const u8, value: []const u8) DatabaseError!void {
        if (!self.data.contains(key)) {
            return DatabaseError.KeyNotFound;
        }

        // Get the existing entry to free old value
        const old_value = self.data.get(key).?;
        self.allocator.free(old_value);

        // Store new value
        const value_copy = self.allocator.dupe(u8, value) catch return DatabaseError.OutOfMemory;
        errdefer self.allocator.free(value_copy);

        // Update in place (key stays the same)
        self.data.put(key, value_copy) catch return DatabaseError.OutOfMemory;
    }

    /// Get a value by key
    /// Returns error.KeyNotFound if key doesn't exist
    /// Caller does NOT own the returned slice
    pub fn get(self: *Database, key: []const u8) DatabaseError![]const u8 {
        return self.data.get(key) orelse DatabaseError.KeyNotFound;
    }

    /// Delete a key-value pair
    /// Returns error.KeyNotFound if key doesn't exist
    pub fn delete(self: *Database, key: []const u8) DatabaseError!void {
        if (!self.data.contains(key)) {
            return DatabaseError.KeyNotFound;
        }

        // Get and free the stored key and value
        const kv = self.data.fetchRemove(key).?;
        self.allocator.free(kv.key);
        self.allocator.free(kv.value);
    }

    /// Check if a key exists
    pub fn exists(self: *Database, key: []const u8) bool {
        return self.data.contains(key);
    }

    /// Get the number of entries in the database
    pub fn count(self: *Database) usize {
        return self.data.count();
    }

    /// Clear all entries from the database
    pub fn clear(self: *Database) void {
        // Free all stored keys and values
        var it = self.data.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.data.clearRetainingCapacity();
    }
};
