// Example: FixedBufferAllocator for Stack-Based Operations
// Chapter 3: Memory & Allocators
//
// Demonstrates FixedBufferAllocator for zero-syscall, bounded allocations

const std = @import("std");

fn formatMessage(buffer: []u8, name: []const u8, value: i32) ![]const u8 {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    const allocator = fba.allocator();

    return try std.fmt.allocPrint(
        allocator,
        "User: {s}, Score: {}",
        .{ name, value },
    );
}

pub fn main() !void {
    var stack_buffer: [256]u8 = undefined;

    const msg1 = try formatMessage(&stack_buffer, "Alice", 100);
    std.debug.print("{s}\n", .{msg1});

    // Reuse same buffer (overwrites previous content)
    const msg2 = try formatMessage(&stack_buffer, "Bob", 200);
    std.debug.print("{s}\n", .{msg2});

    // Demonstrate buffer reuse
    const msg3 = try formatMessage(&stack_buffer, "Charlie", 300);
    std.debug.print("{s}\n", .{msg3});

    std.debug.print("\nAll operations used stack memory only—no heap allocations!\n", .{});
}
