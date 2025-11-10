const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

// ============================================================================
// String Utility Functions
// ============================================================================

/// Convert a string to uppercase.
/// Caller owns the returned memory and must free it.
pub fn toUpperCase(allocator: Allocator, input: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, input.len);
    for (input, 0..) |c, i| {
        result[i] = std.ascii.toUpper(c);
    }
    return result;
}

/// Convert a string to lowercase.
/// Caller owns the returned memory and must free it.
pub fn toLowerCase(allocator: Allocator, input: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, input.len);
    for (input, 0..) |c, i| {
        result[i] = std.ascii.toLower(c);
    }
    return result;
}

/// Reverse a string.
/// Caller owns the returned memory and must free it.
pub fn reverse(allocator: Allocator, input: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, input.len);
    for (input, 0..) |c, i| {
        result[input.len - 1 - i] = c;
    }
    return result;
}

/// Check if a string starts with a given prefix.
pub fn startsWith(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    return std.mem.eql(u8, haystack[0..needle.len], needle);
}

/// Check if a string ends with a given suffix.
pub fn endsWith(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    const start = haystack.len - needle.len;
    return std.mem.eql(u8, haystack[start..], needle);
}

/// Count occurrences of a character in a string.
pub fn countChar(input: []const u8, char: u8) usize {
    var count: usize = 0;
    for (input) |c| {
        if (c == char) count += 1;
    }
    return count;
}

/// Trim whitespace from both ends of a string.
pub fn trim(input: []const u8) []const u8 {
    return std.mem.trim(u8, input, &std.ascii.whitespace);
}

/// Split a string by a delimiter.
/// Returns a slice of slices. Caller owns the outer slice.
pub fn split(allocator: Allocator, input: []const u8, delimiter: u8) ![][]const u8 {
    // Count segments first
    var count: usize = 1;
    for (input) |c| {
        if (c == delimiter) count += 1;
    }

    // Allocate result array
    const result = try allocator.alloc([]const u8, count);
    errdefer allocator.free(result);

    // Fill result
    var iterator = std.mem.splitScalar(u8, input, delimiter);
    var i: usize = 0;
    while (iterator.next()) |segment| : (i += 1) {
        result[i] = segment;
    }

    return result;
}

/// Join an array of strings with a delimiter.
/// Caller owns the returned memory and must free it.
pub fn join(allocator: Allocator, parts: []const []const u8, delimiter: []const u8) ![]u8 {
    if (parts.len == 0) return try allocator.alloc(u8, 0);

    // Calculate total length
    var total_len: usize = 0;
    for (parts, 0..) |part, i| {
        total_len += part.len;
        if (i < parts.len - 1) total_len += delimiter.len;
    }

    // Allocate and join
    const result = try allocator.alloc(u8, total_len);
    var pos: usize = 0;

    for (parts, 0..) |part, i| {
        @memcpy(result[pos .. pos + part.len], part);
        pos += part.len;

        if (i < parts.len - 1) {
            @memcpy(result[pos .. pos + delimiter.len], delimiter);
            pos += delimiter.len;
        }
    }

    return result;
}

// ============================================================================
// Tests
// ============================================================================

test "toUpperCase: basic conversion" {
    const allocator = testing.allocator;

    const result = try toUpperCase(allocator, "hello world");
    defer allocator.free(result);

    try testing.expectEqualStrings("HELLO WORLD", result);
}

test "toUpperCase: already uppercase" {
    const allocator = testing.allocator;

    const result = try toUpperCase(allocator, "HELLO");
    defer allocator.free(result);

    try testing.expectEqualStrings("HELLO", result);
}

test "toUpperCase: mixed case" {
    const allocator = testing.allocator;

    const result = try toUpperCase(allocator, "HeLLo WoRLd");
    defer allocator.free(result);

    try testing.expectEqualStrings("HELLO WORLD", result);
}

test "toUpperCase: empty string" {
    const allocator = testing.allocator;

    const result = try toUpperCase(allocator, "");
    defer allocator.free(result);

    try testing.expectEqualStrings("", result);
}

test "toLowerCase: basic conversion" {
    const allocator = testing.allocator;

    const result = try toLowerCase(allocator, "HELLO WORLD");
    defer allocator.free(result);

    try testing.expectEqualStrings("hello world", result);
}

test "toLowerCase: already lowercase" {
    const allocator = testing.allocator;

    const result = try toLowerCase(allocator, "hello");
    defer allocator.free(result);

    try testing.expectEqualStrings("hello", result);
}

test "reverse: basic string" {
    const allocator = testing.allocator;

    const result = try reverse(allocator, "hello");
    defer allocator.free(result);

    try testing.expectEqualStrings("olleh", result);
}

test "reverse: single character" {
    const allocator = testing.allocator;

    const result = try reverse(allocator, "a");
    defer allocator.free(result);

    try testing.expectEqualStrings("a", result);
}

test "reverse: empty string" {
    const allocator = testing.allocator;

    const result = try reverse(allocator, "");
    defer allocator.free(result);

    try testing.expectEqualStrings("", result);
}

test "reverse: palindrome" {
    const allocator = testing.allocator;

    const result = try reverse(allocator, "racecar");
    defer allocator.free(result);

    try testing.expectEqualStrings("racecar", result);
}

test "startsWith: basic cases" {
    try testing.expect(startsWith("hello world", "hello"));
    try testing.expect(startsWith("hello world", "h"));
    try testing.expect(startsWith("hello world", ""));
    try testing.expect(!startsWith("hello world", "world"));
    try testing.expect(!startsWith("hello world", "hello world!"));
}

test "endsWith: basic cases" {
    try testing.expect(endsWith("hello world", "world"));
    try testing.expect(endsWith("hello world", "d"));
    try testing.expect(endsWith("hello world", ""));
    try testing.expect(!endsWith("hello world", "hello"));
    try testing.expect(!endsWith("hello world", "!hello world"));
}

test "countChar: basic counting" {
    try testing.expectEqual(@as(usize, 3), countChar("hello world", 'l'));
    try testing.expectEqual(@as(usize, 1), countChar("hello world", 'h'));
    try testing.expectEqual(@as(usize, 0), countChar("hello world", 'z'));
    try testing.expectEqual(@as(usize, 0), countChar("", 'a'));
}

test "trim: whitespace removal" {
    try testing.expectEqualStrings("hello", trim("  hello  "));
    try testing.expectEqualStrings("hello", trim("hello"));
    try testing.expectEqualStrings("hello", trim("\t\nhello\t\n"));
    try testing.expectEqualStrings("", trim("   "));
}

test "split: basic splitting" {
    const allocator = testing.allocator;

    const result = try split(allocator, "a,b,c", ',');
    defer allocator.free(result);

    try testing.expectEqual(@as(usize, 3), result.len);
    try testing.expectEqualStrings("a", result[0]);
    try testing.expectEqualStrings("b", result[1]);
    try testing.expectEqualStrings("c", result[2]);
}

test "split: empty parts" {
    const allocator = testing.allocator;

    const result = try split(allocator, "a,,c", ',');
    defer allocator.free(result);

    try testing.expectEqual(@as(usize, 3), result.len);
    try testing.expectEqualStrings("a", result[0]);
    try testing.expectEqualStrings("", result[1]);
    try testing.expectEqualStrings("c", result[2]);
}

test "split: no delimiter" {
    const allocator = testing.allocator;

    const result = try split(allocator, "hello", ',');
    defer allocator.free(result);

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("hello", result[0]);
}

test "join: basic joining" {
    const allocator = testing.allocator;

    const parts = [_][]const u8{ "hello", "world", "test" };
    const result = try join(allocator, &parts, " ");
    defer allocator.free(result);

    try testing.expectEqualStrings("hello world test", result);
}

test "join: empty array" {
    const allocator = testing.allocator;

    const parts = [_][]const u8{};
    const result = try join(allocator, &parts, " ");
    defer allocator.free(result);

    try testing.expectEqualStrings("", result);
}

test "join: single element" {
    const allocator = testing.allocator;

    const parts = [_][]const u8{"hello"};
    const result = try join(allocator, &parts, " ");
    defer allocator.free(result);

    try testing.expectEqualStrings("hello", result);
}

test "join: empty delimiter" {
    const allocator = testing.allocator;

    const parts = [_][]const u8{ "a", "b", "c" };
    const result = try join(allocator, &parts, "");
    defer allocator.free(result);

    try testing.expectEqualStrings("abc", result);
}

// ============================================================================
// Integration Test: Complete Workflow
// ============================================================================

test "string operations integration" {
    const allocator = testing.allocator;

    // Create a test string
    const original = "  Hello World  ";

    // Trim whitespace
    const trimmed = trim(original);
    try testing.expectEqualStrings("Hello World", trimmed);

    // Convert to uppercase
    const upper = try toUpperCase(allocator, trimmed);
    defer allocator.free(upper);
    try testing.expectEqualStrings("HELLO WORLD", upper);

    // Convert to lowercase
    const lower = try toLowerCase(allocator, trimmed);
    defer allocator.free(lower);
    try testing.expectEqualStrings("hello world", lower);

    // Reverse
    const reversed = try reverse(allocator, trimmed);
    defer allocator.free(reversed);
    try testing.expectEqualStrings("dlroW olleH", reversed);

    // Count characters
    try testing.expectEqual(@as(usize, 3), countChar(trimmed, 'l'));
    try testing.expectEqual(@as(usize, 1), countChar(trimmed, 'H'));

    // Check prefixes and suffixes
    try testing.expect(startsWith(trimmed, "Hello"));
    try testing.expect(endsWith(trimmed, "World"));
}
