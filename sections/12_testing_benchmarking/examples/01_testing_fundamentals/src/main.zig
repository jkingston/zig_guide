const std = @import("std");
const math = @import("math.zig");
const string_utils = @import("string_utils.zig");

pub fn main() !void {
    std.debug.print("=== Testing Fundamentals Demo ===\n\n", .{});

    // Demonstrate math functions
    std.debug.print("Math Operations:\n", .{});
    std.debug.print("  add(5, 3) = {d}\n", .{math.add(5, 3)});
    std.debug.print("  subtract(10, 4) = {d}\n", .{math.subtract(10, 4)});
    std.debug.print("  multiply(6, 7) = {d}\n", .{math.multiply(6, 7)});

    const result = math.divide(20, 4) catch |err| {
        std.debug.print("  divide error: {}\n", .{err});
        return err;
    };
    std.debug.print("  divide(20, 4) = {d}\n", .{result});

    // Demonstrate string functions
    std.debug.print("\nString Operations:\n", .{});
    const allocator = std.heap.page_allocator;

    const upper = try string_utils.toUpperCase(allocator, "hello world");
    defer allocator.free(upper);
    std.debug.print("  toUpperCase('hello world') = '{s}'\n", .{upper});

    const lower = try string_utils.toLowerCase(allocator, "HELLO WORLD");
    defer allocator.free(lower);
    std.debug.print("  toLowerCase('HELLO WORLD') = '{s}'\n", .{lower});

    const reversed = try string_utils.reverse(allocator, "testing");
    defer allocator.free(reversed);
    std.debug.print("  reverse('testing') = '{s}'\n", .{reversed});

    std.debug.print("\n✓ All operations completed successfully!\n", .{});
    std.debug.print("\nRun tests with: zig test src/main.zig\n", .{});
}

// ============================================================================
// Test Blocks
// ============================================================================
// Test blocks are standalone functions that run when 'zig test' is executed.
// They are only included in test builds, not in regular executables.

const testing = std.testing;

test "basic test block" {
    // Simple test demonstrating the test syntax
    const x = 42;
    try testing.expectEqual(@as(i32, 42), x);
}

test "testing booleans" {
    try testing.expect(true);
    try testing.expect(2 + 2 == 4);
    try testing.expect(false == false);
}

test "testing integer arithmetic" {
    const a: i32 = 5;
    const b: i32 = 3;

    try testing.expectEqual(@as(i32, 8), a + b);
    try testing.expectEqual(@as(i32, 2), a - b);
    try testing.expectEqual(@as(i32, 15), a * b);
}

test "testing error unions" {
    const result = math.divide(10, 2);
    try testing.expectEqual(@as(i32, 5), try result);

    // Test error case
    const error_result = math.divide(10, 0);
    try testing.expectError(error.DivisionByZero, error_result);
}

test "testing optional values" {
    const maybe_value: ?i32 = 42;
    const no_value: ?i32 = null;

    try testing.expectEqual(@as(i32, 42), maybe_value.?);
    try testing.expectEqual(@as(?i32, null), no_value);
}

test "testing slices and arrays" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[1..4];

    try testing.expectEqual(@as(usize, 5), array.len);
    try testing.expectEqual(@as(usize, 3), slice.len);
    try testing.expectEqualSlices(u8, &[_]u8{ 2, 3, 4 }, slice);
}

test "testing strings" {
    const str1 = "hello";
    const str2 = "hello";
    const str3 = "world";

    try testing.expectEqualStrings(str1, str2);
    try testing.expect(!std.mem.eql(u8, str1, str3));
}

// ============================================================================
// Memory Leak Detection with std.testing.allocator
// ============================================================================

test "memory allocation with testing allocator" {
    // std.testing.allocator detects memory leaks
    const allocator = testing.allocator;

    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    // Use the buffer
    @memset(buffer, 0);
    try testing.expectEqual(@as(u8, 0), buffer[50]);
}

test "memory leak detection demonstration" {
    // This test will FAIL if you uncomment the allocation without freeing
    const allocator = testing.allocator;

    // Properly managed memory
    const good_alloc = try allocator.alloc(u8, 50);
    defer allocator.free(good_alloc);

    // Uncomment below to see leak detection in action:
    // const leaked = try allocator.alloc(u8, 100);
    // // Forgot to free! Test will fail with leak detection
}

test "testing allocator with structs" {
    const allocator = testing.allocator;

    const Point = struct {
        x: f32,
        y: f32,
    };

    const point = try allocator.create(Point);
    defer allocator.destroy(point);

    point.* = .{ .x = 10.5, .y = 20.3 };

    try testing.expectEqual(@as(f32, 10.5), point.x);
    try testing.expectEqual(@as(f32, 20.3), point.y);
}

// ============================================================================
// Testing Floating Point Values
// ============================================================================

test "approximate equality for floats" {
    const a: f64 = 0.1 + 0.2;
    const b: f64 = 0.3;

    // Don't use expectEqual for floats - use approximate comparison
    try testing.expectApproxEqAbs(b, a, 0.0001);
}

test "approximate relative equality" {
    const a: f64 = 1000.001;
    const b: f64 = 1000.002;

    // Use relative tolerance for large numbers
    try testing.expectApproxEqRel(a, b, 0.001);
}

// ============================================================================
// Testing with Different Types
// ============================================================================

test "testing struct equality" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const p1 = Point{ .x = 10, .y = 20 };
    const p2 = Point{ .x = 10, .y = 20 };

    try testing.expectEqual(p1, p2);
}

test "testing enum values" {
    const Color = enum {
        red,
        green,
        blue,
    };

    const c1 = Color.red;
    const c2 = Color.red;

    try testing.expectEqual(c1, c2);
}

test "testing union values" {
    const Value = union(enum) {
        int: i32,
        float: f64,
        string: []const u8,
    };

    const v1 = Value{ .int = 42 };
    const v2 = Value{ .int = 42 };

    try testing.expectEqual(v1, v2);
}

// ============================================================================
// Nested Test Organization
// ============================================================================

test "math module integration" {
    // Test various math operations
    try testing.expectEqual(@as(i32, 8), math.add(5, 3));
    try testing.expectEqual(@as(i32, 2), math.subtract(5, 3));
    try testing.expectEqual(@as(i32, 15), math.multiply(5, 3));
    try testing.expectEqual(@as(i32, 1), try math.divide(5, 3));
}

test "string_utils module integration" {
    const allocator = testing.allocator;

    // Test string operations
    const upper = try string_utils.toUpperCase(allocator, "test");
    defer allocator.free(upper);
    try testing.expectEqualStrings("TEST", upper);

    const lower = try string_utils.toLowerCase(allocator, "TEST");
    defer allocator.free(lower);
    try testing.expectEqualStrings("test", lower);

    const rev = try string_utils.reverse(allocator, "abc");
    defer allocator.free(rev);
    try testing.expectEqualStrings("cba", rev);
}

// ============================================================================
// Comptime Testing
// ============================================================================

test "comptime evaluation" {
    comptime {
        const result = math.add(2, 3);
        if (result != 5) {
            @compileError("Math is broken!");
        }
    }
}

test "comptime type checking" {
    comptime {
        try testing.expectEqual(i32, @TypeOf(math.add(1, 2)));
    }
}
