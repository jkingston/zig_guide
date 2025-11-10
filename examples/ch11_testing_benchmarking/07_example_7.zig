// Example 7: Example 7
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");

/// Standard test data for numeric operations
pub const test_numbers = [_]i32{ 1, 2, 3, 4, 5, 10, 42, 100, 1000 };

/// Standard test strings
pub const test_strings = [_][]const u8{
    "",
    "a",
    "hello",
    "Hello, World!",
    "The quick brown fox jumps over the lazy dog",
};

/// Create a test arena allocator
pub fn createTestArena(backing: std.mem.Allocator) std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(backing);
}