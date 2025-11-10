const std = @import("std");
const testing = std.testing;

test "basic assertions" {
    try testing.expectEqual(@as(i32, 5), 2 + 3);
    try testing.expect(true);
}

test "string and slice testing" {
    try testing.expectEqualStrings("hello", "hello");
    const a = [_]i32{1, 2, 3};
    const b = [_]i32{1, 2, 3};
    try testing.expectEqualSlices(i32, &a, &b);
}

test "memory leak detection" {
    const allocator = testing.allocator;
    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);
}

test "table-driven" {
    const cases = [_]struct { input: i32, expected: i32 }{
        .{ .input = 0, .expected = 0 },
        .{ .input = 2, .expected = 4 },
    };
    for (cases) |case| {
        try testing.expectEqual(case.expected, case.input * case.input);
    }
}
