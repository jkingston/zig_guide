/// Glossary Terms in Context
/// This example demonstrates many Zig terminology items in practical usage.
/// Each section is annotated to show how glossary terms appear in real code.

const std = @import("std");

// === ALLOCATOR: Interface for memory allocation ===
// GPA (GeneralPurposeAllocator): Production-quality allocator with safety checks
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // === ARENA: Memory allocation pattern for temporary allocations ===
    // All allocations freed together at deinit()
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // === SLICE: Runtime-sized view into array or memory ===
    // []const u8: Immutable byte slice, common for strings
    const message: []const u8 = "Hello, Zig!";

    // === ARRAYLIST: Dynamic array container ===
    var list = std.ArrayList(u32).init(arena_allocator);
    // Note: In 0.15+, deinit requires allocator parameter
    // defer list.deinit(arena_allocator); // Uncomment for 0.15+

    // === ERROR UNION: Type that can be value or error ===
    // TRY: Propagates error or unwraps value
    try list.append(42);
    try list.append(100);
    try list.append(255);

    // === OPTIONAL: Type that can be value or null ===
    const maybe_value: ?u32 = list.getLastOrNull();

    // === ORELSE: Provides default if optional is null ===
    const value = maybe_value orelse 0;

    std.debug.print("List last value: {d}\n", .{value});

    // === COMPTIME: Compile-time execution ===
    // This computation happens at compile time, zero runtime cost
    const factorial_10 = comptime computeFactorial(10);
    std.debug.print("Factorial of 10 (computed at comptime): {d}\n", .{factorial_10});

    // === ERROR SET: Named collection of possible errors ===
    demonstrateErrorHandling() catch |err| {
        // @errorName: Converts error value to string
        std.debug.print("Caught error: {s}\n", .{@errorName(err)});
    };

    // === HASHMAP: Key-value storage ===
    var map = std.AutoHashMap(u32, []const u8).init(allocator);
    defer map.deinit();

    try map.put(1, "first");
    try map.put(2, "second");

    // === OPTIONAL unwrapping with IF ===
    if (map.get(1)) |val| {
        std.debug.print("Key 1 maps to: {s}\n", .{val});
    }

    // === SENTINEL-TERMINATED: Array with known terminator ===
    // [*:0]const u8: Null-terminated string (C-style)
    const c_string: [*:0]const u8 = "C compatible string";
    std.debug.print("C string: {s}\n", .{c_string});

    // === DEFER: Execute code at scope exit (LIFO order) ===
    {
        var resource1 = Resource.init(1);
        defer resource1.deinit(); // Executes last

        var resource2 = Resource.init(2);
        defer resource2.deinit(); // Executes first

        std.debug.print("Resources initialized\n", .{});
        // Cleanup happens in reverse order: resource2, then resource1
    }

    // === WRITER: Generic I/O interface for output ===
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Writing to stdout using Writer interface\n", .{});

    // === ANYTYPE: Generic parameter inferred at compile time ===
    printValue(42);
    printValue("Hello");
    printValue(3.14);
}

// === COMPTIME function: Forces compile-time evaluation ===
fn computeFactorial(comptime n: u32) u32 {
    if (n <= 1) return 1;
    return n * computeFactorial(n - 1);
}

// === ERROR SET: Explicit error types ===
const DemoError = error{
    InvalidInput,
    OutOfRange,
};

// === ERROR UNION return type: !T syntax ===
fn demonstrateErrorHandling() DemoError!void {
    // Returning an error
    return error.InvalidInput;
}

// === ANYTYPE: Compile-time polymorphism ===
fn printValue(value: anytype) void {
    std.debug.print("Value: {any}\n", .{value});
}

// === STRUCT: Custom type with fields and methods ===
const Resource = struct {
    id: u32,

    // === INIT/DEINIT pattern: Standard resource management ===
    pub fn init(id: u32) Resource {
        std.debug.print("Resource {d} initialized\n", .{id});
        return Resource{ .id = id };
    }

    // === SELF PARAMETER: *Self for mutation, *const Self for reading ===
    pub fn deinit(self: *Resource) void {
        std.debug.print("Resource {d} deinitialized\n", .{self.id});
    }
};

// === TEST BLOCK: Unit testing embedded in source ===
test "ArrayList operations demonstrate glossary terms" {
    // === STD.TESTING.ALLOCATOR: Test allocator with leak detection ===
    const allocator = std.testing.allocator;

    // Create ArrayList (demonstrates ERROR UNION with TRY)
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    // Test operations
    try list.append(1);
    try list.append(2);
    try list.append(3);

    // === ASSERTIONS: Verify expected behavior ===
    try std.testing.expectEqual(@as(usize, 3), list.items.len);
    try std.testing.expectEqual(@as(i32, 1), list.items[0]);
}

test "Optional handling demonstrates orelse and if unwrapping" {
    const maybe_number: ?i32 = 42;
    const no_number: ?i32 = null;

    // Using orelse (demonstrates OPTIONAL with default)
    const value1 = maybe_number orelse 0;
    const value2 = no_number orelse -1;

    try std.testing.expectEqual(@as(i32, 42), value1);
    try std.testing.expectEqual(@as(i32, -1), value2);

    // Using if unwrapping (demonstrates OPTIONAL unwrapping)
    if (maybe_number) |num| {
        try std.testing.expectEqual(@as(i32, 42), num);
    }
}

test "Error handling demonstrates try and catch" {
    // Demonstrates ERROR UNION with CATCH
    const result = failingFunction() catch |err| blk: {
        try std.testing.expectEqual(error.AlwaysFails, err);
        break :blk 999; // Provide default value on error
    };

    try std.testing.expectEqual(@as(i32, 999), result);
}

fn failingFunction() !i32 {
    return error.AlwaysFails;
}
