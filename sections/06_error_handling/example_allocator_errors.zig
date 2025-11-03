const std = @import("std");

const DataError = error{
    TooLarge,
    InvalidData,
};

// Handling allocation errors with graceful degradation
fn processWithFallback(allocator: std.mem.Allocator, size: usize) ![]u8 {
    std.debug.print("Attempting to allocate {d} bytes...\n", .{size});

    const buffer = allocator.alloc(u8, size) catch |err| {
        std.debug.print("Allocation failed: {s}\n", .{@errorName(err)});
        std.debug.print("Falling back to smaller size\n", .{});

        // Fall back to a smaller allocation
        const fallback_size = size / 2;
        return allocator.alloc(u8, fallback_size) catch {
            std.debug.print("Fallback also failed\n", .{});
            return err; // Re-throw the error
        };
    };

    std.debug.print("Successfully allocated {d} bytes\n", .{buffer.len});
    return buffer;
}

// Using arena allocator to simplify error handling
fn processWithArena(parent_allocator: std.mem.Allocator) !void {
    std.debug.print("\n=== Arena Allocator Example ===\n", .{});

    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit(); // Single cleanup for all allocations

    // Multiple allocations with no individual cleanup needed
    const buffer1 = try arena.allocator().alloc(u8, 100);
    const buffer2 = try arena.allocator().alloc(u32, 50);
    const buffer3 = try arena.allocator().alloc(u64, 25);

    // Use buffers
    std.debug.print("Allocated buffers: {d}, {d}, {d} bytes\n", .{
        buffer1.len,
        buffer2.len * @sizeOf(u32),
        buffer3.len * @sizeOf(u64),
    });

    // All allocations freed automatically by arena.deinit()
    // No individual defer statements needed
}

// Robust allocation with validation
fn allocateValidated(
    allocator: std.mem.Allocator,
    size: usize,
    max_size: usize,
) ![]u8 {
    if (size > max_size) {
        return error.TooLarge;
    }

    if (size == 0) {
        return error.InvalidData;
    }

    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    // Validate allocation succeeded
    std.debug.assert(buffer.len == size);

    return buffer;
}

// Container with complex cleanup
const Container = struct {
    items: std.ArrayList([]const u8),
    scratch: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Container {
        var items = std.ArrayList([]const u8).init(allocator);
        errdefer items.deinit();

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
        self.items.deinit();
        self.allocator.free(self.scratch);
    }

    fn addItem(self: *Container, data: []const u8) !void {
        const copy = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(copy);

        try self.items.append(copy);
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

    // Test allocation with fallback
    {
        const buffer = try processWithFallback(allocator, 1000);
        defer allocator.free(buffer);
    }

    // Test arena allocator
    try processWithArena(allocator);

    // Test validated allocation
    {
        std.debug.print("\n=== Validated Allocation ===\n", .{});

        const valid = try allocateValidated(allocator, 100, 1000);
        defer allocator.free(valid);
        std.debug.print("Valid allocation succeeded\n", .{});

        // Test error conditions
        _ = allocateValidated(allocator, 2000, 1000) catch |err| {
            std.debug.print("Expected error: {s}\n", .{@errorName(err)});
        };
    }

    // Test container with complex cleanup
    {
        std.debug.print("\n=== Container Example ===\n", .{});

        var container = try Container.init(allocator);
        defer container.deinit();

        try container.addItem("first");
        try container.addItem("second");
        try container.addItem("third");

        std.debug.print("Added {d} items to container\n", .{container.items.items.len});
    }
}
