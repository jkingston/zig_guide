const std = @import("std");

// Import our custom C library
const c = @cImport({
    @cInclude("mylib.h");
});

/// Zig wrapper for C add_numbers function
pub fn addNumbers(a: i32, b: i32) i32 {
    // Note: Using i32 directly because our C library uses int32_t
    // which has a fixed size, not c_int which is platform-dependent
    return c.add_numbers(a, b);
}

/// Zig wrapper for C print_message function
pub fn printMessage(message: []const u8) !void {
    // Convert Zig slice to null-terminated C string
    const allocator = std.heap.c_allocator;
    const c_message = try allocator.dupeZ(u8, message);
    defer allocator.free(c_message);

    c.print_message(c_message);
}

/// Zig wrapper for C calculate_average function
pub fn calculateAverage(values: []const f64) f64 {
    if (values.len == 0) return 0.0;
    return c.calculate_average(values.ptr, values.len);
}

// Zig-native function that can be called from main
pub fn processData(allocator: std.mem.Allocator, count: usize) !void {
    std.debug.print("Processing {d} items (Zig function)...\n", .{count});

    const data = try allocator.alloc(f64, count);
    defer allocator.free(data);

    // Fill with sample data
    for (data, 0..) |*item, i| {
        item.* = @as(f64, @floatFromInt(i + 1)) * 10.0;
    }

    const avg = calculateAverage(data);
    std.debug.print("Average: {d:.2}\n", .{avg});
}
