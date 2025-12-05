# Appendix B: Migrating from Zig 0.14 to 0.15

> **Quick reference for upgrading codebases from Zig 0.14.x to 0.15.2**

---

## Overview

This appendix provides a quick-reference guide for migrating code from Zig 0.14.x to 0.15.2. For detailed explanations and production examples, see the main chapters.

**Estimated migration time:** 2-4 hours for typical projects (< 10,000 lines)

### Breaking Changes at a Glance

| Change | Impact | Quick Fix |
|--------|--------|-----------|
| **Build system**: `root_module` required | Every build.zig | Wrap in `b.createModule(.{...})` |
| **I/O API**: Explicit buffering | All I/O code | Add buffer parameter to `writer()` |
| **ArrayList**: Unmanaged default | All container code | Pass allocator to methods |

---

## Build System Migration

### The Change

`addExecutable()`, `addTest()`, and `addLibrary()` now require `.root_module` field.

### Before (0.14.x)

```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

### After (0.15.2)

```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

### Migration Steps

1. Add `.root_module = b.createModule(.{` wrapper
2. Move `root_source_file`, `target`, `optimize` inside `createModule()`
3. Close with `}),`

**Common error:**
```
error: missing struct field: root_module
```
→ Add the `.root_module` field as shown above.

---

## I/O and Writer Migration

### The Changes

1. **Location change:** `std.io.getStdOut()` → `std.fs.File.stdout()`
2. **Buffer required:** `writer()` now requires a buffer parameter
3. **Interface accessor:** Methods accessed via `.interface` field
4. **Flush required:** Must call `flush()` before close

### Before (0.14.x)

```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Hello\n", .{});
```

### After (0.15.2)

```zig
const stdout = std.fs.File.stdout();
var buf: [256]u8 = undefined;
var writer = stdout.writer(&buf);
try writer.interface.print("Hello\n", .{});
try writer.interface.flush();  // CRITICAL
```

### Buffer Sizing Guide

| Use Case | Buffer Size | Example |
|----------|-------------|---------|
| stdout/stderr | 256-1024 bytes | `var buf: [256]u8 = undefined;` |
| File I/O | 4096 bytes | `var buf: [4096]u8 = undefined;` |
| Error messages | Unbuffered | `writer(&.{})` |

### Migration Steps

1. Replace `std.io.getStdOut()` → `std.fs.File.stdout()`
2. Add buffer: `var buf: [4096]u8 = undefined;`
3. Pass to writer: `writer(&buf)`
4. Add `.interface` to method calls: `writer.interface.print()`
5. **Add `flush()` before close/exit**

**Common error:**
```
error: no field named 'print' in struct 'fs.File.Writer'
```
→ Use `writer.interface.print()` instead of `writer.print()`

**Critical mistake:** Forgetting `flush()` causes silent data loss!

```zig
// ❌ WRONG - Data lost!
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
file.close();  // Buffer not flushed!

// ✅ CORRECT
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
try writer.interface.flush();  // Ensure data written
file.close();
```

---

## ArrayList Migration

### The Change

`ArrayList(T)` is now unmanaged by default (no stored allocator). All mutation methods require explicit allocator parameter.

### Before (0.14.x)

```zig
var list = std.ArrayList(u32).init(allocator);  // Stores allocator
defer list.deinit();

try list.append(42);
try list.appendSlice(&[_]u32{1, 2, 3});
```

### After (0.15.2)

```zig
var list = std.ArrayList(u32).empty;  // No stored allocator
defer list.deinit(allocator);  // Pass allocator

try list.append(allocator, 42);
try list.appendSlice(allocator, &[_]u32{1, 2, 3});
```

### Migration Steps

1. `.init(allocator)` → `.empty` (or `.{}`)
2. `.deinit()` → `.deinit(allocator)`
3. Add `allocator` as first parameter to: `append`, `appendSlice`, `insert`, `resize`, etc.

**Common errors:**

```
error: expected 2 arguments, found 1
defer list.deinit();
```
→ Pass allocator: `defer list.deinit(allocator);`

```
error: expected 3 arguments, found 2
try list.append(42);
```
→ Pass allocator: `try list.append(allocator, 42);`

### Memory Savings

Unmanaged containers save 8 bytes per instance (no allocator pointer):

```zig
const Config = struct {
    items: ArrayList(u32),     // 0 bytes overhead
    names: ArrayList([]u8),    // 0 bytes overhead
    allocator: Allocator,      // 8 bytes (shared)
    // Total: 8 bytes vs 24 bytes with managed
};
```

---

## HashMap Migration

Same pattern as ArrayList - pass allocator to mutation methods:

### Before (0.14.x)

```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();
try map.put(1, "one");
```

### After (0.15.2)

```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit(allocator);
try map.put(allocator, 1, "one");
```

---

## Common Pitfalls

### 1. Forgetting flush() - Silent Data Loss

**Symptom:** File is incomplete or empty, no error message

**Fix:**
```zig
try writer.interface.flush();  // Before close!
file.close();
```

### 2. Wrong Import Path for stdout/stderr

**Symptom:**
```
error: no field named 'getStdOut' in struct 'std.io'
```

**Fix:**
```zig
// OLD: std.io.getStdOut()
// NEW: std.fs.File.stdout()
```

### 3. Missing Allocator in deinit()

**Symptom:**
```
error: expected 2 arguments, found 1
```

**Fix:**
```zig
defer list.deinit(allocator);  // Pass allocator
```

### 4. Missing .interface Accessor

**Symptom:**
```
error: no field named 'print' in struct 'fs.File.Writer'
```

**Fix:**
```zig
writer.interface.print()  // Not writer.print()
```

### 5. Buffer Lifetime Issues

**Problem:** Buffer destroyed before use

```zig
// ❌ WRONG - Stack allocation
fn getWriter(file: std.fs.File) Writer {
    var buf: [256]u8 = undefined;  // Destroyed on return!
    return file.writer(&buf);
}

// ✅ CORRECT - Buffer outlives writer
const FileWriter = struct {
    buffer: [4096]u8 = undefined,
    writer: std.fs.File.Writer,

    fn init(file: std.fs.File) FileWriter {
        var self: FileWriter = undefined;
        self.writer = file.writer(&self.buffer);
        return self;
    }
};
```

---

## Migration Checklist

### Pre-Migration (15 min)
- [ ] Backup codebase (git commit or branch)
- [ ] Update Zig to 0.15.2
- [ ] Review this guide

### Phase 1: Build System (15-30 min)
- [ ] Update `build.zig` with `.root_module` wrappers
- [ ] Test: `zig build` compiles
- [ ] Commit: "build: migrate to 0.15.2 module API"

### Phase 2: I/O (30-60 min)
- [ ] Update stdout/stderr imports
- [ ] Add buffers to all `writer()` calls
- [ ] Add `.interface` accessor to method calls
- [ ] Add `flush()` before close/exit
- [ ] Test: Output correctness
- [ ] Commit: "refactor: migrate I/O to 0.15.2"

### Phase 3: Containers (30-60 min)
- [ ] Change `.init(allocator)` → `.empty`
- [ ] Add allocator to `deinit()` calls
- [ ] Add allocator to mutation methods
- [ ] Test: Functionality works
- [ ] Test: No memory leaks
- [ ] Commit: "refactor: migrate containers to 0.15.2"

### Final Validation (30-60 min)
- [ ] Run full test suite
- [ ] Check for warnings
- [ ] Test release builds
- [ ] Update CI configuration
- [ ] Final commit: "chore: complete Zig 0.15.2 migration"

**Total time:** 2-4 hours for typical projects

---

## Quick Find-Replace Patterns

**Build system:**
```
Find:    .target = target,\n    .optimize = optimize,
Replace: .root_module = b.createModule(.{\n        .target = target,\n        .optimize = optimize,
(Then manually add closing }),)
```

**I/O:**
```
Find:    std.io.getStdOut()
Replace: std.fs.File.stdout()

Find:    std.io.getStdErr()
Replace: std.fs.File.stderr()
```

**Containers:**
```
Find:    ArrayList(.*).init\(allocator\)
Replace: ArrayList$1.empty
(Then manually add allocator parameters)
```

---

## Example Migration

**Complete file migration example:**

Before (0.14.x):
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try list.appendSlice("Hello, World!");
    try stdout.print("{s}\n", .{list.items});
}
```

After (0.15.2):
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.fs.File.stdout();
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(&buf);

    var list = std.ArrayList(u8).empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, "Hello, World!");
    try writer.interface.print("{s}\n", .{list.items});
    try writer.interface.flush();
}
```

---

## Resources

**For detailed explanations:**
- Chapter 5: Collections & Containers (managed vs unmanaged)
- Chapter 6: I/O, Streams & Formatting (buffering patterns)
- Chapter 9: Build System (module system)

**For working code examples:**
- `examples/` directory contains 100 validated 0.15.2 examples
- All examples compile successfully on Zig 0.15.2

**If migration issues persist:**
- Zig Discord: Real-time help
- Ziggit forum: Migration questions
- GitHub issues: Report unclear error messages

---

**Appendix B Complete**

For quick-reference patterns working with 0.14.1 code, see Appendix A.
