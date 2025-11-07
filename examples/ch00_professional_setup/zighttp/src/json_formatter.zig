const std = @import("std");

/// Format JSON string with pretty printing
pub fn format(allocator: std.mem.Allocator, json_str: []const u8) ![]const u8 {
    // Parse JSON
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_str, .{}) catch {
        // If parsing fails, return original string
        return try allocator.dupe(u8, json_str);
    };
    defer parsed.deinit();

    // Re-serialize with pretty printing
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    try std.json.stringify(parsed.value, .{
        .whitespace = .indent_2,
    }, output.writer());

    return try output.toOwnedSlice();
}

/// Check if a string is likely JSON
pub fn isJson(s: []const u8) bool {
    if (s.len == 0) return false;

    // Simple heuristic: starts with { or [
    const trimmed = std.mem.trim(u8, s, " \t\n\r");
    if (trimmed.len == 0) return false;

    return trimmed[0] == '{' or trimmed[0] == '[';
}

// Unit tests
test "format valid JSON" {
    const allocator = std.testing.allocator;

    const input = "{\"name\":\"John\",\"age\":30}";
    const formatted = try format(allocator, input);
    defer allocator.free(formatted);

    // Should have indentation
    try std.testing.expect(std.mem.indexOf(u8, formatted, "  ") != null);
}

test "format invalid JSON returns original" {
    const allocator = std.testing.allocator;

    const input = "not json";
    const formatted = try format(allocator, input);
    defer allocator.free(formatted);

    try std.testing.expectEqualStrings(input, formatted);
}

test "isJson detection" {
    try std.testing.expect(isJson("{\"test\":1}"));
    try std.testing.expect(isJson("[1,2,3]"));
    try std.testing.expect(isJson("  {\"test\":1}  "));
    try std.testing.expect(!isJson("not json"));
    try std.testing.expect(!isJson(""));
}
