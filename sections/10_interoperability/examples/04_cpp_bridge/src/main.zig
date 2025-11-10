const std = @import("std");

// Import C bridge to C++ class
const c = @cImport({
    @cInclude("c_bridge.h");
});

pub fn main() !void {
    std.debug.print("=== C++ Bridge Demo ===\n\n", .{});

    // Create C++ object through C bridge
    const obj = c.MyCppClass_create(42);
    if (obj == null) {
        std.debug.print("Failed to create C++ object\n", .{});
        return error.CreateFailed;
    }
    defer c.MyCppClass_destroy(obj);

    std.debug.print("Created C++ object\n", .{});

    // Get and set values
    var value = c.MyCppClass_getValue(obj);
    std.debug.print("Initial value: {d}\n", .{value});

    c.MyCppClass_increment(obj);
    value = c.MyCppClass_getValue(obj);
    std.debug.print("After increment: {d}\n", .{value});

    c.MyCppClass_setValue(obj, 100);
    value = c.MyCppClass_getValue(obj);
    std.debug.print("After setValue(100): {d}\n\n", .{value});

    // Work with strings
    const msg = c.MyCppClass_getMessage(obj);
    if (msg != null) {
        std.debug.print("Current message: {s}\n", .{msg});
        c.MyCppClass_freeString(msg);
    }

    c.MyCppClass_setMessage(obj, "Hello from Zig!");
    const new_msg = c.MyCppClass_getMessage(obj);
    if (new_msg != null) {
        std.debug.print("Updated message: {s}\n\n", .{new_msg});
        c.MyCppClass_freeString(new_msg);
    }

    // Work with arrays
    const values = [_]f64{ 1.5, 2.5, 3.5, 4.5, 5.5 };
    const sum = c.MyCppClass_calculateSum(obj, &values, values.len);
    std.debug.print("Sum of values: {d:.2}\n", .{sum});

    std.debug.print("\n=== Demo Complete ===\n", .{});
}
