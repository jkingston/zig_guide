// Example 6: Example 6
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

// Only compile this module in test mode
comptime {
    if (!builtin.is_test) {
        @compileError("test_helpers module is only for tests");
    }
}

/// Helper to create a test allocator with tracking
pub fn TestAllocator() type {
    return struct {
        gpa: std.heap.GeneralPurposeAllocator(.{}),

        pub fn init() @This() {
            return .{ .gpa = .{} };
        }

        pub fn allocator(self: *@This()) std.mem.Allocator {
            return self.gpa.allocator();
        }

        pub fn deinit(self: *@This()) !void {
            const leaked = self.gpa.deinit();
            if (leaked == .leak) {
                return error.MemoryLeak;
            }
        }
    };
}