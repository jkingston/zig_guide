# Example 3: Build System Integration with C Dependencies

## Overview

This example demonstrates how to integrate C source files and custom C libraries into a Zig build using `build.zig`. It shows proper configuration of include paths, compiler flags, and modular organization.

## Learning Objectives

- Compile C source files alongside Zig code
- Configure include paths with `addIncludePath`
- Set C compiler flags with `addCSourceFiles`
- Organize code with Zig modules
- Create Zig wrappers for C functions
- Handle string conversion between Zig and C

## Project Structure

```
03_build_integration/
├── build.zig          # Build configuration
├── src/
│   ├── main.zig       # Entry point
│   └── wrapper.zig    # Zig wrappers for C functions
└── c_lib/
    ├── mylib.h        # C library header
    └── mylib.c        # C library implementation
```

## Key Build Concepts

### Adding C Source Files

```zig
exe.addCSourceFiles(.{
    .files = &.{
        "c_lib/mylib.c",
    },
    .flags = &.{
        "-Wall",
        "-Wextra",
        "-std=c99",
    },
});
```

### Configuring Include Paths

```zig
exe.addIncludePath(b.path("c_lib"));
```

This makes headers in `c_lib/` available to both C and Zig code.

### Creating Zig Modules

```zig
const wrapper_module = b.addModule("wrapper", .{
    .root_source_file = b.path("src/wrapper.zig"),
});
exe.root_module.addImport("wrapper", wrapper_module);
```

## Key Code Patterns

### String Conversion (Zig → C)

C requires null-terminated strings. Convert Zig slices:

```zig
pub fn printMessage(message: []const u8) !void {
    const allocator = std.heap.c_allocator;
    const c_message = try allocator.dupeZ(u8, message);
    defer allocator.free(c_message);

    c.print_message(c_message);
}
```

### Array Passing

Zig slices can be passed to C using `.ptr` and `.len`:

```zig
pub fn calculateAverage(values: []const f64) f64 {
    return c.calculate_average(values.ptr, values.len);
}
```

### Fixed vs Platform Types

When C uses fixed-size types (`int32_t`), you can use Zig's fixed types (`i32`):

```zig
// C header: int32_t add_numbers(int32_t a, int32_t b);
pub fn addNumbers(a: i32, b: i32) i32 {
    return c.add_numbers(a, b);
}
```

If C uses platform-dependent types (`int`), use `c_int` instead.

## Building and Running

```bash
# Build the example
zig build

# Run the example
zig build run
```

## Expected Output

```
=== Build Integration Demo ===

15 + 27 = 42 (via C library)

[C Library] Hello from Zig!
[C Library] Mixed Zig and C code working together

Average of values: 30.36

Processing 5 items (Zig function)...
Average: 30.00

=== Demo Complete ===
```

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2

## Cross-Platform Considerations

This example works across platforms because:
- Uses standard C99
- No platform-specific APIs
- Fixed-size integer types in C headers
- Proper include path configuration

## Common Pitfalls Avoided

1. **Missing linkLibC**: Required when compiling C code
2. **Include path errors**: Using `b.path()` for correct resolution
3. **String lifetime**: Using `defer` to free allocated C strings
4. **Type mismatches**: Using `i32` when C uses `int32_t`

## References

- [Zig Build System Guide](https://zig.guide/build-system/)
- [Ghostty build.zig](https://github.com/ghostty-org/ghostty/blob/main/build.zig) - Production build system example
- [Zig Language Reference - Build System](https://ziglang.org/documentation/0.15.2/#Build-System)
