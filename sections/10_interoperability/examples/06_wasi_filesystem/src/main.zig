const std = @import("std");

pub fn main() !void {
    // WASI stdout - using debug print for simplicity
    std.debug.print("=== WASI Filesystem Demo ===\n\n", .{});

    // Get allocator (WASI uses page allocator)
    const allocator = std.heap.page_allocator;

    // Example 1: Read command-line arguments
    std.debug.print("1. Command-line arguments:\n", .{});
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var arg_count: usize = 0;
    while (args.next()) |arg| {
        std.debug.print("   arg[{d}]: {s}\n", .{ arg_count, arg });
        arg_count += 1;
    }
    std.debug.print("\n", .{});

    // Example 2: Read environment variables
    std.debug.print("2. Environment variables:\n", .{});
    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    var env_iter = env_map.iterator();
    var env_count: usize = 0;
    while (env_iter.next()) |entry| {
        if (env_count < 5) { // Show first 5
            std.debug.print("   {s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
        env_count += 1;
    }
    std.debug.print("   (Total: {d} variables)\n\n", .{env_count});

    // Example 3: Working with current directory
    // Note: Requires --dir=. capability when running
    std.debug.print("3. Current directory operations:\n", .{});

    const cwd = std.fs.cwd();

    // Create a test file
    const test_file_name = "wasi_test_output.txt";
    std.debug.print("   Creating file: {s}\n", .{test_file_name});

    {
        const file = try cwd.createFile(test_file_name, .{});
        defer file.close();

        try file.writeAll("Hello from WASI!\n");
        try file.writeAll("This file was created by Zig running in WASI.\n");
        try file.writeAll("Demonstrating filesystem capabilities.\n");
    }

    // Read the file back
    std.debug.print("   Reading file back:\n", .{});
    {
        const file = try cwd.openFile(test_file_name, .{});
        defer file.close();

        const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(contents);

        std.debug.print("   --- File contents ---\n", .{});
        std.debug.print("{s}", .{contents});
        std.debug.print("   --- End of file ---\n\n", .{});
    }

    // Get file metadata
    std.debug.print("   File metadata:\n", .{});
    {
        const file = try cwd.openFile(test_file_name, .{});
        defer file.close();

        const stat = try file.stat();
        std.debug.print("   Size: {d} bytes\n", .{stat.size});
        std.debug.print("   Kind: {s}\n\n", .{@tagName(stat.kind)});
    }

    // Example 4: Directory operations
    std.debug.print("4. Directory operations:\n", .{});

    const test_dir_name = "wasi_test_dir";
    std.debug.print("   Creating directory: {s}\n", .{test_dir_name});
    try cwd.makeDir(test_dir_name);

    // Create a file in the directory
    const nested_file = try std.fmt.allocPrint(
        allocator,
        "{s}/nested_file.txt",
        .{test_dir_name},
    );
    defer allocator.free(nested_file);

    {
        const file = try cwd.createFile(nested_file, .{});
        defer file.close();
        try file.writeAll("Nested file content\n");
    }
    std.debug.print("   Created nested file: {s}\n", .{nested_file});

    // List directory contents
    std.debug.print("   Listing directory contents:\n", .{});
    {
        var dir = try cwd.openDir(test_dir_name, .{ .iterate = true });
        defer dir.close();

        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            std.debug.print("   - {s} ({s})\n", .{ entry.name, @tagName(entry.kind) });
        }
    }
    std.debug.print("\n", .{});

    // Example 5: Error handling
    std.debug.print("5. Error handling:\n", .{});

    // Try to open a non-existent file
    cwd.openFile("non_existent.txt", .{}) catch |err| {
        std.debug.print("   Expected error: {s}\n", .{@errorName(err)});
    };
    std.debug.print("\n", .{});

    // Example 6: Cleanup
    std.debug.print("6. Cleaning up:\n", .{});

    std.debug.print("   Deleting nested file\n", .{});
    try cwd.deleteFile(nested_file);

    std.debug.print("   Deleting directory\n", .{});
    try cwd.deleteDir(test_dir_name);

    std.debug.print("   Deleting test file\n", .{});
    try cwd.deleteFile(test_file_name);

    std.debug.print("\n=== Demo Complete ===\n", .{});
}
