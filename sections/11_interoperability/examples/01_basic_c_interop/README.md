# Example 1: Basic C Interoperability

## Overview

This example demonstrates the fundamentals of C interoperability in Zig using `@cImport` to translate C headers and call C standard library functions.

## Learning Objectives

- Understand `@cImport` and `@cInclude` syntax
- Import and call C stdlib functions (printf, malloc, free, strlen, memset)
- Work with C types (c_int, c_size_t)
- Handle C strings with null termination ([*:0]const u8)
- Manage C-allocated memory safely using defer

## Key Concepts

### @cImport

`@cImport` invokes Clang to translate C headers into Zig-compatible declarations:

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
```

### C Type Mapping

Zig provides C-compatible types that match platform ABIs:

- `c.c_int` - matches C's `int` (platform-dependent size)
- `c.c_size_t` - matches C's `size_t`
- `c.c_char` - matches C's `char`

Using these types ensures ABI compatibility across different platforms.

### C String Handling

C strings are null-terminated, represented in Zig as `[*:0]const u8`:

```zig
const c_string: [*:0]const u8 = "null-terminated";
_ = c.strlen(c_string); // Safe to pass to C
```

### Memory Management

When using C allocation functions, always pair malloc/free:

```zig
const ptr = c.malloc(size);
if (ptr == null) return error.OutOfMemory;
defer c.free(ptr); // Ensures cleanup
```

## Building and Running

```bash
# Build the example
zig build

# Run the example
zig build run
```

## Expected Output

```
=== Basic C Interoperability Demo ===
Hello from C's printf function!

C int value: 42
Size of c_int: 4 bytes

String via printf: C-style null-terminated string
String length: 31

Allocated 100 bytes at address 0x...
Initialized memory with zeros

Formatted string: Format example: 123

=== Demo Complete ===
```

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2

## Common Pitfalls Avoided

1. **Memory leaks**: Using `defer c.free(ptr)` ensures cleanup
2. **Null checks**: Checking malloc return value before use
3. **Buffer overflows**: Using `snprintf` instead of `sprintf`
4. **Type safety**: Using `c.c_int` instead of assuming `i32`

## References

- [Zig Language Reference 0.15.2 - C Interop](https://ziglang.org/documentation/0.15.2/#C)
- [Zig stdlib std/c.zig](https://github.com/ziglang/zig/blob/master/lib/std/c.zig)
