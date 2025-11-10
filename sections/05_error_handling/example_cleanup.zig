const std = @import("std");

const ResourceError = error{
    InitFailed,
    AllocationFailed,
};

const Resource = struct {
    id: u32,
    name: []const u8,

    fn init(id: u32, name: []const u8) Resource {
        std.debug.print("Resource {d} ({s}) initialized\n", .{ id, name });
        return Resource{ .id = id, .name = name };
    }

    fn deinit(self: *Resource) void {
        std.debug.print("Resource {d} ({s}) cleaned up\n", .{ self.id, self.name });
    }
};

// Demonstrate defer - executes in LIFO order
fn demonstrateDefer() void {
    std.debug.print("\n=== Defer Example ===\n", .{});

    var r1 = Resource.init(1, "first");
    defer r1.deinit(); // Executes last (LIFO)

    var r2 = Resource.init(2, "second");
    defer r2.deinit(); // Executes second

    var r3 = Resource.init(3, "third");
    defer r3.deinit(); // Executes first

    std.debug.print("All resources initialized\n", .{});
    // Cleanup happens in reverse order: r3, r2, r1
}

// Demonstrate errdefer - only executes on error
fn initializeWithErrorHandling(allocator: std.mem.Allocator, should_fail: bool) ![]Resource {
    std.debug.print("\n=== Errdefer Example (should_fail={}) ===\n", .{should_fail});

    // Allocate first resource
    var list = try allocator.alloc(Resource, 3);
    errdefer allocator.free(list); // Only runs if an error occurs

    // Initialize resources one by one
    list[0] = Resource.init(10, "alpha");
    errdefer list[0].deinit(); // Cleanup if subsequent operations fail

    list[1] = Resource.init(11, "beta");
    errdefer list[1].deinit();

    if (should_fail) {
        std.debug.print("Simulating failure...\n", .{});
        return error.InitFailed;
    }

    list[2] = Resource.init(12, "gamma");
    errdefer list[2].deinit();

    std.debug.print("All resources initialized successfully\n", .{});
    return list;
}

// Demonstrate proper cleanup with both defer and errdefer
fn complexCleanup(allocator: std.mem.Allocator) !void {
    std.debug.print("\n=== Complex Cleanup Example ===\n", .{});

    const buffer = try allocator.alloc(u8, 128);
    errdefer allocator.free(buffer); // Cleanup on error
    defer allocator.free(buffer); // Always cleanup

    var resource = Resource.init(20, "complex");
    errdefer resource.deinit(); // Cleanup on error
    defer resource.deinit(); // Always cleanup

    std.debug.print("Resources allocated successfully\n", .{});
    // Both defer statements execute normally
}

pub fn main() !void {
    // Demonstrate defer LIFO order
    demonstrateDefer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Success case - errdefer does not execute
    {
        const resources = try initializeWithErrorHandling(allocator, false);
        defer {
            for (resources) |*r| r.deinit();
            allocator.free(resources);
        }
    }

    // Failure case - errdefer executes, cleaning up partial initialization
    {
        _ = initializeWithErrorHandling(allocator, true) catch |err| {
            std.debug.print("Caught error: {s}\n", .{@errorName(err)});
            std.debug.print("Partial resources were cleaned up by errdefer\n", .{});
        };
    }

    // Complex cleanup with both defer and errdefer
    try complexCleanup(allocator);
}
