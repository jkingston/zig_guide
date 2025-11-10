// Example 9: Allocator Testing
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

test "memory leak detection" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(testing.allocator); // Required - test fails without this

    try list.append(testing.allocator, 42);
    try list.append(testing.allocator, 43);

    try testing.expectEqual(@as(usize, 2), list.items.len);
    // testing.allocator automatically checks for leaks when test completes
}

test "allocation failure handling" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    // This allocation should fail immediately
    const result = allocator.alloc(u8, 100);
    try testing.expectError(error.OutOfMemory, result);
}

test "robust error path testing" {
    // Test allocation failure at different points
    var fail_index: u32 = 0;
    while (fail_index < 5) : (fail_index += 1) {
        var failing = testing.FailingAllocator.init(testing.allocator, .{
            .fail_index = fail_index
        });
        const allocator = failing.allocator();

        const result = createDataStructure(allocator);

        if (result) |structure| {
            defer structure.deinit(allocator);
            // Verify structure is valid
            try testing.expect(structure.isValid());
        } else |err| {
            // Should only fail with OutOfMemory
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}

fn createDataStructure(allocator: std.mem.Allocator) !DataStructure {
    var ds = DataStructure{};

    // Multiple allocations - test failure at each point
    ds.buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(ds.buffer1);

    ds.buffer2 = try allocator.alloc(u32, 50);
    errdefer allocator.free(ds.buffer2);

    ds.buffer3 = try allocator.alloc(i64, 25);
    errdefer allocator.free(ds.buffer3);

    return ds;
}

const DataStructure = struct {
    buffer1: []u8 = undefined,
    buffer2: []u32 = undefined,
    buffer3: []i64 = undefined,

    pub fn isValid(self: DataStructure) bool {
        return self.buffer1.len == 100 and
               self.buffer2.len == 50 and
               self.buffer3.len == 25;
    }

    pub fn deinit(self: DataStructure, allocator: std.mem.Allocator) void {
        allocator.free(self.buffer1);
        allocator.free(self.buffer2);
        allocator.free(self.buffer3);
    }
};

test "arena allocator pattern" {
    // Arena simplifies cleanup for multiple allocations
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Multiple allocations
    const data1 = try allocator.alloc(u8, 100);
    const data2 = try allocator.alloc(u32, 50);
    const data3 = try allocator.alloc(i64, 25);

    // Use the data
    data1[0] = 42;
    data2[0] = 100;
    data3[0] = -50;

    // No individual free() needed - arena.deinit(allocator) frees everything
}