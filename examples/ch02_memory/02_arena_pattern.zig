// Example: Arena Pattern for Request Handling
// Chapter 3: Memory & Allocators
//
// Demonstrates arena allocator for request-scoped allocations with bulk cleanup

const std = @import("std");

fn handleRequest(allocator: std.mem.Allocator, req_id: u32, data: []const u8) ![]u8 {
    _ = data;
    var parts = std.ArrayList([]const u8).empty;
    defer parts.deinit(allocator);

    try parts.append(allocator, "Processing request ");
    const id_str = try std.fmt.allocPrint(allocator, "{}", .{req_id});
    defer allocator.free(id_str);
    try parts.append(allocator, id_str);

    // Concatenate parts
    var total_len: usize = 0;
    for (parts.items) |part| total_len += part.len;

    const result = try allocator.alloc(u8, total_len);
    var offset: usize = 0;
    for (parts.items) |part| {
        @memcpy(result[offset..][0..part.len], part);
        offset += part.len;
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    // Process multiple requests
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        defer _ = arena.reset(.{ .retain_with_limit = 4096 });
        const response = try handleRequest(arena.allocator(), i, "data");
        std.debug.print("{s}\n", .{response});
        // No individual frees needed—arena handles it
    }

    std.debug.print("\nArena reset and reused for each request\n", .{});
}
