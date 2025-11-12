# Language Idioms & Core Patterns

> **TL;DR for Zig idioms:**
> - **Naming:** `snake_case` (vars/functions), `PascalCase` (types), `SCREAMING_SNAKE_CASE` (constants)
> - **Cleanup:** `defer cleanup()` (runs at scope exit in LIFO order), `errdefer` (only on error paths)
> - **Errors:** `!T` for error unions, `try` propagates, `catch` handles, see [Ch7 for details](#/07_error_handling)
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

Zig's `defer` executes code when leaving the current scope (via return, break, or block end). `errdefer` executes only when leaving via error return.[^5] See Ch7 for comprehensive coverage of resource cleanup patterns.

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

View source: [vsr.zig](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/src/vsr.zig)

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

View source: [main.zig](https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/src/main.zig)

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

View source: [comptime_string_map.zig](https://github.com/oven-sh/bun/blob/e0aae8adc1ca0d84046f973e563387d0a0abeb4e/src/bun.js/bindings/comptime_string_map.zig)

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
[^4]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/docs/TIGER_STYLE.md)
[^5]: [Zig Language Reference 0.15.2 - defer](https://ziglang.org/documentation/0.15.2/#defer)
[^6]: [Zig Language Reference 0.15.2 - Error Union Type](https://ziglang.org/documentation/0.15.2/#Error-Union-Type)
[^7]: [Zig Language Reference 0.15.2 - comptime](https://ziglang.org/documentation/0.15.2/#comptime)
[^8]: [Zig Language Reference 0.15.2 - import](https://ziglang.org/documentation/0.15.2/#import)
[^9]: [How to organize large projects in Zig](https://stackoverflow.com/questions/78766103/how-to-organize-large-projects-in-zig-language)
[^10]: [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
[^11]: [TigerBeetle vsr.zig](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/src/vsr.zig)
[^12]: [Ghostty main.zig](https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/src/main.zig)
[^13]: [Bun comptime_string_map.zig](https://github.com/oven-sh/bun/blob/e0aae8adc1ca0d84046f973e563387d0a0abeb4e/src/bun.js/bindings/comptime_string_map.zig)
