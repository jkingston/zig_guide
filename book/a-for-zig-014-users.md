# Appendix A: For Zig 0.14 Users

> If you're on Zig 0.14.x, this appendix shows the key differences from the book's examples and how to upgrade.

---

## About

This book targets **Zig 0.16.0-dev**. If you're on 0.14.x, you have two options: use this appendix to mentally translate examples as you read, or upgrade directly to 0.16.0-dev. **Recommendation:** upgrade directly to 0.16.0-dev -- the migration is straightforward and lets you run every example unchanged.

**Estimated migration time:** 2-4 hours for typical projects (< 10,000 lines).

---

## Breaking Changes at a Glance

| Area | 0.14.x | 0.16.0-dev (book) | Quick Fix |
|------|--------|-------------------|-----------|
| **Build system** | Fields at top level | `.root_module = b.createModule(.{...})` | Wrap in `createModule` |
| **I/O** | `std.io.getStdOut().writer()` | `std.Io.File.stdout()` with `init.io` + buffer | New writer pattern |
| **Containers** | Managed (allocator stored) | Unmanaged (pass allocator to methods) | Pass allocator explicitly |
| **Entry point** | `pub fn main() !void` | `pub fn main(init: std.process.Init) !void` | Add `init` parameter |
| **std.net** | `std.net` | `std.posix` / updated API | Update imports |

---

## Build System

### Before (0.14.x)

```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

### After (0.16.0-dev)

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
3. Close with `})` -- note the nested closing
4. For imports: replace `exe.root_module.addImport(...)` calls with `.imports` inside `createModule()`

---

## I/O and Writers

### Before (0.14.x)

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});
}
```

### After (0.16.0-dev)

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const stdout = std.Io.File.stdout(init.io);
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(&buf);
    try writer.interface.print("Hello, {s}!\n", .{"world"});
    try writer.interface.flush();
}
```

### Key Differences

1. **Location:** `std.io.getStdOut()` becomes `std.Io.File.stdout(init.io)`
2. **Init parameter:** `stdout()` requires the `init.io` handle from the entry point
3. **Buffer required:** `writer()` takes a buffer parameter
4. **Interface accessor:** Methods accessed via `.interface` field
5. **Flush required:** Must call `flush()` before exit or close

### Buffer Sizing Guide

| Use Case | Buffer Size | Example |
|----------|-------------|---------|
| stdout/stderr | 256-1024 bytes | `var buf: [256]u8 = undefined;` |
| File I/O | 4096 bytes | `var buf: [4096]u8 = undefined;` |
| Error messages | Unbuffered | `writer(&.{})` |

**Critical mistake:** Forgetting `flush()` causes silent data loss!

```zig
// WRONG - Data lost!
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
file.close();  // Buffer not flushed!

// CORRECT
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
try writer.interface.flush();  // Ensure data written
file.close();
```

---

## Containers

### ArrayList

**Before (0.14.x):**
```zig
var list = std.ArrayList(u32).init(allocator);  // Stores allocator
defer list.deinit();

try list.append(42);
try list.appendSlice(&[_]u32{1, 2, 3});
```

**After (0.16.0-dev):**
```zig
var list = std.ArrayList(u32).empty;  // No stored allocator
defer list.deinit(allocator);

try list.append(allocator, 42);
try list.appendSlice(allocator, &[_]u32{1, 2, 3});
```

### HashMap

Same pattern -- pass allocator to mutation methods:

**Before (0.14.x):**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();
try map.put(1, "one");
```

**After (0.16.0-dev):**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit(allocator);
try map.put(allocator, 1, "one");
```

### Migration Steps

1. `.init(allocator)` becomes `.empty` (or `.{}`) for ArrayList
2. `.deinit()` becomes `.deinit(allocator)`
3. Add `allocator` as first parameter to: `append`, `appendSlice`, `insert`, `resize`, `put`, `toOwnedSlice`, etc.

---

## Entry Point

Zig 0.16.0-dev introduces `std.process.Init` as a parameter to `main`. This replaces implicit global access to process resources.

### The Three Signatures

```zig
// Minimal (no error, no init)
pub fn main() void { }

// With errors
pub fn main() !void { }

// Full (0.16.0-dev) - needed for I/O, env, args
pub fn main(init: std.process.Init) !void { }
```

The `init` parameter provides access to `init.io`, `init.args`, and other process resources. Any code that uses stdout/stderr needs this parameter.

---

## Translation Guide

When reading book examples on a 0.14.x codebase, apply these transformations:

### Build System

| Book (0.16.0-dev) | 0.14.x |
|--------------------|--------|
| `.root_module = b.createModule(.{...})` | Remove wrapper, fields at top level |
| `target`, `optimize` inside `createModule` | `target`, `optimize` at top level |

### I/O

| Book (0.16.0-dev) | 0.14.x |
|--------------------|--------|
| `std.Io.File.stdout(init.io)` | `std.io.getStdOut()` |
| `std.Io.File.stderr(init.io)` | `std.io.getStdErr()` |
| `var buf: [N]u8 = undefined;` | Not needed |
| `file.writer(&buf)` | `file.writer()` |
| `writer.interface.print()` | `writer.print()` |
| `writer.interface.flush()` | Not needed (auto-flush) |
| `pub fn main(init: std.process.Init) !void` | `pub fn main() !void` |

### Containers

| Book (0.16.0-dev) | 0.14.x |
|--------------------|--------|
| `.empty` or `.{}` | `.init(allocator)` |
| `.deinit(allocator)` | `.deinit()` |
| `.append(allocator, item)` | `.append(item)` |
| `.appendSlice(allocator, items)` | `.appendSlice(items)` |
| `.put(allocator, k, v)` | `.put(k, v)` |
| `.toOwnedSlice(allocator)` | `.toOwnedSlice()` |

---

## Migration Checklist

### Pre-Migration (15 min)

- [ ] Backup codebase (git commit or branch)
- [ ] Install Zig 0.16.0-dev
- [ ] Review this appendix

### Phase 1: Build System (15-30 min)

- [ ] Update `build.zig` with `.root_module` wrappers
- [ ] Test: `zig build` compiles
- [ ] Commit: "build: migrate to 0.16 module API"

### Phase 2: Entry Points (15 min)

- [ ] Add `init: std.process.Init` parameter to `main()`
- [ ] Thread `init.io` to I/O call sites
- [ ] Commit: "refactor: adopt process.Init entry point"

### Phase 3: I/O (30-60 min)

- [ ] Replace `std.io.getStdOut()` with `std.Io.File.stdout(init.io)`
- [ ] Add buffers to all `writer()` calls
- [ ] Add `.interface` accessor to method calls
- [ ] Add `flush()` before close/exit
- [ ] Test output correctness
- [ ] Commit: "refactor: migrate I/O to 0.16"

### Phase 4: Containers (30-60 min)

- [ ] Change `.init(allocator)` to `.empty`
- [ ] Add allocator to `deinit()` calls
- [ ] Add allocator to mutation methods
- [ ] Test functionality and check for memory leaks
- [ ] Commit: "refactor: migrate containers to unmanaged"

### Final Validation (30-60 min)

- [ ] Run full test suite
- [ ] Check for warnings
- [ ] Test release builds
- [ ] Update CI configuration

**Total time:** 2-4 hours for typical projects.

---

## Common Errors

### `error: missing struct field: root_module`

You're using the old `addExecutable` format. Wrap fields in `b.createModule(.{...})` -- see Build System section above.

### `error: no field named 'getStdOut' in struct 'std.io'`

The I/O path changed. Use `std.Io.File.stdout(init.io)` instead.

### `error: expected 2 arguments, found 1` on `deinit()`

Containers are now unmanaged. Pass the allocator: `list.deinit(allocator)`.

### `error: expected 3 arguments, found 2` on `append()`

Same cause. Pass the allocator as first argument: `list.append(allocator, 42)`.

### `error: no field named 'print' in struct Writer`

Writer methods are behind `.interface`: use `writer.interface.print()`.

### Empty or incomplete file output

You forgot to `flush()`. Always call `writer.interface.flush()` before closing a file or exiting.

---

**Appendix A Complete**
