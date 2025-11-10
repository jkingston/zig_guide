// Example: Allocator Selection Patterns
// Chapter 3: Memory & Allocators
//
// Demonstrates choosing allocators based on use case

const std = @import("std");

fn processWithArena(gpa: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Simulate request processing with multiple allocations
    const headers = try allocator.alloc([]const u8, 3);
    headers[0] = try allocator.dupe(u8, "Content-Type: application/json");
    headers[1] = try allocator.dupe(u8, "Authorization: Bearer token");
    headers[2] = try allocator.dupe(u8, "User-Agent: Zig/0.15.2");

    std.debug.print("Arena allocator for request scoping:\n", .{});
    for (headers) |header| {
        std.debug.print("  {s}\n", .{header});
    }
    std.debug.print("  ✓ All memory freed at once via arena.deinit()\n", .{});
}

fn processWithFixedBuffer() !void {
    var buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const message = try std.fmt.allocPrint(allocator, "Temperature: {d:.1}°C", .{23.5});

    std.debug.print("\nFixedBufferAllocator for bounded operations:\n", .{});
    std.debug.print("  {s}\n", .{message});
    std.debug.print("  ✓ No heap allocations, predictable performance\n", .{});
}

fn processWithGPA() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            std.debug.print("  ❌ Leak detected!\n", .{});
        } else {
            std.debug.print("  ✓ No leaks detected\n", .{});
        }
    }
    const allocator = gpa.allocator();

    const data = try allocator.alloc(u8, 1024);
    defer allocator.free(data);

    std.debug.print("\nGeneralPurposeAllocator for development:\n", .{});
    std.debug.print("  Allocated {} bytes with safety features\n", .{data.len});
}

pub fn main() !void {
    var gpa_main = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_main.deinit();

    try processWithArena(gpa_main.allocator());
    try processWithFixedBuffer();
    try processWithGPA();

    std.debug.print("\n=== Allocator Selection Guide ===\n", .{});
    std.debug.print("Arena:        Request scoping, bulk cleanup\n", .{});
    std.debug.print("FixedBuffer:  Known max size, no syscalls\n", .{});
    std.debug.print("GPA:          Development, safety features\n", .{});
    std.debug.print("c_allocator:  Release builds, performance\n", .{});
}
