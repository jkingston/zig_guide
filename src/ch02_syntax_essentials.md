# Zig Syntax Essentials

> **TL;DR for experienced developers:**
> - **Types:** `i32`/`u64` (integers), `f64` (floats), `bool`, `void`
> - **Pointers:** `*T` (single), `[]T` (slice), `[*]T` (many-item), `?T` (optional), `!T` (error union)
> - **Composite:** `struct`, `enum`, `union` (tagged/untagged), `packed struct` (bit-level control)
> - **Variables:** `const` (immutable), `var` (mutable). Prefer `const`.
> - **Control flow:** `if`/`while`/`for`/`switch` (switch must be exhaustive)
> - **Functions:** Return types required. Use `comptime` for generics.
> - **Builtins:** `@intCast`, `@TypeOf`, `@sizeOf` for type operations
> - **Jump to:** [Types §2.1](#types-and-declarations) | [Pointers §2.2](#pointers-arrays-and-slices) | [Composite §2.3](#composite-types) | [Control Flow §2.5](#control-flow)

Zig's syntax prioritizes explicitness and compile-time verification. This chapter covers essential syntax needed before exploring idioms in Chapter 3. Skip if already familiar with Zig syntax.

---

## Types and Declarations

**Integers are sized explicitly. No implicit conversions.**

```zig
const signed: i32 = -42;
const unsigned: u64 = 100;
const ptr_sized: usize = 8;  // Matches pointer width

// Integer literals infer minimal type
const inferred = 42;  // comptime_int, coerces at use
```

**Common integer types:** `i8`, `u8`, `i16`, `u16`, `i32`, `u32`, `i64`, `u64`, `i128`, `u128`, `isize`, `usize`

**Arbitrary bit-width integers** enable precise memory control:

```zig
const tiny: u3 = 7;     // 0-7 (3 bits)
const custom: i13 = 42;  // -4096 to 4095 (13 bits)
const flag: u1 = 1;      // Single bit (0 or 1)
```

Use cases: Protocol implementations, bit-field structures, hardware interfaces.

**Floats follow IEEE 754:**

```zig
const small: f32 = 3.14;
const large: f64 = 2.71828;
const precise: f128 = 1.41421;  // Quad precision
```

**Strings are UTF-8 byte slices:**

```zig
const msg: []const u8 = "Hello";
const literal = "inferred as []const u8";

// C-compatible null-terminated
const cstr: [*:0]const u8 = "C string";
```

**Type aliases use `const`:**

```zig
const UserId = u64;
const Result = ![]const u8;  // Error union alias
```

---

## Pointers, Arrays, and Slices

**Pointers require explicit types. No automatic dereferencing.**

```zig
const value: i32 = 42;
const ptr: *const i32 = &value;  // Single-item pointer
const deref = ptr.*;             // Explicit dereference

var mutable: i32 = 10;
const mut_ptr: *i32 = &mutable;
mut_ptr.* = 20;  // Modify through pointer
```

| Type | Description | Use Case |
|------|-------------|----------|
| `*T` | Single-item pointer | Passing by reference |
| `[]T` | Slice (pointer + length) | Working with sequences |
| `[*]T` | Many-item pointer | C interop, manual indexing |
| `[*:0]T` | Sentinel-terminated | Null-terminated C strings |

**Arrays have compile-time fixed size:**

```zig
const arr: [5]i32 = .{ 1, 2, 3, 4, 5 };
const len = arr.len;  // 5, known at compile time

// Size inferred from initializer
const inferred = [_]u8{ 0x00, 0xFF };
```

**Slices are runtime-sized views:**

```zig
const arr = [_]i32{ 10, 20, 30, 40 };
const slice: []const i32 = arr[1..3];  // [20, 30]

// Iteration uses slices
for (slice) |item| {
    // item is 20, then 30
}
```

**Common pitfall:** Array decay to slice requires explicit syntax:

```zig
const arr = [_]i32{ 1, 2, 3 };

// ❌ Type mismatch
// fn takesSlice(s: []const i32) void { }
// takesSlice(arr);

// ✅ Explicit slice
fn takesSlice(s: []const i32) void {}
takesSlice(&arr);  // Takes address, coerces to slice
```

---

## Composite Types

### Structs

**Structs group related data with named fields:**

```zig
const Point = struct {
    x: i32,
    y: i32,

    // Methods are just namespaced functions
    pub fn distance(self: Point, other: Point) f64 {
        const dx = @as(f64, @floatFromInt(self.x - other.x));
        const dy = @as(f64, @floatFromInt(self.y - other.y));
        return @sqrt(dx * dx + dy * dy);
    }
};

const p1 = Point{ .x = 0, .y = 0 };
const p2 = Point{ .x = 3, .y = 4 };
const dist = p1.distance(p2);  // 5.0
```

**Anonymous structs** enable lightweight data grouping:

```zig
fn getUserInfo() struct { name: []const u8, age: u32 } {
    return .{ .name = "Alice", .age = 30 };
}

const info = getUserInfo();
// info.name is "Alice", info.age is 30
```

**Default field values:**

```zig
const Config = struct {
    port: u16 = 8080,
    host: []const u8 = "localhost",
    debug: bool = false,
};

const cfg1 = Config{};  // All defaults
const cfg2 = Config{ .debug = true };  // Override one field
```

### Enums

**Enums define named constants with optional associated values:**

```zig
const Color = enum {
    red,
    green,
    blue,

    pub fn isWarm(self: Color) bool {
        return self == .red or self == .orange;
    }
};

const color: Color = .red;
```

**Tagged unions** combine enums with data:

```zig
const Value = union(enum) {
    int: i64,
    float: f64,
    string: []const u8,
    boolean: bool,
};

const v1 = Value{ .int = 42 };
const v2 = Value{ .string = "hello" };

// Switch handles all cases
switch (v1) {
    .int => |val| std.debug.print("int: {}\n", .{val}),
    .float => |val| std.debug.print("float: {}\n", .{val}),
    .string => |s| std.debug.print("string: {s}\n", .{s}),
    .boolean => |b| std.debug.print("bool: {}\n", .{b}),
}
```

**Enum with explicit values:**

```zig
const Status = enum(u8) {
    ok = 0,
    error = 1,
    pending = 2,
};

const status_code: u8 = @intFromEnum(Status.ok);  // 0
```

### Unions

**Untagged unions** save memory by overlapping fields:

```zig
const IntOrFloat = union {
    int: i64,
    float: f64,
};

var value: IntOrFloat = undefined;
value.int = 42;
// Accessing value.float is unsafe - no tag to check
```

**Tagged unions** are safer - require enum tag:

```zig
const Payload = union(enum) {
    none,
    text: []const u8,
    number: i64,
};

const p = Payload{ .text = "data" };
if (p == .text) {
    // Safe to access p.text
}
```

### Packed Structs

**Packed structs** control bit-level layout:

```zig
const Flags = packed struct {
    read: bool,
    write: bool,
    execute: bool,
    _padding: u5 = 0,  // Pad to byte boundary
};

const flags = Flags{ .read = true, .write = false, .execute = true };
const as_byte: u8 = @bitCast(flags);  // 0b00000101
```

**Use cases:**
- Hardware register interfaces
- Network protocol headers
- File format parsing
- Bit-field manipulation

**Packed struct with bit-width integers:**

```zig
const IPv4Header = packed struct {
    version: u4,        // 4 bits
    ihl: u4,            // 4 bits
    dscp: u6,           // 6 bits
    ecn: u2,            // 2 bits
    total_length: u16,  // 16 bits
    // ... (32 bits total in this example)
};

// Guaranteed layout matches network byte order
```

**Memory guarantees:**
- Packed structs have no padding between fields
- Total size equals sum of field bit widths (rounded to byte boundary)
- Field order matches declaration order

---

## Optionals and Error Unions

**Optionals represent potentially absent values using `?T`:**

```zig
const maybe: ?i32 = null;
const present: ?i32 = 42;

// Unwrap with orelse
const value = maybe orelse 0;

// Unwrap with if
if (maybe) |val| {
    // val is i32, not ?i32
} else {
    // Handle null case
}
```

**Error unions represent failable operations using `!T`:**

```zig
fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

// Propagate with try
const result = try divide(10, 2);  // Returns 5 or propagates error

// Catch and handle
const safe = divide(10, 0) catch 0;  // Returns 0 on error
```

| Feature | Optional `?T` | Error Union `!T` |
|---------|---------------|------------------|
| Represents | Absence | Failure |
| Null-like | `null` | `error.Name` |
| Unwrap | `orelse` | `catch` |
| Propagate | `orelse return` | `try` |

See Ch7 for comprehensive error handling patterns.

---

## Variables and Constants

**Immutability is default:**

```zig
const x = 42;        // Cannot reassign
var y: i32 = 10;     // Mutable
y = 20;              // ✅ OK
// x = 100;          // ❌ Compile error
```

**Type inference reduces boilerplate:**

```zig
const inferred = 42;           // comptime_int
const explicit: u32 = 42;      // u32
const computed = inferred * 2; // comptime_int
```

**Shadowing is not allowed in same scope:**

```zig
const x = 10;
// const x = 20;  // ❌ Compile error

{
    const x = 20;  // ✅ Different scope
}
```

---

## Control Flow

**If expressions return values:**

```zig
const max = if (a > b) a else b;

// Statement form
if (condition) {
    // ...
} else if (other) {
    // ...
} else {
    // ...
}
```

**While loops with optional continue expression:**

```zig
var i: u32 = 0;
while (i < 10) : (i += 1) {  // Continue expression after each iteration
    if (i == 5) break;
    if (i == 3) continue;
}
```

**For loops iterate over arrays and slices:**

```zig
const items = [_]i32{ 10, 20, 30 };

// Basic iteration
for (items) |item| {
    // item is i32
}

// With index
for (items, 0..) |item, idx| {
    // idx is usize
}

// Range iteration
for (0..10) |i| {
    // i from 0 to 9
}
```

**Switch must be exhaustive:**

```zig
const value: u8 = 42;
switch (value) {
    0 => {},                    // Single value
    1...10 => {},               // Range (inclusive)
    11, 12, 13 => {},           // Multiple values
    else => {},                 // Required if not exhaustive
}

// Switch as expression
const category = switch (value) {
    0 => "zero",
    1...10 => "small",
    else => "large",
};
```

**Common pitfall:** `defer` in loops executes per iteration:

```zig
// ❌ Allocates 100 buffers, frees all at end
for (0..100) |_| {
    const buf = try allocator.alloc(u8, 1024);
    defer allocator.free(buf);  // Defers until loop end
    // use buf
}

// ✅ Use nested block for immediate cleanup
for (0..100) |_| {
    {
        const buf = try allocator.alloc(u8, 1024);
        defer allocator.free(buf);  // Defers until block end
        // use buf
    }  // buf freed here
}
```

See Ch3 §3.3 for `defer` and `errdefer` patterns.

---

## Functions

**Return type required (except `void`):**

```zig
fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn noReturn(a: i32) void {
    _ = a;  // Suppress unused warning
}
```

**Generic functions use `comptime` parameters:**

```zig
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

const result = max(i32, 10, 20);  // T = i32
```

**Error return types integrate with `try`:**

```zig
fn readFile(path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    // ...
}
```

---

## Builtin Functions

**Type conversion requires explicit builtins:**

```zig
const a: i32 = 42;
const b: u64 = @intCast(a);      // Signed to unsigned
const c: f32 = @floatFromInt(a); // Int to float
const d: i32 = @intFromFloat(3.14); // Float to int (truncates)
```

**Type introspection at compile time:**

```zig
const T = @TypeOf(42);           // Returns type
const size = @sizeOf(i32);       // Returns 4
const align_val = @alignOf(i32); // Returns alignment

// Compile-time checks
if (@sizeOf(usize) == 8) {
    // 64-bit platform
}
```

**Common builtins:**

| Builtin | Purpose | Example |
|---------|---------|---------|
| `@intCast` | Safe integer conversion | `@intCast(value)` |
| `@floatFromInt` | Integer to float | `@floatFromInt(42)` |
| `@intFromFloat` | Float to int (truncate) | `@intFromFloat(3.14)` |
| `@intFromEnum` | Enum to integer | `@intFromEnum(Status.ok)` |
| `@TypeOf` | Get type of expression | `@TypeOf(x)` |
| `@sizeOf` | Size in bytes | `@sizeOf(T)` |
| `@bitCast` | Reinterpret bits | `@bitCast(value)` |
| `@import` | Load module | `@import("std")` |
| `@compileError` | Emit compile error | `@compileError("msg")` |

Full builtin reference: https://ziglang.org/documentation/master/#Builtin-Functions

---

## Syntax Quick Reference

```zig
// Primitive types
const int: i32 = -42;
const uint: u64 = 100;
const float: f64 = 3.14;
const boolean: bool = true;
const bit_width: u7 = 127;      // Arbitrary bit-width
const optional: ?i32 = null;
const err_union: !i32 = error.Fail;

// Composite types
const Point = struct { x: i32, y: i32 };
const Color = enum { red, green, blue };
const Value = union(enum) { int: i64, string: []u8 };
const Flags = packed struct { read: bool, write: bool };

// Variables
const immutable = 42;
var mutable: i32 = 10;

// Pointers & Slices
const ptr: *const i32 = &int;
const slice: []const u8 = "string";
const array: [3]i32 = .{ 1, 2, 3 };

// Control flow
if (condition) value1 else value2
while (cond) : (continue_expr) { }
for (items) |item| { }
for (items, 0..) |item, idx| { }
switch (value) {
    case => result,
    else => default,
}

// Functions
fn name(param: Type) ReturnType { }
fn generic(comptime T: type, val: T) T { }
fn fallible() !T { }

// Common builtins
@intCast(value)
@TypeOf(expr)
@sizeOf(T)
@bitCast(value)
@import("module")
```

---

**Next:** Chapter 3 covers idiomatic patterns: `defer`, error handling, `comptime` generics, and naming conventions.
