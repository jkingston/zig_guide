const std = @import("std");
const zighttp = @import("zighttp");

// Integration tests that test the full request flow
// Note: These tests require network access and may be flaky
// In a real project, you'd want to mock the HTTP layer

test "library imports work" {
    // Verify all public exports are accessible
    _ = zighttp.Args;
    _ = zighttp.Method;
    _ = zighttp.Response;
    _ = zighttp.request;
    _ = zighttp.formatJson;
    _ = zighttp.isJson;
}

test "args parsing logic" {
    const allocator = std.testing.allocator;

    // Test method parsing
    const get = try zighttp.Method.fromString("GET");
    try std.testing.expectEqual(zighttp.Method.GET, get);

    const post = try zighttp.Method.fromString("POST");
    try std.testing.expectEqual(zighttp.Method.POST, post);
}

test "json formatter" {
    const allocator = std.testing.allocator;

    // Test valid JSON formatting
    const input = "{\"name\":\"test\",\"value\":123}";
    const formatted = try zighttp.formatJson(allocator, input);
    defer allocator.free(formatted);

    // Should contain indentation
    try std.testing.expect(std.mem.indexOf(u8, formatted, "  ") != null);

    // Test JSON detection
    try std.testing.expect(zighttp.isJson("{\"test\":1}"));
    try std.testing.expect(zighttp.isJson("[1,2,3]"));
    try std.testing.expect(!zighttp.isJson("plain text"));
}

test "response structure creation and cleanup" {
    const allocator = std.testing.allocator;

    const body = try allocator.dupe(u8, "test response body");
    var response = zighttp.Response{
        .status_code = 200,
        .body = body,
        .allocator = allocator,
    };
    defer response.deinit();

    try std.testing.expectEqual(@as(u16, 200), response.status_code);
    try std.testing.expectEqualStrings("test response body", response.body);
}

// Note: Real HTTP request tests would be here
// They would require either:
// 1. A local test server
// 2. Mocking the HTTP client
// 3. Testing against a stable public API
//
// Example (commented out as it requires network):
// test "make real HTTP GET request" {
//     const allocator = std.testing.allocator;
//
//     const request_args = zighttp.Args{
//         .url = try allocator.dupe(u8, "https://httpbin.org/get"),
//         .method = .GET,
//     };
//     defer request_args.deinit(allocator);
//
//     var response = try zighttp.request(allocator, request_args);
//     defer response.deinit();
//
//     try std.testing.expect(response.status_code >= 200 and response.status_code < 300);
// }
