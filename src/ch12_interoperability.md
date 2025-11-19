# Interoperability (C/C++/WASI/WASM)

> **TL;DR for experienced C/C++ developers:**
> - **Import C headers:** `const c = @cImport(@cInclude("header.h"));`
> - **Call C function:** `extern "c" fn function_name(...) return_type;`
> - **Expose to C:** `export fn zig_function(...) return_type`
> - **Function pointers:** Add `callconv(.C)` for ABI compatibility
> - **Link libc:** `exe.linkLibC()` in build.zig
> - **See [Quick Reference](#quick-reference-c-interop-mechanisms) below for decision tree**
> - **Jump to:** [C headers](#cimport-and-c-header-translation) | [Extern/Export](#extern-and-export-declarations) | [WASM](#webassembly-targets)

## Overview

Zig treats C as a first-class citizen, providing direct, zero-overhead integration via:

- **`@cImport`** - Translates C headers at compile-time using Clang
- **`extern`/`export`** - Declares cross-language function boundaries
- **C-compatible types** - Match platform ABIs exactly

This eliminates the impedance mismatch common in FFI systems, enabling gradual C migration and library integration (SQLite, Vulkan, system APIs).

**Memory safety at boundaries:** Responsibility for allocation/deallocation must be explicit. Use `defer` for cleanup (see Ch7). Mixing allocators or mismatched types causes platform-specific bugs.

**WebAssembly:** wasm32-freestanding (browser + JS FFI) and wasm32-wasi (POSIX-like). Linear memory model: pointers become 32-bit offsets.

**Coverage:** C/C++ integration, WASM compilation, production patterns from Ghostty, TigerBeetle, Bun.

## Quick Reference: C Interop Mechanisms

| Mechanism | Purpose | When to Use | Example | Requires libc |
|-----------|---------|-------------|---------|---------------|
| `@cImport` | Import C headers | Need full C API, translate types at compile-time | `const c = @cImport(@cInclude("stdio.h"));` | Yes |
| `extern` | Declare external C function | Call C function without header, minimal deps | `extern "c" fn malloc(size: usize) ?*anyopaque;` | No (but must link) |
| `export` | Expose Zig function to C | Create C-callable library/API | `export fn add(a: i32, b: i32) i32` | No |
| `callconv(.C)` | Specify calling convention | Function pointers, platform-specific APIs | `fn callback() callconv(.C) void` | No |
| `@cDefine` | Define C macro for import | Control conditional compilation in headers | `@cDefine("DEBUG", "1")` (in `@cImport`) | Yes |

**Decision tree:**
- **Have C header?** → Use `@cImport` (easiest, full type translation)
- **No header, calling C?** → Use `extern` (manual declaration)
- **Exposing Zig to C?** → Use `export` (creates C-compatible symbols)
- **Function pointer for C?** → Add `callconv(.C)` (ensures ABI compatibility)

## Core Concepts

### @cImport and C Header Translation

The `@cImport` builtin function is Zig's primary mechanism for importing C declarations. Unlike traditional FFI approaches that require manual binding generation, @cImport invokes Clang internally to translate C headers directly into Zig-compatible types at compile time.[^1]

**Basic Usage:**

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
});

pub fn main() !void {
    _ = c.printf("Hello from C!\n");
}
```

The `@cImport` block creates an anonymous struct containing all declarations from the included headers. Each `@cInclude` directive specifies which header to process. The distinction is important: `@cImport` is the function that creates the import context, while `@cInclude` is a directive within that context specifying individual headers.

**Translation Process:**

When Zig encounters @cImport, it:

1. Invokes Clang with platform-appropriate flags for target architecture and OS
2. Parses C headers into Clang's AST (Abstract Syntax Tree)
3. Translates C types, functions, and constants into Zig equivalents
4. Caches the translation to avoid reprocessing on subsequent builds
5. Makes symbols available through the returned struct

This translation happens at compile time, not runtime, ensuring zero overhead. The cache directory stores translated headers keyed by content hash, so changing header contents or include paths invalidates only affected translations.

**Include Path Configuration:**

C headers often reference other headers via relative paths. Configure include paths in build.zig:

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.addIncludePath(b.path("c_headers"));
    exe.addIncludePath(b.path("vendor/library/include"));
    exe.linkLibC();

    b.installArtifact(exe);
}
```

The `linkLibC()` call adds system include paths automatically, enabling standard library headers like stdio.h and stdlib.h to be found. Custom headers require explicit `addIncludePath` calls with paths relative to build.zig.[^2]

**Macro Translation:**

C macros present challenges for translation. Simple constant macros translate successfully:

```c
// C header
#define MAX_SIZE 1024
#define PI 3.14159
```

```zig
// Accessible in Zig as:
const max_size = c.MAX_SIZE;  // 1024
const pi = c.PI;              // 3.14159
```

However, complex macros involving token pasting (##), stringification (#), or variadic arguments fail to translate. For these cases, create a C wrapper file that converts macros to actual functions:

```c
// wrapper.c
#include "complex_header.h"

int get_complex_value(void) {
    return COMPLEX_MACRO(arg1, arg2);
}
```

Compile wrapper.c alongside Zig code and call the wrapper function instead of the macro. This pattern appears frequently in production code when integrating legacy C libraries.

**Conditional Compilation:**

@cImport supports build-time conditionals for platform-specific headers. Ghostty demonstrates this pattern:[^3]

```zig
const builtin = @import("builtin");
const build_options = @import("build_options");

pub const c = @cImport({
    @cInclude("hb.h");
    if (build_options.freetype) @cInclude("hb-ft.h");
    if (builtin.os.tag.isDarwin()) @cInclude("hb-coretext.h");
});
```

This enables selective header inclusion based on build options or target platform, avoiding compilation errors from missing platform-specific headers.

**Performance Considerations:**

Large C header files increase compile time on first build. Subsequent builds use cached translations, but the initial penalty can be significant. Organize imports by subsystem to enable incremental recompilation:

```zig
// Separate import blocks for different subsystems
const graphics_c = @cImport({
    @cInclude("vulkan/vulkan.h");
});

const audio_c = @cImport({
    @cInclude("portaudio.h");
});

const db_c = @cImport({
    @cInclude("sqlite3.h");
});
```

When only audio code changes, graphics and database headers need not be reprocessed.

### Extern and Export Declarations

The `extern` keyword declares functions defined elsewhere—typically in C libraries or object files compiled separately. The `export` keyword makes Zig functions callable from C by generating C-compatible symbols.[^4]

**Declaring External Functions:**

```zig
// Declare C function to call from Zig
extern "c" fn malloc(size: usize) ?*anyopaque;
extern "c" fn free(ptr: ?*anyopaque) void;
extern "c" fn strlen(s: [*:0]const u8) usize;

pub fn allocateBuffer(size: usize) ![]u8 {
    const ptr = malloc(size) orelse return error.OutOfMemory;
    const bytes = @as([*]u8, @ptrCast(ptr));
    return bytes[0..size];
}
```

The `"c"` string literal after `extern` specifies C calling convention. Other conventions include `.C` (same as "c"), `.Stdcall` for Windows APIs, and `.Naked` for functions without prologues.

**Exporting Functions to C:**

```zig
// Make Zig function callable from C
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn processData(data: [*]const u8, len: usize) i32 {
    // Process data...
    return 0; // Success code
}
```

From C code, these appear as regular C functions:

```c
// C header for Zig library
extern int32_t add(int32_t a, int32_t b);
extern int32_t processData(const uint8_t* data, size_t len);
```

Exported symbols use the function name directly without name mangling, ensuring C code can link against them.

**Calling Conventions:**

Calling conventions determine how arguments are passed (registers vs stack) and who cleans up the stack. Specify conventions with `callconv`:

```zig
fn standardC() callconv(.C) void {
    // C calling convention (cdecl on x86)
}

fn windowsStdcall() callconv(.Stdcall) void {
    // Windows stdcall convention
}

fn alwaysInline() callconv(.Inline) void {
    // Always inlined at call site
}
```

Most C interop uses `.C` convention. Platform-specific APIs may require `.Stdcall` (Win32 API) or other conventions.

**Symbol Visibility and Weak Linkage:**

Advanced use cases require controlling symbol visibility and linkage. Zig's standard library uses weak linkage for optional symbols:[^5]

```zig
extern var _mh_execute_header: mach_hdr;
var dummy_execute_header: mach_hdr = undefined;

comptime {
    if (builtin.os.tag.isDarwin()) {
        @export(&dummy_execute_header, .{
            .name = "_mh_execute_header",
            .linkage = .weak,
        });
    }
}
```

Weak linkage allows symbols to be overridden by strong symbols from other object files, enabling fallback implementations.

**Function Pointers and Callbacks:**

C libraries frequently use function pointers for callbacks. Declare callback types matching C signatures:

```zig
const CallbackFn = ?*const fn (ctx: ?*anyopaque, event: i32) callconv(.C) void;

extern "c" fn register_callback(ctx: ?*anyopaque, callback: CallbackFn) void;

fn myCallback(ctx: ?*anyopaque, event: i32) callconv(.C) void {
    _ = ctx;
    std.debug.print("Event: {d}\n", .{event});
}

pub fn setupCallback() void {
    register_callback(null, myCallback);
}
```

Ensure callback functions use C calling convention and that any context pointers remain valid for the callback's lifetime.

**Variadic Functions:**

Zig can call C variadic functions but cannot define them:

```zig
pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;
pub extern "c" fn scanf(format: [*:0]const u8, ...) c_int;

pub fn example() void {
    _ = printf("Number: %d, String: %s\n", 42, "test");
}
```

To create variadic-like functionality from Zig, accept slices and use C wrappers with va_list internally.

### C Type Mapping and ABI Compatibility

Correct type mapping between C and Zig is fundamental for ABI compatibility. Using the wrong types causes subtle bugs that may only manifest on specific platforms or architectures.[^6]

**The Critical Rule: Use C Types for C APIs**

When declaring C functions, always use Zig's C-compatible types (`c_int`, `c_long`, etc.) unless the C API explicitly uses fixed-size types (`int32_t`, `uint64_t`).

**Wrong:**
```zig
// Assumes int is 32-bit everywhere
extern fn process_value(value: i32) void;
```

**Correct:**
```zig
// Adapts to platform's int size
extern fn process_value(value: c_int) void;
```

This distinction matters because C's `int` type varies by platform:
- Modern desktop platforms: 32-bit
- Historical 16-bit platforms: 16-bit
- Some 64-bit ABIs: could be 64-bit

Using `c_int` ensures compatibility across all platforms Zig supports.

**Complete Type Reference:**

| C Type | Zig Type | Platform Dependent | Notes |
|--------|----------|-------------------|-------|
| `char` | `c_char` | Yes (sign) | May be signed or unsigned |
| `signed char` | `i8` | No | Always signed |
| `unsigned char` | `u8` | No | Always unsigned |
| `short` | `c_short` | Yes (size) | Usually 16-bit |
| `unsigned short` | `c_ushort` | Yes (size) | Usually 16-bit |
| `int` | `c_int` | Yes (size) | Usually 32-bit |
| `unsigned int` | `c_uint` | Yes (size) | Usually 32-bit |
| `long` | `c_long` | Yes (size) | 32-bit on Win64, 64-bit on Unix64 |
| `unsigned long` | `c_ulong` | Yes (size) | Platform-dependent |
| `long long` | `c_longlong` | No | At least 64-bit |
| `unsigned long long` | `c_ulonglong` | No | At least 64-bit |
| `float` | `f32` | No | IEEE 754 single precision |
| `double` | `f64` | No | IEEE 754 double precision |
| `long double` | `c_longdouble` | Yes | 80-bit on x86, varies elsewhere |
| `size_t` | `usize` | Yes | Pointer-sized unsigned |
| `ssize_t` | `isize` | Yes | Pointer-sized signed |
| `ptrdiff_t` | `isize` | Yes | Pointer difference type |
| `intptr_t` | `isize` | Yes | Can hold pointer value |
| `uintptr_t` | `usize` | Yes | Can hold pointer value |
| `int8_t` | `i8` | No | Fixed 8-bit signed |
| `uint8_t` | `u8` | No | Fixed 8-bit unsigned |
| `int16_t` | `i16` | No | Fixed 16-bit signed |
| `uint16_t` | `u16` | No | Fixed 16-bit unsigned |
| `int32_t` | `i32` | No | Fixed 32-bit signed |
| `uint32_t` | `u32` | No | Fixed 32-bit unsigned |
| `int64_t` | `i64` | No | Fixed 64-bit signed |
| `uint64_t` | `u64` | No | Fixed 64-bit unsigned |
| `bool` (C99) | `c_bool` | Yes | Use for C99/C11 bool |
| `void*` | `*anyopaque` | No | Opaque pointer |
| `const void*` | `*const anyopaque` | No | Const opaque pointer |

**Platform Type Variations:**

Zig's standard library demonstrates platform-specific type selection:[^7]

```zig
pub const ino_t = switch (native_os) {
    .linux => linux.ino_t,
    .emscripten => emscripten.ino_t,
    .wasi => wasi.inode_t,
    .windows => windows.LARGE_INTEGER,
    .haiku => i64,
    else => u64,
};

pub const time_t = switch (native_os) {
    .linux => linux.time_t,
    .windows => c_longlong,
    else => isize,
};
```

This shows how even standard POSIX types vary significantly across platforms. Always use the appropriate C-compatible type.

**Pointer Type Mapping:**

Zig provides multiple pointer types with different semantics:

| C Pointer | Zig Type | Semantics | Nullable |
|-----------|----------|-----------|----------|
| `T*` (single item) | `*T` | Single-item pointer | No |
| `T*` (nullable) | `?*T` | Optional single-item | Yes |
| `T*` (array) | `[*]T` | Many-item pointer | No |
| `T*` (C compatible) | `[*c]T` | C pointer (all uses) | Yes |
| `char*` (string) | `[*:0]u8` | Null-terminated string | No |
| `const char*` | `[*:0]const u8` | Const null-terminated | No |

The `[*c]T` pointer type is special—it's compatible with all C pointer uses:

```zig
const ptr: [*c]u8 = malloc(100);
if (ptr == null) return error.OutOfMemory;

// Can use as single-item pointer
ptr[0] = 42;

// Can use as many-item pointer
ptr[10] = 43;

// Can compare with null
if (ptr == null) {
    // Handle error
}
```

Use `[*c]T` when interacting with C APIs that may return null or expect nullable pointers. For pure Zig code, prefer more specific pointer types like `*T` or `[*]T`.

**Struct Layout and Alignment:**

C structs require `extern` keyword to preserve their layout:

```zig
// Zig may reorder fields for optimization
const BadPoint = struct {
    x: f32,
    y: f32,
};

// C-compatible layout, fields not reordered
const GoodPoint = extern struct {
    x: f32,
    y: f32,
};
```

Without `extern`, Zig's compiler may reorder fields to optimize memory layout or alignment. C code expects fields in declaration order, so always use `extern struct` for C interop.

**Padding and Alignment:**

C compilers insert padding to satisfy alignment requirements:

```zig
const MixedStruct = extern struct {
    a: u8,     // 1 byte
    // 3 bytes padding
    b: u32,    // 4 bytes (requires 4-byte alignment)
    c: u16,    // 2 bytes
    // 2 bytes padding (to make struct size multiple of 4)
};

comptime {
    assert(@sizeOf(MixedStruct) == 12); // Not 7
}
```

Zig preserves C padding rules automatically for extern structs. Use `@sizeOf`, `@alignOf`, and `@offsetOf` to verify struct layout matches C expectations.

**Packed Structs for Bitfields:**

For C bitfields or tightly-packed data structures:

```zig
const BitFlags = packed struct {
    flag_a: bool,
    flag_b: bool,
    flag_c: bool,
    unused: u5,
};

comptime {
    assert(@sizeOf(BitFlags) == 1); // Exactly 1 byte
}
```

Packed structs eliminate padding entirely, useful for hardware registers or network protocols.

**Opaque Types:**

C often uses incomplete type declarations (forward declarations):

```c
// C header
typedef struct sqlite3 sqlite3;
struct sqlite3* sqlite3_open(...);
```

Zig represents these with opaque types:

```zig
const sqlite3 = opaque {};

var db: ?*sqlite3 = null;
extern fn sqlite3_open(filename: [*:0]const u8, db: *?*sqlite3) c_int;
```

Opaque types have no size or alignment—they can only be used as pointer targets. This matches C's incomplete types perfectly.

**String Handling:**

C strings are null-terminated byte arrays. Zig string literals are not null-terminated by default, requiring explicit conversion:

```zig
const zig_str: []const u8 = "Hello";         // Not null-terminated
const c_str: [*:0]const u8 = "Hello";        // Null-terminated

// Convert Zig string to C string
const allocator = std.heap.c_allocator;
const c_allocated = try allocator.dupeZ(u8, zig_str);
defer allocator.free(c_allocated);

_ = c.printf("%s\n", c_allocated.ptr);
```

The `:0` sentinel type annotation indicates null termination. When passing strings to C functions, always ensure null termination to avoid buffer overruns.

**Boolean Representation:**

C99 introduced `bool` type via stdbool.h. Pre-C99 code uses `int` for booleans:

```zig
// For C99/C11 code with stdbool.h
extern fn modern_c_func(flag: c_bool) void;

// For pre-C99 code
extern fn legacy_c_func(flag: c_int) void;

pub fn example() void {
    modern_c_func(true);   // Zig bool converts to c_bool
    legacy_c_func(1);      // Use 1/0 for legacy code
}
```

### Build System Integration

Integrating C source files and libraries into Zig builds requires configuring compilation flags, include paths, and library dependencies in build.zig.[^8]

**Adding C Source Files:**

The `addCSourceFiles` method compiles C code alongside Zig:

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.addCSourceFiles(.{
        .files = &.{
            "c_src/helper.c",
            "c_src/platform.c",
            "c_src/wrapper.c",
        },
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-std=c99",
            "-pedantic",
        },
    });

    exe.addIncludePath(b.path("c_src"));
    exe.linkLibC();

    b.installArtifact(exe);
}
```

The `.flags` field accepts standard C compiler flags. Use `-std=c99` or `-std=c11` to specify language standard, and warning flags like `-Wall -Wextra` to catch issues early.

**Linking System Libraries:**

External libraries require explicit linking:

```zig
exe.linkLibC();                    // C standard library
exe.linkSystemLibrary("sqlite3");  // SQLite3
exe.linkSystemLibrary("pthread");  // POSIX threads
exe.linkSystemLibrary("m");        // Math library (Unix)
```

System libraries are found via pkg-config or standard system paths. On Windows, this may require additional configuration for library search paths.

**Framework Linking (macOS/iOS):**

Apple platforms use frameworks instead of libraries:

```zig
if (target.result.os.tag.isDarwin()) {
    exe.linkFramework("Cocoa");
    exe.linkFramework("Metal");
    exe.linkFramework("QuartzCore");
}
```

Frameworks contain headers, libraries, and resources in a single bundle.

**Conditional Compilation:**

Platform-specific code requires conditional file inclusion:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    var c_sources = std.ArrayList([]const u8).init(b.allocator);
    defer c_sources.deinit();

    // Common files
    c_sources.append("src/common.c") catch unreachable;

    // Platform-specific files
    if (target.result.os.tag == .windows) {
        c_sources.append("src/windows.c") catch unreachable;
        exe.linkSystemLibrary("user32");
    } else if (target.result.os.tag.isDarwin()) {
        c_sources.append("src/macos.c") catch unreachable;
        exe.linkFramework("Cocoa");
    } else {
        c_sources.append("src/linux.c") catch unreachable;
        exe.linkSystemLibrary("X11");
    }

    exe.addCSourceFiles(.{
        .files = c_sources.items,
        .flags = &.{"-Wall", "-Wextra"},
    });
    exe.linkLibC();

    b.installArtifact(exe);
}
```

This pattern enables single codebase builds for multiple platforms with platform-specific implementations.

**Cross-Compilation:**

Zig's cross-compilation support extends to C dependencies. When building for a different target, C source files are automatically compiled for that target:

```zig
const targets = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

for (targets) |t| {
    const resolved_target = b.resolveTargetQuery(t);

    const exe = b.addExecutable(.{
        .name = b.fmt("myapp-{s}-{s}", .{
            @tagName(t.cpu_arch.?),
            @tagName(t.os_tag.?),
        }),
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = resolved_target,
            .optimize = optimize,
        }),
    });

    exe.addCSourceFiles(.{
        .files = &.{"src/helper.c"},
        .flags = &.{"-Wall"},
    });
    exe.linkLibC();

    b.installArtifact(exe);
}
```

This builds the same source for multiple targets in a single `zig build` invocation.

### C++ Interoperability via Extern "C" Bridges

Zig cannot directly call C++ code due to fundamental incompatibilities: name mangling for overloading, virtual tables, templates, and exception handling. The solution is creating a C-compatible bridge layer that wraps C++ functionality.[^9]

**Fundamental Limitations:**

- No direct C++ class support
- Cannot call methods with name mangling
- Cannot use templates (must instantiate in bridge)
- Exceptions must not cross boundary
- RAII incompatible with Zig's explicit cleanup

**Bridge Architecture:**

```
Zig Code → C Bridge (extern "C") → C++ Implementation
```

The C bridge provides a C-compatible API that Zig can call, while internally using C++ classes and features.

**Basic Bridge Pattern:**

Given a C++ class:

```cpp
// MyCppClass.hpp
class MyCppClass {
public:
    MyCppClass(int value);
    ~MyCppClass();
    int getValue() const;
    void setValue(int value);
private:
    int value_;
};
```

Create a C bridge header:

```cpp
// c_bridge.h
#ifndef C_BRIDGE_H
#define C_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct MyCppClass_Opaque MyCppClass_Opaque;

MyCppClass_Opaque* MyCppClass_create(int value);
void MyCppClass_destroy(MyCppClass_Opaque* obj);
int MyCppClass_getValue(const MyCppClass_Opaque* obj);
void MyCppClass_setValue(MyCppClass_Opaque* obj, int value);

#ifdef __cplusplus
}
#endif

#endif
```

And implementation:

```cpp
// c_bridge.cpp
#include "c_bridge.h"
#include "MyCppClass.hpp"

extern "C" {

MyCppClass_Opaque* MyCppClass_create(int value) {
    try {
        return reinterpret_cast<MyCppClass_Opaque*>(
            new MyCppClass(value)
        );
    } catch (...) {
        return nullptr;  // Never let exceptions escape
    }
}

void MyCppClass_destroy(MyCppClass_Opaque* obj) {
    delete reinterpret_cast<MyCppClass*>(obj);
}

int MyCppClass_getValue(const MyCppClass_Opaque* obj) {
    try {
        return reinterpret_cast<const MyCppClass*>(obj)->getValue();
    } catch (...) {
        return 0;  // Safe default
    }
}

void MyCppClass_setValue(MyCppClass_Opaque* obj, int value) {
    try {
        reinterpret_cast<MyCppClass*>(obj)->setValue(value);
    } catch (...) {
        // Log error but cannot propagate
    }
}

}  // extern "C"
```

From Zig:

```zig
const c = @cImport({
    @cInclude("c_bridge.h");
});

pub fn example() !void {
    const obj = c.MyCppClass_create(42) orelse return error.CreateFailed;
    defer c.MyCppClass_destroy(obj);

    const value = c.MyCppClass_getValue(obj);
    std.debug.print("Value: {d}\n", .{value});

    c.MyCppClass_setValue(obj, 100);
}
```

**Key Bridge Patterns:**

1. **Opaque pointers**: Hide C++ object layout from Zig
2. **Create/destroy pairing**: Explicit resource management
3. **Exception catching**: All C++ exceptions caught at boundary
4. **Error codes**: Return status codes instead of throwing
5. **String conversion**: Convert std::string to C strings with explicit free functions

**String Conversion:**

C++ strings require special handling:

```cpp
extern "C" char* MyCppClass_getString(const MyCppClass_Opaque* obj) {
    try {
        std::string str = reinterpret_cast<const MyCppClass*>(obj)->getString();
        char* result = static_cast<char*>(malloc(str.length() + 1));
        if (result) {
            strcpy(result, str.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

extern "C" void MyCppClass_freeString(char* str) {
    free(str);
}
```

From Zig:

```zig
const str = c.MyCppClass_getString(obj);
if (str != null) {
    defer c.MyCppClass_freeString(str);
    std.debug.print("{s}\n", .{str});
}
```

**Build Configuration:**

Compile C++ bridge code with linkLibCpp:

```zig
exe.addCSourceFiles(.{
    .files = &.{
        "cpp/MyCppClass.cpp",
        "cpp/c_bridge.cpp",
    },
    .flags = &.{
        "-Wall",
        "-Wextra",
        "-std=c++17",
        "-fno-exceptions",  // Optional: disable exceptions
        "-fno-rtti",        // Optional: disable RTTI
    },
});

exe.addIncludePath(b.path("cpp"));
exe.linkLibC();
exe.linkLibCpp();  // Link C++ standard library
```

The `-fno-exceptions` flag prevents exception overhead if not using exceptions. The `-fno-rtti` flag disables runtime type information if not needed.

### WebAssembly Compilation and JavaScript FFI

Zig compiles to WebAssembly for browser and Node.js environments, enabling high-performance computation in JavaScript applications. WASM uses a linear memory model fundamentally different from native code.[^10]

**WASM Target Configuration:**

```zig
// build.zig
const target = b.resolveTargetQuery(.{
    .cpu_arch = .wasm32,
    .os_tag = .freestanding,
});

const lib = b.addExecutable(.{
    .name = "app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});

lib.entry = .disabled;  // No main() needed for library
lib.rdynamic = true;    // Export all public symbols
```

This produces a .wasm file that JavaScript can instantiate and call.

**Linear Memory Model:**

WebAssembly uses a single, contiguous linear memory:[^11]

- Memory is a flat array of bytes
- Pointers are 32-bit offsets (i32) into this array
- Memory can grow at runtime in 64KB pages
- No MMU or memory protection within WASM
- Multiple instances can share memory

**Key Implications:**

1. All pointers are u32 offsets, not native pointers
2. Memory growth may relocate the entire buffer (invalidating JavaScript views)
3. Bounds checking must be explicit
4. No segmentation faults—out-of-bounds access traps

**Exporting Functions to JavaScript:**

```zig
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn fibonacci(n: i32) i32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

export fn processArray(ptr: [*]i32, len: i32) i32 {
    var sum: i32 = 0;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        sum += ptr[i];
    }
    return sum;
}
```

JavaScript usage:

```javascript
const result = await WebAssembly.instantiateStreaming(fetch('app.wasm'));
const { add, fibonacci, processArray } = result.instance.exports;

console.log(add(5, 7));        // 12
console.log(fibonacci(10));    // 55

// Access WASM memory
const memory = result.instance.exports.memory;
const array = new Int32Array(memory.buffer, 0, 10);
array.set([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
console.log(processArray(0, 10));  // 55
```

**Importing JavaScript Functions:**

Declare JavaScript functions with extern:

```zig
extern "c" fn consoleLog(ptr: [*]const u8, len: usize) void;
extern "c" fn alert(ptr: [*]const u8, len: usize) void;

export fn greet(name_ptr: [*]const u8, name_len: usize) void {
    const greeting = "Hello, ";
    consoleLog(greeting.ptr, greeting.len);
    consoleLog(name_ptr, name_len);
}
```

Provide implementations in JavaScript:

```javascript
const decoder = new TextDecoder();

const importObject = {
    env: {
        consoleLog: (ptr, len) => {
            const bytes = new Uint8Array(memory.buffer, ptr, len);
            const str = decoder.decode(bytes);
            console.log(str);
        },
        alert: (ptr, len) => {
            const bytes = new Uint8Array(memory.buffer, ptr, len);
            const str = decoder.decode(bytes);
            window.alert(str);
        }
    }
};

const result = await WebAssembly.instantiate(wasmBytes, importObject);
```

**String Passing:**

Strings require encoding/decoding between JavaScript UTF-16 and WASM UTF-8:

**WASM → JavaScript:**

```zig
export fn getMessage() [*]const u8 {
    return "Hello from WASM".ptr;
}

export fn getMessageLength() usize {
    return "Hello from WASM".len;
}
```

```javascript
const ptr = instance.exports.getMessage();
const len = instance.exports.getMessageLength();
const bytes = new Uint8Array(memory.buffer, ptr, len);
const str = new TextDecoder().decode(bytes);
console.log(str);
```

**JavaScript → WASM:**

```javascript
function stringToWasm(str) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(str);

    // Allocate in WASM memory
    const ptr = instance.exports.allocate(bytes.length);

    const wasmBytes = new Uint8Array(memory.buffer, ptr, bytes.length);
    wasmBytes.set(bytes);

    return { ptr, len: bytes.length };
}

const { ptr, len } = stringToWasm("Hello from JS");
instance.exports.processString(ptr, len);
instance.exports.deallocate(ptr, len);
```

**Memory Management:**

Expose allocator functions:

```zig
const allocator = std.heap.wasm_allocator;

export fn allocate(size: usize) [*]u8 {
    const slice = allocator.alloc(u8, size) catch return undefined;
    return slice.ptr;
}

export fn deallocate(ptr: [*]u8, size: usize) void {
    const slice = ptr[0..size];
    allocator.free(slice);
}
```

**Memory Growth:**

WASM memory grows in 64KB pages:

```zig
export fn needMoreMemory() bool {
    const pages_before = @wasmMemorySize(0);
    const result = @wasmMemoryGrow(0, 10);  // Request 10 pages (640KB)

    if (result < 0) {
        return false;  // Growth failed
    }

    const pages_after = @wasmMemorySize(0);
    std.debug.print("Grew from {d} to {d} pages\n", .{
        pages_before, pages_after
    });

    return true;
}
```

**Critical Warning:** Memory growth changes the buffer address in JavaScript:

```javascript
let buffer = memory.buffer;
const oldView = new Uint8Array(buffer, 0, 100);

instance.exports.needMoreMemory();  // Memory grows

// oldView is now invalid! Must re-acquire:
const newView = new Uint8Array(memory.buffer, 0, 100);
```

Always re-acquire TypedArray views after memory growth.

### WASI: Capability-Based System Interface

WebAssembly System Interface (WASI) provides standardized APIs for filesystem, environment variables, and system interactions with a capability-based security model.[^12]

**WASI Target Configuration:**

```zig
const target = b.resolveTargetQuery(.{
    .cpu_arch = .wasm32,
    .os_tag = .wasi,
});
```

This enables POSIX-like APIs from Zig's standard library.

**Capability-Based Security:**

WASI requires explicit capability grants at runtime. Programs cannot access resources without permission:[^13]

```bash
# No filesystem access (will fail)
wasmtime program.wasm

# Grant read/write to current directory
wasmtime --dir=. program.wasm

# Grant access to specific directory
wasmtime --dir=/tmp program.wasm

# Multiple directories
wasmtime --dir=. --dir=/tmp program.wasm

# Different mount point
wasmtime --mapdir=/app::/path/to/app program.wasm

# Environment variables
wasmtime --env=MY_VAR=value program.wasm
```

Without `--dir=.`, any filesystem operation fails with PermissionDenied error.

**Filesystem Operations:**

Standard Zig filesystem APIs work in WASI:

```zig
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cwd = std.fs.cwd();

    // Create file
    const file = try cwd.createFile("output.txt", .{});
    defer file.close();

    try file.writeAll("Hello from WASI\n");

    // Read file
    try file.seekTo(0);
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(contents);

    std.debug.print("Contents: {s}\n", .{contents});

    // Directory operations
    try cwd.makeDir("test_dir");
    var dir = try cwd.openDir("test_dir", .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        std.debug.print("Found: {s}\n", .{entry.name});
    }
}
```

**Command-Line Arguments:**

```zig
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var i: usize = 0;
    while (args.next()) |arg| {
        std.debug.print("arg[{d}]: {s}\n", .{ i, arg });
        i += 1;
    }
}
```

Run with arguments:

```bash
wasmtime --dir=. program.wasm arg1 arg2 arg3
```

**Environment Variables:**

```zig
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    var iter = env_map.iterator();
    while (iter.next()) |entry| {
        std.debug.print("{s}={s}\n", .{
            entry.key_ptr.*,
            entry.value_ptr.*
        });
    }
}
```

Set environment variables:

```bash
wasmtime --dir=. --env=KEY=value --env=DEBUG=1 program.wasm
```

**WASI Versions:**

- **Preview 1 (snapshot_preview1)**: Current stable version
  - Filesystem, stdio, environment, clocks
  - Single-threaded
  - No networking

- **Preview 2 (in development)**: Future version
  - Component model
  - Network sockets
  - HTTP client/server
  - Better modularity

**Security Benefits:**

WASI's capability model prevents:

- Unauthorized filesystem access (no ambient authority)
- Unexpected network connections
- Time-of-check-time-of-use (TOCTOU) attacks
- Privilege escalation

Every capability must be explicitly granted when launching the WASM program. This provides defense-in-depth for running untrusted code.

## Code Examples

This section demonstrates practical interoperability patterns through six complete examples. Each example builds on concepts from Core Concepts, showing real-world usage patterns.

### Example 1: Basic C Interoperability

This example demonstrates fundamental @cImport usage and C type handling. It calls C standard library functions, manages C-allocated memory, and handles C strings correctly.

**Key Code Snippet:**

```zig
const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
});

pub fn main() !void {
    // Call C's printf
    _ = c.printf("Hello from C's printf!\n");

    // Work with C integers
    const value: c.c_int = 42;
    _ = c.printf("C int value: %d\n", value);

    // C string handling with null termination
    const c_string: [*:0]const u8 = "C-style string";
    const len = c.strlen(c_string);
    _ = c.printf("String length: %zu\n", len);

    // C memory allocation with defer cleanup
    const size: usize = 100;
    const ptr = c.malloc(size);
    if (ptr == null) return error.OutOfMemory;
    defer c.free(ptr);

    _ = c.memset(ptr, 0, size);
    _ = c.printf("Allocated and zeroed %zu bytes\n", size);
}
```

**Patterns Demonstrated:**

- @cImport with multiple headers (stdio.h, stdlib.h, string.h)
- Using c_int instead of i32 for platform compatibility
- Null-terminated string type ([*:0]const u8)
- C memory allocation with malloc/free
- defer for automatic cleanup
- Null checking before dereferencing C pointers

The complete example shows additional patterns including snprintf for safe string formatting and proper error handling. See `examples/01_basic_c_interop/` for full source code and README.

### Example 2: SQLite3 Library Integration

This example demonstrates integration with a real-world C library (SQLite3), showing how to link external libraries, handle C APIs with error codes, use prepared statements, and manage opaque pointer types.

**Key Code Snippet:**

```zig
const std = @import("std");

const c = @cImport({
    @cInclude("sqlite3.h");
});

pub fn main() !void {
    var db: ?*c.sqlite3 = null;
    defer _ = c.sqlite3_close(db);

    // Open in-memory database
    const rc = c.sqlite3_open(":memory:", &db);
    if (rc != c.SQLITE_OK) {
        std.debug.print("Cannot open database: {s}\n", .{c.sqlite3_errmsg(db)});
        return error.DatabaseError;
    }

    // Create table
    const create_sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)";
    var errmsg: [*c]u8 = null;
    defer c.sqlite3_free(errmsg);

    _ = c.sqlite3_exec(db, create_sql, null, null, &errmsg);

    // Insert data using prepared statement
    const insert_sql = "INSERT INTO users (name, age) VALUES (?, ?)";
    var stmt: ?*c.sqlite3_stmt = null;
    defer _ = c.sqlite3_finalize(stmt);

    _ = c.sqlite3_prepare_v2(db, insert_sql, -1, &stmt, null);
    _ = c.sqlite3_bind_text(stmt, 1, "Alice", -1, c.SQLITE_TRANSIENT);
    _ = c.sqlite3_bind_int(stmt, 2, 30);
    _ = c.sqlite3_step(stmt);

    std.debug.print("Inserted user successfully\n", .{});
}
```

**Patterns Demonstrated:**

- Linking external system library (sqlite3) via build.zig
- Opaque pointer types (?*c.sqlite3, ?*c.sqlite3_stmt)
- C error code checking (SQLITE_OK)
- Resource cleanup with defer (database handle, statement, error messages)
- Prepared statements for SQL injection prevention
- C string constants with correct lifetimes
- Binding parameters to prepared statements

The full example shows querying data, iterating results, and comprehensive error handling. Build configuration demonstrates linkSystemLibrary usage. See `examples/02_sqlite_interop/` for complete implementation.

### Example 3: Build System Integration

This example shows how to integrate C source files into a Zig build, configure include paths, set compiler flags, and create Zig wrapper modules around C functionality.

**Build Configuration (build.zig):**

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "build_integration",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Compile C source files
    exe.addCSourceFiles(.{
        .files = &.{
            "c_lib/mylib.c",
        },
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-std=c99",
        },
    });

    // Add include path for C headers
    exe.addIncludePath(b.path("c_lib"));
    exe.linkLibC();

    b.installArtifact(exe);
}
```

**Zig Wrapper (wrapper.zig):**

```zig
const std = @import("std");

const c = @cImport({
    @cInclude("mylib.h");
});

pub fn addNumbers(a: i32, b: i32) i32 {
    return c.add_numbers(a, b);
}

pub fn printMessage(message: []const u8) !void {
    const allocator = std.heap.c_allocator;
    const c_message = try allocator.dupeZ(u8, message);
    defer allocator.free(c_message);

    c.print_message(c_message);
}

pub fn calculateAverage(values: []const f64) f64 {
    return c.calculate_average(values.ptr, values.len);
}
```

**Patterns Demonstrated:**

- addCSourceFiles with compiler flags
- addIncludePath for custom headers
- Converting Zig slices to C pointers (.ptr and .len)
- String conversion with allocator.dupeZ for null termination
- Using std.heap.c_allocator for C-compatible allocation
- Creating Zig wrapper modules for type safety

This pattern enables organizing C code separately from Zig code while maintaining clean boundaries. See `examples/03_build_integration/` for project structure and complete code.

### Example 4: C++ Bridge Pattern

This example demonstrates safe C++ interoperability using an extern "C" bridge layer. It shows opaque pointers, exception handling at boundaries, and resource management across languages.

**C++ Class:**

```cpp
// MyCppClass.hpp
class MyCppClass {
public:
    MyCppClass(int value) : value_(value) {}
    int getValue() const { return value_; }
    void setValue(int value) { value_ = value; }
    void increment() { value_++; }
private:
    int value_;
};
```

**C Bridge (c_bridge.cpp):**

```cpp
#include "c_bridge.h"
#include "MyCppClass.hpp"

extern "C" {

MyCppClass_Opaque* MyCppClass_create(int value) {
    try {
        return reinterpret_cast<MyCppClass_Opaque*>(new MyCppClass(value));
    } catch (...) {
        return nullptr;
    }
}

void MyCppClass_destroy(MyCppClass_Opaque* obj) {
    delete reinterpret_cast<MyCppClass*>(obj);
}

int MyCppClass_getValue(const MyCppClass_Opaque* obj) {
    try {
        return reinterpret_cast<const MyCppClass*>(obj)->getValue();
    } catch (...) {
        return 0;
    }
}

void MyCppClass_increment(MyCppClass_Opaque* obj) {
    try {
        reinterpret_cast<MyCppClass*>(obj)->increment();
    } catch (...) {
        // Silently handle exception
    }
}

}  // extern "C"
```

**Zig Usage:**

```zig
const c = @cImport({
    @cInclude("c_bridge.h");
});

pub fn main() !void {
    const obj = c.MyCppClass_create(42) orelse return error.CreateFailed;
    defer c.MyCppClass_destroy(obj);

    const value = c.MyCppClass_getValue(obj);
    std.debug.print("Initial value: {d}\n", .{value});

    c.MyCppClass_increment(obj);
    std.debug.print("After increment: {d}\n", .{c.MyCppClass_getValue(obj)});
}
```

**Patterns Demonstrated:**

- Opaque pointer types hiding C++ objects
- extern "C" linkage preventing name mangling
- Exception catching at boundary (never let exceptions reach Zig)
- Explicit create/destroy pairing for resource management
- reinterpret_cast for opaque pointer conversion
- Error handling via return codes instead of exceptions

The complete example shows string conversion (std::string to C strings), container handling, and build configuration with linkLibCpp. See `examples/04_cpp_bridge/` for full implementation.

### Example 5: WebAssembly JavaScript FFI

This example demonstrates compiling Zig to WebAssembly, exporting functions to JavaScript, importing JavaScript host functions, and managing linear memory across the boundary.

**Zig WASM Module:**

```zig
const std = @import("std");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn fibonacci(n: i32) i32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

extern "c" fn consoleLog(ptr: [*]const u8, len: usize) void;

export fn greet(name_ptr: [*]const u8, name_len: usize) void {
    const greeting = "Hello, ";
    consoleLog(greeting.ptr, greeting.len);
    consoleLog(name_ptr, name_len);
}

const allocator = std.heap.wasm_allocator;

export fn allocate(size: usize) [*]u8 {
    const slice = allocator.alloc(u8, size) catch return undefined;
    return slice.ptr;
}

export fn deallocate(ptr: [*]u8, size: usize) void {
    const slice = ptr[0..size];
    allocator.free(slice);
}
```

**JavaScript Host:**

```javascript
const decoder = new TextDecoder();
const encoder = new TextEncoder();

const importObject = {
    env: {
        consoleLog: (ptr, len) => {
            const bytes = new Uint8Array(memory.buffer, ptr, len);
            const str = decoder.decode(bytes);
            console.log(str);
        }
    }
};

const result = await WebAssembly.instantiateStreaming(
    fetch('app.wasm'),
    importObject
);

const { add, fibonacci, greet, allocate, deallocate, memory } = result.instance.exports;

// Call exported functions
console.log(add(5, 7));           // 12
console.log(fibonacci(10));       // 55

// Pass string to WASM
const name = "World";
const nameBytes = encoder.encode(name);
const ptr = allocate(nameBytes.length);
const wasmView = new Uint8Array(memory.buffer, ptr, nameBytes.length);
wasmView.set(nameBytes);
greet(ptr, nameBytes.length);
deallocate(ptr, nameBytes.length);
```

**Patterns Demonstrated:**

- WASM target compilation (wasm32-freestanding)
- Exporting functions with export keyword
- Importing JavaScript functions with extern
- String passing using (pointer, length) pairs
- Memory allocation exposed to JavaScript
- TypedArray views for accessing WASM memory
- Text encoding/decoding between UTF-16 and UTF-8

The complete example includes an interactive HTML page demonstrating arithmetic, string operations, and memory management. See `examples/05_wasm_js_ffi/` for web files and build configuration.

### Example 6: WASI Filesystem Operations

This example demonstrates WASI compilation, filesystem operations with capability-based security, command-line arguments, and environment variables in a sandboxed WASM environment.

**WASI Program:**

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout_file = std.fs.File.stdout();
    var buf: [256]u8 = undefined;
    var stdout_writer = stdout_file.writer(&buf);
    const stdout = &stdout_writer.interface;

    // Command-line arguments
    try stdout.print("=== Command-line arguments ===\n", .{});
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var i: usize = 0;
    while (args.next()) |arg| {
        try stdout.print("arg[{d}]: {s}\n", .{ i, arg });
        i += 1;
    }

    // Environment variables
    try stdout.print("\n=== Environment variables ===\n", .{});
    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    var iter = env_map.iterator();
    while (iter.next()) |entry| {
        try stdout.print("{s}={s}\n", .{
            entry.key_ptr.*,
            entry.value_ptr.*
        });
    }

    // Filesystem operations (requires --dir capability)
    try stdout.print("\n=== Filesystem operations ===\n", .{});
    const cwd = std.fs.cwd();

    // Create file
    const file = try cwd.createFile("wasi_test.txt", .{});
    defer file.close();

    try file.writeAll("Hello from WASI!\n");
    try stdout.print("Created file: wasi_test.txt\n", .{});

    // Read file
    try file.seekTo(0);
    const contents = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(contents);

    try stdout.print("Contents: {s}\n", .{contents});

    // Create directory
    try cwd.makeDir("wasi_dir");
    try stdout.print("Created directory: wasi_dir\n", .{});
    try stdout.flush();
}
```

**Running with Capabilities:**

```bash
# Build WASI target
zig build

# Run with directory access granted
wasmtime --dir=. ./zig-out/bin/wasi_filesystem.wasm

# Run with arguments and environment variables
wasmtime --dir=. --env=DEBUG=1 ./zig-out/bin/wasi_filesystem.wasm arg1 arg2
```

**Patterns Demonstrated:**

- WASI target compilation (wasm32-wasi)
- Capability-based security (--dir grants filesystem access)
- Standard filesystem APIs (std.fs.cwd, createFile, makeDir)
- Command-line argument parsing
- Environment variable access
- Standard I/O in WASI (stdout, stderr, stdin)

Without `--dir=.`, filesystem operations fail with PermissionDenied errors, demonstrating WASI's security model. The complete example shows directory iteration, file metadata, and cleanup. See `examples/06_wasi_filesystem/` for full source and detailed README.

## Common Pitfalls

This section documents frequent interoperability errors, their consequences, and solutions. Each pitfall includes incorrect and correct code examples.

### Memory Management Pitfalls

**Pitfall 1: Forgetting to Free C Allocations**

C's manual memory management requires explicit free calls. Forgetting to free causes memory leaks.

❌ **Incorrect:**
```zig
const ptr = c.malloc(1024);
if (ptr == null) return error.OutOfMemory;
doSomething(ptr);
// Memory leak - forgot to free!
```

✅ **Correct:**
```zig
const ptr = c.malloc(1024);
if (ptr == null) return error.OutOfMemory;
defer c.free(ptr);
doSomething(ptr);
// ptr freed when scope exits
```

**Detection:** Use Valgrind or AddressSanitizer to detect leaks:
```bash
zig build -Dsanitize=address
valgrind --leak-check=full ./program
```

**Pitfall 2: Double Free**

Freeing memory twice causes undefined behavior, often crashing immediately or corrupting the allocator.

❌ **Incorrect:**
```zig
const ptr = c.malloc(100);
defer c.free(ptr);
processData(ptr);
c.free(ptr);  // Double free!
```

✅ **Correct:**
```zig
const ptr = c.malloc(100);
defer c.free(ptr);
processData(ptr);
// Only freed once by defer
```

**Detection:** AddressSanitizer detects double frees:
```bash
zig build -Dsanitize=address
./program  # Will report double-free error
```

**Pitfall 3: Use-After-Free**

Accessing memory after freeing it causes undefined behavior.

❌ **Incorrect:**
```zig
const ptr = c.malloc(100);
if (ptr == null) return error.OutOfMemory;
c.free(ptr);
useData(ptr);  // Use-after-free!
```

✅ **Correct:**
```zig
const ptr = c.malloc(100);
if (ptr == null) return error.OutOfMemory;
defer c.free(ptr);
useData(ptr);
// Free happens after use
```

**Detection:** AddressSanitizer catches use-after-free:
```bash
zig build -Dsanitize=address
```

**Pitfall 4: Mixing Allocators**

Using different allocators for allocation and deallocation corrupts memory.

❌ **Incorrect:**
```zig
const allocator = std.heap.page_allocator;
const ptr = try allocator.alloc(u8, 100);
c.free(@ptrCast(ptr.ptr));  // Wrong allocator!
```

✅ **Correct (Option 1 - C allocator):**
```zig
const ptr = c.malloc(100);
if (ptr == null) return error.OutOfMemory;
defer c.free(ptr);
```

✅ **Correct (Option 2 - Zig allocator):**
```zig
const allocator = std.heap.c_allocator;  // C-compatible allocator
const ptr = try allocator.alloc(u8, 100);
defer allocator.free(ptr);
```

**Detection:** Crashes or corruption, difficult to detect. Use consistent allocator throughout.

### String Handling Pitfalls

**Pitfall 5: Missing Null Termination**

C expects null-terminated strings. Passing non-terminated strings causes buffer overruns.

❌ **Incorrect:**
```zig
const zig_str = "Hello";
_ = c.printf(zig_str.ptr);  // Undefined behavior - not null-terminated!
```

✅ **Correct:**
```zig
const c_str: [*:0]const u8 = "Hello";
_ = c.printf(c_str);
```

**Detection:** AddressSanitizer may catch buffer overruns, but not always. Use correct types.

**Pitfall 6: String Lifetime Issues**

Returning pointers to stack-allocated strings creates dangling pointers.

❌ **Incorrect:**
```zig
fn getBadString() [*:0]const u8 {
    var buffer: [100]u8 = undefined;
    _ = c.snprintf(@ptrCast(&buffer), 100, "temp %d", 42);
    return @ptrCast(&buffer);  // Dangling pointer!
}
```

✅ **Correct (Option 1 - Static string):**
```zig
fn getGoodString() [*:0]const u8 {
    return "constant string";  // Static lifetime
}
```

✅ **Correct (Option 2 - Heap allocation):**
```zig
fn getAllocatedString(allocator: std.mem.Allocator) ![*:0]u8 {
    return try std.fmt.allocPrintZ(allocator, "temp {d}", .{42});
}
```

**Detection:** Stack protection may catch, but often causes silent corruption.

**Pitfall 7: Buffer Overflow**

Using unsafe C functions like sprintf without bounds checking.

❌ **Incorrect:**
```zig
var buf: [10]u8 = undefined;
_ = c.sprintf(@ptrCast(&buf), "Very long string %d", 12345);
// Buffer overflow!
```

✅ **Correct (Option 1 - snprintf):**
```zig
var buf: [100]u8 = undefined;
_ = c.snprintf(@ptrCast(&buf), buf.len, "Very long string %d", 12345);
```

✅ **Correct (Option 2 - Zig's std.fmt):**
```zig
var buf: [100]u8 = undefined;
const result = try std.fmt.bufPrint(&buf, "Very long string {d}", .{12345});
```

**Detection:** AddressSanitizer or manual code review.

### Type Mismatch Pitfalls

**Pitfall 8: Using Fixed-Size Types for Platform Types**

Using i32 instead of c_int breaks on platforms where int is not 32-bit.

❌ **Incorrect:**
```zig
extern fn process_value(x: i32) void;  // Assumes int is 32-bit
```

✅ **Correct:**
```zig
extern fn process_value(x: c_int) void;  // Platform-adaptive
```

**Detection:** Only manifests on non-standard platforms. Use correct types from start.

**Pitfall 9: Pointer Type Confusion**

Using wrong pointer type for C APIs.

❌ **Incorrect:**
```zig
extern fn c_function(ptr: [*]u8) void;  // Non-nullable
const ptr: ?[*]u8 = c.malloc(100);
c_function(ptr);  // Type error
```

✅ **Correct:**
```zig
extern fn c_function(ptr: [*c]u8) void;  // C pointer (nullable)
const ptr = c.malloc(100);
if (ptr == null) return error.OutOfMemory;
c_function(ptr);
```

**Detection:** Compile error (type mismatch).

**Pitfall 10: Struct Layout Mismatch**

Omitting extern keyword allows field reordering.

❌ **Incorrect:**
```zig
const Point = struct {  // Zig may reorder
    x: f32,
    y: f32,
};
```

✅ **Correct:**
```zig
const Point = extern struct {  // C-compatible layout
    x: f32,
    y: f32,
};
```

**Detection:** Silent corruption or crashes. Always use extern struct for C interop.

### Build Configuration Pitfalls

**Pitfall 11: Forgetting linkLibC**

C code requires linking the C standard library.

❌ **Incorrect:**
```zig
exe.addCSourceFiles(.{ .files = &.{"lib.c"} });
// Link error - undefined references
```

✅ **Correct:**
```zig
exe.addCSourceFiles(.{ .files = &.{"lib.c"} });
exe.linkLibC();
```

**Detection:** Link-time errors for C standard library symbols.

**Pitfall 12: Missing Include Paths**

@cImport fails without proper include paths.

❌ **Incorrect:**
```zig
// build.zig missing addIncludePath
const c = @cImport({
    @cInclude("myheader.h");  // Error: file not found
});
```

✅ **Correct:**
```zig
// build.zig
exe.addIncludePath(b.path("c_headers"));
exe.linkLibC();

// main.zig
const c = @cImport({
    @cInclude("myheader.h");  // Found
});
```

**Detection:** Compile-time error from @cImport.

**Pitfall 13: Missing System Library**

Forgetting to link required system libraries.

❌ **Incorrect:**
```zig
exe.linkLibC();
// Undefined references to pthread_create, etc.
```

✅ **Correct:**
```zig
exe.linkLibC();
exe.linkSystemLibrary("pthread");
exe.linkSystemLibrary("m");  // Math library on Unix
```

**Detection:** Link-time undefined reference errors.

### WASM-Specific Pitfalls

**Pitfall 14: Pointer Invalidation on Memory Growth**

Growing WASM memory invalidates JavaScript TypedArray views.

❌ **Incorrect:**
```javascript
const view = new Uint8Array(memory.buffer, 0, 100);
instance.exports.needMoreMemory();  // Grows memory
view[0] = 42;  // Using invalidated view!
```

✅ **Correct:**
```javascript
let view = new Uint8Array(memory.buffer, 0, 100);
instance.exports.needMoreMemory();  // Grows memory
view = new Uint8Array(memory.buffer, 0, 100);  // Re-acquire view
view[0] = 42;
```

**Detection:** Silent data corruption or exceptions. Always re-acquire after growth.

**Pitfall 15: Incorrect String Encoding**

Assuming ASCII instead of proper UTF-8 handling.

❌ **Incorrect:**
```javascript
// Binary data as string
const bytes = [0xFF, 0xFE, 0xFD];
const str = String.fromCharCode(...bytes);  // Invalid UTF-8
```

✅ **Correct:**
```javascript
const bytes = new Uint8Array([0xFF, 0xFE, 0xFD]);
const decoder = new TextDecoder('utf-8', { fatal: true });
try {
    const str = decoder.decode(bytes);
} catch {
    console.error('Invalid UTF-8');
}
```

**Detection:** TextDecoder with fatal mode throws on invalid UTF-8.

**Pitfall 16: Exceeding WASM Memory Limits**

WASM has maximum memory size (typically 2GB or 4GB).

❌ **Incorrect:**
```zig
const huge = allocator.alloc(u8, 5_000_000_000) catch unreachable;
// OutOfMemory or trap
```

✅ **Correct:**
```zig
const max_size = 1_000_000_000;  // 1GB limit
if (size > max_size) return error.TooLarge;

const result = allocator.alloc(u8, size) catch return error.OutOfMemory;
```

**Detection:** OutOfMemory error or WASM trap. Set realistic size limits.

## In Practice

This section examines production patterns from real-world Zig projects, demonstrating how interoperability works at scale.

### Ghostty: Platform Abstraction Patterns

Ghostty, a GPU-accelerated terminal emulator, demonstrates clean platform-specific C interop.[^14]

**Conditional Platform Headers:**

```zig
// ghostty/src/os/passwd.zig
const builtin = @import("builtin");

const c = if (builtin.os.tag != .windows) @cImport({
    @cInclude("sys/types.h");
    @cInclude("unistd.h");
    @cInclude("pwd.h");
}) else {};

comptime {
    if (builtin.target.cpu.arch.isWasm()) {
        @compileError("passwd is not available for wasm");
    }
}

pub fn get(alloc: std.mem.Allocator) !Entry {
    if (builtin.os.tag == .windows)
        @compileError("passwd is not available on windows");

    var buf: [1024]u8 = undefined;
    var pw: c.struct_passwd = undefined;
    var pw_ptr: ?*c.struct_passwd = null;

    const res = c.getpwuid_r(c.getuid(), &pw, &buf, buf.len, &pw_ptr);
    if (res != 0) {
        log.warn("error retrieving pw entry code={d}", .{res});
        return Entry{};
    }
    // Convert C strings to Zig strings...
}
```

**Key Patterns:**
- Compile-time platform detection (`builtin.os.tag`)
- Conditional @cImport for platform-specific headers
- @compileError for unsupported platforms
- Logging warnings for runtime errors
- Safe fallback values
- Static buffer allocation for C functions

**HarfBuzz Integration:**

```zig
// ghostty/pkg/harfbuzz/c.zig
pub const c = @cImport({
    @cInclude("hb.h");
    if (build_options.freetype) @cInclude("hb-ft.h");
    if (build_options.coretext) @cInclude("hb-coretext.h");
});
```

This pattern enables optional dependencies based on build configuration, avoiding compilation errors when optional features are disabled.

### TigerBeetle: C Client API Generation

TigerBeetle, a distributed financial database, generates a professional C API from Zig code.[^15]

**Opaque Type with Size Verification:**

```zig
// tigerbeetle/src/clients/c/tb_client_exports.zig
pub const tb_client_t = extern struct {
    @"opaque": [4]u64,

    pub inline fn cast(self: *tb_client_t) *tb.ClientInterface {
        return @ptrCast(self);
    }

    comptime {
        assert(@sizeOf(tb_client_t) == @sizeOf(tb.ClientInterface));
        assert(@bitSizeOf(tb_client_t) == @bitSizeOf(tb.ClientInterface));
        assert(@alignOf(tb_client_t) == @alignOf(tb.ClientInterface));
    }
};
```

**Error Code Enumeration:**

```zig
pub const tb_init_status = enum(c_int) {
    success = 0,
    unexpected,
    out_of_memory,
    address_invalid,
    address_limit_exceeded,
    system_resources,
    network_subsystem,
};

pub fn init_error_to_status(err: tb.InitError) tb_init_status {
    return switch (err) {
        error.Unexpected => .unexpected,
        error.OutOfMemory => .out_of_memory,
        error.AddressInvalid => .address_invalid,
        error.AddressLimitExceeded => .address_limit_exceeded,
        error.SystemResources => .system_resources,
        error.NetworkSubsystemFailed => .network_subsystem,
    };
}
```

**C-Compatible Initialization:**

```zig
pub fn init(
    tb_client_out: *tb_client_t,
    cluster_id_ptr: *const [16]u8,
    addresses_ptr: [*:0]const u8,
    addresses_len: u32,
    completion_ctx: usize,
    completion_callback: tb_completion_t,
) callconv(.c) tb_init_status {
    const addresses = @as([*]const u8, @ptrCast(addresses_ptr))[0..addresses_len];

    const client = tb_client_out.cast();
    client.init(
        cluster_id_ptr.*,
        addresses,
        @ptrFromInt(completion_ctx),
        completion_callback,
    ) catch |err| {
        return init_error_to_status(err);
    };

    return .success;
}
```

**Key Patterns:**
- Opaque types matching Zig implementation size
- Compile-time size/alignment verification
- C-compatible error enums (backed by c_int)
- Error conversion from Zig errors to C codes
- Explicit .c calling convention
- Slice reconstruction from pointer-length pairs

### zig-gamedev: Advanced C++ Library Integration

zig-gamedev demonstrates sophisticated patterns for integrating complex C++ libraries (ImGui, PhysX, WebGPU) with type-safe Zig APIs.[^16]

**C++ Library Wrapping Pattern:**

```zig
// zig-gamedev/libs/zgui/build.zig
const zgui = b.addStaticLibrary(.{
    .name = "zgui",
    .target = target,
    .optimize = optimize,
});

zgui.addCSourceFiles(&.{
    "libs/imgui/imgui.cpp",
    "libs/imgui/imgui_draw.cpp",
    "libs/imgui/imgui_widgets.cpp",
    "libs/imgui/imgui_tables.cpp",
    "libs/imgui/imgui_demo.cpp",
    "src/imgui_impl.cpp",  // Zig-friendly adapter layer
}, &.{"-std=c++17", "-fno-exceptions", "-fno-rtti"});

zgui.linkLibCpp();  // Required for C++ standard library
```

**Type-Safe Zig API Over C++:**

```zig
// Type-safe wrapper for ImGui C++ API
pub fn begin(name: [:0]const u8, flags: WindowFlags) bool {
    return c.zgui_Begin(name.ptr, null, @intFromEnum(flags));
}

pub fn button(label: [:0]const u8, size: [2]f32) bool {
    return c.zgui_Button(label.ptr, size[0], size[1]);
}

pub fn text(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const text_slice = std.fmt.bufPrintZ(&buf, fmt, args) catch &buf;
    c.zgui_Text(text_slice.ptr);
}
```

**Key Patterns:**

1. **Adapter Layer Pattern:**
   - C++ libraries wrapped in extern "C" adapter functions
   - Zig code calls C-ABI functions, not C++ directly
   - Avoids name mangling and exception handling complexity

2. **Memory Ownership at FFI Boundary:**
   - Allocators passed through to C++ when possible
   - Clear documentation of which side owns memory
   - RAII objects wrapped with explicit `init()`/`deinit()` pairs

3. **Platform-Specific Graphics API Integration:**
```zig
pub fn link(compile: *std.Build.Step.Compile) void {
    switch (compile.target.result.os.tag) {
        .windows => {
            compile.linkSystemLibrary("d3d12");
            compile.linkSystemLibrary("dxgi");
        },
        .macos => {
            compile.linkFramework("Metal");
            compile.linkFramework("MetalKit");
            compile.linkFramework("QuartzCore");
        },
        .linux => {
            compile.linkSystemLibrary("vulkan");
            compile.linkSystemLibrary("X11");
        },
        else => @panic("Unsupported platform"),
    }
}
```

4. **Multi-Library Dependency Management:**
   - Central `Package` struct exports all library modules
   - Shared compilation flags across all C/C++ code
   - Consistent allocator threading through FFI boundaries

**Testing C++ Interop:**

```zig
test "ImGui context lifecycle" {
    const ctx = c.zgui_CreateContext(null);
    defer c.zgui_DestroyContext(ctx);

    try testing.expect(ctx != null);
    try testing.expect(c.zgui_GetCurrentContext() == ctx);
}
```

This pattern enables Zig projects to leverage mature C++ game development libraries (ImGui, PhysX, Dear ImPlot) while maintaining Zig's safety guarantees and explicit allocator model.

> **See also:** Chapter 9 (Build System) for zig-gamedev's build organization and multi-library dependency management.

### Memory Safety with defer and errdefer

Production code uses defer consistently for cleanup:

```zig
fn processResource() !void {
    const resource = try allocateResource();
    defer deallocateResource(resource);
    errdefer logErrorState(resource);

    try resource.initialize();
    errdefer resource.deinitialize();

    try resource.processData();
    // Cleanup happens in reverse order
}
```

This RAII-like pattern ensures cleanup even when errors occur. The errdefer ensures error-specific cleanup executes only on failure paths.

### Cross-Platform Build Organization

Production projects organize C sources by platform:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    var c_sources = std.ArrayList([]const u8).init(b.allocator);
    defer c_sources.deinit();

    // Common cross-platform code
    c_sources.append("src/common.c") catch unreachable;

    // Platform-specific sources
    switch (target.result.os.tag) {
        .windows => {
            c_sources.append("src/platform/windows.c") catch unreachable;
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("gdi32");
        },
        .macos, .ios => {
            c_sources.append("src/platform/darwin.c") catch unreachable;
            exe.linkFramework("Cocoa");
            exe.linkFramework("Metal");
        },
        .linux => {
            c_sources.append("src/platform/linux.c") catch unreachable;
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("pthread");
        },
        else => {
            c_sources.append("src/platform/fallback.c") catch unreachable;
        },
    }

    exe.addCSourceFiles(.{
        .files = c_sources.items,
        .flags = common_flags,
    });
}
```

### Testing FFI Code

Testing C interop requires validating both success and failure paths:

```zig
test "C allocation and deallocation" {
    const ptr = c.malloc(1024);
    try testing.expect(ptr != null);
    defer c.free(ptr);

    const bytes = @as([*]u8, @ptrCast(ptr));
    bytes[0] = 42;
    try testing.expectEqual(@as(u8, 42), bytes[0]);
}

test "C function error handling" {
    const result = c.risky_function();
    if (result < 0) {
        // Expected error path
        try testing.expect(result == c.ERROR_CODE);
    }
}
```

### Performance Considerations

FFI calls have overhead from crossing language boundaries:

1. **Inline small wrappers**: Simple C calls can be inlined
2. **Batch operations**: Minimize boundary crossings
3. **Direct memory access**: Share memory when possible
4. **Avoid string conversions**: Use binary protocols where feasible

Example of batching:

```zig
// ❌ Inefficient: Multiple C calls
for (items) |item| {
    c.process_item(&item);
}

// ✅ Efficient: Single batched call
c.process_items(items.ptr, items.len);
```

## Summary

Zig's interoperability capabilities enable seamless integration with existing C ecosystems while maintaining safety and performance. This chapter covered fundamental mechanisms (@cImport, extern, export), type mapping rules, build system integration, C++ bridging patterns, and WebAssembly targets.

**Core Mental Models:**

1. **C as a First-Class Citizen**: Zig treats C interop as a primary feature, not an afterthought. @cImport directly translates C headers using Clang, eliminating manual binding generation.

2. **Type Safety at Boundaries**: Use C-compatible types (c_int, c_long) for platform ABIs, not fixed-size types unless C uses them. This prevents subtle cross-platform bugs.

3. **Explicit Resource Management**: defer provides scope-based cleanup for C resources. Always pair allocation with deallocation using defer or errdefer.

4. **Language Boundaries Are Security Boundaries**: When C++ exceptions, JavaScript errors, or WASI capabilities cross boundaries, handle them explicitly. Never let exceptions propagate through C APIs.

5. **Linear Memory in WASM**: WebAssembly pointers are 32-bit offsets into linear memory. Memory growth invalidates pointers, requiring careful management.

6. **Capability-Based Security**: WASI requires explicit permission grants for all system access. This provides defense-in-depth for untrusted code execution.

**When to Use What:**

| Use Case | Approach | Key Considerations |
|----------|----------|-------------------|
| Call C library | @cImport + extern | Use c_int types, check return codes |
| Expose Zig to C | export functions | C calling convention, C-compatible types |
| Integrate C++ library | extern "C" bridge | Opaque pointers, catch all exceptions |
| Browser/Node.js | WASM (freestanding) | Linear memory, string encoding |
| Sandboxed execution | WASI | Capability grants required |
| Cross-platform APIs | Conditional compilation | Platform detection, fallback implementations |

**Best Practices Recap:**

1. Always use C types (c_int) for C APIs unless fixed-size
2. Link libc when using C code (exe.linkLibC())
3. Validate string null-termination ([*:0]u8)
4. Check C function return values for errors
5. Use extern struct for C struct compatibility
6. Catch C++ exceptions at bridge boundary
7. Grant WASI capabilities explicitly
8. Validate WASM memory bounds
9. Re-acquire views after WASM memory growth
10. Test on all target platforms

**Common Mistakes to Avoid:**

- Using i32 instead of c_int for C function parameters
- Forgetting defer for C-allocated resources
- Letting C++ exceptions cross into Zig
- Assuming strings are null-terminated without :0 annotation
- Missing linkLibC() when compiling C code
- Using Zig struct instead of extern struct for C interop
- Not checking malloc return values for null
- Mixing Zig and C allocators
- Using invalidated WASM TypedArray views after memory growth

**Production Patterns:**

Real-world projects demonstrate these principles at scale:

- **Ghostty**: Platform abstraction with conditional @cImport
- **TigerBeetle**: Professional C API generation with opaque types
- **Bun**: Complex JavaScript runtime integration
- **Zig stdlib**: Comprehensive platform-specific type definitions

These projects show that Zig's interoperability enables gradual migration from C, integration with platform APIs, and safe exposure of Zig functionality to other languages.

The zero-overhead nature of Zig's FFI—combined with compile-time safety checks, explicit resource management, and cross-platform type compatibility—makes it an ideal choice for systems programming requiring C integration. Whether wrapping C libraries, creating C APIs, or compiling to WebAssembly, Zig provides the tools needed for safe, performant interoperability.

## References

1. [Zig Language Reference 0.15.2 - @cImport](https://ziglang.org/documentation/0.15.2/#cImport)
2. [Zig Language Reference 0.15.2 - Build System](https://ziglang.org/documentation/0.15.2/#Build-System)
3. [Ghostty harfbuzz C imports](https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/pkg/harfbuzz/c.zig)
4. [Zig Language Reference 0.15.2 - extern and export](https://ziglang.org/documentation/0.15.2/#extern)
5. [Zig stdlib std/c.zig weak linkage](https://github.com/ziglang/zig/blob/0.15.2/lib/std/c.zig#L41-L47)
6. [Zig Language Reference 0.15.2 - C Type Primitives](https://ziglang.org/documentation/0.15.2/#C-Type-Primitives)
7. [Zig stdlib std/c.zig type definitions](https://github.com/ziglang/zig/blob/0.15.2/lib/std/c.zig#L74-L141)
8. [Ghostty build.zig](https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/build.zig)
9. [Bun GitHub Repository](https://github.com/oven-sh/bun)
10. [Zig Language Reference 0.15.2 - WebAssembly](https://ziglang.org/documentation/0.15.2/#WebAssembly)
11. [MDN WebAssembly Memory](https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/Memory)
12. [WASI Specification](https://github.com/WebAssembly/WASI)
13. [Zig stdlib std/os/wasi.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/os/wasi.zig)
14. [Ghostty passwd.zig](https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/src/os/passwd.zig)
15. [TigerBeetle C client exports](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/src/clients/c/tb_client_exports.zig)
16. [TigerBeetle tb_client_exports.zig opaque types](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/src/clients/c/tb_client_exports.zig#L10-L22)
17. [Zig stdlib std/c.zig platform types](https://github.com/ziglang/zig/blob/0.15.2/lib/std/c.zig#L74-L234)
18. [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)
19. [Zig Standard Library Reference](https://ziglang.org/documentation/0.15.2/std)
20. [Zig Build System Guide](https://zig.guide/build-system/)
21. [WebAssembly Specification](https://webassembly.github.io/spec/)
22. [Wasmtime Documentation](https://docs.wasmtime.dev/)
23. [WASI Tutorial](https://github.com/bytecodealliance/wasmtime/blob/1fcd0933144436a959b261abf4d9234d42db29e4/docs/WASI-tutorial.md)
24. [C ABI Compatibility - Itanium C++ ABI](https://itanium-cxx-abi.github.io/cxx-abi/)
25. [SQLite C API](https://www.sqlite.org/c3ref/intro.html)
26. [Zig stdlib std/fs](https://ziglang.org/documentation/0.15.2/std/#std.fs)
27. [Mach GitHub Repository](https://github.com/hexops/mach)
28. [Zig by Example](https://zig-by-example.com)
29. [MDN TextEncoder Documentation](https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder)
30. [MDN TextDecoder Documentation](https://developer.mozilla.org/en-US/docs/Web/API/TextDecoder)
31. [MDN TypedArray Documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray)
32. [Zig Language Reference 0.15.2 - WASI](https://ziglang.org/documentation/0.15.2/#WASI)

[^1]: https://ziglang.org/documentation/0.15.2/#cImport
[^2]: https://ziglang.org/documentation/0.15.2/#Build-System
[^3]: https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/pkg/harfbuzz/c.zig
[^4]: https://ziglang.org/documentation/0.15.2/#extern
[^5]: https://github.com/ziglang/zig/blob/0.15.2/lib/std/c.zig#L41-L47
[^6]: https://ziglang.org/documentation/0.15.2/#C-Type-Primitives
[^7]: https://github.com/ziglang/zig/blob/0.15.2/lib/std/c.zig#L74-L141
[^8]: https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/build.zig
[^9]: https://github.com/oven-sh/bun
[^10]: https://ziglang.org/documentation/0.15.2/#WebAssembly
[^11]: https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/Memory
[^12]: https://github.com/WebAssembly/WASI
[^13]: https://github.com/ziglang/zig/blob/0.15.2/lib/std/os/wasi.zig
[^14]: https://github.com/ghostty-org/ghostty/blob/05b580911577ae86e7a29146fac29fb368eab536/src/os/passwd.zig
[^15]: https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b1cbb2dc7342ac485707f2c4e0c702523/src/clients/c/tb_client_exports.zig
[^16]: https://github.com/michal-z/zig-gamedev - C++ library integration patterns (ImGui, PhysX, WebGPU)
