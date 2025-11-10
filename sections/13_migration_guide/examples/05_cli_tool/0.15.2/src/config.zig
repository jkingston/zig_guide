const std = @import("std");

pub const Config = struct {
    patterns: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Config {
        return Config{
            // ✅ 0.15+: ArrayList is unmanaged, no stored allocator
            .patterns = std.ArrayList([]const u8).empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Config) void {
        // Free all pattern strings
        for (self.patterns.items) |pattern| {
            self.allocator.free(pattern);
        }
        // ✅ 0.15+: Pass allocator to deinit
        self.patterns.deinit(self.allocator);
    }

    pub fn addPattern(self: *Config, pattern: []const u8) !void {
        const owned = try self.allocator.dupe(u8, pattern);
        // ✅ 0.15+: Pass allocator to append
        try self.patterns.append(self.allocator, owned);
    }
};
