const std = @import("std");
const wrapper = @import("wrapper.zig");

pub fn main() !void {
    std.debug.print("=== Build Integration Demo ===\n\n", .{});

    // Example 1: Call C function through wrapper
    const sum = wrapper.addNumbers(15, 27);
    std.debug.print("15 + 27 = {d} (via C library)\n\n", .{sum});

    // Example 2: Pass string to C
    try wrapper.printMessage("Hello from Zig!");
    try wrapper.printMessage("Mixed Zig and C code working together");
    std.debug.print("\n", .{});

    // Example 3: Work with array data
    const values = [_]f64{ 10.5, 20.3, 30.1, 40.7, 50.2 };
    const avg = wrapper.calculateAverage(&values);
    std.debug.print("Average of values: {d:.2}\n\n", .{avg});

    // Example 4: Use Zig-native function
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try wrapper.processData(allocator, 5);

    std.debug.print("\n=== Demo Complete ===\n", .{});
}
