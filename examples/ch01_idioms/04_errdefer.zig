// Example: errdefer for Partial Failure Cleanup
// Chapter 2: Language Idioms & Core Patterns
//
// Demonstrates using errdefer to handle partial failures

const std = @import("std");

fn createResources(allocator: std.mem.Allocator) !struct { a: []u8, b: []u8 } {
    const a = try allocator.alloc(u8, 100);
    errdefer allocator.free(a); // Only frees if subsequent operations fail

    const b = try allocator.alloc(u8, 200);
    errdefer allocator.free(b);

    return .{ .a = a, .b = b };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const resources = try createResources(allocator);
    defer allocator.free(resources.a);
    defer allocator.free(resources.b);

    std.debug.print("Successfully created resources:\n", .{});
    std.debug.print("  Resource a: {} bytes\n", .{resources.a.len});
    std.debug.print("  Resource b: {} bytes\n", .{resources.b.len});
}
