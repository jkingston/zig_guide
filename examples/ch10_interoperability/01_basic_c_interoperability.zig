// Example 1: Basic C Interoperability
// 11 Interoperability
//
// Extracted from chapter content.md

const std = @import("std");

// Mock C functions for demonstration (real version would use @cImport)
const c = struct {
    pub fn printf(comptime fmt: [*:0]const u8) i32 {
        // Mock implementation - in real code this would call C's printf
        std.debug.print("{s}", .{std.mem.span(fmt)});
        return 0;
    }

    pub fn strlen(s: [*:0]const u8) usize {
        var len: usize = 0;
        while (s[len] != 0) : (len += 1) {}
        return len;
    }

    pub fn malloc(size: usize) ?*anyopaque {
        // Mock implementation
        const allocator = std.heap.page_allocator;
        const bytes = allocator.alloc(u8, size) catch return null;
        return @ptrCast(bytes.ptr);
    }

    pub fn free(ptr: ?*anyopaque) void {
        _ = ptr;
        // Mock implementation - in real code would free memory
    }

    pub fn memset(ptr: ?*anyopaque, value: i32, size: usize) ?*anyopaque {
        if (ptr) |p| {
            const bytes: [*]u8 = @ptrCast(@alignCast(p));
            @memset(bytes[0..size], @intCast(value));
            return p;
        }
        return null;
    }
};

pub fn main() !void {
    // Call C's printf
    _ = c.printf("Hello from C's printf!\n");

    // Work with C integers
    const value: i32 = 42;
    std.debug.print("C int value: {d}\n", .{value});

    // C string handling with null termination
    const c_string: [*:0]const u8 = "C-style string";
    const len = c.strlen(c_string);
    std.debug.print("String length: {d}\n", .{len});

    // C memory allocation with defer cleanup
    const size: usize = 100;
    const ptr = c.malloc(size);
    if (ptr == null) return error.OutOfMemory;
    defer c.free(ptr);

    _ = c.memset(ptr, 0, size);
    std.debug.print("Allocated and zeroed {d} bytes\n", .{size});
}