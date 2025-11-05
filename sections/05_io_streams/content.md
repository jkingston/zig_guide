# I/O, Streams & Formatting

## Overview

Zig provides a consistent I/O abstraction through its `Writer` and `Reader` interfaces. These generic interfaces enable uniform I/O operations across different backends—files, network sockets, memory buffers—without sacrificing performance or control. The standard library uses a vtable-based approach, allowing you to write code that works with any I/O source or destination.

**Version Note:** Significant API changes occurred between Zig 0.14.x and 0.15.x for stdout/stderr access and writer buffering. This chapter marks version-specific patterns with 🕐 **0.14.x** for legacy code and ✅ **0.15+** for current patterns. Most file I/O operations remain compatible across versions.

This chapter covers obtaining writers and readers, formatting output, managing stream lifetimes, and practical patterns from production Zig codebases. Understanding these patterns is essential for CLI tools, servers, build systems, and any program that reads or writes data.

## Core Concepts

### Writers and Readers

Zig's I/O abstraction centers on two generic interfaces: `Writer` for output and `Reader` for input. Both use vtables to provide polymorphic behavior without runtime overhead.

**Obtaining stdout and stderr writers:**

🕐 **0.14.x:**
```zig
const std = @import("std");

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();
const writer = stdout.writer();
try writer.print("Hello!\n", .{});
```

✅ **0.15+:**
```zig
const std = @import("std");

const stdout = std.fs.File.stdout();
const stderr = std.fs.File.stderr();

// Buffered writer (requires explicit buffer)
var buf: [4096]u8 = undefined;
var file_writer = stdout.writer(&buf);
try file_writer.interface.print("Hello!\n", .{});
try file_writer.interface.flush();

// Unbuffered writer
var unbuffered = stdout.writer(&.{});  // Empty slice = unbuffered
try unbuffered.interface.writeAll("Direct output\n");
```

The key difference in 0.15+ is explicit buffering: you pass a buffer slice to `file.writer()`, and the returned `File.Writer` contains an `interface: Io.Writer` field that provides formatting methods. Passing an empty slice creates an unbuffered writer.

**Basic formatting example:**

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();  // ✅ 0.15+
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(&buf);

    try writer.interface.print("Hello from stdout! Number: {d}\n", .{42});
    try writer.interface.print("Hex: 0x{x}, Binary: 0b{b}\n", .{ 255, 5 });
    try writer.interface.flush();
}
```

### File I/O Patterns

Opening and reading files follows consistent patterns across versions:

```zig
const std = @import("std");

pub fn readEntireFile(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();  // Always close on scope exit

    // Read entire file with 1MB limit
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    return contents;  // Caller must free
}
```

**Writing to files:**

```zig
pub fn writeToFile(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    // ✅ 0.15+: Buffered writing
    var buf: [4096]u8 = undefined;
    var file_writer = file.writer(&buf);
    try file_writer.interface.writeAll(data);
    try file_writer.interface.flush();
}
```

**Streaming file reads:**

For large files, stream data instead of loading everything into memory:

```zig
pub fn processFileLine(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var file_reader = file.reader(&buf);

    while (true) {
        const line = file_reader.readUntilDelimiterOrEof(&buf, '\n') catch |err| switch (err) {
            error.StreamTooLong => {
                // Line longer than buffer, skip to next newline
                try file_reader.skipUntilDelimiterOrEof('\n');
                continue;
            },
            else => return err,
        } orelse break;  // EOF

        // Process line...
        std.debug.print("{s}\n", .{line});
    }
}
```

### Formatting and Print

Zig's `std.fmt` module provides format specifiers for the `print` function:

| Specifier | Type | Example | Output |
|-----------|------|---------|--------|
| `{}` | Any | `print("{}", .{42})` | `42` |
| `{d}` | Decimal | `print("{d}", .{42})` | `42` |
| `{x}` | Hex (lower) | `print("{x}", .{255})` | `ff` |
| `{X}` | Hex (upper) | `print("{X}", .{255})` | `FF` |
| `{o}` | Octal | `print("{o}", .{8})` | `10` |
| `{b}` | Binary | `print("{b}", .{5})` | `101` |
| `{s}` | String | `print("{s}", .{"hello"})` | `hello` |
| `{e}` | Scientific | `print("{e}", .{1000.0})` | `1.0e+03` |
| `{d:.2}` | Float precision | `print("{d:.2}", .{3.14159})` | `3.14` |
| `{s:<10}` | Left align | `print("'{s:<10}'", .{"hi"})` | `'hi        '` |
| `{s:>10}` | Right align | `print("'{s:>10}'", .{"hi"})` | `'        hi'` |
| `{s:^10}` | Center | `print("'{s:^10}'", .{"hi"})` | `'    hi    '` |

**Custom formatting for user types:**

Implement the `format` function to make your types printable:

```zig
const Point = struct {
    x: f32,
    y: f32,

    pub fn format(
        self: Point,
        comptime fmt_str: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt_str;
        try writer.print("Point({d:.2}, {d:.2})", .{ self.x, self.y });
    }
};

// Usage:
const p = Point{ .x = 3.14, .y = 2.71 };
try writer.print("Location: {}\n", .{p});  // Output: Location: Point(3.14, 2.71)
```

For types with multiple format modes, inspect `fmt_str`:

```zig
const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn format(
        self: Color,
        comptime fmt_str: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        if (std.mem.eql(u8, fmt_str, "hex")) {
            try writer.print("#{x:0>2}{x:0>2}{x:0>2}", .{ self.r, self.g, self.b });
        } else {
            try writer.print("rgb({d}, {d}, {d})", .{ self.r, self.g, self.b });
        }
    }
};

// Usage:
const color = Color{ .r = 255, .g = 128, .b = 64 };
try writer.print("Default: {}\n", .{color});      // rgb(255, 128, 64)
try writer.print("Hex: {hex}\n", .{color});       // #ff8040
```

### Stream Lifetime Management

Proper resource cleanup is critical for I/O operations. Zig provides `defer` and `errdefer` for deterministic cleanup:

```zig
pub fn safeFileOperation(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();  // Executed when scope exits (success or error)

    // File automatically closed on error or normal return
    const stat = try file.stat();
    std.debug.print("Size: {d} bytes\n", .{stat.size});
}
```

**Error-path-only cleanup with `errdefer`:**

```zig
pub fn createAndWrite(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    errdefer file.close();  // Only executed if subsequent operations fail

    // If writeAll fails, errdefer closes the file
    try file.writeAll(data);

    file.close();  // Normal close on success path
}
```

**Multiple resources with proper cleanup order:**

```zig
pub fn complexOperation(allocator: std.mem.Allocator) !void {
    const file1 = try std.fs.cwd().createFile("file1.txt", .{});
    errdefer file1.close();

    const file2 = try std.fs.cwd().createFile("file2.txt", .{});
    errdefer file2.close();

    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);

    // Do work...

    // Success path: clean up in reverse order
    allocator.free(buffer);
    file2.close();
    file1.close();
}
```

**Arena pattern for bulk cleanup:**

When multiple allocations share a lifetime, use `ArenaAllocator`:

```zig
pub fn processBatch() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();  // Frees all allocations at once

    const allocator = arena.allocator();

    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    var buf: [256]u8 = undefined;
    var file_writer = file.writer(&buf);

    // Multiple allocations—all freed by arena.deinit()
    for (0..10) |i| {
        const line = try std.fmt.allocPrint(allocator, "Line {d}\n", .{i});
        try file_writer.interface.writeAll(line);
        // No need to free 'line'—arena handles it
    }

    try file_writer.interface.flush();
}
```

## Code Examples

### Fixed Buffer Stream (Zero Allocation)

For situations where heap allocation is undesirable, use `fixedBufferStream`:

```zig
const std = @import("std");

pub fn formatMetric(value: u64) ![512]u8 {
    var buffer: [512]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    const writer = fbs.writer();

    try writer.print("metric.count:{d}|g\n", .{value});

    return buffer;  // Entire buffer returned
}
```

This pattern appears in TigerBeetle's StatsD metrics formatting, where allocation-free formatting is critical for performance.[^1]

### Buffered vs Unbuffered Performance

Buffering significantly improves performance for many small writes:

```zig
const std = @import("std");

pub fn demonstrateBuffering() !void {
    const iterations = 1000;

    // Unbuffered (slower)
    {
        const file = try std.fs.cwd().createFile("unbuffered.txt", .{});
        defer file.close();

        var writer = file.writer(&.{});  // Empty slice = unbuffered
        var timer = try std.time.Timer.start();

        for (0..iterations) |i| {
            try writer.interface.print("Line {d}\n", .{i});
        }

        const unbuffered_time = timer.read();
        std.debug.print("Unbuffered: {d}ns\n", .{unbuffered_time});
    }

    // Buffered (faster)
    {
        const file = try std.fs.cwd().createFile("buffered.txt", .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        var writer = file.writer(&buf);
        var timer = try std.time.Timer.start();

        for (0..iterations) |i| {
            try writer.interface.print("Line {d}\n", .{i});
        }
        try writer.interface.flush();

        const buffered_time = timer.read();
        std.debug.print("Buffered: {d}ns\n", .{buffered_time});
    }
}
```

Typical results show 5-10x speedup for buffered writes with small individual operations.

### Ownership Transfer Pattern

When building types that manage I/O resources, implement clear ownership semantics:

```zig
const FileBuffer = struct {
    file: std.fs.File,
    buffer: []u8,
    allocator: std.mem.Allocator,

    pub fn init(path: []const u8, allocator: std.mem.Allocator) !FileBuffer {
        const file = try std.fs.cwd().openFile(path, .{});
        errdefer file.close();

        const buffer = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
        errdefer allocator.free(buffer);

        return FileBuffer{
            .file = file,
            .buffer = buffer,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FileBuffer) void {
        self.allocator.free(self.buffer);
        self.file.close();
    }
};

// Usage:
var fb = try FileBuffer.init("data.txt", allocator);
defer fb.deinit();
// Use fb.buffer...
```

## Common Pitfalls

### 1. Forgetting to Flush Buffered Output

**Problem:** Buffered data may not be written to the underlying stream without an explicit flush.

```zig
// ❌ Data might not be written
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Important data\n", .{});
file.close();  // Buffer contents lost!
```

**Solution:** Always flush before closing or when you need data to be visible:

```zig
// ✅ Correct
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Important data\n", .{});
try writer.interface.flush();  // Ensure data is written
file.close();
```

### 2. Not Closing File Handles

**Problem:** File descriptors leak if not closed, eventually exhausting system resources.

```zig
// ❌ File leaks if readToEndAlloc fails
pub fn readConfig(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    return try file.readToEndAlloc(allocator, max_size);
}
```

**Solution:** Use `defer` to ensure cleanup:

```zig
// ✅ File always closed
pub fn readConfig(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, max_size);
}
```

### 3. Using debug.print in Production

**Problem:** `std.debug.print()` is for debugging only and may not work when stderr is redirected or unavailable.

```zig
// ❌ Debug only, not suitable for production
std.debug.print("Status: {}\n", .{status});
```

**Solution:** Use proper stderr writers for production logging:

```zig
// ✅ Production-ready
const stderr = std.fs.File.stderr();  // ✅ 0.15+
var writer = stderr.writer(&.{});
try writer.interface.print("Status: {}\n", .{status});
```

### 4. Incorrect Buffer Sizing

**Problem:** Buffers that are too small cause frequent flushes, reducing performance.

```zig
// ❌ Too small, causes many syscalls
var buf: [16]u8 = undefined;
var writer = file.writer(&buf);
for (0..1000) |i| {
    try writer.interface.print("Line {d}\n", .{i});
}
```

**Solution:** Use appropriate buffer sizes (4KB-8KB for files):

```zig
// ✅ Better performance
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
for (0..1000) |i| {
    try writer.interface.print("Line {d}\n", .{i});
}
try writer.interface.flush();
```

### 5. Stream Lifetime Confusion

**Problem:** Returning a writer whose buffer or file has gone out of scope.

```zig
// ❌ buf and file are local variables!
fn getWriter() !std.Io.Writer {
    var buf: [256]u8 = undefined;
    var file = try std.fs.cwd().createFile("out.txt", .{});
    var file_writer = file.writer(&buf);
    return file_writer.interface;  // Dangling references!
}
```

**Solution:** Ensure buffer and file outlive the writer:

```zig
// ✅ Buffer and file have appropriate lifetime
fn writeData(file: std.fs.File, data: []const u8) !void {
    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);
    try writer.interface.writeAll(data);
    try writer.interface.flush();
}
```

### 6. Version-Specific: Missing Buffer Parameter (✅ 0.15+)

**Problem:** In 0.15+, writers require an explicit buffer parameter.

```zig
// ❌ 0.15+ compilation error
const stdout = std.fs.File.stdout();
var writer = stdout.writer();  // Missing buffer parameter!
```

**Solution:** Always pass a buffer (empty slice for unbuffered):

```zig
// ✅ 0.15+ correct
var buf: [4096]u8 = undefined;
var writer = stdout.writer(&buf);  // Buffered

// Or for unbuffered:
var writer = stdout.writer(&.{});  // Unbuffered
```

## In Practice

### TigerBeetle: Correctness-Focused I/O

TigerBeetle, a distributed financial database, demonstrates I/O patterns prioritizing correctness and observability.

**Fixed Buffer Streams for Metrics**
- Uses `std.io.fixedBufferStream()` for zero-allocation StatsD metrics formatting[^1]
- Pattern: Compile-time buffer sizing for worst-case metric strings

**Direct I/O with Sector Alignment**
- Opens journal files with `O_DIRECT` flag to bypass page cache[^2]
- Graceful fallback when Direct I/O unavailable
- Block device vs regular file handling

**Latent Sector Error (LSE) Recovery**
- Binary search subdivision to isolate failed sectors on read errors[^3]
- Zeros unreadable sectors for graceful degradation
- AIMD-based recovery throttling

### Ghostty: Event-Driven Terminal I/O

Ghostty, a terminal emulator, shows modern async I/O patterns with the xev library.

**PTY Stream Management**
- Uses `xev.Stream.initFd()` for async pseudo-terminal I/O[^4]
- Write queue with buffer pooling to reduce allocation overhead

**Config File Reading**
- XDG-compliant path resolution with fallbacks[^5]
- Comprehensive validation: file type, size checks before reading

**Fixed Buffer Writers for String Conversion**
- Stack-allocated buffers for config value serialization
- Pattern: `var writer: std.Io.Writer = .fixed(&buf);`

### Bun: High-Performance Buffered I/O

Bun, a JavaScript runtime, demonstrates performance-optimized I/O for module loading.

**Reference-Counted I/O Readers**
- Buffered readers with async deinit queues[^6]
- Pattern: Ref-counting prevents premature resource cleanup in async contexts

**Dynamic Buffers with ArrayListUnmanaged**
- Uses `std.ArrayListUnmanaged` for buffers without storing allocators
- Reduces struct size and indirection overhead for hot-path I/O

### ZLS: LSP Message Formatting

The Zig Language Server demonstrates I/O patterns for protocol communication.

**Fixed Buffer Logging**
- 4KB stack buffer for log message formatting with overflow handling[^7]
- Gracefully handles buffer overflow with "..." suffix
- Pattern: `var writer: std.Io.Writer = .fixed(&buffer);`

**Unbuffered stderr for Critical Messages**
- Uses `std.fs.File.stderr().writer(&.{})` for immediate error output[^7]

## Summary

Zig's I/O abstraction provides explicit control over buffering, resource lifetimes, and formatting. Key decisions:

**Buffering Strategy:**
- Use buffered I/O (4KB-8KB buffers) for files and network streams
- Use unbuffered I/O for interactive terminal output and critical errors
- Use fixed buffer streams when heap allocation is undesirable

**Version Migration:**
- 0.14.x to 0.15+: Replace `std.io.getStdOut()` with `std.fs.File.stdout()`
- Pass explicit buffers to `file.writer(&buf)` or `&.{}` for unbuffered
- Access formatting through `writer.interface.print()` instead of `writer.print()`

**Resource Management:**
- Always use `defer` for cleanup on all paths (success and error)
- Use `errdefer` for cleanup only on error paths
- Consider arena allocators when multiple allocations share a lifetime

**Performance:**
- Buffered I/O typically provides 5-10x speedup for small writes
- Pre-allocate buffers on the stack when size is known
- Use `writeAll` for static strings; reserve `print` for actual formatting

The explicit nature of 0.15+ buffering may seem verbose initially, but it provides clarity about when and how much buffering occurs—essential for systems programming where I/O behavior must be predictable.

---

[^1]: [TigerBeetle - Fixed buffer metrics formatting](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85)
[^2]: [TigerBeetle - Direct I/O implementation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1433-L1570)
[^3]: [TigerBeetle - LSE error recovery](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/storage.zig#L279-L384)
[^4]: [Ghostty - Event loop stream management](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig)
[^5]: [Ghostty - Config file patterns](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig#L136-L166)
[^6]: [Bun - Buffered I/O with reference counting](https://github.com/oven-sh/bun/blob/main/src/shell/IOReader.zig)
[^7]: [ZLS - Fixed buffer logging](https://github.com/zigtools/zls/blob/master/src/main.zig#L50-L100)

## References

1. Zig Standard Library – Io.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/Io.zig))
2. Zig Standard Library – fmt.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fmt.zig))
3. Zig Standard Library – fs/File.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fs/File.zig))
4. TigerBeetle – Fixed buffer metrics formatting ([src/trace/statsd.zig:59-85](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85))
5. TigerBeetle – Direct I/O implementation ([src/io/linux.zig:1433-1570](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1433-L1570))
6. TigerBeetle – LSE error recovery ([src/storage.zig:279-384](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/storage.zig#L279-L384))
7. Ghostty – Event loop stream management ([src/termio/Exec.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig))
8. Ghostty – Config file patterns ([src/config/file_load.zig:136-166](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig#L136-L166))
9. Bun – Buffered I/O with reference counting ([src/shell/IOReader.zig](https://github.com/oven-sh/bun/blob/main/src/shell/IOReader.zig))
10. ZLS – Fixed buffer logging ([src/main.zig:50-100](https://github.com/zigtools/zls/blob/master/src/main.zig#L50-L100))
11. zig.guide – Readers and Writers ([standard-library/readers-and-writers](https://zig.guide/standard-library/readers-and-writers))
