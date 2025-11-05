# Example 4: File I/O with Buffering

This example demonstrates file I/O migration in Zig 0.15.2, focusing on explicit buffering for performance and the critical importance of `flush()`.

## What Changed

File I/O in 0.15.2 requires explicit buffer management:

1. **Buffer parameter**: `file.writer()` → `file.writer(buffer)`
2. **Interface access**: Operations via `.interface` field
3. **Manual flush**: **CRITICAL** - must `flush()` before closing file
4. **Performance control**: Choose buffer size based on workload

## Performance Impact

### Benchmark: Writing 1000 Small Lines

| Version | Approach | Syscalls | Time | Speedup |
|---------|----------|----------|------|---------|
| 0.14.1 | Implicit buffering | ~1000 | 800μs | baseline |
| 0.15.2 | Unbuffered (`&.{}`) | ~1000 | 800μs | 1x |
| 0.15.2 | **4KB buffer** | ~5-10 | **80μs** | **10x** |

**Key Takeaway**: Buffering provides 5-10x performance improvement for file I/O.

## Migration Steps

### Step 1: Add Buffer

Choose buffer size based on use case:

```zig
// 🕐 0.14.x
const writer = file.writer();

// ✅ 0.15+ (optimal for files)
var buf: [4096]u8 = undefined;  // 4KB matches filesystem block size
var writer = file.writer(&buf);
```

### Step 2: Access via .interface

```zig
// 🕐 0.14.x
try writer.print("Data\n", .{});

// ✅ 0.15+
try writer.interface.print("Data\n", .{});
```

### Step 3: Add CRITICAL flush() Call

```zig
// ✅ 0.15+ - ALWAYS flush before close
try writer.interface.flush();
file.close();
```

## Building and Running

### Zig 0.14.1 Version

```bash
cd 0.14.1
/path/to/zig-0.14.1/zig build run
cat output_014.txt
```

### Zig 0.15.2 Version

```bash
cd 0.15.2
/path/to/zig-0.15.2/zig build run
cat output_015.txt
```

### Expected Output

Both versions create a file with:
```
File I/O Example - Zig 0.14.x / 0.15.2
Writing multiple lines:
Line 0: This is test data
Line 1: This is test data
...
Line 99: This is test data

Write complete!
```

Console output:
```
File written successfully to output_01x.txt
```

## Buffer Size Guidelines

| File Operation Type | Recommended Size | Rationale |
|---------------------|------------------|-----------|
| Small files (< 1KB) | 256-512 bytes | Minimal overhead |
| **General file I/O** | **4096 bytes** | **Matches FS block size** |
| Large sequential writes | 8192-16384 bytes | Reduces syscall overhead |
| Network-backed files | 4096 bytes | Balance latency/throughput |

**Stack allocation limits**: Keep buffers under ~8KB for stack allocation. Larger buffers should be heap-allocated.

## The Critical flush() Requirement

### What Happens Without flush()

```zig
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Important data\n", .{});
file.close();  // ❌ Data still in buffer - LOST!
```

**Result**: File is incomplete or empty. No compile error, no runtime error - just silent data loss.

### Always flush() Before

1. **Closing files**: Ensure all data written to disk
2. **Reading back**: If you write then read the same file
3. **Critical checkpoints**: Transaction boundaries, important milestones
4. **Program exit**: For any buffered file writers still open

### Example: Write-Then-Read Pattern

```zig
// Write phase
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
try writer.interface.flush();  // ✅ CRITICAL before reading

// Seek back to beginning
try file.seekTo(0);

// Read phase
var read_buf: [100]u8 = undefined;
const bytes_read = try file.read(&read_buf);
```

## Common Errors

### Error 1: Forgetting flush() - Silent Data Loss

**Problem** (no compile error):
```zig
var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
file.close();  // ❌ Buffer not flushed
```

**Result**: File is smaller than expected or empty

**Fix**:
```zig
try writer.interface.flush();  // ✅ Always flush first
file.close();
```

**Detection**: File size is less than expected. Use assertions in tests:
```zig
const stat = try file.stat();
try std.testing.expectEqual(expected_size, stat.size);
```

### Error 2: Wrong Buffer Size

**Problem**:
```zig
var buf: [16]u8 = undefined;  // Too small for file I/O
var writer = file.writer(&buf);
// Frequent flushes, poor performance
```

**Fix**:
```zig
var buf: [4096]u8 = undefined;  // Optimal for files
```

### Error 3: Buffer Lifetime Issues

**Problem**:
```zig
fn getFileWriter(file: std.fs.File) !FileWriter {
    var buf: [4096]u8 = undefined;  // ❌ Stack allocation
    var writer = file.writer(&buf);
    return writer;  // ❌ buf is destroyed!
}
```

**Fix**: Keep buffer with writer in struct
```zig
const FileWriter = struct {
    file: std.fs.File,
    buffer: [4096]u8 = undefined,
    writer: std.fs.File.Writer,

    fn init(file: std.fs.File) FileWriter {
        var self: FileWriter = undefined;
        self.file = file;
        self.writer = file.writer(&self.buffer);
        return self;
    }

    fn deinit(self: *FileWriter) !void {
        try self.writer.interface.flush();
        self.file.close();
    }
};
```

## Performance Tips

### 1. Use Appropriate Buffer Size

```zig
// ❌ Too small - frequent syscalls
var buf: [128]u8 = undefined;

// ✅ Optimal for files
var buf: [4096]u8 = undefined;

// ❌ Too large - wastes stack space
var buf: [65536]u8 = undefined;
```

### 2. Flush Strategically

```zig
// ❌ Flush after every write - defeats buffering
try writer.interface.print("Line\n", .{});
try writer.interface.flush();  // Too frequent

// ✅ Flush at logical boundaries
for (batches) |batch| {
    for (batch.items) |item| {
        try writer.interface.print("{}\n", .{item});
    }
    try writer.interface.flush();  // Once per batch
}
```

### 3. Consider Unbuffered for Critical Data

```zig
// Audit log - must hit disk immediately
var writer = audit_file.writer(&.{});  // Unbuffered
try writer.interface.print("[{}] {s}\n", .{ timestamp, event });
// No flush needed - writes immediately
```

## Error Handling

### Handle flush() Errors

```zig
writer.interface.flush() catch |err| {
    std.log.err("Failed to flush file: {}", .{err});
    return err;
};
file.close();
```

### Use errdefer for Cleanup

```zig
const file = try std.fs.cwd().createFile("data.txt", .{});
errdefer file.close();  // Close on error

var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);

try writer.interface.print("Data\n", .{});
try writer.interface.flush();

file.close();  // Normal close
```

## Testing File I/O

```zig
test "file write and flush" {
    const file = try std.fs.cwd().createFile("test.txt", .{});
    defer {
        file.close();
        std.fs.cwd().deleteFile("test.txt") catch {};
    }

    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);

    try writer.interface.print("Test data\n", .{});
    try writer.interface.flush();

    // Verify file size
    const stat = try file.stat();
    try std.testing.expectEqual(10, stat.size);  // "Test data\n"

    // Verify contents
    try file.seekTo(0);
    var read_buf: [100]u8 = undefined;
    const n = try file.read(&read_buf);
    try std.testing.expectEqualStrings("Test data\n", read_buf[0..n]);
}
```

## Summary

File I/O migration checklist:

- [ ] Add buffer (4KB for files)
- [ ] Access methods via `.interface`
- [ ] **Add flush() before close** (CRITICAL)
- [ ] Ensure buffer lifetime
- [ ] Test file size and contents
- [ ] Handle flush errors

**Most Important**: Never forget `flush()` before closing files. This is the most common source of bugs in migrated code.

## Next Steps

- See Example 2 for stdout/stderr buffering
- See Example 5 for file I/O in complete application
- Review Chapter 5 for more I/O patterns

## Estimated Migration Time

**15-20 minutes per module with file I/O**

Mostly mechanical, but requires careful review of all file close operations to ensure flush() is called.
