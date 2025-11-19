// Example 3: Allocator Error Handling
// 06 Error Handling
//
// Extracted from chapter content.md

const std = @import("std");

// Graceful degradation on allocation failure
fn processWithFallback(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const buffer = allocator.alloc(u8, size) catch |err| {
        std.debug.print("Allocation of {d} bytes failed\n", .{size});

        // Fall back to smaller allocation
        const fallback_size = size / 2;
        return allocator.alloc(u8, fallback_size) catch {
            std.debug.print("Fallback also failed\n", .{});
            return err;
        };
    };

    return buffer;
}

// Container with complex cleanup
const Container = struct {
    items: std.ArrayList([]const u8),
    scratch: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Container {
        var items = std.ArrayList([]const u8).empty;
        errdefer items.deinit(allocator);

        const scratch = try allocator.alloc(u8, 1024);
        errdefer allocator.free(scratch);

        return Container{
            .items = items,
            .scratch = scratch,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Container) void {
        for (self.items.items) |item| {
            self.allocator.free(item);
        }
        self.items.deinit(self.allocator);
        self.allocator.free(self.scratch);
    }

    fn addItem(self: *Container, data: []const u8) !void {
        const copy = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(copy);

        try self.items.append(self.allocator, copy);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Memory leaked!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    var container = try Container.init(allocator);
    defer container.deinit();

    try container.addItem("first");
    try container.addItem("second");
    try container.addItem("third");
}