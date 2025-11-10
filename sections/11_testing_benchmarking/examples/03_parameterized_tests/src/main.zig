const std = @import("std");
const testing = std.testing;
const parser = @import("parser.zig");
const validator = @import("validator.zig");
const calculator = @import("calculator.zig");

/// Main demonstration of parameterized testing patterns
/// Shows basic examples of table-driven and loop-based parameterized tests

pub fn main() !void {
    std.debug.print("\n=== Parameterized Tests Demo ===\n\n", .{});

    // Demonstrate calculator
    std.debug.print("Calculator Operations:\n", .{});
    std.debug.print("  2 + 3 = {}\n", .{calculator.add(2, 3)});
    std.debug.print("  10 - 4 = {}\n", .{calculator.subtract(10, 4)});
    std.debug.print("  5 * 6 = {}\n", .{calculator.multiply(5, 6)});
    std.debug.print("  20 / 4 = {}\n", .{try calculator.divide(20, 4)});
    std.debug.print("  2^10 = {}\n", .{calculator.power(2, 10)});

    // Demonstrate parser
    std.debug.print("\nParser Operations:\n", .{});
    std.debug.print("  parseInt('42') = {}\n", .{try parser.parseInt("42")});
    std.debug.print("  parseFloat('3.14') = {d}\n", .{try parser.parseFloat("3.14")});
    std.debug.print("  parseBool('true') = {}\n", .{try parser.parseBool("true")});
    std.debug.print("  parseHex('FF') = {}\n", .{try parser.parseHex("FF")});

    const allocator = std.heap.page_allocator;
    const list = try parser.parseList("apple,banana,cherry", allocator);
    defer parser.freeList(list, allocator);

    std.debug.print("  parseList('apple,banana,cherry') = [", .{});
    for (list, 0..) |item, i| {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("'{s}'", .{item});
    }
    std.debug.print("]\n", .{});

    // Demonstrate validator
    std.debug.print("\nValidator Operations:\n", .{});
    std.debug.print("  validateEmail('user@example.com') = {}\n", .{
        validator.validateEmail("user@example.com"),
    });
    std.debug.print("  validateUrl('https://example.com') = {}\n", .{
        validator.validateUrl("https://example.com"),
    });
    std.debug.print("  validatePhoneNumber('123-456-7890') = {}\n", .{
        validator.validatePhoneNumber("123-456-7890"),
    });
    std.debug.print("  validatePassword('SecureP@ss123') = {s}\n", .{
        @tagName(validator.validatePassword("SecureP@ss123")),
    });
    std.debug.print("  validateUsername('john_doe') = {}\n", .{
        validator.validateUsername("john_doe"),
    });

    std.debug.print("\nAll modules working correctly!\n", .{});
    std.debug.print("Run 'zig build test' to see parameterized tests in action.\n\n", .{});
}

// ============================================================================
// Basic Parameterized Test Examples
// ============================================================================

// Simple table-driven test with struct
test "basic table-driven test" {
    const TestCase = struct {
        input: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .input = 0, .expected = 0 },
        .{ .input = 1, .expected = 1 },
        .{ .input = 5, .expected = 5 },
        .{ .input = -3, .expected = -3 },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, case.input);
    }
}

// Loop-based parameterized test
test "loop-based parameterized test" {
    const inputs = [_]i32{ 0, 1, 2, 3, 4, 5 };

    for (inputs) |input| {
        const result = input * 2;
        try testing.expectEqual(input + input, result);
    }
}

// Test with error context
test "test with failure context" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .a = 1, .b = 1, .expected = 2 },
        .{ .a = 5, .b = 3, .expected = 8 },
        .{ .a = -2, .b = 2, .expected = 0 },
    };

    for (cases) |case| {
        const result = case.a + case.b;
        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Failed: {any} + {any} should equal {any}, got {any}\n", .{
                case.a,
                case.b,
                case.expected,
                result,
            });
            return err;
        };
    }
}

// Parameterized error testing
test "parameterized error testing" {
    const ErrorCase = struct {
        input: []const u8,
        expected_error: parser.ParseError,
    };

    const cases = [_]ErrorCase{
        .{ .input = "", .expected_error = error.EmptyInput },
        .{ .input = "abc", .expected_error = error.InvalidInput },
        .{ .input = "99999999999", .expected_error = error.Overflow },
    };

    for (cases) |case| {
        const result = parser.parseInt(case.input);
        testing.expectError(case.expected_error, result) catch |err| {
            std.debug.print("Expected error {any} for input '{s}'\n", .{
                case.expected_error,
                case.input,
            });
            return err;
        };
    }
}

// Multiple assertions per test case
test "multiple assertions per case" {
    const TestCase = struct {
        input: []const u8,
        email_valid: bool,
        url_valid: bool,
    };

    const cases = [_]TestCase{
        .{
            .input = "http://example.com",
            .email_valid = false,
            .url_valid = true,
        },
        .{
            .input = "user@example.com",
            .email_valid = true,
            .url_valid = false,
        },
        .{
            .input = "not-valid",
            .email_valid = false,
            .url_valid = false,
        },
    };

    for (cases) |case| {
        const email_result = validator.validateEmail(case.input);
        const url_result = validator.validateUrl(case.input);

        testing.expectEqual(case.email_valid, email_result) catch |err| {
            std.debug.print("Email validation failed for '{s}'\n", .{case.input});
            return err;
        };

        testing.expectEqual(case.url_valid, url_result) catch |err| {
            std.debug.print("URL validation failed for '{s}'\n", .{case.input});
            return err;
        };
    }
}

// ============================================================================
// String Operation Tests (Demonstrating Different Patterns)
// ============================================================================

fn stringLength(s: []const u8) usize {
    return s.len;
}

fn stringIsEmpty(s: []const u8) bool {
    return s.len == 0;
}

fn stringStartsWith(s: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, s, prefix);
}

test "stringLength: multiple inputs" {
    const TestCase = struct {
        input: []const u8,
        expected: usize,
    };

    const cases = [_]TestCase{
        .{ .input = "", .expected = 0 },
        .{ .input = "a", .expected = 1 },
        .{ .input = "hello", .expected = 5 },
        .{ .input = "hello world", .expected = 11 },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, stringLength(case.input));
    }
}

test "stringIsEmpty: multiple inputs" {
    const TestCase = struct {
        input: []const u8,
        expected: bool,
    };

    const cases = [_]TestCase{
        .{ .input = "", .expected = true },
        .{ .input = " ", .expected = false },
        .{ .input = "a", .expected = false },
        .{ .input = "hello", .expected = false },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, stringIsEmpty(case.input));
    }
}

test "stringStartsWith: multiple inputs" {
    const TestCase = struct {
        input: []const u8,
        prefix: []const u8,
        expected: bool,
    };

    const cases = [_]TestCase{
        .{ .input = "hello", .prefix = "he", .expected = true },
        .{ .input = "hello", .prefix = "hello", .expected = true },
        .{ .input = "hello", .prefix = "hi", .expected = false },
        .{ .input = "hello", .prefix = "", .expected = true },
        .{ .input = "", .prefix = "a", .expected = false },
        .{ .input = "test", .prefix = "testing", .expected = false },
    };

    for (cases) |case| {
        const result = stringStartsWith(case.input, case.prefix);
        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Failed: stringStartsWith('{s}', '{s}') should be {any}\n", .{
                case.input,
                case.prefix,
                case.expected,
            });
            return err;
        };
    }
}

// ============================================================================
// Math Operation Tests (Demonstrating Range Testing)
// ============================================================================

fn isEven(n: i32) bool {
    return @mod(n, 2) == 0;
}

fn isPositive(n: i32) bool {
    return n > 0;
}

fn absoluteValue(n: i32) i32 {
    return if (n < 0) -n else n;
}

test "isEven: range of inputs" {
    const TestCase = struct {
        input: i32,
        expected: bool,
    };

    const cases = [_]TestCase{
        .{ .input = 0, .expected = true },
        .{ .input = 1, .expected = false },
        .{ .input = 2, .expected = true },
        .{ .input = 3, .expected = false },
        .{ .input = -2, .expected = true },
        .{ .input = -3, .expected = false },
        .{ .input = 100, .expected = true },
        .{ .input = 101, .expected = false },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, isEven(case.input));
    }
}

test "isPositive: boundary testing" {
    const TestCase = struct {
        input: i32,
        expected: bool,
    };

    const cases = [_]TestCase{
        .{ .input = -100, .expected = false },
        .{ .input = -1, .expected = false },
        .{ .input = 0, .expected = false }, // Zero is not positive
        .{ .input = 1, .expected = true },
        .{ .input = 100, .expected = true },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, isPositive(case.input));
    }
}

test "absoluteValue: comprehensive" {
    const TestCase = struct {
        input: i32,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{ .input = 0, .expected = 0, .description = "zero" },
        .{ .input = 5, .expected = 5, .description = "positive" },
        .{ .input = -5, .expected = 5, .description = "negative" },
        .{ .input = 100, .expected = 100, .description = "large positive" },
        .{ .input = -100, .expected = 100, .description = "large negative" },
    };

    for (cases) |case| {
        const result = absoluteValue(case.input);
        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Failed for {s}: abs({any}) should be {any}\n", .{
                case.description,
                case.input,
                case.expected,
            });
            return err;
        };
    }
}

// ============================================================================
// Integration Tests with Multiple Modules
// ============================================================================

test "integration: parse and validate" {
    // Test parsing integers and validating them
    const valid_int_strings = [_][]const u8{ "0", "42", "-123", "999" };

    for (valid_int_strings) |str| {
        const value = try parser.parseInt(str);
        // All successfully parsed integers should be valid (not necessarily positive)
        _ = value; // Just checking it parses
    }
}

test "integration: calculator and parser" {
    // Parse numbers and use calculator
    const a = try parser.parseInt("10");
    const b = try parser.parseInt("5");

    try testing.expectEqual(@as(i32, 15), calculator.add(a, b));
    try testing.expectEqual(@as(i32, 5), calculator.subtract(a, b));
    try testing.expectEqual(@as(i32, 50), calculator.multiply(a, b));
    try testing.expectEqual(@as(i32, 2), try calculator.divide(a, b));
}

test "integration: validator combinations" {
    // Test that validators work correctly together
    const TestCase = struct {
        email: []const u8,
        url: []const u8,
        phone: []const u8,
        username: []const u8,
        all_should_be_valid: bool,
    };

    const cases = [_]TestCase{
        .{
            .email = "user@example.com",
            .url = "https://example.com",
            .phone = "123-456-7890",
            .username = "user123",
            .all_should_be_valid = true,
        },
        .{
            .email = "invalid",
            .url = "not-a-url",
            .phone = "123",
            .username = "u",
            .all_should_be_valid = false,
        },
    };

    for (cases) |case| {
        const email_valid = validator.validateEmail(case.email);
        const url_valid = validator.validateUrl(case.url);
        const phone_valid = validator.validatePhoneNumber(case.phone);
        const username_valid = validator.validateUsername(case.username);

        const all_valid = email_valid and url_valid and phone_valid and username_valid;

        try testing.expectEqual(case.all_should_be_valid, all_valid);
    }
}
