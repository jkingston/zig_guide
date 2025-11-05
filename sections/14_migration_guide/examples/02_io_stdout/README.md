# Example 2: I/O Migration - stdout/stderr

This example demonstrates the I/O API changes in Zig 0.15.2, including stdout/stderr relocation and explicit buffering requirements.

## What Changed

Three major I/O changes in 0.15.2:

1. **Relocation**: `std.io.getStdOut()` → `std.fs.File.stdout()`
2. **Buffering**: `writer()` now requires explicit buffer parameter
3. **Interface**: Writer methods accessed via `.interface` field
4. **Flush**: Manual `flush()` required before program exit

## Migration Steps

### Step 1: Update Import Locations

```zig
// 🕐 0.14.x
const stdout = std.io.getStdOut().writer();

// ✅ 0.15+
const stdout = std.fs.File.stdout();
```

### Step 2: Add Buffer

Choose buffered or unbuffered approach:

**Buffered (better performance)**:
```zig
var stdout_buf: [256]u8 = undefined;
var stdout = std.fs.File.stdout().writer(&stdout_buf);
```

**Unbuffered (immediate writes)**:
```zig
var stdout = std.fs.File.stdout().writer(&.{});  // Empty slice
```

### Step 3: Access via .interface

```zig
// 🕐 0.14.x
try stdout.print("Hello\n", .{});

// ✅ 0.15+
try stdout.interface.print("Hello\n", .{});
```

### Step 4: Add flush()

For buffered writers, ensure data is written before exit:

```zig
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
Regular output to stdout
Formatted value: 42
Multiple values: 10 + 32 = 42
Error message to stderr
Warning: This is a test warning
```

## Buffered vs Unbuffered

### When to Use Buffered

- **File I/O**: Always use buffering for files (4KB-8KB buffer)
- **stdout**: Use for performance-critical output
- **Multiple small writes**: Reduces syscalls significantly

**Example**: 1000 small writes
- Unbuffered: ~1000 syscalls, 500-1000 microseconds
- Buffered (4KB): ~1-10 syscalls, 50-100 microseconds (**5-10x faster**)

### When to Use Unbuffered

- **stderr**: Error messages should be immediately visible
- **Interactive output**: User should see output immediately
- **Critical logging**: Data must hit disk/terminal right away
- **Low-frequency writes**: Buffering overhead not worth it

## Common Errors

### Error 1: Missing Buffer Parameter

```zig
var stdout = std.fs.File.stdout().writer();  // ❌ Compile error
```

```
error: expected 1 argument, found 0
```

**Fix**:
```zig
var stdout = std.fs.File.stdout().writer(&.{});  // ✅ Unbuffered
// OR
var buf: [256]u8 = undefined;
var stdout = std.fs.File.stdout().writer(&buf);  // ✅ Buffered
```

### Error 2: Wrong Import Path

```zig
const stdout = std.io.getStdOut();  // ❌ Function moved
```

```
error: no field named 'getStdOut' in struct 'std.io'
```

**Fix**:
```zig
const stdout = std.fs.File.stdout();  // ✅ New location
```

### Error 3: Forgetting .interface Accessor

```zig
var stdout = std.fs.File.stdout().writer(&buf);
try stdout.print("Hello\n", .{});  // ❌ No field 'print'
```

```
error: no field named 'print' in struct 'fs.File.Writer'
```

**Fix**:
```zig
try stdout.interface.print("Hello\n", .{});  // ✅ Access via .interface
```

### Error 4: Forgetting flush() - Silent Data Loss

```zig
var buf: [256]u8 = undefined;
var stdout = std.fs.File.stdout().writer(&buf);
try stdout.interface.print("Important data\n", .{});
// Program exits - data still in buffer, never written!
```

**No compile error**, but output may be missing or incomplete.

**Fix**:
```zig
try stdout.interface.print("Important data\n", .{});
try stdout.interface.flush();  // ✅ Ensure data is written
```

## Buffer Size Guidelines

| Use Case | Recommended Size | Rationale |
|----------|------------------|-----------|
| Terminal output | 256-1024 bytes | Enough for typical lines |
| File I/O | 4096-8192 bytes | Matches filesystem block size |
| Network I/O | 4096-16384 bytes | Network packet sizes |
| Logging | 1024-4096 bytes | Balance of memory/performance |

## Performance Tips

1. **Use larger buffers for batch writes**: More writes → larger buffer
2. **Flush strategically**: At logical boundaries, not after every write
3. **Prefer unbuffered for stderr**: Immediate visibility more important than speed
4. **Stack-allocate buffers when possible**: Avoid heap allocation overhead

## Why These Changes?

- **Explicit buffering**: Performance is now predictable and controllable
- **Clear ownership**: Buffer lifetime is explicit
- **Better error handling**: Flush errors can be caught and handled
- **Consistent API**: All writers work the same way

## Next Steps

- See Example 4 for file I/O with buffering
- See Example 5 for I/O in a complete application
- Review Chapter 5 for more I/O patterns

## Estimated Migration Time

**10-15 minutes per module with I/O code**

Mostly mechanical changes, but requires careful attention to flush() calls.
