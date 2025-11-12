const std = @import("std");

// Demonstrates basic Zig syntax concepts from Chapter 2

pub fn main() !void {
    // Types and declarations
    const signed: i32 = -42;
    const unsigned: u64 = 100;
    const ptr_sized: usize = 8;
    const float: f64 = 3.14159;
    const boolean: bool = true;

    // Bit-width integers
    const tiny: u3 = 7;  // 0-7 (3 bits)
    const custom: i13 = 42;  // -4096 to 4095 (13 bits)

    // Pointers and arrays
    var value: i32 = 42;
    const ptr: *i32 = &value;
    ptr.* = 100;  // Modify through pointer

    const arr = [_]i32{ 10, 20, 30, 40 };
    const slice: []const i32 = arr[1..3];  // [20, 30]

    // Optionals
    const maybe: ?i32 = 42;
    const default_value = maybe orelse 0;

    // Error unions
    const result = try divide(10, 2);
    const safe = divide(10, 0) catch 0;

    // Structs
    const point = Point{ .x = 10, .y = 20 };
    const dist = point.distance(Point{ .x = 0, .y = 0 });

    // Enums
    const color: Color = .red;
    _ = color.isWarm();

    // Tagged unions
    const val = Value{ .int = 42 };
    switch (val) {
        .int => |i| std.debug.print("int: {}\n", .{i}),
        .float => |f| std.debug.print("float: {}\n", .{f}),
        .string => |s| std.debug.print("string: {s}\n", .{s}),
        .boolean => |b| std.debug.print("bool: {}\n", .{b}),
    }

    // Packed structs
    const flags = Flags{ .read = true, .write = false, .execute = true };
    const as_byte: u8 = @bitCast(flags);
    std.debug.print("Flags as byte: 0b{b:0>8}\n", .{as_byte});

    // Control flow
    const max = if (signed > 0) signed else 0;

    // For loop
    for (arr) |item| {
        std.debug.print("Item: {}\n", .{item});
    }

    // For loop with index
    for (slice, 0..) |item, idx| {
        std.debug.print("[{}] = {}\n", .{idx, item});
    }

    // Switch statement
    const category = switch (unsigned) {
        0 => "zero",
        1...10 => "small",
        else => "large",
    };

    // Builtins
    const T = @TypeOf(signed);
    const size = @sizeOf(i32);
    const from_float: i32 = @intFromFloat(float);

    std.debug.print("Results: {}, {}, {}, {}, {s}\n",
        .{result, safe, dist, default_value, category});
    std.debug.print("Type info: size={}, from_float={}\n", .{size, from_float});

    // Suppress unused warnings
    _ = T;
    _ = ptr_sized;
    _ = boolean;
    _ = tiny;
    _ = custom;
    _ = max;
}

// Struct example
const Point = struct {
    x: i32,
    y: i32,

    pub fn distance(self: Point, other: Point) f64 {
        const dx = @as(f64, @floatFromInt(self.x - other.x));
        const dy = @as(f64, @floatFromInt(self.y - other.y));
        return @sqrt(dx * dx + dy * dy);
    }
};

// Enum example
const Color = enum {
    red,
    green,
    blue,

    pub fn isWarm(self: Color) bool {
        return self == .red;
    }
};

// Tagged union example
const Value = union(enum) {
    int: i64,
    float: f64,
    string: []const u8,
    boolean: bool,
};

// Packed struct example
const Flags = packed struct {
    read: bool,
    write: bool,
    execute: bool,
    _padding: u5 = 0,
};

// Error union function
fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

test "syntax basics" {
    const x: i32 = 42;
    const y: u64 = @intCast(x);
    try std.testing.expect(y == 42);
}

test "optionals" {
    const maybe: ?i32 = null;
    const value = maybe orelse 0;
    try std.testing.expect(value == 0);
}

test "error unions" {
    const result = divide(10, 2) catch 0;
    try std.testing.expect(result == 5);
}
