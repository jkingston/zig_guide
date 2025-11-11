# Research Plan: Chapter 11 - Interoperability (C/C++/WASI/WASM)

## Document Information
- **Chapter**: 11 - Interoperability (C/C++/WASI/WASM)
- **Target Zig Versions**: 0.14.0, 0.14.1, 0.15.1, 0.15.2
- **Created**: 2025-11-04
- **Status**: Planning

## 1. Objectives

This research plan outlines the methodology for creating comprehensive documentation on Zig's interoperability capabilities with C, C++, and WebAssembly (WASI/WASM) targets. The chapter provides practical guidance for safe, maintainable foreign function interface (FFI) usage, memory ownership across language boundaries, and build integration.

**Primary Goals:**
1. Document @cImport and @cInclude mechanisms for C header translation
2. Explain extern declarations and calling conventions
3. Demonstrate C type mapping and ABI compatibility patterns
4. Show build system integration for C/C++ dependencies
5. Cover C++ interoperability via extern "C" bridges
6. Document WASM linear memory model and WASI pointer ownership
7. Provide practical examples from production codebases
8. Cover version-specific differences in FFI patterns

**Strategic Approach:**
- Focus on memory safety and ownership contracts across FFI boundaries
- Show real-world examples from Ghostty, Bun, TigerBeetle, and Zig stdlib
- Document common pitfalls (string handling, memory leaks, undefined behavior)
- Demonstrate build integration patterns for various C/C++ libraries
- Cover WASM-specific concerns (linear memory, JavaScript host interaction)
- Balance theory with runnable, testable examples
- Maintain version compatibility through clear markers

## 2. Scope Definition

### In Scope

**C Interoperability Topics:**
- @cImport and @cInclude fundamentals
- How clang translates C headers to Zig
- Extern function declarations and calling conventions
- C type mapping (primitives, pointers, structs, enums)
- C string handling (null-terminated vs Zig slices)
- Opaque types and incomplete struct declarations
- C variadic functions
- Function pointers and callbacks
- Alignment and padding considerations
- ABI compatibility guarantees

**Build Integration Topics:**
- Linking C object files and static libraries
- Dynamic library loading
- System library dependencies
- Cross-compilation with C dependencies
- Build.zig patterns for C/C++ code
- Include path management
- Compiler flags and defines
- pkg-config integration

**C++ Interoperability Topics:**
- Limitations of direct C++ interop
- Extern "C" bridge patterns
- Name mangling considerations
- C wrapper generation for C++ APIs
- Template instantiation strategies
- RAII vs defer/errdefer patterns
- Exception handling across boundaries

**WASM/WASI Topics:**
- WASM target compilation
- Linear memory model
- Pointer ownership in WASM
- JavaScript FFI patterns
- WASI filesystem and system interfaces
- Memory import/export
- Host function callbacks
- Browser vs Node.js vs standalone runtimes

### Out of Scope

- Automated binding generators (focus on manual patterns first)
- Platform-specific syscall details (beyond common patterns)
- Complex C++ template metaprogramming interop
- Advanced LLVM IR optimization for FFI
- JNI, Python, or other language bindings (focus on C/C++/WASM)
- Low-level assembly calling conventions (unless critical to understanding)
- Deep dive into C ABI specifications (reference only)

### Version-Specific Handling

**0.14.x and 0.15+ Differences:**
- @cImport behavior changes (if any)
- Build system C dependency integration API changes (refer to Chapter 8)
- WASM target specification syntax
- Standard library C interface changes (std.c)
- Extern declaration syntax consistency check

**Common Patterns (all versions):**
- @cImport mechanics are fundamentally consistent
- Extern declarations remain stable
- C type mapping is version-independent
- WASM linear memory model is consistent

## 3. Core Topics

### Topic 1: @cImport and @cInclude Fundamentals

**Concepts to Cover:**
- How @cImport invokes clang to translate C headers
- Difference between @cImport and @cInclude
- C macro translation and limitations
- Include path configuration
- System header location strategies
- Handling C header dependencies
- Preprocessor definitions and conditional compilation
- Namespace and naming conflicts
- Performance considerations of @cImport
- Caching of translated headers

**Research Sources:**
- Zig Language Reference 0.15.2: C translation section
- Zig stdlib: std/c.zig and std/c/*.zig files
- Zig compiler source: translate-c implementation
- Ghostty: How it imports platform C headers
- ZLS: C library header usage patterns
- Community guide: zig.guide on C interop

**Example Ideas:**
- Basic @cImport with stdio.h
- System library import (libc, pthread)
- Handling C macros and constants
- Conditional compilation with C headers

**Version-Specific Notes:**
- Check for any @cImport behavioral changes between 0.14.x and 0.15+
- Document any breaking changes in C translation

### Topic 2: Extern Declarations and Calling Conventions

**Concepts to Cover:**
- `extern` keyword for function declarations
- `export` keyword for exposing Zig functions to C
- Calling conventions (.C, .Inline, .Naked, etc.)
- Symbol visibility and linkage
- Name mangling and `@"symbol name"` syntax
- Weak linkage and optional symbols
- Thread-local storage across FFI
- Variadic function handling
- Function pointer types and callbacks
- Inline assembly for custom conventions

**Research Sources:**
- Zig Language Reference: extern and export sections
- TigerBeetle: C client library generation (tb_client.h)
- Bun: JavaScriptCore C++ integration patterns
- Zig stdlib: OS-specific extern declarations (std/os/*.zig)
- Ghostty: Platform abstraction layer

**Example Ideas:**
- Calling C functions (puts, malloc, free)
- Exposing Zig functions to C callers
- Function pointer callbacks
- Variadic function wrapper

**Version-Specific Notes:**
- Calling convention syntax consistency
- Export symbol naming conventions

### Topic 3: C Type Mapping and ABI Compatibility

**Concepts to Cover:**
- Primitive type mapping (c_int, c_char, c_long, etc.)
- Why not use i32 directly (platform differences)
- Pointer types ([*c]T vs [*]T vs *T)
- C array types (c_array)
- Struct layout and padding (@cStruct)
- Enum representation (c_enum)
- Union types (extern union)
- Opaque types for incomplete structs
- Alignment requirements (@alignOf, @sizeOf)
- Packed structs and bitfields
- Boolean representation (c_bool vs bool)
- C string types ([*:0]u8, [*c]u8)
- Size and signedness (c_size_t, c_ssize_t)

**Research Sources:**
- Zig Language Reference: C ABI types section
- std/c.zig: Complete type mapping reference
- Ghostty: Platform type definitions
- TigerBeetle: Cross-platform C ABI usage
- Bun: V8/JSC type mapping

**Example Ideas:**
- Type mapping reference table
- Struct layout demonstration
- Pointer type comparisons
- String handling example

**Version-Specific Notes:**
- c_* type definitions consistency
- @cStruct behavior verification

### Topic 4: Build System Integration for C/C++ Dependencies

**Concepts to Cover:**
- addCSourceFile and addCSourceFiles
- Include directory management (addIncludePath)
- Library linking (linkLibC, linkSystemLibrary)
- Static vs dynamic linking
- Cross-compilation with C libraries
- Compiler flags and defines
- pkg-config integration
- Submodule and vendored C library patterns
- Build artifact dependencies
- Conditional compilation based on target

**Research Sources:**
- Zig Build System documentation (zig.guide)
- Chapter 8: Build System (cross-reference)
- sqlite3 Zig binding examples
- raylib-zig: C library wrapper pattern
- Mach: OpenGL/Vulkan C header integration
- Ghostty: Build system for C dependencies

**Example Ideas:**
- Basic C file compilation in build.zig
- Linking system libraries (sqlite3)
- Vendored C library integration
- Cross-platform conditional compilation

**Version-Specific Notes:**
- Build API changes from 0.14.x to 0.15+ (refer to Chapter 8)
- addCSourceFile deprecations or changes

### Topic 5: C++ Interoperability Patterns

**Concepts to Cover:**
- Limitations: No direct C++ class/template interop
- Extern "C" bridge technique
- Creating C wrapper headers for C++ APIs
- Name mangling avoidance strategies
- Handling C++ exceptions (don't cross boundary)
- RAII wrappers in C with Zig cleanup
- C++ standard library considerations
- Template instantiation in C bridge
- Virtual function tables (vtable) concerns
- Constructors and destructors via C functions

**Research Sources:**
- Bun: C++ JavaScriptCore/V8 integration
- Zig compiler: C++ backend interaction
- Community discussions on C++ interop
- Example C++ wrapper libraries
- Zig stdlib: C++ standard library avoidance

**Example Ideas:**
- C wrapper for C++ class
- Extern "C" bridge header
- C++ library integration via wrapper
- String conversion (std::string ↔ Zig slice)

**Version-Specific Notes:**
- linkLibCpp availability
- C++ standard library linking changes

### Topic 6: WASM/WASI - Linear Memory and Ownership

**Concepts to Cover:**
- WASM compilation target (wasm32-freestanding, wasm32-wasi)
- Linear memory model fundamentals
- Pointer representation in WASM (i32 offsets)
- Memory import/export from JavaScript host
- WASI filesystem and stdio interfaces
- Host function imports
- Exporting Zig functions to JavaScript
- Memory ownership across WASM boundary
- JavaScript TypedArray interaction
- String encoding (UTF-8, UTF-16 considerations)
- Stack vs heap allocation in WASM
- Growth of linear memory (@wasmMemoryGrow)
- WASI preview1 vs preview2 differences

**Research Sources:**
- Zig Language Reference: WASM target section
- std/wasi.zig: WASI interface definitions
- Mach: WASM examples and demos
- zig-wasm examples in community
- MDN: WebAssembly JavaScript API
- WASI documentation and proposals

**Example Ideas:**
- Basic WASM module with exported function
- WASI filesystem operations
- JavaScript ↔ WASM string passing
- Memory import/export demonstration
- WASI command-line tool

**Version-Specific Notes:**
- WASM target specification syntax (0.14.x vs 0.15+)
- WASI preview version support
- std.wasi API changes

## 4. Code Examples Specification

### Example 1: Basic C Interop with @cImport

**Purpose:**
Demonstrate the fundamentals of @cImport for translating C headers and calling C standard library functions.

**Learning Objectives:**
- Understand @cImport syntax
- Import and call C stdlib functions
- Handle C types in Zig
- Use C constants and macros

**Technical Requirements:**
- Import stdio.h and stdlib.h
- Call printf, malloc, free
- Handle C strings ([*:0]const u8)
- Demonstrate C type usage (c_int, c_size_t)

**File Structure:**
```
examples/01_basic_c_interop/
  main.zig
  build.zig
  README.md
```

**Success Criteria:**
- Compiles on Zig 0.14.1 and 0.15.2
- Demonstrates safe memory management
- Shows proper C string handling
- Includes error handling

**Example Code Sketch:**
```zig
const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

pub fn main() void {
    // Call C printf
    _ = c.printf("Hello from C via @cImport\n");

    // Allocate C memory
    const ptr = c.malloc(100);
    defer c.free(ptr);

    // Type demonstration
    const num: c.c_int = 42;
    _ = c.printf("Number: %d\n", num);
}
```

### Example 2: Real C Library Integration (sqlite3)

**Purpose:**
Show integration with a real-world C library, demonstrating build configuration and API usage.

**Learning Objectives:**
- Link external C libraries
- Handle C library API patterns
- Manage C library resources
- Demonstrate practical FFI usage

**Technical Requirements:**
- Link sqlite3 library
- Open/close database
- Execute SQL queries
- Handle C error codes
- Proper resource cleanup

**File Structure:**
```
examples/02_sqlite_interop/
  main.zig
  build.zig
  README.md
  schema.sql (optional)
```

**Success Criteria:**
- Compiles with system sqlite3
- Demonstrates CRUD operations
- Shows proper error handling
- No memory leaks (valgrind clean)

**Example Code Sketch:**
```zig
const std = @import("std");
const c = @cImport({
    @cInclude("sqlite3.h");
});

pub fn main() !void {
    var db: ?*c.sqlite3 = null;
    const rc = c.sqlite3_open(":memory:", &db);
    if (rc != c.SQLITE_OK) return error.SqliteError;
    defer _ = c.sqlite3_close(db);

    // Execute SQL, fetch results, etc.
}
```

### Example 3: Build.zig with C Dependencies

**Purpose:**
Demonstrate comprehensive build system integration for projects mixing Zig and C code.

**Learning Objectives:**
- Compile C source files alongside Zig
- Configure include paths
- Link static/dynamic libraries
- Handle cross-platform build configuration

**Technical Requirements:**
- Multiple C source files
- Custom include directories
- Library dependencies
- Conditional compilation
- Cross-platform support

**File Structure:**
```
examples/03_build_integration/
  src/
    main.zig
    wrapper.zig
  c_lib/
    mylib.c
    mylib.h
  build.zig
  README.md
```

**Success Criteria:**
- Builds C and Zig code together
- Handles include paths correctly
- Cross-compiles successfully
- Demonstrates best practices

**Example Code Sketch:**
```zig
// build.zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "mixed",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.addCSourceFiles(.{
        .files = &.{"c_lib/mylib.c"},
        .flags = &.{"-Wall", "-O2"},
    });
    exe.addIncludePath(b.path("c_lib"));
    exe.linkLibC();

    b.installArtifact(exe);
}
```

### Example 4: C++ Interop via Extern "C" Bridge

**Purpose:**
Show how to safely interoperate with C++ code using an extern "C" bridge layer.

**Learning Objectives:**
- Understand C++ interop limitations
- Create extern "C" wrapper functions
- Bridge C++ classes to C API
- Manage C++ resources from Zig

**Technical Requirements:**
- Simple C++ class
- C wrapper header with extern "C"
- Zig code calling through C bridge
- Resource management (constructor/destructor)

**File Structure:**
```
examples/04_cpp_bridge/
  src/
    main.zig
  cpp/
    MyCppClass.hpp
    MyCppClass.cpp
    c_bridge.h
    c_bridge.cpp
  build.zig
  README.md
```

**Success Criteria:**
- Compiles with C++ code
- Safely manages C++ objects
- Demonstrates best practices
- Works on 0.14.1 and 0.15.2

**Example Code Sketch:**
```cpp
// c_bridge.h
#ifdef __cplusplus
extern "C" {
#endif

typedef struct MyCppClass MyCppClass;

MyCppClass* MyCppClass_create();
void MyCppClass_destroy(MyCppClass* obj);
int MyCppClass_getValue(MyCppClass* obj);

#ifdef __cplusplus
}
#endif
```

```zig
// main.zig
const c = @cImport({
    @cInclude("c_bridge.h");
});

pub fn main() void {
    const obj = c.MyCppClass_create();
    defer c.MyCppClass_destroy(obj);

    const value = c.MyCppClass_getValue(obj);
    std.debug.print("Value: {}\n", .{value});
}
```

### Example 5: WASM FFI with JavaScript Host

**Purpose:**
Demonstrate WASM compilation and JavaScript FFI for browser/Node.js environments.

**Learning Objectives:**
- Compile to WASM target
- Export Zig functions to JavaScript
- Import JavaScript host functions
- Handle memory and string passing

**Technical Requirements:**
- WASM target compilation
- Exported functions for JavaScript
- Imported host functions
- Memory management across boundary
- String encoding handling

**File Structure:**
```
examples/05_wasm_js_ffi/
  src/
    main.zig
  web/
    index.html
    loader.js
  build.zig
  README.md
```

**Success Criteria:**
- Compiles to WASM successfully
- Runs in browser and Node.js
- Demonstrates bidirectional calls
- Handles strings correctly

**Example Code Sketch:**
```zig
// main.zig
extern "c" fn consoleLog(ptr: [*]const u8, len: usize) void;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn greet(name_ptr: [*]const u8, name_len: usize) void {
    const message = "Hello, ";
    consoleLog(message.ptr, message.len);
    consoleLog(name_ptr, name_len);
}
```

```javascript
// loader.js
const imports = {
    env: {
        consoleLog: (ptr, len) => {
            const bytes = new Uint8Array(memory.buffer, ptr, len);
            const str = new TextDecoder().decode(bytes);
            console.log(str);
        }
    }
};

WebAssembly.instantiateStreaming(fetch('main.wasm'), imports)
    .then(result => {
        const { add, greet } = result.instance.exports;
        console.log('2 + 3 =', add(2, 3));
    });
```

### Example 6: WASI Filesystem and Pointer Ownership

**Purpose:**
Demonstrate WASI system interfaces with focus on memory ownership and filesystem operations.

**Learning Objectives:**
- Use WASI filesystem interfaces
- Understand WASI capability model
- Manage memory ownership in WASI
- Handle WASI error codes

**Technical Requirements:**
- WASI target compilation
- File read/write operations
- Stdio usage in WASI
- Proper error handling
- Memory safety across WASI boundary

**File Structure:**
```
examples/06_wasi_filesystem/
  src/
    main.zig
  build.zig
  test_input.txt
  README.md
```

**Success Criteria:**
- Compiles with wasm32-wasi target
- Runs in wasmtime
- Demonstrates filesystem operations
- Shows proper resource cleanup

**Example Code Sketch:**
```zig
const std = @import("std");

pub fn main() !void {
    // WASI stdout
    const stdout = std.io.getStdOut().writer();
    try stdout.print("WASI Filesystem Demo\n", .{});

    // Open file (requires --dir=. capability)
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    // Read contents
    const allocator = std.heap.page_allocator;
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(contents);

    try stdout.print("File contents: {s}\n", .{contents});
}
```

## 5. Research Methodology

### Phase 1: Official Documentation Review

**Objective:** Establish authoritative baseline knowledge of Zig's C interop and WASM capabilities.

**Tasks:**
1. Read Zig Language Reference 0.15.2:
   - C translation section (@cImport mechanics)
   - Extern and export keywords
   - C ABI type mappings
   - WASM target documentation
   - Cross-compilation section

2. Study std.c module:
   - Type definitions (std/c.zig)
   - Platform-specific types (std/c/linux.zig, std/c/darwin.zig, std/c/windows.zig)
   - Common C patterns in stdlib

3. Examine std.wasi:
   - WASI interface definitions
   - Filesystem operations
   - Memory management

4. Review Zig Build System docs:
   - addCSourceFile/addCSourceFiles APIs
   - linkLibC and linkSystemLibrary
   - Include path management

**Deliverables:**
- Annotated notes on C interop mechanisms
- Type mapping reference table
- WASM/WASI capability matrix
- Version difference documentation

**Timeline:** 1-2 hours

### Phase 2: Examine Ghostty (C/Swift Interop Patterns)

**Objective:** Study production-quality C interop patterns from a major cross-platform application.

**Research Focus:**
1. Platform abstraction layer:
   - How Ghostty abstracts platform differences
   - C header usage for system APIs
   - Cross-platform build configuration

2. Build system patterns:
   - build.zig C dependency integration
   - Include path organization
   - Conditional compilation

3. Memory safety patterns:
   - Resource management across FFI
   - Error handling at boundaries
   - Pointer ownership contracts

**Specific Files to Review:**
- build.zig: C dependency configuration
- src/os/: Platform-specific C interop
- C header imports and wrapper patterns

**Key Questions:**
- How does Ghostty handle platform-specific C APIs?
- What patterns ensure memory safety at FFI boundaries?
- How are C callbacks managed?

**Deliverables:**
- Pattern catalog with code citations
- Build configuration examples
- Memory safety best practices

**Timeline:** 2-3 hours

### Phase 3: Examine Bun (C++ Integration Patterns)

**Objective:** Understand C++ interop strategies from a JavaScript runtime implemented in Zig.

**Research Focus:**
1. JavaScriptCore/V8 integration:
   - How Bun bridges Zig to C++ JS engines
   - Type conversions between Zig and C++ types
   - Memory management across language boundaries

2. Native module system:
   - C++ native module integration
   - Extern "C" bridge patterns
   - Template instantiation strategies

3. Build system:
   - C++ compilation configuration
   - Linking strategy (static vs dynamic)
   - Cross-platform C++ dependency handling

**Specific Files to Review:**
- build.zig: C++ compilation setup
- src/js/: JavaScript engine integration
- Native module bindings

**Key Questions:**
- What extern "C" bridge patterns does Bun use?
- How are C++ exceptions handled?
- What are the memory ownership contracts?

**Deliverables:**
- C++ bridge pattern documentation
- Build configuration reference
- Memory safety guidelines

**Timeline:** 2-3 hours

### Phase 4: Examine TigerBeetle (C Client Generation)

**Objective:** Study how TigerBeetle generates C client libraries from Zig code.

**Research Focus:**
1. C client library generation:
   - How TigerBeetle exposes Zig API to C
   - Export patterns and naming conventions
   - ABI stability guarantees

2. C header generation:
   - Automated header file creation
   - Type mapping (Zig → C)
   - Documentation generation for C users

3. Error handling patterns:
   - How errors cross the FFI boundary
   - C error code conventions
   - Resource cleanup patterns

**Specific Files to Review:**
- src/clients/c/tb_client.h: Generated C header
- src/clients/c/: C client implementation
- Client library build configuration

**Key Questions:**
- How does TigerBeetle ensure ABI stability?
- What patterns ensure safe resource management from C?
- How are complex Zig types exposed to C?

**Deliverables:**
- Export pattern documentation
- ABI stability guidelines
- C header generation insights

**Timeline:** 1-2 hours

### Phase 5: WASM/WASI Patterns from Mach and Stdlib

**Objective:** Document WASM compilation and WASI interface patterns.

**Research Focus:**
1. Mach WASM examples:
   - WASM target build configuration
   - Browser integration patterns
   - Memory management strategies

2. std.wasi exploration:
   - WASI syscall wrappers
   - Filesystem capability model
   - Error handling patterns

3. Community WASM examples:
   - zig-wasm repositories
   - Real-world WASM use cases
   - Performance considerations

**Specific Files to Review:**
- Mach WASM examples and demos
- std/wasi.zig: WASI interface definitions
- Community WASM projects

**Key Questions:**
- How does linear memory affect pointer usage?
- What are WASI capability model implications?
- How to handle JavaScript ↔ WASM string conversion?

**Deliverables:**
- WASM compilation guide
- WASI pattern documentation
- JavaScript FFI reference

**Timeline:** 2-3 hours

### Phase 6: Create and Test All Examples

**Objective:** Develop, test, and validate all 6 code examples.

**Tasks:**
1. Example 1: Basic C interop
   - Write main.zig with @cImport demo
   - Create build.zig
   - Test on 0.14.1 and 0.15.2
   - Write README with explanation

2. Example 2: sqlite3 integration
   - Write sqlite3 wrapper code
   - Configure build for system library
   - Test CRUD operations
   - Verify memory safety (valgrind)

3. Example 3: Build integration
   - Create mixed Zig/C project
   - Configure complex build.zig
   - Test cross-compilation
   - Document best practices

4. Example 4: C++ bridge
   - Write C++ class and bridge
   - Create extern "C" wrapper
   - Implement Zig caller
   - Test resource management

5. Example 5: WASM JavaScript FFI
   - Write WASM module
   - Create HTML/JS loader
   - Test in browser and Node.js
   - Document string handling

6. Example 6: WASI filesystem
   - Write WASI program
   - Test with wasmtime
   - Demonstrate file operations
   - Show capability model

**Validation Criteria:**
- All examples compile on 0.14.1 and 0.15.2
- No compiler warnings
- Memory safety verified (valgrind, ASan where applicable)
- Clear documentation and comments
- Runnable without modification

**Deliverables:**
- 6 complete, tested examples
- README for each example
- Build configuration for each
- Test results documentation

**Timeline:** 4-6 hours

### Phase 7: Document Common Pitfalls

**Objective:** Create comprehensive documentation of common FFI mistakes and their solutions.

**Research Approach:**
1. Survey community forums (ziggit.dev, GitHub issues)
2. Analyze error patterns in reference projects
3. Test edge cases and failure modes
4. Document safe alternatives

**Pitfall Categories:**
1. **Memory Management:**
   - Leaking C allocations
   - Double-free errors
   - Use-after-free across FFI
   - Stack vs heap allocation mismatches

2. **String Handling:**
   - Null termination issues
   - UTF-8 vs C string confusion
   - Buffer overflow vulnerabilities
   - Lifetime management

3. **Type Mismatches:**
   - Using i32 instead of c_int
   - Pointer type confusion ([*c] vs [*] vs *)
   - Alignment issues
   - Struct layout mismatches

4. **Build Configuration:**
   - Missing linkLibC
   - Incorrect include paths
   - ABI incompatibilities
   - Cross-compilation failures

5. **WASM Specific:**
   - Linear memory overflow
   - Pointer invalidation on growth
   - JavaScript type conversion errors
   - WASI capability violations

**Deliverables:**
- "Common Pitfalls" section with examples
- Comparison table (incorrect vs correct)
- Debug strategies
- Best practice recommendations

**Timeline:** 2-3 hours

### Phase 8: Synthesize Findings into research_notes.md

**Objective:** Consolidate all research into comprehensive notes for content writing.

**Tasks:**
1. Organize all findings by topic
2. Add deep citations (25+ references)
3. Include code snippets from reference projects
4. Document version differences
5. Create pattern catalog
6. Summarize key insights

**Structure:**
1. @cImport and Translation
   - Mechanisms and internals
   - Best practices
   - Citations

2. Extern and Export Patterns
   - Calling conventions
   - Symbol management
   - Examples from projects

3. C Type Mapping Reference
   - Complete type table
   - Platform differences
   - ABI considerations

4. Build Integration Patterns
   - Configuration examples
   - Cross-platform strategies
   - Dependency management

5. C++ Interop Strategies
   - Bridge patterns
   - Resource management
   - Real-world examples

6. WASM/WASI Patterns
   - Compilation strategies
   - Memory management
   - JavaScript integration

**Deliverables:**
- research_notes.md (800-1000 lines minimum)
- 25+ deep GitHub/documentation citations
- Code examples from production projects
- Version compatibility notes

**Timeline:** 2-3 hours

## 6. Reference Projects Analysis

### Analysis Matrix

| Project | Primary Focus | Files to Review | Key Patterns |
|---------|--------------|-----------------|--------------|
| **Ghostty** | C/Swift FFI, platform abstraction | `build.zig`, `src/os/`, C header imports | Platform-specific C APIs, cross-platform build, memory safety patterns |
| **Bun** | C++ integration, JS runtime | `build.zig`, `src/js/`, native modules | Extern "C" bridges, C++ template handling, memory ownership |
| **TigerBeetle** | C client generation | `src/clients/c/`, `tb_client.h` | Export patterns, ABI stability, error handling |
| **Zig Compiler** | Self-hosting, C++ backend | `src/`, build configuration | C++ interop, clang integration, cross-compilation |
| **ZLS** | C library usage | `build.zig`, dependency integration | System library linking, pkg-config patterns |
| **Mach** | WASM targets | WASM examples, graphics integration | WASM compilation, browser APIs, OpenGL C interop |
| **std lib** | Canonical C interop | `std/c.zig`, `std/wasi.zig`, OS layers | Type definitions, WASI interfaces, syscall wrappers |

### Detailed Analysis Plan

**For Each Project:**
1. Clone/update to latest stable version
2. Review build.zig for C/C++ integration patterns
3. Identify FFI boundaries and ownership contracts
4. Extract representative code snippets
5. Document patterns and anti-patterns
6. Note version-specific behaviors

**Citation Format:**
For each pattern, provide deep GitHub links:
```markdown
[Project: Pattern description](https://github.com/owner/repo/blob/commit/path/to/file.zig#L123-L145)
```

## 7. Key Research Questions

### @cImport and Translation
1. **How does @cImport invoke clang internally?**
   - What flags are passed to clang?
   - How are include paths resolved?
   - What happens to C macros?

2. **What C constructs cannot be translated?**
   - Variadic macros
   - Complex preprocessor logic
   - Inline assembly
   - C99 vs C11 features

3. **How are naming conflicts resolved?**
   - Namespace collision handling
   - Symbol renaming strategies
   - @"symbol name" syntax usage

### Memory and Ownership
4. **What are the ownership rules at FFI boundaries?**
   - Who owns memory allocated by C?
   - How to transfer ownership safely?
   - What are the lifetime guarantees?

5. **How should C strings be handled?**
   - When to use [*:0]u8 vs [*c]u8?
   - How to convert between C strings and Zig slices?
   - What are the null-termination pitfalls?

6. **How to prevent memory leaks across FFI?**
   - Defer patterns for C resources
   - Errdefer for cleanup on errors
   - RAII-like patterns in Zig

### ABI and Types
7. **Why use c_int instead of i32?**
   - Platform-specific size differences
   - ABI compatibility guarantees
   - When can you safely use fixed-size types?

8. **How to handle struct layout differences?**
   - @cStruct annotation
   - Padding and alignment
   - Packed structs vs extern structs

9. **What are the calling convention implications?**
   - When to specify callconv(.C)?
   - Platform-specific variations
   - Inline and naked conventions

### Build System
10. **How to integrate C/C++ source files?**
    - addCSourceFile vs addCSourceFiles
    - Compiler flag management
    - Conditional compilation

11. **How to link external libraries correctly?**
    - Static vs dynamic linking
    - System library dependencies
    - Cross-compilation considerations

12. **How to handle pkg-config dependencies?**
    - Running pkg-config from build.zig
    - Parsing cflags and libs
    - Cross-compilation with pkg-config

### C++ Interoperability
13. **What are the fundamental limitations with C++?**
    - No direct class/template support
    - Name mangling issues
    - Exception handling incompatibility

14. **How to create effective extern "C" bridges?**
    - Wrapper function patterns
    - Opaque type handling
    - Resource management

15. **How to handle C++ exceptions?**
    - Must not cross FFI boundary
    - Catching in C++ wrapper
    - Converting to error codes

### WASM/WASI
16. **How does linear memory affect pointer usage?**
    - Pointers as i32 offsets
    - Memory growth invalidation
    - Bounds checking

17. **What are WASI capability model implications?**
    - Filesystem access restrictions
    - Security boundaries
    - Capability passing

18. **How to handle JavaScript ↔ WASM interaction?**
    - Function imports and exports
    - Memory sharing
    - String encoding (UTF-8 vs UTF-16)

### Version Differences
19. **What changed in FFI between 0.14.x and 0.15+?**
    - @cImport behavior
    - Build system APIs
    - Type definitions

20. **Are there ABI changes between versions?**
    - Binary compatibility
    - C type definitions
    - Export symbol names

## 8. Success Criteria

### Content Quality
- [ ] All major C/C++/WASM interop patterns documented
- [ ] 4-6 runnable, tested examples provided
- [ ] Common pitfalls section with solutions
- [ ] Clear memory safety guidelines
- [ ] Real-world patterns from production projects

### Citations and References
- [ ] 25+ authoritative citations minimum
- [ ] Deep GitHub links to actual code (file + line numbers)
- [ ] Official documentation references
- [ ] Community resource links
- [ ] Version-specific documentation where applicable

### Technical Accuracy
- [ ] All code examples compile on Zig 0.14.1
- [ ] All code examples compile on Zig 0.15.2
- [ ] Examples run without errors
- [ ] Memory safety verified (valgrind/ASan clean)
- [ ] Cross-platform compatibility tested

### Completeness
- [ ] All topics from prompt.md covered
- [ ] @cImport/cInclude fully explained
- [ ] Build integration thoroughly documented
- [ ] C++ interop patterns shown
- [ ] WASM/WASI extensively covered
- [ ] Version differences clearly marked

### Educational Value
- [ ] Clear learning progression (simple → complex)
- [ ] Practical, actionable guidance
- [ ] Pitfall prevention strategies
- [ ] Best practices highlighted
- [ ] Production patterns demonstrated

## 9. Validation and Testing

### Code Example Validation

**For Each Example:**
1. **Compilation Test:**
   ```bash
   # Test on Zig 0.14.1
   /path/to/zig-0.14.1/zig build
   /path/to/zig-0.14.1/zig build test

   # Test on Zig 0.15.2
   /path/to/zig-0.15.2/zig build
   /path/to/zig-0.15.2/zig build test
   ```

2. **Runtime Test:**
   ```bash
   # Run and verify output
   zig build run
   ```

3. **Memory Safety:**
   ```bash
   # For examples with C memory management
   valgrind --leak-check=full ./zig-out/bin/example

   # Or with AddressSanitizer
   zig build -Doptimize=Debug
   ASAN_OPTIONS=detect_leaks=1 ./zig-out/bin/example
   ```

4. **Cross-Platform:**
   ```bash
   # Test cross-compilation
   zig build -Dtarget=x86_64-linux
   zig build -Dtarget=x86_64-windows
   zig build -Dtarget=aarch64-macos
   ```

### WASM-Specific Validation

**Example 5 (WASM JS FFI):**
```bash
# Build WASM
zig build-exe src/main.zig -target wasm32-freestanding -fno-entry -O ReleaseSmall

# Test in Node.js
node web/loader.js

# Test in browser (requires local server)
python3 -m http.server 8000
# Open http://localhost:8000/web/
```

**Example 6 (WASI):**
```bash
# Build WASI
zig build-exe src/main.zig -target wasm32-wasi

# Test with wasmtime
wasmtime --dir=. main.wasm

# Test with wasmer
wasmer run --dir=. main.wasm
```

### Documentation Validation

**Checklist:**
- [ ] All code examples have README.md
- [ ] Build instructions are clear
- [ ] Dependencies are documented
- [ ] Expected output is shown
- [ ] Version compatibility is marked
- [ ] Error cases are explained

### Peer Review Criteria

**Technical Review:**
- [ ] FFI patterns are idiomatic
- [ ] Memory safety is ensured
- [ ] ABI concerns are addressed
- [ ] Build configuration is correct
- [ ] WASM patterns are modern

**Educational Review:**
- [ ] Progression is logical
- [ ] Examples are clear
- [ ] Pitfalls are highlighted
- [ ] Best practices are emphasized
- [ ] References are authoritative

## 10. Common Pitfalls Documentation Plan

### Structure for Pitfalls Section

For each pitfall:
1. **Description:** What the mistake is
2. **Example:** Code showing the incorrect pattern
3. **Problem:** Why it's wrong (undefined behavior, memory leak, etc.)
4. **Solution:** Correct pattern
5. **Detection:** How to catch it (compiler warnings, runtime tools)

### Priority Pitfalls to Document

#### 1. Memory Management Pitfalls

**Pitfall 1.1: Forgetting to Free C Allocations**
```zig
// ❌ Incorrect
const ptr = c.malloc(100);
doSomething(ptr);
// Memory leak!

// ✅ Correct
const ptr = c.malloc(100);
defer c.free(ptr);
doSomething(ptr);
```

**Pitfall 1.2: Use-After-Free with C Pointers**
```zig
// ❌ Incorrect
const ptr = c.malloc(100);
c.free(ptr);
usePointer(ptr); // Use after free!

// ✅ Correct
const ptr = c.malloc(100);
defer c.free(ptr);
usePointer(ptr);
// Free happens after scope ends
```

**Pitfall 1.3: Mixing Zig and C Allocators**
```zig
// ❌ Incorrect
const allocator = std.heap.page_allocator;
const ptr = try allocator.alloc(u8, 100);
c.free(ptr); // Wrong allocator!

// ✅ Correct
const ptr = c.malloc(100);
defer c.free(ptr);
// Use C malloc/free together
```

#### 2. String Handling Pitfalls

**Pitfall 2.1: Missing Null Termination**
```zig
// ❌ Incorrect
const zig_str = "Hello";
_ = c.printf(zig_str.ptr); // Not null-terminated!

// ✅ Correct
const c_str: [*:0]const u8 = "Hello";
_ = c.printf(c_str);
```

**Pitfall 2.2: Incorrect String Type**
```zig
// ❌ Incorrect
fn processString(s: []const u8) void {
    _ = c.strlen(s.ptr); // s may not be null-terminated
}

// ✅ Correct
fn processString(s: [*:0]const u8) void {
    _ = c.strlen(s);
}
```

**Pitfall 2.3: Buffer Overflow with C Strings**
```zig
// ❌ Incorrect
var buf: [10]u8 = undefined;
_ = c.sprintf(&buf, "Very long string %d", 12345);
// Buffer overflow!

// ✅ Correct
var buf: [100]u8 = undefined;
_ = c.snprintf(&buf, buf.len, "Very long string %d", 12345);
// Or use Zig's std.fmt
```

#### 3. Type Mismatch Pitfalls

**Pitfall 3.1: Using Fixed-Size Types Instead of C Types**
```zig
// ❌ Incorrect (may break on some platforms)
extern fn processInt(x: i32) void;
// On some platforms, int is 16-bit or 64-bit

// ✅ Correct
extern fn processInt(x: c_int) void;
```

**Pitfall 3.2: Pointer Type Confusion**
```zig
// ❌ Incorrect
extern fn cFunction(ptr: [*]u8) void;
// C expects potentially-null pointer

// ✅ Correct
extern fn cFunction(ptr: [*c]u8) void;
// [*c] allows null and is C-compatible
```

**Pitfall 3.3: Struct Layout Mismatches**
```zig
// ❌ Incorrect
const MyStruct = struct {
    a: u8,
    b: u32, // Zig may add padding differently than C
};

// ✅ Correct
const MyStruct = extern struct {
    a: u8,
    b: u32, // Uses C ABI layout rules
};
```

#### 4. Build Configuration Pitfalls

**Pitfall 4.1: Forgetting linkLibC**
```zig
// build.zig
// ❌ Incorrect
exe.addCSourceFiles(.{ .files = &.{"lib.c"} });
// Will fail to link C standard library

// ✅ Correct
exe.addCSourceFiles(.{ .files = &.{"lib.c"} });
exe.linkLibC();
```

**Pitfall 4.2: Incorrect Include Paths**
```zig
// ❌ Incorrect
// @cImport fails because headers not found

// ✅ Correct
// In build.zig:
exe.addIncludePath(b.path("c_lib/include"));
```

**Pitfall 4.3: Missing System Library**
```zig
// ❌ Incorrect
exe.linkLibC();
// Missing: exe.linkSystemLibrary("sqlite3");

// ✅ Correct
exe.linkLibC();
exe.linkSystemLibrary("sqlite3");
```

#### 5. WASM-Specific Pitfalls

**Pitfall 5.1: Pointer Invalidation on Memory Growth**
```zig
// ❌ Incorrect
const ptr = allocate(100);
growMemory(); // Pointer may now be invalid!
usePointer(ptr); // May be wrong location

// ✅ Correct
// Reallocate or use offsets instead of raw pointers
const offset = allocateOffset(100);
growMemory();
const ptr = getPointerFromOffset(offset);
```

**Pitfall 5.2: Incorrect String Encoding for JavaScript**
```zig
// ❌ Incorrect
// Passing raw bytes without UTF-8 validation

// ✅ Correct
// Ensure UTF-8 validity or handle encoding explicitly
try std.unicode.utf8ValidateSlice(string);
```

**Pitfall 5.3: Exceeding Linear Memory**
```zig
// ❌ Incorrect
const huge = allocate(100_000_000); // May exceed WASM memory

// ✅ Correct
// Check memory limits and grow if needed
if (needMoreMemory()) {
    _ = @wasmMemoryGrow(0, pages_needed);
}
```

### Detection and Debugging

**For Each Pitfall Category:**

1. **Compiler Warnings:**
   - Enable all warnings: `-Wall`
   - Treat warnings as errors in CI

2. **Runtime Tools:**
   - Valgrind for memory leaks
   - AddressSanitizer for use-after-free
   - UndefinedBehaviorSanitizer for UB

3. **Static Analysis:**
   - Zig's built-in checks
   - Review safety annotations

4. **Testing:**
   - Unit tests for FFI boundary code
   - Fuzz testing for string handling
   - Cross-platform CI for type size issues

## 11. Timeline and Milestones

### Week 1: Research and Documentation Foundation

**Days 1-2: Official Documentation and Core Concepts**
- Phase 1: Official documentation review (1-2 hours)
- Establish baseline knowledge
- Create type mapping reference

**Days 3-4: Reference Project Analysis**
- Phase 2: Ghostty analysis (2-3 hours)
- Phase 3: Bun analysis (2-3 hours)
- Phase 4: TigerBeetle analysis (1-2 hours)

**Day 5: WASM/WASI Research**
- Phase 5: WASM/WASI patterns (2-3 hours)
- Collect WASM examples

**Milestone 1: Research notes foundation complete**

### Week 2: Example Development and Content Creation

**Days 1-2: Core Examples**
- Example 1: Basic C interop (1 hour)
- Example 2: sqlite3 integration (2 hours)
- Example 3: Build integration (1 hour)

**Days 3-4: Advanced Examples**
- Example 4: C++ bridge (2 hours)
- Example 5: WASM JS FFI (2 hours)
- Example 6: WASI filesystem (1 hour)

**Day 5: Pitfalls and Synthesis**
- Phase 7: Common pitfalls (2-3 hours)
- Phase 8: research_notes.md synthesis (2-3 hours)

**Milestone 2: All examples complete and tested**

### Week 3: Content Writing and Review

**Days 1-3: Content Writing**
- Write content.md (1000-1500 lines)
- Integrate all examples
- Add citations (25+ minimum)

**Days 4-5: Review and Refinement**
- Technical review
- Test all code on both versions
- Validate citations
- Proofread and polish

**Milestone 3: Chapter complete and ready for publication**

### Total Estimated Time: 25-35 hours

## 12. Deliverables Checklist

### Research Phase Deliverables
- [X] research_plan.md (this document)
- [ ] research_notes.md (800-1000 lines, 25+ citations)
- [ ] Type mapping reference table
- [ ] Pattern catalog from reference projects
- [ ] Common pitfalls documentation

### Code Example Deliverables
- [ ] Example 1: Basic C interop (complete with README)
- [ ] Example 2: sqlite3 integration (complete with README)
- [ ] Example 3: Build integration (complete with README)
- [ ] Example 4: C++ bridge (complete with README)
- [ ] Example 5: WASM JS FFI (complete with README + HTML)
- [ ] Example 6: WASI filesystem (complete with README)

### Final Content Deliverables
- [ ] content.md (1000-1500 lines minimum)
- [ ] All examples tested on 0.14.1 and 0.15.2
- [ ] 25+ authoritative citations
- [ ] Version markers (✅ 0.15+ / 🕐 0.14.x) where applicable
- [ ] Complete References section

### Quality Assurance
- [ ] All code compiles without warnings
- [ ] Memory safety verified
- [ ] Cross-platform compatibility tested
- [ ] Documentation clarity review
- [ ] Citation accuracy verified

---

## Notes for Execution

When executing this research plan:

1. **Start with official docs** to establish authoritative baseline
2. **Focus on memory safety** throughout - this is the critical concern for FFI
3. **Prioritize practical patterns** over theoretical completeness
4. **Cite deeply** - link to specific files and line numbers in production code
5. **Test rigorously** - all examples must be runnable and safe
6. **Document pitfalls** - prevention is as important as instruction
7. **Consider both versions** - mark differences clearly
8. **Think about WASM** - it's fundamentally different from native FFI

The goal is not just to explain *how* FFI works, but to teach *safe, maintainable patterns* for production code.

---

**Status:** Planning complete, ready for execution
**Next Step:** Begin Phase 1 (Official Documentation Review)
