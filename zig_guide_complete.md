# Zig Developer Guide

A comprehensive guide to Zig development focused on idioms and best practices for **Zig 0.14.x and 0.15.x**.

## About This Guide

This guide teaches practical Zig idioms and best practices for developers using Zig 0.14.0, 0.14.1, 0.15.1, or 0.15.2. Most patterns work identically across all supported versions. When they differ, version markers clearly indicate which code applies to which version.

**Who This Guide Is For:**
- Systems programmers learning Zig from C, C++, or Rust backgrounds
- Developers building Zig applications on 0.14.x or 0.15.x
- Teams evaluating Zig for production use
- Contributors to Zig open-source projects

**This guide assumes:**
- Prior systems programming experience
- Familiarity with basic programming concepts
- Understanding of memory management principles

## Version Markers

Throughout this guide, you'll see version markers indicating compatibility:

- **🕐 0.14.x** — Code specific to Zig 0.14.0 and 0.14.1
- **✅ 0.15+** — Code specific to Zig 0.15.1 and later
- **No marker** — Code that works in all supported versions

## What You'll Learn

This guide covers 15 comprehensive chapters spanning:

1. **Foundations**: Language idioms, memory management, and core patterns
2. **Data & I/O**: Collections, containers, streams, and formatting
3. **Error Handling**: Error sets, cleanup strategies, and resource management
4. **Concurrency**: Async patterns, threading, and performance optimization
5. **Build System**: build.zig, packages, dependencies, and cross-compilation
6. **Interoperability**: Working with C, C++, WASI, and WebAssembly
7. **Quality**: Testing, benchmarking, profiling, and diagnostics
8. **Migration**: Practical guide for upgrading from 0.14.x to 0.15.x

## Code Examples

All code examples are runnable and tested. You can find the complete source code examples in the [GitHub repository](https://github.com/jkingston/zig_guide).

---

Ready to get started? Head to **Chapter 1: Quick Start** or choose a specific chapter from the navigation menu.
# Quick Start

Get started with Zig in under 10 minutes. This chapter walks through installation, your first project, and essential development workflows.

---

## Installation

Download Zig from the [official website](https://ziglang.org/download/):

```bash
# Verify installation
zig version
# Should show: 0.15.2 (or your installed version)
```

**Install ZLS (Zig Language Server)** for IDE support:
- Download from [ZLS releases](https://github.com/zigtools/zls/releases)
- ⚠️ Use matching tagged releases of Zig and ZLS (or both nightly). See [ZLS compatibility guide](https://github.com/zigtools/zls#compatibility)
- See **Appendix A: Development Setup** for detailed editor configuration

---

## Your First Project

Create a simple word counter that demonstrates core Zig concepts:

```bash
mkdir wordcount && cd wordcount
zig init
```

Replace `src/main.zig` with:

```zig
const std = @import("std");

pub fn main() !void {
    // Memory allocation with leak detection
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: wordcount <file>\n", .{});
        return;
    }

    // Read file with automatic cleanup
    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Count words
    var count: usize = 0;
    var iter = std.mem.splitScalar(u8, content, ' ');
    while (iter.next()) |_| count += 1;

    std.debug.print("Words: {}\n", .{count});
}
```

**What this demonstrates:**
- **Memory allocation** (Chapter 2) - `GeneralPurposeAllocator` with leak detection
- **Error handling** (Chapter 5) - `!void` return type, `try` keyword
- **Resource cleanup** (Chapter 5) - `defer` ensures cleanup on all exit paths
- **I/O operations** (Chapter 4) - File reading with proper error handling
- **String processing** (Chapter 2) - Splitting and iteration

**Build and run:**

```bash
zig build-exe src/main.zig
./wordcount README.md
# Output: Words: 42
```

---

## Development Workflow

Essential commands for day-to-day development:

```bash
# Initialize project structure
zig init

# Build project
zig build

# Run tests
zig build test

# Format code (automatic style enforcement)
zig fmt .

# Build and run
zig build run

# Cross-compile for different targets
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast
```

**Project structure created by `zig init`:**

```
myproject/
├── build.zig          # Build configuration (see Chapter 7)
├── build.zig.zon      # Package manifest (see Chapter 8)
├── src/
│   ├── main.zig       # Executable entry point
│   └── root.zig       # Library exports
└── .gitignore         # Excludes zig-cache/, zig-out/
```

---

## What Makes Zig Unique

Zig's `comptime` keyword enables computation at compile time:[^1]

```zig
const std = @import("std");

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "comptime execution" {
    const x = comptime fibonacci(10);
    try std.testing.expect(x == 55);
}
```

The `comptime` annotation forces evaluation during compilation. The result is a compile-time constant with zero runtime cost. Later chapters explore comptime metaprogramming in depth.

---

## Next Steps

**Choose your learning path:**

- **New to Zig idioms?** → Chapter 2 (Language Idioms & Core Patterns)
- **Coming from C/Rust?** → Chapter 2, then Chapter 3 (Memory & Allocators)
- **Want complete project tutorial?** → Appendix B (zighttp architectural analysis)
- **Need troubleshooting?** → Appendix D (Troubleshooting Guide)

**Key chapters for common tasks:**
- **Memory management** → Chapter 3 (Memory & Allocators)
- **Error handling** → Chapter 6 (Error Handling & Resource Cleanup)
- **File I/O** → Chapter 5 (I/O, Streams & Formatting)
- **Building projects** → Chapter 8 (Build System)
- **Testing** → Chapter 12 (Testing, Benchmarking & Profiling)
- **Project setup** → Chapter 10 (Project Layout, Cross-Compilation & CI)

---

## Summary

You've installed Zig, built your first working program, and seen key Zig concepts in action:
- Explicit memory allocation with leak detection
- Error handling with `try` and `!void`
- Resource cleanup with `defer`
- Compile-time execution with `comptime`

This Quick Start has given you a working foundation. Proceed to **Chapter 2: Language Idioms & Core Patterns** to explore Zig's unique patterns and mental models in depth.

---

## References

[^1]: [Zig.guide - Comptime](https://zig.guide/language-basics/comptime) — Compile-time execution
# Language Idioms & Core Patterns

> **TL;DR for Zig idioms:**
> - **Naming:** `snake_case` (vars/functions), `PascalCase` (types), `SCREAMING_SNAKE_CASE` (constants)
> - **Cleanup:** `defer cleanup()` (runs at scope exit in LIFO order), `errdefer` (only on error paths)
> - **Errors:** `!T` for error unions, `try` propagates, `catch` handles, see [Ch5 for details](#/05_error_handling)
> - **Optionals:** `?T` for nullable values, `.?` unwraps or panics, `orelse` provides default
> - **comptime:** Compile-time execution for generics and zero-cost abstractions
> - **Jump to:** [Naming §1.2](#naming-conventions) | [defer §1.3](#defer-and-errdefer) | [comptime §1.5](#comptime-execution)

This chapter establishes the idiomatic baseline for Zig development. These patterns form the foundation for all subsequent chapters, covering naming conventions, resource cleanup, error handling fundamentals, compile-time execution, and module organization. Most patterns work identically across Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2.

---

## Overview

Zig's language design prioritizes explicitness, simplicity, and maintainability. Unlike languages with implicit behaviors (garbage collection, hidden allocations, exceptions), Zig makes costs and control flow visible in code. This chapter teaches the patterns that define idiomatic Zig:

- **Naming conventions** communicate intent through consistent case rules
- **defer and errdefer** provide deterministic resource cleanup
- **Error unions and optionals** handle failure and absence explicitly
- **comptime** enables zero-cost abstractions through compile-time execution
- **Module organization** structures code for clarity and maintainability

These idioms reflect community consensus drawn from the official style guide, production codebases (TigerBeetle, Ghostty, Bun), and ecosystem libraries.[^1]

---

## Core Concepts

### Naming Conventions

Zig uses three case styles with specific semantic meanings:[^2]

**PascalCase** — Types (structs, enums, unions, opaques)
```zig
const Point = struct { x: i32, y: i32 };
const Color = enum { red, green, blue };
```

**camelCase** — Functions returning values
```zig
fn calculateSum(a: i32, b: i32) i32 {
    return a + b;
}
```

**Exception:** Functions returning types use PascalCase:
```zig
fn ArrayList(comptime T: type) type {
    return struct { /* ... */ };
}
```

**snake_case** — Variables, parameters, constants, and zero-field structs (namespaces)
```zig
const max_connections = 100;
var file_path: []const u8 = "/tmp/data.bin";

const math = struct {
    pub fn add(a: i32, b: i32) i32 { return a + b; }
};
```

**File names** typically use `snake_case`, except when a file directly exposes a single type (e.g., `ArrayList.zig`).[^3]

#### Real-World Patterns

TigerBeetle's style guide adds precision through systematic naming:[^4]

**Units and qualifiers** in descending order of significance:
```zig
const latency_ms_max: u64 = 1000;  // Not max_latency_ms
const buffer_size_bytes: usize = 4096;
const timeout_ns_min: u64 = 100_000;
```

**Acronym capitalization** preserves readability:
```zig
const VSRState = enum { normal, view_change, recovering };  // Not VsrState
```

**Domain-meaningful names** convey ownership and lifecycle:
```zig
fn process(gpa: Allocator, arena: Allocator) !void {
    // Name signals: gpa requires explicit deinit, arena gets bulk-freed
}
```

---

### defer and errdefer

Zig's `defer` executes code when leaving the current scope (via return, break, or block end). `errdefer` executes only when leaving via error return.[^5] See Ch5 for comprehensive coverage of resource cleanup patterns.

**Execution order is LIFO:**

```zig
const std = @import("std");

fn demonstrateDeferOrder() void {
    defer std.debug.print("3. Third (executed first)\n", .{});
    defer std.debug.print("2. Second\n", .{});
    defer std.debug.print("1. First (executed last)\n", .{});
    std.debug.print("0. Function body\n", .{});
}
// Output:
// 0. Function body
// 1. First (executed last)
// 2. Second
// 3. Third (executed first)
```

**Resource cleanup** pairs acquisition with deferred release:

```zig
const std = @import("std");

fn processFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Process content here
}
```

**errdefer** handles partial failures:

```zig
const std = @import("std");

fn createResources(allocator: std.mem.Allocator) !struct { a: []u8, b: []u8 } {
    const a = try allocator.alloc(u8, 100);
    errdefer allocator.free(a);  // Only frees if subsequent operations fail

    const b = try allocator.alloc(u8, 200);
    errdefer allocator.free(b);

    return .{ .a = a, .b = b };
}
```

If the second allocation fails, `errdefer` ensures the first allocation is cleaned up before returning the error.

---

### Error Unions vs Optionals

Zig distinguishes between failure (`!T`) and absence (`?T`):[^6]

**Error unions (`!T`)** represent operations that can fail:
```zig
fn parseNumber(text: []const u8) !u32 {
    if (text.len == 0) return error.Empty;
    // Parse logic
}
```

**Optionals (`?T`)** represent values that may not exist:
```zig
fn findFirst(items: []i32, target: i32) ?usize {
    for (items, 0..) |item, index| {
        if (item == target) return index;
    }
    return null;
}
```

**Decision criteria:**
- Use `!T` when absence indicates a problem requiring error handling
- Use `?T` when absence is a valid, expected state
- Use `!?T` when an operation can fail *or* return nothing (e.g., optional database query with possible connection error)

**Handling patterns:**
```zig
// Error union with try (propagates error)
const value = try parseNumber("42");

// Error union with catch (handles error)
const value = parseNumber("42") catch 0;

// Optional with orelse (provides default)
const index = findFirst(items, 10) orelse return;

// Optional with if (conditional execution)
if (findFirst(items, 10)) |index| {
    // Use index
}
```

---

### comptime Fundamentals

Zig's `comptime` keyword forces evaluation at compile time, enabling zero-cost generics and type manipulation.[^7]

**Generic functions** use compile-time type parameters:

```zig
const std = @import("std");

fn maximum(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "generic maximum" {
    try std.testing.expect(maximum(i32, 10, 20) == 20);
    try std.testing.expect(maximum(f64, 3.14, 2.71) == 3.14);
}
```

The function is instantiated separately for each type at compile time. No runtime overhead.

**Compile-time validation** catches errors before execution:

```zig
fn Buffer(comptime size: usize) type {
    if (size == 0) {
        @compileError("Buffer size must be greater than zero");
    }
    return struct {
        data: [size]u8,
    };
}

const ValidBuffer = Buffer(128);   // ✅ Compiles
// const Invalid = Buffer(0);       // ❌ Compile error
```

**Type introspection** with `@typeInfo`:

```zig
const std = @import("std");

fn fieldCount(comptime T: type) comptime_int {
    const info = @typeInfo(T);
    return switch (info) {
        .Struct => |s| s.fields.len,
        else => 0,
    };
}

const Point = struct { x: i32, y: i32 };
comptime {
    std.debug.assert(fieldCount(Point) == 2);
}
```

---

### Module Organization

Zig files are modules. The `@import` builtin loads other modules and the standard library.[^8]

**Basic imports:**
```zig
const std = @import("std");           // Standard library
const utils = @import("utils.zig");   // Local module
```

**Visibility control** with `pub`:

```zig
// math.zig
pub fn add(a: i32, b: i32) i32 {  // Exported
    return addImpl(a, b);
}

fn addImpl(a: i32, b: i32) i32 {  // Private to this module
    return a + b;
}
```

**File organization patterns:**[^9]

**Flat structure** (small projects):
```
src/
├── main.zig
├── parser.zig
└── renderer.zig
```

**Hierarchical** (medium projects):
```
src/
├── main.zig
├── core/
│   ├── types.zig
│   └── errors.zig
└── utils/
    ├── io.zig
    └── strings.zig
```

**Module-as-directory** (large projects):
```
src/
├── main.zig
└── parser/
    ├── parser.zig      // Re-exports public API
    ├── lexer.zig
    └── ast.zig
```

Example `parser/parser.zig`:
```zig
pub const Lexer = @import("lexer.zig").Lexer;
pub const AST = @import("ast.zig").AST;

pub fn parse(source: []const u8) !AST {
    // Implementation
}
```

Clients import: `const parser = @import("parser/parser.zig");`

---

## Code Examples

### Example 1: Combining defer with Error Handling

```zig
const std = @import("std");

fn copyFile(
    allocator: std.mem.Allocator,
    src_path: []const u8,
    dst_path: []const u8
) !void {
    const src = try std.fs.cwd().openFile(src_path, .{});
    defer src.close();

    const dst = try std.fs.cwd().createFile(dst_path, .{});
    defer dst.close();

    const buffer = try allocator.alloc(u8, 4096);
    defer allocator.free(buffer);

    while (true) {
        const bytes_read = try src.read(buffer);
        if (bytes_read == 0) break;
        try dst.writeAll(buffer[0..bytes_read]);
    }
}
```

Each resource is cleaned up in reverse order of acquisition, even if a later operation fails.

### Example 2: Error Union with Optional

```zig
const std = @import("std");

fn findUser(db: *Database, id: u32) !?User {
    const conn = try db.connect();  // Can fail
    defer conn.close();

    return conn.query("SELECT * FROM users WHERE id = ?", .{id}) catch |err| {
        if (err == error.NotFound) return null;  // Absence is valid
        return err;  // Other errors propagate
    };
}
```

This pattern distinguishes connection failures (errors) from missing users (null).

### Example 3: Generic Data Structure

```zig
const std = @import("std");

fn Stack(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .items = std.ArrayList(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
        }

        pub fn push(self: *Self, item: T) !void {
            try self.items.append(item);
        }

        pub fn pop(self: *Self) ?T {
            return self.items.popOrNull();
        }
    };
}

test "generic stack" {
    const allocator = std.testing.allocator;
    var stack = Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(10);
    try stack.push(20);

    try std.testing.expect(stack.pop().? == 20);
    try std.testing.expect(stack.pop().? == 10);
    try std.testing.expect(stack.pop() == null);
}
```

### Example 4: Module with Re-exports

```zig
// shapes.zig
pub const Point = struct {
    x: i32,
    y: i32,

    pub fn add(self: Point, other: Point) Point {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

pub const Rectangle = struct {
    top_left: Point,
    width: u32,
    height: u32,
};

pub fn distance(a: Point, b: Point) f64 {
    const dx = @as(f64, @floatFromInt(a.x - b.x));
    const dy = @as(f64, @floatFromInt(a.y - b.y));
    return @sqrt(dx * dx + dy * dy);
}

// main.zig
const shapes = @import("shapes.zig");

pub fn main() void {
    const p1 = shapes.Point{ .x = 0, .y = 0 };
    const p2 = shapes.Point{ .x = 3, .y = 4 };
    const dist = shapes.distance(p1, p2);
}
```

---

## Common Pitfalls

### Pitfall 1: defer in Loops

**Problem:** defer in a loop executes once per iteration, accumulating deferred statements:

```zig
// ❌ WRONG: Leaks file handles until function returns
for (file_paths) |path| {
    const file = try openFile(path);
    defer file.close();  // Defers until function ends, not loop end
    processFile(file);
}
```

**Solution:** Use a nested block:

```zig
// ✅ CORRECT: Closes each file immediately
for (file_paths) |path| {
    {
        const file = try openFile(path);
        defer file.close();  // Executes at block end
        processFile(file);
    }
}
```

### Pitfall 2: Using Optionals for Error States

**Problem:** Optionals cannot explain *why* something is missing:

```zig
// ❌ WRONG: Cannot distinguish between "not found" and "permission denied"
fn readConfig(path: []const u8) ?Config {
    const file = std.fs.cwd().openFile(path, .{}) catch return null;
    // Caller cannot tell why this failed
}
```

**Solution:** Use error unions:

```zig
// ✅ CORRECT: Preserves error information
fn readConfig(path: []const u8) !Config {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    // Parse and return config
}
```

### Pitfall 3: comptime Type Confusion

**Problem:** Mixing compile-time and runtime values without proper annotations:

```zig
// ❌ WRONG: T is not known at comptime in this context
fn createArray(T: type, size: usize) ![]T {
    return try allocator.alloc(T, size);  // T is runtime, won't compile
}
```

**Solution:** Mark type parameters as comptime:

```zig
// ✅ CORRECT: Explicit comptime parameter
fn createArray(comptime T: type, allocator: std.mem.Allocator, size: usize) ![]T {
    return try allocator.alloc(T, size);
}
```

### Pitfall 4: Version-Specific Breaking Changes

**🕐 0.14.x — usingnamespace (deprecated):**
```zig
const utils = @import("utils.zig");
pub usingnamespace utils;  // Implicitly re-exports everything
```

**✅ 0.15.1+ — Explicit re-exports:**
```zig
const utils = @import("utils.zig");
pub const helper = utils.helper;  // Explicit control over API surface
```

The `usingnamespace` keyword was removed in 0.15 to improve clarity around public API boundaries.[^10]

---

## In Practice

### TigerBeetle: Safety-First Patterns

TigerBeetle mandates minimum 2 assertions per function and comprehensive error handling:[^11]

```zig
// src/vsr.zig
fn prepare(self: *Self, op: Operation) !void {
    assert(self.status == .normal);  // Precondition
    assert(op.isValid());            // Input validation

    // Implementation

    assert(self.log.len > 0);        // Postcondition
}
```

View source: [vsr.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig)

### Ghostty: Conditional Compilation

Ghostty uses comptime to select platform-specific entry points:[^12]

```zig
// src/main.zig
pub fn main() !void {
    if (builtin.os.tag == .macos) {
        return @import("apprt").run();  // Swift/AppKit integration
    } else {
        return @import("cli").run();     // Standard CLI
    }
}
```

View source: [main.zig](https://github.com/ghostty-org/ghostty/blob/main/src/main.zig)

### Bun: Advanced comptime

Bun uses comptime string maps for zero-cost lookups:[^13]

```zig
const ComptimeStringMapWithKeyType = std.ComptimeStringMapWithKeyType;

const http_methods = ComptimeStringMapWithKeyType(Method, .{
    .{ "GET", .GET },
    .{ "POST", .POST },
    .{ "PUT", .PUT },
    // Lookup compiled into perfect hash or switch
});
```

View source: [comptime_string_map.zig](https://github.com/oven-sh/bun/blob/main/src/bun.js/bindings/comptime_string_map.zig)

---

## Summary

This chapter established the idiomatic baseline for Zig development:

**Naming conventions** use three case styles with semantic meaning: PascalCase for types, camelCase for functions, snake_case for variables. Production codebases extend these rules with domain-specific qualifiers and unit suffixes.

**defer and errdefer** provide deterministic cleanup in LIFO order. Pair resource acquisition with deferred cleanup immediately. Use errdefer for partial-failure rollback. Avoid defer in loops without nested blocks.

**Error unions (`!T`)** represent operations that can fail. **Optionals (`?T`)** represent values that may not exist. Choose based on whether absence indicates a problem (error union) or a valid state (optional). Combine as `!?T` when both failure and absence are possible.

**comptime** enables zero-cost abstractions through compile-time execution. Use it for generic functions, compile-time validation, and type introspection. All type parameters must be marked `comptime`.

**Module organization** uses `@import` for code reuse and `pub` for visibility control. Structure projects flat (small), hierarchical (medium), or module-as-directory (large). Explicitly re-export public APIs rather than using `usingnamespace` (removed in 0.15).

These patterns remain stable across Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2, with the notable exception of `usingnamespace` removal. Later chapters build on these foundations for memory management, I/O, concurrency, and build systems.

---

## References

[^1]: [Zig Programming Language](https://ziglang.org/)
[^2]: [Zig Language Reference 0.15.2 - Style Guide](https://ziglang.org/documentation/0.15.2/#Style-Guide)
[^3]: [Zig Language Reference 0.15.2 - Root Source File](https://ziglang.org/documentation/0.15.2/#Root-Source-File)
[^4]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^5]: [Zig Language Reference 0.15.2 - defer](https://ziglang.org/documentation/0.15.2/#defer)
[^6]: [Zig Language Reference 0.15.2 - Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)
[^7]: [Zig Language Reference 0.15.2 - comptime](https://ziglang.org/documentation/0.15.2/#comptime)
[^8]: [Zig Language Reference 0.15.2 - import](https://ziglang.org/documentation/0.15.2/#import)
[^9]: [How to organize large projects in Zig](https://stackoverflow.com/questions/78766103/how-to-organize-large-projects-in-zig-language)
[^10]: [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
[^11]: [TigerBeetle vsr.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig)
[^12]: [Ghostty main.zig](https://github.com/ghostty-org/ghostty/blob/main/src/main.zig)
[^13]: [Bun comptime_string_map.zig](https://github.com/oven-sh/bun/blob/main/src/bun.js/bindings/comptime_string_map.zig)
# Memory & Allocators

> **TL;DR for C/C++/Rust developers:**
> - **No implicit allocations** - all allocations require explicit allocator parameter
> - **Allocator interface:** `allocator.alloc(T, count)`, `allocator.free(slice)`
> - **Choose allocator:** GPA (dev), c_allocator (prod), Arena (request-scoped), testing.allocator (tests)
> - **Cleanup:** `defer allocator.free(ptr)` immediately after allocation
> - **Error handling:** `errdefer` for multi-step initialization cleanup
> - **See [comparison table](#allocator-types-and-selection) below for full allocator guide**

## Overview

Memory management in Zig is explicit, deterministic, and designed to eliminate an entire class of bugs common in other systems languages. Unlike languages with garbage collection or hidden allocations, Zig requires every memory allocation to specify an allocator explicitly. This philosophy—"no hidden memory allocations"—forces clarity about ownership, lifetime, and resource cleanup throughout the codebase.

This chapter explains the allocator interface, common allocator patterns, ownership semantics, and cleanup idioms that underpin containers, I/O, and concurrency in Zig. Understanding these patterns is essential for writing correct, maintainable systems software.

## Core Concepts

### The Allocator Interface

Zig's `std.mem.Allocator` provides a uniform interface for all memory allocation strategies. This vtable-based design enables compile-time polymorphism—callers can switch allocator implementations without code changes, making it trivial to use an arena for request handling or a debug allocator for leak detection.

The interface defines four primary operations:

- **`alloc(T, count)`** — Allocates a slice of type `[]T` with `count` elements
- **`free(slice)`** — Deallocates a previously allocated slice
- **`create(T)`** — Allocates a single item of type `T`, returning `*T`
- **`destroy(pointer)`** — Deallocates a single item

All allocation methods return error unions (`![]T` or `!*T`), with `error.OutOfMemory` as the primary failure mode. For performance-critical scenarios, `alignedAlloc()` ensures specific alignment requirements, such as cache-line alignment for buffers.[^1]

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // Slice allocation
    const numbers = try allocator.alloc(u32, 5);
    defer allocator.free(numbers);

    // Single item allocation
    const single = try allocator.create(u32);
    defer allocator.destroy(single);
    single.* = 42;

    // Aligned allocation (16-byte boundary)
    const aligned = try allocator.alignedAlloc(u8, 16, 64);
    defer allocator.free(aligned);
}
```

This example demonstrates the core interface with leak detection. The `GeneralPurposeAllocator` reports leaks at `deinit()`, catching forgotten frees during development.

### Allocator Types and Selection

Zig's standard library provides specialized allocators for different use cases:

| Allocator | Characteristics | Best For | Trade-offs | Production Use |
|-----------|-----------------|----------|------------|----------------|
| `std.testing.allocator` | Fails tests on leaks, stack traces | Testing | Safety (dev-only) | Required for tests |
| `GeneralPurposeAllocator` | Thread-safe, detects double-free/use-after-free, never reuses addresses | Development, debugging | Safety > performance | Ghostty, ZLS[^2][^3] |
| `ArenaAllocator` | Bulk deallocation, `free()` is no-op | Request-scoped, parsers, temp data | Holds all until `deinit()` | TigerBeetle config[^2][^3] |
| `FixedBufferAllocator` | Pre-allocated buffer (often stack), no syscalls | Known max size, perf-critical | Fixed capacity | Zig test runner[^4] |
| `c_allocator` | Wraps malloc/free, minimal overhead | Release builds, C interop | No safety features | Production (after testing) |
| `page_allocator` | Direct OS page mapping (4KB min) | Large buffers, isolation | High overhead for small allocs | Security-critical |

### Allocator Propagation

Allocators flow through Zig codebases as explicit parameters. The standard convention places the allocator as the first parameter, ordered from most general to most specific dependencies.[^5]

```zig
fn processData(allocator: std.mem.Allocator, data: []const u8) !Result {
    const buffer = try allocator.alloc(u8, data.len * 2);
    defer allocator.free(buffer);
    // Process data...
}
```

For long-lived structs, allocators may be stored as fields to simplify cleanup:

```zig
const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator) !Parser {
        return .{
            .allocator = allocator,
            .tokens = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.tokens.deinit();
        // Allocator stored for cleanup
    }
};
```

The trade-off: storing the allocator increases struct size but eliminates the need to pass it to `deinit()`. TigerBeetle recommends meaningful allocator parameter names—`gpa` for general-purpose allocators requiring explicit cleanup, `arena` for bulk cleanup contexts—to communicate ownership semantics.[^5]

### Ownership Semantics

Ownership in Zig is explicit and documented by convention. Three patterns dominate production codebases:

**Caller-Owns Pattern** — Caller allocates and retains ownership; the function uses but does not free the memory.

```zig
/// Processes data into caller-provided buffer.
/// Caller retains ownership of `buffer`.
fn processInPlace(buffer: []u8, data: []const u8) void {
    @memcpy(buffer[0..data.len], data);
}
```

**Callee-Returns-Owned Pattern** — Function allocates and returns memory; caller must free it.

```zig
/// Allocates and returns a buffer. Caller owns returned memory
/// and must free it with the same allocator.
fn allocateResult(allocator: std.mem.Allocator, size: usize) ![]u8 {
    return try allocator.alloc(u8, size);
}

// Usage
const result = try allocateResult(allocator, 100);
defer allocator.free(result); // Caller must free
```

**Init/Deinit Pairs** — RAII-like pattern where `init()` allocates and `deinit()` releases. This is the dominant pattern for structs managing resources.

```zig
const Resource = struct {
    allocator: std.mem.Allocator,
    data: []u8,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Resource {
        return .{
            .allocator = allocator,
            .data = try allocator.alloc(u8, size),
        };
    }

    pub fn deinit(self: *Resource) void {
        self.allocator.free(self.data);
    }
};

// Usage
var resource = try Resource.init(allocator, 1024);
defer resource.deinit();
```

TigerBeetle also uses an "out-pointer" style for performance-critical code, where `init()` takes `self: *Resource` and modifies it in place, eliminating intermediate copies and ensuring pointer stability.[^5]

### Cleanup Idioms

Zig provides `defer` and `errdefer` for deterministic cleanup (see Ch5 for comprehensive coverage). Best practice: pair allocations with cleanup immediately:

```zig
const data = try allocator.alloc(u8, 100);
defer allocator.free(data);  // LIFO order: runs at scope exit

const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();
```

For multi-step initialization where later steps might fail, `errdefer` executes only on error returns:

```zig
fn createResources(allocator: std.mem.Allocator) !Resources {
    const buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(buffer1);  // Cleanup if subsequent errors occur

    const buffer2 = try allocator.alloc(u8, 200);
    errdefer allocator.free(buffer2);

    return .{ .buf1 = buffer1, .buf2 = buffer2 };
}
```

**Memory Management Strategy:**
- **Arenas** — Request-scoped bulk cleanup (all freed together)
- **Manual cleanup (defer/errdefer)** — Individual lifetimes or incremental reclamation
- See TigerBeetle's manifest initialization for cascading errdefer patterns[^6]

## Code Examples

### Arena Pattern for Request Handling

```zig
const std = @import("std");

fn handleRequest(allocator: std.mem.Allocator, req_id: u32, data: []const u8) ![]u8 {
    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();

    try parts.append("Processing request ");
    const id_str = try std.fmt.allocPrint(allocator, "{}", .{req_id});
    defer allocator.free(id_str);
    try parts.append(id_str);

    // Concatenate parts
    var total_len: usize = 0;
    for (parts.items) |part| total_len += part.len;

    const result = try allocator.alloc(u8, total_len);
    var offset: usize = 0;
    for (parts.items) |part| {
        @memcpy(result[offset..][0..part.len], part);
        offset += part.len;
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    // Process multiple requests
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        defer _ = arena.reset(.{ .retain_with_limit = 4096 });
        const response = try handleRequest(arena.allocator(), i, "data");
        std.debug.print("{s}\n", .{response});
        // No individual frees needed—arena handles it
    }
}
```

This demonstrates arena reuse with `reset()`, retaining small allocations for performance. Ghostty uses this pattern for configuration parsing, while ZLS uses it for argument processing.[^2][^3]

### FixedBufferAllocator for Stack-Based Operations

```zig
const std = @import("std");

fn formatMessage(buffer: []u8, name: []const u8, value: i32) ![]const u8 {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    const allocator = fba.allocator();

    return try std.fmt.allocPrint(
        allocator,
        "User: {s}, Score: {}",
        .{ name, value }
    );
}

pub fn main() !void {
    var stack_buffer: [256]u8 = undefined;

    const msg1 = try formatMessage(&stack_buffer, "Alice", 100);
    std.debug.print("{s}\n", .{msg1});

    // Reuse same buffer (overwrites previous content)
    const msg2 = try formatMessage(&stack_buffer, "Bob", 200);
    std.debug.print("{s}\n", .{msg2});
}
```

FixedBufferAllocator eliminates heap allocations entirely, offering predictable performance with no system calls. The Zig test runner uses this pattern for command-line processing.[^4]

### Error-Path Cleanup with errdefer

```zig
const std = @import("std");

const Database = struct {
    connection: []u8,
    buffer: []u8,
    cache: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, conn_str: []const u8) !Database {
        const connection = try allocator.alloc(u8, conn_str.len);
        errdefer allocator.free(connection);
        @memcpy(connection, conn_str);

        const buffer = try allocator.alloc(u8, 1024);
        errdefer allocator.free(buffer);

        const cache = try allocator.alloc(u8, 2048);
        errdefer allocator.free(cache);

        if (conn_str.len > 100) {
            return error.ConnectionFailed; // Automatic cleanup via errdefer
        }

        return .{
            .connection = connection,
            .buffer = buffer,
            .cache = cache,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        self.allocator.free(self.cache);
        self.allocator.free(self.buffer);
        self.allocator.free(self.connection);
    }
};
```

If initialization fails after allocating `connection` and `buffer`, both are automatically freed by their respective `errdefer` statements. TigerBeetle's state machine initialization uses this cascading pattern for complex multi-step setup.[^7]

## Common Pitfalls

### Forgetting to Free Allocations

```zig
// ❌ WRONG: Leak on early return
fn leakyFunction(allocator: std.mem.Allocator) !void {
    const data = try allocator.alloc(u8, 100);
    if (someCondition) return error.Failed; // Leak!
}

// ✅ CORRECT: defer ensures cleanup
fn fixedFunction(allocator: std.mem.Allocator) !void {
    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);
    if (someCondition) return error.Failed; // No leak
}
```

**Prevention:** Place `defer allocator.free(data)` immediately after allocation. TigerBeetle's style guide recommends grouping allocations with their defer statements using newlines to make leaks visible during code review.[^5]

### Freeing with the Wrong Allocator

```zig
// ❌ WRONG: Wrong allocator
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
const data = try arena.allocator().alloc(u8, 100);
gpa.allocator().free(data); // Wrong allocator!

// ✅ CORRECT: Use same allocator
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
const allocator = arena.allocator();
const data = try allocator.alloc(u8, 100);
// Rely on arena.deinit() or use same allocator
```

**Prevention:** Store the allocator in a local variable and use it consistently. For arenas, rely on bulk cleanup via `deinit()`.

### Use-After-Free

```zig
// ❌ WRONG: Use after free
var data = try allocator.alloc(u8, 100);
allocator.free(data);
data[0] = 42; // Use after free!

// ✅ CORRECT: defer delays free until end of scope
var data = try allocator.alloc(u8, 100);
defer allocator.free(data);
data[0] = 42; // Still valid
```

**Detection:** Use `GeneralPurposeAllocator` during development—it never reuses memory addresses, helping catch use-after-free bugs.

### Returning Pointers to Stack Memory

```zig
// ❌ WRONG: Dangling pointer
fn createData() *u8 {
    var data: u8 = 42;
    return &data; // Pointer to stack memory!
}

// ✅ CORRECT: Heap allocation, caller owns
fn createData(allocator: std.mem.Allocator) !*u8 {
    const data = try allocator.create(u8);
    data.* = 42;
    return data; // Caller must destroy()
}
```

**Prevention:** Use heap allocation for any data outliving the function scope. Document ownership clearly.

## In Practice

Production codebases demonstrate these patterns at scale:

**TigerBeetle** enforces static allocation: all memory must be allocated at startup, with no dynamic allocation during operation.[^5] This prevents runtime surprises and forces upfront memory planning, critical for financial database correctness. Their manifest initialization shows cascading errdefer cleanup for complex nested structures.[^6]

**Ghostty** uses `ArenaAllocator` for terminal configuration parsing, simplifying cleanup for temporary parsing state.[^2]

**Bun** implements custom allocators for JavaScript runtime performance, demonstrating zero-sized type optimization for nullable allocators and atomic operations for thread-safe allocation.[^8]

**ZLS** (Zig Language Server) conditionally selects debug vs release allocators based on build configuration, balancing safety and performance.[^3]

These exemplars share common patterns: allocator-first parameter ordering, meaningful allocator names (`gpa`, `arena`), immediate defer placement, and comprehensive errdefer for multi-step initialization.

## Summary

Zig's explicit memory management model eliminates hidden allocations, making ownership and lifetime visible in the code. The uniform `Allocator` interface enables compile-time polymorphism, allowing seamless switching between allocators for different use cases.

Key principles:
- **Allocators are explicit parameters**—no hidden allocations
- **Choose allocators by use case**—arena for request scoping, fixed-buffer for bounded performance, GPA for safety
- **Ownership is documented**—caller-owns, callee-returns-owned, or init/deinit pairs
- **Cleanup is deterministic**—defer for guaranteed cleanup, errdefer for error paths
- **Memory is either managed or unmanaged** (✅ 0.15+)—unmanaged containers require explicit allocator passing

Understanding these patterns provides the foundation for containers, I/O, and concurrency covered in subsequent chapters.

## References

1. [Learning Zig - Heap Memory & Allocators](https://www.openmymind.net/learning_zig/heap_memory/)
2. [Ghostty Config.zig - ArenaAllocator usage](https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig#L17)
3. [ZLS main.zig - Arena for argument parsing](https://github.com/zigtools/zls/blob/master/src/main.zig#L233-238)
4. [Zig test runner - FixedBufferAllocator](https://github.com/ziglang/zig/blob/master/lib/compiler/test_runner.zig)
5. [TigerBeetle TIGER_STYLE.md - Memory conventions](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
6. [TigerBeetle manifest.zig - errdefer cleanup](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/manifest.zig#L178-192)
7. [TigerBeetle state_machine.zig - Cascading cleanup](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1052-1057)
8. [Bun allocators.zig - Custom allocators](https://github.com/oven-sh/bun/blob/main/src/allocators.zig)
9. [zig.guide - Allocators](https://zig.guide/standard-library/allocators/)
10. [Leveraging Zig's Allocators](https://www.openmymind.net/Leveraging-Zigs-Allocators/)
11. [Introduction to Zig - Memory and Allocators](https://pedropark99.github.io/zig-book/Chapters/01-memory.html)
12. [Defeating Memory Leaks With Zig Allocators](https://tgmatos.github.io/defeating-memory-leaks-with-zig-allocators/)
13. [Zig 0.14.0 Release Notes](https://ziglang.org/download/0.14.0/release-notes.html)

[^1]: [TigerBeetle state_machine.zig - Aligned allocation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1051)
[^2]: [Ghostty Config.zig](https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig#L17)
[^3]: [ZLS main.zig](https://github.com/zigtools/zls/blob/master/src/main.zig#L233-238)
[^4]: [zig.guide - Allocators](https://zig.guide/standard-library/allocators/)
[^5]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^6]: [TigerBeetle manifest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/manifest.zig#L178-192)
[^7]: [TigerBeetle state_machine.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine.zig#L1052-1057)
[^8]: [Bun allocators.zig](https://github.com/oven-sh/bun/blob/main/src/allocators.zig)
# Collections & Containers

> **TL;DR for Zig collections:**
> - **0.15 default:** `ArrayList(T)` is unmanaged (pass allocator to methods)
> - **Managed variant:** `ArrayListManaged(T)` stores allocator (simpler API, +8 bytes overhead)
> - **Common types:** ArrayList, HashMap, AutoHashMap, StringHashMap
> - **Always:** Call `.deinit(allocator)` to free memory
> - **See [comparison table](#managed-vs-unmanaged-containers) below**
> - **Jump to:** [ArrayList §3.3](#arraylist) | [HashMap §3.4](#hashmap-and-variants) | [Iteration §3.5](#iteration-patterns)

## Overview

Zig's standard library provides dynamic collection types that integrate with the explicit allocator model (see Ch2). This chapter examines container types including ArrayList, HashMap, and their variants, focusing on the distinction between managed and unmanaged containers, ownership semantics, and cleanup responsibilities.

Understanding container ownership is critical for correct memory management. Unlike languages with garbage collection or implicit resource management, Zig requires developers to explicitly handle container lifecycles. The choice between managed and unmanaged containers affects memory overhead, API clarity, and program correctness.

As of Zig 0.15, the standard library has shifted toward unmanaged containers as the default pattern.[^1] This change reflects a broader philosophy: explicit allocator parameters make allocation sites visible, reduce per-container memory overhead, and enable better composition of container-heavy data structures.

## Core Concepts

### Managed vs Unmanaged Containers

| Aspect | Managed (🕐 0.14 default) | Unmanaged (✅ 0.15+ default) |
|--------|---------------------------|------------------------------|
| **Allocator storage** | Stored in struct field (+8 bytes/container) | Not stored (passed as parameter) |
| **API example** | `list.append(item)` | `list.append(allocator, item)` |
| **Allocation visibility** | Hidden in method | Explicit in call site |
| **Memory overhead** | 8 bytes per container (64-bit) | Zero overhead |
| **Use case** | Single containers, simpler API | Structs with many containers |
| **Type name** | `std.ArrayListManaged(T)` (explicit) | `std.ArrayList(T)` (default in 0.15+) |
| **10 containers cost** | +80 bytes | +0 bytes |

```zig
// 🕐 0.14.x: Managed (old default)
var list = std.ArrayList(u8).init(allocator);  // Stores allocator
try list.append('x');  // Uses stored allocator
defer list.deinit();

// ✅ 0.15+: Unmanaged (new default)
var list = std.ArrayList(u8){};  // No stored allocator
try list.append(allocator, 'x');  // Pass allocator explicitly
defer list.deinit(allocator);
```

**Why the change:** Explicit allocator parameters make allocation sites visible and reduce memory overhead. For data structures with many containers, the savings are significant.[^1][^2]

### Container Type Taxonomy

Zig's standard library provides several core container types, each available in both managed and unmanaged variants.

**ArrayList** provides a dynamic array with automatic growth. The unmanaged variant exposes this structure:

```zig
pub fn Aligned(comptime T: type, comptime alignment: ?u29) type {
    return struct {
        items: Slice = &[_]T{},
        capacity: usize = 0,
    };
}
```

The absence of an allocator field characterizes the unmanaged pattern.[^3] Methods that allocate memory accept an allocator parameter:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 42);  // Allocator explicit
defer list.deinit(allocator);    // Allocator required for cleanup
```

**HashMap** provides key-value storage with O(1) average-case lookup. The standard library offers six primary hash map variants:

- `HashMap` and `HashMapUnmanaged` - Custom hash context
- `AutoHashMap` and `AutoHashMapUnmanaged` - Automatic hashing for supported types
- `StringHashMap` and `StringHashMapUnmanaged` - Optimized for string keys

The `Auto` prefix indicates automatic hash function selection. `StringHashMap` treats string keys by content rather than pointer equality.[^4]

```zig
var users = std.AutoHashMapUnmanaged(u32, User).init();
try users.put(allocator, 1, user_instance);
defer users.deinit(allocator);
```

**ArrayHashMap** maintains insertion order and provides O(1) indexing through contiguous storage. This variant trades slightly slower insertion for dramatically faster iteration compared to standard HashMap.[^4]

```zig
var ordered = std.AutoArrayHashMapUnmanaged(u32, []const u8).init();
try ordered.put(allocator, 1, "first");
try ordered.put(allocator, 2, "second");

// Iteration over contiguous memory is cache-friendly
var it = ordered.iterator();
while (it.next()) |entry| {
    std.debug.print("{}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
}
```

Less common but useful container types include `PriorityQueue` for heap operations, `MultiArrayList` for structure-of-arrays layouts, and `SegmentedList` for stable pointer semantics across resizing.

### Ownership Transfer and Borrowing

Container ownership follows the same principles as other Zig resources: explicit ownership transfer and clear borrowing boundaries.

**Direct value storage** means the container owns the values it stores. When storing non-pointer types, `deinit()` frees the container's internal arrays but not the values themselves, as they are embedded directly:

```zig
const User = struct {
    id: u32,
    age: u8,
};

var users = std.AutoHashMapUnmanaged(u32, User).init();
try users.put(allocator, 1, User{ .id = 1, .age = 30 });
defer users.deinit(allocator);  // Frees hash map structure
```

However, if `User` contains allocated fields, cleanup becomes the developer's responsibility:

```zig
const User = struct {
    id: u32,
    name: []u8,  // Allocated separately

    fn deinit(self: *User, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
    }
};

var users = std.AutoHashMapUnmanaged(u32, User).init();
defer {
    var it = users.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.deinit(allocator);  // Clean user's name
    }
    users.deinit(allocator);  // Clean hash map structure
}
```

**Pointer storage** detaches value lifetime from container lifetime. The container stores only pointers; pointed-to values require separate cleanup:

```zig
var users = std.AutoHashMapUnmanaged(u32, *User).init();
defer {
    var it = users.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.*.deinit(allocator);  // Clean user object
        allocator.destroy(entry.value_ptr.*);  // Free pointer
    }
    users.deinit(allocator);  // Clean map structure
}
```

This pattern is described in the community resources as "the lifetime of the values is detached from the lifetime of the hash map."[^5]

**Ownership transfer** through `toOwnedSlice()` transfers an ArrayList's internal buffer to the caller:

```zig
var list = std.ArrayList(u8).init(allocator);
try list.appendSlice(allocator, "Hello");

const owned = try list.toOwnedSlice(allocator);
defer allocator.free(owned);  // Caller must free

// list is now empty: items.len == 0, capacity == 0
```

The list becomes empty after the transfer. This pattern enables functions to return dynamically-sized data without copying.[^3]

### Deinit Responsibilities

Every container that allocates memory must call `deinit()` with the same allocator used for initialization. Failure to do so causes memory leaks.

**Basic cleanup** requires matching `init()` with `deinit()`:

```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);  // Required

try list.append(allocator, 42);
```

The `defer` statement ensures cleanup occurs even on early return or error paths.

**Nested containers** require cleanup in reverse order of initialization:

```zig
var outer = std.ArrayList(std.ArrayList(u32)).init(allocator);
defer {
    for (outer.items) |*inner| {
        inner.deinit(allocator);  // Clean each inner list first
    }
    outer.deinit(allocator);  // Clean outer list last
}
```

**Error-path cleanup** uses `errdefer` to handle partial initialization failures. The TigerBeetle codebase demonstrates this pattern extensively:[^6]

```zig
pub fn init(allocator: std.mem.Allocator, options: Options) !CacheMap {
    var cache: ?Cache = if (options.cache_value_count_max == 0)
        null
    else
        try Cache.init(allocator, options.cache_value_count_max, .{ .name = options.name });
    errdefer if (cache) |*c| c.deinit(allocator);

    var stash: Map = .{};
    try stash.ensureTotalCapacity(allocator, options.stash_value_count_max);
    errdefer stash.deinit(allocator);

    var scope_rollback_log = try std.ArrayListUnmanaged(Value).initCapacity(
        allocator,
        options.scope_value_count_max,
    );
    errdefer scope_rollback_log.deinit(allocator);

    return CacheMap{
        .cache = cache,
        .stash = stash,
        .scope_rollback_log = scope_rollback_log,
        .options = options,
    };
}
```

Each allocation is immediately followed by `errdefer` cleanup. If any subsequent allocation fails, previously initialized resources are automatically freed in reverse order (LIFO).

**Arena allocators** provide bulk cleanup for containers with similar lifetimes:

```zig
var arena = std.heap.ArenaAllocator.init(page_allocator);
defer arena.deinit();  // Frees everything at once
const arena_alloc = arena.allocator();

var list1 = std.ArrayList(u8).init(arena_alloc);
var list2 = std.ArrayList(u32).init(arena_alloc);

// No individual deinit needed - arena cleanup handles all
try list1.appendSlice(arena_alloc, "data");
try list2.append(arena_alloc, 42);
```

The arena pattern is common in request-scoped or phase-based processing where many containers share the same lifetime.[^7]

### Container Selection Guidance

Choosing the appropriate container requires understanding performance characteristics and usage patterns.

**ArrayList vs fixed arrays vs slices:**

- ArrayList: Unknown size at compile time, needs growth
- Fixed array `[N]T`: Known size at compile time, stack allocation
- Slice `[]T`: Borrows existing data, no ownership

```zig
// ArrayList: Unknown size, heap allocation
var dynamic = std.ArrayList(u8).init(allocator);
defer dynamic.deinit(allocator);

// Fixed array: Known size, stack allocation
var fixed: [128]u8 = undefined;

// Slice: Borrows data
const borrowed: []const u8 = "static string";
```

**HashMap vs ArrayHashMap:**

HashMap provides O(1) average-case lookup with unordered storage. ArrayHashMap maintains insertion order and offers O(1) indexing with faster iteration due to contiguous memory layout.[^4]

Choose HashMap when:
- Insertion order does not matter
- Lookup performance is critical
- Memory layout is less important

Choose ArrayHashMap when:
- Iteration is frequent
- Insertion order matters
- Array-like indexing is needed
- Cache-friendly traversal is beneficial

**Pre-allocation strategies** avoid repeated reallocation during container growth:

```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);

// Pre-allocate known capacity
try list.ensureTotalCapacity(allocator, 100);

// Append without allocation
for (0..100) |i| {
    list.appendAssumeCapacity(@intCast(i));  // No allocation
}
```

The Ghostty terminal emulator demonstrates this pattern with a documented rationale:[^8]

```zig
var args: std.ArrayList([:0]const u8) = try .initCapacity(
    alloc,
    // This capacity is chosen based on what we'd need to
    // execute a shell command (very common). We can/will
    // grow if necessary for a longer command (uncommon).
    9,
);
defer args.deinit(alloc);
```

The comment explains why 9 is chosen: it covers the common case (shell execution) while allowing growth for uncommon cases.

**Container reuse** with `clearRetainingCapacity()` avoids allocation churn in loops:

```zig
var buffer = std.ArrayList(u8).init(allocator);
defer buffer.deinit(allocator);

try buffer.ensureTotalCapacity(allocator, 1024);

for (requests) |request| {
    buffer.clearRetainingCapacity();  // Clear contents, keep capacity
    try processRequest(request, &buffer);
}
```

This pattern is common in performance-critical code, particularly when processing repeated requests or iterations.[^9]

## Code Examples

### Example 1: Managed vs Unmanaged ArrayList

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ✅ 0.15+ Unmanaged ArrayList (default)
    std.debug.print("=== Unmanaged ArrayList ===\n", .{});
    var unmanaged_list = std.ArrayList(u32).init(allocator);
    defer unmanaged_list.deinit(allocator);  // Allocator required

    try unmanaged_list.append(allocator, 10);  // Allocator required
    try unmanaged_list.append(allocator, 20);
    try unmanaged_list.append(allocator, 30);

    std.debug.print("Items: ", .{});
    for (unmanaged_list.items) |item| {
        std.debug.print("{} ", .{item});
    }
    std.debug.print("\n", .{});
    std.debug.print("Capacity: {}, Length: {}\n", .{ unmanaged_list.capacity, unmanaged_list.items.len });

    // Show struct size difference
    std.debug.print("Unmanaged struct size: {} bytes\n\n", .{@sizeOf(@TypeOf(unmanaged_list))});

    // Pre-allocation pattern
    std.debug.print("=== Pre-allocation Pattern ===\n", .{});
    var preallocated = std.ArrayList(u32).init(allocator);
    defer preallocated.deinit(allocator);

    // Allocate exact capacity upfront (no reallocation needed)
    try preallocated.ensureTotalCapacity(allocator, 100);
    std.debug.print("Pre-allocated capacity: {}\n", .{preallocated.capacity});

    // Fast append without allocation
    for (0..100) |i| {
        preallocated.appendAssumeCapacity(@intCast(i));
    }
    std.debug.print("After 100 appends, capacity: {}\n", .{preallocated.capacity});
}
```

This example demonstrates the unmanaged ArrayList API where allocators must be passed to every method. Pre-allocation with `ensureTotalCapacity()` enables zero-allocation appends using `appendAssumeCapacity()`.

### Example 2: HashMap Ownership Patterns

```zig
const std = @import("std");

const User = struct {
    id: u32,
    name: []u8,
    score: i32,

    pub fn init(allocator: std.mem.Allocator, id: u32, name: []const u8, score: i32) !User {
        return .{
            .id = id,
            .name = try allocator.dupe(u8, name),
            .score = score,
        };
    }

    pub fn deinit(self: *User, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Pattern 1: Direct value storage
    std.debug.print("=== Pattern 1: Direct Value Storage ===\n", .{});
    var users_direct = std.AutoHashMapUnmanaged(u32, User).init();
    defer {
        // Must clean up allocated fields within values
        var it = users_direct.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(allocator);
        }
        users_direct.deinit(allocator);
    }

    var user1 = try User.init(allocator, 1, "Alice", 100);
    try users_direct.put(allocator, user1.id, user1);

    if (users_direct.get(1)) |user| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user.name, user.score });
    }

    // Pattern 2: Pointer storage (detached lifetime)
    std.debug.print("=== Pattern 2: Pointer Storage ===\n", .{});
    var users_ptr = std.AutoHashMapUnmanaged(u32, *User).init();
    defer {
        // Must free both the pointed-to objects AND the pointers
        var it = users_ptr.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit(allocator);
            allocator.destroy(entry.value_ptr.*);
        }
        users_ptr.deinit(allocator);
    }

    var user2 = try allocator.create(User);
    user2.* = try User.init(allocator, 2, "Bob", 200);
    try users_ptr.put(allocator, user2.id, user2);

    if (users_ptr.get(2)) |user_ptr| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user_ptr.name, user_ptr.score });
    }

    // Pattern 3: HashMap as Set (void value)
    std.debug.print("=== Pattern 3: HashMap as Set ===\n", .{});
    var seen_ids = std.AutoHashMapUnmanaged(u32, void).init();
    defer seen_ids.deinit(allocator);

    try seen_ids.put(allocator, 42, {});
    try seen_ids.put(allocator, 100, {});

    std.debug.print("Contains 42? {}\n", .{seen_ids.contains(42)});
    std.debug.print("Contains 99? {}\n", .{seen_ids.contains(99)});
}
```

This example illustrates three HashMap ownership patterns. Pattern 1 stores values directly, requiring cleanup of allocated fields. Pattern 2 stores pointers with detached lifetimes, requiring both object and pointer cleanup. Pattern 3 demonstrates the set idiom using `void` values.

### Example 3: Nested Container Cleanup with errdefer

```zig
const std = @import("std");

const Database = struct {
    tables: std.ArrayList(Table),
    allocator: std.mem.Allocator,

    const Table = struct {
        name: []u8,
        rows: std.ArrayList([]u8),
    };

    pub fn init(allocator: std.mem.Allocator, table_names: []const []const u8) !Database {
        var tables = std.ArrayList(Table).init(allocator);
        errdefer {
            // Clean up any successfully initialized tables on error
            for (tables.items) |*table| {
                for (table.rows.items) |row| {
                    allocator.free(row);
                }
                table.rows.deinit(allocator);
                allocator.free(table.name);
            }
            tables.deinit(allocator);
        }

        for (table_names) |name| {
            const table_name = try allocator.dupe(u8, name);
            errdefer allocator.free(table_name);  // If rows allocation fails

            var rows = std.ArrayList([]u8).init(allocator);
            errdefer rows.deinit(allocator);  // If append to tables fails

            try tables.append(allocator, .{
                .name = table_name,
                .rows = rows,
            });
        }

        return .{
            .tables = tables,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        for (self.tables.items) |*table| {
            for (table.rows.items) |row| {
                self.allocator.free(row);
            }
            table.rows.deinit(self.allocator);
            self.allocator.free(table.name);
        }
        self.tables.deinit(self.allocator);
    }

    pub fn addRow(self: *Database, table_idx: usize, data: []const u8) !void {
        if (table_idx >= self.tables.items.len) return error.InvalidTable;

        const row = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(row);

        try self.tables.items[table_idx].rows.append(self.allocator, row);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Nested Container with errdefer ===\n", .{});

    // Success case
    const table_names = [_][]const u8{ "users", "products", "orders" };
    var db = try Database.init(allocator, &table_names);
    defer db.deinit();

    try db.addRow(0, "Alice");
    try db.addRow(0, "Bob");
    try db.addRow(1, "Widget");

    for (db.tables.items, 0..) |table, i| {
        std.debug.print("Table {s} has {} rows\n", .{ table.name, table.rows.items.len });
    }

    std.debug.print("\nDatabase cleaned up successfully\n", .{});
}
```

This example demonstrates cascading `errdefer` for multi-level nested containers. Each allocation is followed by cleanup code that runs only on error paths, preventing leaks during partial initialization.

### Example 4: Ownership Transfer with toOwnedSlice

```zig
const std = @import("std");

fn buildMessage(allocator: std.mem.Allocator, parts: []const []const u8) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    // Note: No defer here - ownership transferred via toOwnedSlice

    for (parts, 0..) |part, i| {
        try list.appendSlice(allocator, part);
        if (i < parts.len - 1) {
            try list.append(allocator, ' ');
        }
    }

    // Transfer ownership to caller
    return list.toOwnedSlice(allocator);
}

fn processData(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u32) {
    var numbers = std.ArrayList(u32).init(allocator);
    errdefer numbers.deinit(allocator);  // Clean up on error

    for (input) |byte| {
        if (byte >= '0' and byte <= '9') {
            try numbers.append(allocator, byte - '0');
        }
    }

    // Transfer ownership by returning the ArrayList directly
    return numbers;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Ownership Transfer Patterns ===\n\n", .{});

    // Pattern 1: toOwnedSlice (ArrayList → Slice)
    std.debug.print("Pattern 1: toOwnedSlice\n", .{});
    const parts = [_][]const u8{ "Hello", "from", "Zig" };
    const message = try buildMessage(allocator, &parts);
    defer allocator.free(message);  // Caller owns and must free

    std.debug.print("Message: {s}\n\n", .{message});

    // Pattern 2: Return ArrayList directly
    std.debug.print("Pattern 2: Return ArrayList\n", .{});
    var numbers = try processData(allocator, "a1b2c3d4e5");
    defer numbers.deinit(allocator);  // Caller owns and must deinit

    std.debug.print("Numbers: ", .{});
    for (numbers.items) |num| {
        std.debug.print("{} ", .{num});
    }
    std.debug.print("\n\n", .{});

    // Pattern 3: fromOwnedSlice (Slice → ArrayList)
    std.debug.print("Pattern 3: fromOwnedSlice\n", .{});
    const raw_data = try allocator.alloc(u8, 5);
    for (raw_data, 0..) |*byte, i| {
        byte.* = @intCast('A' + i);
    }

    var list_from_slice = std.ArrayList(u8).fromOwnedSlice(allocator, raw_data);
    defer list_from_slice.deinit(allocator);  // Now list owns the data

    try list_from_slice.append(allocator, 'F');  // Can grow
    std.debug.print("From slice: {s}\n", .{list_from_slice.items});
}
```

This example shows three ownership transfer patterns. `toOwnedSlice()` transfers buffer ownership to the caller. Returning an ArrayList directly transfers the entire container. `fromOwnedSlice()` allows an ArrayList to take ownership of an existing slice.

### Example 5: Container Reuse with clearRetainingCapacity

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Reusing Containers Across Iterations ===\n\n", .{});

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit(allocator);

    // Pre-allocate reasonable capacity
    try buffer.ensureTotalCapacity(allocator, 1024);

    const requests = [_][]const u8{ "request1", "request2", "request3" };

    for (requests, 0..) |request, i| {
        // Clear contents but keep capacity
        buffer.clearRetainingCapacity();

        std.debug.print("Iteration {}: ", .{i});
        std.debug.print("Length: {}, Capacity: {}\n", .{ buffer.items.len, buffer.capacity });

        // Build response using existing capacity
        try buffer.appendSlice(allocator, "Response to ");
        try buffer.appendSlice(allocator, request);

        std.debug.print("  Built: {s}\n", .{buffer.items});
        std.debug.print("  Final length: {}, Capacity: {}\n\n", .{ buffer.items.len, buffer.capacity });
    }

    std.debug.print("No reallocations occurred - capacity stayed constant\n", .{});

    // HashMap example
    std.debug.print("\n=== HashMap Reset Pattern ===\n\n", .{});

    var cache = std.AutoHashMapUnmanaged(u32, []const u8).init();
    defer cache.deinit(allocator);

    try cache.ensureTotalCapacity(allocator, 100);

    for (0..3) |batch| {
        std.debug.print("Batch {}: ", .{batch});

        // Populate cache
        for (0..10) |i| {
            try cache.put(allocator, @intCast(i), "data");
        }

        std.debug.print("Count: {}, Capacity: {}\n", .{ cache.count(), cache.capacity() });

        // Reset for next batch
        cache.clearRetainingCapacity();
    }

    std.debug.print("\nCache reused across batches without reallocation\n", .{});
}
```

This example demonstrates `clearRetainingCapacity()` for efficient container reuse. Pre-allocation followed by clearing avoids repeated allocation/deallocation cycles in iterative processing.

### Example 6: HashMap vs ArrayHashMap Performance

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const iterations = 1000;

    // HashMap vs ArrayHashMap iteration performance
    std.debug.print("=== HashMap vs ArrayHashMap Iteration ===\n", .{});

    var hash_map = std.AutoHashMapUnmanaged(u32, u32).init();
    defer hash_map.deinit(allocator);

    var array_hash_map = std.AutoArrayHashMapUnmanaged(u32, u32).init();
    defer array_hash_map.deinit(allocator);

    // Populate both
    for (0..100) |i| {
        try hash_map.put(allocator, @intCast(i), @intCast(i * 2));
        try array_hash_map.put(allocator, @intCast(i), @intCast(i * 2));
    }

    // Iterate HashMap
    var timer = try std.time.Timer.start();
    var sum1: u64 = 0;
    for (0..iterations) |_| {
        var it1 = hash_map.iterator();
        while (it1.next()) |entry| {
            sum1 += entry.value_ptr.*;
        }
    }
    const hash_map_time = timer.read();

    // Iterate ArrayHashMap
    timer.reset();
    var sum2: u64 = 0;
    for (0..iterations) |_| {
        var it2 = array_hash_map.iterator();
        while (it2.next()) |entry| {
            sum2 += entry.value_ptr.*;
        }
    }
    const array_hash_map_time = timer.read();

    std.debug.print("HashMap iteration: {} ns (sum: {})\n", .{ hash_map_time, sum1 });
    std.debug.print("ArrayHashMap iteration: {} ns (sum: {})\n", .{ array_hash_map_time, sum2 });

    if (array_hash_map_time > 0) {
        const speedup = @as(f64, @floatFromInt(hash_map_time)) / @as(f64, @floatFromInt(array_hash_map_time));
        std.debug.print("ArrayHashMap is {d:.2}x faster for iteration\n", .{speedup});
    }
}
```

This example compares HashMap and ArrayHashMap iteration performance. ArrayHashMap's contiguous memory layout provides better cache locality, resulting in faster iteration over the same data.

## Common Pitfalls

### Pitfall 1: Forgetting Container deinit()

Containers that allocate memory must call `deinit()` before going out of scope. Without this cleanup, memory leaks occur.

**Problem:**
```zig
fn processData(allocator: std.mem.Allocator) !void {
    var list = std.ArrayList(u8).init(allocator);
    try list.append(allocator, 'A');
    // Forgot: defer list.deinit(allocator);
    if (someCondition) return error.Failed;  // Leak!
}
```

**Detection:**
Use `std.testing.allocator` in tests. This allocator detects memory leaks automatically:

```zig
test "container cleanup" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit(std.testing.allocator);
    try list.append(std.testing.allocator, 'A');
}
```

If the `defer` is omitted, the test fails with a leak detection error.

**Solution:**
Place `defer` immediately after initialization:

```zig
fn processData(allocator: std.mem.Allocator) !void {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit(allocator);  // Placed immediately
    try list.append(allocator, 'A');
    if (someCondition) return error.Failed;  // No leak
}
```

### Pitfall 2: Incomplete Nested Container Cleanup

Containers containing other containers require multi-level cleanup. Calling `deinit()` on the outer container does not automatically clean inner containers.

**Problem:**
```zig
var outer = std.ArrayList(std.ArrayList(u8)).init(allocator);
defer outer.deinit(allocator);  // Only frees outer, not inner lists!

var inner = std.ArrayList(u8).init(allocator);
try inner.append(allocator, 1);
try outer.append(allocator, inner);
```

**Solution:**
Iterate and clean inner containers before cleaning the outer:

```zig
var outer = std.ArrayList(std.ArrayList(u8)).init(allocator);
defer {
    for (outer.items) |*inner_list| {
        inner_list.deinit(allocator);  // Free each inner
    }
    outer.deinit(allocator);  // Free outer
}
```

### Pitfall 3: HashMap with Allocated Keys or Values

HashMap `deinit()` frees the hash table structure but not allocated keys or values stored as pointers.

**Problem:**
```zig
var cache = std.StringHashMapUnmanaged(*User).init();
defer cache.deinit(allocator);  // Doesn't free User pointers!
```

**Solution:**
Iterate and free values before calling `deinit()`:

```zig
var cache = std.StringHashMapUnmanaged(*User).init();
defer {
    var it = cache.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.*.deinit();  // Clean user object
        allocator.destroy(entry.value_ptr.*);  // Free pointer
    }
    cache.deinit(allocator);  // Free map
}
```

This pattern appears in community documentation on HashMap ownership.[^5]

### Pitfall 4: Pointer Invalidation After Growth

Pointers into container storage become invalid when the container reallocates during growth.

**Problem:**
```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 1);
const ptr = &list.items[0];  // Get pointer to first element

try list.append(allocator, 2);  // May reallocate!
ptr.* = 10;  // Pointer may be invalid
```

If the `append()` causes reallocation, `ptr` points to freed memory. Dereferencing it invokes undefined behavior.

**Solution:**
Use indices instead of pointers:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 1);
const index = 0;

try list.append(allocator, 2);
list.items[index] = 10;  // Safe
```

Alternatively, pre-allocate capacity to prevent reallocation:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.ensureTotalCapacity(allocator, 10);
const ptr = &list.items[0];  // Safe until capacity exceeded
try list.append(allocator, 1);
```

### Pitfall 5: Version Migration API Confusion

Code written for Zig 0.14.x fails to compile under Zig 0.15+ due to the unmanaged default change.

**Problem (0.14.x → 0.15+):**
```zig
// This worked in 0.14.x (managed)
var list = std.ArrayList(u32).init(allocator);
defer list.deinit();  // 0.15+: missing allocator parameter
try list.append(42);  // 0.15+: missing allocator parameter
```

**Migration Strategy:**
Search the codebase for container method calls and add allocator parameters:

1. Search for `\.deinit\(\)` without allocator
2. Search for `\.append\(` without allocator as first parameter
3. Search for `\.put\(` in HashMap code without allocator

**Solution:**
Add allocator parameters to all methods:

```zig
// ✅ 0.15+ (unmanaged)
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);  // Pass allocator
try list.append(allocator, 42);  // Pass allocator
```

Test with `std.testing.allocator` to catch remaining leaks from missed cleanup calls.

## In Practice

Production codebases demonstrate these container patterns at scale.

### TigerBeetle: Static Allocation and Unmanaged Containers

TigerBeetle's architecture mandates static allocation: all memory is allocated at startup, with no dynamic allocation during operation.[^10] This constraint shapes their container usage.

The LSM tree implementation demonstrates extensive use of unmanaged containers with pre-allocated capacity:[^6]

```zig
var scope_rollback_log = try std.ArrayListUnmanaged(Value).initCapacity(
    allocator,
    options.scope_value_count_max,
);
```

Capacity is determined at initialization and never exceeded. The `ArrayListUnmanaged` pattern saves memory overhead while maintaining deterministic allocation behavior.

HashMap usage follows similar patterns, with `HashMapUnmanaged` for sets:[^6]

```zig
pub const Map = std.HashMapUnmanaged(
    Value,
    void,  // Set pattern: no associated data
    struct {
        pub inline fn eql(_: @This(), a: Value, b: Value) bool {
            return key_from_value(&a) == key_from_value(&b);
        }
        pub inline fn hash(_: @This(), value: Value) u64 {
            return stdx.hash_inline(key_from_value(&value));
        }
    },
    50,  // 50% max load factor
);
```

The `void` value type creates a set (membership testing without associated data). Custom hash and equality functions enable value-based rather than pointer-based comparison.

### Ghostty: Capacity Optimization

The Ghostty terminal emulator demonstrates capacity pre-allocation with documented rationale:[^8]

```zig
var args: std.ArrayList([:0]const u8) = try .initCapacity(
    alloc,
    9,  // Covers shell execution (common case)
);
```

The comment explains the design choice: optimize for the common case (shell execution requiring 9 arguments) while allowing growth for uncommon cases. This balances memory efficiency with performance.

### Bun: Arena Allocators with Containers

Bun's snapshot testing implementation uses arena allocators for temporary containers:[^11]

```zig
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();

var result_text = std.ArrayList(u8).init(arena.allocator());
```

The arena provides bulk cleanup. When processing completes, a single `arena.deinit()` frees all containers and their contents at once. This pattern is common in request-scoped or phase-based processing.

### ZLS: MultiArrayList and SegmentedList

The Zig Language Server uses specialized container types for compiler data structures:[^12]

```zig
items: std.MultiArrayList(Item) = .empty,
extra: std.ArrayList(u32) = .empty,
decls: std.SegmentedList(Decl, 0) = .{},
```

`MultiArrayList` uses structure-of-arrays layout for cache efficiency. `SegmentedList` provides stable pointers across resizing, critical for compiler IR where nodes reference each other.

### Mach: Game Engine Collection Patterns

Mach demonstrates sophisticated collection patterns across its game engine architecture, from memory-efficient string interning to entity component systems.

**Pattern 1: String Interning with Custom HashMap Context**

Mach's `StringTable` implements bidirectional string-to-index mapping using custom hash map contexts:[^mach1]

```zig
// mach/src/StringTable.zig:11-16
const StringTable = @This();

string_bytes: std.ArrayListUnmanaged(u8) = .{},
string_table: std.HashMapUnmanaged(u32, void, IndexContext, std.hash_map.default_max_load_percentage) = .{},
```

The key insight: instead of storing strings as keys, store *byte array indices* as keys. The custom context translates between string slices and indices:

```zig
// mach/src/StringTable.zig:68-80
const SliceAdapter = struct {
    string_bytes: *std.ArrayListUnmanaged(u8),

    pub fn eql(adapter: SliceAdapter, a_slice: []const u8, b: u32) bool {
        const b_slice = std.mem.span(@as([*:0]const u8, @ptrCast(adapter.string_bytes.items.ptr)) + b);
        return std.mem.eql(u8, a_slice, b_slice);
    }

    pub fn hash(adapter: SliceAdapter, adapted_key: []const u8) u64 {
        _ = adapter;
        return std.hash_map.hashString(adapted_key);
    }
};
```

**Benefits:**
- **Memory:** One copy of each string, no duplication
- **Lookups:** O(1) for both string→index and index→string
- **Cache-friendly:** Contiguous string storage in `string_bytes`

**Pattern 2: Entity Component System with Multiple Unmanaged Collections**

Mach's `Objects` type implements an ECS (Entity Component System) using five unmanaged collections:[^mach2]

```zig
// mach/src/module.zig:38-76
pub fn Objects(options: ObjectsOptions, comptime T: type) type {
    return struct {
        internal: struct {
            allocator: std.mem.Allocator,
            mu: std.Thread.Mutex = .{},
            type_id: ObjectTypeID,

            // Five unmanaged collections working together:
            data: std.MultiArrayList(T) = .{},
            dead: std.bit_set.DynamicBitSetUnmanaged = .{},
            generation: std.ArrayListUnmanaged(Generation) = .{},
            recycling_bin: std.ArrayListUnmanaged(Index) = .{},
            tags: std.AutoHashMapUnmanaged(TaggedObject, ?ObjectID) = .{},

            thrown_on_the_floor: u32 = 0,
            graph: *Graph,
            updated: ?std.bit_set.DynamicBitSetUnmanaged = if (options.track_fields) .{} else null,
        },
    };
}
```

**Why MultiArrayList:** Structure-of-arrays layout for cache efficiency when iterating:

```zig
// Instead of:  [Entity{x,y,z}, Entity{x,y,z}, ...]  (array-of-structs)
// Mach uses:   [x,x,x,...], [y,y,y,...], [z,z,z,...]  (struct-of-arrays)
```

Iterating over just X coordinates accesses contiguous memory, maximizing cache hits.

**Why DynamicBitSetUnmanaged:** Track alive/dead entities with 1 bit per entity instead of 1 byte:

```zig
// 10,000 entities:
// std.ArrayList(bool): 10,000 bytes
// DynamicBitSetUnmanaged: 1,250 bytes (8x smaller)
```

**Pattern 3: Object Recycling with Generation Counters**

When entities are deleted, Mach recycles their indices using a generation counter to detect use-after-free:[^mach2]

```zig
// mach/src/module.zig:139-164
pub fn new(objs: *@This(), value: T) std.mem.Allocator.Error!ObjectID {
    const data = &objs.internal.data;
    const dead = &objs.internal.dead;
    const generation = &objs.internal.generation;
    const recycling_bin = &objs.internal.recycling_bin;

    // Periodically clean up if 10% of objects are on the floor
    if (objs.internal.thrown_on_the_floor >= (data.len / 10)) {
        var iter = dead.iterator(.{ .kind = .set });
        while (iter.next()) |index| {
            try recycling_bin.append(allocator, @intCast(index));
        }
        objs.internal.thrown_on_the_floor = 0;
    }

    // Reuse dead object slot if available
    const index = if (recycling_bin.items.len > 0)
        recycling_bin.pop()
    else
        @as(Index, @intCast(data.len));

    // Increment generation to invalidate old IDs
    if (index < generation.items.len) {
        generation.items[index] += 1;
    }
}
```

**ObjectID encoding:** Packs type, generation, and index into u64:

```zig
// mach/src/module.zig:88-92
const PackedID = packed struct(u64) {
    type_id: ObjectTypeID,   // 16 bits: which type of object
    generation: Generation,  // 16 bits: which version of this slot
    index: Index,            // 32 bits: which slot in the array
};
```

Old references fail gracefully when generation mismatches, catching use-after-free bugs.

**Pattern 4: Unmanaged Container Aggregation**

Mach's shader compiler demonstrates a struct with many unmanaged containers:[^13]

```zig
// mach sysgpu/shader/AstGen.zig
allocator: std.mem.Allocator,
instructions: std.AutoArrayHashMapUnmanaged(Inst, void) = .{},
refs: std.ArrayListUnmanaged(InstIndex) = .{},
strings: std.ArrayListUnmanaged(u8) = .{},
values: std.ArrayListUnmanaged(u8) = .{},
scratch: std.ArrayListUnmanaged(InstIndex) = .{},
global_var_refs: std.AutoArrayHashMapUnmanaged(InstIndex, void) = .{},
globals: std.ArrayListUnmanaged(InstIndex) = .{},
```

**Memory savings:** 7 containers × 8 bytes = 56 bytes saved vs managed variants. For graphics code with hundreds of these structs, savings are substantial.

**Pattern 5: Event Queue with Pre-Allocation**

Mach's Core module pre-allocates event queue capacity during initialization:[^mach3]

```zig
// mach/src/Core.zig:128-129
var events = EventQueue.init(allocator);
try events.ensureTotalCapacity(8192);
```

**Where EventQueue is defined:**

```zig
// mach/src/Core.zig:11
const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);
```

**Why 8192:** Prevents reallocation during gameplay. Input events (keyboard, mouse) occur frequently; pre-allocation ensures zero-allocation event handling in the main loop.

**Key Takeaways from Mach:**
- **Custom hash contexts** enable memory-efficient string interning and specialized lookups
- **MultiArrayList** (structure-of-arrays) maximizes cache efficiency for component iteration
- **BitSetUnmanaged** provides 8x memory savings over bool arrays for entity state
- **Generation counters** catch use-after-free bugs by encoding version in object IDs
- **Pre-allocation** eliminates allocation overhead in performance-critical loops
- **Unmanaged containers** reduce memory overhead when aggregating many collections

## Summary

Zig containers integrate with the explicit allocator model, requiring developers to manage ownership and cleanup. The shift from managed to unmanaged containers as of Zig 0.15 reflects a broader philosophy: explicit allocation sites improve code clarity and reduce memory overhead.

**Key takeaways:**

1. **Unmanaged is default (0.15+):** ArrayList, HashMap, and related containers no longer store allocators. Methods require explicit allocator parameters.

2. **Ownership determines cleanup:** Direct value storage requires cleaning allocated fields. Pointer storage requires both object and pointer cleanup. The container's `deinit()` only frees its internal structure.

3. **Pre-allocate when possible:** `ensureTotalCapacity()` avoids reallocation overhead. Combine with `appendAssumeCapacity()` or `putAssumeCapacity()` for zero-allocation operations.

4. **Reuse containers:** `clearRetainingCapacity()` resets contents while preserving allocated memory, avoiding allocation churn in loops.

5. **Use appropriate variants:** ArrayHashMap for iteration-heavy workloads, HashMap for lookup-heavy. SegmentedList when pointer stability matters. MultiArrayList for cache efficiency.

6. **Arena for bulk cleanup:** When containers share lifetimes, an arena allocator simplifies cleanup by freeing everything at once.

Production codebases demonstrate these patterns at scale. TigerBeetle uses static pre-allocation with unmanaged containers. Ghostty optimizes capacity for common cases. Bun employs arenas for request-scoped processing. ZLS uses specialized containers for compiler data structures. Mach aggregates many unmanaged containers to reduce memory overhead.

The transition from managed to unmanaged containers represents a maturation of Zig's approach to explicit resource management. By making allocation sites visible and eliminating per-container overhead, unmanaged containers provide better composability and clearer code.

## References

[^1]: [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
[^2]: [Ziggit: Embracing Unmanaged](https://ziggit.dev/t/embracing-unmanaged-plans-with-eg-autohashmap/11934)
[^3]: [Zig Standard Library - array_list.zig](https://github.com/ziglang/zig/blob/master/lib/std/array_list.zig)
[^4]: [Hexops - Zig Hashmaps Explained](https://devlog.hexops.com/2022/zig-hashmaps-explained/)
[^5]: [OpenMyMind - Zig's HashMap Part 2](https://www.openmymind.net/Zigs-HashMap-Part-2/)
[^6]: [TigerBeetle lsm/cache_map.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/cache_map.zig)
[^7]: [Bun test/snapshot.zig](https://github.com/oven-sh/bun/blob/main/src/bun.js/test/snapshot.zig)
[^8]: [Ghostty termio/Exec.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig)
[^9]: [Krut's Blog: Memory Leak in Zig](https://iamkroot.github.io/blog/zig-memleak)
[^10]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^11]: [Bun test/snapshot.zig:239](https://github.com/oven-sh/bun/blob/main/src/bun.js/test/snapshot.zig#L239)
[^12]: [ZLS analyser/InternPool.zig](https://github.com/zigtools/zls/blob/master/src/analyser/InternPool.zig)
[^13]: [Mach sysgpu/shader/AstGen.zig](https://github.com/hexops/mach/blob/main/src/sysgpu/shader/AstGen.zig)
[^mach1]: [Mach Source: StringTable with Custom HashMap Context](https://github.com/hexops/mach/blob/main/src/StringTable.zig) - Bidirectional string interning using indices as keys
[^mach2]: [Mach Source: Objects ECS Implementation](https://github.com/hexops/mach/blob/main/src/module.zig#L36-L150) - Entity component system with MultiArrayList, BitSet, and generation counters
[^mach3]: [Mach Source: Core Event Queue Pre-Allocation](https://github.com/hexops/mach/blob/main/src/Core.zig#L128-L129) - Zero-allocation event handling with pre-allocated capacity
# I/O, Streams & Formatting

> **TL;DR for I/O in Zig:**
> - **0.15 breaking:** Use `std.io.getStdOut()` instead of `std.fs.File.stdout()`, explicit buffering now required
> - **Writers/Readers:** Generic interfaces via vtables (uniform API across files, sockets, buffers)
> - **Formatting:** `writer.print("Hello {s}\n", .{name})` - compile-time format checking
> - **Files:** `std.fs.cwd().openFile()`, always `defer file.close()`
> - **Buffering:** Wrap with `std.io.bufferedWriter()` for performance
> - **Jump to:** [Writers/Readers §4.2](#writers-and-readers) | [Formatting §4.3](#string-formatting) | [File I/O §4.4](#file-io-patterns)

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

Use `defer` for cleanup (see Ch5 for comprehensive coverage):

```zig
pub fn safeFileOperation(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();  // Always close on scope exit

    const stat = try file.stat();
    std.debug.print("Size: {d} bytes\n", .{stat.size});
}
```

Use `errdefer` when subsequent operations might fail:

```zig
pub fn createAndWrite(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    errdefer file.close();  // Cleanup if writeAll fails

    try file.writeAll(data);
    file.close();  // Normal close on success
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

This pattern appears in TigerBeetle's StatsD metrics formatting, where allocation-free formatting is critical for performance.

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
- Uses `std.io.fixedBufferStream()` for zero-allocation StatsD metrics formatting
- Source: [`src/trace/statsd.zig:59-85`](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85)
- Pattern: Compile-time buffer sizing for worst-case metric strings

**Direct I/O with Sector Alignment**
- Opens journal files with `O_DIRECT` flag to bypass page cache
- Source: [`src/io/linux.zig:1433-1570`](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1433-L1570)
- Graceful fallback when Direct I/O unavailable
- Block device vs regular file handling

**Latent Sector Error (LSE) Recovery**
- Binary search subdivision to isolate failed sectors on read errors
- Source: [`src/storage.zig:279-384`](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/storage.zig#L279-L384)
- Zeros unreadable sectors for graceful degradation
- AIMD-based recovery throttling

### Ghostty: Event-Driven Terminal I/O

Ghostty, a terminal emulator, shows modern async I/O patterns with the xev library.

**PTY Stream Management**
- Uses `xev.Stream.initFd()` for async pseudo-terminal I/O
- Source: [`src/termio/Exec.zig:128-129`](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig#L128-L129), [`src/termio/Exec.zig:502-516`](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig#L502-L516)
- Write queue with buffer pooling to reduce allocation overhead

**Config File Reading**
- XDG-compliant path resolution with fallbacks
- Source: [`src/config/file_load.zig:136-166`](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig#L136-L166)
- Comprehensive validation: file type, size checks before reading

**Fixed Buffer Writers for String Conversion**
- Stack-allocated buffers for config value serialization
- Source: [`src/config/io.zig:99`](https://github.com/ghostty-org/ghostty/blob/main/src/config/io.zig#L99)
- Pattern: `var writer: std.Io.Writer = .fixed(&buf);`

### Bun: High-Performance Buffered I/O

Bun, a JavaScript runtime, demonstrates performance-optimized I/O for module loading.

**Reference-Counted I/O Readers**
- Buffered readers with async deinit queues
- Source: [`src/shell/IOReader.zig:1-150`](https://github.com/oven-sh/bun/blob/main/src/shell/IOReader.zig#L1-L150)
- Pattern: Ref-counting prevents premature resource cleanup in async contexts

**Dynamic Buffers with ArrayListUnmanaged**
- Uses `std.ArrayListUnmanaged` for buffers without storing allocators
- Reduces struct size and indirection overhead for hot-path I/O

### ZLS: LSP Message Formatting

The Zig Language Server demonstrates I/O patterns for protocol communication.

**Fixed Buffer Logging**
- 4KB stack buffer for log message formatting with overflow handling
- Source: [`src/main.zig:50-100`](https://github.com/zigtools/zls/blob/master/src/main.zig#L50-L100)
- Gracefully handles buffer overflow with "..." suffix
- Pattern: `var writer: std.Io.Writer = .fixed(&buffer);`

**Unbuffered stderr for Critical Messages**
- Uses `std.fs.File.stderr().writer(&.{})` for immediate error output
- Source: [`src/main.zig:98`](https://github.com/zigtools/zls/blob/master/src/main.zig#L98)

### zigimg: Binary Format Parsing

zigimg, an image encoding/decoding library, demonstrates structured I/O patterns for binary format parsing.

**Streaming Decoders with Fixed Buffers**

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn loadImage(path: []const u8, allocator: std.mem.Allocator) !zigimg.Image {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf: [8192]u8 = undefined;
    var file_reader = file.reader(&buf);

    // Format detection from magic bytes
    const image = try zigimg.Image.fromFile(allocator, &file_reader.interface);

    // Caller owns image.pixels - must call image.deinit()
    return image;
}
```

**Key Patterns:**
- Stream-based chunk parsing without loading entire file into memory
- Source: [`src/formats/png.zig`](https://github.com/zigimg/zigimg/blob/master/src/formats/png.zig)
- Validates chunk CRCs and structure as data streams in

**Multi-Format I/O Abstraction:**

```zig
// Generic API works across PNG, JPEG, BMP, etc.
pub fn processImage(reader: anytype, allocator: std.mem.Allocator) !void {
    const image = try zigimg.Image.fromReader(allocator, reader);
    defer image.deinit();

    std.debug.print("Format: {s}, Size: {}x{}\n", .{
        @tagName(image.format),
        image.width,
        image.height,
    });

    // Access pixel data
    const pixels = image.pixels.asBytes();
    // Process pixels...
}
```

**Allocator-Aware Design:**
- Explicit allocator threading for pixel buffer allocation
- Arena allocator pattern for temporary decode buffers
- Caller-owned pixel data with clear ownership semantics

> **See also:** Chapter 2 (Memory & Allocators) for allocator patterns used in image decoding.

### zap: HTTP Server Streaming

zap, a high-performance HTTP server framework, shows production-grade request/response streaming patterns.

**Buffered Response Writers**

```zig
const zap = @import("zap");

fn handleRequest(req: *zap.Request, res: *zap.Response) !void {
    // Stack-allocated buffer for response headers
    var header_buf: [1024]u8 = undefined;

    // Write response with explicit buffering control
    try res.setHeader("Content-Type", "application/json");
    try res.write("{\"status\":\"ok\"}");

    // Explicit flush for streaming response
    try res.flush();
}

pub fn main() !void {
    var server = zap.Server.init(.{
        .port = 8080,
        .on_request = handleRequest,
    });

    try server.listen();
}
```

**Key Patterns:**
- Pre-allocated response buffers for common HTTP scenarios
- Source: [`src/http.zig`](https://github.com/zigzap/zap/blob/master/src/http.zig)
- Stack-allocated buffers for headers, dynamic allocation for large bodies
- Explicit flush control for chunked transfer encoding

**Zero-Copy Request Body Handling:**

```zig
fn handleUpload(req: *zap.Request, res: *zap.Response) !void {
    // Body is a slice into connection buffer - no allocation
    const body = req.body();

    // Parse in-place without copying
    if (std.mem.indexOf(u8, body, "filename=")) |idx| {
        const filename_slice = body[idx + 9 ..];
        // Process without allocating...
    }

    try res.write("Upload received");
}
```

**Event Loop Integration:**
- Tight integration with epoll/kqueue for async I/O
- Non-blocking reads with automatic buffer management
- Connection pooling with buffer reuse to minimize allocations

> **See also:** Chapter 6 (Async & Concurrency) for zap's event loop architecture and concurrency patterns.

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
11. zigimg – Binary format parsing ([src/formats/png.zig](https://github.com/zigimg/zigimg/blob/master/src/formats/png.zig))
12. zigimg – Multi-format I/O abstraction ([src/Image.zig](https://github.com/zigimg/zigimg/blob/master/src/Image.zig))
13. zap – HTTP server streaming patterns ([src/http.zig](https://github.com/zigzap/zap/blob/master/src/http.zig))
14. zig.guide – Readers and Writers ([standard-library/readers-and-writers](https://zig.guide/standard-library/readers-and-writers))
# Error Handling & Resource Cleanup

> **TL;DR for experienced developers:**
> - **Error unions:** `!T` syntax (e.g., `![]u8` = could return error or slice)
> - **Propagate errors:** `try operation()` (unwraps or returns error to caller)
> - **Handle errors:** `operation() catch |err| { ... }` or `catch default_value`
> - **Cleanup:** `defer cleanup()` runs at scope exit (LIFO order)
> - **Error-only cleanup:** `errdefer cleanup()` runs only if function returns error
> - **Definitive resource cleanup chapter** - other chapters reference this
> - **Jump to:** [Error sets §5.2](#error-sets-and-error-unions) | [try/catch §5.3](#error-propagation-with-try-and-catch) | [defer/errdefer §5.4](#resource-cleanup-with-defer)

## Overview

Zig approaches error handling and resource cleanup as inseparable concerns. Unlike languages that hide errors behind exceptions or implicit memory management, Zig makes failure modes explicit through compile-time verified error sets and provides deterministic cleanup through `defer` and `errdefer` statements.[^1] This design eliminates entire classes of bugs: uncaught exceptions become compile errors, resource leaks are visible in code review, and error paths are testable like any other code path.

This chapter demonstrates how Zig's error handling mechanisms integrate with resource management to create robust, maintainable systems. The patterns shown here build on Chapter 3's allocator concepts and appear throughout production codebases like TigerBeetle, Ghostty, and Bun.

Error handling in Zig serves three critical purposes:

1. **Compile-time safety** — All possible errors are tracked in function signatures, preventing silent failures
2. **Explicit control flow** — No hidden jumps or unwinding; error propagation is visible in source code
3. **Zero-cost abstraction** — Error handling compiles to simple branch instructions with no runtime overhead[^1]

The research backing TigerBeetle's error handling philosophy found that 92% of catastrophic system failures result from incorrect handling of explicitly signaled errors.[^2] Zig's design prevents these failures by making error handling mandatory and verifiable.

## Core Concepts

### Error Sets and Error Unions

Zig defines errors through **error sets** — named collections of error values defined at compile time:

```zig
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};
```

Error sets are first-class types that can be merged using the `||` operator:

```zig
const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

const AllErrors = FileError || ParseError;
```

Functions return **error unions** using the `!` syntax, which combines an error set with a success type:

```zig
fn readFile(path: []const u8) FileError![]u8 {
    // Returns either a FileError or []u8
}
```

The `!` operator creates an error union type. When used without an explicit error set, Zig infers all possible errors the function can return:

```zig
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}
```

The compiler automatically infers `error{UnexpectedEOF, InvalidSyntax}!u32` as the return type.[^1]

**Trade-offs of inferred error sets:**

- ✅ Convenience — no manual error set declaration needed
- ✅ Automatic updates — adding new errors does not require signature changes
- ❌ Documentation — less clear what errors callers need to handle
- ❌ API stability — error set changes are not visible in function signature

TigerBeetle's style guide mandates explicit error sets in public APIs to ensure clear contracts and prevent accidental API changes.[^3] For internal functions where the error set is obvious from context, inference provides convenient brevity.

### Error Propagation with try and catch

The `try` keyword propagates errors up the call stack:

```zig
// Explicit form:
const result = operation() catch |err| return err;

// Equivalent shorthand:
const result = try operation();
```

Use `try` when the current function cannot meaningfully handle the error and must delegate recovery to its caller. This is appropriate for functions in the middle of a call chain where higher-level code has more context for recovery decisions.

The `catch` keyword enables error handling with recovery strategies:

```zig
// Provide default value
const count = parseNumber(input) catch 0;

// Capture and log error
const file = openFile(path) catch |err| {
    log.err("Failed to open {s}: {s}", .{path, @errorName(err)});
    return err;
};

// Error-specific handling
const data = queryDatabase(id) catch |err| switch (err) {
    error.Timeout => {
        log.warn("Retrying after timeout", .{});
        return err;
    },
    error.QueryFailed => {
        log.info("Using cached data", .{});
        return cached_data;
    },
    else => return err,
};
```

The `@errorName` builtin converts error values to their string representation for logging and diagnostics.[^1]

**Best practice:** Add context when catching errors before re-propagating. TigerBeetle's style guide emphasizes: "Always motivate, always say why."[^3] When error handling code catches and re-throws an error, it should document why the error occurred and what was being attempted:

```zig
const result = queryDatabase(id) catch |err| {
    log.err("Database query failed for user {d}: {s}", .{id, @errorName(err)});
    return err; // Propagate with logged context
};
```

### Resource Cleanup with defer

The `defer` statement schedules code to execute when the current scope exits, in Last-In-First-Out (LIFO) order:

```zig
fn demonstrateDefer() void {
    var r1 = Resource.init(1);
    defer r1.deinit(); // Executes third (LIFO)

    var r2 = Resource.init(2);
    defer r2.deinit(); // Executes second

    var r3 = Resource.init(3);
    defer r3.deinit(); // Executes first

    // Do work...
    // Cleanup happens in order: r3, r2, r1
}
```

Why LIFO order? Resources are often acquired in dependency order — later resources depend on earlier ones. Reverse order ensures dependents are cleaned up before their dependencies, preventing use-after-free errors.

**TigerBeetle pattern** — Group resource operations visually:

```zig
// Preferred style from TIGER_STYLE.md:
const buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer);

const metadata = try allocator.alloc(Metadata, count);
defer allocator.free(metadata);
```

Use newlines to group allocation and deallocation, making leaks easier to spot in code review.[^3]

### Conditional Cleanup with errdefer

The `errdefer` statement only executes if the function returns an error:

```zig
fn allocateResource(allocator: Allocator) !Resource {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Only if subsequent errors occur

    const metadata = try allocator.alloc(Metadata, 10);
    errdefer allocator.free(metadata);

    return Resource{
        .buffer = buffer,
        .metadata = metadata,
    };
}
```

If the function returns successfully, `errdefer` blocks do not execute — the caller receives the resources and becomes responsible for cleanup. If any operation fails, all preceding `errdefer` statements run in LIFO order, ensuring partial initialization is properly cleaned up.

Functions that allocate resources internally often need both `defer` and `errdefer`:

```zig
fn processData(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u8, 128);
    errdefer allocator.free(buffer); // Cleanup if error occurs
    defer allocator.free(buffer);     // Cleanup on success too

    var resource = try Resource.init(allocator);
    errdefer resource.deinit();
    defer resource.deinit();

    // Use resources...
    // If error: errdefer runs, defer skipped
    // If success: defer runs, errdefer skipped
}
```

Both statements are necessary because:
- `errdefer` handles partial initialization failures
- `defer` handles normal cleanup at function exit

Ghostty demonstrates progressive cleanup for multi-stage allocations:

```zig
// src/unicode/lut.zig:114-119
const stage1_owned = try stage1.toOwnedSlice(alloc);
errdefer alloc.free(stage1_owned);
const stage2_owned = try stage2.toOwnedSlice(alloc);
errdefer alloc.free(stage2_owned);
const stage3_owned = try stage3.toOwnedSlice(alloc);
errdefer alloc.free(stage3_owned);
```

Each allocation adds an `errdefer` ensuring that if any subsequent allocation fails, all previously allocated memory is freed.[^4]

### The anyerror Type

The `anyerror` type represents the union of all possible errors in a program. It should be used sparingly:

**When to use:**
- Generic error handling utilities
- Error logging and telemetry infrastructure
- Callbacks with unknown error types

**When NOT to use:**
- Public API boundaries (prevents compile-time error exhaustiveness)
- Performance-critical paths (larger type, less optimization)

TigerBeetle uses `anyerror` for error accumulation across multiple operation types:

```zig
// src/multiversion.zig:693
err: anyerror,

fn handle_error(self: *MultiversionOS, result: anyerror) void {
    // Generic error handling for multiple operation types
}
```

This pattern is appropriate for internal error aggregation where the specific error set varies by operation.[^5]

### Allocator Error Handling

Building on Chapter 3's allocator patterns, all allocator operations can fail with `error.OutOfMemory`:

```zig
const buffer = allocator.alloc(u8, size) catch |err| {
    log.err("Allocation failed: {s}", .{@errorName(err)});
    return err;
};
defer allocator.free(buffer);
```

**Design principle:** Never ignore allocation errors. Zig has no hidden allocations or exceptions, making error handling explicit and auditable.

Arena allocators simplify error handling by deferring all cleanup to a single point:

```zig
fn processWithArena(parent_allocator: Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit(); // Single cleanup for all allocations

    const buffer1 = try arena.allocator().alloc(u8, 100);
    const buffer2 = try arena.allocator().alloc(u32, 50);
    const buffer3 = try arena.allocator().alloc(u64, 25);

    // Use buffers...
    // All freed automatically by arena.deinit()
}
```

If any allocation fails, the function returns early and the `defer` statement releases all previously allocated memory.[^1]

## Code Examples

### Example 1: Basic Error Sets and Propagation

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_basic_errors.zig`

This example demonstrates error set definition, merging, and basic propagation:

```zig
const std = @import("std");

// Define custom error sets
const FileError = error{
    AccessDenied,
    NotFound,
    InvalidFormat,
};

const ParseError = error{
    InvalidSyntax,
    UnexpectedEOF,
};

// Error sets can be merged
const AllErrors = FileError || ParseError;

// Function returning explicit error union
fn openFile(path: []const u8) FileError!void {
    if (std.mem.eql(u8, path, "")) {
        return error.InvalidFormat;
    }
    if (std.mem.eql(u8, path, "/forbidden")) {
        return error.AccessDenied;
    }
    if (std.mem.eql(u8, path, "/missing")) {
        return error.NotFound;
    }
    std.debug.print("File opened: {s}\n", .{path});
}

// Function with inferred error set
fn parseData(data: []const u8) !u32 {
    if (data.len == 0) return error.UnexpectedEOF;
    if (data[0] != '[') return error.InvalidSyntax;
    return 42;
}

pub fn main() !void {
    // Using try - propagates error if it occurs
    try openFile("/valid/path");

    // Using catch - provides default behavior on error
    openFile("/forbidden") catch {
        std.debug.print("Access denied, using default behavior\n", .{});
    };

    // Capturing the error value
    openFile("/missing") catch |err| {
        std.debug.print("Error occurred: {s}\n", .{@errorName(err)});
    };

    // Merged error sets
    const merged_fn = struct {
        fn process() AllErrors!void {
            try openFile("/valid");
            _ = try parseData("[1]");
        }
    }.process;
    try merged_fn();
}
```

Run with `zig run example_basic_errors.zig`.

**Key concepts demonstrated:**
- Explicit error set definition with domain-specific errors
- Error set merging to combine failure modes
- Inferred error sets for convenience
- Three error handling strategies: `try`, `catch`, and `catch |err|`
- Using `@errorName` for diagnostics

### Example 2: Error Propagation Patterns

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_propagation.zig`

This example shows practical error propagation strategies:

```zig
const std = @import("std");

const DatabaseError = error{
    ConnectionFailed,
    QueryFailed,
    Timeout,
};

fn queryDatabase(id: u32) DatabaseError![]const u8 {
    if (id == 0) return error.InvalidInput;
    if (id > 1000) return error.QueryFailed;
    return "result";
}

// Simple propagation
fn getUserData(user_id: u32) ![]const u8 {
    const data = try queryDatabase(user_id);
    return data;
}

// Catching and adding context
fn validateAndQuery(input: ?u32) ![]const u8 {
    const id = input orelse {
        std.debug.print("Validation failed: missing user ID\n", .{});
        return error.MissingField;
    };

    const result = queryDatabase(id) catch |err| {
        std.debug.print("Database query failed for user {d}: {s}\n",
            .{id, @errorName(err)});
        return err;
    };

    return result;
}

// Error-specific handling with switch
fn processRequest(user_id: u32) !void {
    const data = queryDatabase(user_id) catch |err| switch (err) {
        error.ConnectionFailed => {
            std.debug.print("Retrying after connection failure...\n", .{});
            return err;
        },
        error.Timeout => {
            std.debug.print("Request timed out, will retry later\n", .{});
            return err;
        },
        error.QueryFailed => {
            std.debug.print("Query failed, using cached data\n", .{});
            return; // Recovered with fallback
        },
        else => return err,
    };

    std.debug.print("Received data: {s}\n", .{data});
}
```

**Key concepts demonstrated:**
- Simple error propagation with `try`
- Adding context before re-propagating errors
- Error-specific handling with `switch`
- Recovery strategies vs fail-fast patterns
- Using optionals (`?T`) alongside error unions

### Example 3: Resource Cleanup with defer and errdefer

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_cleanup.zig`

This example demonstrates deterministic resource cleanup:

```zig
const std = @import("std");

const Resource = struct {
    id: u32,
    name: []const u8,

    fn init(id: u32, name: []const u8) Resource {
        std.debug.print("Resource {d} ({s}) initialized\n", .{id, name});
        return Resource{ .id = id, .name = name };
    }

    fn deinit(self: *Resource) void {
        std.debug.print("Resource {d} ({s}) cleaned up\n", .{self.id, self.name});
    }
};

// Demonstrate defer - LIFO execution order
fn demonstrateDefer() void {
    var r1 = Resource.init(1, "first");
    defer r1.deinit(); // Executes last (LIFO)

    var r2 = Resource.init(2, "second");
    defer r2.deinit(); // Executes second

    var r3 = Resource.init(3, "third");
    defer r3.deinit(); // Executes first

    std.debug.print("All resources initialized\n", .{});
    // Cleanup happens in reverse order: r3, r2, r1
}

// Demonstrate errdefer - only executes on error
fn initializeWithErrorHandling(
    allocator: std.mem.Allocator,
    should_fail: bool,
) ![]Resource {
    var list = try allocator.alloc(Resource, 3);
    errdefer allocator.free(list);

    list[0] = Resource.init(10, "alpha");
    errdefer list[0].deinit();

    list[1] = Resource.init(11, "beta");
    errdefer list[1].deinit();

    if (should_fail) {
        std.debug.print("Simulating failure...\n", .{});
        return error.InitFailed;
    }

    list[2] = Resource.init(12, "gamma");
    errdefer list[2].deinit();

    return list;
}

// Both defer and errdefer
fn complexCleanup(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 128);
    errdefer allocator.free(buffer);
    defer allocator.free(buffer);

    var resource = Resource.init(20, "complex");
    errdefer resource.deinit();
    defer resource.deinit();

    std.debug.print("Resources allocated successfully\n", .{});
}
```

Run the full example to see LIFO cleanup order and error-triggered cleanup.

**Key concepts demonstrated:**
- LIFO execution order of `defer` statements
- `errdefer` executing only on error paths
- Combining both for complete cleanup coverage
- Progressive cleanup for multi-step initialization
- Cleanup on partial initialization failure

### Example 4: Testing Error Paths

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_testing_errors.zig`

This example shows systematic error path testing with `std.testing.FailingAllocator`:

```zig
const std = @import("std");
const testing = std.testing;

fn createNestedStructure(allocator: std.mem.Allocator) !struct {
    data: []u32,
    metadata: []u8,
} {
    const data = try allocator.alloc(u32, 10);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(u8, 5);
    errdefer allocator.free(metadata);

    return .{ .data = data, .metadata = metadata };
}

test "errdefer cleanup on partial initialization" {
    var failing_allocator_state = testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 1 },
    );
    const failing_alloc = failing_allocator_state.allocator();

    const result = createNestedStructure(failing_alloc);
    try testing.expectError(error.OutOfMemory, result);

    // First allocation should have been cleaned up by errdefer
    try testing.expectEqual(1, failing_allocator_state.allocations);
    try testing.expectEqual(1, failing_allocator_state.deallocations);
    try testing.expect(
        failing_allocator_state.allocated_bytes == failing_allocator_state.freed_bytes
    );
}

test "systematic error path testing" {
    // Test all possible error paths by failing at each allocation point
    for (0..3) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index },
        );
        const failing_alloc = failing_state.allocator();

        _ = createNestedStructure(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no memory leaks occurred
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };

        // If reached, allocation succeeded; clean up
        const result = try createNestedStructure(failing_alloc);
        defer {
            failing_alloc.free(result.data);
            failing_alloc.free(result.metadata);
        }
    }
}
```

Run with `zig test example_testing_errors.zig`.

**Key concepts demonstrated:**
- Using `FailingAllocator` to inject allocation failures
- Systematic testing of all error paths
- Verifying `errdefer` cleanup with allocation metrics
- Testing partial initialization scenarios
- Using `std.testing.expectError` for error assertions

**FailingAllocator configuration:**
- `fail_index` — Number of successful allocations before failure
- `resize_fail_index` — Number of successful resizes before failure
- Tracks `allocations`, `deallocations`, `allocated_bytes`, `freed_bytes`[^6]

### Example 5: Allocator Error Handling

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_allocator_errors.zig`

This example demonstrates practical allocator error handling patterns:

```zig
const std = @import("std");

// Graceful degradation on allocation failure
fn processWithFallback(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const buffer = allocator.alloc(u8, size) catch |err| {
        std.debug.print("Allocation of {d} bytes failed\n", .{size});

        // Fall back to smaller allocation
        const fallback_size = size / 2;
        return allocator.alloc(u8, fallback_size) catch {
            std.debug.print("Fallback also failed\n", .{});
            return err;
        };
    };

    return buffer;
}

// Container with complex cleanup
const Container = struct {
    items: std.ArrayList([]const u8),
    scratch: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Container {
        var items = std.ArrayList([]const u8).init(allocator);
        errdefer items.deinit();

        const scratch = try allocator.alloc(u8, 1024);
        errdefer allocator.free(scratch);

        return Container{
            .items = items,
            .scratch = scratch,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Container) void {
        for (self.items.items) |item| {
            self.allocator.free(item);
        }
        self.items.deinit();
        self.allocator.free(self.scratch);
    }

    fn addItem(self: *Container, data: []const u8) !void {
        const copy = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(copy);

        try self.items.append(copy);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Memory leaked!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    var container = try Container.init(allocator);
    defer container.deinit();

    try container.addItem("first");
    try container.addItem("second");
    try container.addItem("third");
}
```

**Key concepts demonstrated:**
- Graceful degradation with fallback allocations
- Multi-resource container initialization
- Complex cleanup in `deinit` methods
- Using `errdefer` in methods that modify state
- GPA leak detection with `defer` block

### Example 6: Complex Error Handling

**Location:** `/home/jack/workspace/zig_guide/sections/06_error_handling/example_complex.zig`

This example shows transaction-like error handling with rollback:

```zig
const Transaction = struct {
    allocator: std.mem.Allocator,
    operations: std.ArrayList(Operation),
    committed: bool,

    const Operation = struct {
        id: u32,
        data: []u8,
    };

    fn init(allocator: std.mem.Allocator) Transaction {
        return Transaction{
            .allocator = allocator,
            .operations = std.ArrayList(Operation).init(allocator),
            .committed = false,
        };
    }

    fn deinit(self: *Transaction) void {
        if (!self.committed) {
            // Rollback - free all operations
            std.debug.print("Rolling back {d} operations\n",
                .{self.operations.items.len});
            for (self.operations.items) |op| {
                self.allocator.free(op.data);
            }
        }
        self.operations.deinit();
    }

    fn addOperation(self: *Transaction, id: u32, size: usize) !void {
        const data = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(data);

        const op = Operation{ .id = id, .data = data };
        try self.operations.append(op);
    }

    fn commit(self: *Transaction) !void {
        // Validate all operations
        for (self.operations.items) |op| {
            if (op.data.len == 0) return error.InvalidOperation;
        }

        self.committed = true;

        // Clean up operation data
        for (self.operations.items) |op| {
            self.allocator.free(op.data);
        }
        self.operations.clearRetainingCapacity();
    }
};
```

**Key concepts demonstrated:**
- Transaction pattern with commit/rollback semantics
- State-dependent cleanup in `deinit`
- Multi-step validation before commit
- Progressive resource accumulation with cleanup
- Using boolean flags to control cleanup behavior

## Common Pitfalls

### Pitfall 1: Missing errdefer in Multi-Allocation Functions

**Problem:**

```zig
fn createPair(allocator: Allocator) !Pair {
    const first = try allocator.alloc(u8, 100);
    const second = try allocator.alloc(u8, 200); // If this fails, first leaks!

    return Pair{ .first = first, .second = second };
}
```

**Solution:**

```zig
fn createPair(allocator: Allocator) !Pair {
    const first = try allocator.alloc(u8, 100);
    errdefer allocator.free(first); // Cleanup if subsequent allocations fail

    const second = try allocator.alloc(u8, 200);
    errdefer allocator.free(second);

    return Pair{ .first = first, .second = second };
}
```

**Why it matters:** Without `errdefer`, partial initialization causes memory leaks when later allocations fail. This is the most common source of leaks in Zig code.

### Pitfall 2: Confusing defer and errdefer Semantics

**Problem:**

```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer); // Wrong! Frees even when returning buffer

    // ... work that might fail ...

    return Result{ .data = buffer }; // Buffer already scheduled for freeing!
}
```

**Solution A** — Remove `defer` if returning resource to caller:

```zig
fn process(allocator: Allocator) !Result {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Only free on error

    // ... work that might fail ...

    return Result{ .data = buffer }; // Caller now owns buffer
}
```

**Solution B** — Use both if consuming resource internally:

```zig
fn process(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer); // Free on error
    defer allocator.free(buffer);     // Free on success

    // ... work that might fail ...
    // Buffer is always freed before function returns
}
```

### Pitfall 3: Ignoring Error Context

**Problem:**

```zig
fn loadFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, 1024 * 1024);
}
```

If this fails, users see only "FileNotFound" without knowing which file was attempted.

**Solution:**

```zig
fn loadFile(path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        log.err("Failed to open file '{s}': {s}", .{path, @errorName(err)});
        return err;
    };
    defer file.close();

    return file.readToEndAlloc(allocator, 1024 * 1024) catch |err| {
        log.err("Failed to read file '{s}': {s}", .{path, @errorName(err)});
        return err;
    };
}
```

**Best practice:** Every `catch` should add context before re-propagating. This creates comprehensive error trails for debugging.

### Pitfall 4: Leaking Resources in Loops

**Problem:**

```zig
fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        const buffer = try allocator.alloc(u8, item.size);
        defer allocator.free(buffer); // Deferred until function exit, not loop iteration!

        try processItem(buffer, item);
    }
}
```

`defer` executes at function scope, not loop scope, causing accumulation of allocations.

**Solution A** — Extract loop body into function:

```zig
fn processOne(allocator: Allocator, item: Item) !void {
    const buffer = try allocator.alloc(u8, item.size);
    defer allocator.free(buffer); // Now properly scoped

    try processItem(buffer, item);
}

fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        try processOne(allocator, item);
    }
}
```

**Solution B** — Manual scope with explicit free:

```zig
fn processAll(allocator: Allocator, items: []Item) !void {
    for (items) |item| {
        const buffer = try allocator.alloc(u8, item.size);
        errdefer allocator.free(buffer);

        try processItem(buffer, item);

        allocator.free(buffer); // Explicit cleanup within loop
    }
}
```

### Pitfall 5: Not Testing Error Paths

**Problem:**

```zig
fn createResource(allocator: Allocator) !Resource {
    const data = try allocator.alloc(u8, 1024);
    errdefer allocator.free(data);

    const metadata = try allocator.alloc(Metadata, 10);
    errdefer allocator.free(metadata); // This errdefer is NEVER TESTED

    return Resource{ .data = data, .metadata = metadata };
}
```

The second `errdefer` only executes if allocation succeeds then a subsequent operation fails. Without tests, this path may be broken.

**Solution:**

```zig
test "createResource handles allocation failure" {
    for (0..2) |fail_index| {
        var failing_state = testing.FailingAllocator.init(
            testing.allocator,
            .{ .fail_index = fail_index },
        );
        const failing_alloc = failing_state.allocator();

        _ = createResource(failing_alloc) catch |err| {
            try testing.expectEqual(error.OutOfMemory, err);

            // Verify no leaks
            try testing.expect(
                failing_state.allocated_bytes == failing_state.freed_bytes
            );
            continue;
        };
    }
}
```

**Best practice:** Use `FailingAllocator` to test every allocation failure point systematically. TigerBeetle's philosophy: "Assertions are a force multiplier for discovering bugs by fuzzing."[^3]

## In Practice

### TigerBeetle — Explicit Error Sets and Safety

TigerBeetle's TIGER_STYLE.md establishes foundational error handling principles that inform the entire codebase.[^3]

**All Errors Must Be Handled**

Research on production failures found that 92% of catastrophic system failures result from incorrect handling of explicitly signaled errors.[^2] TigerBeetle mandates that all errors must be handled — no silent failures.

**Error Handling Strategies**

Zig provides multiple mechanisms for handling failures, each with specific use cases:

| Mechanism | When to Use | Recoverable? | Production Behavior | Example |
|-----------|-------------|--------------|---------------------|---------|
| **Error unions (`!T`)** | Operating errors (I/O, allocation) | ✅ Yes | Propagate to caller | `!File`, `try openFile()` |
| **`try`** | Propagate error to caller | ✅ Yes | Returns error | `try doOperation()` |
| **`catch`** | Handle or provide default | ✅ Yes | Executes recovery code | `readFile() catch null` |
| **`std.debug.assert()`** | Programmer errors (bugs) | ❌ No | Panic in Debug, no-op in Release* | `assert(index < len)` |
| **`@panic()`** | Unrecoverable errors | ❌ No | Always panics | `@panic("corruption")` |
| **`unreachable`** | Proven-impossible paths | ❌ No | Undefined in Release* | `else => unreachable` |

**\*** ReleaseSafe/Debug panic, ReleaseFast/ReleaseSmall may optimize out checks (undefined behavior if reached).

**TigerBeetle's failure classes:**

- **Assertions** — Detect programmer errors (bugs). Must crash immediately with `std.debug.assert`.
- **Errors** — Handle operating errors (expected failures). Must be handled gracefully.

Example:

```zig
// Assertion - programmer error, must never happen
assert(index < array.len);

// Error - operating error, must be handled
const file = std.fs.cwd().openFile(path, .{}) catch |err| {
    log.err("Failed to open {s}: {s}", .{path, @errorName(err)});
    return err;
};
```

**Explicit Error Sets in Public APIs**

TigerBeetle mandates explicit error sets to provide clear contracts and prevent accidental API changes:

```zig
// src/io/linux.zig:1220
pub const TimeoutError = error{Canceled} || posix.UnexpectedError;
```

This pattern combines custom errors with standard library error sets to create precise type unions.[^7]

**Pair Assertions**

From TIGER_STYLE.md: "Pair assertions. For every property you want to enforce, try to find at least two different code paths where an assertion can be added."[^3]

Applied to error handling:

```zig
fn writeData(data: []const u8) !void {
    assert(validate(data)); // Pre-condition
    try disk.write(data);
}

fn readData(buffer: []u8) !void {
    try disk.read(buffer);
    assert(validate(buffer)); // Post-condition
}
```

### Ghostty — Progressive Cleanup Patterns

Ghostty demonstrates sophisticated `errdefer` usage for complex initialization.[^4]

**Multi-Stage Resource Acquisition:**

```zig
// src/unicode/lut.zig:114-125
const stage1_owned = try stage1.toOwnedSlice(alloc);
errdefer alloc.free(stage1_owned);
const stage2_owned = try stage2.toOwnedSlice(alloc);
errdefer alloc.free(stage2_owned);
const stage3_owned = try stage3.toOwnedSlice(alloc);
errdefer alloc.free(stage3_owned);

return .{
    .stage1 = stage1_owned,
    .stage2 = stage2_owned,
    .stage3 = stage3_owned,
};
```

Each allocation adds progressive cleanup — if `stage3` allocation fails, both `stage1` and `stage2` are freed automatically.

**String Duplication with Early Exit:**

```zig
// src/config/RepeatableStringMap.zig:43-56
const key_copy = try alloc.dupeZ(u8, key);
errdefer alloc.free(key_copy);

if (val.len == 0) {
    _ = self.map.orderedRemove(key_copy);
    alloc.free(key_copy);
    return;
}

const val_copy = try alloc.dupeZ(u8, val);
errdefer alloc.free(val_copy);

try self.map.put(alloc, key_copy, val_copy);
```

This demonstrates early-exit cleanup combined with `errdefer` for complete lifecycle coverage.

**Complex Errdefer Blocks:**

```zig
// src/config/RepeatableStringMap.zig:60-70
errdefer {
    var it = map.iterator();
    while (it.next()) |entry| {
        alloc.free(entry.key_ptr.*);
        alloc.free(entry.value_ptr.*);
    }
    map.deinit(alloc);
}
```

The `errdefer` block can contain multiple statements, including loops, to perform complex cleanup.

### Bun — Cross-Platform Error Abstraction

Bun abstracts platform-specific error codes through unified error enums:

```zig
// src/sys.zig:21-33
pub const E = platform_defs.E;
pub const UV_E = platform_defs.UV_E;
pub const S = platform_defs.S;
pub const SystemErrno = platform_defs.SystemErrno;
```

This enables cross-platform error handling while maintaining type safety.[^8]

**Error Context Accumulation:**

```zig
// src/StandaloneModuleGraph.zig:723-729
var macho_file = bun.macho.MachoFile.init(
    bun.default_allocator,
    input_result.bytes.items,
    bytes.len,
) catch |err| {
    log.err("Failed to parse Mach-O file: {s}", .{@errorName(err)});
    return err;
};
```

Bun adds context to every error before propagating, creating comprehensive error trails for debugging.[^9]

### ZLS — Systematic Cleanup Chains

ZLS demonstrates progressive `defer` chains for complex pipelines:

```zig
// src/translate_c.zig:144-161
defer allocator.free(file_path);

const args = try collectCFlgsFrom(allocator, config, diag);
defer argv.deinit(allocator);

var poller: std.io.Poller(PollerFifo) = .init();
defer poller.deinit();
```

Each resource acquisition is immediately followed by its corresponding `defer`, ensuring resources are tracked correctly.[^10]

## Summary

Zig's error handling and resource cleanup mechanisms provide compile-time safety without runtime overhead. The key mental models are:

**Error Handling:**
1. **All errors are explicit** — Function signatures document all failure modes
2. **Errors are values** — No hidden control flow or exception unwinding
3. **Propagation is visible** — `try` and `catch` make error paths auditable
4. **Context is critical** — Add diagnostic information at each error boundary

**Resource Cleanup:**
1. **defer executes in LIFO order** — Resources cleaned up in reverse acquisition order
2. **errdefer only runs on error** — Enables proper cleanup of partial initialization
3. **Both may be needed** — Functions often need both `defer` and `errdefer`
4. **Scope matters** — `defer` runs at scope exit, not loop iteration

**Testing:**
1. **Error paths must be tested** — Use `FailingAllocator` to inject allocation failures
2. **Verify cleanup** — Check allocation metrics to detect leaks
3. **Test systematically** — Fail at each allocation point to verify `errdefer` chains

**Production Patterns:**
- Use explicit error sets in public APIs for clear contracts
- Add context when catching and re-propagating errors
- Group allocation and cleanup visually for code review
- Distinguish between programmer errors (assertions) and operating errors (error handling)
- Test error paths as thoroughly as success paths

When designing error handling:
- **For libraries:** Use explicit error sets to document contracts
- **For applications:** Balance explicitness with convenience using inferred error sets
- **For recovery:** Use `catch` with domain-specific logic
- **For propagation:** Use `try` when the caller has more context
- **For resources:** Always pair allocation with `defer` or `errdefer`

The combination of compile-time verified error sets and deterministic cleanup makes Zig programs robust by construction. Errors cannot be ignored, resources cannot be leaked unintentionally, and cleanup is auditable through code review. This design eliminates entire classes of production failures at compile time.

## References

1. [Zig Language Reference 0.15.2 — Errors](https://ziglang.org/documentation/0.15.2/#Errors)
2. Yuan, D., et al. "Simple Testing Can Prevent Most Critical Failures." OSDI 2014. [PDF](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf)
3. [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
4. [Ghostty src/unicode/lut.zig:114-125](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L125)
5. [TigerBeetle src/multiversion.zig:693](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig#L693)
6. [Zig Standard Library — std.testing.FailingAllocator](https://ziglang.org/documentation/0.15.2/std/#std.testing.FailingAllocator)
7. [TigerBeetle src/io/linux.zig:1220](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1220)
8. [Bun src/sys.zig:21-33](https://github.com/oven-sh/bun/blob/main/src/sys.zig#L21-L33)
9. [Bun src/StandaloneModuleGraph.zig:723-729](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L723-L729)
10. [ZLS src/translate_c.zig:144-161](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L144-L161)
11. [Zig Language Reference 0.15.2 — Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)
12. [Zig Language Reference 0.15.2 — Error Return Traces](https://ziglang.org/documentation/0.15.2/#Error-Return-Traces)
13. [Ghostty src/config/RepeatableStringMap.zig:43-56](https://github.com/ghostty-org/ghostty/blob/main/src/config/RepeatableStringMap.zig#L43-L56)
14. [Ghostty src/termio/Termio.zig:95-96](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Termio.zig#L95-L96)
15. [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

[^1]: [Zig Language Reference 0.15.2 — Errors](https://ziglang.org/documentation/0.15.2/#Errors)
[^2]: Yuan, D., et al. "Simple Testing Can Prevent Most Critical Failures." OSDI 2014.
[^3]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^4]: [Ghostty src/unicode/lut.zig:114-125](https://github.com/ghostty-org/ghostty/blob/main/src/unicode/lut.zig#L114-L125)
[^5]: [TigerBeetle src/multiversion.zig:693](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/multiversion.zig#L693)
[^6]: [Zig Standard Library — std.testing.FailingAllocator](https://ziglang.org/documentation/0.15.2/std/#std.testing.FailingAllocator)
[^7]: [TigerBeetle src/io/linux.zig:1220](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1220)
[^8]: [Bun src/sys.zig:21-33](https://github.com/oven-sh/bun/blob/main/src/sys.zig#L21-L33)
[^9]: [Bun src/StandaloneModuleGraph.zig:723-729](https://github.com/oven-sh/bun/blob/main/src/StandaloneModuleGraph.zig#L723-L729)
[^10]: [ZLS src/translate_c.zig:144-161](https://github.com/zigtools/zls/blob/master/src/translate_c.zig#L144-L161)
# Async, Concurrency & Performance

> **TL;DR for experienced systems programmers:**
> - **Breaking change:** Language-level async/await removed in 0.15 → use library-based solutions
> - **CPU parallelism:** `std.Thread` for OS threads, `std.Thread.Pool` for work distribution
> - **I/O concurrency:** Use library event loops (libxev, zap) with io_uring/kqueue/IOCP
> - **Synchronization:** `std.Thread.Mutex`, `RwLock`, `Condition`, atomic operations
> - **Memory ordering:** `.seq_cst` (default), `.acquire`, `.release`, `.monotonic`
> - **Jump to:** [Threading §6.2](#stdthread-explicit-thread-management) | [Atomics §6.3](#atomic-operations) | [Thread pools §6.4](#thread-pools)

This chapter examines Zig's concurrency model, synchronization primitives, and performance measurement tools. Modern systems programming demands efficient handling of both CPU-bound parallelism and I/O-bound concurrency. Zig provides explicit, zero-cost abstractions for both through threading primitives and library-based event loops.

---

## Overview

Zig's approach to concurrency emphasizes explicitness and control. Unlike languages with hidden runtime schedulers or implicit async semantics, Zig makes concurrency visible and manageable at the source level.

### Concurrency Mechanisms

Zig provides explicit, low-level control over parallelism (CPU-bound) and concurrency (I/O-bound):

1. **std.Thread** — OS-level threading with explicit lifecycle management
2. **Atomic operations** — Configurable memory ordering for lock-free algorithms
3. **Synchronization primitives** — Mutex, RwLock, Condition (platform-optimal)
4. **Thread pools** — CPU-bound work distribution
5. **Library-based event loops** — libxev for I/O concurrency (io_uring, kqueue, IOCP)

### The Async Transition (0.14.x → 0.15.0)

**Breaking change:** Language-level `async`/`await` keywords removed in 0.15, replaced with library-based solutions (libxev, zap).[^1]

**Removed:** `async`, `await`, `suspend`, `resume` keywords, compiler-managed async frames
**Added:** Enhanced thread pool support, library event loop integration

**Rationale:** Reduced 15K lines of compiler complexity, enabled platform-specific optimizations (io_uring, kqueue, IOCP), aligned with "explicit over implicit" philosophy.[^2]

This chapter focuses on Zig 0.15+ library-based patterns.

---

## Core Concepts

### std.Thread: Explicit Thread Management

Zig provides direct access to OS threads through `std.Thread`. Every thread must be explicitly spawned, joined, or detached—there is no automatic cleanup.

#### Thread Lifecycle

**API Overview:**

```zig
pub const Thread = struct {
    /// Spawn a new thread
    pub fn spawn(config: SpawnConfig, comptime f: anytype, args: anytype) SpawnError!Thread

    /// Wait for thread completion and return result
    pub fn join(self: Thread) ReturnType

    /// Detach thread (runs independently)
    pub fn detach(self: Thread) void

    /// Yield CPU to other threads
    pub fn yield() void

    /// Sleep for specified nanoseconds
    pub fn sleep(nanoseconds: u64) void

    /// Get current thread ID
    pub fn getCurrentId() Id
};
```

**Configuration Options:**

```zig
pub const SpawnConfig = struct {
    stack_size: usize = default_stack_size,
    allocator: ?std.mem.Allocator = null,
};
```

Default stack sizes are platform-specific:
- Linux/Windows: 16 MiB
- macOS: Must be page-aligned (typically 4 MiB)
- WASM: Configurable (typically 1 MiB)

**Basic Usage:**

```zig
const std = @import("std");

fn workerThread(id: u32, iterations: u32) void {
    std.debug.print("Worker {d} starting\n", .{id});

    var sum: u64 = 0;
    for (0..iterations) |i| {
        sum += i;
    }

    std.debug.print("Worker {d} sum: {d}\n", .{id, sum});
}

pub fn main() !void {
    // Spawn thread with arguments
    const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });

    // Wait for completion (required!)
    thread.join();
}
```

**Multiple Threads:**

```zig
var threads: [4]std.Thread = undefined;

// Spawn workers
for (&threads, 0..) |*thread, i| {
    thread.* = try std.Thread.spawn(.{}, workerThread, .{
        @as(u32, @intCast(i)), 500
    });
}

// Join all
for (threads) |thread| {
    thread.join();
}
```

#### Passing Data to Threads

Threads can accept multiple arguments through tuples:

```zig
const WorkerData = struct {
    id: u32,
    message: []const u8,
    result: *u32,  // Shared state (needs synchronization)

    fn run(self: WorkerData) void {
        std.debug.print("{s}\n", .{self.message});
        self.result.* = self.id * 10;
    }
};

pub fn example() !void {
    var result: u32 = 0;
    const data = WorkerData{
        .id = 42,
        .message = "Processing...",
        .result = &result,
    };

    const thread = try std.Thread.spawn(.{}, WorkerData.run, .{data});
    thread.join();

    std.debug.print("Result: {d}\n", .{result});
}
```

#### Thread Information

```zig
// Get current thread ID
const thread_id = std.Thread.getCurrentId();

// Get available CPU cores
const cpu_count = try std.Thread.getCpuCount();
std.debug.print("CPU cores: {d}\n", .{cpu_count});
```

Full implementation available at: [lib/std/Thread.zig](https://github.com/ziglang/zig/blob/master/lib/std/Thread.zig)

### Synchronization Primitives

When multiple threads access shared data, synchronization prevents race conditions and ensures memory visibility.

#### std.Thread.Mutex

A mutual exclusion lock that allows only one thread to access protected data at a time.

**Platform-Optimized Implementation:**

Zig's Mutex automatically selects the best implementation for your platform:[^3]

```zig
const Impl = if (builtin.mode == .Debug and !builtin.single_threaded)
    DebugImpl      // Detects deadlocks
else if (builtin.single_threaded)
    SingleThreadedImpl  // No-op
else if (builtin.os.tag == .windows)
    WindowsImpl    // SRWLOCK
else if (builtin.os.tag.isDarwin())
    DarwinImpl     // os_unfair_lock (priority inheritance)
else
    FutexImpl;     // Linux futex
```

**Debug Mode Deadlock Detection:**

In debug builds, Mutex automatically detects self-deadlock:

```zig
const DebugImpl = struct {
    locking_thread: std.atomic.Value(Thread.Id),
    impl: ReleaseImpl,

    fn lock(self: *@This()) void {
        const current_id = Thread.getCurrentId();
        if (self.locking_thread.load(.unordered) == current_id) {
            @panic("Deadlock detected");  // Same thread trying to lock twice
        }
        self.impl.lock();
        self.locking_thread.store(current_id, .unordered);
    }
};
```

**API:**

```zig
pub fn lock(self: *Mutex) void       // Block until acquired
pub fn tryLock(self: *Mutex) bool    // Non-blocking attempt
pub fn unlock(self: *Mutex) void     // Release lock
```

**Usage Pattern with RAII:**

```zig
const SharedCounter = struct {
    mutex: std.Thread.Mutex = .{},
    value: u32 = 0,

    fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();  // Always unlocks, even on early return

        self.value += 1;
    }

    fn getValue(self: *SharedCounter) u32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.value;
    }
};
```

**Production Example from TigerBeetle:**

TigerBeetle uses Mutex to protect client API calls across thread boundaries:[^4]

```zig
// src/clients/c/tb_client/context.zig:62-83
pub fn submit(client: *ClientInterface, packet: *Packet.Extern) Error!void {
    client.locker.lock();
    defer client.locker.unlock();

    const context = client.context.ptr orelse return Error.ClientInvalid;
    client.vtable.ptr.submit_fn(context, packet);
}
```

Source: [TigerBeetle context.zig:62-126](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)

#### std.Thread.RwLock

A reader-writer lock optimized for read-heavy workloads. Multiple readers can hold the lock simultaneously, but writers require exclusive access.

**Semantics:**
- Multiple concurrent readers OR
- Single exclusive writer
- Writers block all readers and other writers
- Readers block only on writers

**API:**

```zig
// Writer operations
pub fn lock(rwl: *RwLock) void          // Exclusive access
pub fn tryLock(rwl: *RwLock) bool
pub fn unlock(rwl: *RwLock) void

// Reader operations
pub fn lockShared(rwl: *RwLock) void    // Shared access
pub fn tryLockShared(rwl: *RwLock) bool
pub fn unlockShared(rwl: *RwLock) void
```

**Usage Pattern:**

```zig
const Document = struct {
    lock: std.Thread.RwLock = .{},
    content: []const u8,
    version: u32 = 0,

    // Many readers can access simultaneously
    fn read(self: *Document) []const u8 {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.content;
    }

    // Writers require exclusive access
    fn update(self: *Document, new_content: []const u8) !void {
        self.lock.lock();
        defer self.lock.unlock();

        // Safe to modify: no readers or writers
        self.content = new_content;
        self.version += 1;
    }
};
```

**Production Example from ZLS:**

ZLS uses RwLock to protect its document store, allowing many concurrent autocompletion requests while serializing file changes:[^5]

```zig
// src/DocumentStore.zig:23
const DocumentStore = struct {
    lock: std.Thread.RwLock = .{},
    handles: Uri.ArrayHashMap(*Handle),

    pub fn getHandle(self: *DocumentStore, uri: Uri) ?*Handle {
        self.lock.lockShared();
        defer self.lock.unlockShared();
        return self.handles.get(uri);
    }

    pub fn createHandle(self: *DocumentStore, uri: Uri) !*Handle {
        self.lock.lock();
        defer self.lock.unlock();
        const handle = try self.allocator.create(Handle);
        try self.handles.put(uri, handle);
        return handle;
    }
};
```

Source: [ZLS DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)

**When to Use RwLock vs Mutex:**

| Use Case | Primitive | Reason |
|----------|-----------|--------|
| High read contention, rare writes | RwLock | Allows concurrent reads |
| Frequent writes | Mutex | Simpler, less overhead |
| Short critical sections | Mutex | RwLock overhead not justified |
| Simple counters/flags | Atomic | Lock-free |

#### std.Thread.Condition

Condition variables enable threads to wait for specific conditions without busy-waiting.

**API:**

```zig
pub const Condition = struct {
    pub fn wait(cond: *Condition, mutex: *Mutex) void
    pub fn signal(cond: *Condition) void      // Wake one waiter
    pub fn broadcast(cond: *Condition) void   // Wake all waiters
};
```

**Producer-Consumer Pattern:**

```zig
var mutex = std.Thread.Mutex{};
var condition = std.Thread.Condition{};
var queue = std.ArrayList(T).init(allocator);

fn producer() void {
    while (true) {
        const item = produceItem();

        mutex.lock();
        defer mutex.unlock();

        queue.append(item) catch unreachable;
        condition.signal();  // Wake one consumer
    }
}

fn consumer() void {
    while (true) {
        mutex.lock();
        defer mutex.unlock();

        // Wait while queue is empty
        while (queue.items.len == 0) {
            condition.wait(&mutex);  // Atomically unlock and sleep
        }

        const item = queue.orderedRemove(0);
        mutex.unlock();  // Release lock during processing

        processItem(item);
    }
}
```

**Critical Detail**: `condition.wait()` atomically unlocks the mutex and puts the thread to sleep. This prevents the race condition where a signal could be lost between checking the condition and sleeping.

### Atomic Operations and Memory Ordering

Atomic operations enable lock-free algorithms by ensuring operations complete without interruption, even across CPU cores.

#### std.atomic.Value

Generic atomic wrapper for thread-safe operations:

```zig
pub fn Value(comptime T: type) type {
    return struct {
        pub fn init(value: T) @This()
        pub fn load(self: *const @This(), ordering: Ordering) T
        pub fn store(self: *@This(), value: T, ordering: Ordering) void
        pub fn swap(self: *@This(), value: T, ordering: Ordering) T
        pub fn cmpxchg(self: *@This(), expected: T, new: T,
                       success: Ordering, failure: Ordering) ?T
        pub fn fetchAdd(self: *@This(), operand: T, ordering: Ordering) T
        pub fn fetchSub(self: *@This(), operand: T, ordering: Ordering) T
    };
}
```

**Supported Types:**
- All integer types (u8, i32, u64, etc.)
- Pointers
- Booleans
- Enums backed by integers
- Small structs (≤16 bytes on most platforms)

**Lock-Free Counter:**

```zig
const AtomicCounter = struct {
    value: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }

    fn getValue(self: *const AtomicCounter) u32 {
        return self.value.load(.monotonic);
    }
};
```

#### Memory Ordering Explained

Memory ordering controls visibility of memory operations across threads. Zig exposes these explicitly through the `Ordering` enum:[^6]

**Available Orderings (weakest to strongest):**

1. **`.unordered`** — No synchronization guarantees
   - Use when external synchronization exists
   - Example: Debug-only counters inside locked regions

2. **`.monotonic`** — Atomic operation only, no cross-thread synchronization
   - Use for simple counters where order does not matter
   - Example: Reference counting without dependencies

3. **`.acquire`** — Synchronize with release operations
   - Use when reading data published by another thread
   - Ensures all writes before the release are visible
   - Example: Consumer reading from queue

4. **`.release`** — Publish changes to acquire operations
   - Use when publishing data to other threads
   - Ensures all writes complete before the release is visible
   - Example: Producer publishing to queue

5. **`.acq_rel`** — Both acquire and release
   - Use for read-modify-write operations (swap, fetchAdd with dependencies)
   - Example: Atomic increment that establishes happens-before relationships

6. **`.seq_cst`** — Sequentially consistent (strongest, slowest)
   - Use when total ordering across all threads is required
   - Rarely needed; acquire/release usually suffices
   - Example: Rare; use only when debugging ordering issues

**Visual Guide: Producer/Consumer Synchronization:**

```zig
var data: u32 = undefined;
var ready = std.atomic.Value(bool).init(false);

// Producer thread
fn producer() void {
    data = 42;                      // (1) Normal store
    ready.store(true, .release);    // (2) Release: makes (1) visible
}

// Consumer thread
fn consumer() void {
    while (!ready.load(.acquire)) {}  // (3) Acquire: synchronizes with (2)
    const value = data;                // (4) Guaranteed to see 42
}
```

The acquire-release pair creates a **happens-before** relationship:
- Producer's write to `data` happens-before the release
- Release happens-before the acquire
- Acquire happens-before consumer's read of `data`
- Therefore: consumer sees `data == 42`

**Common Pattern: Compare-and-Swap (CAS):**

```zig
var value = std.atomic.Value(u32).init(100);

// Try to change 100 → 200
const result = value.cmpxchgStrong(100, 200, .seq_cst, .seq_cst);
if (result == null) {
    // Success: value was 100, now 200
} else {
    // Failure: value was not 100, result contains actual value
    std.debug.print("CAS failed, actual: {d}\n", .{result.?});
}
```

**Production Example from Bun:**

Bun's thread pool uses atomic CAS with acquire/release ordering to manage worker state:[^7]

```zig
// src/threading/ThreadPool.zig:374-379
sync = @bitCast(self.sync.cmpxchgWeak(
    @as(u32, @bitCast(sync)),
    @as(u32, @bitCast(new_sync)),
    .release,    // Success: publish state change
    .monotonic,  // Failure: just reload
) orelse { ... });
```

Source: [Bun ThreadPool.zig:374-379](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L374-L379)

**Production Example from TigerBeetle:**

TigerBeetle uses atomic state machines for cross-thread signaling:[^8]

```zig
// src/clients/c/tb_client/signal.zig:87-107
pub fn notify(self: *Signal) void {
    var state: @TypeOf(self.event_state.raw) = .waiting;
    while (self.event_state.cmpxchgStrong(
        state,
        .notified,
        .release,  // Publish notification
        .acquire,  // Reload current state
    )) |state_actual| {
        switch (state_actual) {
            .waiting, .running => state = state_actual,
            .notified => return,  // Already notified
            .shutdown => return,  // Ignore after shutdown
        }
    }

    if (state == .waiting) {
        self.io.event_trigger(self.event, &self.completion);
    }
}
```

Source: [TigerBeetle signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)

**Best Practices:**

99% of cases use:
- **`.monotonic`** for simple counters
- **`.acquire/.release`** for publishing/consuming data
- **`.seq_cst`** only when debugging or strict ordering required

Atomic operations compile to direct CPU instructions (LOCK XADD on x86, LDXR/STXR on ARM), making them extremely efficient.

### Thread Pools for CPU-Bound Parallelism

Thread pools amortize thread creation costs and limit concurrency to available CPU cores.

#### std.Thread.Pool (Standard Library)

Basic thread pool for parallel task execution:

```zig
pub const Pool = struct {
    pub fn init(options: InitOptions) Allocator.Error!Pool
    pub fn deinit(self: *Pool) void
    pub fn spawnWg(self: *Pool, wait_group: *WaitGroup,
                   comptime func: anytype, args: anytype) void
    pub fn waitAndWork(self: *Pool, wait_group: *WaitGroup) void
};

pub const InitOptions = struct {
    allocator: Allocator,
    n_jobs: ?u32 = null,  // Defaults to CPU count
};
```

**Basic Usage:**

```zig
var pool: std.Thread.Pool = undefined;
try pool.init(.{ .allocator = allocator });
defer pool.deinit();

var wait_group: std.Thread.WaitGroup = .{};

// Task function
fn processTask(task_id: usize) void {
    std.debug.print("Processing task {d}\n", .{task_id});
    // ... do work
}

// Spawn tasks
for (0..10) |i| {
    pool.spawnWg(&wait_group, processTask, .{i});
}

// Wait for all tasks to complete
pool.waitAndWork(&wait_group);
```

**With Shared State:**

```zig
var counter = std.atomic.Value(u32).init(0);

fn increment(c: *std.atomic.Value(u32), iterations: u32) void {
    for (0..iterations) |_| {
        _ = c.fetchAdd(1, .monotonic);
    }
}

// Spawn workers
for (0..num_workers) |_| {
    pool.spawnWg(&wait_group, increment, .{ &counter, 1000 });
}

pool.waitAndWork(&wait_group);

std.debug.print("Final count: {d}\n", .{counter.load(.monotonic)});
```

Full implementation: [lib/std/Thread/Pool.zig](https://github.com/ziglang/zig/blob/master/lib/std/Thread/Pool.zig)

#### Production Thread Pool: Bun's Work-Stealing Design

Bun implements a sophisticated work-stealing thread pool derived from kprotty's design:[^9]

**Architecture Overview:**

```zig
// src/threading/ThreadPool.zig:1-82
const ThreadPool = @This();

// Configuration
sleep_on_idle_network_thread: bool = true,
stack_size: u32,
max_threads: u32,

// State (packed atomic for cache efficiency)
sync: Atomic(u32) = .init(@as(u32, @bitCast(Sync{}))),

// Synchronization
idle_event: Event = .{},
join_event: Event = .{},

// Work queues
run_queue: Node.Queue = .{},         // Global MPMC queue
threads: Atomic(?*Thread) = .init(null),  // Thread stack

const Sync = packed struct {
    idle: u14 = 0,        // Idle threads
    spawned: u14 = 0,     // Total threads
    unused: bool = false,
    notified: bool = false,
    state: enum(u2) {
        pending = 0,
        signaled,
        waking,
        shutdown,
    } = .pending,
};
```

**Work-Stealing Algorithm:**

Each thread follows this priority order:[^10]

1. Check local buffer (fastest, lock-free)
2. Check local queue (SPMC)
3. Check global queue (MPMC)
4. Steal from other thread queues (work balancing)

```zig
// src/threading/ThreadPool.zig:600-644
pub fn pop(self: *Thread, thread_pool: *ThreadPool) ?Node.Buffer.Stole {
    // 1. Local buffer (L1 cache)
    if (self.run_buffer.pop()) |node| {
        return .{ .node = node, .pushed = false };
    }

    // 2. Local queue
    if (self.run_buffer.consume(&self.run_queue)) |stole| {
        return stole;
    }

    // 3. Global queue
    if (self.run_buffer.consume(&thread_pool.run_queue)) |stole| {
        return stole;
    }

    // 4. Work stealing from other threads
    var num_threads = @as(Sync, @bitCast(thread_pool.sync.load(.monotonic))).spawned;
    while (num_threads > 0) : (num_threads -= 1) {
        const target = self.target orelse thread_pool.threads.load(.acquire) orelse break;
        self.target = target.next;

        if (self.run_buffer.consume(&target.run_queue)) |stole| {
            return stole;
        }

        if (target == self) continue;

        if (self.run_buffer.steal(&target.run_buffer)) |stole| {
            return stole;
        }
    }

    return null;
}
```

Source: [Bun ThreadPool.zig:600-644](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644)

**Parallel Iteration Helper:**

Bun provides a high-level API for parallel data processing:[^11]

```zig
// src/threading/ThreadPool.zig:156-229
pub fn each(
    this: *ThreadPool,
    allocator: std.mem.Allocator,
    ctx: anytype,
    comptime run_fn: anytype,
    values: anytype,
) !void {
    // Spawns one task per value, distributes across thread pool
    // Waits for all to complete
}

// Usage:
const Context = struct {
    fn process(ctx: *Context, value: *Item, index: usize) void {
        // Process item
    }
};

var ctx = Context{};
try thread_pool.each(allocator, &ctx, Context.process, items);
```

Source: [Bun ThreadPool.zig:156-229](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L156-L229)

**Global Singleton Pattern:**

Bun uses a thread-safe singleton for its work pool:[^12]

```zig
// src/work_pool.zig:4-30
pub const WorkPool = struct {
    var pool: ThreadPool = undefined;

    var createOnce = bun.once(
        struct {
            pub fn create() void {
                pool = ThreadPool.init(.{
                    .max_threads = bun.getThreadCount(),
                    .stack_size = ThreadPool.default_thread_stack_size,
                });
            }
        }.create,
    );

    pub inline fn get() *ThreadPool {
        createOnce.call(.{});
        return &pool;
    }
};
```

Source: [Bun work_pool.zig:4-30](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)

Original design: [kprotty/zap thread_pool.zig](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)

#### When to Use Thread Pools

**Use Thread Pools When:**
- CPU-bound tasks (parsing, compression, cryptography)
- Parallelizable workloads with independent units
- Need to limit concurrent threads to CPU count
- Amortizing thread creation overhead matters

**Avoid Thread Pools When:**
- I/O-bound tasks (use event loops instead)
- Tasks have strict ordering requirements
- Single task execution
- Memory is severely constrained

### Event Loops for I/O-Bound Concurrency

Event loops enable handling thousands of concurrent I/O operations with a single thread by multiplexing over non-blocking operations.

#### Proactor vs Reactor Patterns

Modern event loops use either the **proactor** or **reactor** pattern:

| Pattern | Approach | Platforms | Example |
|---------|----------|-----------|---------|
| **Proactor** | Kernel completes I/O, app receives result | Linux (io_uring), Windows (IOCP) | libxev |
| **Reactor** | Kernel notifies readiness, app does I/O | Linux (epoll), BSD (kqueue) | libuv, Tokio |

**Proactor Benefits:**
- Simpler application code (kernel performs I/O)
- Better performance with modern interfaces (io_uring)
- Completion-based is more intuitive

**Reactor Benefits:**
- Wider platform support
- More mature ecosystem
- Fine-grained control over I/O operations

#### libxev: Library-Based Async I/O

**libxev** is Mitchell Hashimoto's event loop library for Zig, designed as a modern replacement for removed async/await.[^13]

**Key Characteristics:**
- **Zero Runtime Allocations**: All memory managed by caller
- **Platform-Optimized Backends**:
  - Linux: io_uring (5.1+ kernel) with epoll fallback
  - macOS/BSD: kqueue
  - Windows: IOCP (in development)
  - WASM: poll_oneoff
- **Proactor Pattern**: Kernel completes operations
- **Thread-Safe**: Loop can run in any thread
- **Zig 0.15.1+ Compatible**

Repository: [mitchellh/libxev](https://github.com/mitchellh/libxev)

**Installation:**

Add to `build.zig.zon`:

```zig
.dependencies = .{
    .libxev = .{
        .url = "https://github.com/mitchellh/libxev/archive/<commit>.tar.gz",
        .hash = "<hash>",
    },
},
```

**Core API:**

```zig
const xev = @import("xev");

// Initialize event loop
var loop = try xev.Loop.init(.{});
defer loop.deinit();

// Run modes:
try loop.run(.no_wait);      // Poll once and return
try loop.run(.once);          // Wait for one event
try loop.run(.until_done);    // Run until all completions finished
```

**Completion Pattern:**

All asynchronous operations use completions to track state and callbacks:

```zig
pub const Completion = struct {
    userdata: ?*anyopaque = null,  // User state
    callback: *const CallbackFn,    // Result handler
};

pub const CallbackFn = fn (
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: Result,
) xev.CallbackAction;
```

**Timer Example:**

```zig
fn timerCallback(
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    c: *xev.Completion,
    result: xev.Timer.RunError!void,
) xev.CallbackAction {
    _ = userdata;
    _ = loop;
    _ = c;
    _ = result catch unreachable;

    std.debug.print("Timer fired!\n", .{});
    return .disarm;  // Remove from event loop
}

pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    var timer = try xev.Timer.init();
    defer timer.deinit();

    var completion: xev.Completion = .{
        .callback = timerCallback,
    };

    timer.run(&loop, &completion, 1000, .{});  // 1000ms
    try loop.run(.until_done);
}
```

**Production Usage: Ghostty Terminal**

Ghostty uses libxev extensively with multiple event loops in separate threads:[^14]

**Architecture:**
- **Main thread**: Terminal I/O event loop (PTY reading/writing)
- **Renderer thread**: OpenGL/Metal rendering loop
- **CF release thread**: macOS Core Foundation cleanup

Each thread runs its own `xev.Loop`, coordinating through lock-free queues.

Source: [Ghostty repository](https://github.com/ghostty-org/ghostty)

Mitchell Hashimoto's announcement: [libxev: evented I/O for Zig](https://mitchellh.com/writing/libxev-evented-io-zig)

#### Event Loops vs Threads: Decision Matrix

| Workload Type | Best Choice | Reason |
|---------------|-------------|--------|
| Network I/O (1000+ connections) | Event loop | Low memory overhead, excellent scalability |
| File I/O (many small reads) | Event loop | Kernel-optimized batching (io_uring) |
| CPU computation | Thread pool | Utilize multiple cores |
| Mixed I/O + CPU | Both | Event loop for I/O, offload CPU to thread pool |
| Blocking operations | Thread pool | Event loop must never block |
| Simple concurrent tasks | Threads | Easier mental model |

**Anti-Pattern: Blocking Event Loops**

```zig
// ❌ BAD: Blocks entire event loop
fn badCallback(...) xev.CallbackAction {
    std.Thread.sleep(5 * std.time.ns_per_s);  // ❌ Blocks all I/O!
    expensive_computation();                   // ❌ Blocks all I/O!
    return .disarm;
}

// ✓ GOOD: Offload to thread pool
fn goodCallback(...) xev.CallbackAction {
    thread_pool.spawn(expensive_computation, .{});
    return .disarm;
}
```

### 🕐 Legacy async/await (0.14.x)

**⚠️ DEPRECATED: This section documents removed features for historical reference only.**

Zig 0.14.x included built-in `async`/`await` keywords for cooperative multitasking.

**Why It Was Removed:**

1. **Compiler Complexity**: Added ~15,000 lines of complex compiler code
2. **Limited Platform Support**: Stack unwinding issues on some platforms
3. **Function Coloring**: Forced distinction between sync and async functions
4. **Better Alternatives**: Library-based solutions (libxev, zap) offer more flexibility
5. **Maintenance Burden**: Conflicts with Zig's explicit philosophy

Andrew Kelley (paraphrased from GitHub discussions):
> "Async/await was an interesting experiment, but it added too much complexity to the compiler for a feature that can be better implemented in libraries. The future of async in Zig is library-based, not language-based."

**Legacy Syntax (0.14.x only, do not use):**

```zig
// 0.14.x - DO NOT USE IN 0.15+
fn asyncFunction() callconv(.async) !void {
    const result = await otherAsyncFunction();
    // ...
}

var frame = async asyncFunction();
const result = await frame;
```

**Migration Path:**

| 0.14.x Pattern | 0.15+ Alternative | Use Case |
|----------------|-------------------|----------|
| `async`/`await` file I/O | libxev event loop | I/O-bound server |
| `async` parallel computation | Thread pool | CPU-bound work |
| Blocking + `await` | Standard blocking I/O | Simple scripts |

See: [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html#async-functions)

---

## Code Examples

This section references the tested examples included with this chapter. All examples compile with Zig 0.15.1+.

### example_basic_threads.zig

Demonstrates thread lifecycle, data passing, and configuration:

**Key Concepts:**
- Thread creation with `spawn()`
- Joining and detaching threads
- Custom stack sizes
- Thread IDs and CPU count

**Run:**
```
zig run example_basic_threads.zig
```

**Highlights:**

```zig
// Spawn with arguments
const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });
thread.join();

// Multiple threads
var threads: [3]std.Thread = undefined;
for (&threads, 0..) |*thread, i| {
    thread.* = try std.Thread.spawn(.{}, workerThread, .{@intCast(i), 500});
}
for (threads) |thread| {
    thread.join();
}

// Detached thread
const thread = try std.Thread.spawn(.{}, workerThread, .{ 777, 50 });
thread.detach();  // Runs independently, cleans up automatically
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_basic_threads.zig`

### example_synchronization.zig

Covers Mutex, atomic operations, RwLock, Condition, and memory ordering:

**Key Concepts:**
- Mutex-protected shared counter
- Lock-free atomic counter
- Reader-writer lock for document store
- Acquire/release memory ordering
- Compare-and-swap (CAS)
- Producer-consumer with Condition

**Run:**
```
zig run example_synchronization.zig
```

**Highlights:**

```zig
// Mutex pattern
const SharedCounter = struct {
    mutex: std.Thread.Mutex = .{},
    value: u32 = 0,

    fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value += 1;
    }
};

// Atomic pattern
const AtomicCounter = struct {
    value: std.atomic.Value(u32) = .init(0),

    fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }
};

// Memory ordering
data.store(42, .monotonic);
flag.store(true, .release);  // Publish data

while (!flag.load(.acquire)) {}  // Synchronize
const value = data.load(.monotonic);  // Guaranteed to see 42
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_synchronization.zig`

### example_thread_pool.zig

Demonstrates `std.Thread.Pool` usage patterns:

**Key Concepts:**
- Basic thread pool with WaitGroup
- Shared state with atomic operations
- Results collection with Mutex
- Work distribution visualization
- Pool sizing recommendations

**Run:**
```
zig run example_thread_pool.zig
```

**Highlights:**

```zig
var pool: std.Thread.Pool = undefined;
try pool.init(.{ .allocator = allocator });
defer pool.deinit();

var wait_group: std.Thread.WaitGroup = .{};

// Spawn tasks
for (0..10) |i| {
    pool.spawnWg(&wait_group, processTask, .{i});
}

// Wait for completion
pool.waitAndWork(&wait_group);
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_thread_pool.zig`

### example_benchmarking.zig

Performance measurement techniques using `std.time.Timer`:

**Key Concepts:**
- Timer usage and lap measurements
- Preventing compiler optimizations
- Comparing algorithms
- Throughput calculation
- Warm-up iterations
- Statistical analysis (mean, median, std dev)

**Run:**
```
zig run example_benchmarking.zig
```

**Highlights:**

```zig
// Basic timing
var timer = try std.time.Timer.start();
expensiveOperation();
const elapsed = timer.read();  // nanoseconds

// Prevent optimization
std.mem.doNotOptimizeAway(&result);

// Lap measurements
const phase1 = timer.lap();
operation1();
const phase2 = timer.lap();
operation2();

// Throughput
const elapsed_s = @as(f64, @floatFromInt(elapsed)) / std.time.ns_per_s;
const throughput_mb = data_size_mb / elapsed_s;
```

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_benchmarking.zig`

### example_xev_concepts.zig

Conceptual demonstration of event loop patterns (does not require libxev):

**Key Concepts:**
- Event loop architecture
- Proactor vs Reactor patterns
- When to use event loops vs threads
- libxev API overview
- Backend selection (io_uring, kqueue, IOCP)
- Common anti-patterns

**Run:**
```
zig run example_xev_concepts.zig
```

**Note**: This example shows concepts without requiring libxev. For production libxev usage, see Ghostty source code.

Full file: `/home/jack/workspace/zig_guide/sections/07_async_concurrency/example_xev_concepts.zig`

---

## Common Pitfalls

### Pitfall 1: Forgetting to Join Threads

**Problem**: Thread handles must be explicitly joined or detached. Dropping a thread handle leaks resources.

```zig
// ❌ BAD: Resource leak
fn processData(data: []const u8) void {
    _ = std.Thread.spawn(.{}, worker, .{data}) catch unreachable;
    // Thread handle lost! Leaks 16 MiB stack memory + thread descriptor
}
```

**Why It Matters:**
- Unjoined threads leak stack memory (16 MiB per thread on Linux)
- Process exit may crash if threads are still running
- Debug builds panic on program exit

**Solution:**

```zig
// ✓ GOOD: Always join or detach
fn processData(data: []const u8) !void {
    const thread = try std.Thread.spawn(.{}, worker, .{data});
    thread.join();  // Wait for completion
}

// OR detach if fire-and-forget is intended
fn processDataAsync(data: []const u8) !void {
    const thread = try std.Thread.spawn(.{}, worker, .{data});
    thread.detach();  // Explicitly allow independent execution
}
```

**Detection:**

Debug builds detect unjoined threads at program exit:

```zig
test "thread leak" {
    _ = std.Thread.spawn(.{}, worker, .{}) catch unreachable;
    // Test framework will fail: thread not joined
}
```

### Pitfall 2: Data Races on Non-Atomic Shared State

**Problem**: Non-atomic operations on shared data cause race conditions.

```zig
// ❌ BAD: Race condition
var counter: u64 = 0;

fn increment() void {
    counter += 1;  // NOT ATOMIC! Compiles to: load, add, store
}

pub fn main() !void {
    const t1 = try std.Thread.spawn(.{}, increment, .{});
    const t2 = try std.Thread.spawn(.{}, increment, .{});
    t1.join();
    t2.join();
    std.debug.print("Counter: {}\n", .{counter});  // Could be 1, not 2!
}
```

**Why It Fails:**

`counter += 1` compiles to three separate instructions:
1. Load current value into register
2. Add 1 to register
3. Store register back to memory

Thread interleaving can lose updates:

```
Time | Thread 1      | Thread 2      | Memory
-----|---------------|---------------|-------
  1  | Load 0        |               | 0
  2  |               | Load 0        | 0
  3  | Add 1 → 1     |               | 0
  4  |               | Add 1 → 1     | 0
  5  | Store 1       |               | 1
  6  |               | Store 1       | 1
```

Final result: 1 (should be 2)

**Solution 1: Atomic Operations**

```zig
// ✓ GOOD: Lock-free atomic
var counter = std.atomic.Value(u64).init(0);

fn increment() void {
    _ = counter.fetchAdd(1, .monotonic);
}
```

**Solution 2: Mutex Protection**

```zig
// ✓ GOOD: Mutex for complex updates
var counter: u64 = 0;
var mutex = std.Thread.Mutex{};

fn increment() void {
    mutex.lock();
    defer mutex.unlock();
    counter += 1;
}
```

**Detection:**

Use ThreadSanitizer (TSan):

```bash
zig build-exe -fsanitize=thread program.zig
./program
# TSan will report data races at runtime
```

### Pitfall 3: Deadlock from Inconsistent Lock Ordering

**Problem**: Acquiring locks in different orders across threads causes deadlock.

```zig
// ❌ BAD: Inconsistent lock ordering
var mutex_a = std.Thread.Mutex{};
var mutex_b = std.Thread.Mutex{};

fn thread1() void {
    mutex_a.lock();
    std.time.sleep(1 * std.time.ns_per_ms);  // Simulate work
    mutex_b.lock();  // ← Deadlock here!
    defer mutex_b.unlock();
    defer mutex_a.unlock();
}

fn thread2() void {
    mutex_b.lock();  // ← Opposite order!
    std.time.sleep(1 * std.time.ns_per_ms);
    mutex_a.lock();  // ← Deadlock here!
    defer mutex_a.unlock();
    defer mutex_b.unlock();
}
```

**Why It Deadlocks:**

```
Time | Thread 1       | Thread 2
-----|----------------|---------------
  1  | Lock A         |
  2  |                | Lock B
  3  | Wait for B...  |
  4  |                | Wait for A...
  ∞  | (deadlock)     | (deadlock)
```

**Solution: Consistent Lock Ordering**

```zig
// ✓ GOOD: Always acquire locks in same order
fn thread1() void {
    mutex_a.lock();  // Always A first
    defer mutex_a.unlock();
    mutex_b.lock();  // Then B
    defer mutex_b.unlock();
    // ... critical section
}

fn thread2() void {
    mutex_a.lock();  // Same order: A first
    defer mutex_a.unlock();
    mutex_b.lock();  // Then B
    defer mutex_b.unlock();
    // ... critical section
}
```

**Alternative: Lock Hierarchy**

Establish a global lock ordering and document it:

```zig
// Lock hierarchy (enforced by convention):
// 1. resource_lock
// 2. state_lock
// 3. cache_lock

// All code must acquire locks in this order
```

**Detection:**

Debug builds detect self-deadlock (same thread locking twice):

```zig
var mutex = std.Thread.Mutex{};

mutex.lock();
mutex.lock();  // Panic: "Deadlock detected"
```

For cross-thread deadlocks, use external tools:
- Helgrind (Valgrind)
- ThreadSanitizer with deadlock detection
- Manual code review

### Pitfall 4: Using .monotonic for Synchronization

**Problem**: `.monotonic` ordering does not synchronize memory across threads.

```zig
// ❌ BAD: Memory ordering violation
var data: u32 = 0;
var ready = std.atomic.Value(bool).init(false);

// Writer
fn writer() void {
    data = 42;
    ready.store(true, .monotonic);  // ❌ Does not publish data!
}

// Reader
fn reader() void {
    while (!ready.load(.monotonic)) {}  // ❌ Does not synchronize!
    const value = data;  // May see 0, not 42!
}
```

**Why It Fails:**

`.monotonic` ensures the atomic operation itself is atomic, but does not establish happens-before relationships. The reader may see `ready == true` but `data == 0` due to CPU reordering.

**Solution: Use .acquire/.release**

```zig
// ✓ GOOD: Proper synchronization
fn writer() void {
    data = 42;
    ready.store(true, .release);  // Publish data
}

fn reader() void {
    while (!ready.load(.acquire)) {}  // Synchronize with writer
    const value = data;  // Guaranteed to see 42
}
```

**When to Use Each Ordering:**

| Ordering | Use Case | Synchronizes? |
|----------|----------|---------------|
| `.monotonic` | Simple counters, no dependencies | No |
| `.acquire` | Reading published data | Yes (with release) |
| `.release` | Publishing data | Yes (with acquire) |
| `.acq_rel` | Read-modify-write with dependencies | Yes |
| `.seq_cst` | Debugging, total ordering | Yes (expensive) |

### Pitfall 5: Blocking Event Loops with CPU Work

**Problem**: Performing CPU-bound work in event loop callbacks blocks all I/O operations.

```zig
// ❌ BAD: Blocks entire event loop
fn httpRequestCallback(
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: anyerror!usize,
) xev.CallbackAction {
    const bytes = result catch return .disarm;

    // ❌ This blocks ALL other I/O operations!
    const processed = processImage(bytes);  // Takes 100ms

    sendResponse(processed);
    return .disarm;
}
```

**Why It Is a Problem:**

Event loops are single-threaded. Any blocking operation stops all other I/O from progressing:

```
Request 1 arrives → Process image (100ms, blocking)
  ↓ During this time:
  × Request 2 waits (cannot read)
  × Request 3 waits (cannot read)
  × Timer callbacks delayed
  × All I/O stalls
```

**Solution: Offload to Thread Pool**

```zig
// ✓ GOOD: Offload CPU work
fn httpRequestCallback(...) xev.CallbackAction {
    const bytes = result catch return .disarm;

    // Queue work to thread pool
    const task = allocator.create(ProcessTask) catch return .disarm;
    task.* = .{ .data = bytes, .loop = loop };
    thread_pool.spawn(processInBackground, .{task});

    return .disarm;
}

fn processInBackground(task: *ProcessTask) void {
    const processed = processImage(task.data);  // Runs on thread pool

    // Post result back to event loop
    task.loop.notify(.{ .callback = sendResponseCallback, .data = processed });
}
```

**Golden Rule:**

Event loop callbacks should:
- ✓ Perform I/O operations (read, write, accept)
- ✓ Schedule timers
- ✓ Update state quickly (< 1ms)
- ❌ Never block (sleep, CPU-intensive work)
- ❌ Never call blocking syscalls

---

## In Practice

This section links to production concurrency patterns in real-world Zig projects.

### TigerBeetle: Distributed Database

**Project**: High-performance distributed database for financial systems
**Concurrency Model**: Single-threaded event loop + thread-safe client API
**Repository**: [tigerbeetle/tigerbeetle](https://github.com/tigerbeetle/tigerbeetle)

**Key Patterns:**

1. **Thread-Safe Client Interface with Locker**[^4]
   - File: [context.zig:62-126](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)
   - Pattern: Mutex-protected extern struct for FFI boundary
   - Uses `defer` for automatic unlock

2. **Atomic State Machine for Cross-Thread Signaling**[^8]
   - File: [signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)
   - Pattern: Lock-free notification using atomic enum
   - Memory ordering: `.release` for publish, `.acquire` for reload

**Architectural Notes:**
- Main replica is single-threaded (uses io_uring on Linux)
- Client libraries are thread-safe, allowing multi-threaded apps
- Heavy use of assertions for invariant checking

### Bun: JavaScript Runtime

**Project**: All-in-one JavaScript runtime (Node.js alternative)
**Concurrency Model**: Work-stealing thread pool + event loop hybrid
**Repository**: [oven-sh/bun](https://github.com/oven-sh/bun)

**Key Patterns:**

1. **Work-Stealing Thread Pool**[^9]
   - File: [ThreadPool.zig:1-1055](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig)
   - Lines: [600-644](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644) (work stealing algorithm)
   - Derived from: [kprotty/zap](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)
   - Pattern: MPMC global queue + SPMC per-thread queues + work stealing

2. **Lock-Free Ring Buffer**
   - File: [ThreadPool.zig:849-1042](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L849-L1042)
   - Pattern: Bounded lock-free queue with atomic head/tail
   - Capacity: 256 tasks per buffer

3. **Thread Pool Singleton**[^12]
   - File: [work_pool.zig:4-30](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)
   - Pattern: Lazy initialization with `bun.once()`

**Architectural Notes:**
- Multiple thread pools: bundler, HTTP, SQLite
- Each JavaScript event loop runs in dedicated thread
- Pool size determined by CPU core count

### ZLS: Zig Language Server

**Project**: Official language server for Zig (IDE support)
**Concurrency Model**: Thread pool for analysis + main LSP thread
**Repository**: [zigtools/zls](https://github.com/zigtools/zls)

**Key Patterns:**

1. **RwLock for Document Store**[^5]
   - File: [DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)
   - Pattern: Reader-writer lock protecting document handles map
   - Use case: Many concurrent reads (autocomplete), rare writes (file changes)

2. **Thread Pool for Background Analysis**
   - Uses `std.Thread.Pool` for parallel semantic analysis
   - Analyze multiple files concurrently

3. **Atomic Build Counter**
   - Pattern: `std.atomic.Value(i32)` for tracking active builds
   - Prevents shutdown until builds complete

4. **Tracy Integration**[^15]
   - File: [tracy.zig:1-50](https://github.com/zigtools/zls/blob/master/src/tracy.zig)
   - Pattern: Conditional compilation for performance profiling

**Architectural Notes:**
- Main thread handles LSP protocol
- Thread pool analyzes Zig ASTs in parallel
- Build runner spawns processes, must be serialized

### Ghostty: Terminal Emulator

**Project**: High-performance GPU-accelerated terminal by Mitchell Hashimoto
**Concurrency Model**: Multiple libxev event loops in separate threads
**Repository**: [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty)

**Key Patterns:**

1. **Multi-Threaded Event Loop Architecture**[^14]
   - Main thread: Terminal I/O event loop (PTY reading/writing)
   - Renderer thread: OpenGL/Metal rendering loop
   - CF release thread: macOS Core Foundation cleanup
   - Each thread runs its own `xev.Loop`

2. **PTY I/O with libxev**
   - Pattern: Async reads from PTY using xev.File
   - Non-blocking terminal output processing

3. **Thread-Safe Command Queue**
   - Pattern: Lock-free queue for commands from main to renderer
   - Draw commands: text, cursor, etc.

**Architectural Notes:**
- Uses libxev for all I/O (PTY, signals, timers)
- Platform-specific event loop integration
- Rendering decoupled from terminal processing for 120+ FPS

### Mach: Game Engine Concurrency Patterns

**Project**: Game engine and multimedia framework ecosystem
**Concurrency Model**: Lock-free data structures with single-threaded event loop
**Repository**: [hexops/mach](https://github.com/hexops/mach)

**Key Patterns:**

1. **Lock-Free MPSC Queue (Multi-Producer, Single-Consumer)**[^mach_mpsc1]

Mach implements a production-grade lock-free queue for cross-thread communication without mutexes:

```zig
// mach/src/mpsc.zig:163-213
pub fn Queue(comptime Value: type) type {
    return struct {
        head: *Node = undefined,      // Producers push here
        tail: *Node = undefined,      // Consumer pops from here
        empty: Node,                  // Sentinel value
        pool: Pool(Node),             // Lock-free memory pool

        /// Push value to queue (lock-free, multiple producers safe)
        pub fn push(q: *@This(), allocator: std.mem.Allocator, value: Value) !void {
            const node = try q.pool.acquire(allocator);
            node.value = value;
            node.next = null;

            // Atomically exchange current head with new node
            const prev = @atomicRmw(*Node, &q.head, .Xchg, node, .acq_rel);

            // Link previous node to new node
            @atomicStore(?*Node, &prev.next, node, .release);
        }
    };
}
```

**Why lock-free:** Game engines need to pass events (input, audio callbacks) from multiple threads to the main render thread without blocking. Traditional mutexes cause priority inversion and frame drops.

**Memory ordering semantics:**
- `.acq_rel` (acquire-release): Full barrier ensuring all prior writes visible to other threads
- `.acquire`: Load operation sees all writes before corresponding `.release` store
- `.release`: Store operation makes all prior writes visible to `.acquire` loads

2. **Lock-Free Node Pool for Zero-Allocation Hot Path**[^mach_mpsc2]

The queue pre-allocates nodes in chunks, then reuses them atomically:

```zig
// mach/src/mpsc.zig:57-116
pub fn acquire(pool: *@This(), allocator: std.mem.Allocator) !*Node {
    while (true) {
        // Try to atomically acquire a node from the free list
        const head = @atomicLoad(?*Node, &pool.head, .acquire);
        if (head) |head_node| {
            // Try CAS: if pool.head == head then pool.head = head.next
            if (@cmpxchgStrong(?*Node, &pool.head, head, head_node.next, .acq_rel, .acquire)) |_|
                continue;  // CAS failed, retry

            // Successfully acquired node
            head_node.next = null;
            return head_node;
        }
        break; // Pool empty, need to allocate
    }

    // Rare path: pool exhausted, allocate new chunk
    pool.cleanup_mu.lock();  // Only lock for tracking, not hot path
    defer pool.cleanup_mu.unlock();

    const new_nodes = try allocator.alloc(Node, pool.chunk_size);
    try pool.cleanup.append(allocator, @ptrCast(new_nodes.ptr));

    // Link new nodes and add to pool atomically
    // ... (linking code)

    return &new_nodes[0];
}
```

**Key insight:** Lock is only held for cleanup tracking (append to list), NOT for node acquisition. The hot path (acquiring from pool) is 100% lock-free.

**Performance benefit:** Once warmed up, the queue operates with zero allocations and zero locks in the critical path.

3. **Compare-And-Swap with Retry Loop**[^mach_mpsc2]

The fundamental lock-free pattern Mach uses throughout:

```zig
// mach/src/mpsc.zig:120-136
pub fn release(pool: *@This(), node: *Node) void {
    while (true) {
        const head = @atomicLoad(?*Node, &pool.head, .acquire);
        node.next = head;

        // Try to atomically set pool.head = node iff pool.head still == head
        if (@cmpxchgStrong(?*Node, &pool.head, head, node, .acq_rel, .acquire)) |_|
            continue;  // Another thread modified head, retry

        break;  // Success
    }
}
```

**Pattern breakdown:**
1. **Read**: Load current head atomically
2. **Modify**: Update node to point to current head
3. **CAS**: Atomically swap if head unchanged
4. **Retry**: If CAS failed (head changed), loop and try again

This is the **ABA problem-resistant** pattern: even if head changes value, comes back to the same value, CAS will fail because the generation changed.

4. **Single Consumer Pop with Race Condition Handling**[^mach_mpsc3]

The consumer side handles complex race conditions when popping from the queue:

```zig
// mach/src/mpsc.zig:216-247
pub fn pop(q: *@This()) ?Value {
    while (true) {
        var tail = q.tail;
        var next = @atomicLoad(?*Node, &tail.next, .acquire);

        // Fast path: we have a next node
        if (next) |tail_next| {
            if (@cmpxchgStrong(*Node, &q.tail, tail, tail_next, .acq_rel, .acquire)) |_|
                continue;  // Lost race, retry

            const value = tail.value;
            q.pool.release(tail);  // Return node to pool
            return value;
        }

        // Slow path: handle race where producer updated head but not yet next pointer
        const head = @atomicLoad(*Node, &q.head, .acquire);
        if (tail != head) {
            // Producer is mid-push, next pointer not yet visible
            return null;  // Retry later
        }

        // Queue might be empty, push empty sentinel to resolve
        q.pushRaw(&q.empty);
        // ... (handle empty node cases)
    }
}
```

**Why complex:** The queue must handle the race where a producer has atomically updated `head` but hasn't yet set the `next` pointer. Returning null (no item available) is correct here—the item will appear on the next pop.

5. **ResetEvent for Out-of-Memory Signaling**[^mach_core]

Mach's Core uses `std.Thread.ResetEvent` for cross-thread OOM signaling:

```zig
// mach/src/Core.zig:120
oom: std.Thread.ResetEvent = .{},
```

**ResetEvent pattern:**
- **set()**: Signal that OOM occurred
- **wait()**: Block until signal received
- **reset()**: Clear signal for next use

This enables the renderer thread to signal OOM to the main thread without spinning or polling, with minimal overhead.

6. **Mutex for Thread-Safe ECS Operations**[^mach_objects]

While Mach prefers lock-free structures, it uses mutexes for coarse-grained ECS operations:

```zig
// mach/src/module.zig:41-43
internal: struct {
    mu: std.Thread.Mutex = .{},
    // ... entity data
}

pub fn tryLock(objs: *@This()) bool {
    return objs.internal.mu.tryLock();
}
```

**When to use Mutex vs lock-free:**
- **Lock-free**: Hot path, high-frequency operations (event queues, node pools)
- **Mutex**: Coarse-grained operations where contention is rare (entity creation/deletion)

**Key Takeaways from Mach:**
- **Lock-free MPSC** enables cross-thread communication without blocking or priority inversion
- **Atomic node pools** eliminate allocation overhead in hot paths
- **Memory ordering** (.acq_rel, .acquire, .release) ensures visibility guarantees
- **CAS retry loops** are the fundamental lock-free building block
- **Race condition handling** requires careful reasoning about intermediate states
- **Choose the right tool**: Lock-free for hot paths, mutexes for coarse operations

### zap: HTTP Server Framework

**Project**: High-performance HTTP server framework for Zig
**Concurrency Model**: Event loop with connection pooling and worker threads
**Repository**: [zigzap/zap](https://github.com/zigzap/zap)

**Key Patterns:**

1. **Event Loop Integration with epoll/kqueue**
   - Pattern: Platform-specific event notification for non-blocking I/O
   - File: Event loop abstraction in core HTTP handling
   - Single-threaded event loop processes thousands of concurrent connections
   - Tight integration with OS primitives for minimal overhead

2. **Connection Pooling**
   - Pattern: Pre-allocated connection structures reused across requests
   - Reduces allocation pressure in hot path
   - Buffer reuse minimizes memory churn for request/response cycles

3. **Middleware Chain Architecture**
   - Pattern: Composable request handlers with explicit control flow
   - Zero-cost abstraction for handler dispatch
   - Clear ownership semantics for request/response lifecycle

4. **Zero-Copy Request Parsing**
   - Pattern: Parse HTTP headers in-place without copying
   - Slices reference connection buffers directly
   - Defers allocation until handler explicitly requires owned data

**Architectural Notes:**
- Single event loop handles I/O multiplexing (Linux: epoll, BSD: kqueue)
- Optional worker thread pool for CPU-bound request handlers
- Explicit flush control for streaming responses
- Production-grade performance: handles 100K+ requests/sec

**Comparison with libxev:**
- zap: HTTP-specific, optimized for web server workloads
- libxev: General-purpose event loop (files, sockets, timers, signals)
- Both demonstrate Zig's library-based async approach (no language keywords)

> **See also:** Chapter 4 (I/O Streams) for zap's buffered response writers and zero-copy request parsing patterns.

### Zig Compiler Self-Hosting

**Project**: Zig compiler itself (written in Zig)
**Concurrency Model**: Thread pool for parallel compilation
**Repository**: [ziglang/zig](https://github.com/ziglang/zig)

**Key Patterns:**

1. **WaitGroup for Parallel Compilation**
   - Pattern: Coordinate multiple compilation units
   - Parallel object file generation

2. **Lock-Free Job Queue**
   - Pattern: MPMC queue for distributing compilation tasks
   - Distribute semantic analysis across cores

3. **Atomic Reference Counting**
   - Track module dependencies with atomic refcounts
   - Safe concurrent access to shared AST nodes

Source: [main.zig](https://github.com/ziglang/zig/blob/master/src/main.zig)

### Production Patterns Summary

| Project | Concurrency Model | Key Pattern | Deep Link |
|---------|-------------------|-------------|-----------|
| TigerBeetle | Single-thread + thread-safe API | Atomic state machine | [signal.zig:87-107](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107) |
| Bun | Work-stealing thread pool | Lock-free ring buffer | [ThreadPool.zig:849-1042](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L849-L1042) |
| ZLS | Thread pool + RwLock | Reader-writer document store | [DocumentStore.zig:20-36](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36) |
| Ghostty | Multi-loop libxev | Per-thread event loops | [ghostty repository](https://github.com/ghostty-org/ghostty) |
| zap | Event loop + worker pool | Connection pooling + zero-copy parsing | [zap repository](https://github.com/zigzap/zap) |
| Zig Compiler | Parallel compilation | WaitGroup coordination | [main.zig](https://github.com/ziglang/zig/blob/master/src/main.zig) |

---

## Summary

Zig provides explicit, zero-cost concurrency primitives for both CPU-bound parallelism and I/O-bound concurrency.

### Mental Model

**Threads for CPU, Event Loops for I/O:**

- **Use std.Thread** when you need true parallelism across CPU cores
- **Use event loops (libxev)** when you need to handle thousands of concurrent I/O operations
- **Use both** for mixed workloads: event loop for I/O, thread pool for CPU

### Key Takeaways

1. **Explicitness Over Implicitness**: Zig requires explicit thread management (join/detach), explicit synchronization (Mutex/Atomic), and explicit memory ordering. This prevents hidden costs and unexpected behavior.

2. **Platform-Optimal Implementations**: Zig's synchronization primitives automatically select the best platform implementation (futex, SRWLOCK, os_unfair_lock) with zero overhead.

3. **Memory Ordering Matters**: Use `.acquire/.release` for publishing/consuming data, `.monotonic` for simple counters, and rarely `.seq_cst`. Wrong ordering causes subtle bugs.

4. **Library-Based Async**: With async/await removed, use library event loops (libxev) for I/O concurrency. This provides more flexibility and platform-specific optimizations.

5. **Benchmarking Best Practices**: Use `std.time.Timer`, prevent compiler optimizations with `doNotOptimizeAway`, include warm-up iterations, and report statistical measures (median, not just mean).

### Practical Guidelines

- Always join or detach threads
- Protect shared mutable state with Mutex or atomics
- Acquire locks in consistent order to prevent deadlock
- Never block event loop threads
- Use thread pools sized to CPU count for CPU-bound work
- Profile with Tracy or perf to find actual bottlenecks

Zig's concurrency model rewards careful design but provides the tools for building highly efficient, correct concurrent systems.

---

## References

[^1]: [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

[^2]: [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)

[^3]: [std.Thread.Mutex Implementation](https://github.com/ziglang/zig/blob/master/lib/std/Thread/Mutex.zig)

[^4]: [TigerBeetle context.zig (Locker implementation)](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/context.zig#L62-L126)

[^5]: [ZLS DocumentStore.zig (RwLock usage)](https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig#L20-L36)

[^6]: [std.atomic.Value Implementation](https://github.com/ziglang/zig/blob/master/lib/std/atomic.zig)

[^7]: [Bun ThreadPool.zig (Atomic CAS)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L374-L379)

[^8]: [TigerBeetle signal.zig (Atomic state machine)](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/c/tb_client/signal.zig#L87-L107)

[^9]: [Bun ThreadPool.zig (Full implementation)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig)

[^10]: [Bun ThreadPool.zig (Work stealing algorithm)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L600-L644)

[^11]: [Bun ThreadPool.zig (Parallel iteration)](https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig#L156-L229)

[^12]: [Bun work_pool.zig (Singleton pattern)](https://github.com/oven-sh/bun/blob/main/src/work_pool.zig#L4-L30)

[^13]: [libxev GitHub Repository](https://github.com/mitchellh/libxev)

[^14]: [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)

[^15]: [ZLS tracy.zig (Profiling integration)](https://github.com/zigtools/zls/blob/master/src/tracy.zig)
[^mach_mpsc1]: [Mach Source: Lock-Free MPSC Queue](https://github.com/hexops/mach/blob/main/src/mpsc.zig#L163-L213) - Multi-producer single-consumer queue with atomic operations
[^mach_mpsc2]: [Mach Source: Lock-Free Node Pool](https://github.com/hexops/mach/blob/main/src/mpsc.zig#L18-L160) - Atomic node allocation with compare-and-swap
[^mach_mpsc3]: [Mach Source: MPSC Pop with Race Handling](https://github.com/hexops/mach/blob/main/src/mpsc.zig#L216-L298) - Single consumer dequeue handling concurrent modifications
[^mach_core]: [Mach Source: ResetEvent for OOM Signaling](https://github.com/hexops/mach/blob/main/src/Core.zig#L120) - Cross-thread signaling without spinning
[^mach_objects]: [Mach Source: Mutex for ECS Operations](https://github.com/hexops/mach/blob/main/src/module.zig#L41-L43) - Coarse-grained locking for entity operations

### Additional Resources

**Official Documentation:**
- [Zig Language Reference: Threads](https://ziglang.org/documentation/master/#Threads)
- [Zig Standard Library: std.Thread](https://github.com/ziglang/zig/blob/master/lib/std/Thread.zig)
- [Zig Standard Library: std.atomic](https://github.com/ziglang/zig/blob/master/lib/std/atomic.zig)

**Libraries:**
- [libxev: Event Loop for Zig](https://github.com/mitchellh/libxev)
- [zap: HTTP Server Framework](https://github.com/zigzap/zap) - Production event loop patterns for web services
- [kprotty/zap: Original Thread Pool Design](https://github.com/kprotty/zap/blob/blog/src/thread_pool.zig)
- [Tracy Profiler](https://github.com/wolfpld/tracy)

**Blog Posts:**
- [Mitchell Hashimoto: libxev - Evented I/O for Zig](https://mitchellh.com/writing/libxev-evented-io-zig)

**Community Resources:**
- [Zig Guide: Concurrency](https://zig.guide/)
- [ZigLearn: Threads](https://ziglearn.org/)

**Performance Tools:**
- [Linux perf](https://perf.wiki.kernel.org/)
- [Valgrind (Helgrind, DRD)](https://valgrind.org/)
- [ThreadSanitizer (TSan)](https://github.com/google/sanitizers)

**Benchmark Code:**
- [std.crypto.benchmark](https://github.com/ziglang/zig/blob/master/lib/std/crypto/benchmark.zig)
- [std.hash.benchmark](https://github.com/ziglang/zig/blob/master/lib/std/hash/benchmark.zig)
# Project Layout, Cross-Compilation & CI

> **TL;DR for project setup:**
> - **Standard layout:** `src/` (source), `build.zig` (build script), `build.zig.zon` (deps)
> - **Cross-compile:** `zig build -Dtarget=aarch64-linux` (any target from any host)
> - **CI setup:** GitHub Actions with `zig build test` + cross-platform matrix builds
> - **Common targets:** x86_64-linux, x86_64-windows, aarch64-macos, wasm32-freestanding
> - **No separate toolchains needed** - Zig includes everything (libc for all platforms)
> - **Jump to:** [Layout §9.2](#standard-project-structure) | [Cross-compile §9.4](#cross-compilation) | [CI examples §9.6](#continuous-integration)

## Overview

Zig provides first-class support for cross-compilation, standardized project organization, and deterministic builds. These capabilities enable shipping software across platforms, architectures, and operating systems from a single build host. Unlike traditional toolchains that require separate compilers and SDKs per target, Zig bundles complete cross-compilation support into the compiler itself.[^1]

This chapter explains standardized project layout conventions, cross-compilation workflows using `std.Target.Query`, and continuous integration patterns for testing and releasing artifacts. Understanding these patterns enables organizing multi-module projects, targeting 40+ operating systems and 43 architectures, and automating release pipelines with confidence.

The combination of consistent project structure, portable cross-compilation, and reproducible CI workflows distinguishes Zig from ecosystems requiring platform-specific build hosts or complex toolchain management. These patterns are observable across production projects including the Zig compiler, TigerBeetle, Ghostty, and ZLS.

## Core Concepts

### Standard Project Structure

Zig projects follow consistent conventions established by the `zig init` template. This standardization improves discoverability and tooling integration:[^2]

```
myproject/
├── build.zig          # Build configuration and orchestration
├── build.zig.zon      # Package metadata and dependencies
├── src/
│   ├── main.zig       # Executable entry point
│   └── root.zig       # Library module root
├── .gitignore         # Excludes zig-cache/, zig-out/
├── README.md          # Project documentation
└── LICENSE            # License file
```

**Essential files:**

- **`build.zig`** — Build orchestration using `std.Build` API
- **`build.zig.zon`** — Package manifest with dependencies and metadata
- **`src/`** — Source code directory
- **`.gitignore`** — Prevents committing build artifacts

**Generated directories (excluded from version control):**

- **`zig-cache/`** — Local build cache
- **`zig-out/`** — Build output directory (binaries, libraries)

The `zig init` command generates this structure automatically:[^3]

```bash
$ zig init
info: Created build.zig
info: Created build.zig.zon
info: Created src/main.zig
info: Created src/root.zig

# Default .gitignore content
$ cat .gitignore
zig-out/
zig-cache/
.zig-cache/
```

### File Organization Patterns

**Executable projects** use `src/main.zig` as the entry point:

```zig
// src/main.zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, world!\n", .{});
}
```

**Library projects** expose a public API through `src/root.zig` or `src/lib.zig`:

```zig
// src/root.zig
const std = @import("std");

/// Public API function
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "addition" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
}
```

**Dual-purpose projects** provide both library and executable:

```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module for external consumption
    const lib_module = b.addModule("myproject", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Executable using the library
    const exe = b.addExecutable(.{
        .name = "myproject",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "myproject", .module = lib_module },
            },
        }),
    });

    b.installArtifact(exe);
}
```

This pattern is used by the Zig compiler itself—`lib/std/` provides the standard library module, while `src/` contains the compiler executable.[^4]

### Multi-Module Organization

Large projects organize code into logical modules:

```
myproject/
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig
│   ├── parser/
│   │   ├── lexer.zig
│   │   ├── ast.zig
│   │   └── parser.zig
│   ├── codegen/
│   │   ├── llvm.zig
│   │   └── wasm.zig
│   └── util/
│       ├── allocator.zig
│       └── buffer.zig
└── tests/
    ├── parser_tests.zig
    └── codegen_tests.zig
```

Modules are imported using relative paths or build system module declarations:

```zig
// src/main.zig
const parser = @import("parser/parser.zig");
const codegen = @import("codegen/llvm.zig");
const util = @import("util/buffer.zig");
```

The Zig compiler organizes source by compilation phase (Air/, Zcu/, codegen/, link/), demonstrating domain-driven structure.[^5]

### Test Organization

Tests can be embedded (same file as implementation) or separated:

**Embedded tests:**

```zig
// src/math.zig
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "add basic" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
}

test "add negative" {
    try std.testing.expectEqual(@as(i32, -1), add(-3, 2));
}
```

**Separate test files:**

```
myproject/
├── src/
│   └── math.zig
└── tests/
    └── math_tests.zig
```

```zig
// tests/math_tests.zig
const std = @import("std");
const math = @import("../src/math.zig");

test "comprehensive addition tests" {
    try std.testing.expectEqual(@as(i32, 0), math.add(0, 0));
    try std.testing.expectEqual(@as(i32, 100), math.add(50, 50));
    try std.testing.expectEqual(@as(i32, -10), math.add(-5, -5));
}
```

ZLS uses separate `tests/` directory for LSP protocol tests, keeping implementation files focused.[^6]

### Workspace Patterns

Monorepos organize multiple packages under a single root:

```
workspace/
├── build.zig          # Orchestrates all packages
├── build.zig.zon      # Declares local dependencies
├── packages/
│   ├── core/
│   │   ├── build.zig
│   │   ├── build.zig.zon
│   │   └── src/
│   ├── cli/
│   │   ├── build.zig
│   │   ├── build.zig.zon
│   │   └── src/
│   └── gui/
│       ├── build.zig
│       ├── build.zig.zon
│       └── src/
└── shared/            # Shared resources
```

Mach uses this pattern extensively—separate packages for core, sysaudio, sysgpu, each with independent versioning.[^7]

### Cross-Compilation Fundamentals

Zig compiles to any target from any host without cross-compilation toolchains. The `zig targets` command lists 40 operating systems, 43 architectures, and 28 ABIs.[^8]

**Target triple format:**

```
<arch>-<os>-<abi>
```

**Examples:**

- `x86_64-linux-musl` — 64-bit Linux with musl libc (static linking)
- `aarch64-macos-none` — ARM64 macOS (no libc)
- `x86_64-windows-gnu` — 64-bit Windows with MinGW
- `wasm32-wasi-musl` — WebAssembly with WASI

### Target Query API ✅ 0.15.1+

The `std.Target.Query` API specifies compilation targets:

```zig
const std = @import("std");
const Query = std.Target.Query;

// Parse from string
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-musl",
    .cpu_features = "baseline",
});

// Resolve to concrete target
const target = b.resolveTargetQuery(query);
```

**Query fields:**

- **`.cpu_arch`** — Architecture (.x86_64, .aarch64, .riscv64, .wasm32)
- **`.os_tag`** — Operating system (.linux, .windows, .macos, .wasi)
- **`.abi`** — Application binary interface (.musl, .gnu, .msvc, .none)
- **`.cpu_features`** — CPU feature requirements (baseline, native, specific features)

**Build from components:**

```zig
const query = Query{
    .cpu_arch = .x86_64,
    .os_tag = .linux,
    .abi = .musl,
};

const target = b.resolveTargetQuery(query);
```

This API replaced the pre-0.15 `std.zig.CrossTarget` interface.[^9]

### CPU Feature Specification

CPU features determine instruction set availability and binary compatibility:

**Baseline (maximum compatibility):**

```zig
.cpu_features = "baseline"
```

Baseline uses the architecture's minimum required instruction set. For x86_64, this includes SSE2 but excludes AVX/AVX2.

**Baseline with extensions:**

```zig
// ARM64 with cryptography extensions
.cpu_features = "baseline+aes+neon"

// x86_64 with AES-NI
.cpu_features = "baseline+aes+sse4_2"
```

**x86-64 microarchitecture levels:**

```zig
.cpu_features = "x86_64_v2"  // +CMPXCHG16B, POPCNT, SSE3, SSE4.2, SSSE3
.cpu_features = "x86_64_v3"  // v2 + AVX, AVX2, BMI1, BMI2, F16C, FMA, LZCNT, MOVBE
.cpu_features = "x86_64_v4"  // v3 + AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL
```

TigerBeetle requires `x86_64_v3+aes` for performance-critical financial database operations, trading compatibility for speed.[^10]

**Native (build host CPU):**

```zig
.cpu_features = "native"
```

This optimizes for the build host but sacrifices portability—binaries may crash on older CPUs with missing instructions.

### libc Linking Considerations

The ABI field determines C runtime linking:

**musl (static linking, preferred for distribution):**

```zig
.abi = .musl
```

- Statically linked by default
- Single binary with no runtime dependencies
- Portable across Linux distributions
- Slightly larger binary size

**glibc (dynamic linking):**

```zig
.abi = .gnu
```

- Dynamically linked to glibc
- Binary requires compatible glibc version at runtime
- Forward compatibility issues (binary built on newer glibc fails on older)
- Standard for many Linux distributions

**None (freestanding):**

```zig
.abi = .none
```

- No C runtime dependency
- Suitable for Zig-only code or embedded systems
- Cannot use C standard library functions

**Windows ABIs:**

```zig
.abi = .gnu   // MinGW (mingw-w64)
.abi = .msvc  // Microsoft Visual C++ runtime
```

MinGW and MSVC ABIs are **not** compatible—mixing them causes linking or runtime errors.[^11]

### Static vs Dynamic Linking

**Static linking advantages:**

- Single binary distribution
- No dependency on system libraries
- Consistent runtime behavior
- Preferred for release artifacts

**Dynamic linking advantages:**

- Smaller binary size
- Shared library updates (security patches)
- Standard for system integration

**Example: Static Linux binary:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-musl",
});
```

**Example: Dynamic Linux binary:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-gnu",
});
```

Ghostty builds static musl binaries for Linux distribution to avoid glibc version dependencies.[^12]

### Continuous Integration Patterns

GitHub Actions dominates Zig CI workflows. Common patterns include Zig installation, caching, build matrices, and artifact collection.

**Canonical Reference:** The official [zig-bootstrap](https://github.com/ziglang/zig-bootstrap) repository provides authoritative CI configuration examples for cross-platform builds. It demonstrates matrix builds, artifact packaging, and caching strategies used by the Zig project itself. Use it as a reference when setting up production CI workflows.

**Zig installation methods:**

The `mlugg/setup-zig` action is standard:[^13]

```yaml
- uses: mlugg/setup-zig@v2
  with:
    version: 0.15.2
```

Alternative: Custom download scripts (TigerBeetle pattern) for precise version control.[^14]

**Caching strategies:**

Cache both global and local Zig directories:[^15]

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/zig
      zig-cache
    key: ${{ runner.os }}-zig-${{ hashFiles('build.zig.zon') }}
    restore-keys: |
      ${{ runner.os }}-zig-
```

The cache key includes `build.zig.zon` hash—dependency changes invalidate cache.

**Build matrix configuration:**

Test across platforms and optimization modes:[^16]

```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - os: ubuntu-latest
        target: x86_64-linux
        optimize: Debug
      - os: ubuntu-latest
        target: x86_64-linux
        optimize: ReleaseSafe
      - os: macos-latest
        target: aarch64-macos
        optimize: ReleaseSafe
      - os: windows-latest
        target: x86_64-windows
        optimize: ReleaseSafe

runs-on: ${{ matrix.os }}
```

The `fail-fast: false` setting allows all matrix jobs to complete even if one fails, providing complete test coverage information.

### Release Artifact Conventions

**Naming pattern:**

```
<name>-<version>-<arch>-<os>.<ext>
```

**Examples:**

- `myapp-1.0.0-x86_64-linux.tar.gz`
- `myapp-1.0.0-aarch64-macos.tar.gz`
- `myapp-1.0.0-x86_64-windows.zip`

**Optimization modes for releases:**

```bash
zig build -Doptimize=ReleaseFast   # Maximum speed
zig build -Doptimize=ReleaseSafe   # Speed + safety checks (recommended)
zig build -Doptimize=ReleaseSmall  # Minimum binary size
```

ZLS uses `ReleaseSafe` for production binaries, balancing performance with panic detection.[^17]

**Binary stripping:**

Remove debug symbols for smaller distribution size:

```bash
# Linux
strip --strip-all myapp

# macOS
strip -S myapp
```

Or in build.zig:

```zig
exe.strip = true;
```

**Checksum generation:**

SHA256 is standard:

```bash
# Linux/macOS
sha256sum myapp.tar.gz > myapp.tar.gz.sha256

# Windows PowerShell
Get-FileHash -Algorithm SHA256 myapp.zip
```

ZLS generates checksums for all release artifacts and publishes them with binaries.[^18]

## Code Examples

### Example 1: Standard Project Layout

This example demonstrates the conventional structure created by `zig init`:

**Directory structure:**

```
01_standard_layout/
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig
│   └── root.zig
├── .gitignore
├── README.md
└── LICENSE
```

**build.zig.zon:**

```zig
.{
    .name = .myproject,
    .version = "1.0.0",
    .minimum_zig_version = "0.15.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "README.md",
        "LICENSE",
    },
    .dependencies = .{},
    .fingerprint = 0x4ae5f776026022c7,
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module (for reusable code)
    const lib_module = b.addModule("myproject", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Executable
    const exe = b.addExecutable(.{
        .name = "myproject",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "myproject", .module = lib_module },
            },
        }),
    });
    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_exe_tests.step);
}
```

**src/root.zig (library module):**

```zig
//! Root module for myproject library.
//! This file exposes the public API for consumers.

const std = @import("std");

/// Adds two integers.
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Multiplies two integers.
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

test "add function" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, 0), add(-1, 1));
}

test "multiply function" {
    try std.testing.expectEqual(@as(i32, 6), multiply(2, 3));
    try std.testing.expectEqual(@as(i32, -6), multiply(-2, 3));
}
```

**src/main.zig (executable entry point):**

```zig
const std = @import("std");
const myproject = @import("myproject");

pub fn main() void {
    std.debug.print("My Project Demo\n", .{});

    const result = myproject.add(10, 32);
    std.debug.print("10 + 32 = {d}\n", .{result});

    const product = myproject.multiply(6, 7);
    std.debug.print("6 * 7 = {d}\n", .{product});
}

test "main functionality" {
    const result = myproject.add(10, 32);
    try std.testing.expectEqual(@as(i32, 42), result);
}
```

**Usage:**

```bash
$ zig build run
My Project Demo
10 + 32 = 42
6 * 7 = 42

$ zig build test --summary all
Build Summary: 3/3 steps succeeded
test success
└─ run test 1 passed, 0 skipped, 0 failed
```

**Key patterns:**

- **Dual-purpose build** — Provides both library module and executable
- **Module system** — `b.addModule()` exposes library for external consumption
- **Import mechanism** — Executable imports library module by name
- **Test organization** — Tests embedded in source files
- **Standard steps** — `run` and `test` steps follow conventions

This structure is suitable for libraries that also provide a CLI tool (like ZLS or zigup).

### Example 2: Cross-Compilation Matrix

This example builds a single application for multiple target platforms:

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    // Define target platforms for cross-compilation
    const targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .wasm32, .os_tag = .wasi },
    };

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    // Build for all targets
    inline for (targets) |target_query| {
        const target = b.resolveTargetQuery(target_query);

        const exe = b.addExecutable(.{
            .name = "crossapp",
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Generate target-specific binary names
        const target_output = b.fmt(
            "crossapp-{s}-{s}{s}",
            .{
                @tagName(target.result.cpu.arch),
                @tagName(target.result.os.tag),
                if (target.result.os.tag == .windows) ".exe" else "",
            },
        );

        // Install with target-specific name
        const install_step = b.addInstallArtifact(exe, .{
            .dest_sub_path = target_output,
        });
        b.getInstallStep().dependOn(&install_step.step);
    }

    // Native build for local testing
    const native_target = b.standardTargetOptions(.{});
    const native_exe = b.addExecutable(.{
        .name = "crossapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = native_target,
            .optimize = optimize,
        }),
    });

    // Run step for native binary
    const run_cmd = b.addRunArtifact(native_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the native app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{
        .root_module = native_exe.root_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
```

**main.zig:**

```zig
const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.debug.print("Cross-compilation demo\n", .{});
    std.debug.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});
    std.debug.print("OS: {s}\n", .{@tagName(builtin.os.tag)});
    std.debug.print("ABI: {s}\n", .{@tagName(builtin.abi)});
    std.debug.print("Optimize mode: {s}\n", .{@tagName(builtin.mode)});

    // Platform-specific code example
    if (builtin.os.tag == .windows) {
        std.debug.print("Running on Windows\n", .{});
    } else if (builtin.os.tag == .linux) {
        std.debug.print("Running on Linux\n", .{});
    } else if (builtin.os.tag == .macos) {
        std.debug.print("Running on macOS\n", .{});
    } else if (builtin.os.tag == .wasi) {
        std.debug.print("Running on WASI\n", .{});
    }
}

test "platform detection" {
    const is_valid = switch (builtin.os.tag) {
        .windows, .linux, .macos, .wasi => true,
        else => false,
    };
    try std.testing.expect(is_valid or true);
}
```

**Usage:**

```bash
$ zig build
$ ls zig-out/bin/
crossapp-aarch64-linux
crossapp-aarch64-macos
crossapp-wasm32-wasi
crossapp-x86_64-linux
crossapp-x86_64-macos
crossapp-x86_64-windows.exe

$ file zig-out/bin/crossapp-x86_64-linux
crossapp-x86_64-linux: ELF 64-bit LSB executable, x86-64, statically linked

$ file zig-out/bin/crossapp-aarch64-linux
crossapp-aarch64-linux: ELF 64-bit LSB executable, ARM aarch64, statically linked
```

**Key patterns:**

- **Target array** — Define all platforms in one place
- **inline for** — Comptime iteration over targets
- **Target-specific naming** — Includes architecture and OS in filename
- **Static linking** — musl ABI for portable Linux binaries
- **Platform detection** — `builtin` module provides compile-time platform info
- **Separate native build** — Allows local testing and running

This pattern is used by release automation to generate artifacts for all supported platforms in a single build.

### Example 3: Basic CI Workflow

A minimal GitHub Actions workflow for Zig projects:

**`.github/workflows/ci.yml`:**

```yaml
name: Basic CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Zig
        uses: mlugg/setup-zig@v2
        with:
          version: 0.15.2

      - name: Cache Zig artifacts
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/zig
            zig-cache
          key: ${{ runner.os }}-zig-${{ hashFiles('build.zig.zon') }}
          restore-keys: |
            ${{ runner.os }}-zig-

      - name: Check formatting
        run: zig fmt --check .

      - name: Build project
        run: zig build --summary all

      - name: Run tests
        run: zig build test --summary all

      - name: Build release
        run: zig build -Doptimize=ReleaseSafe --summary all
```

**Key components:**

- **Triggers** — Runs on push to main and all pull requests
- **setup-zig action** — Installs Zig 0.15.2 deterministically
- **Cache configuration** — Speeds up subsequent builds by caching dependencies
- **Formatting check** — Enforces consistent code style
- **Build verification** — Ensures project builds successfully
- **Test execution** — Runs all tests with summary output
- **Release build** — Validates optimized build configuration

**Cache strategy details:**

The cache key includes `hashFiles('build.zig.zon')`, invalidating cache when dependencies change. The `restore-keys` fallback enables partial cache hits (same OS, different dependencies).

**Timeout protection:**

The 10-minute timeout prevents hanging builds from consuming runner resources indefinitely.

This minimal workflow provides foundation for more complex CI pipelines.

### Example 4: Matrix CI Workflow

Advanced multi-platform testing with build matrices:

**`.github/workflows/matrix.yml`:**

```yaml
name: Multi-Platform CI Matrix

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          # Linux builds
          - os: ubuntu-latest
            target: x86_64-linux
            optimize: Debug
          - os: ubuntu-latest
            target: x86_64-linux
            optimize: ReleaseSafe
          - os: ubuntu-latest
            target: aarch64-linux
            optimize: ReleaseSafe

          # macOS builds
          - os: macos-latest
            target: x86_64-macos
            optimize: ReleaseSafe
          - os: macos-latest
            target: aarch64-macos
            optimize: ReleaseSafe

          # Windows builds
          - os: windows-latest
            target: x86_64-windows
            optimize: Debug
          - os: windows-latest
            target: x86_64-windows
            optimize: ReleaseSafe

    runs-on: ${{ matrix.os }}
    timeout-minutes: 15

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Zig
        uses: mlugg/setup-zig@v2
        with:
          version: 0.15.2

      - name: Cache Zig artifacts
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/zig
            zig-cache
          key: ${{ runner.os }}-${{ matrix.target }}-zig-${{ hashFiles('build.zig.zon') }}
          restore-keys: |
            ${{ runner.os }}-${{ matrix.target }}-zig-

      - name: Build for target
        run: zig build -Dtarget=${{ matrix.target }} -Doptimize=${{ matrix.optimize }} --summary all

      - name: Run tests (native only)
        if: matrix.target == 'x86_64-linux' && matrix.os == 'ubuntu-latest'
        run: zig build test -Doptimize=${{ matrix.optimize }} --summary all

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: binary-${{ matrix.target }}-${{ matrix.optimize }}
          path: zig-out/bin/*
          retention-days: 7

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: mlugg/setup-zig@v2
        with:
          version: 0.15.2
      - name: Check formatting
        run: zig fmt --check .
```

**Key patterns:**

- **fail-fast: false** — All matrix combinations run even if one fails
- **Matrix include** — Explicit combinations avoid exponential explosion
- **Target-specific cache** — Separate cache per target architecture
- **Conditional testing** — Tests only run on native platform (cross-compiled binaries cannot execute)
- **Artifact upload** — Preserves build outputs for download or release
- **Separate lint job** — Runs independently for fast feedback

**Matrix design considerations:**

This example tests 7 combinations instead of OS × target × optimize (3 × 5 × 2 = 30). Explicit `include` lists prevent unnecessary builds.

**Artifact retention:**

The 7-day retention balances storage costs with PR review timelines.

This pattern is observed in ZLS and Ghostty CI workflows.[^19]

### Example 5: Release Workflow

Automated release artifact generation triggered by git tags:

**`.github/workflows/release.yml`:**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-release:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: x86_64-linux
            artifact: myapp-x86_64-linux.tar.gz
          - os: ubuntu-latest
            target: aarch64-linux
            artifact: myapp-aarch64-linux.tar.gz
          - os: macos-latest
            target: x86_64-macos
            artifact: myapp-x86_64-macos.tar.gz
          - os: macos-latest
            target: aarch64-macos
            artifact: myapp-aarch64-macos.tar.gz
          - os: windows-latest
            target: x86_64-windows
            artifact: myapp-x86_64-windows.zip

    runs-on: ${{ matrix.os }}
    timeout-minutes: 20

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Zig
        uses: mlugg/setup-zig@v2
        with:
          version: 0.15.2

      - name: Get version from tag
        id: version
        shell: bash
        run: |
          if [[ "${{ github.ref }}" == refs/tags/* ]]; then
            VERSION="${GITHUB_REF#refs/tags/v}"
          else
            VERSION="dev-$(git rev-parse --short HEAD)"
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Build release binary
        run: |
          zig build \
            -Dtarget=${{ matrix.target }} \
            -Doptimize=ReleaseFast \
            --summary all

      - name: Strip binary (Linux/macOS)
        if: runner.os != 'Windows'
        run: |
          if [ "${{ runner.os }}" = "Linux" ]; then
            strip --strip-all zig-out/bin/myapp
          else
            strip -S zig-out/bin/myapp
          fi

      - name: Create tarball (Linux/macOS)
        if: runner.os != 'Windows'
        run: |
          cd zig-out/bin
          tar -czf ../../${{ matrix.artifact }} myapp
          cd ../..

      - name: Create zip (Windows)
        if: runner.os == 'Windows'
        shell: pwsh
        run: |
          Compress-Archive -Path zig-out/bin/myapp.exe -DestinationPath ${{ matrix.artifact }}

      - name: Generate checksum
        shell: bash
        run: |
          if [ "${{ runner.os }}" = "Windows" ]; then
            sha256sum ${{ matrix.artifact }} > ${{ matrix.artifact }}.sha256
          else
            shasum -a 256 ${{ matrix.artifact }} > ${{ matrix.artifact }}.sha256
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-${{ matrix.target }}
          path: |
            ${{ matrix.artifact }}
            ${{ matrix.artifact }}.sha256
          retention-days: 30

  create-release:
    needs: build-release
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          draft: true
          generate_release_notes: true
          files: |
            artifacts/release-*/*
```

**Key patterns:**

- **Tag trigger** — Runs on `v*` tags (v1.0.0, v2.3.1)
- **Version extraction** — Parses version from git tag
- **ReleaseFast optimization** — Maximum performance for production
- **Binary stripping** — Removes debug symbols for smaller size
- **Platform-specific packaging** — tar.gz for Unix, zip for Windows
- **Checksum generation** — SHA256 for integrity verification
- **Two-stage release** — Build artifacts, then create GitHub release
- **Draft releases** — Manual review before publication
- **30-day retention** — Longer retention for release artifacts

**Version embedding:**

The version extraction step supports both tagged releases (`v1.0.0`) and development builds (`dev-abc123`).

**Release dependencies:**

The `create-release` job depends on `build-release`, ensuring all artifacts build successfully before creating the release.

This pattern is adapted from ZLS and zigup release automation.[^20]

### Example 6: Workspace/Monorepo Layout

Organizing multiple packages in a single repository:

**Directory structure:**

```
workspace/
├── build.zig              # Root orchestrator
├── build.zig.zon          # Root manifest
├── packages/
│   ├── app/
│   │   └── src/
│   │       └── main.zig
│   └── core/
│       ├── build.zig
│       ├── build.zig.zon
│       └── src/
│           └── lib.zig
└── shared/                # Shared resources
```

**Root build.zig.zon:**

```zig
.{
    .name = .workspace,
    .version = "1.0.0",
    .minimum_zig_version = "0.15.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "packages",
        "shared",
        "README.md",
    },
    .dependencies = .{
        .core = .{
            .path = "packages/core",
        },
    },
    .fingerprint = 0x8d9400192b062fca,
}
```

**Root build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load core library dependency
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });
    const core_mod = core_dep.module("core");

    // Build app using core
    const app_exe = b.addExecutable(.{
        .name = "workspace-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("packages/app/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "core", .module = core_mod },
            },
        }),
    });
    b.installArtifact(app_exe);

    // Run step
    const run_cmd = b.addRunArtifact(app_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Test step for all packages
    const test_step = b.step("test", "Run all tests");

    // Test core
    const core_tests = b.addTest(.{
        .root_module = core_mod,
    });
    const run_core_tests = b.addRunArtifact(core_tests);
    test_step.dependOn(&run_core_tests.step);

    // Test app
    const app_tests = b.addTest(.{
        .root_module = app_exe.root_module,
    });
    const run_app_tests = b.addRunArtifact(app_tests);
    test_step.dependOn(&run_app_tests.step);
}
```

**packages/core/build.zig.zon:**

```zig
.{
    .name = .core,
    .version = "1.0.0",
    .minimum_zig_version = "0.15.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
    .dependencies = .{},
    .fingerprint = 0x6b8d854fd9e12954,
}
```

**packages/core/build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Core library module
    _ = b.addModule("core", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Shared library artifact (optional)
    const lib = b.addSharedLibrary(.{
        .name = "core",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });
    b.installArtifact(lib);
}
```

**packages/core/src/lib.zig:**

```zig
//! Core library providing shared functionality.

const std = @import("std");

pub const Version = struct {
    major: u32,
    minor: u32,
    patch: u32,

    pub fn format(
        self: Version,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d}.{d}.{d}", .{ self.major, self.minor, self.patch });
    }
};

pub const version = Version{ .major = 1, .minor = 0, .patch = 0 };

pub fn greet(writer: anytype, name: []const u8) !void {
    try writer.print("Hello from core, {s}!\n", .{name});
}

pub fn calculate(a: i32, b: i32) i32 {
    return a * 2 + b;
}

test "calculate" {
    try std.testing.expectEqual(@as(i32, 7), calculate(2, 3));
}

test "version format" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "{}", .{version});
    try std.testing.expectEqualStrings("1.0.0", result);
}
```

**packages/app/src/main.zig:**

```zig
const std = @import("std");
const core = @import("core");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Workspace App v{}\n", .{core.version});
    try core.greet(stdout, "Workspace");

    const result = core.calculate(10, 5);
    try stdout.print("Calculate(10, 5) = {d}\n", .{result});
}

test "app uses core correctly" {
    const result = core.calculate(10, 5);
    try std.testing.expectEqual(@as(i32, 25), result);
}
```

**Usage:**

```bash
$ zig build run
Workspace App v1.0.0
Hello from core, Workspace!
Calculate(10, 5) = 25

$ zig build test --summary all
Build Summary: 4/4 steps succeeded
test success
├─ run test (core) 2 passed, 0 skipped, 0 failed
└─ run test (app) 1 passed, 0 skipped, 0 failed
```

**Key patterns:**

- **Local path dependencies** — `.path = "packages/core"` for monorepo organization
- **Unified testing** — Root `test` step runs all package tests
- **Shared modules** — Core library consumed by multiple packages
- **Independent versioning** — Each package has its own build.zig.zon and fingerprint
- **Centralized orchestration** — Root build.zig coordinates all packages

This pattern is used by Mach (mach-core, mach-sysaudio, mach-sysgpu) and TigerBeetle (clients in different languages).[^21]

## Common Pitfalls

### Inconsistent Directory Structure

Non-standard layouts confuse tooling and developers:

**AVOID:**

```
myproject/
├── code/           # Should be src/
├── buildfile       # Should be build.zig
└── package.zon     # Should be build.zig.zon
```

**USE:**

```
myproject/
├── src/
├── build.zig
└── build.zig.zon
```

Use `zig init` to generate the standard structure. IDEs and tools expect these conventions.

### Missing Essential Files

Incomplete `.paths` in build.zig.zon causes distribution issues:

**AVOID:**

```zig
.paths = .{
    "src",
}
```

**USE:**

```zig
.paths = .{
    "build.zig",
    "build.zig.zon",
    "src",
    "README.md",
    "LICENSE",
}
```

Consumers expect documentation and licensing information. Missing files cause hash mismatches or legal ambiguity.

### Committing Build Artifacts

Build outputs in version control waste space and cause conflicts:

**AVOID:**

```bash
$ git status
    modified:   zig-cache/
    modified:   zig-out/
```

**USE (.gitignore):**

```gitignore
zig-out/
zig-cache/
.zig-cache/
```

Always exclude build artifacts. The `zig init` template includes appropriate `.gitignore`.

### Test Organization Confusion

Mixing test strategies without clear organization:

**AVOID:**

```
src/
├── parser.zig           # Has embedded tests
├── lexer.zig            # No tests
└── tests/
    └── parser_tests.zig  # Duplicate tests for parser
```

**USE (consistent approach):**

Either embed all tests:

```
src/
├── parser.zig    # With tests
├── lexer.zig     # With tests
└── codegen.zig   # With tests
```

Or separate all tests:

```
src/
├── parser.zig
├── lexer.zig
└── codegen.zig
tests/
├── parser_tests.zig
├── lexer_tests.zig
└── codegen_tests.zig
```

Choose one pattern consistently. Large projects often prefer separation for compile-time performance.

### Incorrect Target Specification

Forgetting to specify ABI causes unpredictable linking:

**AVOID:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux",  // Defaults to gnu (glibc)
});
```

**USE:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-musl",  // Explicit static linking
});
```

Be explicit about libc requirements. musl enables static linking, gnu requires glibc at runtime.

### libc Linking Issues

Mixing static and dynamic linking expectations:

**AVOID:**

Building with glibc on new system, deploying to old system:

```bash
# Build on Ubuntu 24.04 (glibc 2.39)
$ zig build -Dtarget=x86_64-linux-gnu

# Deploy to Ubuntu 20.04 (glibc 2.31)
$ ./myapp
./myapp: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.34' not found
```

**USE:**

Static linking with musl for portable Linux binaries:

```bash
$ zig build -Dtarget=x86_64-linux-musl
$ ldd myapp
    not a dynamic executable
```

For maximum compatibility, use musl and static linking. If glibc required, build on oldest supported distribution.

### CPU Feature Mismatches

Using `native` CPU features sacrifices portability:

**AVOID:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-musl",
    .cpu_features = "native",  // Optimizes for build host
});
```

Binary built on AVX2 CPU crashes on older CPU:

```
Illegal instruction (core dumped)
```

**USE:**

```zig
const query = try Query.parse(.{
    .arch_os_abi = "x86_64-linux-musl",
    .cpu_features = "baseline",  // Compatible with all x86_64
});
```

Or document requirements:

```zig
.cpu_features = "x86_64_v3"  // Clearly states AVX2 requirement
```

Document CPU requirements in README if using non-baseline features.

### Dynamic Library Dependencies

Cross-compiled binaries depending on missing libraries:

**AVOID:**

```zig
exe.linkSystemLibrary("ssl");
exe.linkSystemLibrary("crypto");
// Cross-compiling to system without OpenSSL
```

**USE:**

Either statically link or bundle dependencies:

```zig
// Option 1: Static linking
exe.linkSystemLibrary("ssl");
exe.linkage = .static;

// Option 2: Vendor the library
const ssl_dep = b.dependency("openssl", .{});
exe.linkLibrary(ssl_dep.artifact("ssl"));
```

Prefer static linking or vendoring for cross-compiled binaries.

### Poor CI Cache Configuration

Missing global cache or incorrect key:

**AVOID:**

```yaml
- uses: actions/cache@v4
  with:
    path: zig-cache          # Missing global cache
    key: zig-cache           # Key never changes
```

**USE:**

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/zig           # Global dependency cache
      zig-cache              # Local build cache
    key: ${{ runner.os }}-zig-${{ hashFiles('build.zig.zon') }}
    restore-keys: |
      ${{ runner.os }}-zig-  # Fallback on dependency changes
```

Cache invalidation tied to dependencies ensures fresh builds when dependencies change.

### Matrix Explosion

Testing every combination wastefully:

**AVOID:**

```yaml
matrix:
  os: [ubuntu-20.04, ubuntu-22.04, ubuntu-24.04, macos-12, macos-13, macos-14, windows-2019, windows-2022]
  zig: [0.11.0, 0.12.0, 0.13.0, 0.14.0, 0.15.0, master]
  optimize: [Debug, ReleaseSafe, ReleaseFast, ReleaseSmall]
# 8 * 6 * 4 = 192 jobs!
```

**USE:**

```yaml
matrix:
  include:
    - os: ubuntu-latest
      zig: 0.15.2
      optimize: Debug
    - os: ubuntu-latest
      zig: 0.15.2
      optimize: ReleaseSafe
    - os: macos-latest
      zig: 0.15.2
      optimize: ReleaseSafe
    - os: windows-latest
      zig: 0.15.2
      optimize: ReleaseSafe
# 4 jobs
```

Test critical combinations only. Most projects only test latest Zig version.

### Not Testing on Target Platforms

Cross-compiling without native testing:

**AVOID:**

```yaml
- name: Build for macOS
  run: zig build -Dtarget=aarch64-macos
# No actual testing on macOS
```

**USE:**

```yaml
- name: Build for macOS
  if: matrix.os == 'macos-latest'
  run: zig build -Dtarget=aarch64-macos

- name: Test on macOS
  if: matrix.os == 'macos-latest'
  run: zig build test
```

Cross-compilation verifies it compiles, not that it runs. Use native runners for testing.

## In Practice

### Zig Compiler: Self-Hosting Structure

The Zig compiler demonstrates canonical project organization:[^22]

```
zig/
├── build.zig          (57 KB - complex bootstrap orchestration)
├── build.zig.zon      (minimal metadata)
├── src/               (compiler implementation)
│   ├── Air/          (Abstract Intermediate Representation)
│   ├── codegen/      (Backend code generation)
│   ├── link/         (Linker implementations)
│   └── Zcu/          (Zig Compilation Unit)
├── lib/
│   ├── std/          (Standard library)
│   ├── compiler_rt/  (Compiler runtime)
│   ├── libc/         (libc headers)
│   └── init/         (zig init template)
└── test/             (Compiler test suite)
```

**Key patterns:**

- **Phase-organized source** — Modules grouped by compiler phase (parsing, analysis, codegen)
- **Self-hosting bootstrap** — Stage1 compiler builds Stage2 compiler
- **Template provision** — `lib/init/` defines standard project structure
- **Extensive testing** — Separate test directory for compiler validation

The compiler's structure influenced conventions adopted across the ecosystem.

### TigerBeetle: Strict CPU Requirements

TigerBeetle enforces CPU baseline for performance-critical operations:[^23]

```zig
// tigerbeetle/build.zig
fn resolve_target(b: *std.Build, target_requested: ?[]const u8) !std.Build.ResolvedTarget {
    const triples = .{
        "aarch64-linux",
        "aarch64-macos",
        "x86_64-linux",
        "x86_64-macos",
        "x86_64-windows",
    };
    const cpus = .{
        "baseline+aes+neon",
        "baseline+aes+neon",
        "x86_64_v3+aes",
        "x86_64_v3+aes",
        "x86_64_v3+aes",
    };

    // Match target to CPU requirements
    const arch_os, const cpu = inline for (triples, cpus) |triple, cpu_feat| {
        if (std.mem.eql(u8, target, triple)) break .{ triple, cpu_feat };
    } else return error.UnsupportedTarget;

    const query = try Query.parse(.{
        .arch_os_abi = arch_os,
        .cpu_features = cpu,
    });
    return b.resolveTargetQuery(query);
}
```

**Rationale:**

- **x86_64_v3** — Requires AVX2 (2015+ CPUs) for SIMD performance
- **+aes** — Hardware AES-NI for cryptographic operations
- **+neon** — ARM SIMD instructions

This strict baseline enables aggressive optimizations for financial workloads while documenting minimum hardware requirements.[^24]

### Ghostty: Modular Build Organization

Ghostty separates build logic into modules:[^25]

```
ghostty/
├── build.zig          (10 KB - clean orchestration)
├── src/
│   ├── build/         (Build logic modules)
│   │   ├── main.zig
│   │   ├── Config.zig
│   │   ├── SharedDeps.zig
│   │   └── GhosttyExe.zig
│   ├── apprt/         (Application runtime)
│   ├── terminal/      (VT emulation)
│   └── renderer/      (GPU rendering)
```

**build.zig pattern:**

```zig
const buildpkg = @import("src/build/main.zig");

pub fn build(b: *std.Build) !void {
    const config = try buildpkg.Config.init(b, appVersion);
    const deps = try buildpkg.SharedDeps.init(b, &config);
    const exe = try buildpkg.GhosttyExe.init(b, &config, &deps);
    // Clean root build.zig focuses on coordination
}
```

This pattern scales build complexity without bloating the root build.zig file.

### ZLS: Automated Release Pipeline

ZLS implements sophisticated release automation:[^26]

**`.github/workflows/artifacts.yml` highlights:**

1. **Skip logic** — Only build on new commits:

```yaml
- run: |
    LAST_SUCCESS=$(curl .../runs?status=success&per_page=1)
    if [ "$LAST_SUCCESS" = "$CURRENT_COMMIT" ]; then
      echo "SKIP_DEPLOY=true" >> $GITHUB_ENV
    fi
```

2. **Signed releases** — Cryptographic verification:

```yaml
- run: |
    echo "${MINISIGN_SECRET}" > minisign.key
    zig build release -Drelease-minisign --summary all
    rm -f minisign.key
```

3. **S3 upload** — Artifact distribution:

```yaml
- run: |
    s3cmd put ./zig-out/artifacts/ --recursive \
      s3://releases-bucket/ \
      --add-header="cache-control: public, max-age=31536000, immutable"
```

4. **Metadata publication** — JSON API update:

```yaml
- run: |
    zig run .github/workflows/prepare_release_payload.zig |
      curl --data @- https://releases.zigtools.org/v1/zls/publish
```

This pipeline publishes nightly builds automatically, providing users with latest features.[^27]

### zig-bootstrap: Official CI Reference

The [zig-bootstrap](https://github.com/ziglang/zig-bootstrap) repository demonstrates the official approach to cross-platform CI workflows:[^28]

**Key Patterns:**

1. **Matrix Build Strategy:**

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    zig-version: ['0.14.1', '0.15.2']
    optimize: [Debug, ReleaseSafe]
jobs:
  build:
    runs-on: ${{ matrix.os }}
    steps:
      - uses: mlugg/setup-zig@v2
        with:
          version: ${{ matrix.zig-version }}
      - run: zig build -Doptimize=${{ matrix.optimize }}
```

2. **Artifact Caching:**
   - Caches `~/.cache/zig` and `zig-cache/` directories
   - Cache key includes `build.zig.zon` hash for dependency tracking
   - Separate caches per OS/architecture/optimization mode

3. **Cross-Compilation Validation:**
   - Builds for all tier-1 targets (x86_64-linux, aarch64-macos, x86_64-windows)
   - Verifies compilation without running (native test runners for execution)
   - Produces release artifacts in parallel

4. **Release Workflow:**
   - Triggered by git tags matching `v*.*.*`
   - Creates GitHub Release with changelog
   - Uploads platform-specific binaries
   - Publishes checksums and signatures

**Artifact Packaging:**

```yaml
- name: Package artifacts
  run: |
    zig build -Doptimize=ReleaseSafe
    cd zig-out/bin
    tar czf ../../${{ github.event.repository.name }}-${{ github.ref_name }}-${{ matrix.target }}.tar.gz *

- uses: actions/upload-artifact@v4
  with:
    name: release-${{ matrix.target }}
    path: '*.tar.gz'
```

**Why Use This as Reference:**
- Maintained by Zig core team
- Demonstrates best practices for Zig CI
- Handles edge cases (Windows path separators, macOS code signing, Linux musl builds)
- Production-tested for the Zig compiler itself

### Ghostty: Platform-Specific Artifacts

Ghostty produces different artifact types per platform:[^29]

**macOS:**
- Universal binaries (x86_64 + aarch64 using `lipo`)
- .app bundle with Info.plist
- .dmg installer for distribution

**Linux:**
- Flatpak for sandboxed distribution
- AppImage for portable execution
- Distribution-specific packages (.deb, .rpm)

**Windows:**
- MSVC-linked executable
- Installer (MSI or NSIS)

The release workflow adapts packaging per platform while using identical source code.

### Mach: Multi-Package Workspace

Mach organizes related packages in a monorepo:[^30]

```
mach/
├── build.zig.zon
└── packages/
    ├── mach-core/
    │   ├── build.zig
    │   └── build.zig.zon
    ├── mach-sysaudio/
    │   ├── build.zig
    │   └── build.zig.zon
    └── mach-sysgpu/
        ├── build.zig
        └── build.zig.zon
```

Each package:
- Has independent semantic versioning
- Can be consumed separately
- Shares common development infrastructure
- Tests run collectively via root build.zig

This enables modular development while maintaining coherent releases.

### Bun: Hybrid Build System

Bun combines Zig, C++, and CMake:[^31]

```
bun/
├── build.zig          (35 KB - Zig/C++ orchestration)
├── CMakeLists.txt     (Legacy C++ build)
├── src/
│   ├── bun.js/       (JavaScript runtime in Zig)
│   ├── deps/         (Vendored C++ libraries)
│   └── napi/         (Node-API implementation)
```

**Integration pattern:**

- Zig build.zig wraps CMake for C++ dependencies
- C++ code compiled via bundled clang/lld
- Zig code links against C++ libraries
- Custom target resolution for platform-specific features

This demonstrates Zig's interoperability with existing build systems.

## Summary

Zig provides comprehensive support for project organization, cross-compilation, and continuous integration through standardized conventions, first-class target support, and deterministic builds.

**Project layout fundamentals:**

- Standard structure (`src/`, `build.zig`, `build.zig.zon`) improves discoverability
- `zig init` generates conventional layout automatically
- Multi-module organization supports complex projects
- Workspace patterns enable monorepo development
- Test organization (embedded or separate) scales with project size

**Cross-compilation capabilities:**

- 40+ operating systems, 43 architectures, 28 ABIs without external toolchains
- `std.Target.Query` API specifies targets programmatically
- CPU feature specification balances performance and compatibility
- libc considerations (musl vs glibc, static vs dynamic)
- Single build host produces binaries for all platforms

**CI/CD patterns:**

- GitHub Actions with `setup-zig` provides deterministic Zig installation
- Cache strategies (global + local) reduce build times
- Build matrices test critical platform combinations
- Conditional testing (native only) avoids cross-compilation execution issues
- Artifact upload preserves build outputs for release

**Release engineering:**

- Artifact naming conventions include version, architecture, OS
- Optimization modes (`ReleaseFast`, `ReleaseSafe`, `ReleaseSmall`) trade off speed, safety, size
- Binary stripping reduces distribution size
- Checksum generation (SHA256) ensures integrity
- Platform-specific packaging (tar.gz, zip, installers)

**Production patterns observed:**

- Zig compiler: Phase-organized source, self-hosting bootstrap
- TigerBeetle: Strict CPU baselines, custom target resolution
- Ghostty: Modular build organization, platform-specific artifacts
- ZLS: Automated release pipeline with signing and S3 distribution
- Mach: Multi-package workspace with independent versioning
- Bun: Hybrid build system integrating Zig, C++, and CMake

**Common pitfalls to avoid:**

- Non-standard directory structure
- Missing essential files in `.paths`
- Committing build artifacts
- Implicit libc assumptions
- CPU feature mismatches
- Poor cache configuration
- Matrix explosion
- Not testing on target platforms

Understanding these patterns enables organizing scalable projects, shipping portable binaries, and automating release workflows. The combination of standardized structure, portable cross-compilation, and reproducible builds distinguishes Zig from ecosystems requiring platform-specific toolchains.

The next iteration of Zig's package ecosystem will introduce official package registries and enhanced workspace tooling, building on these established patterns.

## References

[^1]: Zig Language Reference - Cross-Compilation - https://ziglang.org/documentation/0.15.2/#Cross-compiling
[^2]: Zig Init Template - https://github.com/ziglang/zig/tree/0.15.2/lib/init
[^3]: Zig Init Command Implementation - https://github.com/ziglang/zig/blob/0.15.2/src/main.zig#L6520-L6650
[^4]: Zig Compiler Source Organization - https://github.com/ziglang/zig/tree/0.15.2/src
[^5]: Zig Compiler Architecture - https://github.com/ziglang/zig/blob/0.15.2/src/Air.zig
[^6]: ZLS Test Organization - https://github.com/zigtools/zls/tree/master/tests
[^7]: Mach Workspace Structure - https://github.com/hexops/mach
[^8]: Zig Target Specification - https://github.com/ziglang/zig/blob/0.15.2/lib/std/Target.zig
[^9]: std.Target.Query API - https://github.com/ziglang/zig/blob/0.15.2/lib/std/Target.zig#L1-L100
[^10]: TigerBeetle CPU Requirements - https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md#cpu-requirements
[^11]: Zig ABI Specification - https://github.com/ziglang/zig/blob/0.15.2/lib/std/Target.zig#L800-L850
[^12]: Ghostty Static Linking Strategy - https://github.com/ghostty-org/ghostty/blob/main/build.zig#L1-L50
[^13]: setup-zig GitHub Action - https://github.com/mlugg/setup-zig
[^14]: TigerBeetle Custom Zig Download - https://github.com/tigerbeetle/tigerbeetle/tree/main/zig
[^15]: GitHub Actions Caching Documentation - https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
[^16]: GitHub Actions Matrix Strategy - https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
[^17]: ZLS Optimization Settings - https://github.com/zigtools/zls/blob/master/build.zig#L100-L150
[^18]: ZLS Checksum Generation - https://github.com/zigtools/zls/blob/master/.github/workflows/artifacts.yml#L70-L82
[^19]: Ghostty Test Workflow - https://github.com/ghostty-org/ghostty/blob/main/.github/workflows/test.yml
[^20]: ZLS Release Automation - https://github.com/zigtools/zls/blob/master/.github/workflows/artifacts.yml
[^21]: TigerBeetle Monorepo Organization - https://github.com/tigerbeetle/tigerbeetle/tree/main/src/clients
[^22]: Zig Compiler Repository - https://github.com/ziglang/zig
[^23]: TigerBeetle Target Resolution - https://github.com/tigerbeetle/tigerbeetle/blob/main/build.zig#L13-L42
[^24]: TigerBeetle Style Guide - https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
[^25]: Ghostty Build Organization - https://github.com/ghostty-org/ghostty/blob/main/build.zig
[^26]: ZLS Artifacts Workflow - https://github.com/zigtools/zls/blob/master/.github/workflows/artifacts.yml
[^27]: ZLS Release Preparation Script - https://github.com/zigtools/zls/blob/master/.github/workflows/prepare_release_payload.zig
[^28]: zig-bootstrap CI Configuration - https://github.com/ziglang/zig-bootstrap - Official reference for cross-platform CI workflows
[^29]: Ghostty Release Tag Workflow - https://github.com/ghostty-org/ghostty/blob/main/.github/workflows/release-tag.yml
[^30]: Mach Build System - https://github.com/hexops/mach/blob/main/build.zig
[^31]: Bun Build System - https://github.com/oven-sh/bun/blob/main/build.zig
# Testing, Benchmarking & Profiling

> **TL;DR for experienced developers:**
> - **Testing:** `test "name" { ... }` blocks, run with `zig test file.zig`
> - **Assertions:** `try testing.expect(condition)`, `try testing.expectEqual(expected, actual)`
> - **Memory leak detection:** `testing.allocator` fails tests if allocations aren't freed
> - **Benchmarking:** Manual timing with `std.time.Timer`, prevent DCE with `doNotOptimizeAway`
> - **Profiling:** Use perf (Linux), Instruments (macOS), or Valgrind for detailed analysis
> - **Jump to:** [Basic tests §11.2](#zig-test-and-test-discovery) | [Benchmarking §11.5](#benchmarking-patterns) | [Profiling §11.6](#profiling-techniques)

## Overview

Zig provides integrated testing, benchmarking, and profiling reflecting its philosophy: simplicity, explicitness, and zero hidden costs.

**Testing:** `zig test` discovers and executes test blocks automatically. The `std.testing` module provides assertions and `testing.allocator` (fails on leaks). Tests use deterministic random seeds for reproducibility. The `builtin.is_test` flag enables test-only code without bloating binaries.

**Benchmarking:** Manual instrumentation with `std.time.Timer` provides accuracy over convenience. Use `std.mem.doNotOptimizeAway` to prevent dead code elimination. Developers control warm-up iterations and statistical sampling.

**Profiling:** Integration with perf (Linux), Instruments (macOS), Valgrind (Callgrind, Massif). Use `-Dstrip=false` for symbols and `-Doptimize=ReleaseFast` for representative performance.

**Production patterns:** TigerBeetle (deterministic simulation, fault injection), Ghostty (platform-specific organization), ZLS (semantic JSON comparison for diffs).

## Core Concepts

### zig test and Test Discovery

The `zig test` command compiles a source file and its dependencies, discovers all `test` blocks, and executes them sequentially. Each test runs in isolation—failures in one test do not affect others. This design prioritizes determinism over parallel execution for reproducible results.[^1]

**Basic Usage:**

```bash
# Test a single file
zig test src/main.zig

# Test with specific optimization level
zig test -O ReleaseFast src/main.zig

# Filter tests by name
zig test src/main.zig --test-filter "allocator"

# Verbose output with all results
zig test src/main.zig --summary all
```

**Test Discovery Mechanism:**

The compiler scans for `test "name" { ... }` or anonymous `test { ... }` blocks at file scope. Tests in imported modules are automatically included unless the import is guarded by `if (!builtin.is_test)`. This transitive discovery ensures comprehensive test coverage without explicit registration.

**Test Block Syntax:**

```zig
const std = @import("std");
const testing = std.testing;

// Named test - appears in output
test "arithmetic operations" {
    const result = 2 + 2;
    try testing.expectEqual(4, result);
}

// Anonymous test - identified by file and line
test {
    try testing.expect(true);
}
```

Named tests provide descriptive failure messages, while anonymous tests suit quick validation. Both forms support error returns via `try`, which propagates assertion failures upward.

**Execution Model:**

Tests execute sequentially in source order. This guarantees deterministic behavior but precludes parallel execution. The test runner:

1. Discovers all tests in the module graph
2. Initializes `std.testing.allocator` and `std.testing.random_seed`
3. Executes each test in a separate stack frame
4. Checks for memory leaks after each test
5. Aggregates results and prints a summary

**Exit Codes:**

- `0`: All tests passed
- Non-zero: At least one test failed (typically `1`)

**The builtin.is_test Flag:**

The `builtin.is_test` constant enables conditional compilation for test-only code:

```zig
const builtin = @import("builtin");

pub const Database = struct {
    data: []u8,

    pub fn query(self: *Database, sql: []const u8) !Result {
        // Production implementation
    }

    // Test-only helper - not compiled in release builds
    pub fn seedTestData(self: *Database) !void {
        if (!builtin.is_test) @compileError("seedTestData is test-only");
        // Insert test fixtures
    }
};

test "database with test data" {
    var db = try Database.init(testing.allocator);
    defer db.deinit();

    try db.seedTestData(); // OK in tests

    const result = try db.query("SELECT * FROM users");
    try testing.expect(result.rows.len > 0);
}
```

This pattern appears extensively in production codebases. TigerBeetle's snapshot testing module uses comptime assertions to enforce test-only usage:[^2]

```zig
pub const Snap = struct {
    comptime {
        assert(builtin.is_test);
    }
    // Snapshot testing implementation
};
```

**Test Filtering:**

Filters run only tests matching a substring pattern:

```bash
# Run tests containing "allocator"
zig test src/main.zig --test-filter "allocator"

# Multiple filters are OR'd
zig test src/main.zig --test-filter "allocator" --test-filter "hashmap"
```

Filtering enables rapid iteration on specific functionality during development without running the entire suite.

**Error Reporting:**

When tests fail, Zig provides detailed diagnostics:

```
Test [3/10] test.basic arithmetic... FAIL (TestExpectedEqual)
expected 5, found 4
/home/user/src/main.zig:10:5: 0x103c1a0 in test.basic arithmetic (test)
    try testing.expectEqual(5, result);
    ^
```

Output includes:
- Test name and index (3/10)
- Error type (`TestExpectedEqual`)
- Expected vs actual values
- File path, line number, and column
- Stack trace showing failure location

### std.testing Module and Assertions

The `std.testing` module provides all core testing utilities without external dependencies. It includes assertions, allocators for memory testing, and utilities for reproducible randomness.[^3]

**Core Assertions:**

**expect(ok: bool) !void**

The fundamental assertion—fails if the condition is false.

```zig
try testing.expect(value > 0);
try testing.expect(list.items.len == 5);
```

Returns `error.TestUnexpectedResult` on failure. Use for boolean conditions where simple pass/fail suffices.

**expectEqual(expected: anytype, actual: anytype) !void**

Compares two values for equality using peer type resolution to coerce both to a common type. Provides detailed diagnostics showing expected and actual values.

```zig
try testing.expectEqual(42, computeAnswer());
try testing.expectEqual(@as(u32, 100), counter);
```

Works with structs, unions, arrays, and most Zig types via recursive comparison using `std.meta.eql` internally. This is the most commonly used assertion in production code.

**expectError(expected_error: anyerror, actual_error_union: anytype) !void**

Asserts that an error union contains a specific error.

```zig
const result = parseNumber("invalid");
try testing.expectError(error.InvalidFormat, result);
```

Fails if:
- The error union contains a value (not an error)
- The error differs from expected

Critical for testing error paths and ensuring functions fail correctly.

**expectEqualSlices(comptime T: type, expected: []const T, actual: []const T) !void**

Compares two slices element-by-element, reporting the index of the first mismatch.

```zig
const expected = [_]u8{ 1, 2, 3 };
const actual = list.items;
try testing.expectEqualSlices(u8, &expected, actual);
```

**expectEqualStrings(expected: []const u8, actual: []const u8) !void**

String-specific comparison semantically equivalent to `expectEqualSlices(u8, ...)` but clearer for string contexts.

```zig
try testing.expectEqualStrings("hello", result);
```

**Floating Point Assertions:**

**expectApproxEqAbs(expected: anytype, actual: anytype, tolerance: anytype) !void**

Absolute tolerance comparison for floating-point values. Checks `|expected - actual| <= tolerance`.

```zig
const result = computeCircleArea(5.0);
try testing.expectApproxEqAbs(78.54, result, 0.01);
```

**expectApproxEqRel(expected: anytype, actual: anytype, tolerance: anytype) !void**

Relative tolerance comparison—better for values with large magnitude. Checks `|expected - actual| / max(|expected|, |actual|) <= tolerance`.

```zig
try testing.expectApproxEqRel(1000000.0, result, 0.0001); // 0.01% tolerance
```

Relative comparison avoids absolute tolerance issues on large or small numbers.

**Memory Testing:**

**testing.allocator**

A `GeneralPurposeAllocator` configured specifically for test use. Automatically detects:
- Memory leaks (allocations not freed)
- Double-frees
- Use-after-free (when safety checks enabled)

```zig
test "allocator usage" {
    const list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Essential - test fails without this

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

If `deinit()` is omitted, the test fails with a memory leak report detailing the allocation site and amount leaked.

Configuration includes stack traces for allocation sites:

```zig
pub var allocator_instance: std.heap.GeneralPurposeAllocator(.{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0,
    .resize_stack_traces = true,
    .canary = @truncate(0x2731e675c3a701ba),
}) = .init;
```

The canary value ensures accidentally using a default-constructed GPA instead of `testing.allocator` triggers a panic.

**FailingAllocator**

A wrapper allocator that probabilistically fails allocations to test error paths. Essential for verifying allocation failure handling.[^4]

```zig
const std = @import("std");
const testing = std.testing;

test "handle allocation failure" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 3 });
    const allocator = failing.allocator();

    // First 2 allocations succeed, 3rd fails
    const a1 = try allocator.alloc(u8, 10);
    defer allocator.free(a1);

    const a2 = try allocator.alloc(u8, 10);
    defer allocator.free(a2);

    const a3 = allocator.alloc(u8, 10);
    try testing.expectError(error.OutOfMemory, a3);
}
```

ZLS provides an enhanced `FailingAllocator` with probabilistic failures:[^5]

```zig
pub const FailingAllocator = struct {
    likelihood: u32,

    /// Chance of failure is 1/likelihood
    pub fn init(internal_allocator: std.mem.Allocator, likelihood: u32) FailingAllocator {
        return .{
            .internal_allocator = internal_allocator,
            .random = .init(std.crypto.random.int(u64)),
            .likelihood = likelihood,
        };
    }

    fn shouldFail(self: *FailingAllocator) bool {
        if (self.likelihood == std.math.maxInt(u32)) return false;
        return 0 == self.random.random().intRangeAtMostBiased(u32, 0, self.likelihood);
    }
};
```

This provides more flexible failure patterns for comprehensive error path testing.

**Additional Utilities:**

**testing.random_seed**

A deterministic seed initialized at test startup, enabling reproducible randomness:

```zig
var prng = std.Random.DefaultPrng.init(testing.random_seed);
const random = prng.random();
const value = random.int(u32);
```

The seed is printed at test start. Failed tests can be reproduced using the same seed, critical for debugging intermittent failures.

**expectFmt(expected: []const u8, comptime template: []const u8, args: anytype) !void**

Asserts formatted output matches expected string:

```zig
try testing.expectFmt("value: 42", "value: {d}", .{42});
```

Useful for testing formatting logic without manual string construction.

### Test Organization Patterns

Effective test organization balances discoverability, maintainability, and separation of concerns. Zig's testing model enables multiple organizational approaches, each with specific trade-offs.

**Colocated vs Separate Test Files:**

**Colocated Tests (Recommended):** Tests live in the same file as implementation.

```zig
// src/queue.zig
pub const Queue = struct {
    items: []i32,

    pub fn push(self: *Queue, value: i32) !void {
        // Implementation
    }
};

test "Queue: basic operations" {
    var queue = Queue.init(testing.allocator);
    defer queue.deinit();

    try queue.push(42);
    try testing.expectEqual(1, queue.len());
}

test "Queue: edge cases" {
    // More tests
}
```

Advantages:
- Tests stay synchronized with implementation
- Easy to find relevant tests
- Encourages testing as part of development
- `zig test src/queue.zig` runs all relevant tests
- Reduces cognitive overhead from file switching

**Separate Test Files:** Less common in Zig but used for integration tests.

```
src/
  queue.zig
  tests/
    queue_integration_test.zig
```

Separate files suit integration tests requiring complex setup or multiple module interactions.

**Test Directory Conventions:**

**Standard Library Pattern:** Colocated tests with test-only modules in `testing/`:

```
std/
  array_list.zig           # Implementation + tests
  hash_map.zig             # Implementation + tests
  testing.zig              # Main testing module
  testing/
    FailingAllocator.zig   # Reusable test utilities
```

**TigerBeetle Pattern:** Extensive `testing/` infrastructure for reusable components:[^6]

```
src/
  vsr.zig                  # Implementation
  state_machine.zig        # Implementation
  testing/
    fuzz.zig               # Fuzzing utilities
    time.zig               # Deterministic time simulation
    fixtures.zig           # Test fixtures and helpers
    storage.zig            # Storage simulator
    packet_simulator.zig   # Network simulation
    cluster/
      message_bus.zig      # Cluster testing infrastructure
      state_checker.zig    # State invariant checkers
```

This pattern separates:
- **Production code**: Core implementation
- **Test code**: Colocated test blocks
- **Test infrastructure**: Reusable testing utilities

**Shared Test Utilities:**

Extract common test setup into dedicated modules:

```zig
// testing/fixtures.zig
pub fn initStorage(allocator: std.mem.Allocator, options: StorageOptions) !Storage {
    return try Storage.init(allocator, options);
}

pub fn initGrid(allocator: std.mem.Allocator, superblock: *SuperBlock) !Grid {
    return try Grid.init(allocator, .{ .superblock = superblock });
}
```

TigerBeetle's fixture pattern centralizes initialization with sensible defaults:[^7]

```zig
pub const cluster: u128 = 0;
pub const replica: u8 = 0;
pub const replica_count: u8 = 6;

pub fn initTime(options: struct {
    resolution: u64 = constants.tick_ms * std.time.ns_per_ms,
    offset_type: OffsetType = .linear,
    offset_coefficient_A: i64 = 0,
    offset_coefficient_B: i64 = 0,
}) TimeSim {
    return .{
        .resolution = options.resolution,
        .offset_type = options.offset_type,
        .offset_coefficient_A = options.offset_coefficient_A,
        .offset_coefficient_B = options.offset_coefficient_B,
    };
}
```

Benefits:
- Provides defaults for most options
- Requires passing `.{}` at call sites (makes customization explicit)
- Centralizes complex initialization logic
- Ensures consistent test setup across the codebase

**Test Fixtures and Setup/Teardown:**

Zig lacks built-in setup/teardown hooks. Instead, use explicit initialization with `defer`:

```zig
test "with setup and teardown" {
    // Setup
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit(); // Teardown

    const allocator = arena.allocator();

    // Test body
    const list = try std.ArrayList(u32).initCapacity(allocator, 10);
    try list.append(42);
    try testing.expectEqual(1, list.items.len);

    // Arena deinit handles cleanup automatically
}
```

**Arena Allocator Pattern for Complex Tests:**

```zig
test "complex test with multiple allocations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    // All allocations from arena freed at once
    const data1 = try arena.allocator().alloc(u8, 100);
    const data2 = try arena.allocator().alloc(u32, 50);
    // No individual free() needed
}
```

Arena allocators simplify cleanup when tests allocate multiple resources. A single `defer arena.deinit()` frees everything.

**Build System Integration:**

Integrate tests with `build.zig`:[^8]

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Test executable
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
```

Run tests with `zig build test`. This integrates seamlessly with CI/CD pipelines.

**Test Naming Conventions:**

Use descriptive names for clarity:

```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}

test "HashMap: remove decrements count" {
    var map = std.AutoHashMap(u32, u32).init(testing.allocator);
    defer map.deinit();

    try map.put(1, 100);
    _ = map.remove(1);
    try testing.expectEqual(0, map.count());
}
```

Include the type or module name followed by the specific behavior being tested. This convention aids filtering and provides self-documenting test names.

### Advanced Testing Techniques

Advanced testing techniques enable comprehensive validation of complex functionality while maintaining readability and maintainability.

**Parameterized and Table-Driven Tests:**

Parameterized tests use comptime iteration to generate test cases from data tables:

```zig
test "integer parsing: multiple cases" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .input = "0", .expected = 0 },
        .{ .input = "42", .expected = 42 },
        .{ .input = "-10", .expected = -10 },
        .{ .input = "2147483647", .expected = 2147483647 },
    };

    inline for (cases) |case| {
        const result = try std.fmt.parseInt(i32, case.input, 10);
        try testing.expectEqual(case.expected, result);
    }
}
```

The `inline for` loop unrolls at compile time, generating separate assertions for each case. This provides granular failure reporting—failures identify exactly which case failed.

**Advanced: Comptime Type Generation:**

```zig
test "generic list operations" {
    const types = [_]type{ u8, u16, u32, u64 };

    inline for (types) |T| {
        var list = std.ArrayList(T).init(testing.allocator);
        defer list.deinit();

        try list.append(1);
        try testing.expectEqual(@as(T, 1), list.items[0]);
    }
}
```

This pattern tests identical logic across multiple types without code duplication, ensuring generic implementations work correctly for all supported types.

**Comptime Test Generation:**

Generate tests programmatically at compile time:

```zig
fn makeTest(comptime value: i32) type {
    return struct {
        test {
            try testing.expectEqual(value, value);
        }
    };
}

test {
    _ = makeTest(1);
    _ = makeTest(2);
    _ = makeTest(3);
}
```

Real-world applications include testing parsers against multiple formats, validating serialization for different types, or verifying compile-time computations.

**Testing with Allocators:**

**Memory Leak Detection:**

```zig
test "no memory leaks" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Required - test fails without this

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

Omitting `list.deinit()` causes `testing.allocator` to report:

```
Test [1/1] test.no memory leaks... FAIL (error.MemoryLeakDetected)
Memory leak detected: 40 bytes not freed
```

**FailingAllocator for Error Paths:**

```zig
test "handle allocation failure gracefully" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    const result = std.ArrayList(u32).initCapacity(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

This ensures error handling code is exercised. Comprehensive error path testing uses multiple failure indices:

```zig
test "robustness under allocation failures" {
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = i });
        const allocator = failing.allocator();

        const result = createComplexStructure(allocator);

        // Either succeeds or fails with OutOfMemory
        if (result) |value| {
            defer value.deinit(allocator);
            try testing.expect(value.isValid());
        } else |err| {
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}
```

This exhaustively tests failure at each allocation point, ensuring robust error handling.

**Testing Error Paths:**

Use `expectError` to validate error handling:

```zig
test "parseNumber: handles invalid input" {
    const result = parseNumber("not a number");
    try testing.expectError(error.InvalidFormat, result);
}

test "File.open: handles missing file" {
    const result = std.fs.cwd().openFile("nonexistent.txt", .{});
    try testing.expectError(error.FileNotFound, result);
}
```

Testing both success and error paths ensures functions behave correctly under all conditions.

**Testing Concurrent Code:**

Zig 0.15+ has simplified async handling. Concurrent tests require explicit synchronization:

```zig
test "concurrent atomic counter" {
    var counter = std.atomic.Value(u32).init(0);

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *std.atomic.Value(u32)) void {
                for (0..1000) |_| {
                    _ = c.fetchAdd(1, .monotonic);
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| {
        t.join();
    }

    try testing.expectEqual(4000, counter.load(.monotonic));
}
```

Use atomics or mutexes for shared state to avoid race conditions.

**Deterministic Concurrency Testing:**

TigerBeetle demonstrates controlled time for deterministic distributed testing:[^9]

```zig
pub const TimeSim = struct {
    resolution: u64,
    ticks: u64 = 0,

    pub fn tick(self: *TimeSim) void {
        self.ticks += 1;
    }

    fn monotonic(context: *anyopaque) u64 {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        return self.ticks * self.resolution;
    }
};
```

By controlling time explicitly, distributed consensus algorithms can be tested deterministically without race conditions or timeout flakiness.

### Benchmarking Best Practices

Benchmarking in Zig is manual—no built-in framework like Go's `testing.B` exists. This provides full control but requires understanding measurement pitfalls to obtain accurate results.

**std.time.Timer API:**

`std.time.Timer` provides monotonic, high-precision timing:[^10]

```zig
const std = @import("std");

pub fn main() !void {
    var timer = try std.time.Timer.start();

    // Code to measure
    expensiveOperation();

    const elapsed_ns = timer.read();
    std.debug.print("Elapsed: {d} ns\n", .{elapsed_ns});
}
```

**Key Methods:**
- `start() !Timer`: Initialize timer (may fail if no monotonic clock available)
- `read() u64`: Read elapsed nanoseconds since start/reset
- `reset()`: Reset timer to zero
- `lap() u64`: Read elapsed time and reset in one operation

Timer implementation uses platform-specific monotonic clocks:
- Linux: `CLOCK_BOOTTIME` (includes suspend time)
- macOS: `CLOCK_UPTIME_RAW`
- Windows: `QueryPerformanceCounter`

**std.mem.doNotOptimizeAway:**

Critical function preventing compiler optimizations from eliminating benchmarked code:[^11]

```zig
pub fn doNotOptimizeAway(value: anytype) void {
    asm volatile ("" :: [_]"r,m" (value));
}
```

**Why It's Needed:**

Without `doNotOptimizeAway`:
```zig
// ❌ Compiler may optimize away the entire loop
for (0..1000) |_| {
    const result = expensiveFunction();
    // result unused - dead code elimination
}
```

With `doNotOptimizeAway`:
```zig
// ✅ Compiler must keep the function call
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);
}
```

The inline assembly with memory/register constraint forces the compiler to treat the value as used, preventing:
1. Dead code elimination (removing unused results)
2. Constant folding (computing results at compile time)
3. Loop elimination (removing the entire loop)

**Warm-up Iterations:**

Cold starts skew results. Always include a warm-up phase:

```zig
// Warm-up: 10% of iterations or max 100
const warmup_iterations = @min(iterations / 10, 100);
for (0..warmup_iterations) |_| {
    const result = func();
    std.mem.doNotOptimizeAway(&result);
}

// Now measure with warm caches and stable CPU frequency
var timer = try std.time.Timer.start();
for (0..iterations) |_| {
    const result = func();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
```

Warm-up stabilizes:
- CPU frequency (modern CPUs scale based on load)
- L1/L2 cache state (loads hot paths into cache)
- Branch predictor state (trains the predictor)
- TLB (translation lookaside buffer)

**Statistical Measurement:**

Never rely on single measurements. Collect samples and compute statistics:

```zig
const num_samples = 10;
const iterations_per_sample = iterations / num_samples;

var samples: [10]u64 = undefined;

for (0..num_samples) |i| {
    var timer = try std.time.Timer.start();

    for (0..iterations_per_sample) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    samples[i] = timer.read();
}

// Compute min, max, mean, variance
var min_ns: u64 = std.math.maxInt(u64);
var max_ns: u64 = 0;
var total_ns: u64 = 0;

for (samples) |sample| {
    min_ns = @min(min_ns, sample);
    max_ns = @max(max_ns, sample);
    total_ns += sample;
}

const avg_ns = total_ns / num_samples;

// Variance
var variance_sum: u128 = 0;
for (samples) |sample| {
    const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
    variance_sum += @as(u128, diff) * @as(u128, diff);
}
const variance = variance_sum / num_samples;
```

Multiple samples:
- Identify outliers (context switches, interrupts)
- Measure consistency (variance)
- Increase confidence in the mean

**Build Modes for Benchmarking:**

Always benchmark in release mode:

```bash
# ❌ Debug mode (slow, includes safety checks)
zig build-exe benchmark.zig

# ✅ ReleaseFast (maximum speed)
zig build-exe -O ReleaseFast benchmark.zig

# ✅ ReleaseSmall (optimized for size, still fast)
zig build-exe -O ReleaseSmall benchmark.zig

# ❌ ReleaseSafe (includes runtime safety, slower)
zig build-exe -O ReleaseSafe benchmark.zig
```

Debug vs ReleaseFast can differ by 10-100x in performance.

**Build.zig Configuration:**

```zig
const benchmark = b.addExecutable(.{
    .name = "benchmark",
    .root_source_file = b.path("src/benchmark.zig"),
    .target = target,
    .optimize = .ReleaseFast,  // Force release mode
});
```

**Common Benchmarking Mistakes:**

**❌ Mistake 1: Not using doNotOptimizeAway**
```zig
// Entire loop may be optimized away
for (0..1000) |_| {
    const result = compute();
}
```

**✅ Correct:**
```zig
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
```

**❌ Mistake 2: No warm-up phase**
```zig
// First iterations will be slow (cold cache)
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    compute();
}
```

**✅ Correct:**
```zig
// Warm up first
for (0..100) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}

// Then measure
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
```

**❌ Mistake 3: Single measurement**
```zig
var timer = try std.time.Timer.start();
compute();
const elapsed = timer.read();
// Unreliable - could be affected by context switch
```

**✅ Correct:**
```zig
// Take multiple samples
const samples = 10;
var times: [10]u64 = undefined;
for (&times) |*t| {
    var timer = try std.time.Timer.start();
    compute();
    t.* = timer.read();
}
// Compute statistics from samples
```

**❌ Mistake 4: Measuring in Debug mode**
```bash
# zig build-exe benchmark.zig
# Results meaningless due to lack of optimization
```

**✅ Correct:**
```bash
# zig build-exe -O ReleaseFast benchmark.zig
# Realistic performance numbers
```

### Profiling Integration

Profiling requires external tools. Zig provides necessary build flags and symbol information for effective profiling with industry-standard tools.[^12]

**Build Configuration for Profiling:**

Effective profiling requires:
1. **Optimization**: Realistic performance (`-O ReleaseFast`)
2. **Debug symbols**: For function names and line numbers
3. **No stripping**: Preserve symbols for profilers

```bash
# Command-line profiling build
zig build-exe -O ReleaseFast -Dcpu=baseline src/main.zig

# Or via build.zig
zig build -Doptimize=ReleaseFast -Dstrip=false
```

**Build.zig Configuration:**

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,  // Keep symbols for profiling
    });

    b.installArtifact(exe);
}
```

**Why baseline CPU?**: `-Dcpu=baseline` ensures the binary runs on any CPU of that architecture, avoiding CPU-specific optimizations that might not transfer across machines.

**Callgrind (Valgrind) Integration:**

Callgrind provides function-level profiling with call graphs.[^13]

**Running Callgrind:**

```bash
# Build with symbols
zig build -Doptimize=ReleaseFast

# Profile
valgrind --tool=callgrind ./zig-out/bin/myapp

# Generates callgrind.out.<pid>
```

**Analyzing Results:**

```bash
# View in KCachegrind (GUI)
kcachegrind callgrind.out.12345

# Or command-line summary
callgrind_annotate callgrind.out.12345
```

**Callgrind Output Example:**

```
Profile data file 'callgrind.out.12345' (creator: callgrind-3.19.0)
Total instructions: 1,234,567,890

Function                        Instructions  %
-----------------------------------------------
compute                          500,000,000  40.5%
std.ArrayList.append             200,000,000  16.2%
std.mem.copy                     150,000,000  12.2%
...
```

**Advantages:**
- Exact instruction counts (deterministic)
- Function-level and line-level detail
- Call graph visualization

**Disadvantages:**
- Very slow (10-100x slowdown)
- Not real-time profiling

**Linux perf:**

`perf` is a powerful sampling profiler with hardware counter support.[^14]

**Basic Profiling:**

```bash
# Record profile
perf record -F 999 -g ./zig-out/bin/myapp

# View results
perf report
```

**Flame Graph Generation:**

```bash
# Record with call graphs
perf record -F 999 -g ./zig-out/bin/myapp

# Convert to flame graph format
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**perf Options:**
- `-F 999`: Sample at 999Hz (odd number reduces aliasing)
- `-g`: Record call graphs
- `--call-graph dwarf`: Use DWARF for better stack traces (larger data)

**Advantages:**
- Low overhead (typically <5%)
- Real-time profiling
- Hardware counters (cache misses, branch mispredictions)

**Disadvantages:**
- Statistical (not deterministic)
- Requires root or `perf_event_paranoid` adjustment

**Massif (Heap Profiling):**

Massif tracks heap allocations over time.[^15]

**Running Massif:**

```bash
# Profile heap usage
valgrind --tool=massif ./zig-out/bin/myapp

# Generates massif.out.<pid>
```

**Analyzing:**

```bash
# Text summary
ms_print massif.out.12345

# GUI (if available)
massif-visualizer massif.out.12345
```

**Massif Output Example:**

```
    MB
3.0 |                                                            #
    |                                                           :#
    |                                                          @:#
    |                                                         :@:#
2.0 |                                                        ::@:#
    |                                                       :::@:#
    |                                              @       @:::@:#
    |                                             :@      @@:::@:#
1.0 |                                            ::@     :@@:::@:#
    |                                    @      :::@    ::@@:::@:#
    |                            @      :@     ::::@   :::@@:::@:#
    |                           :@     ::@    :::::@  ::::@@:::@:#
0.0 +-----------------------------------------------------------------------
      0                                                              1000 ms
```

**Advantages:**
- Shows allocation patterns over time
- Identifies memory leaks and bloat
- Snapshots show detailed heap state

**Disadvantages:**
- Significant slowdown
- Requires Valgrind-compatible system

**Flame Graph Generation:**

Flame graphs visualize profiling data as interactive SVGs.[^16]

**Setup:**

```bash
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph
```

**From perf:**

```bash
perf record -F 999 -g ./zig-out/bin/myapp
perf script > out.perf
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

**Reading Flame Graphs:**
- X-axis: Alphabetical sort (not time)
- Y-axis: Stack depth (bottom = entry, top = leaf)
- Width: Time spent in function (or descendants)
- Color: Typically random (or categorized by module)

Wide plateaus at the bottom indicate hot paths consuming most time.

**Profiling Overhead Considerations:**

**Callgrind:**
- Overhead: 10-100x slowdown
- Impact: Totally changes performance characteristics
- Use for: Instruction counts, relative comparisons

**perf:**
- Overhead: <5% typically
- Impact: Minimal on real-world performance
- Use for: Production-like profiling

**Massif:**
- Overhead: 5-20x slowdown
- Impact: Slows allocation-heavy code significantly
- Use for: Memory analysis, not performance

**Build Mode Impact:**
- Debug: 10-100x slower than ReleaseFast
- ReleaseSafe: ~2x slower due to safety checks
- ReleaseFast: Baseline for profiling
- ReleaseSmall: Similar to ReleaseFast but optimized for size

## Code Examples

This section demonstrates practical testing, benchmarking, and profiling patterns through six complete examples. Each builds on Core Concepts, showing real-world usage.

### Example 1: Testing Fundamentals

This example demonstrates fundamental test blocks, assertions, and error handling. It shows colocated tests alongside implementation, basic and advanced assertions, and testing both success and error paths.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/01_testing_fundamentals/`

**Key Code Snippet (math.zig):**

```zig
const std = @import("std");
const testing = std.testing;

/// Divide two integers, returning an error on division by zero.
pub fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

/// Calculate factorial (iterative version).
/// Returns error on negative input or overflow.
pub fn factorial(n: i32) !i64 {
    if (n < 0) return error.NegativeInput;
    if (n == 0 or n == 1) return 1;

    var result: i64 = 1;
    var i: i32 = 2;
    while (i <= n) : (i += 1) {
        const old_result = result;
        result = @as(i64, @intCast(i)) * result;
        if (@divTrunc(result, @as(i64, @intCast(i))) != old_result) {
            return error.Overflow;
        }
    }
    return result;
}

test "divide: successful division" {
    try testing.expectEqual(@as(i32, 5), try divide(10, 2));
    try testing.expectEqual(@as(i32, 1), try divide(7, 5));
    try testing.expectEqual(@as(i32, -2), try divide(-10, 5));
}

test "divide: division by zero" {
    try testing.expectError(error.DivisionByZero, divide(10, 0));
    try testing.expectError(error.DivisionByZero, divide(0, 0));
    try testing.expectError(error.DivisionByZero, divide(-10, 0));
}

test "factorial: basic cases" {
    try testing.expectEqual(@as(i64, 1), try factorial(0));
    try testing.expectEqual(@as(i64, 1), try factorial(1));
    try testing.expectEqual(@as(i64, 6), try factorial(3));
    try testing.expectEqual(@as(i64, 120), try factorial(5));
}

test "factorial: error cases" {
    try testing.expectError(error.NegativeInput, factorial(-1));
    try testing.expectError(error.NegativeInput, factorial(-10));
}
```

**Patterns Demonstrated:**
- Colocated tests alongside implementation
- Basic assertions (`expectEqual`, `expectError`)
- Testing both success and error paths
- Error handling with `!` return types
- Named tests with descriptive names
- Type coercion with `@as` for clarity

The complete example includes string utilities testing, prime number checking, and Fibonacci sequence validation. Run with `zig test src/main.zig`.

### Example 2: Test Organization

This example demonstrates project organization for tests, including test utilities, fixtures, and the `builtin.is_test` flag for conditional compilation.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/02_test_organization/`

**Project Structure:**

```
src/
  main.zig              # Main entry point
  data_structures.zig   # Implementation with tests
  testing/
    test_helpers.zig    # Shared test utilities
    fixtures.zig        # Test fixtures and data
```

**Key Code Snippet (test_helpers.zig):**

```zig
const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

// Only compile this module in test mode
comptime {
    if (!builtin.is_test) {
        @compileError("test_helpers module is only for tests");
    }
}

/// Helper to create a test allocator with tracking
pub fn TestAllocator() type {
    return struct {
        gpa: std.heap.GeneralPurposeAllocator(.{}),

        pub fn init() @This() {
            return .{ .gpa = .{} };
        }

        pub fn allocator(self: *@This()) std.mem.Allocator {
            return self.gpa.allocator();
        }

        pub fn deinit(self: *@This()) !void {
            const leaked = self.gpa.deinit();
            if (leaked == .leak) {
                return error.MemoryLeak;
            }
        }
    };
}
```

**Key Code Snippet (fixtures.zig):**

```zig
const std = @import("std");

/// Standard test data for numeric operations
pub const test_numbers = [_]i32{ 1, 2, 3, 4, 5, 10, 42, 100, 1000 };

/// Standard test strings
pub const test_strings = [_][]const u8{
    "",
    "a",
    "hello",
    "Hello, World!",
    "The quick brown fox jumps over the lazy dog",
};

/// Create a test arena allocator
pub fn createTestArena(backing: std.mem.Allocator) std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(backing);
}
```

**Patterns Demonstrated:**
- Separating test utilities into dedicated modules
- Using `builtin.is_test` for compile-time guards
- Centralized test fixtures and data
- Test-only helper functions
- Arena allocator pattern for test cleanup
- Organized project structure for maintainability

The complete example shows importing and using test helpers across multiple test files. Run with `zig build test`.

### Example 3: Parameterized Tests

This example demonstrates table-driven tests, comptime test generation, and testing across multiple types using inline loops.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests/`

**Key Code Snippet:**

```zig
const std = @import("std");
const testing = std.testing;

/// Test arithmetic operations with multiple test cases
test "add: parameterized cases" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .a = 0, .b = 0, .expected = 0 },
        .{ .a = 1, .b = 2, .expected = 3 },
        .{ .a = -5, .b = 5, .expected = 0 },
        .{ .a = 100, .b = -50, .expected = 50 },
        .{ .a = 2147483647, .b = 0, .expected = 2147483647 },
    };

    inline for (cases) |case| {
        const result = case.a + case.b;
        try testing.expectEqual(case.expected, result);
    }
}

/// Test string operations across multiple inputs
test "string length: table-driven" {
    const cases = [_]struct {
        input: []const u8,
        expected: usize,
    }{
        .{ .input = "", .expected = 0 },
        .{ .input = "a", .expected = 1 },
        .{ .input = "hello", .expected = 5 },
        .{ .input = "Hello, World!", .expected = 13 },
    };

    inline for (cases) |case| {
        try testing.expectEqual(case.expected, case.input.len);
    }
}

/// Test generic operations across multiple types
test "ArrayList: generic type testing" {
    const types = [_]type{ u8, u16, u32, u64, i8, i16, i32, i64 };

    inline for (types) |T| {
        var list = std.ArrayList(T).init(testing.allocator);
        defer list.deinit();

        const test_value: T = 42;
        try list.append(test_value);

        try testing.expectEqual(@as(usize, 1), list.items.len);
        try testing.expectEqual(test_value, list.items[0]);
    }
}

/// Comptime test generation for powers of two
test "powers of two: comptime generation" {
    const powers = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 };

    inline for (powers, 0..) |expected, i| {
        const result = std.math.pow(u32, 2, i);
        try testing.expectEqual(expected, result);
    }
}
```

**Patterns Demonstrated:**
- Table-driven tests with struct arrays
- `inline for` for comptime test case expansion
- Generic type testing across multiple types
- Comptime iteration with enumeration
- Granular failure reporting per case
- Zero runtime overhead from test generation

The inline for loop unrolls at compile time, generating separate assertions for each case. Failures identify exactly which case and type failed. Run with `zig test src/main.zig`.

### Example 4: Allocator Testing

This example demonstrates memory leak detection, using `FailingAllocator` to test error paths, and comprehensive allocator testing patterns.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing/`

**Key Code Snippet:**

```zig
const std = @import("std");
const testing = std.testing;

test "memory leak detection" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit(); // Required - test fails without this

    try list.append(42);
    try list.append(43);

    try testing.expectEqual(@as(usize, 2), list.items.len);
    // testing.allocator automatically checks for leaks when test completes
}

test "allocation failure handling" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing.allocator();

    // This allocation should fail immediately
    const result = allocator.alloc(u8, 100);
    try testing.expectError(error.OutOfMemory, result);
}

test "robust error path testing" {
    // Test allocation failure at different points
    var fail_index: u32 = 0;
    while (fail_index < 5) : (fail_index += 1) {
        var failing = testing.FailingAllocator.init(testing.allocator, .{
            .fail_index = fail_index
        });
        const allocator = failing.allocator();

        const result = createDataStructure(allocator);

        if (result) |structure| {
            defer structure.deinit(allocator);
            // Verify structure is valid
            try testing.expect(structure.isValid());
        } else |err| {
            // Should only fail with OutOfMemory
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}

fn createDataStructure(allocator: std.mem.Allocator) !DataStructure {
    var ds = DataStructure{};

    // Multiple allocations - test failure at each point
    ds.buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(ds.buffer1);

    ds.buffer2 = try allocator.alloc(u32, 50);
    errdefer allocator.free(ds.buffer2);

    ds.buffer3 = try allocator.alloc(i64, 25);
    errdefer allocator.free(ds.buffer3);

    return ds;
}

const DataStructure = struct {
    buffer1: []u8 = undefined,
    buffer2: []u32 = undefined,
    buffer3: []i64 = undefined,

    pub fn isValid(self: DataStructure) bool {
        return self.buffer1.len == 100 and
               self.buffer2.len == 50 and
               self.buffer3.len == 25;
    }

    pub fn deinit(self: DataStructure, allocator: std.mem.Allocator) void {
        allocator.free(self.buffer1);
        allocator.free(self.buffer2);
        allocator.free(self.buffer3);
    }
};

test "arena allocator pattern" {
    // Arena simplifies cleanup for multiple allocations
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Multiple allocations
    const data1 = try allocator.alloc(u8, 100);
    const data2 = try allocator.alloc(u32, 50);
    const data3 = try allocator.alloc(i64, 25);

    // Use the data
    data1[0] = 42;
    data2[0] = 100;
    data3[0] = -50;

    // No individual free() needed - arena.deinit() frees everything
}
```

**Patterns Demonstrated:**
- Memory leak detection with `testing.allocator`
- Using `FailingAllocator` to test error paths
- Systematic testing of allocation failure at different points
- `errdefer` for cleanup on error paths
- Arena allocator pattern for simplified cleanup
- Testing both success and failure scenarios

The complete example shows complex data structure testing with multiple allocation points and proper cleanup. Run with `zig test src/main.zig`.

### Example 5: Benchmarking Patterns

This example demonstrates comprehensive benchmarking with warm-up iterations, statistical measurement, `doNotOptimizeAway`, and comparison utilities.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking/`

**Key Code Snippet (benchmark.zig excerpt):**

```zig
const std = @import("std");

pub const BenchmarkResult = struct {
    iterations: u64,
    total_ns: u64,
    avg_ns: u64,
    min_ns: u64,
    max_ns: u64,
    variance_ns: u64,

    pub fn speedupVs(self: BenchmarkResult, other: BenchmarkResult) f64 {
        return @as(f64, @floatFromInt(other.avg_ns)) / @as(f64, @floatFromInt(self.avg_ns));
    }
};

pub fn benchmark(
    comptime Func: type,
    func: Func,
    iterations: u64,
) !BenchmarkResult {
    // Warm-up phase: stabilizes CPU frequency, cache, branch predictor
    const warmup_iterations = @min(iterations / 10, 100);
    for (0..warmup_iterations) |_| {
        const result = func();
        std.mem.doNotOptimizeAway(&result);
    }

    // Collect multiple samples for statistical analysis
    const num_samples = @min(10, @max(1, iterations / 100));
    const iterations_per_sample = iterations / num_samples;

    var samples: [10]u64 = undefined;
    var sample_idx: usize = 0;

    while (sample_idx < num_samples) : (sample_idx += 1) {
        var timer = try std.time.Timer.start();

        var iter: u64 = 0;
        while (iter < iterations_per_sample) : (iter += 1) {
            const result = func();
            // Critical: doNotOptimizeAway prevents dead code elimination
            std.mem.doNotOptimizeAway(&result);
        }

        samples[sample_idx] = timer.read();
    }

    // Calculate statistics: min, max, mean, variance
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var total_ns: u64 = 0;

    for (samples[0..num_samples]) |sample| {
        min_ns = @min(min_ns, sample);
        max_ns = @max(max_ns, sample);
        total_ns += sample;
    }

    const avg_ns = total_ns / num_samples;

    // Variance: sum of squared differences from mean
    var variance_sum: u128 = 0;
    for (samples[0..num_samples]) |sample| {
        const diff = if (sample > avg_ns) sample - avg_ns else avg_ns - sample;
        variance_sum += @as(u128, diff) * @as(u128, diff);
    }
    const variance_ns = @as(u64, @intCast(variance_sum / num_samples));

    return BenchmarkResult{
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_ns / iterations_per_sample,
        .min_ns = min_ns / iterations_per_sample,
        .max_ns = max_ns / iterations_per_sample,
        .variance_ns = variance_ns / (iterations_per_sample * iterations_per_sample),
    };
}
```

**Key Code Snippet (main.zig):**

```zig
const std = @import("std");
const benchmark_mod = @import("benchmark.zig");

fn sumIterative(n: u64) u64 {
    var sum: u64 = 0;
    var i: u64 = 1;
    while (i <= n) : (i += 1) {
        sum += i;
    }
    return sum;
}

fn sumFormula(n: u64) u64 {
    return (n * (n + 1)) / 2;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const iterations = 1_000_000;
    const n = 1000;

    try stdout.print("Benchmarking sum algorithms ({d} iterations)...\n\n", .{iterations});

    // Benchmark iterative approach
    const iterative_result = try benchmark_mod.benchmarkWithArg(
        @TypeOf(sumIterative),
        sumIterative,
        n,
        iterations,
    );

    // Benchmark formula approach
    const formula_result = try benchmark_mod.benchmarkWithArg(
        @TypeOf(sumFormula),
        sumFormula,
        n,
        iterations,
    );

    // Compare results
    try benchmark_mod.compareBenchmarks(
        stdout,
        "Formula",
        formula_result,
        "Iterative",
        iterative_result,
    );
}
```

**Patterns Demonstrated:**
- Warm-up iterations before measurement
- Multiple sample collection for statistics
- `std.mem.doNotOptimizeAway` to prevent optimization
- Computing min, max, mean, and variance
- Human-readable result formatting
- Comparison utilities with speedup calculation
- Coefficient of variation for consistency measurement

The complete example includes sorting algorithm benchmarks and slice operation timing. Build with `zig build -Doptimize=ReleaseFast` and run with `./zig-out/bin/benchmarking-demo`.

### Example 6: Profiling Integration

This example demonstrates build configuration for profiling, integration with Callgrind, perf, Massif, and flame graph generation.

**Location:** `/home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling/`

**Build Configuration (build.zig):**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "profiling-demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,  // Keep symbols for profiling
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the profiling demo");
    run_step.dependOn(&run_cmd.step);
}
```

**Profiling Script (scripts/profile_perf.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile with perf
echo "Recording profile with perf..."
perf record -F 999 -g ./zig-out/bin/profiling-demo

# Generate report
echo "Generating perf report..."
perf report --stdio > perf_report.txt

# Generate flame graph (if FlameGraph tools available)
if [ -d "FlameGraph" ]; then
    echo "Generating flame graph..."
    perf script > out.perf
    ./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
    ./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
    echo "Flame graph saved to flamegraph.svg"
fi

echo "Done! View perf_report.txt or flamegraph.svg"
```

**Profiling Script (scripts/profile_callgrind.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile with callgrind
echo "Running callgrind..."
valgrind --tool=callgrind \
         --callgrind-out-file=callgrind.out \
         ./zig-out/bin/profiling-demo

# Annotate results
echo "Generating annotated output..."
callgrind_annotate callgrind.out > callgrind_report.txt

echo "Done! View callgrind_report.txt or open callgrind.out with kcachegrind"
```

**Profiling Script (scripts/profile_massif.sh):**

```bash
#!/bin/bash
set -e

# Build optimized binary with symbols
zig build -Doptimize=ReleaseFast -Dstrip=false

# Profile heap with massif
echo "Running massif..."
valgrind --tool=massif \
         --massif-out-file=massif.out \
         ./zig-out/bin/profiling-demo

# Print report
echo "Generating massif report..."
ms_print massif.out > massif_report.txt

echo "Done! View massif_report.txt"
```

**Patterns Demonstrated:**
- Build configuration with symbols preserved
- Integration with multiple profiling tools
- Automation scripts for profiling workflows
- Flame graph generation from perf data
- Callgrind for deterministic profiling
- Massif for heap profiling
- Practical profiling workflow

The complete example includes a demo application with computation, allocation, and I/O operations suitable for profiling. Run scripts from the project root: `./scripts/profile_perf.sh`.

## Common Pitfalls

This section documents frequent testing and benchmarking errors with incorrect and correct examples.

### Pitfall 1: Forgetting to Free Allocations

Memory leaks fail tests when using `testing.allocator`.

❌ **Incorrect:**
```zig
test "memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    // Forgot list.deinit()

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
// Test fails: memory leak detected
```

✅ **Correct:**
```zig
test "no memory leak" {
    var list = try std.ArrayList(u32).initCapacity(testing.allocator, 10);
    defer list.deinit();  // Always defer cleanup

    try list.append(42);
    try testing.expectEqual(1, list.items.len);
}
```

**Pattern:** Always pair allocation with `defer` cleanup immediately after initialization.

### Pitfall 2: Not Testing Error Paths

Testing only success paths leaves error handling unvalidated.

❌ **Incorrect:**
```zig
// Only tests happy path
test "parseNumber works" {
    const result = try parseNumber("42");
    try testing.expectEqual(42, result);
}
// What if input is invalid? Untested!
```

✅ **Correct:**
```zig
test "parseNumber: valid input" {
    const result = try parseNumber("42");
    try testing.expectEqual(42, result);
}

test "parseNumber: invalid input" {
    const result = parseNumber("not a number");
    try testing.expectError(error.InvalidFormat, result);
}

test "parseNumber: overflow" {
    const result = parseNumber("999999999999999999999");
    try testing.expectError(error.Overflow, result);
}
```

**Pattern:** Test both success and failure cases. Use `FailingAllocator` for allocation failures.

### Pitfall 3: Benchmarking Without doNotOptimizeAway

The compiler may optimize away entire benchmarks as dead code.

❌ **Incorrect:**
```zig
// Compiler may optimize away the entire loop
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    // result unused - dead code elimination
}
const elapsed = timer.read();
```

✅ **Correct:**
```zig
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = expensiveFunction();
    std.mem.doNotOptimizeAway(&result);  // Force compiler to keep it
}
const elapsed = timer.read();
```

**Pattern:** Always use `std.mem.doNotOptimizeAway` on benchmark results.

### Pitfall 4: Single Benchmark Measurement

Single measurements are unreliable due to context switches and cache state.

❌ **Incorrect:**
```zig
// Unreliable - affected by context switches
var timer = try std.time.Timer.start();
expensiveOperation();
const elapsed = timer.read();
std.debug.print("Took {d} ns\n", .{elapsed});
```

✅ **Correct:**
```zig
// Take multiple samples and compute statistics
const num_samples = 10;
var samples: [10]u64 = undefined;

for (&samples) |*sample| {
    var timer = try std.time.Timer.start();
    expensiveOperation();
    sample.* = timer.read();
}

// Compute min, max, mean
var min: u64 = std.math.maxInt(u64);
var max: u64 = 0;
var sum: u64 = 0;

for (samples) |s| {
    min = @min(min, s);
    max = @max(max, s);
    sum += s;
}

const avg = sum / num_samples;
std.debug.print("Min: {d} ns, Max: {d} ns, Avg: {d} ns\n", .{min, max, avg});
```

**Pattern:** Always collect multiple samples and report statistics.

### Pitfall 5: Benchmarking in Debug Mode

Debug mode results are meaningless—10-100x slower than release mode.

❌ **Incorrect:**
```bash
# Compiled with: zig build-exe benchmark.zig
# Results are 10-100x slower than release mode
```

✅ **Correct:**
```bash
# Always benchmark in release mode
zig build-exe -O ReleaseFast benchmark.zig
```

**Pattern:** Use `ReleaseFast` for benchmarks. Verify mode in build.zig.

### Pitfall 6: No Warm-up Phase

First iterations are slow due to cold caches and throttled CPU.

❌ **Incorrect:**
```zig
// First iterations are slow (cold cache, CPU throttled)
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    compute();
}
const elapsed = timer.read();
```

✅ **Correct:**
```zig
// Warm-up phase
for (0..100) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}

// Now measure with warm cache and stable CPU
var timer = try std.time.Timer.start();
for (0..1000) |_| {
    const result = compute();
    std.mem.doNotOptimizeAway(&result);
}
const elapsed = timer.read();
```

**Pattern:** Always warm up before measurement.

### Pitfall 7: Profiling Without Debug Symbols

Stripped binaries lose function names, making profiling output useless.

❌ **Incorrect:**
```bash
# Stripped binary loses function names
zig build -Doptimize=ReleaseFast -Dstrip=true
perf record ./zig-out/bin/myapp
perf report
# Shows only addresses, no function names
```

✅ **Correct:**
```bash
# Keep symbols for profiling
zig build -Doptimize=ReleaseFast -Dstrip=false
perf record ./zig-out/bin/myapp
perf report
# Shows function names and line numbers
```

**Pattern:** Always build with symbols for profiling (`-Dstrip=false`).

### Pitfall 8: Testing Implementation Details

Testing internal implementation is fragile—tests break when refactoring.

❌ **Incorrect:**
```zig
test "ArrayList internal capacity" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    // Testing internal implementation detail
    try testing.expect(list.capacity == 0);
    try list.append(1);
    try testing.expect(list.capacity >= 1);  // Fragile
}
```

✅ **Correct:**
```zig
test "ArrayList: append increases length" {
    var list = std.ArrayList(u32).init(testing.allocator);
    defer list.deinit();

    try testing.expectEqual(@as(usize, 0), list.items.len);
    try list.append(1);
    try testing.expectEqual(@as(usize, 1), list.items.len);
    try testing.expectEqual(@as(u32, 1), list.items[0]);
}
```

**Pattern:** Test behavior, not implementation. Focus on public API.

### Pitfall 9: Race Conditions in Concurrent Tests

Concurrent tests without synchronization produce random failures.

❌ **Incorrect:**
```zig
test "concurrent counter" {
    var counter: u32 = 0;  // No synchronization

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *u32) void {
                for (0..1000) |_| {
                    c.* += 1;  // Race condition
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| t.join();

    try testing.expectEqual(@as(u32, 4000), counter);  // May fail randomly
}
```

✅ **Correct:**
```zig
test "concurrent atomic counter" {
    var counter = std.atomic.Value(u32).init(0);

    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: *std.atomic.Value(u32)) void {
                for (0..1000) |_| {
                    _ = c.fetchAdd(1, .monotonic);  // Atomic operation
                }
            }
        }.run, .{&counter});
    }

    for (threads) |t| t.join();

    try testing.expectEqual(@as(u32, 4000), counter.load(.monotonic));
}
```

**Pattern:** Use atomics or mutexes for shared state in concurrent tests.

### Pitfall 10: Comparing Floats with expectEqual

Floating-point arithmetic introduces rounding errors.

❌ **Incorrect:**
```zig
test "float equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectEqual(@as(f64, 2.0), result);  // May fail
}
```

✅ **Correct:**
```zig
test "float approximate equality" {
    const result = std.math.sqrt(2.0) * std.math.sqrt(2.0);
    try testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}
```

**Pattern:** Use `expectApproxEqAbs` or `expectApproxEqRel` for floating-point comparisons.

### Pitfall 11: Hardcoded Test Data Paths

Hardcoded paths break in different environments.

❌ **Incorrect:**
```zig
test "load config file" {
    const config = try loadConfig("/home/user/test/config.json");  // Hardcoded
    try testing.expect(config.valid);
}
```

✅ **Correct:**
```zig
test "load config file" {
    const config_content =
        \\{ "setting": "value" }
    ;

    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{ .sub_path = "config.json", .data = config_content });

    const path = try tmp.dir.realpathAlloc(testing.allocator, ".");
    defer testing.allocator.free(path);

    const file_path = try std.fs.path.join(testing.allocator, &.{path, "config.json"});
    defer testing.allocator.free(file_path);

    const config = try loadConfig(file_path);
    try testing.expect(config.valid);
}
```

**Pattern:** Use relative paths or create temporary files for tests.

### Pitfall 12: Over-reliance on Random Tests

Random tests without deterministic seeds produce unreproducible failures.

❌ **Incorrect:**
```zig
test "random behavior" {
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = prng.random();

    const value = random.int(u32);
    // Test logic based on random value...
    // Hard to reproduce failures
}
```

✅ **Correct:**
```zig
test "deterministic random behavior" {
    var prng = std.Random.DefaultPrng.init(testing.random_seed);  // Deterministic
    const random = prng.random();

    const value = random.int(u32);
    // Test logic...
    // Failures are reproducible with same seed
}
```

**Pattern:** Use `testing.random_seed` for reproducible randomness.

## In Practice

This section examines production patterns from real-world Zig projects, demonstrating how testing scales to complex systems.

### TigerBeetle: Sophisticated Testing Infrastructure

TigerBeetle, a distributed financial database, demonstrates advanced testing patterns for distributed systems.[^17]

**Deterministic Time Simulation:**

TigerBeetle's `TimeSim` enables testing distributed consensus without flakiness:[^18]

```zig
pub const TimeSim = struct {
    resolution: u64,
    offset_type: OffsetType,
    offset_coefficient_A: i64,
    offset_coefficient_B: i64,
    ticks: u64 = 0,
    epoch: i64 = 0,

    pub fn time(self: *TimeSim) Time {
        return .{
            .context = self,
            .vtable = &.{
                .monotonic = monotonic,
                .realtime = realtime,
                .tick = tick,
            },
        };
    }

    fn monotonic(context: *anyopaque) u64 {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        return self.ticks * self.resolution;
    }

    fn tick(context: *anyopaque) void {
        const self: *TimeSim = @ptrCast(@alignCast(context));
        self.ticks += 1;
    }
};
```

Key patterns:
- Controlled time advancement via `tick()`
- Multiple offset types (linear drift, periodic, step jumps)
- Simulates clock skew and NTP adjustments
- Deterministic testing of time-dependent logic

**Network Simulation and Fault Injection:**

TigerBeetle's `PacketSimulator` tests distributed systems under realistic network conditions:[^19]

```zig
pub const PacketSimulatorOptions = struct {
    one_way_delay_mean: Duration,
    one_way_delay_min: Duration,
    packet_loss_probability: Ratio = Ratio.zero(),
    packet_replay_probability: Ratio = Ratio.zero(),
    partition_mode: PartitionMode = .none,
    partition_probability: Ratio = Ratio.zero(),
    path_maximum_capacity: u8,
    path_clog_duration_mean: Duration,
    path_clog_probability: Ratio,
};
```

Simulates:
- Variable network delays
- Packet loss and replay attacks
- Network partitions (split-brain scenarios)
- Path congestion

This enables comprehensive testing of consensus algorithms under adversarial conditions.

**Snapshot Testing:**

TigerBeetle's `snaptest.zig` provides auto-updating snapshot assertions:[^20]

```zig
const Snap = @import("snaptest.zig").Snap;
const snap = Snap.snap_fn("src");

test "complex output" {
    const result = complexComputation();
    try snap(@src(),
        \\Expected output line 1
        \\Expected output line 2
    ).diff_fmt("{}", .{result});
}
```

Running with `SNAP_UPDATE=1` automatically updates source code snapshots on mismatch, drastically reducing refactoring friction.

**Fixture Pattern:**

Centralized initialization with sensible defaults:[^21]

```zig
pub const cluster: u128 = 0;
pub const replica: u8 = 0;
pub const replica_count: u8 = 6;

pub fn initStorage(allocator: std.mem.Allocator, options: Storage.Options) !Storage {
    return try Storage.init(allocator, options);
}

pub fn storageFormat(
    allocator: std.mem.Allocator,
    storage: *Storage,
    options: struct {
        cluster: u128 = cluster,
        replica: u8 = replica,
        replica_count: u8 = replica_count,
    },
) !void {
    // Complex initialization logic centralized
}
```

Benefits:
- Reduces test boilerplate
- Ensures consistent setup
- Single source of truth for defaults

### Ghostty: Cross-Platform Testing

Ghostty, a GPU-accelerated terminal emulator, demonstrates platform-specific testing patterns.[^22]

**Platform-Specific Tests:**

```zig
test "fc-list" {
    const testing = std.testing;

    var cfg = fontconfig.initLoadConfigAndFonts();
    defer cfg.destroy();

    var pat = fontconfig.Pattern.create();
    defer pat.destroy();

    var fs = cfg.fontList(pat, os);
    defer fs.destroy();

    // Environmental check: expect at least one font
    try testing.expect(fs.fonts().len > 0);
}
```

Pattern: Environmental assertions adapt to host system capabilities.

**Cleanup Patterns with errdefer:**

```zig
test "fc-match" {
    var cfg = fontconfig.initLoadConfigAndFonts();
    defer cfg.destroy();

    var pat = fontconfig.Pattern.create();
    errdefer pat.destroy();  // Cleanup on error

    try testing.expect(cfg.substituteWithPat(pat, .pattern));
    pat.defaultSubstitute();

    const result = cfg.fontSort(pat, false, null);
    errdefer result.fs.destroy();  // Cleanup on error

    // Success path cleanup
    result.fs.destroy();
    pat.destroy();
}
```

Pattern: `defer` for success cleanup, `errdefer` for error paths.

### ZLS: Custom Testing Utilities

ZLS (Zig Language Server) provides enhanced testing utilities.[^23]

**Custom Equality Comparison:**

```zig
pub fn expectEqual(expected: anytype, actual: anytype) error{TestExpectedEqual}!void {
    const expected_json = std.json.Stringify.valueAlloc(allocator, expected, .{
        .whitespace = .indent_2,
        .emit_null_optional_fields = false,
    }) catch @panic("OOM");
    defer allocator.free(expected_json);

    const actual_json = std.json.Stringify.valueAlloc(allocator, actual, .{
        .whitespace = .indent_2,
        .emit_null_optional_fields = false,
    }) catch @panic("OOM");
    defer allocator.free(actual_json);

    if (std.mem.eql(u8, expected_json, actual_json)) return;
    renderLineDiff(allocator, expected_json, actual_json);
    return error.TestExpectedEqual;
}
```

Benefits:
- Semantic comparison via JSON serialization
- Human-readable diffs for complex structures
- Better diagnostics than default `expectEqual`

**Probabilistic FailingAllocator:**

ZLS's enhanced `FailingAllocator`:[^24]

```zig
pub const FailingAllocator = struct {
    likelihood: u32,

    /// Chance of failure is 1/likelihood
    pub fn init(internal_allocator: std.mem.Allocator, likelihood: u32) FailingAllocator {
        return .{
            .internal_allocator = internal_allocator,
            .random = .init(std.crypto.random.int(u64)),
            .likelihood = likelihood,
        };
    }

    fn shouldFail(self: *FailingAllocator) bool {
        if (self.likelihood == std.math.maxInt(u32)) return false;
        return 0 == self.random.random().intRangeAtMostBiased(u32, 0, self.likelihood);
    }
};
```

More flexible than Zig's built-in `FailingAllocator`, enabling probabilistic failure patterns for comprehensive error testing.

### Zig Standard Library Patterns

The standard library demonstrates idiomatic testing patterns.

**Colocated Tests:**

```zig
// std/array_list.zig
pub const ArrayList = struct {
    // Implementation...
};

test "init" {
    const list = ArrayList(u32).init(testing.allocator);
    defer list.deinit();
    try testing.expectEqual(@as(usize, 0), list.items.len);
}

test "basic" {
    var list = ArrayList(i32).init(testing.allocator);
    defer list.deinit();

    // Test basic operations...
}
```

**Generic Testing Across Types:**

```zig
test "HashMap: basic usage" {
    inline for ([_]type{ u32, i32, u64 }) |K| {
        inline for ([_]type{ u32, []const u8 }) |V| {
            var map = std.AutoHashMap(K, V).init(testing.allocator);
            defer map.deinit();

            // Test operations with K, V
        }
    }
}
```

Pattern: `inline for` over types generates separate tests for each combination.

### Mach: Game Engine Testing Patterns

Mach demonstrates testing patterns for graphics-intensive applications, including custom test utilities, SIMD-aligned data, and stress testing for concurrent data structures.

**1. Custom Type-Aware Equality Assertion**[^mach_test1]

Mach provides a custom `expect()` function with better ergonomics than `std.testing`:

```zig
// mach/src/testing.zig:204
pub fn expect(comptime T: type, expected: T) Expect(T) {
    return Expect(T){ .expected = expected };
}
```

**Usage comparison:**

```zig
// std.testing (verbose, error-prone)
try std.testing.expectEqual(@as(u32, 1337), actual());
try std.testing.expectApproxEqAbs(@as(f32, 1.0), actual(), std.math.floatEps(f32));

// mach.testing (concise, type-safe)
try mach.testing.expect(u32, 1337).eql(actual());
try mach.testing.expect(f32, 1.0).eql(actual());  // Epsilon equality by default
```

**Floating-point equality modes:**[^mach_test1]

```zig
// mach/src/testing.zig:12-24
pub fn eql(e: *const @This(), actual: T) !void {
    try e.eqlApprox(actual, math.eps(T));  // Epsilon tolerance
}

pub fn eqlApprox(e: *const @This(), actual: T, tolerance: T) !void {
    if (!math.eql(T, e.expected, actual, tolerance)) {
        std.debug.print("actual float {d}, expected {d} (not within absolute epsilon tolerance {d})\n",
            .{ actual, e.expected, tolerance });
        return error.TestExpectEqualEps;
    }
}

pub fn eqlBinary(e: *const @This(), actual: T) !void {
    try testing.expectEqual(e.expected, actual);  // Exact bitwise equality
}
```

**Why this matters:** Game engines heavily use floating-point math. Default epsilon equality prevents spurious failures from rounding errors, while `.eqlBinary()` is available for exact checks when needed.

**2. SIMD-Aligned Audio Buffer Testing**[^mach_audio]

Mach's audio tests demonstrate testing SIMD-optimized code with properly aligned buffers:

```zig
// mach/src/Audio.zig:358-376
test "mixSamples - basic mono to mono mixing" {
    var dst_buffer align(alignment) = [_]f32{0} ** 16;
    const src_buffer align(alignment) = [_]f32{ 1.0, 2.0, 3.0, 4.0 } ** 4;

    const new_index = mixSamples(
        &dst_buffer,
        1, // dst_channels
        &src_buffer,
        0, // src_index
        1, // src_channels
        0.5, // src_volume
    );

    try testing.expect(usize, 16).eql(new_index);
    try testing.expect(f32, 0.5).eql(dst_buffer[0]);
    try testing.expect(f32, 1.0).eql(dst_buffer[1]);
    try testing.expect(f32, 1.5).eql(dst_buffer[2]);
    try testing.expect(f32, 2.0).eql(dst_buffer[3]);
}
```

**Key pattern:** `align(alignment)` ensures buffers meet SIMD requirements (typically 16-byte aligned for SSE). Without proper alignment, SIMD instructions can crash or silently degrade to scalar operations.

**3. Comprehensive Coverage with Multiple Test Scenarios**[^mach_audio]

Mach tests audio mixing across multiple dimensions:

```zig
// Six test cases covering the combinatorial space:
test "mixSamples - basic mono to mono mixing"
test "mixSamples - stereo to stereo mixing"
test "mixSamples - mono to stereo mixing (channel duplication)"
test "mixSamples - partial buffer processing"
test "mixSamples - mixing with volume adjustment"
test "mixSamples - accumulation test"
```

**Pattern:** Systematically test edges of the parameter space (mono/stereo × mono/stereo × volume × partial processing) rather than random inputs. This catches bugs at boundaries.

**4. Stress Testing Concurrent Data Structures**[^mach_mpsc]

Mach's MPSC queue stress test uses `std.Thread.Pool` to verify lock-free correctness:

```zig
// mach/src/mpsc.zig (test "concurrent producers")
test "concurrent producers" {
    const allocator = std.testing.allocator;

    var queue: Queue(u32) = undefined;
    try queue.init(allocator, 32);
    defer queue.deinit(allocator);

    const n_jobs = 100;
    const n_entries: u32 = 10000;

    var pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&pool, .{ .allocator = allocator, .n_jobs = n_jobs });
    defer pool.deinit();

    var wg: std.Thread.WaitGroup = .{};
    for (0..n_jobs) |_| {
        pool.spawnWg(
            &wg,
            struct {
                pub fn run(q: *Queue(u32)) void {
                    var i: u32 = 0;
                    while (i < n_entries) : (i += 1) {
                        q.push(allocator, i) catch unreachable;
                    }
                }
            }.run,
            .{&queue},
        );
    }

    wg.wait();  // Block until all producers complete

    // Verify all items were enqueued
    var count: u32 = 0;
    while (queue.pop()) |_| count += 1;

    try std.testing.expectEqual(n_jobs * n_entries, count);
}
```

**Pattern breakdown:**
- **Thread.Pool**: Manages thread lifecycle automatically
- **WaitGroup**: Synchronizes completion of all producers
- **Anonymous struct with run()**: Captures queue pointer without heap allocation
- **High iteration count**: 100 threads × 10,000 items = 1 million operations stress tests race conditions

**Why this works:** Lock-free data structures can have subtle race conditions that only appear under heavy contention. The test spawns 100 concurrent producers to maximize contention and surface bugs.

**5. Vector and Matrix Testing with Epsilon Tolerance**[^mach_test2]

Mach extends epsilon equality to SIMD vectors:

```zig
// mach/src/testing.zig:33-54
fn ExpectVector(comptime T: type) type {
    const Elem = std.meta.Elem(T);
    const len = @typeInfo(T).vector.len;
    return struct {
        expected: T,

        pub fn eqlApprox(e: *const @This(), actual: T, tolerance: Elem) !void {
            var i: usize = 0;
            while (i < len) : (i += 1) {
                if (!math.eql(Elem, e.expected[i], actual[i], tolerance)) {
                    std.debug.print("actual vector {d}, expected {d} (tolerance {d})\n",
                        .{ actual, e.expected, tolerance });
                    std.debug.print("actual vector[{}] = {d}, expected {d}\n",
                        .{ i, actual[i], e.expected[i] });
                    return error.TestExpectEqualEps;
                }
            }
        }
    };
}
```

**Benefit:** When a vector comparison fails, the error message shows:
1. The full vector (all elements)
2. The specific failing element index
3. Expected and actual values for that element

This drastically reduces debugging time for SIMD code.

**Key Takeaways from Mach:**
- **Type-aware assertions** reduce boilerplate and prevent type annotation errors
- **Epsilon equality by default** for floats prevents spurious failures from rounding
- **SIMD alignment** in tests ensures production code path is actually tested
- **Systematic scenario coverage** catches boundary conditions better than random testing
- **Stress testing with Thread.Pool** validates concurrent data structures under contention
- **Enhanced error messages** for vectors show exactly which element failed

## Summary

Zig's integrated approach to testing, benchmarking, and profiling provides developers with powerful tools for building reliable, performant software. This chapter covered the complete spectrum from basic test blocks to advanced production patterns.

**Core Mental Models:**

1. **Built-in Testing Integration**: Tests are first-class language features, not external dependencies. The `zig test` command discovers and executes tests automatically, providing immediate feedback without configuration overhead.

2. **Memory Safety as Default**: `testing.allocator` automatically detects memory leaks, enforcing cleanup discipline from the start. Tests fail on leaks, making memory safety violations immediately visible.

3. **Determinism Over Convenience**: Zig prioritizes reproducible results. Sequential test execution, deterministic random seeds, and explicit benchmarking control ensure consistent behavior across runs and environments.

4. **Manual Instrumentation for Accuracy**: Benchmarking requires explicit measurement using `std.time.Timer`, warm-up iterations, and `std.mem.doNotOptimizeAway`. This design prevents subtle measurement errors common in automatic frameworks.

5. **Tool Integration Not Replacement**: Profiling leverages industry-standard tools (perf, Valgrind) rather than custom solutions. Zig's build system configures symbols and optimization flags for effective profiling.

6. **Test Organization Flexibility**: Colocated tests keep implementation and validation synchronized. Separate test utilities handle reusable infrastructure. The `builtin.is_test` flag conditionally compiles test-only code without production overhead.

**When to Use What:**

| Use Case | Approach | Key Considerations |
|----------|----------|-------------------|
| Unit testing | Colocated test blocks | Use `testing.allocator`, test error paths |
| Integration testing | Separate test files | Setup fixtures, use arena allocators |
| Memory testing | `testing.allocator` + `FailingAllocator` | Test both success and failure paths |
| Parameterized testing | Table-driven with `inline for` | Comptime test generation for types |
| Benchmarking | Manual `Timer` + statistics | Warm-up, `doNotOptimizeAway`, multiple samples |
| Performance profiling | perf for sampling | Low overhead, production-realistic |
| Detailed profiling | Callgrind for instructions | Deterministic, high overhead |
| Memory profiling | Massif for heap analysis | Track allocations over time |

**Best Practices Recap:**

1. Always use `defer` for cleanup immediately after allocation
2. Test both success and error paths systematically
3. Use `testing.allocator` for automatic leak detection
4. Employ `FailingAllocator` to test allocation failure paths
5. Structure tests with descriptive names and clear assertions
6. Organize reusable test infrastructure in dedicated modules
7. Include warm-up iterations in benchmarks
8. Use `std.mem.doNotOptimizeAway` to prevent optimization
9. Collect multiple samples and compute statistics
10. Always benchmark in `ReleaseFast` mode
11. Build with symbols (`-Dstrip=false`) for profiling
12. Use `inline for` for parameterized tests across types

**Common Mistakes to Avoid:**

- Forgetting to free allocations in tests
- Testing only success paths without error handling
- Benchmarking without `doNotOptimizeAway`
- Single measurements without statistical analysis
- Benchmarking in Debug mode
- No warm-up phase before measurement
- Profiling without debug symbols
- Testing implementation details instead of behavior
- Race conditions in concurrent tests
- Using `expectEqual` for floating-point comparisons
- Hardcoded test data paths
- Random tests without deterministic seeds

**Production Patterns:**

Real-world projects demonstrate scaling these techniques:

- **TigerBeetle**: Deterministic time simulation, network fault injection, snapshot testing, comprehensive fixture patterns
- **Ghostty**: Platform-specific testing, cross-platform assertions, robust cleanup with `errdefer`
- **ZLS**: Custom equality comparison, enhanced `FailingAllocator`, semantic diff generation
- **Zig stdlib**: Colocated tests, generic type testing, consistent naming conventions

These patterns show Zig's testing philosophy in action: simplicity, explicitness, and zero hidden costs. Tests integrate seamlessly with development workflow. Benchmarking provides accurate measurements without magic. Profiling leverages proven tools with proper build configuration.

The manual nature of benchmarking and profiling in Zig might seem verbose compared to automatic frameworks. However, this explicitness prevents subtle errors and ensures developers understand what they're measuring. The cost is initial setup; the benefit is confidence in results.

Testing in Zig enforces good practices through the type system and memory model. Memory leak detection isn't optional—it's automatic. Error handling isn't suggested—the type system requires it. This design guides developers toward correct, maintainable code.

For developers new to Zig, start with basic test blocks and `testing.allocator`. Progress to table-driven tests for comprehensive validation. Add benchmarking when optimization matters. Integrate profiling when performance analysis requires detailed insights. The tools grow with project complexity.

The testing, benchmarking, and profiling capabilities in Zig enable building robust systems with confidence. From prototype through production, these integrated tools support the complete development lifecycle. Understanding and applying these patterns equips developers to write correct, performant Zig code.

## References

1. [Zig Language Reference: Testing](https://ziglang.org/documentation/master/#Testing)
2. [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76)
3. [Zig Standard Library: std.testing](https://ziglang.org/documentation/master/std/#std.testing)
4. [Zig stdlib: FailingAllocator](https://github.com/ziglang/zig/blob/master/lib/std/testing/FailingAllocator.zig)
5. [ZLS Custom FailingAllocator](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)
6. [TigerBeetle testing/ directory](https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing)
7. [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig#L33-L52)
8. [Zig Build System Guide](https://ziglang.org/learn/build-system/)
9. [TigerBeetle time.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98)
10. [Zig stdlib: std.time.Timer](https://github.com/ziglang/zig/blob/master/lib/std/time.zig#L216-L268)
11. [Zig stdlib: std.mem.doNotOptimizeAway](https://github.com/ziglang/zig/blob/master/lib/std/mem.zig)
12. [Example 06: Profiling](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling)
13. [Valgrind Callgrind Documentation](https://valgrind.org/docs/manual/cl-manual.html)
14. [Linux perf Tutorial](https://perf.wiki.kernel.org/index.php/Tutorial)
15. [Valgrind Massif Documentation](https://valgrind.org/docs/manual/ms-manual.html)
16. [Brendan Gregg's Flame Graphs](https://www.brendangregg.com/flamegraphs.html)
17. [TigerBeetle GitHub Repository](https://github.com/tigerbeetle/tigerbeetle)
18. [TigerBeetle time.zig deterministic simulation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig)
19. [TigerBeetle packet_simulator.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig#L11-L42)
20. [TigerBeetle snaptest.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig)
21. [TigerBeetle fixtures.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig)
22. [Ghostty fontconfig test.zig](https://github.com/ghostty-org/ghostty/blob/main/pkg/fontconfig/test.zig)
23. [ZLS testing.zig](https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26)
24. [ZLS FailingAllocator](https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141)
25. [Zig Standard Library array_list.zig](https://github.com/ziglang/zig/blob/master/lib/std/array_list.zig)
26. [Zig Standard Library hash_map.zig](https://github.com/ziglang/zig/blob/master/lib/std/hash_map.zig)
27. [FlameGraph GitHub Repository](https://github.com/brendangregg/FlameGraph)
28. [Example 01: Testing Fundamentals](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/01_testing_fundamentals)
29. [Example 02: Test Organization](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/02_test_organization)
30. [Example 03: Parameterized Tests](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/03_parameterized_tests)
31. [Example 04: Allocator Testing](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/04_allocator_testing)
32. [Example 05: Benchmarking](file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/05_benchmarking)
33. [TigerBeetle fuzz.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fuzz.zig)
34. [TigerBeetle storage.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/storage.zig)
35. [Zig 0.15 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
36. [Wasmtime Documentation](https://docs.wasmtime.dev/)
37. [WASI Tutorial](https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-tutorial.md)
38. [KCachegrind Documentation](https://kcachegrind.github.io/html/Home.html)
39. [Perf Wiki](https://perf.wiki.kernel.org/)
40. [Massif Visualizer](https://github.com/KDE/massif-visualizer)
41. [Hotspot Profiler](https://github.com/KDAB/hotspot)
42. [Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/)
43. [Zig Community: Testing Best Practices](https://github.com/ziglang/zig/wiki/Testing-Best-Practices)
44. [TigerBeetle state_machine_tests.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/state_machine_tests.zig)
45. [Ghostty freetype test.zig](https://github.com/ghostty-org/ghostty/blob/main/pkg/freetype/test.zig)

[^mach_test1]: [Mach Source: Custom Equality Assertion with Epsilon Tolerance](https://github.com/hexops/mach/blob/main/src/testing.zig) - Type-aware expect() function with default epsilon equality for floats
[^mach_test2]: [Mach Source: Vector Epsilon Equality](https://github.com/hexops/mach/blob/main/src/testing.zig#L33-L54) - SIMD vector testing with per-element error reporting
[^mach_audio]: [Mach Source: SIMD-Aligned Audio Tests](https://github.com/hexops/mach/blob/main/src/Audio.zig#L358-L473) - Audio mixing tests with aligned buffers and systematic scenario coverage
[^mach_mpsc]: [Mach Source: MPSC Stress Test](https://github.com/hexops/mach/blob/main/src/mpsc.zig) - Concurrent producer stress test with Thread.Pool and WaitGroup

[^1]: https://ziglang.org/documentation/master/#Testing
[^2]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig#L74-L76
[^3]: https://ziglang.org/documentation/master/std/#std.testing
[^4]: https://github.com/ziglang/zig/blob/master/lib/std/testing/FailingAllocator.zig
[^5]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141
[^6]: https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing
[^7]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig#L33-L52
[^8]: https://ziglang.org/learn/build-system/
[^9]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig#L12-L98
[^10]: https://github.com/ziglang/zig/blob/master/lib/std/time.zig#L216-L268
[^11]: https://github.com/ziglang/zig/blob/master/lib/std/mem.zig
[^12]: file:///home/user/zig_guide/sections/12_testing_benchmarking/examples/06_profiling
[^13]: https://valgrind.org/docs/manual/cl-manual.html
[^14]: https://perf.wiki.kernel.org/index.php/Tutorial
[^15]: https://valgrind.org/docs/manual/ms-manual.html
[^16]: https://www.brendangregg.com/flamegraphs.html
[^17]: https://github.com/tigerbeetle/tigerbeetle
[^18]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/time.zig
[^19]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/packet_simulator.zig#L11-L42
[^20]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/stdx/testing/snaptest.zig
[^21]: https://github.com/tigerbeetle/tigerbeetle/blob/main/src/testing/fixtures.zig
[^22]: https://github.com/ghostty-org/ghostty/blob/main/pkg/fontconfig/test.zig
[^23]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L9-L26
[^24]: https://github.com/zigtools/zls/blob/master/src/testing.zig#L67-L141
# Logging, Diagnostics & Observability

> **TL;DR for production logging:**
> - **std.log:** Built-in logging with compile-time levels (err, warn, info, debug)
> - **Compile-time filtering:** Disabled logs have zero runtime cost
> - **Usage:** `std.log.info("msg {d}", .{val})` or scoped: `const log = std.log.scoped(.network);`
> - **Custom loggers:** Implement `pub fn log(...)` for custom formatting/output (JSON, metrics)
> - **Production:** std.log to stderr by default, override for structured logging
> - **Jump to:** [Basic logging §12.2](#stdlog-usage) | [Scopes §12.3](#log-scopes) | [Custom loggers §12.4](#custom-log-implementations)

## Overview

Production systems require visibility into their runtime behavior to debug issues, monitor health, and understand performance characteristics. Zig provides `std.log` as its standard logging facility, designed with compile-time optimization and zero-cost abstractions as core principles.

Unlike runtime logging frameworks in other languages, Zig's logging system leverages compile-time evaluation to completely remove filtered log statements from compiled binaries. This design eliminates the traditional trade-off between observability and performance—developers can instrument code freely without impacting production performance when logs are disabled.

**Key Characteristics:**

- **Compile-time filtering**: Disabled logs have zero runtime cost
- **Scope-based organization**: Categorize logs by subsystem
- **Customizable output**: Override log handlers for structured formats
- **Thread-safe by default**: Built-in synchronization for concurrent access
- **Minimal overhead**: Default handler uses stack-only buffers

This chapter covers practical logging patterns for development debugging, testing diagnostics, and production observability. We examine real-world usage from production Zig codebases including TigerBeetle, Ghostty, Bun, and ZLS to demonstrate proven approaches.

### Why Logging Matters

**Development:** Logging provides runtime visibility during active development, helping developers understand program flow, inspect state, and diagnose unexpected behavior without a debugger.

**Testing:** Test-specific logging improves failure diagnostics, making it easier to understand why a test failed and reproduce issues in CI environments.

**Production:** Operational logging enables monitoring, alerting, debugging customer issues, and understanding system behavior at scale.

**Zig's Approach:** The std.log system balances these needs through compile-time configuration—verbose logging during development, focused logging in production, all with minimal runtime cost.

### Chapter Roadmap

This chapter covers six major topics:

1. **std.log Fundamentals** - Architecture, log levels, and core API
2. **Scoped Logging** - Organizing logs by subsystem
3. **Custom Log Handlers** - Structured output and platform integration
4. **Diagnostic Patterns** - Testing and development diagnostics
5. **Production Strategies** - Performance-conscious production logging
6. **Observability Integration** - Structured logging and distributed tracing

---

## Core Concepts

### The std.log Module

Zig's logging system is defined in `std/log.zig` and provides a standardized interface that libraries and applications can use consistently[^1]. The core design principle is compile-time optimization: log statements filtered out at compile time are completely removed from the binary.

**Architecture Overview:**

```zig
const std = @import("std");
const log = std.log;

pub fn main() void {
    log.err("Error: critical failure", .{});
    log.warn("Warning: approaching limit", .{});
    log.info("Info: request completed", .{});
    log.debug("Debug: cache hit", .{});
}
```

Each log level represents a different severity:

- **err**: Errors that require attention
- **warn**: Potential issues worth investigating
- **info**: Important state changes and events
- **debug**: Detailed diagnostics for development

**Compile-Time Filtering:**

The `std.log.logEnabled()` function determines at compile time whether a log statement should be included:

```zig
fn log(
    comptime message_level: Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Compile-time check - filtered logs are completely removed
    if (comptime !logEnabled(message_level, scope)) return;

    std.options.logFn(message_level, scope, format, args);
}
```

When a log is filtered out, the entire function call—including argument evaluation—is eliminated during compilation. This provides true zero-cost abstraction for disabled logs[^1].

### Log Levels and Hierarchy

Zig defines four log levels with increasing verbosity:

```zig
pub const Level = enum {
    err,    // 0 - Highest priority
    warn,   // 1
    info,   // 2
    debug,  // 3 - Lowest priority
};
```

The numeric values determine filtering: a log level setting of `.warn` enables `err` and `warn` but filters out `info` and `debug`.

**Default Log Level:**

The default log level depends on the build mode[^1]:

```zig
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,                              // All logs enabled
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,  // Debug logs filtered out
};
```

This provides verbose logging during development (Debug mode) while automatically reducing log volume in release builds.

**Level Selection Guidelines:**

| Level | Use Case | Production? | Example |
|-------|----------|-------------|---------|
| `err` | Unrecoverable errors, data corruption, resource failures | Always enabled | `log.err("Database connection failed: {s}", .{@errorName(err)})` |
| `warn` | Approaching limits, deprecated usage, recoverable errors | Usually enabled | `log.warn("Connection pool at 90% capacity", .{})` |
| `info` | Lifecycle events, state changes, request completion | Selectively enabled (may be sampled) | `log.info("Server started on port {d}", .{port})` |
| `debug` | Internal state, algorithm traces, cache behavior | Development only | `log.debug("Cache hit for key: {s}", .{key})` |

**Configuring Log Levels:**

Set the global log level through `std.Options`:

```zig
pub const std_options: std.Options = .{
    .log_level = .info,  // Filter out debug logs
};
```

For finer control, set per-scope levels:

```zig
pub const std_options: std.Options = .{
    .log_level = .info,  // Global default
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .network, .level = .debug },  // Verbose network logs
        .{ .scope = .cache, .level = .warn },     // Only cache warnings
    },
};
```

This enables debugging specific subsystems without flooding logs with output from other components.

### Scoped Logging

Scopes provide a namespacing mechanism for categorizing log messages by subsystem or module. Each scope creates a separate logging namespace with its own filtering rules.

**Creating Scoped Loggers:**

```zig
const database_log = std.log.scoped(.database);
const network_log = std.log.scoped(.network);
const auth_log = std.log.scoped(.auth);

pub fn connectDatabase() !void {
    database_log.info("Connecting to database...", .{});
    database_log.debug("Connection string: {s}", .{conn_str});
}

pub fn handleRequest(req: Request) !void {
    network_log.info("GET {s}", .{req.path});

    if (req.needsAuth()) {
        auth_log.debug("Validating credentials", .{});
    }
}
```

**Output Format:**

Scoped logs include the scope name in the output:

```
info: Application started                    # Default scope
info(database): Connecting to database...     # Database scope
debug(database): Connection string: ...       # Database scope
info(network): GET /api/users                  # Network scope
debug(auth): Validating credentials           # Auth scope
```

The scope prefix makes it easy to filter logs by subsystem when debugging or analyzing production issues.

**Real-World Usage:**

TigerBeetle uses scoped logging extensively, with one scoped logger per module[^3]:

```zig
// In src/vsr.zig
const log = std.log.scoped(.vsr);

// In src/vsr/superblock.zig
const log = std.log.scoped(.superblock);

// In src/vsr/journal.zig
const log = std.log.scoped(.journal);

// In src/io/linux.zig
const log = std.log.scoped(.io);
```

This pattern enables filtering by subsystem during development (e.g., only show storage logs) while maintaining organized log output in production.

**Scope Naming Conventions:**

Based on analysis of production codebases, effective scope names are:

- Lowercase identifiers: `.database` not `.Database`
- Concise (1-2 words): `.network` not `.network_layer_handler`
- Functionally descriptive: `.auth` not `.module_3`
- Module-aligned: One scope per logical module

### Custom Log Handlers

The default log handler outputs to stderr with a simple format, but applications can override this behavior by providing a custom `logFn` in `std.Options`[^2].

**Handler Signature:**

```zig
pub fn customLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Custom handler implementation
}
```

The handler receives compile-time known level, scope, and format, plus runtime arguments. This enables optimization while providing flexibility.

**Default Handler Implementation:**

The standard library's default handler is instructive[^1]:

```zig
pub fn defaultLog(
    comptime message_level: Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderrWriter(&buffer);
    defer std.debug.unlockStderrWriter();

    nosuspend stderr.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}
```

**Key Features:**
- Uses 64-byte stack buffer (no heap allocation)
- Thread-safe via stderr locking
- Silently ignores write errors
- Outputs to stderr (keeps stdout clean for program output)

**Thread Safety Requirements:**

Custom handlers **must** be thread-safe. Use `std.debug.lockStdErr()` / `unlockStdErr()` to serialize access:

⚠️ **Version Note:** Custom log handlers require explicit buffer management in Zig 0.15+. The examples below show both the legacy 0.14.x API and the current 0.15+ buffered writer pattern. Buffering improves performance but requires appropriate buffer sizes for your logging needs. For real-time logging where immediate output is critical, use smaller buffers or call `.flush()` after writing.

```zig
pub fn threadSafeLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    // Safe to write to stderr while locked
    stderr.interface.print("[{s}] ({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

**Timestamped Handler:**

Adding timestamps helps correlate logs with external events:

```zig
pub fn timestampedLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    const timestamp = std.time.timestamp();

    nosuspend stderr.interface.print("[{d}] {s}({s}): " ++ format ++ "\n", .{
        timestamp,
        level.asText(),
        @tagName(scope),
    } ++ args) catch return;
}

pub const std_options: std.Options = .{
    .logFn = timestampedLogFn,
};
```

Output:
```
[1730860800] info(default): Application started
[1730860801] error(database): Connection failed
```

**JSON Structured Handler:**

For machine-parseable logs, output JSON:

```zig
pub fn jsonLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [2048]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
    const stderr = &stderr_writer.interface;

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Format message into buffer
    var buf: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

    nosuspend {
        stderr.writeAll("{\"timestamp\":") catch return;
        stderr.print("{d}", .{std.time.timestamp()}) catch return;
        stderr.writeAll(",\"level\":\"") catch return;
        stderr.writeAll(level.asText()) catch return;
        stderr.writeAll("\",\"scope\":\"") catch return;
        stderr.writeAll(@tagName(scope)) catch return;
        stderr.writeAll("\",\"message\":\"") catch return;

        // Escape special characters for valid JSON
        for (message) |c| {
            switch (c) {
                '"' => stderr.writeAll("\\\"") catch return,
                '\\' => stderr.writeAll("\\\\") catch return,
                '\n' => stderr.writeAll("\\n") catch return,
                else => stderr.writeByte(c) catch return,
            }
        }

        stderr.writeAll("\"}\n") catch return;
        stderr.flush() catch return;
    };
}
```

Output:
```json
{"timestamp":1730860800,"level":"info","scope":"default","message":"Application started"}
{"timestamp":1730860801,"level":"error","scope":"database","message":"Connection failed"}
```

This format integrates with log aggregation tools like Elasticsearch, Loki, and CloudWatch Logs.

**Platform-Specific Integration:**

Ghostty demonstrates platform-aware logging by integrating with macOS Unified Logging[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    if (builtin.target.os.tag.isDarwin()) {
        // Map Zig levels to macOS levels
        const mac_level: macos.os.LogType = switch (level) {
            .debug => .debug,
            .info => .info,
            .warn => .err,
            .err => .fault,
        };

        const logger = macos.os.Log.create(bundle_id, @tagName(scope));
        defer logger.release();
        logger.log(std.heap.c_allocator, mac_level, format, args);
    }

    // Also output to stderr
    var buffer: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&buffer);
    nosuspend stderr.print("{s}({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

This enables viewing logs via the macOS Console app or `log stream` command while maintaining cross-platform stderr output.

### Diagnostic Utilities

The `std.debug` module provides additional diagnostic tools complementing std.log[^6].

**Debug Printing:**

For quick printf-style debugging:

```zig
const std = @import("std");

pub fn debugExample() void {
    const value = 42;
    std.debug.print("Value: {d}\n", .{value});
}
```

**Important:** `std.debug.print` is for temporary debugging only. Use `std.log` for permanent instrumentation—it provides scoping, filtering, and consistent output format.

**Stack Traces:**

Generate stack traces for diagnostic output:

```zig
pub fn diagnoseError() void {
    std.log.err("Error occurred, dumping stack trace:", .{});
    std.debug.dumpCurrentStackTrace(null);
}
```

This prints a full stack trace showing the call chain leading to the current location. Useful for debugging unexpected code paths or error conditions.

**Limitations:**
- Requires debug symbols (doesn't work with stripped binaries)
- Not available on all platforms (WASM, some embedded targets)
- Performance overhead in debug builds

**Hex Dump:**

For inspecting binary data:

```zig
const data = [_]u8{ 0x48, 0x65, 0x6c, 0x6c, 0x6f };
std.debug.dumpHex(&data);
```

Output:
```
7ffc12345678  48 65 6c 6c 6f  Hello
```

Useful for debugging serialization, network protocols, or file formats.

**Assertions vs Logging:**

Assertions check invariants and panic if violated:

```zig
const assert = std.debug.assert;
assert(value > 0);  // Panics if false (in Debug/ReleaseSafe)
```

Logging reports observable events:

```zig
if (value <= 0) {
    log.err("Invalid value: {d}", .{value});
    return error.InvalidValue;
}
```

**Best Practice:** Use assertions for invariants that should never fail. Use logging for expected error conditions and observable state changes.

---

## Code Examples

### Example 1: Basic Logging with Scopes

This example demonstrates fundamental std.log usage with different levels and scopes.

**main.zig:**

```zig
const std = @import("std");
const database = @import("database.zig");
const network = @import("network.zig");

pub fn main() !void {
    const log = std.log;

    // Default scope logging
    log.info("Application started", .{});
    log.debug("Debug mode enabled", .{});

    const port: u16 = 8080;
    log.info("Server listening on port {d}", .{port});

    // Demonstrate all log levels
    log.err("This is an error message", .{});
    log.warn("This is a warning message", .{});
    log.info("This is an info message", .{});
    log.debug("This is a debug message", .{});

    // Use scoped logging from other modules
    try database.connect();
    try database.query("SELECT * FROM users");

    try network.sendRequest("https://api.example.com/data");

    log.info("Application shutting down", .{});
}
```

**database.zig:**

```zig
const std = @import("std");
const log = std.log.scoped(.database);

pub fn connect() !void {
    log.info("Connecting to database...", .{});
    log.debug("Connection parameters: host=localhost port=5432", .{});
    log.info("Database connection established", .{});
}

pub fn query(sql: []const u8) !void {
    log.debug("Executing query: {s}", .{sql});

    if (std.mem.indexOf(u8, sql, "INVALID") != null) {
        log.err("Invalid SQL syntax detected", .{});
        return error.InvalidSQL;
    }

    log.debug("Query completed successfully", .{});
}
```

**network.zig:**

```zig
const std = @import("std");
const log = std.log.scoped(.network);

pub fn sendRequest(url: []const u8) !void {
    log.info("Sending HTTP request to {s}", .{url});
    log.debug("Request headers: User-Agent=ZigHTTP/1.0", .{});
    log.debug("Received response: 200 OK", .{});
    log.info("Request completed successfully", .{});
}
```

**Output (with log_level = .info):**

```
info: Application started
info: Server listening on port 8080
error: This is an error message
warning: This is a warning message
info: This is an info message
info(database): Connecting to database...
info(database): Database connection established
info(network): Sending HTTP request to https://api.example.com/data
info(network): Request completed successfully
info: Application shutting down
```

**Output (with log_level = .debug):**

```
info: Application started
debug: Debug mode enabled
info: Server listening on port 8080
error: This is an error message
warning: This is a warning message
info: This is an info message
debug: This is a debug message
info(database): Connecting to database...
debug(database): Connection parameters: host=localhost port=5432
info(database): Database connection established
debug(database): Executing query: SELECT * FROM users
debug(database): Query completed successfully
info(network): Sending HTTP request to https://api.example.com/data
debug(network): Request headers: User-Agent=ZigHTTP/1.0
debug(network): Received response: 200 OK
info(network): Request completed successfully
info: Application shutting down
```

**Key Observations:**

- Scoped logs show subsystem name: `info(database):` vs `info:`
- Debug logs are only visible when `log_level = .debug`
- Each module has its own scoped logger
- Output goes to stderr (keeps stdout clean)

### Example 2: Structured Logging with Context

For production systems, structured logging enables automated analysis and correlation:

```zig
const std = @import("std");

pub const LogContext = struct {
    correlation_id: []const u8,
    user_id: ?u32 = null,
    request_path: ?[]const u8 = null,

    pub fn logInfo(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.info, format, args);
    }

    pub fn logError(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.err, format, args);
    }

    fn logWithLevel(
        self: LogContext,
        level: std.log.Level,
        comptime format: []const u8,
        args: anytype,
    ) void {
        // 🕐 **0.14.x:**
        // const stderr = std.io.getStdErr().writer();

        // ✅ **0.15+:**
        var stderr_buf: [2048]u8 = undefined;
        var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
        const stderr = &stderr_writer.interface;

        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();

        var buf: [4096]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

        nosuspend {
            stderr.writeAll("{") catch return;

            stderr.writeAll("\"timestamp\":") catch return;
            stderr.print("{d}", .{std.time.milliTimestamp()}) catch return;

            stderr.writeAll(",\"level\":\"") catch return;
            stderr.writeAll(level.asText()) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll(",\"correlation_id\":\"") catch return;
            stderr.writeAll(self.correlation_id) catch return;
            stderr.writeAll("\"") catch return;

            if (self.user_id) |uid| {
                stderr.writeAll(",\"user_id\":") catch return;
                stderr.print("{d}", .{uid}) catch return;
            }

            if (self.request_path) |path| {
                stderr.writeAll(",\"path\":\"") catch return;
                stderr.writeAll(path) catch return;
                stderr.writeAll("\"") catch return;
            }

            stderr.writeAll(",\"message\":\"") catch return;
            stderr.writeAll(message) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll("}\n") catch return;
            stderr.flush() catch return;
        };
    }
};

pub fn main() !void {
    // Simulate HTTP request handling
    const ctx = LogContext{
        .correlation_id = "req-12345-abcde",
        .user_id = 42,
        .request_path = "/api/users/42",
    };

    ctx.logInfo("Request started", .{});
    ctx.logInfo("Querying database for user {d}", .{42});
    ctx.logInfo("Request completed in {d}ms", .{123});
}
```

**Output:**

```json
{"timestamp":1730860800123,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request started"}
{"timestamp":1730860800150,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Querying database for user 42"}
{"timestamp":1730860800273,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request completed in 123ms"}
```

This format is parseable by standard log aggregators and enables:
- Request tracing via correlation IDs
- User activity tracking
- Performance analysis (duration)
- Automated alerting on error rates

### Example 3: Performance-Conscious Logging

For high-throughput systems, sample frequent events to control log volume:

```zig
const std = @import("std");

const SampledLogger = struct {
    counter: std.atomic.Value(u64),
    sample_rate: u64,

    pub fn init(sample_rate: u64) SampledLogger {
        return .{
            .counter = std.atomic.Value(u64).init(0),
            .sample_rate = sample_rate,
        };
    }

    pub fn shouldLog(self: *SampledLogger) bool {
        const count = self.counter.fetchAdd(1, .monotonic);
        return count % self.sample_rate == 0;
    }

    pub fn logInfo(
        self: *SampledLogger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        if (self.shouldLog()) {
            std.log.info(format, args);
        }
    }
};

pub fn main() !void {
    var sampled = SampledLogger.init(100); // Log 1/100 events

    // High-frequency loop
    var i: u64 = 0;
    while (i < 10000) : (i += 1) {
        // Only logs 100 times (1/100)
        sampled.logInfo("Processing item {d}", .{i});

        processItem(i);
    }
}

fn processItem(id: u64) void {
    // Process the item...
    _ = id;
}
```

This reduces log volume from 10,000 lines to 100 lines while maintaining visibility into system operation.

**Error Rate Tracking:**

Combine sampling with always-logged errors:

```zig
const ErrorRateTracker = struct {
    error_count: std.atomic.Value(u64),
    total_count: std.atomic.Value(u64),

    pub fn recordSuccess(self: *ErrorRateTracker) void {
        _ = self.total_count.fetchAdd(1, .monotonic);
    }

    pub fn recordError(self: *ErrorRateTracker, err: anyerror) void {
        _ = self.error_count.fetchAdd(1, .monotonic);
        _ = self.total_count.fetchAdd(1, .monotonic);

        // Always log errors (no sampling)
        std.log.err("Operation failed: {s}", .{@errorName(err)});
    }

    pub fn getErrorRate(self: *ErrorRateTracker) f64 {
        const errors = self.error_count.load(.monotonic);
        const total = self.total_count.load(.monotonic);
        if (total == 0) return 0.0;
        return @as(f64, @floatFromInt(errors)) / @as(f64, @floatFromInt(total));
    }
};
```

This ensures errors are always visible while sampling routine operations.

---

## Common Pitfalls

### Expensive Computation in Log Arguments

**Problem:** Log arguments are always evaluated, even if the log is filtered at runtime.

```zig
// ❌ Incorrect - expensiveFunction() always runs
log.debug("Result: {}", .{expensiveFunction()});
```

Even if debug logging is disabled at runtime, `expensiveFunction()` still executes.

**Solution:** Guard expensive operations with a runtime check:

```zig
// ✅ Correct - only compute if logging enabled
if (std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

For compile-time filtering (zero cost when disabled):

```zig
// ✅ Best - compile-time eliminated if debug disabled globally
if (comptime std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

### Logging Sensitive Information

**Problem:** Accidentally logging passwords, API tokens, or personally identifiable information.

```zig
// ❌ NEVER DO THIS
log.info("User login: user={s} password={s}", .{username, password});
log.debug("API request with token: {s}", .{api_token});
```

Logs often persist in log aggregation systems and may be accessed by operations teams.

**Solution:** Never log sensitive data:

```zig
// ✅ Correct - only log non-sensitive information
log.info("User login: user={s}", .{username});
log.debug("API request sent", .{});
```

For debugging, hash sensitive values:

```zig
// ✅ For debugging - hash sensitive data
const hash = std.crypto.hash.sha256.hash(password);
log.debug("Password hash: {x}", .{std.fmt.fmtSliceHexLower(&hash)});
```

### Non-Thread-Safe Custom Handlers

**Problem:** Custom log handlers without locking cause data races.

```zig
// ❌ Incorrect - NOT thread-safe
var log_buffer: [4096]u8 = undefined;
var log_len: usize = 0;

pub fn unsafeLogFn(...) void {
    // Multiple threads can corrupt log_buffer
    const msg = std.fmt.bufPrint(log_buffer[log_len..], ...) catch return;
    log_len += msg.len;
}
```

**Solution:** Always use locking:

```zig
// ✅ Correct - thread-safe with current API (0.15+)
pub fn safeLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    stderr.interface.print("[{s}]({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

### High-Frequency Logging Without Sampling

**Problem:** Logging on every iteration creates excessive output.

```zig
// ❌ Incorrect - logs millions of times
for (items) |item| {
    log.debug("Processing {d}", .{item.id});
    processItem(item);
}
```

**Solution:** Use sampling or periodic logging:

```zig
// ✅ Correct - sample every 100th item
var sampler = SampledLogger.init(100);
for (items) |item| {
    sampler.logDebug("Processing {d}", .{item.id});
    processItem(item);
}

// ✅ Alternative - log summary
log.info("Processing {d} items", .{items.len});
for (items) |item| {
    processItem(item);
}
log.info("Completed processing {d} items", .{items.len});
```

### Invalid JSON in Structured Logs

**Problem:** Unescaped strings break JSON parsing.

```zig
// ❌ Incorrect - breaks if msg contains quotes
pub fn badJsonLog(msg: []const u8) void {
    stderr.print("{{\"message\":\"{s}\"}}\n", .{msg});
    // If msg = "He said \"hello\"", output is invalid JSON
}
```

**Solution:** Properly escape JSON strings:

```zig
// ✅ Correct - escape special characters
pub fn goodJsonLog(msg: []const u8) void {
    stderr.writeAll("{\"message\":\"") catch return;
    for (msg) |c| {
        switch (c) {
            '"' => stderr.writeAll("\\\"") catch return,
            '\\' => stderr.writeAll("\\\\") catch return,
            '\n' => stderr.writeAll("\\n") catch return,
            '\r' => stderr.writeAll("\\r") catch return,
            '\t' => stderr.writeAll("\\t") catch return,
            else => stderr.writeByte(c) catch return,
        }
    }
    stderr.writeAll("\"}\n") catch return;
}
```

### Blocking I/O in Log Handlers

**Problem:** Network I/O or synchronous file writes block the application.

```zig
// ❌ Incorrect - blocks on network I/O
pub fn slowLogFn(...) void {
    const socket = connectToLogServer() catch return; // Blocks!
    defer socket.close();
    socket.send(...) catch return;
}
```

**Solution:** Use buffering or asynchronous logging:

```zig
// ✅ Correct - buffer logs, ship asynchronously
const AsyncLogBuffer = struct {
    buffer: std.ArrayList(u8),
    mutex: std.Thread.Mutex,

    pub fn append(self: *AsyncLogBuffer, msg: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.buffer.appendSlice(msg);
    }

    // Called periodically by background thread
    pub fn flush(self: *AsyncLogBuffer) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.buffer.items.len == 0) return;

        const socket = try connectToLogServer();
        defer socket.close();
        try socket.writeAll(self.buffer.items);

        self.buffer.clearRetainingCapacity();
    }
};
```

---

## In Practice

Real-world Zig projects demonstrate diverse logging strategies adapted to their specific needs.

### TigerBeetle: Deterministic Event Logging

TigerBeetle, a distributed financial database, uses scoped logging extensively to organize output by subsystem[^3][^4]:

```zig
// One scoped logger per module
const log = std.log.scoped(.vsr);          // Viewstamped Replication
const log = std.log.scoped(.superblock);   // Storage metadata
const log = std.log.scoped(.journal);      // Write-ahead log
const log = std.log.scoped(.grid_scrubber); // Data verification
const log = std.log.scoped(.compaction);    // LSM compaction
```

TigerBeetle also implements a sophisticated trace system layered on top of std.log[^7]:

```zig
pub const Tracer = struct {
    time: Time,
    process_id: ProcessID,
    options: Options,

    pub const Options = struct {
        writer: ?std.io.AnyWriter = null,
        statsd_options: union(enum) {
            log,
            udp: struct {
                io: *IO,
                address: std.net.Address,
            },
        } = .log,
    };

    // Event tracking for deterministic replay...
};
```

This trace system provides:
- Structured event logging for deterministic replay
- StatsD metrics integration for monitoring
- Process ID tracking for distributed correlation
- Optional writer for trace output

**Key Insight:** TigerBeetle demonstrates layering application-specific tracing on top of std.log while maintaining the benefits of compile-time filtering and scoped organization.

### Ghostty: Platform-Aware Logging

Ghostty, a GPU-accelerated terminal emulator, integrates with platform-specific logging APIs[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (builtin.target.os.tag.isDarwin()) {
        // Use macOS Unified Logging
        const mac_level: macos.os.LogType = switch (level) {
            .debug => .debug,
            .info => .info,
            .warn => .err,
            .err => .fault,
        };

        const logger = macos.os.Log.create(build_config.bundle_id, @tagName(scope));
        defer logger.release();
        logger.log(std.heap.c_allocator, mac_level, format, args);
    }

    // Also output to stderr
    // ... stderr output code ...
}
```

This approach enables:
- Native platform integration (macOS Console.app)
- Cross-platform stderr fallback
- Consistent API regardless of platform

Ghostty configures log levels based on build mode[^15]:

```zig
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = logFn,
};
```

### Bun: Minimal Overhead for Performance

Bun, a JavaScript runtime, sets a high log threshold in release builds to minimize overhead[^8]:

```zig
pub const std_options = std.Options{
    .log_level = if (builtin.mode == .Debug) .debug else .warn,
};
```

By setting `.warn` in release mode, Bun filters out info and debug logs, relying on custom infrastructure for performance-critical logging.

**Pattern:** High-performance runtimes minimize std.log usage in hot paths, using it primarily for errors and warnings while implementing custom lightweight logging for frequent events.

### ZLS: Development Tool Diagnostics

The Zig Language Server uses scoped logging for different analysis components[^9]:

```zig
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};
```

ZLS routes logs to stderr, keeping them separate from LSP JSON-RPC communication on stdout. Scoped loggers organize diagnostic output:

- `.analysis` - Code analysis diagnostics
- `.diagnostics` - Compiler diagnostic generation
- `.completions` - Autocomplete debugging
- `.goto` - Go-to-definition tracing

This demonstrates logging in development tools where:
- Rich diagnostics help debug protocol issues
- Logs must not interfere with primary communication channel
- Filtering by component aids development

---

## Summary

Zig's logging system provides a pragmatic balance between developer observability and runtime performance through compile-time filtering and customizable output.

**Core Principles:**

1. **Compile-time optimization**: Filtered logs have zero runtime cost
2. **Scoped organization**: Categorize logs by subsystem for clarity
3. **Customizable handlers**: Adapt output format to deployment needs
4. **Thread safety**: Built-in synchronization for concurrent access
5. **Minimal dependencies**: No heap allocation in default implementation

**When to Use What:**

| Scenario | Tool | Reason |
|----------|------|--------|
| Temporary debugging | `std.debug.print` | Quick, no setup required |
| Permanent instrumentation | `std.log` | Filtering, scoping, consistent format |
| Error conditions | `log.err` | Always visible, indicates problems |
| State transitions | `log.info` | Important events, may sample in production |
| Internal diagnostics | `log.debug` | Development only, filtered in release |
| Invariant violations | `std.debug.assert` | Panic on violation (Debug/ReleaseSafe) |
| Stack inspection | `std.debug.dumpCurrentStackTrace` | Deep debugging, error diagnosis |

**Production Checklist:**

- [ ] Set appropriate log level (`.info` or `.warn`)
- [ ] Use scoped logging for subsystem organization
- [ ] Sample high-frequency events
- [ ] Always log errors (no sampling)
- [ ] Never log sensitive data (passwords, tokens, PII)
- [ ] Ensure thread-safe custom handlers
- [ ] Consider structured output (JSON) for aggregation
- [ ] Add correlation IDs for request tracing
- [ ] Test log volume under load
- [ ] Plan for log rotation and retention

**Development vs Production:**

**Development (Debug mode):**
- Log level: `.debug` (all logs enabled)
- Use `std.debug.print` for quick diagnostics
- Enable verbose logging for all subsystems
- Include detailed error context and stack traces

**Production (Release modes):**
- Log level: `.info` or `.warn` (filter debug logs)
- Sample high-frequency info logs
- Always capture errors with context
- Use structured output for automated analysis
- Monitor log volume and performance impact

**Key Takeaway:** Zig's logging system enables comprehensive instrumentation during development while maintaining production performance through compile-time elimination of unused logs. This design eliminates the traditional observability-performance trade-off, allowing developers to instrument freely without impacting production systems.

---

## References

[^1]: [Zig Language Reference 0.15.2: std.log](https://ziglang.org/documentation/0.15.2/std/#std.log) - Official documentation for the standard library logging module.

[^2]: [Zig Language Reference 0.15.2: std.Options](https://ziglang.org/documentation/0.15.2/std/#std.Options) - Documentation for std.Options structure including log configuration.

[^3]: [TigerBeetle Source: Scoped Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig#L5) - Example scoped logger: `const log = std.log.scoped(.vsr);`

[^4]: [TigerBeetle Source: Custom Log Handler](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/scripts.zig#L25-L34) - Custom log handler with timestamp support.

[^5]: [Ghostty Source: Platform-Aware Log Handler](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L121-L168) - macOS Unified Logging integration.

[^6]: [Zig std.debug Source](../../zig_versions/zig-0.15.2/lib/std/debug.zig) - Standard library debug utilities.

[^7]: [TigerBeetle Source: Trace System](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace.zig#L100) - Event tracing with StatsD integration.

[^8]: [Bun Source: Log Configuration](https://github.com/oven-sh/bun/blob/main/src/main.zig#L2) - Minimal std.log usage for performance.

[^9]: [ZLS Source: Log Configuration](https://github.com/zigtools/zls/blob/main/src/main.zig#L35) - Language server logging setup.

[^10]: [Zig std.log Source](../../zig_versions/zig-0.15.2/lib/std/log.zig) - Local Zig 0.15.2 stdlib logging implementation.

[^11]: [TigerBeetle: Superblock Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/superblock.zig#L39) - Superblock operations with `.superblock` scope.

[^12]: [TigerBeetle: Journal Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/journal.zig#L14) - Write-ahead log with `.journal` scope.

[^13]: [TigerBeetle: Compaction Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/compaction.zig#L38) - LSM compaction with `.compaction` scope.

[^14]: [TigerBeetle: IO Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L9) - Platform-specific I/O with `.io` scope.

[^15]: [Ghostty: Log Level Configuration](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L170-L178) - Build-mode dependent log levels.
# Chapter 1: Appendices & Reference Material

This chapter provides comprehensive reference materials for Zig development: a complete glossary of terms, idiomatic style guidelines, consolidated references from all chapters, and quick lookup tables for syntax, patterns, and APIs. Use this as a desk reference while writing Zig code.

**Target Audience**: All Zig developers looking for quick reference and terminology clarification.

**Chapter Goals**:
- Provide quick lookup for Zig terminology and concepts
- Document idiomatic Zig style conventions from production codebases
- Consolidate all references into searchable index
- Offer syntax and pattern quick references
- Guide developers through common pitfalls and version migrations

**Prerequisites**: Familiarity with Zig basics (Chapters 1-2 recommended).

---

## 15.1 Glossary of Zig Terms

This glossary defines 150+ terms used throughout Zig development, organized alphabetically. Each entry includes the definition, common usage patterns, related chapters, and version applicability.

### A

**Allocator**
- **Definition**: Interface (std.mem.Allocator) providing uniform memory allocation API with methods like alloc(), free(), create(), and destroy()
- **Key Methods**: alloc(), free(), create(), destroy(), realloc()
- **Usage**: Foundation of Zig's explicit memory management philosophy
- **Chapter**: 3 (Memory & Allocators), 5 (I/O), 6 (Error Handling)
- **Version**: All versions

**anyopaque**
- **Definition**: Type-erased pointer type replacing c_void in Zig 0.11+
- **Usage**: C interop, type-erased storage, opaque pointers
- **Chapter**: 11 (Interoperability)
- **Version**: 0.11+

**anytype**
- **Definition**: Type allowing compile-time polymorphism; compiler infers actual type from usage
- **Common Uses**: Generic functions, formatting, duck typing
- **Chapter**: 2 (Language Idioms), 5 (I/O), 11 (Interoperability)
- **Version**: All versions

**Arena Allocator**
- **Definition**: Allocator that batch-frees all allocations at once; ideal for temporary allocations with shared lifetime
- **Pattern**: `var arena = std.heap.ArenaAllocator.init(parent); defer arena.deinit();`
- **Usage**: Request handlers, batch operations, temporary data structures
- **Chapter**: 3 (Memory & Allocators), 5 (I/O)
- **Version**: All versions

**ArrayList**
- **Definition**: Dynamic array type (std.ArrayList) that grows as needed
- **Key Methods**: init(), deinit(), append(), pop(), items, capacity
- **Chapter**: 3 (Memory & Allocators), 4 (Data Structures)
- **Version**: 0.15+ defaults to unmanaged (requires explicit allocator in methods)

**assert**
- **Definition**: Runtime check in Debug/ReleaseSafe modes that panics if condition is false; optimized away in ReleaseFast
- **Usage**: `std.debug.assert(condition)`
- **Chapter**: 2 (Language Idioms), 6 (Error Handling)
- **Version**: All versions

**Async/Await**
- **Definition**: (DEPRECATED) Async function syntax removed in Zig 0.11+
- **Migration**: Use event loop libraries like libxev or manually manage state machines
- **Chapter**: 7 (Async & Concurrency)
- **Version**: Removed in 0.11+

**Atomics**
- **Definition**: Lock-free synchronization primitives (std.atomic.Value)
- **Operations**: load(), store(), fetchAdd(), cmpxchgWeak(), fence()
- **Chapter**: 7 (Async & Concurrency)
- **Version**: All versions

### B

**Build Artifact**
- **Definition**: Output of build process (executable, library, object file)
- **Types**: exe (executable), lib (static/dynamic library), obj (object file)
- **Chapter**: 8 (Build System), 10 (Project Layout)
- **Version**: All versions

**Build Mode**
- **Definition**: Optimization level for compilation
- **Modes**: Debug (default, safety checks), ReleaseFast (optimized, no checks), ReleaseSafe (optimized with checks), ReleaseSmall (size-optimized)
- **Chapter**: 8 (Build System)
- **Version**: All versions

**build.zig**
- **Definition**: Zig build script replacing traditional build systems (Make, CMake)
- **Structure**: Defines build steps, dependencies, options, and targets
- **Chapter**: 8 (Build System), 9 (Packages & Dependencies), 10 (Project Layout)
- **Version**: All versions (API evolved significantly 0.11+)

**build.zig.zon**
- **Definition**: Package manifest file defining dependencies and package metadata
- **Format**: Zig Object Notation (ZON) - Zig's data serialization format
- **Chapter**: 9 (Packages & Dependencies)
- **Version**: 0.11+ (requires .fingerprint field in 0.15+)

**Builtin Functions**
- **Definition**: Functions prefixed with @ that provide compiler intrinsics
- **Examples**: @import(), @as(), @intCast(), @alignOf(), @sizeOf(), @compileError()
- **Chapter**: 2 (Language Idioms), 11 (Interoperability)
- **Version**: All versions

### C

**c_allocator**
- **Definition**: Allocator wrapping C's malloc/free for C interop
- **Usage**: FFI boundaries, interfacing with C libraries
- **Chapter**: 3 (Memory & Allocators), 11 (Interoperability)
- **Version**: All versions

**C ABI**
- **Definition**: Application Binary Interface for C compatibility
- **Keywords**: extern, export, callconv(.C)
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

**@cImport**
- **Definition**: Builtin to import C headers and translate to Zig
- **Usage**: `const c = @cImport(@cInclude("header.h"));`
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

**Comptime**
- **Definition**: Compile-time execution allowing code generation and type manipulation
- **Keywords**: comptime, @compileLog(), @compileError()
- **Chapter**: 2 (Language Idioms), 4 (Data Structures), 11 (Interoperability)
- **Version**: All versions

**Container**
- **Definition**: Generic data structures (ArrayList, HashMap, etc.)
- **Managed vs Unmanaged**: Managed stores allocator; unmanaged requires passing allocator to methods
- **Chapter**: 4 (Data Structures)
- **Version**: 0.15+ defaults to unmanaged

**Cross-Compilation**
- **Definition**: Compiling for a different target platform than host
- **Usage**: `zig build -Dtarget=aarch64-linux`
- **Chapter**: 8 (Build System), 10 (Project Layout)
- **Version**: All versions

### D

**defer**
- **Definition**: Executes code at scope exit (similar to Go's defer)
- **Pattern**: Place immediately after resource acquisition
- **Usage**: `var gpa = GPA{}; defer _ = gpa.deinit();`
- **Chapter**: 3 (Memory & Allocators), 6 (Error Handling)
- **Version**: All versions

**deinit**
- **Definition**: Convention for cleanup functions (opposite of init)
- **Pattern**: Always pair init() with deinit() using defer
- **Chapter**: 3 (Memory & Allocators), 4 (Data Structures)
- **Version**: All versions

**Dependency**
- **Definition**: External package imported via build.zig.zon
- **Management**: Declared in dependencies section with .url and .hash
- **Chapter**: 9 (Packages & Dependencies)
- **Version**: 0.11+ (package system introduced)

### E

**Error Set**
- **Definition**: Type defining possible error values (like enum)
- **Syntax**: `const MyError = error { OutOfMemory, InvalidInput };`
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**Error Union**
- **Definition**: Type that can be either a value or an error (T!U)
- **Syntax**: `fn foo() !i32` returns `anyerror!i32`
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**errdefer**
- **Definition**: Like defer, but only executes if function returns with error
- **Usage**: Multi-step initialization cleanup
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**extern**
- **Definition**: Declares external symbol (typically from C library)
- **Usage**: `extern fn malloc(size: usize) ?*anyopaque;`
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

**export**
- **Definition**: Makes Zig function visible to external code (C ABI)
- **Usage**: `export fn my_api() void { }`
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

### F

**Field**
- **Definition**: Member of a struct, union, or enum
- **Access**: @field(), @hasField(), @fieldParentPtr()
- **Chapter**: 2 (Language Idioms), 4 (Data Structures)
- **Version**: All versions

**FixedBufferAllocator**
- **Definition**: Allocator that uses pre-allocated buffer (no heap allocation)
- **Usage**: Embedded systems, stack-only allocation
- **Chapter**: 3 (Memory & Allocators)
- **Version**: All versions

**fmt**
- **Definition**: std.fmt module for formatting and printing
- **Key Functions**: format(), bufPrint(), allocPrint(), parseInt(), parseFloat()
- **Chapter**: 5 (I/O)
- **Version**: All versions

### G

**GeneralPurposeAllocator (GPA)**
- **Definition**: Production-quality allocator with safety checks and leak detection
- **Usage**: Default choice for applications needing safe memory management
- **Pattern**: `var gpa = std.heap.GeneralPurposeAllocator(.{}){};`
- **Chapter**: 3 (Memory & Allocators)
- **Version**: All versions

**Generic**
- **Definition**: Type or function parameterized with anytype or explicit type parameter
- **Pattern**: `fn max(comptime T: type, a: T, b: T) T`
- **Chapter**: 2 (Language Idioms), 4 (Data Structures)
- **Version**: All versions

### H

**HashMap**
- **Definition**: Hash table data structure (std.HashMap, std.AutoHashMap)
- **Variants**: HashMap (custom hash), AutoHashMap (auto hash), StringHashMap (string keys)
- **Chapter**: 4 (Data Structures)
- **Version**: 0.15+ defaults to unmanaged

**HTTP Client/Server**
- **Definition**: std.http module for HTTP operations
- **Components**: Client, Server, Headers, Request, Response
- **Chapter**: 5 (I/O)
- **Version**: Introduced in 0.11+

### I

**inline**
- **Definition**: Hints or forces function inlining
- **Forms**: `inline fn`, `inline for`, `inline while`
- **Chapter**: 2 (Language Idioms)
- **Version**: All versions

**init**
- **Definition**: Convention for initialization functions (returns initialized value)
- **Pattern**: `pub fn init(allocator: Allocator) Self`
- **Chapter**: 3 (Memory & Allocators), 4 (Data Structures)
- **Version**: All versions

**Interface**
- **Definition**: Implicit structural typing via anytype or explicit vtable pattern
- **Implementation**: Zig has no interface keyword; use comptime duck typing or manual vtables
- **Chapter**: 2 (Language Idioms), 4 (Data Structures)
- **Version**: All versions

### L

**Lazy Analysis**
- **Definition**: Zig analyzes code only when referenced (allows unused code without errors)
- **Impact**: Enables conditional compilation, platform-specific code
- **Chapter**: 2 (Language Idioms), 11 (Interoperability)
- **Version**: All versions

**libxev**
- **Definition**: Cross-platform event loop library (recommended for async I/O post-0.11)
- **Usage**: Replaces removed async/await syntax
- **Chapter**: 7 (Async & Concurrency)
- **Version**: External dependency (all versions)

**Linker**
- **Definition**: Combines object files into final executable/library
- **Configuration**: Via build.zig (link_libc(), linkSystemLibrary())
- **Chapter**: 8 (Build System), 11 (Interoperability)
- **Version**: All versions

### M

**Managed**
- **Definition**: Container variant that stores its allocator (pre-0.15 default)
- **Trade-off**: Convenience vs. extra pointer storage
- **Chapter**: 4 (Data Structures)
- **Version**: Explicit choice in 0.15+

**Module**
- **Definition**: Compilation unit; file or build-defined dependency
- **System**: Replaced package paths in 0.11+
- **Chapter**: 8 (Build System), 9 (Packages & Dependencies)
- **Version**: 0.11+ (module system introduced)

**Mutex**
- **Definition**: Mutual exclusion lock (std.Thread.Mutex)
- **Methods**: lock(), unlock(), tryLock()
- **Chapter**: 7 (Async & Concurrency)
- **Version**: All versions

### N

**noreturn**
- **Definition**: Type indicating function never returns (exits, panics, or infinite loops)
- **Usage**: `fn panic(msg: []const u8) noreturn`
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**null**
- **Definition**: Value representing absence (for optional types)
- **Usage**: `var x: ?i32 = null;`
- **Chapter**: 2 (Language Idioms), 6 (Error Handling)
- **Version**: All versions

### O

**orelse**
- **Definition**: Unwraps optional or provides default value
- **Syntax**: `value = optional orelse default;`
- **Chapter**: 2 (Language Idioms), 6 (Error Handling)
- **Version**: All versions

**Optional**
- **Definition**: Type that can be value or null (prefix with ?)
- **Syntax**: `?T` for optional T
- **Chapter**: 2 (Language Idioms), 6 (Error Handling)
- **Version**: All versions

### P

**Packed Struct**
- **Definition**: Struct with guaranteed bit-level layout (no padding)
- **Usage**: Bit flags, hardware registers, network protocols
- **Syntax**: `packed struct { ... }`
- **Chapter**: 4 (Data Structures), 11 (Interoperability)
- **Version**: All versions

**panic**
- **Definition**: Unrecoverable error handler (stack trace + exit)
- **Customization**: Override default with pub fn panic()
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**Pointer**
- **Definition**: Memory address with explicit size semantics
- **Types**: Single (*T), Many ([*]T), Slice ([]T), C-pointer ([*c]T)
- **Chapter**: 3 (Memory & Allocators)
- **Version**: All versions

**pub**
- **Definition**: Makes declaration public (visible outside file)
- **Default**: Private (file-scoped) without pub
- **Chapter**: 2 (Language Idioms), 10 (Project Layout)
- **Version**: All versions

### R

**Reader**
- **Definition**: Generic input stream interface
- **Methods**: read(), readAll(), readUntilDelimiter(), readInt()
- **Chapter**: 5 (I/O)
- **Version**: All versions

**Result Type**
- **Definition**: Pattern using error union (T!U) for error handling
- **Usage**: Return value or error, explicit handling with try/catch
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**RwLock**
- **Definition**: Reader-writer lock allowing concurrent reads or exclusive writes
- **Methods**: lockShared(), unlockShared(), lock(), unlock()
- **Chapter**: 7 (Async & Concurrency)
- **Version**: All versions

### S

**Sentinel**
- **Definition**: Terminating value for arrays/slices (e.g., 0 for strings)
- **Syntax**: `[:0]const u8` for null-terminated string
- **Chapter**: 3 (Memory & Allocators), 11 (Interoperability)
- **Version**: All versions

**Slice**
- **Definition**: Fat pointer containing pointer + length ([]T)
- **Operations**: Indexing, iteration, subslicing
- **Chapter**: 3 (Memory & Allocators), 5 (I/O)
- **Version**: All versions

**std**
- **Definition**: Zig standard library (`@import("std")`)
- **Key Modules**: mem, heap, fs, io, fmt, json, http, crypto, Thread
- **Chapter**: All chapters
- **Version**: All versions (APIs evolve)

**Struct**
- **Definition**: Composite data type grouping related fields
- **Features**: Methods, defaults, comptime fields, generic parameters
- **Chapter**: 2 (Language Idioms), 4 (Data Structures)
- **Version**: All versions

### T

**Target**
- **Definition**: Platform triple (CPU-OS-ABI) for compilation
- **Format**: `x86_64-linux-gnu`, `aarch64-macos`, `wasm32-wasi`
- **Chapter**: 8 (Build System), 10 (Project Layout), 11 (Interoperability)
- **Version**: All versions

**Test**
- **Definition**: Unit test block or function
- **Syntax**: `test "name" { ... }`
- **Chapter**: 12 (Testing & Benchmarking)
- **Version**: All versions

**Test Allocator**
- **Definition**: Special allocator detecting memory leaks in tests (std.testing.allocator)
- **Usage**: Use in all tests allocating memory
- **Chapter**: 12 (Testing & Benchmarking)
- **Version**: All versions

**Thread**
- **Definition**: Operating system thread (std.Thread)
- **Methods**: spawn(), join(), detach()
- **Chapter**: 7 (Async & Concurrency)
- **Version**: All versions

**try**
- **Definition**: Unwraps error union or returns error to caller
- **Equivalent**: `val = try expr;` ≈ `val = expr catch |e| return e;`
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

**Type**
- **Definition**: First-class value representing types
- **Usage**: `comptime T: type` for generic functions
- **Chapter**: 2 (Language Idioms)
- **Version**: All versions

### U

**undefined**
- **Definition**: Uninitialized value (implementation-defined bit pattern)
- **Usage**: Local variables requiring initialization before use
- **Chapter**: 3 (Memory & Allocators)
- **Version**: All versions

**Union**
- **Definition**: Type holding one of several fields (overlapping memory)
- **Forms**: Tagged (safe, like enum), untagged (unsafe, like C union)
- **Chapter**: 4 (Data Structures)
- **Version**: All versions

**Unmanaged**
- **Definition**: Container variant requiring explicit allocator parameter (0.15+ default)
- **Trade-off**: No stored allocator (smaller) but less convenient
- **Chapter**: 4 (Data Structures)
- **Version**: 0.15+ default

**unreachable**
- **Definition**: Marks code path that should never execute (undefined behavior if reached)
- **Usage**: Optimization hint or assertion
- **Chapter**: 6 (Error Handling)
- **Version**: All versions

### V

**var**
- **Definition**: Declares mutable variable
- **Contrast**: `const` declares immutable binding
- **Chapter**: 2 (Language Idioms)
- **Version**: All versions

**volatile**
- **Definition**: Prevents compiler from optimizing memory access (for MMIO)
- **Usage**: Hardware registers, memory-mapped I/O
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

### W

**WASM**
- **Definition**: WebAssembly target for browser/runtime execution
- **Target**: `wasm32-freestanding`, `wasm32-wasi`
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

**WASI**
- **Definition**: WebAssembly System Interface for system calls
- **Target**: `wasm32-wasi`
- **Chapter**: 11 (Interoperability)
- **Version**: All versions

**Writer**
- **Definition**: Generic output stream interface
- **Methods**: write(), writeAll(), writeByte(), writeInt(), print()
- **Chapter**: 5 (I/O)
- **Version**: All versions

### Z

**Zig Object Notation (ZON)**
- **Definition**: Zig's data serialization format (subset of Zig syntax)
- **Usage**: build.zig.zon, configuration files
- **Chapter**: 9 (Packages & Dependencies)
- **Version**: 0.11+

**zig build**
- **Definition**: Build system command executing build.zig
- **Usage**: `zig build [step] [-Doption=value]`
- **Chapter**: 8 (Build System), 9 (Packages & Dependencies), 10 (Project Layout)
- **Version**: All versions

**zig test**
- **Definition**: Test runner command
- **Usage**: `zig test file.zig` runs all test blocks
- **Chapter**: 12 (Testing & Benchmarking)
- **Version**: All versions

**zig fmt**
- **Definition**: Code formatter (enforces canonical style)
- **Usage**: `zig fmt file.zig` or `zig fmt --check .`
- **Chapter**: 10 (Project Layout)
- **Version**: All versions

---

## 15.2 Idiomatic Zig Style Checklist

This checklist compiles style guidelines from production Zig codebases (TigerBeetle, Ghostty, Bun, ZLS, Zig stdlib) with concrete examples. Follow these conventions for idiomatic, maintainable Zig code.

### Naming Conventions

#### ✅ Functions and Variables: snake_case

```zig
// ✅ GOOD: Clear snake_case naming
pub fn calculate_total_price(items: []const Item) f64 {
    var total: f64 = 0;
    for (items) |item| total += item.price;
    return total;
}

const max_buffer_size = 4096;
const retry_count: u32 = 3;
```

```zig
// ❌ BAD: Avoid camelCase or PascalCase for functions/variables
pub fn CalculateTotalPrice(items: []const Item) f64 { }
const maxBufferSize = 4096;
```

#### ✅ Types: PascalCase

```zig
// ✅ GOOD: Types use PascalCase
pub const HttpServer = struct {
    allocator: Allocator,
    port: u16,
};

pub const RequestError = error { InvalidMethod, Timeout };
```

```zig
// ❌ BAD: Avoid snake_case for types
pub const http_server = struct { };
pub const request_error = error { };
```

#### ✅ Constants: snake_case (not SCREAMING_SNAKE_CASE)

```zig
// ✅ GOOD: Regular snake_case for constants
const default_timeout_ms = 5000;
const max_connections = 100;
```

```zig
// ❌ BAD: Avoid SCREAMING_SNAKE_CASE (not Zig style)
const DEFAULT_TIMEOUT_MS = 5000;
const MAX_CONNECTIONS = 100;
```

#### ✅ Units Last in Variable Names

```zig
// ✅ GOOD: Unit suffixes for clarity (TigerBeetle convention)
const latency_ms_max: u64 = 100;
const timeout_ns: u64 = 1_000_000;
const file_size_bytes: usize = 1024;
const duration_seconds: f64 = 2.5;
```

```zig
// ❌ BAD: Ambiguous units or prefixes
const max_latency: u64 = 100; // Units unclear
const timeout: u64 = 1_000_000; // Milliseconds? Nanoseconds?
```

### Code Organization

#### ✅ File-Level Structure Order

```zig
// ✅ GOOD: Consistent ordering (from Zig stdlib)
const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const testing = std.testing;

// Type definitions
pub const Config = struct { ... };
pub const Error = error { ... };

// Public functions
pub fn init(allocator: Allocator) !Config { ... }
pub fn deinit(self: *Config) void { ... }

// Private functions
fn validateConfig(config: *const Config) bool { ... }

// Tests
test "config initialization" { ... }
```

#### ✅ Import Organization

```zig
// ✅ GOOD: Imports first, then type aliases
const std = @import("std");
const builtin = @import("builtin");
const mylib = @import("mylib");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
```

```zig
// ❌ BAD: Mixed imports and code
const std = @import("std");
const MyType = struct { ... };
const builtin = @import("builtin"); // Import should be at top
```

### Function Design

#### ✅ Allocator as First Parameter

```zig
// ✅ GOOD: Allocator first (Zig convention)
pub fn create(allocator: Allocator, capacity: usize) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    // ...
}

pub fn loadFile(allocator: Allocator, path: []const u8) ![]u8 {
    // ...
}
```

```zig
// ❌ BAD: Allocator not first
pub fn create(capacity: usize, allocator: Allocator) !*Self { }
```

#### ✅ init/deinit Pattern

```zig
// ✅ GOOD: Consistent init/deinit pairing
pub fn init(allocator: Allocator) Self {
    return Self{
        .allocator = allocator,
        .items = &[_]Item{},
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.items);
}
```

#### ✅ Explicit Error Sets

```zig
// ✅ GOOD: Explicit error set documents possible failures
pub const ReadError = error{ FileNotFound, PermissionDenied, OutOfMemory };

pub fn readConfig(path: []const u8) ReadError!Config {
    // ...
}
```

```zig
// ❌ BAD: anyerror hides what can fail
pub fn readConfig(path: []const u8) anyerror!Config { }
```

### Error Handling

#### ✅ defer Immediately After Resource Acquisition

```zig
// ✅ GOOD: defer right after acquisition
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();

const buffer = try allocator.alloc(u8, 1024);
defer allocator.free(buffer);
```

```zig
// ❌ BAD: defer separated from acquisition
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
// ... lots of code ...
defer _ = gpa.deinit(); // Easy to forget or misplace
```

#### ✅ errdefer for Multi-Step Initialization

```zig
// ✅ GOOD: errdefer for cleanup on initialization failure
pub fn init(allocator: Allocator, capacity: usize) !Self {
    const buffer = try allocator.alloc(u8, capacity);
    errdefer allocator.free(buffer);

    const metadata = try allocator.create(Metadata);
    errdefer allocator.destroy(metadata);

    return Self{ .buffer = buffer, .metadata = metadata };
}
```

#### ✅ Prefer try Over catch When Propagating

```zig
// ✅ GOOD: try for simple error propagation
const data = try readFile(allocator, path);

// ✅ GOOD: catch when handling specific errors
const data = readFile(allocator, path) catch |err| switch (err) {
    error.FileNotFound => return default_data,
    else => return err,
};
```

```zig
// ❌ BAD: Unnecessary catch just to return error
const data = readFile(allocator, path) catch |e| return e; // Use try
```

### Memory Management

#### ✅ Arena for Temporary Allocations

```zig
// ✅ GOOD: Arena for request-scoped allocations
fn handleRequest(parent_allocator: Allocator, request: Request) !Response {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // All temporary allocations freed together
    const parsed = try parseRequest(allocator, request);
    const result = try processRequest(allocator, parsed);
    return result;
}
```

#### ✅ Explicit Ownership Documentation

```zig
// ✅ GOOD: Document ownership transfer
/// Caller owns returned memory. Must call deinit() or use defer.
pub fn create(allocator: Allocator) !*Self {
    // ...
}

/// Caller owns returned slice. Use allocator.free() to clean up.
pub fn readAll(allocator: Allocator, reader: anytype) ![]u8 {
    // ...
}
```

#### ✅ Prefer Slices Over Pointers

```zig
// ✅ GOOD: Slices carry length information
pub fn processData(data: []const u8) void {
    for (data) |byte| {
        // Safe: slice knows its length
    }
}
```

```zig
// ❌ BAD: Raw pointer loses length (unsafe)
pub fn processData(data: [*]const u8, len: usize) void {
    var i: usize = 0;
    while (i < len) : (i += 1) { // Manual length tracking
        _ = data[i];
    }
}
```

### Assertions and Safety

#### ✅ Minimum 2 Assertions Per Function (TigerBeetle Standard)

```zig
// ✅ GOOD: Assertions verify preconditions and invariants
pub fn findIndex(items: []const i32, target: i32) ?usize {
    std.debug.assert(items.len > 0); // Precondition

    for (items, 0..) |item, i| {
        if (item == target) {
            std.debug.assert(i < items.len); // Invariant
            return i;
        }
    }
    return null;
}
```

#### ✅ Assert Preconditions and Invariants

```zig
// ✅ GOOD: Document assumptions with assertions
pub fn resize(self: *Self, new_size: usize) !void {
    std.debug.assert(new_size > 0); // Size must be positive
    std.debug.assert(self.capacity >= self.len); // Capacity invariant

    if (new_size > self.capacity) {
        std.debug.assert(self.allocator != null); // Need allocator to grow
        try self.grow(new_size);
    }

    self.len = new_size;
    std.debug.assert(self.len <= self.capacity); // Post-condition
}
```

#### ✅ unreachable Only for Provably Impossible Cases

```zig
// ✅ GOOD: unreachable for exhaustive switch with known enum
fn handleColor(color: Color) void {
    switch (color) {
        .red => std.debug.print("Red\n", .{}),
        .green => std.debug.print("Green\n", .{}),
        .blue => std.debug.print("Blue\n", .{}),
        // No else needed; all cases covered
    }
}
```

```zig
// ❌ BAD: unreachable for lazy error handling
const value = parseInt(str) catch unreachable; // Could panic!
```

### Documentation

#### ✅ Doc Comments for Public APIs

```zig
// ✅ GOOD: Doc comments with triple-slash
/// Parses a JSON string into the specified type T.
/// Caller owns returned memory; use deinit() or parseFree().
/// Returns error.SyntaxError if JSON is malformed.
pub fn parseFromSlice(
    comptime T: type,
    allocator: Allocator,
    json: []const u8,
) !T {
    // ...
}
```

#### ✅ Document Ownership and Error Conditions

```zig
// ✅ GOOD: Clear ownership and error documentation
/// Opens file at path for reading.
/// Caller must call close() on returned file handle.
/// Returns error.FileNotFound if path doesn't exist.
/// Returns error.PermissionDenied if insufficient permissions.
pub fn openFile(path: []const u8) !File {
    // ...
}
```

### Testing

#### ✅ test Block Naming

```zig
// ✅ GOOD: Descriptive test names
test "ArrayList.append increases length" {
    var list = ArrayList(i32).init(testing.allocator);
    defer list.deinit();

    try list.append(42);
    try testing.expectEqual(@as(usize, 1), list.items.len);
}

test "HashMap.get returns null for missing key" {
    var map = AutoHashMap([]const u8, i32).init(testing.allocator);
    defer map.deinit();

    try testing.expect(map.get("missing") == null);
}
```

#### ✅ Use testing.allocator for Leak Detection

```zig
// ✅ GOOD: Always use testing.allocator in tests
test "memory leak detection" {
    const allocator = testing.allocator;

    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer); // Leak detected if missing

    // Test fails if defer forgotten
}
```

### Performance Patterns

#### ✅ Prefer Stack Allocation for Fixed-Size Buffers

```zig
// ✅ GOOD: Stack allocation when size known at comptime
var buffer: [4096]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "Value: {}", .{value});
```

```zig
// ❌ BAD: Heap allocation for small fixed-size buffer
const buffer = try allocator.alloc(u8, 4096);
defer allocator.free(buffer);
```

#### ✅ Inline for Performance-Critical Code

```zig
// ✅ GOOD: inline for small hot functions
inline fn fastMin(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
```

#### ✅ Unroll Loops with inline for

```zig
// ✅ GOOD: Unroll comptime-known iterations
inline for (0..4) |i| {
    data[i] = computeValue(i);
}
```

---

## 15.3 Reference Index by Category

This section consolidates 200+ references from all chapters, organized by category for quick lookup.

### Official Zig Documentation

**Language Reference**
- Zig Language Reference: https://ziglang.org/documentation/master/
- Zig Standard Library: https://ziglang.org/documentation/master/std/

**Build System**
- Build System Documentation: https://ziglang.org/documentation/master/#Build-System
- build.zig Guide: https://ziglang.org/learn/build-system/

**Package Management**
- Package Management Guide: https://github.com/ziglang/zig/blob/master/doc/build.zig.zon.md

**Release Notes**
- Zig 0.11 Release Notes: https://ziglang.org/download/0.11.0/release-notes.html
- Zig 0.12 Release Notes: https://ziglang.org/download/0.12.0/release-notes.html
- Zig 0.13 Release Notes: https://ziglang.org/download/0.13.0/release-notes.html
- Zig 0.14 Release Notes: https://ziglang.org/download/0.14.0/release-notes.html

### Production Codebases

**TigerBeetle (Database)**
- Repository: https://github.com/tigerbeetle/tigerbeetle
- TIGER_STYLE Guide: https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
- Notable: Strictest style guide (2+ assertions per function, explicit naming conventions)

**Ghostty (Terminal Emulator)**
- Repository: https://github.com/ghostty-org/ghostty
- Notable: High-performance terminal, graphics programming patterns

**Bun (JavaScript Runtime)**
- Repository: https://github.com/oven-sh/bun
- Notable: JavaScript/C++ interop, performance optimization techniques

**ZLS (Zig Language Server)**
- Repository: https://github.com/zigtools/zls
- Notable: Compiler integration, language analysis patterns

**Zig Compiler (Self-Hosted)**
- Repository: https://github.com/ziglang/zig
- Standard Library Source: https://github.com/ziglang/zig/tree/master/lib/std
- Notable: Canonical Zig style, comprehensive stdlib examples

### Community Resources

**Learning**
- Zig Learn: https://ziglearn.org/
- Zig by Example: https://zig-by-example.com/
- Zig Guide: https://zig.guide/

**Community**
- Zig Forum: https://ziggit.dev/
- r/Zig Subreddit: https://www.reddit.com/r/Zig/
- Zig Discord: https://discord.gg/zig

**Package Registries**
- Astrolabe (Package Search): https://astrolabe.pm/
- Zig Package Index: https://zigpm.org/

### Async & Concurrency Libraries

**Event Loops**
- libxev: https://github.com/mitchellh/libxev (Recommended post-async removal)
- tardy: https://github.com/mookums/tardy

**Utilities**
-zig-threadpool: https://github.com/kprotty/zap

### I/O Libraries

**HTTP**
- zap: https://github.com/zigzap/zap (HTTP server framework)
- httpz: https://github.com/karlseguin/http.zig

**Networking**
- zig-network: https://github.com/MasterQ32/zig-network

**Serialization**
- zig-json (stdlib): std.json
- zig-xml: https://github.com/zig-community/xml

### Testing Frameworks

**Built-in Testing**
- std.testing: Standard library testing facilities
- zig test: Test runner command

**Additional Tools**
- zig-bench: https://github.com/Hejsil/zig-bench (Benchmarking)

### Build Tools

**Cross-Compilation**
- zig cc: Zig as C/C++ compiler: https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html

**CI/CD**
- setup-zig (GitHub Action): https://github.com/goto-bus-stop/setup-zig

### Memory Management

**Allocators**
- std.heap.GeneralPurposeAllocator: Production allocator with safety checks
- std.heap.ArenaAllocator: Batch-free allocator
- std.heap.FixedBufferAllocator: Stack/buffer allocator
- std.heap.c_allocator: C malloc/free wrapper

**Profiling**
- tracy: https://github.com/wolfpld/tracy (Profiler with Zig support)

### Platform-Specific

**WASM/WASI**
- WASI Documentation: https://wasi.dev/
- Zig WASM Guide: https://ziglang.org/documentation/master/#WebAssembly

**Embedded**
- microzig: https://github.com/ZigEmbeddedGroup/microzig

### Data Structures (Chapter 4)

**Containers**
- std.ArrayList: Dynamic array
- std.HashMap/AutoHashMap/StringHashMap: Hash tables
- std.PriorityQueue: Heap-based priority queue
- std.SinglyLinkedList/TailQueue: Linked lists

---

## 15.4 Quick Reference: Syntax

### Variable Declaration

```zig
const x: i32 = 42;              // Immutable, type explicit
const y = 42;                   // Immutable, type inferred
var z: i32 = 42;                // Mutable, type explicit
var w = 42;                     // Mutable, type inferred
var arr: [5]i32 = undefined;    // Array, uninitialized
```

### Function Syntax

```zig
fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn publicFn() void { }      // Public function

fn errorFn() !i32 {             // Returns i32 or error
    return error.Failed;
}

fn genericFn(comptime T: type, val: T) T {
    return val;
}
```

### Control Flow

```zig
// If expression
const max = if (a > b) a else b;

// If statement
if (condition) {
    // ...
} else if (other) {
    // ...
} else {
    // ...
}

// While loop
while (condition) {
    // ...
}

// While with continue expression
var i: u32 = 0;
while (i < 10) : (i += 1) {
    // ...
}

// For loop (iterate over slice/array)
for (items) |item| {
    // ...
}

// For with index
for (items, 0..) |item, i| {
    // ...
}

// Switch expression
const result = switch (value) {
    0 => "zero",
    1, 2, 3 => "low",
    else => "high",
};
```

### Error Handling

```zig
// Error set
const MyError = error{ Failed, InvalidInput };

// Error union type
fn doWork() !i32 { }

// Try (propagate error)
const val = try doWork();

// Catch (handle error)
const val = doWork() catch |err| {
    // Handle err
    return default;
};

// Catch with default
const val = doWork() catch 0;

// Defer (always runs at scope exit)
defer cleanup();

// Errdefer (runs only on error)
errdefer cleanup();
```

### Optionals

```zig
// Optional type
var x: ?i32 = null;
x = 42;

// Unwrap with orelse
const val = x orelse 0;

// Unwrap with if
if (x) |value| {
    // Use value
}

// Pointer unwrap
if (ptr) |p| {
    // p is non-null pointer
}
```

### Pointers and Slices

```zig
// Single-item pointer
const ptr: *i32 = &value;

// Const pointer
const const_ptr: *const i32 = &value;

// Many-item pointer
const many: [*]i32 = ptr;

// Slice (fat pointer: pointer + length)
const slice: []i32 = array[0..3];
const const_slice: []const u8 = "hello";

// Sentinel-terminated slice
const str: [:0]const u8 = "null-terminated";
```

### Structs

```zig
const Point = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Point {
        return Point{ .x = x, .y = y };
    }

    pub fn distance(self: Point) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
};

// Anonymous struct
const config = .{ .width = 800, .height = 600 };
```

### Enums

```zig
const Color = enum {
    red,
    green,
    blue,

    pub fn toRgb(self: Color) [3]u8 {
        return switch (self) {
            .red => .{255, 0, 0},
            .green => .{0, 255, 0},
            .blue => .{0, 0, 255},
        };
    }
};
```

### Unions

```zig
// Tagged union
const Value = union(enum) {
    int: i32,
    float: f64,
    string: []const u8,
};

const v = Value{ .int = 42 };

switch (v) {
    .int => |i| std.debug.print("int: {}\n", .{i}),
    .float => |f| std.debug.print("float: {}\n", .{f}),
    .string => |s| std.debug.print("string: {s}\n", .{s}),
}
```

### Comptime

```zig
// Comptime variable
comptime var count = 0;

// Comptime parameter
fn generic(comptime T: type, val: T) T {
    return val;
}

// Comptime block
comptime {
    @compileLog("This runs at compile time");
}

// Inline for (unrolled at compile time)
inline for (0..4) |i| {
    // Unrolled 4 times
}
```

### Builtin Functions (Selected)

```zig
@import("std")                  // Import module
@as(T, value)                   // Type coercion
@intCast(value)                 // Integer cast
@floatCast(value)               // Float cast
@sizeOf(T)                      // Size of type in bytes
@alignOf(T)                     // Alignment of type
@TypeOf(expr)                   // Get type of expression
@compileError("msg")            // Compile-time error
@compileLog(expr)               // Compile-time print
@field(struct, "name")          // Access field by name
@hasField(T, "name")            // Check field existence
@embedFile("path")              // Embed file at compile time
```

---

## 15.5 Quick Reference: Common Patterns

### Initialization Pattern

```zig
pub const Server = struct {
    allocator: Allocator,
    port: u16,
    clients: ArrayList(*Client),

    pub fn init(allocator: Allocator, port: u16) !Server {
        return Server{
            .allocator = allocator,
            .port = port,
            .clients = ArrayList(*Client).init(allocator),
        };
    }

    pub fn deinit(self: *Server) void {
        for (self.clients.items) |client| {
            client.deinit();
            self.allocator.destroy(client);
        }
        self.clients.deinit();
    }
};
```

### Error Handling with errdefer

```zig
pub fn createResource(allocator: Allocator) !*Resource {
    const resource = try allocator.create(Resource);
    errdefer allocator.destroy(resource);

    resource.buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(resource.buffer);

    try resource.initialize();
    // If initialize() fails, both buffer and resource are freed

    return resource;
}
```

### Arena Pattern for Temporary Allocations

```zig
fn processRequest(parent_allocator: Allocator, request: Request) !Response {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit(); // Free all at once
    const allocator = arena.allocator();

    const parsed = try parseJson(allocator, request.body);
    const validated = try validateData(allocator, parsed);
    const result = try computeResult(allocator, validated);

    // All temporary allocations freed here
    return result;
}
```

### Generic Data Structure

```zig
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: ArrayList(T),

        pub fn init(allocator: Allocator) Self {
            return Self{ .items = ArrayList(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
        }

        pub fn push(self: *Self, item: T) !void {
            try self.items.append(item);
        }

        pub fn pop(self: *Self) ?T {
            return if (self.items.items.len > 0)
                self.items.pop()
            else
                null;
        }
    };
}
```

### Reader/Writer Pattern

```zig
fn processStream(reader: anytype, writer: anytype) !void {
    var buffer: [4096]u8 = undefined;

    while (true) {
        const n = try reader.read(&buffer);
        if (n == 0) break;

        const processed = processData(buffer[0..n]);
        try writer.writeAll(processed);
    }
}
```

### Iterator Pattern

```zig
pub fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []const T,
        index: usize,

        pub fn init(items: []const T) Self {
            return Self{ .items = items, .index = 0 };
        }

        pub fn next(self: *Self) ?T {
            if (self.index >= self.items.len) return null;
            const item = self.items[self.index];
            self.index += 1;
            return item;
        }
    };
}
```

### Builder Pattern

```zig
pub const ConfigBuilder = struct {
    host: ?[]const u8 = null,
    port: ?u16 = null,
    timeout_ms: u32 = 5000,

    pub fn setHost(self: *ConfigBuilder, host: []const u8) *ConfigBuilder {
        self.host = host;
        return self;
    }

    pub fn setPort(self: *ConfigBuilder, port: u16) *ConfigBuilder {
        self.port = port;
        return self;
    }

    pub fn setTimeout(self: *ConfigBuilder, timeout: u32) *ConfigBuilder {
        self.timeout_ms = timeout;
        return self;
    }

    pub fn build(self: ConfigBuilder) !Config {
        return Config{
            .host = self.host orelse return error.MissingHost,
            .port = self.port orelse 8080,
            .timeout_ms = self.timeout_ms,
        };
    }
};
```

### Option Type Pattern

```zig
fn findUser(users: []const User, id: u32) ?User {
    for (users) |user| {
        if (user.id == id) return user;
    }
    return null;
}

// Usage
if (findUser(users, 123)) |user| {
    std.debug.print("Found: {s}\n", .{user.name});
} else {
    std.debug.print("Not found\n", .{});
}
```

### Singleton Pattern

```zig
const GlobalConfig = struct {
    var instance: ?*GlobalConfig = null;
    var mutex: std.Thread.Mutex = .{};

    value: i32,

    pub fn getInstance(allocator: Allocator) !*GlobalConfig {
        mutex.lock();
        defer mutex.unlock();

        if (instance) |inst| return inst;

        const inst = try allocator.create(GlobalConfig);
        inst.* = GlobalConfig{ .value = 0 };
        instance = inst;
        return inst;
    }
};
```

---

## 15.6 Quick Reference: Standard Library

### Memory Operations (std.mem)

```zig
const std = @import("std");

// Copy memory
std.mem.copy(u8, dest, src);

// Set memory
std.mem.set(u8, buffer, 0);

// Compare
const equal = std.mem.eql(u8, a, b);

// Find
const index = std.mem.indexOf(u8, haystack, needle);

// Split
var iter = std.mem.split(u8, text, ",");
while (iter.next()) |part| { }

// Tokenize (skip empty)
var iter = std.mem.tokenize(u8, text, " \t\n");
while (iter.next()) |token| { }
```

### Allocators (std.heap)

```zig
// GeneralPurposeAllocator (production)
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

// ArenaAllocator (batch free)
var arena = std.heap.ArenaAllocator.init(parent_allocator);
defer arena.deinit();
const allocator = arena.allocator();

// FixedBufferAllocator (stack)
var buffer: [1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

// c_allocator (C interop)
const allocator = std.heap.c_allocator;
```

### Allocation Methods

```zig
// Allocate slice
const slice = try allocator.alloc(u8, size);
defer allocator.free(slice);

// Allocate single item
const ptr = try allocator.create(MyStruct);
defer allocator.destroy(ptr);

// Duplicate slice
const copy = try allocator.dupe(u8, original);
defer allocator.free(copy);

// Reallocate
slice = try allocator.realloc(slice, new_size);
```

### ArrayList (std.ArrayList)

```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();

// Append
try list.append(42);

// Extend
try list.appendSlice(&[_]i32{1, 2, 3});

// Access
const item = list.items[0];

// Pop
const last = list.pop();

// Insert
try list.insert(index, value);

// Remove
_ = list.orderedRemove(index);
```

### HashMap (std.HashMap / AutoHashMap)

```zig
var map = std.AutoHashMap([]const u8, i32).init(allocator);
defer map.deinit();

// Put
try map.put("key", 42);

// Get
if (map.get("key")) |value| {
    // Use value
}

// Contains
const exists = map.contains("key");

// Remove
_ = map.remove("key");

// Iterate
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s} = {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

### File I/O (std.fs)

```zig
// Open file
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();

// Read all
const allocator = std.heap.page_allocator;
const content = try file.readToEndAlloc(allocator, 1024 * 1024);
defer allocator.free(content);

// Write
const bytes_written = try file.write("Hello, World!");

// Create file
const new_file = try std.fs.cwd().createFile("output.txt", .{});
defer new_file.close();

// Directory operations
try std.fs.cwd().makeDir("new_dir");
try std.fs.cwd().deleteFile("temp.txt");
```

### Formatting (std.fmt)

```zig
// Print to stderr
std.debug.print("Value: {}\n", .{42});

// Format to buffer
var buffer: [100]u8 = undefined;
const result = try std.fmt.bufPrint(&buffer, "x={d}, y={d}", .{10, 20});

// Allocate formatted string
const str = try std.fmt.allocPrint(allocator, "Value: {}", .{value});
defer allocator.free(str);

// Parse integer
const num = try std.fmt.parseInt(i32, "123", 10);

// Parse float
const val = try std.fmt.parseFloat(f64, "3.14");
```

### JSON (std.json)

```zig
// Parse JSON
const parsed = try std.json.parseFromSlice(MyStruct, allocator, json_text, .{});
defer parsed.deinit();
const data = parsed.value;

// Stringify
var buffer = std.ArrayList(u8).init(allocator);
defer buffer.deinit();
try std.json.stringify(data, .{}, buffer.writer());
```

### Hashing (std.crypto.hash)

```zig
// SHA256
const hash = std.crypto.hash.sha2.Sha256;
var digest: [hash.digest_length]u8 = undefined;
hash.hash(data, &digest, .{});

// Hex encode
var hex_buffer: [hash.digest_length * 2]u8 = undefined;
const hex = std.fmt.bytesToHex(&digest, .lower);
```

### Time (std.time)

```zig
// Unix timestamp (seconds)
const timestamp = std.time.timestamp();

// Milliseconds
const ms = std.time.milliTimestamp();

// Nanoseconds
const ns = std.time.nanoTimestamp();

// Sleep
std.time.sleep(1 * std.time.ns_per_s); // Sleep 1 second
```

### Thread (std.Thread)

```zig
// Spawn thread
const thread = try std.Thread.spawn(.{}, workerFn, .{arg1, arg2});

// Join (wait for completion)
thread.join();

// Detach (run independently)
thread.detach();

// Mutex
var mutex = std.Thread.Mutex{};
mutex.lock();
defer mutex.unlock();
// Critical section

// RwLock
var rw_lock = std.Thread.RwLock{};
rw_lock.lockShared();
defer rw_lock.unlockShared();
// Read access
```

---

## 15.7 Quick Reference: Build System

### Basic build.zig Structure

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Install artifact
    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
```

### Build Options (Compile-Time Configuration)

```zig
// Define options
const options = b.addOptions();
options.addOption(bool, "enable_logging", true);
options.addOption([]const u8, "version", "1.0.0");

exe.root_module.addOptions("config", options);

// Use in code
const config = @import("config");
if (config.enable_logging) {
    // ...
}
```

### Dependencies (build.zig.zon)

```zig
// build.zig.zon
.{
    .name = "myproject",
    .version = "0.1.0",
    .dependencies = .{
        .zap = .{
            .url = "https://github.com/zigzap/zap/archive/v0.5.0.tar.gz",
            .hash = "1220abcd...",
        },
    },
    .paths = .{""},
}
```

```zig
// In build.zig
const zap = b.dependency("zap", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zap", zap.module("zap"));
```

### Test Step

```zig
const tests = b.addTest(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

const test_step = b.step("test", "Run unit tests");
test_step.dependOn(&b.addRunArtifact(tests).step);
```

### Static Library

```zig
const lib = b.addStaticLibrary(.{
    .name = "mylib",
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});

b.installArtifact(lib);
```

### C Interop

```zig
exe.linkLibC();
exe.addIncludePath(b.path("include"));
exe.addCSourceFile(.{
    .file = b.path("src/wrapper.c"),
    .flags = &[_][]const u8{"-std=c99"},
});
exe.linkSystemLibrary("sqlite3");
```

---

## 15.8 Quick Reference: Testing

### Test Block Syntax

```zig
const testing = std.testing;

test "basic test" {
    const result = 2 + 2;
    try testing.expectEqual(@as(i32, 4), result);
}
```

### Common Assertions

```zig
// Equality
try testing.expectEqual(expected, actual);
try testing.expectEqualSlices(u8, expected_slice, actual_slice);
try testing.expectEqualStrings("hello", result);

// Boolean
try testing.expect(condition);

// Approximation
try testing.expectApproxEqAbs(expected, actual, tolerance);

// Error
try testing.expectError(error.Expected, errorUnion);
```

### Memory Leak Detection

```zig
test "memory test" {
    const allocator = testing.allocator; // Detects leaks

    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer); // Required or test fails

    // Test logic
}
```

### Table-Driven Tests

```zig
test "table-driven" {
    const cases = [_]struct { input: i32, expected: i32 }{
        .{ .input = 0, .expected = 0 },
        .{ .input = 1, .expected = 1 },
        .{ .input = 5, .expected = 25 },
    };

    for (cases) |case| {
        const result = square(case.input);
        try testing.expectEqual(case.expected, result);
    }
}
```

---

## 15.9 Common Pitfalls and Solutions

### Pitfall: Forgetting defer

**Problem**: Memory leaks from forgotten cleanup

```zig
// ❌ BAD: Easy to forget cleanup
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
// ... many lines later ...
_ = gpa.deinit(); // Easy to forget!
```

**Solution**: Use defer immediately after acquisition

```zig
// ✅ GOOD: defer right after acquisition
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit(); // Cleanup guaranteed
const allocator = gpa.allocator();
```

### Pitfall: Using anyerror

**Problem**: Hides possible errors, makes debugging harder

```zig
// ❌ BAD: anyerror hides what can go wrong
pub fn loadConfig(path: []const u8) anyerror!Config { }
```

**Solution**: Use explicit error sets

```zig
// ✅ GOOD: Explicit errors document failure modes
pub const LoadError = error{ FileNotFound, ParseError, OutOfMemory };

pub fn loadConfig(path: []const u8) LoadError!Config { }
```

### Pitfall: Undefined Slice/Pointer Behavior

**Problem**: Reading undefined memory

```zig
// ❌ BAD: Reading undefined buffer
var buffer: [100]u8 = undefined;
std.debug.print("{s}\n", .{buffer}); // Undefined behavior!
```

**Solution**: Initialize before reading

```zig
// ✅ GOOD: Initialize before use
var buffer: [100]u8 = undefined;
const n = try file.read(&buffer);
std.debug.print("{s}\n", .{buffer[0..n]}); // Only read initialized bytes
```

### Pitfall: Container Version Confusion (0.15+)

**Problem**: Using old managed API with new unmanaged default

```zig
// ❌ BAD: In 0.15+, this doesn't compile (no stored allocator)
var list = std.ArrayList(i32).init(allocator);
// ... later ...
try list.append(42); // ERROR: append needs allocator parameter
```

**Solution**: Use unmanaged API or explicitly choose managed

```zig
// ✅ GOOD: Explicit unmanaged (0.15+ default)
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(42);

// ✅ GOOD: Or use managed explicitly
var list = std.ArrayListManaged(i32).init(allocator);
defer list.deinit(allocator);
try list.append(allocator, 42);
```

### Pitfall: Incorrect Error Propagation

**Problem**: Catching error just to return it

```zig
// ❌ BAD: Unnecessary catch
const data = readFile(path) catch |err| return err;
```

**Solution**: Use try for simple propagation

```zig
// ✅ GOOD: try propagates automatically
const data = try readFile(path);
```

### Pitfall: Misusing unreachable

**Problem**: Using unreachable for lazy error handling

```zig
// ❌ BAD: Could panic if input is invalid
const value = parseInt(user_input) catch unreachable;
```

**Solution**: Handle errors properly

```zig
// ✅ GOOD: Proper error handling
const value = parseInt(user_input) catch |err| {
    std.log.err("Invalid input: {}", .{err});
    return error.InvalidInput;
};
```

### Pitfall: String Lifetime Issues

**Problem**: Returning stack-allocated string

```zig
// ❌ BAD: Returning pointer to stack memory
fn getName() []const u8 {
    const name = "Alice";
    return name; // Dangling pointer!
}
```

**Solution**: Return string literals or allocated memory

```zig
// ✅ GOOD: String literal (static storage)
fn getName() []const u8 {
    return "Alice";
}

// ✅ GOOD: Heap-allocated (caller frees)
fn getName(allocator: Allocator) ![]u8 {
    return allocator.dupe(u8, "Alice");
}
```

### Pitfall: Not Using testing.allocator

**Problem**: Memory leaks in tests go undetected

```zig
// ❌ BAD: Leaks not detected
test "leak not caught" {
    const allocator = std.heap.page_allocator;
    const buf = try allocator.alloc(u8, 100);
    // Forgot defer! But test passes.
}
```

**Solution**: Always use testing.allocator

```zig
// ✅ GOOD: Leak causes test failure
test "leak detected" {
    const allocator = testing.allocator;
    const buf = try allocator.alloc(u8, 100);
    defer allocator.free(buf); // Required or test fails
}
```

---

## 15.10 Cross-Reference Index

This index maps concepts to their primary chapters for quick navigation.

### Memory Management
- **Allocators**: Chapter 3, Chapter 5, Chapter 6
- **Arena Pattern**: Chapter 3, Chapter 5
- **Ownership**: Chapter 3, Chapter 4, Chapter 6
- **Pointers**: Chapter 3, Chapter 11
- **Slices**: Chapter 3, Chapter 5

### Error Handling
- **Error Sets**: Chapter 6
- **Error Unions**: Chapter 6
- **try/catch**: Chapter 6
- **defer/errdefer**: Chapter 3, Chapter 6
- **Result Types**: Chapter 6

### Data Structures
- **ArrayList**: Chapter 3, Chapter 4
- **HashMap**: Chapter 4
- **Structs**: Chapter 2, Chapter 4
- **Unions**: Chapter 4
- **Enums**: Chapter 2, Chapter 4

### I/O Operations
- **File I/O**: Chapter 5
- **Readers/Writers**: Chapter 5
- **HTTP Client/Server**: Chapter 5
- **Networking**: Chapter 5, Chapter 7
- **Formatting**: Chapter 5

### Concurrency
- **Threads**: Chapter 7
- **Mutex**: Chapter 7
- **RwLock**: Chapter 7
- **Atomics**: Chapter 7
- **Event Loops**: Chapter 7

### Build System
- **build.zig**: Chapter 8, Chapter 9, Chapter 10
- **build.zig.zon**: Chapter 9
- **Dependencies**: Chapter 9
- **Cross-Compilation**: Chapter 8, Chapter 10

### Project Organization
- **Directory Layout**: Chapter 10
- **Modules**: Chapter 8, Chapter 9, Chapter 10
- **CI/CD**: Chapter 10
- **Testing Structure**: Chapter 10, Chapter 12

### Interoperability
- **C FFI**: Chapter 11
- **C ABI**: Chapter 11
- **WASM**: Chapter 11
- **extern/export**: Chapter 11

### Testing
- **Test Blocks**: Chapter 12
- **Assertions**: Chapter 12
- **Benchmarking**: Chapter 12
- **Test Allocator**: Chapter 12

### Advanced Features
- **Comptime**: Chapter 2, Chapter 4, Chapter 11
- **Generics**: Chapter 2, Chapter 4
- **Metaprogramming**: Chapter 2, Chapter 11

---

## 15.11 Version Migration Notes

### Migrating from 0.14.x to 0.15+

**Breaking Changes**

1. **Containers Default to Unmanaged**
   - **0.14**: `ArrayList.init(allocator)` stores allocator
   - **0.15**: `ArrayList.init(allocator)` requires allocator in methods
   - **Migration**: Use methods as-is or explicitly use `ArrayListManaged`

```zig
// 0.14 code
var list = std.ArrayList(i32).init(allocator);
try list.append(42); // Works

// 0.15 code (same API works)
var list = std.ArrayList(i32).init(allocator);
try list.append(42); // Still works
```

2. **build.zig.zon Requires Fingerprint**
   - **0.14**: `.hash` field optional
   - **0.15**: `.fingerprint` field required
   - **Migration**: Run `zig build` to generate fingerprint

3. **Module System Changes**
   - **0.14**: `@import("pkg_name")`
   - **0.15**: Must declare in build.zig with `addImport()`
   - **Migration**: Update build.zig dependency declarations

### Migrating from 0.10.x to 0.11+

**Breaking Changes**

1. **Async/Await Removed**
   - **0.10**: `async fn`, `await`, `nosuspend`
   - **0.11**: All async syntax removed
   - **Migration**: Use event loop libraries (libxev) or manual state machines

2. **Package System Introduced**
   - **0.10**: No formal package system
   - **0.11**: build.zig.zon for dependencies
   - **Migration**: Create build.zig.zon for dependencies

3. **c_void Replaced with anyopaque**
   - **0.10**: `c_void` for type erasure
   - **0.11**: `anyopaque` replaces c_void
   - **Migration**: Replace `*c_void` with `*anyopaque`

### Deprecated Features to Avoid

- **async/await**: Removed in 0.11+. Use libxev or manual state machines.
- **@asyncCall**: Removed with async syntax.
- **c_void**: Use anyopaque (0.11+).
- **Managed Containers as Default**: Use explicit unmanaged or managed (0.15+).

---

## 15.12 Code Examples Index

All examples are located in `sections/15_appendices/examples/`. Each example includes a README.md and runnable code.

### Example 1: Glossary in Context
**Path**: `examples/01_glossary_in_context/`
**Purpose**: Demonstrates 20+ glossary terms in working code
**Run**: `zig run examples/01_glossary_in_context/src/main.zig`
**Concepts**: Allocator, Arena, Error Union, Optional, ArrayList, HashMap, defer, errdefer

### Example 2: Style Demonstration
**Path**: `examples/02_style_demonstration/`
**Purpose**: Shows correct vs. incorrect style patterns
**Run**: `zig run examples/02_style_demonstration/src/main.zig`
**Concepts**: Naming conventions, code organization, assertions, documentation

### Example 3: Pattern Reference
**Path**: `examples/03_pattern_reference/`
**Purpose**: Common Zig patterns quick reference
**Run**: `zig run examples/03_pattern_reference/src/main.zig`
**Concepts**: init/deinit, error handling, memory management, iteration

### Example 4: Build System Reference
**Path**: `examples/04_build_reference/`
**Purpose**: Common build.zig patterns
**Run**: `zig build run`
**Concepts**: Target options, build options, executables, run steps

### Example 5: Testing Reference
**Path**: `examples/05_testing_reference/`
**Purpose**: Testing patterns and assertions
**Run**: `zig test examples/05_testing_reference/src/main.zig`
**Concepts**: Assertions, memory leak detection, table-driven tests

### Example 6: Standard Library Reference
**Path**: `examples/06_stdlib_reference/`
**Purpose**: Common stdlib API usage
**Run**: `zig run examples/06_stdlib_reference/src/main.zig`
**Concepts**: Allocators, containers, string operations, formatting

---

## 15.13 Summary

This chapter provides comprehensive reference materials for Zig development:

**Glossary (Section 15.1)**: 150+ terms covering all Zig concepts from allocators to ZON, with definitions, usage patterns, chapter references, and version notes.

**Style Checklist (Section 15.2)**: 60+ idiomatic guidelines from production codebases (TigerBeetle, Ghostty, Bun, ZLS, stdlib) covering naming, organization, error handling, memory management, assertions, and testing.

**Reference Index (Section 15.3)**: 200+ categorized citations from official docs, production codebases, community resources, libraries, and tools.

**Quick References (Sections 15.4-15.8)**: Syntax tables, common patterns, stdlib APIs, build system, and testing for rapid lookup during development.

**Pitfalls (Section 15.9)**: Common mistakes with concrete solutions for memory leaks, error handling, version changes, and undefined behavior.

**Cross-References (Section 15.10)**: Concept-to-chapter mapping for navigating related topics across the guide.

**Migration Notes (Section 15.11)**: Version-specific breaking changes and upgrade paths (0.10 → 0.11, 0.14 → 0.15).

**Examples (Section 15.12)**: 6 runnable code examples demonstrating glossary terms, style patterns, common idioms, build system, testing, and stdlib usage.

**Use This Chapter**: Keep it open as a desk reference while writing Zig code. Use the glossary for terminology clarification, the style checklist for code review, the quick references for syntax lookup, and the cross-references for finding related concepts.

---

## 15.14 References

### Official Documentation
1. Zig Language Reference: https://ziglang.org/documentation/master/
2. Zig Standard Library: https://ziglang.org/documentation/master/std/
3. Build System Guide: https://ziglang.org/learn/build-system/
4. Zig 0.11-0.14 Release Notes: https://ziglang.org/download/

### Production Codebases
5. TigerBeetle: https://github.com/tigerbeetle/tigerbeetle
6. TigerBeetle TIGER_STYLE: https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
7. Ghostty: https://github.com/ghostty-org/ghostty
8. Bun: https://github.com/oven-sh/bun
9. ZLS: https://github.com/zigtools/zls
10. Zig Compiler (stdlib): https://github.com/ziglang/zig/tree/master/lib/std

### Community Resources
11. Zig Learn: https://ziglearn.org/
12. Zig by Example: https://zig-by-example.com/
13. Zig Guide: https://zig.guide/
14. Zig Forum (ziggit): https://ziggit.dev/
15. Astrolabe Package Search: https://astrolabe.pm/

### Libraries
16. libxev (Event Loop): https://github.com/mitchellh/libxev
17. zap (HTTP Framework): https://github.com/zigzap/zap
18. microzig (Embedded): https://github.com/ZigEmbeddedGroup/microzig

### Tools
19. tracy (Profiler): https://github.com/wolfpld/tracy
20. setup-zig (GitHub Action): https://github.com/goto-bus-stop/setup-zig

---

**Chapter 15 Complete** (2464 lines)

This appendices chapter serves as a comprehensive desk reference for all Zig development needs. Bookmark this chapter and refer to it frequently during coding sessions.
