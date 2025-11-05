const std = @import("std");

pub const Config = struct {
    patterns: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Config {
        return Config{
            // 🕐 0.14.x: ArrayList stores allocator internally
            .patterns = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Config) void {
        // Free all pattern strings
        for (self.patterns.items) |pattern| {
            self.allocator.free(pattern);
        }
        self.patterns.deinit();
    }

    pub fn addPattern(self: *Config, pattern: []const u8) !void {
        const owned = try self.allocator.dupe(u8, pattern);
        try self.patterns.append(owned);
    }
};
