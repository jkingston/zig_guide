# Example 6: Library with Module System

This example demonstrates library migration patterns including module exports, dependency management, and API design for Zig 0.15.2.

## Library Overview

**mathlib**: A math utility library providing:
- `factorial(n)`: Calculate factorial
- `fibonacci(n, allocator)`: Generate Fibonacci sequence
- `primes(limit, allocator)`: Generate prime numbers

**Structure**:
- `src/mathlib.zig`: Library implementation
- `examples/usage.zig`: Example program using the library
- `build.zig`: Build configuration with module export

## What Changed

This example shows migration of:

1. **Library build.zig**: Module export and executable configuration
2. **Library implementation**: ArrayList usage in public API
3. **Example usage**: Importing and using the migrated library

## Migration Points

### 1. Library build.zig

**0.14.1**:
```zig
// Export library module
_ = b.addModule("mathlib", .{
    .root_source_file = b.path("src/mathlib.zig"),
    .target = target,
    .optimize = optimize,
});

// Example executable
const example = b.addExecutable(.{
    .name = "mathlib_example",
    .root_source_file = b.path("examples/usage.zig"),
    .target = target,
    .optimize = optimize,
});

// Add library import
const mathlib_mod = b.createModule(.{...});
example.root_module.addImport("mathlib", mathlib_mod);
```

**0.15.2**:
```zig
// Export library module (same)
_ = b.addModule("mathlib", .{
    .root_source_file = b.path("src/mathlib.zig"),
    .target = target,
    .optimize = optimize,
});

// Example executable - requires .root_module
const mathlib_mod = b.createModule(.{
    .root_source_file = b.path("src/mathlib.zig"),
    .target = target,
    .optimize = optimize,
});

const example = b.addExecutable(.{
    .name = "mathlib_example",
    .root_module = b.createModule(.{
        .root_source_file = b.path("examples/usage.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mathlib", .module = mathlib_mod },
        },
    }),
});
```

### 2. Library Implementation (mathlib.zig)

**0.14.1**:
```zig
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    var list = std.ArrayList(u64).init(allocator);
    errdefer list.deinit();

    try list.append(0);
    try list.append(1);
    // ...

    return list.toOwnedSlice();
}
```

**0.15.2**:
```zig
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    var list = std.ArrayList(u64).empty;
    errdefer list.deinit(allocator);

    try list.append(allocator, 0);
    try list.append(allocator, 1);
    // ...

    return list.toOwnedSlice(allocator);
}
```

### 3. Example Usage (usage.zig)

**0.14.1**:
```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Factorial: {d}\n", .{result});
```

**0.15.2**:
```zig
var stdout_buf: [512]u8 = undefined;
var stdout = std.fs.File.stdout().writer(&stdout_buf);
try stdout.interface.print("Factorial: {d}\n", .{result});
try stdout.interface.flush();
```

## Building and Running

### Zig 0.14.1 Version

```bash
cd 0.14.1
/path/to/zig-0.14.1/zig build run
```

### Zig 0.15.2 Version

```bash
cd 0.15.2
/path/to/zig-0.15.2/zig build run
```

### Expected Output (Both Versions)

```
Math Library Example
====================

Factorial of 10: 3628800
First 10 Fibonacci numbers: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
Primes up to 50: 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47
```

## Library API Design Considerations

### Allocator Passing

**Best Practice**: Always accept allocator as parameter for functions that allocate:

```zig
// ✅ Good: Allocator explicit
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64

// ❌ Bad: Hidden allocation
pub fn fibonacci(n: u32) ![]const u64  // Where's the allocator?
```

### Ownership Transfer

Functions that return allocated memory should document ownership:

```zig
/// Generate Fibonacci sequence up to n terms
/// Caller owns returned slice
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    // ...
    return list.toOwnedSlice(allocator);
}

// Usage:
const fib = try mathlib.fibonacci(10, allocator);
defer allocator.free(fib);  // Caller frees
```

### Error Handling

Use `errdefer` to clean up on error:

```zig
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    var list = std.ArrayList(u64).empty;
    errdefer list.deinit(allocator);  // Clean up on error

    try list.append(allocator, 0);  // May error
    try list.append(allocator, 1);  // May error

    return list.toOwnedSlice(allocator);  // Transfer ownership
}
```

## Module Export Patterns

### For Library Authors

**Recommended pattern** for libraries to be used by other projects:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Export library module for dependents
    _ = b.addModule("mylib", .{
        .root_source_file = b.path("src/mylib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Optional: example executable
    // ...
}
```

### For Library Users

**Using the library** in another project's build.zig:

```zig
const mylib_dep = b.dependency("mylib", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{
    .name = "my_app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mylib", .module = mylib_dep.module("mylib") },
        },
    }),
});
```

## Testing Library Code

```zig
// In mathlib.zig

test "factorial basic" {
    try std.testing.expectEqual(1, factorial(0));
    try std.testing.expectEqual(1, factorial(1));
    try std.testing.expectEqual(120, factorial(5));
}

test "fibonacci" {
    const allocator = std.testing.allocator;

    const fib = try fibonacci(10, allocator);
    defer allocator.free(fib);

    try std.testing.expectEqual(10, fib.len);
    try std.testing.expectEqual(0, fib[0]);
    try std.testing.expectEqual(1, fib[1]);
    try std.testing.expectEqual(34, fib[9]);
}

test "primes" {
    const allocator = std.testing.allocator;

    const prime_list = try primes(20, allocator);
    defer allocator.free(prime_list);

    try std.testing.expectEqual(8, prime_list.len);
    try std.testing.expectEqual(2, prime_list[0]);
    try std.testing.expectEqual(19, prime_list[7]);
}
```

Run tests:
```bash
zig build test
```

## Migration Checklist for Libraries

- [ ] Update build.zig with .root_module for executables
- [ ] Keep `addModule()` for library export (syntax unchanged)
- [ ] Update ArrayList usage in library code:
  - [ ] .init() → .empty
  - [ ] Add allocator to mutation methods
  - [ ] Add allocator to toOwnedSlice()
- [ ] Update example/test code:
  - [ ] I/O migration
  - [ ] Build system migration
- [ ] Update documentation with ownership notes
- [ ] Add or update tests
- [ ] Verify tests pass on 0.15.2
- [ ] Update README with version compatibility

## Common Library Migration Issues

### Issue 1: Forgetting errdefer with Allocator

**Problem**:
```zig
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    var list = std.ArrayList(u64).empty;
    // Missing errdefer - leaks on error

    try list.append(allocator, 0);  // May error
    return list.toOwnedSlice(allocator);
}
```

**Fix**:
```zig
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    var list = std.ArrayList(u64).empty;
    errdefer list.deinit(allocator);  // ✅ Clean up on error

    try list.append(allocator, 0);
    return list.toOwnedSlice(allocator);
}
```

### Issue 2: Module Import Mismatch

**Problem**: Executable can't find library module

**Fix**: Ensure module names match:
```zig
// In build.zig
.{ .name = "mathlib", .module = mathlib_mod }

// In usage.zig
const mathlib = @import("mathlib");  // Must match name
```

## Performance Notes

**Memory Savings**: Library code using unmanaged ArrayList saves 8 bytes per container instance.

**API Clarity**: Allocator parameters make allocation explicit:
```zig
const fib = try mathlib.fibonacci(100, allocator);  // Clear: allocates
const fact = mathlib.factorial(100);  // Clear: no allocation
```

## Next Steps

- See Chapter 8 for more build system patterns
- See Chapter 9 for package dependency management
- See Chapter 4 for advanced container patterns

## Estimated Migration Time

**20-30 minutes for typical library**

Includes updating implementation, examples, tests, and build configuration.
