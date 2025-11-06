// Example: Allocator Interface Basics
// Chapter 3: Memory & Allocators
//
// Demonstrates the core allocator interface with leak detection

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // Slice allocation
    const numbers = try allocator.alloc(u32, 5);
    defer allocator.free(numbers);

    std.debug.print("Allocated slice of {} u32s\n", .{numbers.len});
    for (numbers, 0..) |*num, i| {
        num.* = @intCast(i * 10);
    }
    std.debug.print("Numbers: {any}\n", .{numbers});

    // Single item allocation
    const single = try allocator.create(u32);
    defer allocator.destroy(single);
    single.* = 42;

    std.debug.print("Single value: {}\n", .{single.*});

    // Aligned allocation (16-byte boundary)
    const aligned = try allocator.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(16), 64);
    defer allocator.free(aligned);

    std.debug.print("Aligned allocation: {} bytes at 16-byte boundary\n", .{aligned.len});
    std.debug.print("Address alignment: {} (should be 0)\n", .{@intFromPtr(aligned.ptr) % 16});
}
