// Example 3: Example 3
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

test "handle allocation failure" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 2 });
    const allocator = failing.allocator();

    // First 2 allocations succeed, 3rd fails (fail_index counts from 0)
    const a1 = try allocator.alloc(u8, 10);
    defer allocator.free(a1);

    const a2 = try allocator.alloc(u8, 10);
    defer allocator.free(a2);

    const a3 = allocator.alloc(u8, 10);
    try testing.expectError(error.OutOfMemory, a3);
}