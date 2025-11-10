// Example 4: Ownership Transfer with toOwnedSlice
// 04 Collections Containers
//
// Extracted from chapter content.md

const std = @import("std");

fn buildMessage(allocator: std.mem.Allocator, parts: []const []const u8) ![]const u8 {
    var list = std.ArrayList(u8){};
    // Note: No defer here - ownership transferred via toOwnedSlice

    for (parts, 0..) |part, i| {
        try list.appendSlice(allocator, part);
        if (i < parts.len - 1) {
            try list.append(allocator, ' ');
        }
    }

    // Transfer ownership to caller
    return list.toOwnedSlice(allocator);
}

fn processData(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u32) {
    var numbers = std.ArrayList(u32){};
    errdefer numbers.deinit(allocator);  // Clean up on error

    for (input) |byte| {
        if (byte >= '0' and byte <= '9') {
            try numbers.append(allocator, byte - '0');
        }
    }

    // Transfer ownership by returning the ArrayList directly
    return numbers;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Ownership Transfer Patterns ===\n\n", .{});

    // Pattern 1: toOwnedSlice (ArrayList → Slice)
    std.debug.print("Pattern 1: toOwnedSlice\n", .{});
    const parts = [_][]const u8{ "Hello", "from", "Zig" };
    const message = try buildMessage(allocator, &parts);
    defer allocator.free(message);  // Caller owns and must free

    std.debug.print("Message: {s}\n\n", .{message});

    // Pattern 2: Return ArrayList directly
    std.debug.print("Pattern 2: Return ArrayList\n", .{});
    var numbers = try processData(allocator, "a1b2c3d4e5");
    defer numbers.deinit(allocator);  // Caller owns and must deinit

    std.debug.print("Numbers: ", .{});
    for (numbers.items) |num| {
        std.debug.print("{} ", .{num});
    }
    std.debug.print("\n\n", .{});

    // Pattern 3: fromOwnedSlice (Slice → ArrayList)
    std.debug.print("Pattern 3: fromOwnedSlice\n", .{});
    const raw_data = try allocator.alloc(u8, 5);
    for (raw_data, 0..) |*byte, i| {
        byte.* = @intCast('A' + i);
    }

    var list_from_slice = std.ArrayList(u8).fromOwnedSlice(raw_data);
    defer list_from_slice.deinit(allocator);  // Now list owns the data

    try list_from_slice.append(allocator, 'F');  // Can grow
    std.debug.print("From slice: {s}\n", .{list_from_slice.items});
}