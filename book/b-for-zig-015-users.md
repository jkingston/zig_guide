# Appendix B: For Zig 0.15 Users

> **If you're on Zig 0.15.x, this appendix shows the key differences from the book's examples and how to upgrade to 0.16.0-dev.**

---

## Overview

This appendix provides a quick-reference guide for migrating code from Zig 0.15.x to 0.16.0. Zig 0.16 introduces three major changes: `process.Init` ("juicy main"), `std.Io` (async I/O), and `std.net` removal.

**Estimated migration time:** 4-8 hours for typical projects (< 10,000 lines)

**Note:** Zig 0.16.0 has not yet been released. This appendix is based on 0.16.0-dev APIs and may change before final release.

### Breaking Changes at a Glance

| Change | Impact | Quick Fix |
|--------|--------|-----------|
| **process.Init**: New `main()` signatures | Every entry point | Add `init: std.process.Init` parameter |
| **std.Io**: Async I/O system | All async/concurrent code | Use `io.async()` / `io.concurrent()` |
| **std.net removed**: Moved to `std.Io.net` | All networking code | Replace with `std.Io.net` + Io parameter |
| **Package storage**: `zig-pkg/` directory | Build configuration | Add `zig-pkg/` to `.gitignore` |
| **Codeberg migration**: Repository moved | All ziglang links | Update to `codeberg.org/ziglang/zig` |

---

## process.Init ("Juicy Main")

### The Change

`pub fn main()` now supports three signatures. The new "full" signature provides a pre-initialized allocator, arena, and I/O interface, eliminating boilerplate.

### Before (0.15.x)

```zig
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.fs.File.stdout();
    var buf: [4096]u8 = undefined;
    var writer = stdout.writer(&buf);

    try writer.interface.print("Hello, {s}!\n", .{"world"});
    try writer.interface.flush();

    _ = allocator;
}
```

### After (0.16 — full init)

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // GPA, arena, and Io are all provided
    try std.Io.File.stdout().writeStreamingAll(init.io, "Hello, world!\n");
}
```

### After (0.16 — minimal init)

```zig
const std = @import("std");

pub fn main(init: std.process.Init.Minimal) !void {
    // Only args and environ provided; set up allocator/io yourself
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();

    var args = try init.args.iterateAllocator(gpa);
    defer args.deinit();
    _ = args.skip(); // skip program name
}
```

### After (0.16 — classic, still works)

```zig
const std = @import("std");

pub fn main() !void {
    // Classic signature still works for simple programs
    std.debug.print("Hello!\n", .{});
}
```

### process.Init Fields

```zig
pub const Init = struct {
    minimal: Minimal,                    // args and environ
    arena: *std.heap.ArenaAllocator,     // permanent process storage
    gpa: std.mem.Allocator,              // general-purpose temporary allocator
    io: std.Io,                          // default I/O implementation
    environ_map: *Environ.Map,           // pre-initialized env vars
};

pub const Minimal = struct {
    args: Args,        // command-line arguments
    environ: Environ,  // environment variables (lazy)
};
```

---

## std.Io (Async I/O System)

### The Change

Zig 0.16 introduces `std.Io` as the unified interface for async I/O. All I/O operations now require an `Io` instance (analogous to how allocations require an `Allocator`).

### Key Types

| Type | Purpose |
|------|---------|
| `std.Io` | The I/O interface (obtained from a backend) |
| `io.async(fn, args)` | Spawn async task, returns `Future` |
| `io.concurrent(fn, args)` | Spawn with true parallelism, returns `!Future` |
| `Future.await(io)` | Block until result available |
| `Future.cancel(io)` | Cancel the task |
| `Io.Queue(T)` | Thread-safe producer/consumer queue |
| `Io.Group` | Manage batches of async tasks |

### Backends

| Backend | Description |
|---------|-------------|
| `std.Io.Threaded` | Thread-pool based, works everywhere |
| `std.Io.Evented` | io_uring (Linux), GCD (macOS) — experimental |
| `std.Io.Blocking` | Single-threaded fallback |

### Basic Async Pattern

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var future = init.io.async(doWork, .{init.io});
    defer future.cancel(init.io) catch {};
    try future.await(init.io);
}

fn doWork(io: std.Io) !void {
    _ = io;
    // ... actual work
}
```

### Concurrent I/O (Producer/Consumer)

```zig
const std = @import("std");
const Io = std.Io;

fn runPipeline(io: Io) !void {
    var queue: Io.Queue([]const u8) = .init(&.{});

    // concurrent() guarantees true parallelism (or fails)
    var producer = try io.concurrent(produce, .{ io, &queue });
    defer producer.cancel(io) catch {};

    var consumer = try io.concurrent(consume, .{ io, &queue });
    defer consumer.cancel(io) catch {};

    try producer.await(io);
    try consumer.await(io);
}
```

### async vs concurrent

- **`io.async()`**: "I don't care if this runs in parallel" — may run on same thread
- **`io.concurrent()`**: "This MUST run in parallel or fail" — returns `!Future` (can error with `ConcurrencyUnavailable`)

Use `concurrent` for producer/consumer patterns where same-thread execution would deadlock.

---

## std.net Removed

### The Change

`std.net` is deleted. Networking moved to `std.Io.net` and requires an `Io` instance.

### Before (0.15.x)

```zig
const addr = try std.net.Address.resolveIp("127.0.0.1", 8080);
```

### After (0.16)

```zig
// Networking now requires an Io instance
const addr = try std.Io.net.HostName.lookup("127.0.0.1", init.io, &queue, .{});
```

---

## Package Storage Changes

### zig-pkg/ Directory

Fetched packages now store in a `zig-pkg/` directory at the project root (next to `build.zig`) instead of exclusively in `.zig-cache`.

**Action:** Add `zig-pkg/` to your `.gitignore`:

```
zig-pkg/
.zig-cache/
zig-out/
```

### --fork Flag

`zig build --fork=[path]` enables temporary local overrides for dependencies across the entire dependency tree without modifying `build.zig.zon`.

---

## Format Specifier Changes (Already in 0.15.x)

These changes landed in 0.15.x and are documented here for completeness:

| New Specifier | Purpose | Replaces |
|---------------|---------|----------|
| `{f}` | Call type's `format` method | `{}` (was implicit) |
| `{t}` | `@tagName()` / `@errorName()` | Manual calls |
| `{b64}` | Base64 encoding | Manual encoding |
| `{B}` | Size formatting (decimal, e.g. "1.5kB") | `fmtIntSizeDec` |
| `{Bi}` | Size formatting (binary, e.g. "1.5KiB") | `fmtIntSizeBin` |
| `{D}` | Duration formatting | `fmtDuration` |

### Format Method Signature (Already in 0.15.x)

```zig
// OLD (0.14.x — no longer compiles):
pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void

// NEW (0.15.x+):
pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void
```

---

## Migration Checklist

- [ ] Update `pub fn main()` signatures (or keep classic for simple programs)
- [ ] Replace `std.net` usage with `std.Io.net`
- [ ] Add `zig-pkg/` to `.gitignore`
- [ ] Update any `github.com/ziglang/zig` links to `codeberg.org/ziglang/zig`
- [ ] Test with `zig build test` on 0.16.0
- [ ] Update CI to use Zig 0.16.0

---

> **See also:** Appendix A (For Zig 0.14 Users) if you're upgrading from an older version.
