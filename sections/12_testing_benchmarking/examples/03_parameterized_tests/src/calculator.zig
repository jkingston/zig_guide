const std = @import("std");
const testing = std.testing;

/// Calculator module demonstrating comptime test generation
/// Shows how to use comptime to reduce test boilerplate

pub const CalculatorError = error{
    DivisionByZero,
    Overflow,
};

/// Add two integers
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Subtract two integers
pub fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

/// Multiply two integers
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

/// Divide two integers with error handling
pub fn divide(a: i32, b: i32) CalculatorError!i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

/// Raise base to power (returns i64 to handle larger results)
pub fn power(base: i32, exp: u32) i64 {
    if (exp == 0) return 1;
    var result: i64 = base;
    var i: u32 = 1;
    while (i < exp) : (i += 1) {
        result *= base;
    }
    return result;
}

/// Modulo operation
pub fn mod(a: i32, b: i32) CalculatorError!i32 {
    if (b == 0) return error.DivisionByZero;
    return @mod(a, b);
}

// ============================================================================
// Comptime Test Generation
// ============================================================================

/// Helper function to generate addition tests at comptime
/// This reduces boilerplate and ensures consistent test structure
fn testAddition(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = add(a, b);
    try testing.expectEqual(expected, result);
}

/// Helper function to generate subtraction tests at comptime
fn testSubtraction(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = subtract(a, b);
    try testing.expectEqual(expected, result);
}

/// Helper function to generate multiplication tests at comptime
fn testMultiplication(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = multiply(a, b);
    try testing.expectEqual(expected, result);
}

/// Helper function to generate power tests at comptime
fn testPower(comptime base: i32, comptime exp: u32, comptime expected: i64) !void {
    const result = power(base, exp);
    try testing.expectEqual(expected, result);
}

// ============================================================================
// Generated Tests - Addition
// ============================================================================

test "add: 0 + 0 = 0" {
    try testAddition(0, 0, 0);
}

test "add: 1 + 1 = 2" {
    try testAddition(1, 1, 2);
}

test "add: 2 + 3 = 5" {
    try testAddition(2, 3, 5);
}

test "add: 10 + 20 = 30" {
    try testAddition(10, 20, 30);
}

test "add: -5 + 5 = 0" {
    try testAddition(-5, 5, 0);
}

test "add: -10 + -20 = -30" {
    try testAddition(-10, -20, -30);
}

test "add: 100 + (-50) = 50" {
    try testAddition(100, -50, 50);
}

// ============================================================================
// Generated Tests - Subtraction
// ============================================================================

test "subtract: 5 - 3 = 2" {
    try testSubtraction(5, 3, 2);
}

test "subtract: 10 - 10 = 0" {
    try testSubtraction(10, 10, 0);
}

test "subtract: 0 - 5 = -5" {
    try testSubtraction(0, 5, -5);
}

test "subtract: -5 - 5 = -10" {
    try testSubtraction(-5, 5, -10);
}

test "subtract: 100 - 200 = -100" {
    try testSubtraction(100, 200, -100);
}

// ============================================================================
// Generated Tests - Multiplication
// ============================================================================

test "multiply: 2 * 3 = 6" {
    try testMultiplication(2, 3, 6);
}

test "multiply: 0 * 100 = 0" {
    try testMultiplication(0, 100, 0);
}

test "multiply: -5 * 4 = -20" {
    try testMultiplication(-5, 4, -20);
}

test "multiply: -3 * -3 = 9" {
    try testMultiplication(-3, -3, 9);
}

test "multiply: 10 * 10 = 100" {
    try testMultiplication(10, 10, 100);
}

// ============================================================================
// Generated Tests - Power
// ============================================================================

test "power: 2^0 = 1" {
    try testPower(2, 0, 1);
}

test "power: 2^1 = 2" {
    try testPower(2, 1, 2);
}

test "power: 2^10 = 1024" {
    try testPower(2, 10, 1024);
}

test "power: 3^4 = 81" {
    try testPower(3, 4, 81);
}

test "power: 5^3 = 125" {
    try testPower(5, 3, 125);
}

test "power: 10^2 = 100" {
    try testPower(10, 2, 100);
}

test "power: -2^3 = -8" {
    try testPower(-2, 3, -8);
}

// ============================================================================
// Table-Driven Tests for Division
// ============================================================================

test "divide: valid operations" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{ .a = 10, .b = 2, .expected = 5, .description = "simple division" },
        .{ .a = 20, .b = 4, .expected = 5, .description = "another simple division" },
        .{ .a = 100, .b = 10, .expected = 10, .description = "division by 10" },
        .{ .a = 7, .b = 2, .expected = 3, .description = "truncated division" },
        .{ .a = -10, .b = 2, .expected = -5, .description = "negative dividend" },
        .{ .a = 10, .b = -2, .expected = -5, .description = "negative divisor" },
        .{ .a = -10, .b = -2, .expected = 5, .description = "both negative" },
        .{ .a = 0, .b = 5, .expected = 0, .description = "zero dividend" },
    };

    for (cases) |case| {
        const result = divide(case.a, case.b) catch |err| {
            std.debug.print("Failed for {s}: {} / {} should equal {}\n", .{
                case.description,
                case.a,
                case.b,
                case.expected,
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for {s}: got {}, expected {}\n", .{
                case.description,
                result,
                case.expected,
            });
            return err;
        };
    }
}

test "divide: division by zero errors" {
    const test_cases = [_]i32{ 0, 1, -1, 100, -100, 999 };

    for (test_cases) |numerator| {
        const result = divide(numerator, 0);
        testing.expectError(error.DivisionByZero, result) catch |err| {
            std.debug.print("Expected DivisionByZero error for {} / 0\n", .{numerator});
            return err;
        };
    }
}

// ============================================================================
// Table-Driven Tests for Modulo
// ============================================================================

test "mod: valid operations" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .a = 10, .b = 3, .expected = 1 },
        .{ .a = 15, .b = 4, .expected = 3 },
        .{ .a = 20, .b = 7, .expected = 6 },
        .{ .a = 100, .b = 10, .expected = 0 },
        .{ .a = 7, .b = 2, .expected = 1 },
    };

    for (cases) |case| {
        const result = try mod(case.a, case.b);
        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Failed: {} mod {} should equal {}, got {}\n", .{
                case.a,
                case.b,
                case.expected,
                result,
            });
            return err;
        };
    }
}

test "mod: modulo by zero errors" {
    const test_cases = [_]i32{ 1, 10, 100 };

    for (test_cases) |numerator| {
        const result = mod(numerator, 0);
        try testing.expectError(error.DivisionByZero, result);
    }
}

// ============================================================================
// Combined Operation Tests
// ============================================================================

test "calculator: combined operations" {
    // (5 + 3) * 2 = 16
    const sum = add(5, 3);
    const product = multiply(sum, 2);
    try testing.expectEqual(16, product);

    // (20 / 4) - 2 = 3
    const quotient = try divide(20, 4);
    const difference = subtract(quotient, 2);
    try testing.expectEqual(3, difference);

    // 2^3 + 10 = 18
    const pow = power(2, 3);
    const result = add(@as(i32, @intCast(pow)), 10);
    try testing.expectEqual(18, result);
}
