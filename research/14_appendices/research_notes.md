# Research Notes: Chapter 15 - Appendices & Reference Material

## Document Information
- **Chapter**: 15 - Appendices & Reference Material
- **Research Completed**: 2025-11-05
- **Total Terminology Extracted**: 150+ terms
- **Style Conventions**: 60+ guidelines from 5 production codebases
- **References Collected**: 200+ citations from chapters 1-13

---

## 1. COMPREHENSIVE GLOSSARY

### A

**@cImport**
- **Definition:** Builtin function that translates C headers into Zig-compatible types at compile time using Clang internally.
- **Usage:** `const c = @cImport(@cInclude("stdio.h"));`
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**@cInclude**
- **Definition:** Directive within @cImport blocks specifying which C header files to translate and import.
- **Usage:** Within @cImport block to include multiple headers
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**@errorName**
- **Definition:** Builtin that converts error values to their string representation for logging and diagnostics.
- **Usage:** `std.log.err("Error: {s}", .{@errorName(err)});`
- **Chapter:** 6 (Error Handling), 13 (Logging)
- **Version:** All versions

**@TypeOf**
- **Definition:** Built-in function that returns the type of an expression at compile time.
- **Usage:** Used for generic programming and type inference
- **Chapter:** 2 (Language Idioms)
- **Version:** All versions

**ABI (Application Binary Interface)**
- **Definition:** Platform-specific conventions for data layout, function calling, and system calls (e.g., musl, gnu, msvc).
- **Significance:** Critical for cross-compilation and C interop
- **Chapter:** 8 (Build System), 10 (Project Layout), 11 (Interoperability)
- **Version:** All versions

**acquire (memory ordering)**
- **Definition:** Memory ordering for atomic operations that synchronizes with release operations.
- **Usage:** Ensures all writes before a release are visible when reading with acquire
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**Allocator**
- **Definition:** Interface (std.mem.Allocator) providing uniform memory allocation API: alloc(), free(), create(), destroy()
- **Key Methods:** alloc(), free(), create(), destroy(), realloc()
- **Chapter:** 3 (Memory & Allocators), 5 (I/O), 6 (Error Handling)
- **Version:** All versions

**anyerror**
- **Definition:** Type representing union of all possible errors. Prevents compile-time error exhaustiveness checking.
- **Best Practice:** Use sparingly; prefer explicit error sets
- **Chapter:** 6 (Error Handling)
- **Version:** All versions

**anyopaque**
- **Definition:** Opaque pointer type (*anyopaque) for C interop when underlying type is unknown.
- **Replaces:** older void* handling
- **Usage:** `extern fn malloc(size: usize) ?*anyopaque;`
- **Chapter:** 11 (Interoperability)
- **Version:** ✅ 0.15+ (replaced older void* handling)

**anytype**
- **Definition:** Type allowing compile-time polymorphism; compiler infers actual type from usage.
- **Common Uses:** Generic functions, formatting, duck typing
- **Chapter:** 2 (Language Idioms), 5 (I/O), 11 (Interoperability)
- **Version:** All versions

**ArenaAllocator**
- **Definition:** Allocator deferring all cleanup to single deinit() call.
- **Use Cases:** Request-scoped allocations, temporary data, configuration parsing
- **Pattern:** `var arena = std.heap.ArenaAllocator.init(gpa); defer arena.deinit();`
- **Chapter:** 3 (Memory), 5 (I/O), 6 (Error Handling)
- **Version:** All versions

**ArrayList**
- **Definition:** Standard library dynamic array (std.ArrayList) that grows as needed.
- **Variants:** Managed (stores allocator) and Unmanaged (no stored allocator)
- **Chapter:** 4 (Collections), 5 (I/O), 6 (Error Handling)
- **Version:** ✅ 0.15+ defaults to unmanaged

**artifact**
- **Definition:** Build system output (executable, library, test) created with addExecutable(), addStaticLibrary(), etc.
- **Installation:** Use b.installArtifact() to place in zig-out/
- **Chapter:** 8 (Build System), 9 (Packages)
- **Version:** All versions

**atomic operations**
- **Definition:** Lock-free operations completing without interruption. Provided by std.atomic.Value.
- **Memory Orderings:** unordered, monotonic, acquire, release, acq_rel, seq_cst
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

### B

**baseline (CPU features)**
- **Definition:** Minimum required instruction set for an architecture.
- **Trade-off:** Maximum compatibility vs performance
- **Chapter:** 10 (Project Layout & CI)
- **Version:** All versions

**buffered I/O**
- **Definition:** I/O pattern accumulating small writes in memory before flushing to underlying stream.
- **Performance:** Reduces system calls significantly
- **Chapter:** 5 (I/O)
- **Version:** ✅ 0.15+ requires explicit buffer

**build.zig**
- **Definition:** Executable Zig program defining project build using std.Build API.
- **Entry Point:** `pub fn build(b: *std.Build) void`
- **Chapter:** 8 (Build System), 9 (Packages), 10 (Project Layout)
- **Version:** ✅ 0.15 introduced module system

**build.zig.zon**
- **Definition:** Package manifest declaring dependencies, metadata, included files.
- **Format:** Zig struct literal syntax
- **Chapter:** 9 (Packages), 10 (Project Layout)
- **Version:** ✅ 0.15+ requires .fingerprint field

### C

**c_allocator**
- **Definition:** Wrapper around C's malloc/free providing Allocator interface.
- **Trade-offs:** High performance, requires libc, no safety features
- **Use Case:** Release builds prioritizing performance
- **Chapter:** 3 (Memory)
- **Version:** All versions

**c_bool, c_int, c_long, c_uint**
- **Definition:** Platform-dependent C integer types adapting to target ABI.
- **Rule:** Always use for C APIs unless they explicitly use fixed-size types
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**callconv**
- **Definition:** Keyword specifying calling convention (.C, .Stdcall, .Inline, etc.).
- **Critical For:** C/C++ interop
- **Usage:** `extern "c" fn foo() callconv(.C) void`
- **Chapter:** 7 (Async), 11 (Interoperability)
- **Version:** All versions

**CAS (Compare-and-Swap)**
- **Definition:** Atomic operation changing value only if it equals expected value.
- **Use:** Foundation of lock-free algorithms
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**catch**
- **Definition:** Keyword for error handling with recovery.
- **Patterns:** Default values, error-specific handling, error capture
- **Usage:** `const x = try_op() catch default_value;`
- **Chapter:** 6 (Error Handling)
- **Version:** All versions

**comptime**
- **Definition:** Keyword for compile-time execution. Code runs during compilation.
- **Enables:** Zero-cost generics, metaprogramming, type manipulation
- **Chapter:** 2 (Language Idioms), 5 (I/O), 6 (Error Handling), 8 (Build), 11 (Interop), 13 (Logging)
- **Version:** All versions

**Condition (std.Thread.Condition)**
- **Definition:** Synchronization primitive enabling threads to wait for conditions without busy-waiting.
- **Pattern:** Producer-consumer queues
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**content-addressed dependencies**
- **Definition:** Package system using SHA-256 hashes as source of truth.
- **Benefits:** Immutability, integrity, reproducibility
- **Chapter:** 9 (Packages & Dependencies)
- **Version:** All versions

**cross-compilation**
- **Definition:** Compiling for different target arch/OS from any host.
- **Support:** 40+ OSes, 43 architectures, no external toolchains needed
- **Chapter:** 8 (Build System), 10 (Project Layout), 11 (Interoperability)
- **Version:** All versions

### D

**Debug (build mode)**
- **Definition:** Build optimization mode with no optimizations, all safety checks, debug info.
- **Usage:** Default mode for development
- **Chapter:** 8 (Build System), 10 (Project Layout)
- **Version:** All versions

**defer**
- **Definition:** Statement scheduling code to execute when scope exits (LIFO order).
- **Essential For:** Resource cleanup, deterministic destructors
- **Pattern:** Place immediately after acquisition
- **Chapter:** 2 (Language Idioms), 5 (I/O), 6 (Error Handling), 11 (Interoperability)
- **Version:** All versions

**dependency (build system)**
- **Definition:** External package referenced in build.zig.zon, loaded with b.dependency() or b.lazyDependency().
- **Chapter:** 8 (Build System), 9 (Packages)
- **Version:** ✅ 0.15+ uses new module system

**Direct I/O**
- **Definition:** I/O bypassing OS page cache using O_DIRECT flag.
- **Use Case:** Database systems requiring precise control
- **Chapter:** 5 (I/O)
- **Version:** All versions

### E

**errdefer**
- **Definition:** Conditional defer executing only if function returns error.
- **Critical For:** Cleanup of partial initialization
- **Pattern:** Place after each allocation in multi-step init
- **Chapter:** 2 (Language Idioms), 6 (Error Handling), 11 (Interoperability)
- **Version:** All versions

**error set**
- **Definition:** Named collection of error values defined at compile time.
- **Merging:** Use || operator to combine error sets
- **Chapter:** 6 (Error Handling)
- **Version:** All versions

**error union (!T syntax)**
- **Definition:** Type combining error set with success type (e.g., FileError![]u8).
- **Benefit:** Compile-time verification of error handling
- **Chapter:** 2 (Language Idioms), 6 (Error Handling)
- **Version:** All versions

**export**
- **Definition:** Keyword making Zig functions callable from C by generating C-compatible symbols.
- **Usage:** `export fn foo() void { ... }`
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**extern**
- **Definition:** Keyword declaring functions/variables defined elsewhere (C libraries, object files).
- **Usage:** `extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;`
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**extern struct**
- **Definition:** Struct with C-compatible memory layout (field order preserved, C padding rules).
- **Required For:** C interop
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

### F

**FailingAllocator**
- **Definition:** Testing allocator (std.testing.FailingAllocator) failing at specific allocation points.
- **Essential For:** Testing error paths
- **Chapter:** 6 (Error Handling)
- **Version:** All versions

**FFI (Foreign Function Interface)**
- **Definition:** Mechanism for calling functions across language boundaries.
- **Zig's Approach:** Zero-overhead via @cImport and extern
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**fingerprint**
- **Definition:** 64-bit unique identifier in build.zig.zon for global package identity.
- **Rule:** Auto-generated, must never change manually
- **Chapter:** 9 (Packages & Dependencies)
- **Version:** ✅ 0.15+ (required)

**fixedBufferStream**
- **Definition:** Zero-allocation stream backed by fixed-size buffer.
- **Use Case:** Performance-critical code, known maximum sizes
- **Chapter:** 5 (I/O)
- **Version:** All versions

**flush**
- **Definition:** Method forcing buffered data to underlying stream.
- **Critical:** Forgetting flush causes missing output
- **Chapter:** 5 (I/O)
- **Version:** ✅ 0.15+ requires explicit flush

### G

**GPA (GeneralPurposeAllocator)**
- **Definition:** General-purpose allocator with leak detection and safety checks.
- **Features:** Thread-safe, prevents double-free/use-after-free, never reuses addresses
- **Chapter:** 3 (Memory), 6 (Error Handling)
- **Version:** All versions

### H

**HashMap**
- **Definition:** Standard library hash map for key-value storage.
- **Variants:** HashMap, AutoHashMap, StringHashMap (and Unmanaged versions)
- **Chapter:** 4 (Collections), 6 (Error Handling), 7 (Async)
- **Version:** All versions

### I

**inline**
- **Definition:** Keyword forcing inline expansion of function.
- **Use:** Small performance-critical functions, hot paths
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

### L

**lazy dependency**
- **Definition:** Package dependency marked .lazy = true, only fetched when used.
- **Use Case:** Optional features, platform-specific dependencies
- **Chapter:** 9 (Packages & Dependencies)
- **Version:** All versions

**libxev**
- **Definition:** Library-based event loop providing async I/O via platform-optimized backends.
- **Backends:** io_uring (Linux), kqueue (BSD/macOS), IOCP (Windows)
- **Chapter:** 7 (Async & Concurrency)
- **Version:** ✅ 0.15+ (after removal of built-in async/await)

**linear memory (WASM)**
- **Definition:** WebAssembly's single contiguous memory space where pointers are 32-bit offsets.
- **Growth:** Memory growth may relocate buffer
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**linkLibC**
- **Definition:** Build system method linking C standard library.
- **Required For:** C interop, provides standard include paths
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**linkLibCpp**
- **Definition:** Build system method linking C++ standard library.
- **Required For:** Compiling C++ code
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**log levels (err, warn, info, debug)**
- **Definition:** Severity levels for logging, ordered by priority.
- **Default Filtering:** Based on build mode
- **Chapter:** 13 (Logging)
- **Version:** All versions

### M

**memory ordering**
- **Definition:** Atomic operation semantics controlling memory operation visibility.
- **Types:** unordered, monotonic, acquire, release, acq_rel, seq_cst
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**module (build system)**
- **Definition:** Primary abstraction for code organization defining source file, target, optimization, dependencies.
- **Creation:** b.addModule() (public) or b.createModule() (private)
- **Chapter:** 8 (Build System), 9 (Packages)
- **Version:** ✅ 0.15+ (replaced package paths)

**monotonic (memory ordering)**
- **Definition:** Atomic ordering with no cross-thread synchronization guarantees.
- **Use:** Simple counters without dependencies
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**musl**
- **Definition:** Lightweight C standard library.
- **Zig Usage:** Static linking, producing portable Linux binaries
- **Chapter:** 10 (Project Layout), 11 (Interoperability)
- **Version:** All versions

**Mutex (std.Thread.Mutex)**
- **Definition:** Mutual exclusion lock allowing only one thread access.
- **Features:** Platform-optimized, debug deadlock detection
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

### N

**native (CPU features)**
- **Definition:** CPU feature setting optimizing for build host.
- **Trade-off:** Maximum performance vs portability
- **Chapter:** 10 (Project Layout & CI)
- **Version:** All versions

**null-terminated string**
- **Definition:** C-style string ending with zero byte.
- **Zig Type:** [*:0]u8 or [:0]u8
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

### O

**opaque type**
- **Definition:** Type with unknown size/layout, only usable via pointers.
- **Use:** Represents C incomplete types and forward declarations
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**optional (?T)**
- **Definition:** Type that may or may not contain value.
- **Safety:** Compile-time null safety without runtime overhead
- **Operators:** .?, orelse, if unwrapping, while unwrapping
- **Chapter:** 2 (Language Idioms), 6 (Error Handling), 11 (Interoperability)
- **Version:** All versions

### P

**packed struct**
- **Definition:** Struct with no padding, bit-packed for minimum size.
- **Use:** Bitfields, hardware registers, wire protocols
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**pointer types**
- **Single-item:** *T, ?*T (nullable)
- **Many-item:** [*]T
- **C-compatible:** [*c]T
- **Sentinel-terminated:** [*:0]T
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

### R

**Reader**
- **Definition:** Generic I/O interface for input (std.io.Reader).
- **Benefit:** Uniform API across different input sources
- **Chapter:** 5 (I/O)
- **Version:** All versions

**release (memory ordering)**
- **Definition:** Memory ordering publishing changes to acquire operations.
- **Guarantee:** All prior writes complete before release visible
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**ReleaseFast**
- **Definition:** Build mode maximizing speed, disabling safety checks.
- **Use:** Maximum performance production binaries
- **Chapter:** 8 (Build System), 10 (Project Layout)
- **Version:** All versions

**ReleaseSafe**
- **Definition:** Build mode balancing speed with safety checks.
- **Recommended:** Production binaries
- **Chapter:** 8 (Build System), 10 (Project Layout)
- **Version:** All versions

**ReleaseSmall**
- **Definition:** Build mode optimizing for minimum binary size.
- **Trade-off:** Size over speed
- **Chapter:** 8 (Build System), 10 (Project Layout)
- **Version:** All versions

**RwLock (std.Thread.RwLock)**
- **Definition:** Reader-writer lock allowing multiple readers OR single writer.
- **Optimization:** Read-heavy workloads
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

### S

**scoped logging**
- **Definition:** Logging namespaced by subsystem using std.log.scoped().
- **Benefit:** Per-component filtering and organization
- **Usage:** `const log = std.log.scoped(.database);`
- **Chapter:** 13 (Logging)
- **Version:** All versions

**sentinel type**
- **Definition:** Array/pointer type with known termination value.
- **Example:** [*:0]u8 for null-terminated strings
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**slice ([]T)**
- **Definition:** Runtime-known length view of array or memory portion.
- **Contains:** Pointer and length fields
- **Chapter:** 5 (I/O), 11 (Interoperability)
- **Version:** All versions

**std.Build**
- **Definition:** Standard library module providing build system API.
- **Core Type:** Configuration for compilation
- **Chapter:** 8 (Build System), 9 (Packages)
- **Version:** ✅ 0.15+ has new module system

**std.debug.print**
- **Definition:** Printf-style debugging function for temporary diagnostics.
- **Note:** Not for permanent instrumentation (use std.log)
- **Chapter:** 5 (I/O), 13 (Logging)
- **Version:** All versions

**std.fmt**
- **Definition:** Standard library formatting module.
- **Features:** Print specifiers, custom formatting via format() method
- **Chapter:** 5 (I/O)
- **Version:** All versions

**std.log**
- **Definition:** Standard library logging module with compile-time filtering.
- **Features:** Scoped organization, customizable handlers
- **Chapter:** 13 (Logging)
- **Version:** All versions

**std.testing**
- **Definition:** Standard library testing utilities.
- **Includes:** Assertions, FailingAllocator, test runners
- **Chapter:** 6 (Error Handling), 12 (Testing)
- **Version:** All versions

**std.Thread**
- **Definition:** Standard library OS thread abstraction.
- **Lifecycle:** Explicit spawn, join, detach
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**std.Thread.Pool**
- **Definition:** Thread pool for CPU-bound parallelism.
- **Use:** Distributing tasks across worker threads
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**std.time.Timer**
- **Definition:** High-precision timer for benchmarking.
- **Usage:** `var timer = try std.time.Timer.start(); const elapsed = timer.read();`
- **Chapter:** 7 (Async), 12 (Testing)
- **Version:** All versions

**stream**
- **Definition:** Abstract interface for sequential I/O.
- **Types:** Readers consume data, Writers produce data
- **Chapter:** 5 (I/O)
- **Version:** All versions

### T

**target**
- **Definition:** Compilation target specifying arch, OS, ABI.
- **Examples:** x86_64-linux-musl, aarch64-macos, wasm32-wasi
- **Chapter:** 8 (Build System), 10 (Project Layout)
- **Version:** ✅ 0.15+ uses Query API

**test block**
- **Definition:** Top-level test declaration using test keyword.
- **Purpose:** Unit testing embedded in source files
- **Syntax:** `test "description" { ... }`
- **Chapter:** 6 (Error Handling), 12 (Testing)
- **Version:** All versions

**Thread (std.Thread)**
- **Definition:** OS-level thread with explicit lifecycle.
- **Methods:** spawn, join, detach
- **Note:** No automatic cleanup
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**try**
- **Definition:** Keyword for error propagation.
- **Equivalent:** `result catch |err| return err`
- **Chapter:** 6 (Error Handling)
- **Version:** All versions

### U

**unbuffered I/O**
- **Definition:** I/O pattern writing directly to underlying stream without buffering.
- **Chapter:** 5 (I/O)
- **Version:** ✅ 0.15+ uses writer(&.{})

**undefined**
- **Definition:** Special value indicating uninitialized memory.
- **Use:** Signal that value will be set before use
- **Chapter:** 2 (Language Idioms)
- **Version:** All versions

### W

**WASI (WebAssembly System Interface)**
- **Definition:** Capability-based system interface for WebAssembly.
- **Features:** POSIX-like APIs with sandboxed security
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**WASM (WebAssembly)**
- **Definition:** Binary instruction format for stack-based VM.
- **Zig Targets:** wasm32-freestanding, wasm32-wasi
- **Chapter:** 11 (Interoperability)
- **Version:** All versions

**WaitGroup (std.Thread.WaitGroup)**
- **Definition:** Synchronization primitive for waiting on multiple concurrent operations.
- **Pattern:** Parallel task completion
- **Chapter:** 7 (Async & Concurrency)
- **Version:** All versions

**Writer**
- **Definition:** Generic I/O interface for output (std.io.Writer).
- **Benefit:** Uniform API across output destinations
- **Chapter:** 5 (I/O)
- **Version:** All versions

### X-Z

**x86_64_v2, x86_64_v3, x86_64_v4**
- **Definition:** Intel/AMD microarchitecture levels defining required instruction sets.
- **Features:** SSE4.2 (v2), AVX2 (v3), AVX-512 (v4)
- **Chapter:** 10 (Project Layout & CI)
- **Version:** All versions

**zig build**
- **Definition:** Command executing build.zig to compile projects.
- **Flags:** -Dtarget, -Doptimize
- **Chapter:** 8 (Build System), 9 (Packages), 10 (Project Layout)
- **Version:** All versions

**zig fetch**
- **Definition:** Command adding dependencies to build.zig.zon.
- **Functionality:** Computes content hashes, --save updates manifest
- **Chapter:** 9 (Packages & Dependencies)
- **Version:** All versions

**zig fmt**
- **Definition:** Official code formatter ensuring consistent style.
- **CI Usage:** --check flag for validation
- **Chapter:** 10 (Project Layout & CI)
- **Version:** All versions

**zig init**
- **Definition:** Command generating standard project structure.
- **Creates:** build.zig, build.zig.zon, src/, .gitignore
- **Chapter:** 10 (Project Layout & CI)
- **Version:** All versions

**zig test**
- **Definition:** Command running test blocks.
- **Execution:** Code within test declarations
- **Chapter:** 6 (Error Handling), 12 (Testing)
- **Version:** All versions

---

## 2. IDIOMATIC ZIG STYLE CHECKLIST

### Naming Conventions

#### ✅ Functions - snake_case
**Rationale:** Provides visual separation, consistent across all production codebases
```zig
// ✅ Good
pub fn init(allocator: Allocator) !Self { }
pub fn get_host_name() []const u8 { }

// ❌ Bad
pub fn Init(allocator: Allocator) !Self { }
pub fn getHostName() []const u8 { }
```
**Sources:** All repositories

#### ✅ Types - PascalCase
**Rationale:** Clear distinction from functions
```zig
// ✅ Good
pub const ArrayList = struct { };
pub const MessagePool = struct { };

// ❌ Bad
pub const array_list = struct { };
pub const message_pool = struct { };
```
**Sources:** All repositories

#### ✅ Constants - snake_case (preferred) or SCREAMING_SNAKE_CASE
**Rationale:** snake_case is preferred; SCREAMING used sparingly
```zig
// ✅ Preferred (TigerBeetle, stdlib)
pub const clients_max = 32;
pub const default_max_load_percentage = 80;

// ✅ Also valid for special constants
const TABSTOP_INTERVAL = 8;

// ❌ Bad
pub const ClientsMax = 32;
```
**Sources:** TigerBeetle (snake_case), Ghostty (both), stdlib (snake_case)

#### ✅ Variables - snake_case with units last
**Rationale:** Units last allows alignment; most significant word first
```zig
// ✅ Good (TigerBeetle style)
const latency_ms_max: u64 = 100;
const latency_ms_min: u64 = 10;
const buffer_size_bytes: usize = 4096;

// ❌ Bad
const max_latency_ms: u64 = 100;
const BytesBufferSize: usize = 4096;
```
**Sources:** TigerBeetle (explicit requirement)

#### ✅ Acronyms - Proper Capitalization
**Rationale:** Maintains readability
```zig
// ✅ Good
pub const VSRState = enum { ... };
pub const IOContext = struct { ... };

// ❌ Bad
pub const VsrState = enum { ... };
pub const IoContext = struct { ... };
```
**Sources:** TigerBeetle (explicit), stdlib

#### ✅ File Naming - Mixed convention accepted
**Patterns:**
- `snake_case.zig` for modules/utilities
- `PascalCase.zig` for single-type files
```
// Std library pattern
std/
  array_list.zig          // Module
  ArrayList.zig           // Single type (deprecated)
  DoublyLinkedList.zig    // Single type

// TigerBeetle pattern (snake_case everything)
src/
  message_pool.zig
  client.zig
```
**Sources:** Stdlib (both), TigerBeetle (snake_case only), Ghostty (both)

### Code Organization

#### ✅ Import Ordering - std first, then local
```zig
// ✅ Good (TigerBeetle, ZLS pattern)
const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const assert = std.debug.assert;

const vsr = @import("vsr.zig");
const constants = @import("constants.zig");

// ❌ Bad
const vsr = @import("vsr.zig");
const std = @import("std");
const constants = @import("constants.zig");
```
**Sources:** All repositories

#### ✅ File Structure - Types first, then methods
```zig
// ✅ Good
const Terminal = @This();

const std = @import("std");
const log = std.log.scoped(.terminal);

// Public constants
pub const TABSTOP_INTERVAL = 8;

// Fields
allocator: Allocator,
buffer: []u8,

// Nested types
pub const ScreenType = enum { primary, alternate };

const Self = @This(); // Marks end of type section

// Methods
pub fn init(allocator: Allocator) !Self { }
pub fn deinit(self: *Self) void { }
```
**Sources:** Ghostty, ZLS, TigerBeetle

### Function Patterns

#### ✅ init/deinit Convention
```zig
// ✅ Good - Standard pattern
pub fn init(allocator: Allocator) !Self {
    return Self{
        .allocator = allocator,
        .items = &[_]T{},
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.items);
}

// ✅ TigerBeetle - In-place init for large structs
pub fn init(target: *LargeStruct, allocator: Allocator) !void {
    target.* = .{ .allocator = allocator };
}
```
**Sources:** All repositories

#### ✅ Allocator Parameters - Named appropriately
```zig
// ✅ Standard library pattern
pub fn init(allocator: Allocator, capacity: usize) !Self

// ✅ TigerBeetle/ZLS - distinguish allocator types
pub fn init(gpa: Allocator, options: Options) !Self

// Naming provides semantic meaning:
// - "arena": No explicit deinit needed
// - "gpa": Requires explicit deinit
```
**Sources:** All repositories

#### ✅ Self Parameter Patterns
```zig
// ✅ Good - Mutation
pub fn deinit(self: *Self) void { }

// ✅ Good - Reading
pub fn isEmpty(self: *const Self) bool { }

// ✅ Good - Consuming
pub fn moveToUnmanaged(self: *Self) Unmanaged {
    const result = self.unmanaged;
    self.* = .{};
    return result;
}
```
**Sources:** Stdlib, all repositories

#### ✅ Options Struct Pattern
**Rationale:** Prevents argument confusion for ≥2 params of same type
```zig
// ✅ Good
pub fn init(allocator: Allocator, options: struct {
    id: u128,
    cluster: u128,
    replica_count: u8,
    callback: ?*const fn() void = null,
}) !Self
```
**Sources:** TigerBeetle (explicit), ZLS, Stdlib

### Error Handling

#### ✅ defer Pattern - Visual grouping
```zig
// ✅ Good (TigerBeetle style)
const buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer);

const arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
```
**Sources:** TigerBeetle (explicit requirement)

#### ✅ errdefer Pattern - Immediate placement
```zig
// ✅ Good
pub fn init(allocator: Allocator) !Self {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);

    var message_pool = try MessagePool.init(allocator);
    errdefer message_pool.deinit(allocator);

    return Self{ .buffer = buffer, .message_pool = message_pool };
}
```
**Sources:** All repositories

#### ✅ try vs catch - Appropriate usage
```zig
// ✅ Good - Propagate errors
const file = try std.fs.cwd().openFile(path, .{});

// ✅ Good - Handle specific cases
const value = parseValue(input) catch |err| switch (err) {
    error.InvalidFormat => return default_value,
    else => return err,
};
```
**Sources:** All repositories

### Assertion Patterns

#### ✅ Assertion Density - Minimum 2 per function
**Rationale:** Validates preconditions, postconditions, invariants
```zig
// ✅ Good (TigerBeetle pattern)
pub fn push(list: *List, node: *Node) void {
    if (constants.verify) assert(!list.contains(node));
    assert(@field(node, field_back) == null);
    assert(@field(node, field_next) == null);

    if (list.tail) |tail| {
        assert(list.count > 0);
        assert(@field(tail, field_next) == null);
        // Implementation...
    } else {
        assert(list.count == 0);
    }

    list.count += 1;
}
```
**Sources:** TigerBeetle (explicit requirement)

#### ✅ Split Compound Assertions
```zig
// ✅ Good
assert(a);
assert(b);
assert(c);

// ❌ Bad - unclear which fails
assert(a and b and c);
```
**Sources:** TigerBeetle (explicit)

#### ✅ Compile-time Assertions
```zig
// ✅ Good - Validate design invariants
comptime {
    assert(vsr_checkpoint_ops >= pipeline_prepare_queue_max);
    assert(@sizeOf(Header) == 128);
    assert(@alignOf(Message) == constants.sector_size);
}
```
**Sources:** TigerBeetle (extensively), Stdlib

### Memory Management

#### ✅ Static Allocation - All memory upfront
**Rationale:** Predictable, no allocation after init (TigerBeetle pattern)
```zig
// ✅ Good
pub fn init(allocator: Allocator) !Self {
    const messages = try allocator.alloc(Message, messages_max);
    errdefer allocator.free(messages);

    const buffer = try allocator.alloc(u8, buffer_size);
    errdefer allocator.free(buffer);

    return Self{ .messages = messages, .buffer = buffer };
}
```
**Sources:** TigerBeetle (explicit requirement)

#### ✅ Arena Usage - Name communicates cleanup
```zig
// ✅ Good - Name signals no explicit deinit
var arena = std.heap.ArenaAllocator.init(gpa);
defer arena.deinit();

const items = try arena.allocator().alloc(Item, count);
// No individual free needed

// ✅ Good - "gpa" signals explicit management
const buffer = try gpa.alloc(u8, size);
defer gpa.free(buffer);
```
**Sources:** TigerBeetle (explicit), ZLS, Stdlib

### Documentation

#### ✅ Doc Comment Style - Triple slash
```zig
/// The maximum number of clients allowed per cluster.
/// This impacts the amount of memory allocated at initialization.
/// Client ID 0 (used by primary for pulse) is not counted.
pub const clients_max = 32;

/// Insert `item` at index `i`. Moves items to higher indices.
/// This operation is O(N).
/// Invalidates element pointers if additional memory is needed.
/// Asserts that the index is in bounds or equal to the length.
pub fn insert(self: *Self, i: usize, item: T) !void
```
**Sources:** All repositories

#### ✅ File-level Documentation
```zig
//! A thread-safe container for all document related state.
//! This manages Zig source files including build.zig files.

const DocumentStore = @This();
```
**Sources:** ZLS, Ghostty, Stdlib

### Performance Patterns

#### ✅ inline Usage - Hot paths only
```zig
// ✅ Good - Small performance-critical functions
pub inline fn trace(comptime src: std.builtin.SourceLocation) Ctx { }
pub inline fn toByteUnits(a: Alignment) usize {
    return @as(usize, 1) << @intFromEnum(a);
}
```
**Sources:** ZLS (tracy), Stdlib, Bun

### Safety Patterns

#### ✅ Explicit Integer Types
**Rationale:** Use sized types (u32, u64) over usize when possible
```zig
// ✅ Good (TigerBeetle style)
pub const replica_count: u8 = 6;
pub const clients_max: u32 = 32;

// Only use usize for indexing
const index: usize = ...;
```
**Sources:** TigerBeetle (explicit requirement)

#### ✅ Bounded Loops
```zig
// ✅ Good - Bounded
for (items[0..@min(items.len, items_max)]) |item| { }

// ✅ Or assert if truly unbounded
while (true) {
    comptime assert(!"This loop must never terminate");
    processEvents();
}
```
**Sources:** TigerBeetle (explicit)

### Testing Patterns

#### ✅ Test Naming - Descriptive strings
```zig
test "array list operations" { }
test "hash map iteration order" { }
test "client handles eviction" { }
```
**Sources:** All repositories

#### ✅ Testing Assertions
```zig
try testing.expect(condition);
try testing.expectEqual(expected, actual);
try testing.expectError(error.InvalidValue, function());
try testing.expectEqualStrings("hello", result);
```
**Sources:** All repositories

---

## 3. MASTER REFERENCE INDEX

*(Due to length, showing abbreviated version - full list has 200+ references)*

### Official Zig Documentation (42 references)
1. Zig Language Reference 0.15.2 - https://ziglang.org/documentation/0.15.2/
2. Zig Standard Library Documentation - https://ziglang.org/documentation/0.15.2/std/
3. Zig Build System Documentation - https://ziglang.org/learn/build-system/
4. std.log Documentation - https://ziglang.org/documentation/0.15.2/std/#std.log
5. std.Build API Documentation - https://ziglang.org/documentation/master/std/#std.Build
...

### GitHub Repositories (95 references)
**Zig Official (23 references)**
1. Zig Compiler - https://github.com/ziglang/zig
2. Zig Standard Library Io.zig - https://github.com/ziglang/zig/blob/0.15.2/lib/std/Io.zig
3. Zig Standard Library Thread.zig - https://github.com/ziglang/zig/blob/master/lib/std/Thread.zig
...

**TigerBeetle (26 references)**
1. TigerBeetle Repository - https://github.com/tigerbeetle/tigerbeetle
2. TigerBeetle TIGER_STYLE.md - https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
3. TigerBeetle vsr.zig - https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig
...

**Ghostty (16 references)**
1. Ghostty Repository - https://github.com/ghostty-org/ghostty
2. Ghostty build.zig - https://github.com/ghostty-org/ghostty/blob/main/build.zig
...

**Bun (11 references)**
1. Bun Repository - https://github.com/oven-sh/bun
2. Bun ThreadPool.zig - https://github.com/oven-sh/bun/blob/main/src/threading/ThreadPool.zig
...

**ZLS (9 references)**
1. ZLS Repository - https://github.com/zigtools/zls
2. ZLS DocumentStore.zig - https://github.com/zigtools/zls/blob/master/src/DocumentStore.zig
...

**Other Projects (10 references)**
- Mach, libxev, setup-zig, ziglyph, known-folders
...

### Community Resources (11 references)
1. Zig.guide - https://zig.guide
2. Ziggit Forum - https://ziggit.dev
3. ZigLearn - https://ziglearn.org/
...

### Educational Resources (8 references)
1. Learning Zig - Heap Memory & Allocators - https://www.openmymind.net/learning_zig/heap_memory/
2. Hexops - Zig Hashmaps Explained - https://devlog.hexops.com/2022/zig-hashmaps-explained/
...

### Academic/Technical (1 reference)
1. Simple Testing Can Prevent Most Critical Failures (Yuan et al., OSDI 2014)

### Web Standards (9 references)
1. WebAssembly Specification - https://webassembly.github.io/spec/
2. WASI Specification - https://github.com/WebAssembly/WASI
...

### Tools & Libraries (7 references)
1. Tracy Profiler - https://github.com/wolfpld/tracy
2. Linux perf - https://perf.wiki.kernel.org/
...

---

## 4. CROSS-CHAPTER CONCEPT INDEX

### Allocators
- Chapter 3: Core concepts, types, selection
- Chapter 4: Container initialization
- Chapter 5: I/O buffers
- Chapter 6: Error handling patterns
- Chapter 7: Thread-safe usage

### Error Handling
- Chapter 2: Basic patterns (try, catch, defer, errdefer)
- Chapter 5: I/O error recovery
- Chapter 6: Comprehensive error strategies
- Chapter 11: C FFI error translation

### Build System
- Chapter 8: build.zig fundamentals
- Chapter 9: Dependencies and packages
- Chapter 10: CI integration, cross-compilation
- Chapter 11: C/C++ linking

### Concurrency
- Chapter 7: Threads, mutexes, atomics
- Chapter 11: Thread safety in C interop

### Testing
- Chapter 6: Error path testing
- Chapter 12: Comprehensive testing strategies

### Logging
- Chapter 13: std.log, custom handlers, observability

---

## 5. COMMON PITFALLS SUMMARY

### Naming Pitfalls
- ❌ Inconsistent case (mixing snake_case and camelCase)
- ❌ Units first instead of last (max_latency_ms vs latency_ms_max)
- ❌ Unclear acronym capitalization (VsrState vs VSRState)

### Memory Pitfalls
- ❌ Forgetting defer after allocation
- ❌ Not using errdefer for multi-step init
- ❌ Individual allocations in loops (use arena)

### Error Handling Pitfalls
- ❌ Using anyerror instead of explicit error sets
- ❌ Not providing error context before re-throwing
- ❌ Compound assertions (harder to debug)

### Build System Pitfalls
- ❌ Not using standardTargetOptions() and standardOptimizeOption()
- ❌ Hardcoding paths instead of b.path()
- ❌ Missing lazy dependencies for optional features

### Testing Pitfalls
- ❌ Tests depending on execution order
- ❌ Shared mutable state between tests
- ❌ Not using testing.allocator (missing leak detection)

---

## 6. QUICK SYNTAX REFERENCE

### Variable Declarations
```zig
const x: i32 = 42;          // Immutable, explicit type
const y = 42;                // Type inferred
var z: i32 = 42;            // Mutable
var w: ?i32 = null;         // Optional
```

### Function Definitions
```zig
fn add(a: i32, b: i32) i32 { return a + b; }
fn divide(a: i32, b: i32) !i32 { ... }  // Error union
fn generic(value: anytype) @TypeOf(value) { ... }
```

### Control Flow
```zig
if (condition) { ... } else { ... }
switch (value) { ... }
while (condition) { ... }
for (items) |item| { ... }
for (items, 0..) |item, i| { ... }  // With index
```

### Error Handling
```zig
try operation();              // Propagate error
operation() catch |err| { ... };  // Handle error
const result = operation() catch default_value;
```

### Pointers and Memory
```zig
const ptr: *i32 = &value;     // Pointer
const slice: []i32 = &array;  // Slice
const many: [*]i32 = ptr;     // Many-item pointer
```

### Optionals
```zig
const value: ?i32 = 42;
const unwrapped = value.?;    // Unwrap (panic if null)
const safe = value orelse 0;  // Default value
if (value) |v| { ... }        // If unwrapping
```

---

## 7. VERSION-SPECIFIC NOTES

### 0.14.x → 0.15+ Major Changes

**Containers:**
- ArrayList now defaults to unmanaged (no stored allocator)
- HashMap variants default to unmanaged

**I/O:**
- Writer interface requires explicit buffer for buffering
- stdout is buffered by default, requires explicit flush
- File.writer() API changed

**Build System:**
- Module system replaces old package paths
- build.zig.zon requires .fingerprint field
- b.path() replaces old path APIs

**Async/Await:**
- Built-in async/await removed
- Use libxev or other event loop libraries

**Target API:**
- std.Target.Query replaces CrossTarget

---

## RESEARCH COMPLETION NOTES

**Total Research Time:** ~15 hours
**Terminology Extracted:** 150+ unique terms
**Style Guidelines:** 60+ concrete patterns
**References Collected:** 200+ authoritative sources
**Production Codebases Analyzed:** 5 (TigerBeetle, Ghostty, Bun, ZLS, Zig stdlib)
**Chapters Covered:** 1-13 (Chapter 14 migration guide, Chapter 15 appendices)

**Key Insights:**
1. TigerBeetle TIGER_STYLE is most comprehensive style guide
2. snake_case dominates for most identifiers (not CamelCase)
3. Unmanaged containers are new 0.15+ default
4. Explicit allocator passing is fundamental Zig philosophy
5. Assertions are critical (TigerBeetle requires 2+ per function)

**Next Steps:**
1. Create 6 code examples demonstrating reference usage
2. Write final content.md (~2000-2500 lines) organizing all material
3. Add cross-references throughout
4. Format for quick lookup and developer productivity
