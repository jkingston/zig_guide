const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// A string builder for efficient string concatenation.
/// Demonstrates proper memory management with dynamic buffer allocations.
pub const StringBuilder = struct {
    data: []u8,
    length: usize,
    capacity: usize,
    allocator: Allocator,

    /// Initialize a new StringBuilder with the given allocator.
    pub fn init(allocator: Allocator) StringBuilder {
        return StringBuilder{
            .data = &[_]u8{},
            .length = 0,
            .capacity = 0,
            .allocator = allocator,
        };
    }

    /// Free all memory used by the StringBuilder.
    pub fn deinit(self: *StringBuilder) void {
        if (self.capacity > 0) {
            self.allocator.free(self.data);
        }
        self.* = undefined;
    }

    /// Append a single character to the builder.
    pub fn append(self: *StringBuilder, char: u8) !void {
        if (self.length >= self.capacity) {
            try self.grow();
        }
        self.data[self.length] = char;
        self.length += 1;
    }

    /// Append a string slice to the builder.
    pub fn appendSlice(self: *StringBuilder, str: []const u8) !void {
        const new_len = self.length + str.len;
        if (new_len > self.capacity) {
            try self.ensureCapacity(new_len);
        }
        @memcpy(self.data[self.length..][0..str.len], str);
        self.length = new_len;
    }

    /// Append a formatted string to the builder.
    pub fn print(self: *StringBuilder, comptime fmt: []const u8, args: anytype) !void {
        const w = writer(self);
        try std.fmt.format(w, fmt, args);
    }

    /// Get a writer for the StringBuilder.
    pub fn writer(self: *StringBuilder) std.io.GenericWriter(*StringBuilder, Allocator.Error, writerWrite) {
        return .{ .context = self };
    }

    fn writerWrite(self: *StringBuilder, bytes: []const u8) Allocator.Error!usize {
        try self.appendSlice(bytes);
        return bytes.len;
    }

    /// Get the current length of the builder.
    pub fn len(self: *const StringBuilder) usize {
        return self.length;
    }

    /// Clear the builder, removing all content but keeping capacity.
    pub fn clear(self: *StringBuilder) void {
        self.length = 0;
    }

    /// Convert to a string, allocating new memory for the result.
    /// Caller owns the returned memory.
    pub fn toString(self: *const StringBuilder) ![]u8 {
        return self.allocator.dupe(u8, self.data[0..self.length]);
    }

    /// Convert to a string slice (non-owning).
    pub fn toSlice(self: *const StringBuilder) []const u8 {
        return self.data[0..self.length];
    }

    /// Convert to an owned slice, consuming the StringBuilder.
    /// After calling this, the StringBuilder is empty but can be reused.
    pub fn toOwnedSlice(self: *StringBuilder) ![]u8 {
        const result = try self.allocator.realloc(self.data, self.length);
        self.data = &[_]u8{};
        self.length = 0;
        self.capacity = 0;
        return result;
    }

    fn grow(self: *StringBuilder) !void {
        const new_capacity = if (self.capacity == 0) 16 else self.capacity * 2;
        const new_data = try self.allocator.realloc(self.data, new_capacity);
        self.data = new_data;
        self.capacity = new_capacity;
    }

    fn ensureCapacity(self: *StringBuilder, min_capacity: usize) !void {
        if (self.capacity >= min_capacity) return;
        var new_capacity = if (self.capacity == 0) 16 else self.capacity;
        while (new_capacity < min_capacity) {
            new_capacity *= 2;
        }
        const new_data = try self.allocator.realloc(self.data, new_capacity);
        self.data = new_data;
        self.capacity = new_capacity;
    }
};

// ============================================================================
// TESTS: String allocation and memory management patterns
// ============================================================================

test "StringBuilder: basic initialization and cleanup" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try testing.expectEqual(@as(usize, 0), builder.len());
}

test "StringBuilder: append single character" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.append('A');
    try testing.expectEqual(@as(usize, 1), builder.len());
    try testing.expectEqualSlices(u8, "A", builder.toSlice());
}

test "StringBuilder: append multiple characters" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.append('H');
    try builder.append('i');
    try builder.append('!');

    try testing.expectEqualSlices(u8, "Hi!", builder.toSlice());
}

test "StringBuilder: append string slice" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("Hello, World!");
    try testing.expectEqualSlices(u8, "Hello, World!", builder.toSlice());
}

test "StringBuilder: multiple append slices" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("Hello");
    try builder.appendSlice(", ");
    try builder.appendSlice("World");
    try builder.appendSlice("!");

    try testing.expectEqualSlices(u8, "Hello, World!", builder.toSlice());
}

test "StringBuilder: print formatted text" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.print("Number: {d}", .{42});
    try testing.expectEqualSlices(u8, "Number: 42", builder.toSlice());
}

test "StringBuilder: print multiple formatted strings" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.print("x = {d}, ", .{10});
    try builder.print("y = {d}", .{20});

    try testing.expectEqualSlices(u8, "x = 10, y = 20", builder.toSlice());
}

test "StringBuilder: clear and reuse" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("first");
    try testing.expectEqualSlices(u8, "first", builder.toSlice());

    builder.clear();
    try testing.expectEqual(@as(usize, 0), builder.len());

    try builder.appendSlice("second");
    try testing.expectEqualSlices(u8, "second", builder.toSlice());
}

test "StringBuilder: toString creates owned copy" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("test string");

    const str = try builder.toString();
    defer testing.allocator.free(str);

    try testing.expectEqualSlices(u8, "test string", str);

    // Original builder is still valid
    try testing.expectEqualSlices(u8, "test string", builder.toSlice());
}

test "StringBuilder: toString ownership transfer" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("owned");

    const str = try builder.toString();
    defer testing.allocator.free(str); // Must free this!

    // Modify original builder
    builder.clear();
    try builder.appendSlice("modified");

    // Owned string is unchanged
    try testing.expectEqualSlices(u8, "owned", str);
    try testing.expectEqualSlices(u8, "modified", builder.toSlice());
}

test "StringBuilder: toOwnedSlice consumes builder" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("consumed");

    const str = try builder.toOwnedSlice();
    defer testing.allocator.free(str);

    try testing.expectEqualSlices(u8, "consumed", str);

    // Builder is now empty but still valid for reuse
    try testing.expectEqual(@as(usize, 0), builder.len());
}

test "StringBuilder: empty builder operations" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try testing.expectEqual(@as(usize, 0), builder.len());
    try testing.expectEqualSlices(u8, "", builder.toSlice());

    const str = try builder.toString();
    defer testing.allocator.free(str);
    try testing.expectEqualSlices(u8, "", str);
}

test "StringBuilder: large string concatenation" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try builder.print("{d} ", .{i});
    }

    const result = builder.toSlice();
    try testing.expect(result.len > 100);
    try testing.expect(std.mem.startsWith(u8, result, "0 1 2 3"));
}

test "StringBuilder: multiple builders independent" {
    var builder1 = StringBuilder.init(testing.allocator);
    defer builder1.deinit();

    var builder2 = StringBuilder.init(testing.allocator);
    defer builder2.deinit();

    try builder1.appendSlice("first");
    try builder2.appendSlice("second");

    try testing.expectEqualSlices(u8, "first", builder1.toSlice());
    try testing.expectEqualSlices(u8, "second", builder2.toSlice());
}

test "StringBuilder: allocation failure on appendSlice" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });
    const allocator = failing.allocator();

    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    // First allocation should fail
    const result = builder.appendSlice("this will fail");
    try testing.expectError(error.OutOfMemory, result);
}

test "StringBuilder: allocation failure on toString" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 1, // Allow appendSlice, fail on toString's dupe
    });

    // Create a builder with failing allocator
    var failing_builder = StringBuilder.init(failing.allocator());
    defer failing_builder.deinit();

    try failing_builder.appendSlice("test");

    const result = failing_builder.toString();
    try testing.expectError(error.OutOfMemory, result);
}

test "StringBuilder: clear multiple times" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("first");
    builder.clear();

    try builder.appendSlice("second");
    builder.clear();

    try builder.appendSlice("third");

    try testing.expectEqualSlices(u8, "third", builder.toSlice());
}

test "StringBuilder: mixed operations" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("Name: ");
    try builder.append('J');
    try builder.append('o');
    try builder.append('e');
    try builder.print(", Age: {d}", .{30});

    try testing.expectEqualSlices(u8, "Name: Joe, Age: 30", builder.toSlice());
}

test "StringBuilder: using with ArenaAllocator" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var builder = StringBuilder.init(allocator);
    // No need to call builder.deinit() with arena

    try builder.appendSlice("test");

    const str = try builder.toString();
    // No need to free str with arena

    try testing.expectEqualSlices(u8, "test", str);
}

test "StringBuilder: stress test many operations" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        try builder.append('x');
    }

    try testing.expectEqual(@as(usize, 1000), builder.len());
}

test "StringBuilder: automatic growth" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    // Start with zero capacity
    try testing.expectEqual(@as(usize, 0), builder.capacity);

    // Append should trigger growth
    try builder.append('A');
    try testing.expect(builder.capacity >= 1);

    // Append more to trigger additional growth
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try builder.append('x');
    }

    try testing.expect(builder.capacity >= 101);
}

// ============================================================================
// INTENTIONALLY FAILING TESTS (commented out)
// ============================================================================

// test "StringBuilder: LEAK DEMO - forgot deinit (WILL FAIL)" {
//     var builder = StringBuilder.init(testing.allocator);
//     // Missing: defer builder.deinit();
//
//     try builder.appendSlice("This will leak!");
//
//     // Zig will detect the leak from the internal buffer allocation
// }

// test "StringBuilder: LEAK DEMO - forgot to free toString result (WILL FAIL)" {
//     var builder = StringBuilder.init(testing.allocator);
//     defer builder.deinit();
//
//     try builder.appendSlice("test");
//
//     const str = try builder.toString();
//     // Missing: defer testing.allocator.free(str);
//     _ = str;
//
//     // The duplicated string will leak!
// }

// test "StringBuilder: LEAK DEMO - multiple leaks (WILL FAIL)" {
//     var builder1 = StringBuilder.init(testing.allocator);
//     defer builder1.deinit();
//
//     var builder2 = StringBuilder.init(testing.allocator);
//     // Missing: defer builder2.deinit();
//
//     try builder1.appendSlice("cleaned");
//     try builder2.appendSlice("leaked");
//
//     const str1 = try builder1.toString();
//     defer testing.allocator.free(str1);
//
//     const str2 = try builder2.toString();
//     // Missing: defer testing.allocator.free(str2);
//     _ = str2;
//
//     // Multiple leaks: builder2 and str2
// }
