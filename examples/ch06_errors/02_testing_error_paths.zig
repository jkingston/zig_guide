// Example 2: Testing Error Paths
// 06 Error Handling
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

fn createNestedStructure(allocator: std.mem.Allocator) !struct {
    data: []u32,
    metadata: []u8,
} {
    const data = try allocator.alloc(u32, 10);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(u8, 5);
    errdefer allocator.free(metadata);

    return .{ .data = data, .metadata = metadata };
}

test "errdefer cleanup on partial initialization" {
    var failing_allocator_state = testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 1 },
    );
    const failing_alloc = failing_allocator_state.allocator();

    const result = createNestedStructure(failing_alloc);
    try testing.expectError(error.OutOfMemory, result);

    // First allocation should have been cleaned up by errdefer
    try testing.expectEqual(1, failing_allocator_state.allocations);
    try testing.expectEqual(1, failing_allocator_state.deallocations);
    try testing.expect(
        failing_allocator_state.allocated_bytes == failing_allocator_state.freed_bytes
    );
}

test "systematic error path testing" {
    // Test all possible error paths by failing at each allocation point
    for (0..3) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index },
        );
        const failing_alloc = failing_state.allocator();

        const result = createNestedStructure(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no memory leaks occurred
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };

        // If reached, allocation succeeded; clean up
        defer {
            failing_alloc.free(result.data);
            failing_alloc.free(result.metadata);
        }
    }
}