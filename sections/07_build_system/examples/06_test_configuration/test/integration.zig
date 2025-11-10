const std = @import("std");

test "integration: memory allocation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("Memory leak detected");
        }
    }
    const allocator = gpa.allocator();

    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try std.testing.expect(buffer.len == 1024);
}

test "integration: file operations" {
    const allocator = std.testing.allocator;

    const test_content = "Integration test content\n";

    // Write
    {
        const file = try std.fs.cwd().createFile("test_file.tmp", .{});
        defer file.close();
        try file.writeAll(test_content);
    }

    // Read
    {
        const file = try std.fs.cwd().openFile("test_file.tmp", .{});
        defer file.close();
        const content = try file.readToEndAlloc(allocator, 1024);
        defer allocator.free(content);
        try std.testing.expectEqualStrings(test_content, content);
    }

    // Cleanup
    try std.fs.cwd().deleteFile("test_file.tmp");
}
