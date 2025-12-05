const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // ✅ 0.15+ Unmanaged ArrayList (default)
    std.debug.print("=== Unmanaged ArrayList ===\n", .{});
    var unmanaged_list = std.ArrayList(u32).empty;
    defer unmanaged_list.deinit(allocator);  // Allocator required

    try unmanaged_list.append(allocator, 10);  // Allocator required
    try unmanaged_list.append(allocator, 20);
    try unmanaged_list.append(allocator, 30);

    std.debug.print("Items: ", .{});
    for (unmanaged_list.items) |item| {
        std.debug.print("{} ", .{item});
    }
    std.debug.print("\n", .{});
    std.debug.print("Capacity: {}, Length: {}\n", .{ unmanaged_list.capacity, unmanaged_list.items.len });

    // Show struct size difference
    std.debug.print("Unmanaged struct size: {} bytes\n\n", .{@sizeOf(@TypeOf(unmanaged_list))});

    // Pre-allocation pattern
    std.debug.print("=== Pre-allocation Pattern ===\n", .{});
    var preallocated = std.ArrayList(u32).empty;
    defer preallocated.deinit(allocator);

    // Allocate exact capacity upfront (no reallocation needed)
    try preallocated.ensureTotalCapacity(allocator, 100);
    std.debug.print("Pre-allocated capacity: {}\n", .{preallocated.capacity});

    // Fast append without allocation
    for (0..100) |i| {
        preallocated.appendAssumeCapacity(@intCast(i));
    }
    std.debug.print("After 100 appends, capacity: {}\n", .{preallocated.capacity});
}
