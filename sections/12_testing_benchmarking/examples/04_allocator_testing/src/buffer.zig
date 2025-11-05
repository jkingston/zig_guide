const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// A dynamically resizable byte buffer.
/// Demonstrates proper memory management and allocation testing patterns.
pub const Buffer = struct {
    data: []u8,
    len: usize,
    capacity: usize,
    allocator: Allocator,

    /// Initialize a buffer with the given initial capacity.
    pub fn init(allocator: Allocator, initial_capacity: usize) !Buffer {
        const data = try allocator.alloc(u8, initial_capacity);
        return Buffer{
            .data = data,
            .len = 0,
            .capacity = initial_capacity,
            .allocator = allocator,
        };
    }

    /// Free the buffer's memory. Must be called to prevent leaks.
    pub fn deinit(self: *Buffer) void {
        self.allocator.free(self.data);
        self.* = undefined;
    }

    /// Append a single byte to the buffer, growing if necessary.
    pub fn append(self: *Buffer, byte: u8) !void {
        if (self.len >= self.capacity) {
            try self.resize(self.capacity * 2);
        }
        self.data[self.len] = byte;
        self.len += 1;
    }

    /// Append multiple bytes to the buffer.
    pub fn appendSlice(self: *Buffer, bytes: []const u8) !void {
        const new_len = self.len + bytes.len;
        if (new_len > self.capacity) {
            var new_capacity = self.capacity;
            while (new_capacity < new_len) {
                new_capacity *= 2;
            }
            try self.resize(new_capacity);
        }
        @memcpy(self.data[self.len..][0..bytes.len], bytes);
        self.len = new_len;
    }

    /// Clear the buffer contents without freeing memory.
    pub fn clear(self: *Buffer) void {
        self.len = 0;
    }

    /// Resize the buffer to a new capacity.
    pub fn resize(self: *Buffer, new_capacity: usize) !void {
        if (new_capacity < self.len) {
            return error.CapacityTooSmall;
        }
        const new_data = try self.allocator.realloc(self.data, new_capacity);
        self.data = new_data;
        self.capacity = new_capacity;
    }

    /// Convert the buffer to an owned slice, transferring ownership.
    /// After calling this, the buffer is in an unusable state and should not be used.
    pub fn toOwnedSlice(self: *Buffer) ![]u8 {
        const result = try self.allocator.realloc(self.data, self.len);
        self.* = undefined;
        return result;
    }

    /// Get a slice of the current contents.
    pub fn slice(self: *const Buffer) []const u8 {
        return self.data[0..self.len];
    }
};

// ============================================================================
// TESTS: Comprehensive allocator testing demonstrations
// ============================================================================

test "Buffer: basic initialization and cleanup" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, 0), buffer.len);
    try testing.expectEqual(@as(usize, 100), buffer.capacity);
}

test "Buffer: initialization with different sizes" {
    {
        var buffer = try Buffer.init(testing.allocator, 1);
        defer buffer.deinit();
        try testing.expectEqual(@as(usize, 1), buffer.capacity);
    }
    {
        var buffer = try Buffer.init(testing.allocator, 1000);
        defer buffer.deinit();
        try testing.expectEqual(@as(usize, 1000), buffer.capacity);
    }
    {
        var buffer = try Buffer.init(testing.allocator, 1024 * 1024);
        defer buffer.deinit();
        try testing.expectEqual(@as(usize, 1024 * 1024), buffer.capacity);
    }
}

test "Buffer: append single byte" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.append('A');
    try testing.expectEqual(@as(usize, 1), buffer.len);
    try testing.expectEqual(@as(u8, 'A'), buffer.data[0]);
}

test "Buffer: append multiple bytes individually" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.append('H');
    try buffer.append('i');
    try buffer.append('!');

    try testing.expectEqual(@as(usize, 3), buffer.len);
    try testing.expectEqualSlices(u8, "Hi!", buffer.slice());
}

test "Buffer: append slice" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.appendSlice("Hello");
    try testing.expectEqual(@as(usize, 5), buffer.len);
    try testing.expectEqualSlices(u8, "Hello", buffer.slice());
}

test "Buffer: multiple append slices" {
    var buffer = try Buffer.init(testing.allocator, 20);
    defer buffer.deinit();

    try buffer.appendSlice("Hello");
    try buffer.appendSlice(" ");
    try buffer.appendSlice("World");

    try testing.expectEqualSlices(u8, "Hello World", buffer.slice());
}

test "Buffer: clear operation" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    try testing.expectEqual(@as(usize, 4), buffer.len);

    buffer.clear();
    try testing.expectEqual(@as(usize, 0), buffer.len);
    try testing.expectEqual(@as(usize, 10), buffer.capacity); // Capacity unchanged
}

test "Buffer: clear and reuse" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.appendSlice("first");
    buffer.clear();
    try buffer.appendSlice("second");

    try testing.expectEqualSlices(u8, "second", buffer.slice());
}

test "Buffer: resize to larger capacity" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    try buffer.resize(100);

    try testing.expectEqual(@as(usize, 100), buffer.capacity);
    try testing.expectEqual(@as(usize, 4), buffer.len);
    try testing.expectEqualSlices(u8, "test", buffer.slice());
}

test "Buffer: resize smaller but within len" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    try buffer.resize(50);

    try testing.expectEqual(@as(usize, 50), buffer.capacity);
    try testing.expectEqualSlices(u8, "test", buffer.slice());
}

test "Buffer: resize error when too small" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("Hello World");

    const result = buffer.resize(5); // Too small for current len
    try testing.expectError(error.CapacityTooSmall, result);
}

test "Buffer: automatic growth on append" {
    var buffer = try Buffer.init(testing.allocator, 2);
    defer buffer.deinit();

    try buffer.append('A');
    try buffer.append('B');
    try testing.expectEqual(@as(usize, 2), buffer.capacity);

    // This should trigger a resize
    try buffer.append('C');
    try testing.expectEqual(@as(usize, 4), buffer.capacity);
    try testing.expectEqualSlices(u8, "ABC", buffer.slice());
}

test "Buffer: automatic growth on appendSlice" {
    var buffer = try Buffer.init(testing.allocator, 4);
    defer buffer.deinit();

    try buffer.appendSlice("Hi");
    try testing.expectEqual(@as(usize, 4), buffer.capacity);

    // This should trigger automatic growth
    try buffer.appendSlice(" World");
    try testing.expect(buffer.capacity >= 8);
    try testing.expectEqualSlices(u8, "Hi World", buffer.slice());
}

test "Buffer: toOwnedSlice transfers ownership" {
    var buffer = try Buffer.init(testing.allocator, 10);
    // Note: No defer here because toOwnedSlice takes ownership

    try buffer.appendSlice("test");

    const owned = try buffer.toOwnedSlice();
    defer testing.allocator.free(owned);

    try testing.expectEqualSlices(u8, "test", owned);
}

test "Buffer: multiple buffers don't interfere" {
    var buffer1 = try Buffer.init(testing.allocator, 10);
    defer buffer1.deinit();

    var buffer2 = try Buffer.init(testing.allocator, 10);
    defer buffer2.deinit();

    try buffer1.appendSlice("first");
    try buffer2.appendSlice("second");

    try testing.expectEqualSlices(u8, "first", buffer1.slice());
    try testing.expectEqualSlices(u8, "second", buffer2.slice());
}

test "Buffer: using std.testing.allocator detects leaks" {
    // This test passes because we properly call deinit
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("leak test");
    // If we forget the defer above, this test will fail with leak detection
}

test "Buffer: testing with ArenaAllocator" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // With arena, we don't need individual deinit calls
    var buffer1 = try Buffer.init(allocator, 10);
    var buffer2 = try Buffer.init(allocator, 20);

    try buffer1.appendSlice("test1");
    try buffer2.appendSlice("test2");

    // arena.deinit() will free everything
}

test "Buffer: allocation failure on init" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0, // Fail immediately
    });
    const allocator = failing.allocator();

    const result = Buffer.init(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);
}

test "Buffer: allocation failure on resize" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });

    // Temporarily replace allocator to simulate failure
    const original_allocator = buffer.allocator;
    buffer.allocator = failing.allocator();

    const result = buffer.resize(100);
    try testing.expectError(error.OutOfMemory, result);

    // Restore original allocator for cleanup
    buffer.allocator = original_allocator;
}

test "Buffer: allocation failure on append growth" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 1, // Allow init, fail on realloc
    });
    const allocator = failing.allocator();

    var buffer = try Buffer.init(allocator, 2);
    defer buffer.deinit();

    try buffer.append('A');
    try buffer.append('B');

    // This append should trigger growth and fail
    const result = buffer.append('C');
    try testing.expectError(error.OutOfMemory, result);

    // Buffer should still be valid with original data
    try testing.expectEqualSlices(u8, "AB", buffer.slice());
}

test "Buffer: state after toOwnedSlice" {
    var buffer = try Buffer.init(testing.allocator, 10);
    try buffer.appendSlice("test");

    const owned = try buffer.toOwnedSlice();
    defer testing.allocator.free(owned);

    // Buffer is now in undefined state and should not be used
    // This test just verifies the pattern works correctly
    try testing.expectEqualSlices(u8, "test", owned);
}

test "Buffer: empty buffer operations" {
    var buffer = try Buffer.init(testing.allocator, 10);
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, 0), buffer.len);
    try testing.expectEqualSlices(u8, "", buffer.slice());

    buffer.clear(); // Should be safe on empty buffer
    try testing.expectEqual(@as(usize, 0), buffer.len);
}

test "Buffer: large allocation stress test" {
    var buffer = try Buffer.init(testing.allocator, 1);
    defer buffer.deinit();

    // Grow the buffer many times
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try buffer.append(@as(u8, @intCast(i % 256)));
    }

    try testing.expectEqual(@as(usize, 100), buffer.len);
    try testing.expect(buffer.capacity >= 100);
}

// ============================================================================
// INTENTIONALLY FAILING TESTS (commented out)
// ============================================================================
// These demonstrate what happens when proper cleanup is not done.
// Uncomment them one at a time to see leak detection in action.

// test "Buffer: LEAK DEMO - forgot deinit (WILL FAIL)" {
//     var buffer = try Buffer.init(testing.allocator, 100);
//     // Missing: defer buffer.deinit();
//     try buffer.appendSlice("This will leak!");
//
//     // When you run this test, you'll see output like:
//     // [gpa] (err): memory address 0x... leaked:
//     // This demonstrates Zig's automatic leak detection!
// }

// test "Buffer: LEAK DEMO - forgot to free toOwnedSlice (WILL FAIL)" {
//     var buffer = try Buffer.init(testing.allocator, 10);
//     try buffer.appendSlice("test");
//
//     const owned = try buffer.toOwnedSlice();
//     // Missing: defer testing.allocator.free(owned);
//     _ = owned;
//
//     // This will also show a leak!
// }

// test "Buffer: LEAK DEMO - partial cleanup (WILL FAIL)" {
//     var buffer1 = try Buffer.init(testing.allocator, 10);
//     defer buffer1.deinit(); // This one is cleaned up
//
//     var buffer2 = try Buffer.init(testing.allocator, 10);
//     // Missing: defer buffer2.deinit();
//
//     try buffer1.appendSlice("cleaned");
//     try buffer2.appendSlice("leaked");
//
//     // Only buffer2's memory will leak
// }
