/// Common Zig Patterns Quick Reference
const std = @import("std");

// === INITIALIZATION PATTERNS ===

// Pattern 1: Struct literal
const Point = struct { x: i32, y: i32 };
const p1 = Point{ .x = 10, .y = 20 };

// Pattern 2: Init function
const Buffer = struct {
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Buffer {
        return Buffer{
            .data = try allocator.alloc(u8, size),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.allocator.free(self.data);
    }
};

// === ERROR HANDLING PATTERNS ===

fn pattern_try_propagate(reader: anytype) !i32 {
    const bytes = try reader.readBytesNoEof(4);
    return std.mem.readInt(i32, &bytes, .big);
}

fn pattern_catch_default(reader: anytype) i32 {
    return pattern_try_propagate(reader) catch 0;
}

fn pattern_errdefer_cleanup(allocator: std.mem.Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);

    const result = try Result.init(allocator);
    errdefer result.deinit();

    return result;
}

const Result = struct {
    data: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Result {
        return Result{
            .data = try allocator.alloc(u8, 10),
            .allocator = allocator,
        };
    }

    fn deinit(self: Result) void {
        self.allocator.free(self.data);
    }
};

// === MEMORY MANAGEMENT PATTERNS ===

fn pattern_defer_cleanup(allocator: std.mem.Allocator, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    _ = content;
}

fn pattern_arena_temporary(allocator: std.mem.Allocator) !FinalResult {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const temp1 = try arena_allocator.alloc(u8, 100);
    const temp2 = try arena_allocator.alloc(u8, 200);
    _ = temp1;
    _ = temp2;

    return FinalResult{ .value = 42 };
}

const FinalResult = struct { value: i32 };

// === OPTIONAL HANDLING PATTERNS ===

fn pattern_orelse_default(maybe_value: ?i32) i32 {
    return maybe_value orelse 42;
}

fn pattern_if_unwrap(maybe_value: ?i32) void {
    if (maybe_value) |val| {
        std.debug.print("Value: {d}\n", .{val});
    } else {
        std.debug.print("No value\n", .{});
    }
}

fn pattern_while_unwrap(iterator: anytype) void {
    while (iterator.next()) |item| {
        std.debug.print("Item: {any}\n", .{item});
    }
}

// === ITERATION PATTERNS ===

fn pattern_for_with_index(items: []const i32) void {
    for (items, 0..) |item, i| {
        std.debug.print("{d}: {d}\n", .{ i, item });
    }
}

fn pattern_while_with_continue(items: []const i32) i64 {
    var sum: i64 = 0;
    var i: usize = 0;
    while (i < items.len) : (i += 1) {
        if (items[i] < 0) continue;
        sum += items[i];
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Demonstrate patterns
    var buffer = try Buffer.init(allocator, 100);
    defer buffer.deinit();

    const items = [_]i32{ 1, 2, 3, 4, 5 };
    pattern_for_with_index(&items);
    const sum = pattern_while_with_continue(&items);
    std.debug.print("Sum: {d}\n", .{sum});

    std.debug.print("All patterns demonstrated!\n", .{});
}
