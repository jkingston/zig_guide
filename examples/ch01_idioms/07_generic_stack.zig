// Example 3: Generic Data Structure
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates creating a generic stack using comptime type parameters

const std = @import("std");

fn Stack(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .items = std.ArrayList(T).empty,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn push(self: *Self, item: T) !void {
            try self.items.append(self.allocator, item);
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }
    };
}

test "generic stack" {
    const allocator = std.testing.allocator;
    var stack = Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(10);
    try stack.push(20);

    try std.testing.expect(stack.pop().? == 20);
    try std.testing.expect(stack.pop().? == 10);
    try std.testing.expect(stack.pop() == null);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var int_stack = Stack(i32).init(allocator);
    defer int_stack.deinit();

    try int_stack.push(10);
    try int_stack.push(20);
    try int_stack.push(30);

    std.debug.print("Popping from stack:\n", .{});
    while (int_stack.pop()) |value| {
        std.debug.print("  {}\n", .{value});
    }
}
