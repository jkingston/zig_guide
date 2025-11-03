const std = @import("std");
const testing = std.testing;

// Function that allocates memory
fn createList(allocator: std.mem.Allocator, size: usize) ![]u32 {
    const list = try allocator.alloc(u32, size);
    errdefer allocator.free(list);

    for (list, 0..) |*item, i| {
        item.* = @intCast(i * 2);
    }
    return list;
}

// Function with nested allocations
fn createNestedStructure(allocator: std.mem.Allocator) !struct { data: []u32, metadata: []u8 } {
    const data = try allocator.alloc(u32, 10);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(u8, 5);
    errdefer allocator.free(metadata);

    return .{ .data = data, .metadata = metadata };
}

test "basic error expectation" {
    const FileError = error{NotFound};

    const result: FileError!void = error.NotFound;

    // Verify that a specific error is returned
    try testing.expectError(error.NotFound, result);
}

test "allocation with FailingAllocator" {
    // Set up FailingAllocator to fail after N allocations
    var failing_allocator_state = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 1, // Fail on the second allocation (index 1)
    });
    const failing_alloc = failing_allocator_state.allocator();

    // First allocation succeeds
    const first = try createList(failing_alloc, 5);
    defer failing_alloc.free(first);

    // Second allocation fails
    const result = createList(failing_alloc, 10);
    try testing.expectError(error.OutOfMemory, result);

    // Verify cleanup happened correctly - no memory leaks
    try testing.expectEqual(1, failing_allocator_state.allocations);
    try testing.expectEqual(1, failing_allocator_state.deallocations);
}

test "errdefer cleanup on partial initialization" {
    // Fail on second allocation to test errdefer cleanup
    var failing_allocator_state = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 1,
    });
    const failing_alloc = failing_allocator_state.allocator();

    const result = createNestedStructure(failing_alloc);
    try testing.expectError(error.OutOfMemory, result);

    // First allocation should have been cleaned up by errdefer
    try testing.expectEqual(1, failing_allocator_state.allocations);
    try testing.expectEqual(1, failing_allocator_state.deallocations);
    try testing.expect(failing_allocator_state.allocated_bytes == failing_allocator_state.freed_bytes);
}

test "systematic error path testing" {
    // Test all possible error paths by failing at each allocation point
    for (0..3) |fail_index| {
        var failing_allocator_state = testing.FailingAllocator.init(testing.allocator, .{
            .fail_index = fail_index,
        });
        const failing_alloc = failing_allocator_state.allocator();

        _ = createNestedStructure(failing_alloc) catch |err| {
            // Verify error is OutOfMemory
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no memory leaks occurred
            try testing.expect(
                failing_allocator_state.allocated_bytes == failing_allocator_state.freed_bytes,
            );
            continue;
        };

        // If we reach here, allocation succeeded
        // Clean up the result
        const result = try createNestedStructure(failing_alloc);
        defer {
            failing_alloc.free(result.data);
            failing_alloc.free(result.metadata);
        }
    }
}

pub fn main() !void {
    std.debug.print("Run with 'zig test example_testing_errors.zig'\n", .{});
}
