// Example 8: Parameterized Tests
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

// Test arithmetic operations with multiple test cases
test "add: parameterized cases" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .a = 0, .b = 0, .expected = 0 },
        .{ .a = 1, .b = 2, .expected = 3 },
        .{ .a = -5, .b = 5, .expected = 0 },
        .{ .a = 100, .b = -50, .expected = 50 },
        .{ .a = 2147483647, .b = 0, .expected = 2147483647 },
    };

    inline for (cases) |case| {
        const result = case.a + case.b;
        try testing.expectEqual(case.expected, result);
    }
}

// Test string operations across multiple inputs
test "string length: table-driven" {
    const cases = [_]struct {
        input: []const u8,
        expected: usize,
    }{
        .{ .input = "", .expected = 0 },
        .{ .input = "a", .expected = 1 },
        .{ .input = "hello", .expected = 5 },
        .{ .input = "Hello, World!", .expected = 13 },
    };

    inline for (cases) |case| {
        try testing.expectEqual(case.expected, case.input.len);
    }
}

// Test generic operations across multiple types
test "ArrayList: generic type testing" {
    const types = [_]type{ u8, u16, u32, u64, i8, i16, i32, i64 };

    inline for (types) |T| {
        var list = std.ArrayList(T){};
        defer list.deinit(testing.allocator);

        const test_value: T = 42;
        try list.append(testing.allocator, test_value);

        try testing.expectEqual(@as(usize, 1), list.items.len);
        try testing.expectEqual(test_value, list.items[0]);
    }
}

// Comptime test generation for powers of two
test "powers of two: comptime generation" {
    const powers = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 };

    inline for (powers, 0..) |expected, i| {
        const result = std.math.pow(u32, 2, i);
        try testing.expectEqual(expected, result);
    }
}