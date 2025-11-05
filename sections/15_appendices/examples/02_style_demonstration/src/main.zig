/// Idiomatic Zig Style Demonstration
/// This file shows correct (✅) vs incorrect (❌) style patterns
/// based on analysis of TigerBeetle, Ghostty, Bun, ZLS, and Zig stdlib

const std = @import("std");

// ============================================================================
// NAMING CONVENTIONS
// ============================================================================

// ✅ GOOD: Functions use snake_case
pub fn calculate_total_price(items: []const Item) f64 {
    var total: f64 = 0;
    for (items) |item| {
        total += item.price;
    }
    return total;
}

// ❌ BAD: Avoid CamelCase for functions
// pub fn CalculateTotalPrice(items: []const Item) f64 { }

// ✅ GOOD: Types use PascalCase
pub const Customer = struct {
    name: []const u8,
    email: []const u8,
    id: u32,

    // ✅ GOOD: init/deinit pattern
    pub fn init(allocator: std.mem.Allocator, name: []const u8) !Customer {
        return Customer{
            .name = try allocator.dupe(u8, name),
            .email = "",
            .id = 0,
        };
    }

    pub fn deinit(self: *Customer, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

// ✅ GOOD: Constants use snake_case (or SCREAMING_SNAKE_CASE for special cases)
pub const max_buffer_size: usize = 4096;
pub const default_timeout_ms: u64 = 5000;
pub const clients_max: u32 = 100;

// TigerBeetle style: units last for alignment
const latency_ms_max: u64 = 1000;
const latency_ms_min: u64 = 10;
const buffer_size_bytes: usize = 4096;

// ❌ BAD: Don't mix conventions
// const MaxBufferSize: usize = 4096;
// const max_latency_ms: u64 = 1000;  // units should be last

// ============================================================================
// CODE ORGANIZATION
// ============================================================================

// ✅ GOOD: Import ordering - std first, then local
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// Then local imports would go here:
// const utils = @import("utils.zig");
// const config = @import("config.zig");

// ============================================================================
// FUNCTION PATTERNS
// ============================================================================

// ✅ GOOD: Allocator as first parameter, named appropriately
pub fn process_data(allocator: Allocator, data: []const u8) ![]u8 {
    const buffer = try allocator.alloc(u8, data.len * 2);
    errdefer allocator.free(buffer);

    // Process data...
    @memcpy(buffer[0..data.len], data);

    return buffer;
}

// ✅ GOOD: Use options struct for multiple parameters of same type
pub fn connect(allocator: Allocator, options: struct {
    host: []const u8,
    port: u16,
    timeout_ms: u64 = 5000,
    retry_count: u32 = 3,
}) !Connection {
    _ = allocator;
    return Connection{
        .host = options.host,
        .port = options.port,
        .timeout_ms = options.timeout_ms,
        .retry_count = options.retry_count,
    };
}

const Connection = struct {
    host: []const u8,
    port: u16,
    timeout_ms: u64,
    retry_count: u32,
};

// ✅ GOOD: Self parameter patterns
const Buffer = struct {
    data: []u8,
    len: usize,
    allocator: Allocator,

    // *Self for mutation
    pub fn append(self: *Buffer, byte: u8) void {
        self.data[self.len] = byte;
        self.len += 1;
    }

    // *const Self for reading
    pub fn isEmpty(self: *const Buffer) bool {
        return self.len == 0;
    }

    // Self for consuming (moves ownership)
    pub fn toOwnedSlice(self: *Buffer) []u8 {
        const result = self.data[0..self.len];
        self.* = undefined;
        return result;
    }
};

// ============================================================================
// ERROR HANDLING
// ============================================================================

// ✅ GOOD: defer immediately after allocation
pub fn process_file(allocator: Allocator, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, max_buffer_size);
    defer allocator.free(content);

    // Process content...
    _ = content;
}

// ✅ GOOD: errdefer for multi-step initialization
pub fn create_resources(allocator: Allocator) !Resources {
    const buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(buffer1);

    const buffer2 = try allocator.alloc(u8, 200);
    errdefer allocator.free(buffer2);

    const buffer3 = try allocator.alloc(u8, 300);
    errdefer allocator.free(buffer3);

    return Resources{
        .buffer1 = buffer1,
        .buffer2 = buffer2,
        .buffer3 = buffer3,
    };
}

const Resources = struct {
    buffer1: []u8,
    buffer2: []u8,
    buffer3: []u8,

    pub fn deinit(self: *Resources, allocator: Allocator) void {
        allocator.free(self.buffer3);
        allocator.free(self.buffer2);
        allocator.free(self.buffer1);
    }
};

// ✅ GOOD: try for propagation, catch for handling
pub fn parse_number_with_default(input: []const u8) i32 {
    return std.fmt.parseInt(i32, input, 10) catch 0;
}

pub fn parse_number_with_logging(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10) catch |err| {
        std.log.err("Failed to parse '{s}': {s}", .{ input, @errorName(err) });
        return err;
    };
}

// ============================================================================
// MEMORY MANAGEMENT
// ============================================================================

// ✅ GOOD: Arena for temporary allocations
pub fn build_report(gpa: Allocator) !Report {
    // Use arena for all temporary work
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // All these allocations cleaned up together
    const temp1 = try arena_allocator.alloc(u8, 100);
    const temp2 = try arena_allocator.alloc(u8, 200);
    _ = temp1;
    _ = temp2;

    // Final result uses original allocator
    const final_data = try gpa.alloc(u8, 50);
    return Report{ .data = final_data };
}

const Report = struct {
    data: []u8,

    pub fn deinit(self: *Report, allocator: Allocator) void {
        allocator.free(self.data);
    }
};

// ❌ BAD: Individual allocations in loop
// pub fn bad_pattern(allocator: Allocator, count: usize) !void {
//     var i: usize = 0;
//     while (i < count) : (i += 1) {
//         const buffer = try allocator.alloc(u8, 100);
//         defer allocator.free(buffer);
//         // Many syscalls!
//     }
// }

// ✅ GOOD: Arena for loop allocations
pub fn good_pattern(allocator: Allocator, count: usize) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const buffer = try arena.allocator().alloc(u8, 100);
        _ = buffer;
        // Use buffer, no individual cleanup needed
    }
}

// ============================================================================
// ASSERTIONS (TigerBeetle pattern)
// ============================================================================

// ✅ GOOD: Multiple simple assertions
pub fn push_item(list: *std.ArrayList(u32), value: u32) !void {
    const old_len = list.items.len;
    try list.append(value);

    // Split assertions for clarity
    std.debug.assert(list.items.len == old_len + 1);
    std.debug.assert(list.items[old_len] == value);
}

// ❌ BAD: Compound assertion
// std.debug.assert(list.items.len == old_len + 1 and list.items[old_len] == value);

// ============================================================================
// DOCUMENTATION
// ============================================================================

/// Calculate the sum of all items in the list.
/// Returns 0 for empty lists.
/// Time complexity: O(n)
///
/// Example:
/// ```zig
/// const items = [_]i32{1, 2, 3, 4};
/// const total = sum_items(&items);
/// // total == 10
/// ```
pub fn sum_items(items: []const i32) i64 {
    var total: i64 = 0;
    for (items) |item| {
        total += item;
    }
    return total;
}

// ============================================================================
// ENTRY POINT
// ============================================================================

const Item = struct {
    price: f64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Demonstrate style patterns
    const items = [_]Item{
        .{ .price = 10.50 },
        .{ .price = 25.99 },
        .{ .price = 5.00 },
    };

    const total = calculate_total_price(&items);
    std.debug.print("Total price: ${d:.2}\n", .{total});

    // Demonstrate connection options
    const conn = try connect(allocator, .{
        .host = "localhost",
        .port = 8080,
    });
    std.debug.print("Connected to {s}:{d}\n", .{ conn.host, conn.port });

    std.debug.print("✅ All style patterns demonstrated successfully!\n", .{});
}

// ============================================================================
// TESTS
// ============================================================================

test "style example - proper test naming" {
    const items = [_]i32{ 1, 2, 3, 4, 5 };
    const result = sum_items(&items);
    try std.testing.expectEqual(@as(i64, 15), result);
}

test "style example - options struct pattern" {
    const conn = try connect(std.testing.allocator, .{
        .host = "example.com",
        .port = 443,
        .timeout_ms = 10000,
    });
    try std.testing.expectEqual(@as(u16, 443), conn.port);
    try std.testing.expectEqual(@as(u64, 10000), conn.timeout_ms);
}
