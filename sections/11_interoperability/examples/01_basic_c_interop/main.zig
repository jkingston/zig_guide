const std = @import("std");

// Import C standard library headers using @cImport
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
});

pub fn main() !void {
    // Example 1: Using C printf
    _ = c.printf("=== Basic C Interoperability Demo ===\n");
    _ = c.printf("Hello from C's printf function!\n\n");

    // Example 2: C type usage (c_int is platform-dependent)
    const num: c_int = 42;
    _ = c.printf("C int value: %d\n", num);
    const sizeof_c_int: usize = @sizeOf(c_int);
    _ = c.printf("Size of c_int: %zu bytes\n\n", sizeof_c_int);

    // Example 3: C string handling with null termination
    const c_string: [*:0]const u8 = "C-style null-terminated string";
    _ = c.printf("String via printf: %s\n", c_string);
    const str_len = c.strlen(c_string);
    _ = c.printf("String length: %zu\n\n", str_len);

    // Example 4: C memory allocation and management
    const size: usize = 100;
    const ptr = c.malloc(size);
    if (ptr == null) {
        _ = c.printf("malloc failed!\n");
        return error.OutOfMemory;
    }
    defer c.free(ptr);

    _ = c.printf("Allocated %zu bytes at address %p\n", size, ptr);

    // Example 5: Using C memset to initialize memory
    _ = c.memset(ptr, 0, size);
    _ = c.printf("Initialized memory with zeros\n\n");

    // Example 6: Working with C arrays
    var buffer: [64]u8 = undefined;
    _ = c.snprintf(&buffer, buffer.len, "Format example: %d", 123);
    _ = c.printf("Formatted string: %s\n", &buffer);

    // Example 7: Demonstrating pointer type compatibility
    // [*c] pointers allow null and are C-compatible
    const c_ptr: [*c]u8 = @ptrCast(ptr);
    _ = c_ptr; // Suppress unused warning

    _ = c.printf("\n=== Demo Complete ===\n");
}
