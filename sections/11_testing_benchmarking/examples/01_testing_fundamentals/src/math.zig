const std = @import("std");
const testing = std.testing;

// ============================================================================
// Simple Math Functions with Doctests
// ============================================================================

/// Add two integers together.
///
/// Example usage:
/// ```zig
/// const result = add(2, 3);
/// try testing.expectEqual(@as(i32, 5), result);
/// ```
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Subtract two integers.
///
/// Example usage:
/// ```zig
/// const result = subtract(10, 3);
/// try testing.expectEqual(@as(i32, 7), result);
/// ```
pub fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

/// Multiply two integers.
///
/// Example usage:
/// ```zig
/// const result = multiply(4, 5);
/// try testing.expectEqual(@as(i32, 20), result);
/// ```
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

/// Divide two integers, returning an error on division by zero.
///
/// Example usage:
/// ```zig
/// const result = try divide(10, 2);
/// try testing.expectEqual(@as(i32, 5), result);
/// ```
///
/// Error handling:
/// ```zig
/// const result = divide(10, 0);
/// try testing.expectError(error.DivisionByZero, result);
/// ```
pub fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

/// Calculate the absolute value of an integer.
pub fn abs(x: i32) i32 {
    return if (x < 0) -x else x;
}

/// Calculate the maximum of two integers.
pub fn max(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}

/// Calculate the minimum of two integers.
pub fn min(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

/// Clamp a value between min and max bounds.
pub fn clamp(value: i32, lower: i32, upper: i32) i32 {
    return max(lower, min(upper, value));
}

// ============================================================================
// Test Blocks for Math Functions
// ============================================================================

test "add: positive numbers" {
    try testing.expectEqual(@as(i32, 5), add(2, 3));
    try testing.expectEqual(@as(i32, 100), add(42, 58));
}

test "add: negative numbers" {
    try testing.expectEqual(@as(i32, -5), add(-2, -3));
    try testing.expectEqual(@as(i32, 0), add(-5, 5));
}

test "add: zero" {
    try testing.expectEqual(@as(i32, 5), add(5, 0));
    try testing.expectEqual(@as(i32, 0), add(0, 0));
}

test "subtract: basic cases" {
    try testing.expectEqual(@as(i32, 5), subtract(10, 5));
    try testing.expectEqual(@as(i32, -5), subtract(5, 10));
    try testing.expectEqual(@as(i32, 0), subtract(7, 7));
}

test "multiply: basic cases" {
    try testing.expectEqual(@as(i32, 20), multiply(4, 5));
    try testing.expectEqual(@as(i32, 0), multiply(5, 0));
    try testing.expectEqual(@as(i32, -20), multiply(-4, 5));
    try testing.expectEqual(@as(i32, 20), multiply(-4, -5));
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

test "abs: absolute value" {
    try testing.expectEqual(@as(i32, 5), abs(5));
    try testing.expectEqual(@as(i32, 5), abs(-5));
    try testing.expectEqual(@as(i32, 0), abs(0));
}

test "max: maximum of two numbers" {
    try testing.expectEqual(@as(i32, 10), max(5, 10));
    try testing.expectEqual(@as(i32, 10), max(10, 5));
    try testing.expectEqual(@as(i32, 0), max(0, -5));
    try testing.expectEqual(@as(i32, 7), max(7, 7));
}

test "min: minimum of two numbers" {
    try testing.expectEqual(@as(i32, 5), min(5, 10));
    try testing.expectEqual(@as(i32, 5), min(10, 5));
    try testing.expectEqual(@as(i32, -5), min(0, -5));
    try testing.expectEqual(@as(i32, 7), min(7, 7));
}

test "clamp: value within bounds" {
    try testing.expectEqual(@as(i32, 5), clamp(5, 0, 10));
    try testing.expectEqual(@as(i32, 0), clamp(-5, 0, 10));
    try testing.expectEqual(@as(i32, 10), clamp(15, 0, 10));
    try testing.expectEqual(@as(i32, 7), clamp(7, 0, 10));
}

// ============================================================================
// More Complex Functions for Advanced Testing
// ============================================================================

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
        // Check for overflow
        if (@divTrunc(result, @as(i64, @intCast(i))) != old_result) {
            return error.Overflow;
        }
    }
    return result;
}

/// Calculate nth Fibonacci number (iterative version).
pub fn fibonacci(n: u32) u64 {
    if (n == 0) return 0;
    if (n == 1) return 1;

    var prev: u64 = 0;
    var curr: u64 = 1;
    var i: u32 = 2;

    while (i <= n) : (i += 1) {
        const next = prev + curr;
        prev = curr;
        curr = next;
    }

    return curr;
}

/// Check if a number is prime.
pub fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    var i: u32 = 3;
    while (i * i <= n) : (i += 2) {
        if (n % i == 0) return false;
    }

    return true;
}

test "factorial: basic cases" {
    try testing.expectEqual(@as(i64, 1), try factorial(0));
    try testing.expectEqual(@as(i64, 1), try factorial(1));
    try testing.expectEqual(@as(i64, 2), try factorial(2));
    try testing.expectEqual(@as(i64, 6), try factorial(3));
    try testing.expectEqual(@as(i64, 24), try factorial(4));
    try testing.expectEqual(@as(i64, 120), try factorial(5));
}

test "factorial: error cases" {
    try testing.expectError(error.NegativeInput, factorial(-1));
    try testing.expectError(error.NegativeInput, factorial(-10));
}

test "fibonacci: sequence values" {
    try testing.expectEqual(@as(u64, 0), fibonacci(0));
    try testing.expectEqual(@as(u64, 1), fibonacci(1));
    try testing.expectEqual(@as(u64, 1), fibonacci(2));
    try testing.expectEqual(@as(u64, 2), fibonacci(3));
    try testing.expectEqual(@as(u64, 3), fibonacci(4));
    try testing.expectEqual(@as(u64, 5), fibonacci(5));
    try testing.expectEqual(@as(u64, 8), fibonacci(6));
    try testing.expectEqual(@as(u64, 13), fibonacci(7));
    try testing.expectEqual(@as(u64, 55), fibonacci(10));
}

test "isPrime: small primes" {
    try testing.expect(!isPrime(0));
    try testing.expect(!isPrime(1));
    try testing.expect(isPrime(2));
    try testing.expect(isPrime(3));
    try testing.expect(!isPrime(4));
    try testing.expect(isPrime(5));
    try testing.expect(!isPrime(6));
    try testing.expect(isPrime(7));
}

test "isPrime: larger numbers" {
    try testing.expect(isPrime(11));
    try testing.expect(isPrime(13));
    try testing.expect(!isPrime(15));
    try testing.expect(isPrime(17));
    try testing.expect(isPrime(19));
    try testing.expect(!isPrime(20));
    try testing.expect(isPrime(97));
    try testing.expect(!isPrime(100));
}
