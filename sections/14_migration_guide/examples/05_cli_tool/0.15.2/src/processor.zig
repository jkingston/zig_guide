const std = @import("std");

pub const Processor = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Processor {
        return Processor{ .allocator = allocator };
    }

    pub fn deinit(_: *Processor) void {
        // No cleanup needed in this simple version
    }

    pub fn findMatches(self: *Processor, text: []const u8, patterns: []const []const u8) !usize {
        _ = self;
        var count: usize = 0;

        for (patterns) |pattern| {
            if (std.mem.indexOf(u8, text, pattern)) |_| {
                count += 1;
            }
        }

        return count;
    }
};
