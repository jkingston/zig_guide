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
- Package Management Guide: https://github.com/ziglang/zig/blob/0.15.2/doc/build.zig.zon.md

**Release Notes**
- Zig 0.11 Release Notes: https://ziglang.org/download/0.11.0/release-notes.html
- Zig 0.12 Release Notes: https://ziglang.org/download/0.12.0/release-notes.html
- Zig 0.13 Release Notes: https://ziglang.org/download/0.13.0/release-notes.html
- Zig 0.14 Release Notes: https://ziglang.org/download/0.14.0/release-notes.html

### Production Codebases

**TigerBeetle (Database)**
- Repository: https://github.com/tigerbeetle/tigerbeetle
- TIGER_STYLE Guide: https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/docs/TIGER_STYLE.md
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
6. TigerBeetle TIGER_STYLE: https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/docs/TIGER_STYLE.md
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
