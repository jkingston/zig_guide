const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// Parser module demonstrating table-driven tests
/// Shows how to organize test cases and provide clear failure context

pub const ParseError = error{
    InvalidInput,
    Overflow,
    EmptyInput,
    OutOfMemory,
};

/// Parse an integer from a string
pub fn parseInt(str: []const u8) ParseError!i32 {
    if (str.len == 0) return error.EmptyInput;

    const result = std.fmt.parseInt(i32, str, 10) catch |err| {
        return switch (err) {
            error.Overflow => error.Overflow,
            error.InvalidCharacter => error.InvalidInput,
        };
    };

    return result;
}

/// Parse a float from a string
pub fn parseFloat(str: []const u8) ParseError!f64 {
    if (str.len == 0) return error.EmptyInput;

    const result = std.fmt.parseFloat(f64, str) catch {
        return error.InvalidInput;
    };

    return result;
}

/// Parse a boolean from a string
/// Accepts: "true", "false", "1", "0", "yes", "no" (case-insensitive)
pub fn parseBool(str: []const u8) ParseError!bool {
    if (str.len == 0) return error.EmptyInput;

    // Convert to lowercase for comparison
    var lower_buf: [32]u8 = undefined;
    if (str.len > lower_buf.len) return error.InvalidInput;

    const lower = std.ascii.lowerString(lower_buf[0..str.len], str);

    if (std.mem.eql(u8, lower, "true") or
        std.mem.eql(u8, lower, "yes") or
        std.mem.eql(u8, lower, "1"))
    {
        return true;
    }

    if (std.mem.eql(u8, lower, "false") or
        std.mem.eql(u8, lower, "no") or
        std.mem.eql(u8, lower, "0"))
    {
        return false;
    }

    return error.InvalidInput;
}

/// Parse a comma-separated list of strings
pub fn parseList(str: []const u8, allocator: Allocator) ParseError![][]const u8 {
    if (str.len == 0) return error.EmptyInput;

    var list: std.ArrayList([]const u8) = .empty;
    errdefer list.deinit(allocator);

    var iter = std.mem.splitScalar(u8, str, ',');
    while (iter.next()) |item| {
        // Trim whitespace
        const trimmed = std.mem.trim(u8, item, " \t\r\n");
        if (trimmed.len > 0) {
            const duped = allocator.dupe(u8, trimmed) catch return error.OutOfMemory;
            list.append(allocator, duped) catch return error.OutOfMemory;
        }
    }

    // If all items were whitespace, the list is empty
    if (list.items.len == 0) return error.EmptyInput;

    return list.toOwnedSlice(allocator) catch error.OutOfMemory;
}

/// Free a list allocated by parseList
pub fn freeList(list: [][]const u8, allocator: Allocator) void {
    for (list) |item| {
        allocator.free(item);
    }
    allocator.free(list);
}

/// Parse a hex string to integer (without 0x prefix)
pub fn parseHex(str: []const u8) ParseError!u32 {
    if (str.len == 0) return error.EmptyInput;

    const result = std.fmt.parseInt(u32, str, 16) catch |err| {
        return switch (err) {
            error.Overflow => error.Overflow,
            error.InvalidCharacter => error.InvalidInput,
        };
    };

    return result;
}

// ============================================================================
// Table-Driven Tests for parseInt
// ============================================================================

test "parseInt: valid integers" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        // Basic positive numbers
        .{ .input = "0", .expected = 0, .description = "zero" },
        .{ .input = "1", .expected = 1, .description = "one" },
        .{ .input = "42", .expected = 42, .description = "two digits" },
        .{ .input = "123", .expected = 123, .description = "three digits" },
        .{ .input = "999", .expected = 999, .description = "three nines" },
        .{ .input = "1000", .expected = 1000, .description = "one thousand" },
        .{ .input = "12345", .expected = 12345, .description = "five digits" },

        // Negative numbers
        .{ .input = "-1", .expected = -1, .description = "negative one" },
        .{ .input = "-42", .expected = -42, .description = "negative two digits" },
        .{ .input = "-123", .expected = -123, .description = "negative three digits" },
        .{ .input = "-999", .expected = -999, .description = "negative three nines" },

        // Edge cases
        .{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
        .{ .input = "-2147483648", .expected = -2147483648, .description = "min i32" },
    };

    for (cases) |case| {
        const result = parseInt(case.input) catch |err| {
            std.debug.print("Failed to parse '{s}' ({s}): {any}\n", .{
                case.input,
                case.description,
                err,
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for '{s}' ({s}): got {any}, expected {any}\n", .{
                case.input,
                case.description,
                result,
                case.expected,
            });
            return err;
        };
    }
}

test "parseInt: invalid input" {
    const ErrorCase = struct {
        input: []const u8,
        expected_error: ParseError,
        description: []const u8,
    };

    const cases = [_]ErrorCase{
        // Empty input
        .{ .input = "", .expected_error = error.EmptyInput, .description = "empty string" },

        // Invalid characters
        .{ .input = "abc", .expected_error = error.InvalidInput, .description = "letters only" },
        .{ .input = "12abc", .expected_error = error.InvalidInput, .description = "mixed digits and letters" },
        .{ .input = "12.34", .expected_error = error.InvalidInput, .description = "decimal point" },
        .{ .input = "12,34", .expected_error = error.InvalidInput, .description = "comma separator" },
        .{ .input = "12 34", .expected_error = error.InvalidInput, .description = "space separator" },
        .{ .input = "0x10", .expected_error = error.InvalidInput, .description = "hex prefix" },

        // Overflow
        .{ .input = "2147483648", .expected_error = error.Overflow, .description = "max i32 + 1" },
        .{ .input = "-2147483649", .expected_error = error.Overflow, .description = "min i32 - 1" },
        .{ .input = "99999999999", .expected_error = error.Overflow, .description = "way too large" },
    };

    for (cases) |case| {
        const result = parseInt(case.input);
        testing.expectError(case.expected_error, result) catch |err| {
            std.debug.print("Expected error {any} for '{s}' ({s}), got: {any}\n", .{
                case.expected_error,
                case.input,
                case.description,
                result,
            });
            return err;
        };
    }
}

// ============================================================================
// Table-Driven Tests for parseFloat
// ============================================================================

test "parseFloat: valid floats" {
    const TestCase = struct {
        input: []const u8,
        expected: f64,
        description: []const u8,
    };

    const cases = [_]TestCase{
        // Integers (valid floats)
        .{ .input = "0", .expected = 0.0, .description = "zero" },
        .{ .input = "1", .expected = 1.0, .description = "one" },
        .{ .input = "42", .expected = 42.0, .description = "integer" },

        // Decimals
        .{ .input = "3.14", .expected = 3.14, .description = "pi approximation" },
        .{ .input = "0.5", .expected = 0.5, .description = "half" },
        .{ .input = "123.456", .expected = 123.456, .description = "three decimal places" },

        // Negative
        .{ .input = "-1.5", .expected = -1.5, .description = "negative decimal" },
        .{ .input = "-42.0", .expected = -42.0, .description = "negative with .0" },

        // Scientific notation
        .{ .input = "1e3", .expected = 1000.0, .description = "1e3" },
        .{ .input = "1.5e2", .expected = 150.0, .description = "1.5e2" },
        .{ .input = "2.5e-1", .expected = 0.25, .description = "2.5e-1" },
    };

    for (cases) |case| {
        const result = parseFloat(case.input) catch |err| {
            std.debug.print("Failed to parse '{s}' ({s}): {any}\n", .{
                case.input,
                case.description,
                err,
            });
            return err;
        };

        testing.expectApproxEqRel(case.expected, result, 0.0001) catch |err| {
            std.debug.print("Wrong result for '{s}' ({s}): got {d}, expected {d}\n", .{
                case.input,
                case.description,
                result,
                case.expected,
            });
            return err;
        };
    }
}

test "parseFloat: invalid input" {
    const error_cases = [_][]const u8{
        "",          // Empty
        "abc",       // Not a number
        "12.34.56",  // Multiple decimal points
        "1.2.3",     // Multiple decimals
        "not_a_num", // Text
    };

    for (error_cases) |input| {
        const result = parseFloat(input);
        testing.expect(std.meta.isError(result)) catch |err| {
            std.debug.print("Expected error for input: '{s}'\n", .{input});
            return err;
        };
    }
}

// ============================================================================
// Table-Driven Tests for parseBool
// ============================================================================

test "parseBool: valid true values" {
    const true_cases = [_][]const u8{
        "true",
        "True",
        "TRUE",
        "yes",
        "Yes",
        "YES",
        "1",
    };

    for (true_cases) |input| {
        const result = parseBool(input) catch |err| {
            std.debug.print("Failed to parse '{s}' as true: {any}\n", .{ input, err });
            return err;
        };

        testing.expect(result == true) catch |err| {
            std.debug.print("Expected true for '{s}', got false\n", .{input});
            return err;
        };
    }
}

test "parseBool: valid false values" {
    const false_cases = [_][]const u8{
        "false",
        "False",
        "FALSE",
        "no",
        "No",
        "NO",
        "0",
    };

    for (false_cases) |input| {
        const result = parseBool(input) catch |err| {
            std.debug.print("Failed to parse '{s}' as false: {any}\n", .{ input, err });
            return err;
        };

        testing.expect(result == false) catch |err| {
            std.debug.print("Expected false for '{s}', got true\n", .{input});
            return err;
        };
    }
}

test "parseBool: invalid input" {
    const error_cases = [_][]const u8{
        "",          // Empty
        "maybe",     // Not a bool
        "2",         // Not 0 or 1
        "y",         // Abbreviated
        "n",         // Abbreviated
        "t",         // Abbreviated
        "f",         // Abbreviated
        "on",        // Alternative bool
        "off",       // Alternative bool
    };

    for (error_cases) |input| {
        const result = parseBool(input);
        testing.expect(std.meta.isError(result)) catch |err| {
            std.debug.print("Expected error for invalid bool input: '{s}'\n", .{input});
            return err;
        };
    }
}

// ============================================================================
// Table-Driven Tests for parseList
// ============================================================================

test "parseList: valid lists" {
    const TestCase = struct {
        input: []const u8,
        expected: []const []const u8,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{
            .input = "apple,banana,cherry",
            .expected = &[_][]const u8{ "apple", "banana", "cherry" },
            .description = "simple list",
        },
        .{
            .input = "one, two, three",
            .expected = &[_][]const u8{ "one", "two", "three" },
            .description = "list with spaces",
        },
        .{
            .input = "single",
            .expected = &[_][]const u8{"single"},
            .description = "single item",
        },
        .{
            .input = "a,b,c,d,e,f",
            .expected = &[_][]const u8{ "a", "b", "c", "d", "e", "f" },
            .description = "many items",
        },
        .{
            .input = "  trimmed  ,  spaces  ",
            .expected = &[_][]const u8{ "trimmed", "spaces" },
            .description = "extra whitespace",
        },
    };

    for (cases) |case| {
        const result = parseList(case.input, testing.allocator) catch |err| {
            std.debug.print("Failed to parse list '{s}' ({s}): {any}\n", .{
                case.input,
                case.description,
                err,
            });
            return err;
        };
        defer freeList(result, testing.allocator);

        testing.expectEqual(case.expected.len, result.len) catch |err| {
            std.debug.print("Wrong length for '{s}' ({s}): got {any}, expected {any}\n", .{
                case.input,
                case.description,
                result.len,
                case.expected.len,
            });
            return err;
        };

        for (case.expected, result, 0..) |expected_item, result_item, i| {
            testing.expectEqualStrings(expected_item, result_item) catch |err| {
                std.debug.print("Wrong item at index {} for '{s}' ({s}): got '{s}', expected '{s}'\n", .{
                    i,
                    case.input,
                    case.description,
                    result_item,
                    expected_item,
                });
                return err;
            };
        }
    }
}

test "parseList: empty input error" {
    const result = parseList("", testing.allocator);
    try testing.expectError(error.EmptyInput, result);
}

test "parseList: empty after trim" {
    const result = parseList("   ", testing.allocator);
    try testing.expectError(error.EmptyInput, result);
}

// ============================================================================
// Table-Driven Tests for parseHex
// ============================================================================

test "parseHex: valid hex strings" {
    const TestCase = struct {
        input: []const u8,
        expected: u32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{ .input = "0", .expected = 0, .description = "zero" },
        .{ .input = "1", .expected = 1, .description = "one" },
        .{ .input = "a", .expected = 10, .description = "lowercase a" },
        .{ .input = "A", .expected = 10, .description = "uppercase A" },
        .{ .input = "f", .expected = 15, .description = "lowercase f" },
        .{ .input = "F", .expected = 15, .description = "uppercase F" },
        .{ .input = "10", .expected = 16, .description = "hex 10" },
        .{ .input = "ff", .expected = 255, .description = "hex ff" },
        .{ .input = "FF", .expected = 255, .description = "hex FF" },
        .{ .input = "100", .expected = 256, .description = "hex 100" },
        .{ .input = "1234", .expected = 4660, .description = "hex 1234" },
        .{ .input = "ABCD", .expected = 43981, .description = "hex ABCD" },
        .{ .input = "deadbeef", .expected = 3735928559, .description = "hex deadbeef" },
    };

    for (cases) |case| {
        const result = parseHex(case.input) catch |err| {
            std.debug.print("Failed to parse hex '{s}' ({s}): {any}\n", .{
                case.input,
                case.description,
                err,
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for hex '{s}' ({s}): got {any}, expected {any}\n", .{
                case.input,
                case.description,
                result,
                case.expected,
            });
            return err;
        };
    }
}

test "parseHex: invalid input" {
    const ErrorCase = struct {
        input: []const u8,
        description: []const u8,
    };

    const cases = [_]ErrorCase{
        .{ .input = "", .description = "empty string" },
        .{ .input = "g", .description = "invalid hex char g" },
        .{ .input = "xyz", .description = "invalid hex string" },
        .{ .input = "0x10", .description = "with 0x prefix" },
        .{ .input = "12.34", .description = "with decimal point" },
        .{ .input = "12 34", .description = "with space" },
    };

    for (cases) |case| {
        const result = parseHex(case.input);
        testing.expect(std.meta.isError(result)) catch |err| {
            std.debug.print("Expected error for '{s}' ({s})\n", .{
                case.input,
                case.description,
            });
            return err;
        };
    }
}

// ============================================================================
// Integration Tests
// ============================================================================

test "parser: multiple functions with same input" {
    // Test that "42" can be parsed as different types
    const input = "42";

    const as_int = try parseInt(input);
    try testing.expectEqual(@as(i32, 42), as_int);

    const as_float = try parseFloat(input);
    try testing.expectApproxEqRel(@as(f64, 42.0), as_float, 0.0001);
}

test "parser: comprehensive edge cases" {
    // Collection of various edge cases across all parsers
    const EdgeCase = struct {
        fn testCase(description: []const u8, should_succeed: bool, test_fn: fn () anyerror!void) !void {
            test_fn() catch |err| {
                if (should_succeed) {
                    std.debug.print("Edge case '{s}' should have succeeded but failed: {any}\n", .{ description, err });
                    return err;
                }
                // Expected to fail, that's ok
                return;
            };

            if (!should_succeed) {
                std.debug.print("Edge case '{s}' should have failed but succeeded\n", .{description});
                return error.TestExpectedError;
            }
        }
    };

    // These should all succeed
    try EdgeCase.testCase("parseInt max value", true, struct {
        fn test_fn() !void {
            const result = try parseInt("2147483647");
            try testing.expectEqual(@as(i32, 2147483647), result);
        }
    }.test_fn);

    try EdgeCase.testCase("parseFloat scientific notation", true, struct {
        fn test_fn() !void {
            const result = try parseFloat("1e3");
            try testing.expectApproxEqRel(@as(f64, 1000.0), result, 0.0001);
        }
    }.test_fn);

    try EdgeCase.testCase("parseBool case insensitive", true, struct {
        fn test_fn() !void {
            const result = try parseBool("TrUe");
            try testing.expect(result == true);
        }
    }.test_fn);
}
