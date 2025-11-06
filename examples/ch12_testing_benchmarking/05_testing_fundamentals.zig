// Example 5: Testing Fundamentals
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const testing = std.testing;

/// Divide two integers, returning an error on division by zero.
pub fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

/// Calculate factorial (iterative version).
/// Returns error on negative input or overflow.
pub fn factorial(n: i32) !i64 {
    if (n < 0) return error.NegativeInput;
    if (n == 0 or n == 1) return 1;

    var result: i64 = 1;
    var i: i32 = 2;
    while (i <= n) : (i += 1) {
        const old_result = result;
        result = @as(i64, @intCast(i)) * result;
        if (@divTrunc(result, @as(i64, @intCast(i))) != old_result) {
            return error.Overflow;
        }
    }
    return result;
}

test "divide: successful division" {
    try testing.expectEqual(@as(i32, 5), try divide(10, 2));
    try testing.expectEqual(@as(i32, 1), try divide(7, 5));
    try testing.expectEqual(@as(i32, -2), try divide(-10, 5));
}

test "divide: division by zero" {
    try testing.expectError(error.DivisionByZero, divide(10, 0));
    try testing.expectError(error.DivisionByZero, divide(0, 0));
    try testing.expectError(error.DivisionByZero, divide(-10, 0));
}

test "factorial: basic cases" {
    try testing.expectEqual(@as(i64, 1), try factorial(0));
    try testing.expectEqual(@as(i64, 1), try factorial(1));
    try testing.expectEqual(@as(i64, 6), try factorial(3));
    try testing.expectEqual(@as(i64, 120), try factorial(5));
}

test "factorial: error cases" {
    try testing.expectError(error.NegativeInput, factorial(-1));
    try testing.expectError(error.NegativeInput, factorial(-10));
}