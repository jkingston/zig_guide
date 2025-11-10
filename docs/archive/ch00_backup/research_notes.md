# Research Notes: Real Zig Project Structures

This document contains research notes on how major Zig projects structure their codebases.
These notes will be used to write Section 0.2 of Chapter 0.

## Projects Analyzed

1. Zig Compiler (https://github.com/ziglang/zig)
2. TigerBeetle (https://github.com/tigerbeetle/tigerbeetle)
3. ZLS (https://github.com/zigtools/zls)
4. Bun (https://github.com/oven-sh/bun)
5. Ghostty (https://github.com/ghostty-org/ghostty)
6. Mach Engine (https://github.com/hexops/mach)

## Methodology

For each project, we analyze:
- Directory structure
- File naming conventions
- Module organization
- Build system patterns
- Test organization
- Documentation structure
- CI/CD setup

---

## 1. Zig Compiler

**Repository:** https://github.com/ziglang/zig
**Type:** Compiler / Language Implementation
**Size:** 300K+ LOC
**Dependencies:** LLVM, LLD, Clang (bundled)

### Directory Structure

```
zig/
├── build.zig                # Bootstrap build system
├── build.zig.zon            # Minimal dependencies
├── src/
│   ├── main.zig             # Compiler entry point
│   ├── Compilation.zig      # Core compilation orchestration
│   ├── Sema.zig             # Semantic analysis
│   ├── AstGen.zig           # AST generation
│   ├── Zir.zig              # Zig IR
│   ├── Air.zig              # Analyzed IR
│   ├── codegen/             # Backend code generation
│   │   ├── llvm.zig
│   │   ├── c.zig
│   │   └── spirv/
│   ├── link/                # Linker backends
│   │   ├── Elf.zig
│   │   ├── MachO.zig
│   │   ├── Coff.zig
│   │   └── Wasm.zig
│   ├── arch/                # Architecture-specific code
│   │   ├── x86_64/
│   │   ├── aarch64/
│   │   └── wasm32/
│   └── std/                 # Standard library source
├── lib/                     # C libraries bundled with Zig
├── test/
│   ├── behavior/            # Language behavior tests
│   ├── cases/               # Compilation test cases
│   └── standalone/          # Standalone project tests
└── tools/
    └── process_headers.zig  # Build-time code generation
```

### Key Patterns

1. **Single-file types with PascalCase**
   - `Compilation.zig` exports a single `Compilation` struct
   - `Sema.zig` exports a single `Sema` struct
   - Makes it easy to find where types are defined

2. **Subdirectories for subsystems**
   - `codegen/` contains all code generation backends
   - `link/` contains all linker implementations
   - `arch/` contains architecture-specific code

3. **Test organization by type**
   - `behavior/` tests language semantics
   - `cases/` tests compilation scenarios
   - `standalone/` tests complete project builds

4. **Minimal dependencies**
   - Only LLVM/Clang (for compilation)
   - Everything else is self-hosted in Zig

5. **Build-time code generation**
   - `tools/` contains utilities that run during build
   - Generates headers, processes C libraries

### Naming Conventions

- **PascalCase.zig** - Files that export a single struct/type
  - Example: `Compilation.zig`, `Sema.zig`, `Module.zig`
- **snake_case.zig** - Module files
  - Example: `main.zig`, `build_runner.zig`
- **Directories** - Always lowercase with underscore
  - Example: `codegen/`, `link/`, `x86_64/`

### Why This Works

- Clear separation between compiler stages (parsing → analysis → codegen → linking)
- Each backend is isolated and can be developed independently
- Large codebase remains navigable
- Tests are organized by what they test, not where code lives

---

## 2. TigerBeetle

**Repository:** https://github.com/tigerbeetle/tigerbeetle
**Type:** Distributed Database
**Size:** 100K+ LOC
**Dependencies:** None (zero external deps!)

### Directory Structure

```
tigerbeetle/
├── build.zig                # Complex build with multiple targets
├── build.zig.zon            # No dependencies!
├── src/
│   ├── tigerbeetle/
│   │   ├── main.zig         # Server entry point
│   │   └── client.zig       # Client library
│   ├── vsr.zig              # Viewstamped Replication core
│   ├── lsm/                 # Log-Structured Merge tree
│   │   ├── tree.zig
│   │   ├── manifest.zig
│   │   └── compaction.zig
│   ├── storage.zig          # Storage engine interface
│   ├── io.zig               # Async I/O abstraction
│   ├── clients/             # Language bindings
│   │   ├── c/
│   │   ├── java/
│   │   ├── node/
│   │   └── dotnet/
│   ├── simulator.zig        # Deterministic simulator
│   └── shell.zig            # Interactive REPL
├── docs/
│   ├── DESIGN.md
│   ├── PROTOCOL.md
│   └── INTERNALS.md
└── scripts/
```

### Key Patterns

1. **Zero external dependencies**
   - Everything implemented from scratch
   - Full control over every line of code
   - Critical for correctness and determinism

2. **Simulator-first development**
   - `simulator.zig` enables deterministic testing
   - Can replay exact scenarios
   - Finds bugs that traditional testing misses

3. **Language bindings co-located**
   - Client libraries for other languages in same repo
   - Ensures consistency across platforms
   - Single source of truth

4. **Extensive documentation**
   - Design documents explain the "why"
   - Protocol specs for implementation details
   - Internals docs for contributors

5. **Storage subsystem isolation**
   - `lsm/` is completely self-contained
   - Can be tested independently
   - Clear interface boundaries

### Build System

The `build.zig` is extensive and includes:
- Server executable
- Client library (static and shared)
- Language bindings (JNI, Node native modules)
- Simulator
- Fuzz testing infrastructure
- Benchmarking tools

### Why This Works

- Zero dependencies = maximum control and predictability
- Simulator enables exhaustive testing of distributed scenarios
- Multi-language clients in one repo ensure consistency
- Performance-critical code is transparent (no hidden deps)

---

## 3. ZLS (Zig Language Server)

**Repository:** https://github.com/zigtools/zls
**Type:** Language Server / Developer Tool
**Size:** 50K+ LOC
**Dependencies:** known-folders, diffz, tracy

### Directory Structure

```
zls/
├── build.zig
├── build.zig.zon            # Has dependencies (known-folders, diffz)
├── src/
│   ├── main.zig             # LSP server entry point
│   ├── Server.zig           # LSP message handling
│   ├── DocumentStore.zig    # Manages open files
│   ├── analysis.zig         # Code analysis
│   ├── semantic_tokens.zig  # Syntax highlighting
│   ├── completions.zig      # Autocomplete
│   ├── goto.zig             # Go-to-definition
│   ├── references.zig       # Find references
│   ├── hover.zig            # Hover documentation
│   ├── signature_help.zig   # Function signatures
│   ├── inlay_hints.zig      # Inline type hints
│   ├── Config.zig           # Configuration management
│   └── types.zig            # Shared type definitions
├── tests/
│   ├── utility/
│   ├── lsp_features/        # Feature-specific tests
│   └── toolchains/          # Multi-version Zig testing
├── schema.json              # Config schema for editors
└── .github/
    └── workflows/
        ├── ci.yml
        ├── release.yml
        └── zig_nightly.yml  # Test against Zig nightlies
```

### Key Patterns

1. **Feature per file**
   - `completions.zig` - All autocomplete logic
   - `hover.zig` - All hover functionality
   - `goto.zig` - All go-to-definition logic
   - Makes features easy to locate

2. **Core types extracted**
   - `Server.zig` - Main LSP server struct
   - `DocumentStore.zig` - Document management
   - `Config.zig` - Configuration
   - Clear separation of concerns

3. **Multi-version compatibility**
   - Must support Zig 0.11, 0.12, 0.13, 0.14, 0.15
   - Tests run against all supported versions
   - Uses conditional compilation

4. **Schema-driven configuration**
   - `schema.json` defines all config options
   - Editors can validate `.zls.json`
   - Single source of truth

5. **External dependencies are OK**
   - `known-folders` for cross-platform paths
   - `diffz` for testing
   - `tracy` for profiling
   - Stable, well-maintained deps

### Configuration

Example `.zls.json`:
```json
{
  "enable_autofix": true,
  "enable_snippets": true,
  "warn_style": true,
  "semantic_tokens": "full"
}
```

Validated against `schema.json` by editors.

### Why This Works

- LSP features map 1:1 to files (easy navigation)
- Multi-version support is critical for dev tools
- Schema-first config prevents configuration errors
- Clear separation: analysis vs LSP protocol

---

## 4. Bun

**Repository:** https://github.com/oven-sh/bun
**Type:** JavaScript Runtime (Zig + C++ + JavaScript)
**Size:** 500K+ LOC (mixed languages)
**Dependencies:** JavaScriptCore (C++), many C libraries

### Directory Structure

```
bun/
├── build.zig                # Zig portions
├── CMakeLists.txt           # C++ portions (JavaScriptCore)
├── package.json             # JS bundler
├── src/
│   ├── main.zig             # Entry point orchestration
│   ├── bun.js/              # JavaScript runtime (C++)
│   │   ├── bindings/        # Zig ↔ C++ FFI
│   │   ├── modules/         # Node.js compatibility
│   │   └── webcore/
│   ├── deps/
│   │   ├── picohttp.zig     # HTTP parser (Zig)
│   │   ├── mimalloc/        # Memory allocator (C)
│   │   └── zstd/            # Compression (C)
│   ├── cli/                 # CLI commands (Zig)
│   │   ├── init.zig
│   │   ├── run.zig
│   │   └── install.zig
│   ├── install/             # Package manager (Zig)
│   │   ├── lockfile.zig
│   │   └── resolver.zig
│   └── bundler/             # JavaScript bundler (Zig + C++)
├── test/
│   ├── js/                  # JavaScript test suites
│   ├── bun/                 # Zig tests
│   └── integration/
└── scripts/
```

### Key Patterns

1. **Hybrid build system**
   - `build.zig` for Zig code
   - `CMakeLists.txt` for C++ code
   - Coordinates between both

2. **Clear language boundaries**
   - Zig: CLI, package manager, HTTP parsing
   - C++: JavaScript engine (JavaScriptCore)
   - Each language does what it's best at

3. **FFI layer isolated**
   - `bindings/` directory for cross-language calls
   - Prevents FFI code from spreading everywhere
   - Clear interfaces

4. **Performance-critical paths in Zig**
   - HTTP parsing
   - Package manager
   - File system operations
   - Zig is faster than JavaScript, safer than C++

5. **Vendored C dependencies**
   - `deps/` contains all C libraries
   - Full control over versions
   - Reproducible builds

### Interop Example

```zig
// src/bun.js/bindings/exports.zig
pub export fn Bun__fetch(
    ctx: *JSContext,
    url: [*:0]const u8,
    options: *FetchOptions,
) JSValue {
    // Zig calls into C++ JavaScriptCore
}
```

### Why This Works

- Reuses mature JavaScriptCore for JS execution
- Writes performance-critical code in Zig
- Clear boundaries prevent "FFI spaghetti"
- Each language handles its strength

---

## 5. Ghostty

**Repository:** https://github.com/ghostty-org/ghostty
**Type:** Terminal Emulator (GUI Application)
**Size:** 80K+ LOC
**Dependencies:** GTK (Linux), Cocoa (macOS), various font libraries

### Directory Structure

```
ghostty/
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig
│   ├── App.zig              # Application state
│   ├── terminal/            # Terminal emulation (platform-agnostic)
│   │   ├── Terminal.zig
│   │   ├── Screen.zig
│   │   ├── parser.zig       # VT100/ANSI parser
│   │   └── color.zig
│   ├── renderer/            # GPU rendering (platform-specific)
│   │   ├── metal.zig        # macOS Metal
│   │   ├── opengl.zig       # Linux/Windows OpenGL
│   │   └── software.zig     # Fallback
│   ├── font/                # Font rendering
│   │   ├── face.zig
│   │   ├── shaper.zig       # HarfBuzz integration
│   │   └── rasterizer.zig   # FreeType integration
│   ├── gui/                 # Platform UI
│   │   ├── gtk/             # Linux (GTK)
│   │   ├── cocoa/           # macOS (AppKit)
│   │   └── windows/         # Windows
│   ├── config/
│   │   ├── Config.zig
│   │   └── parser.zig
│   └── pty/                 # Pseudo-terminal
│       ├── unix.zig
│       └── windows.zig
├── test/
└── assets/
```

### Key Patterns

1. **Platform abstraction**
   - Core terminal emulation is platform-agnostic
   - Platform-specific code in subdirectories
   - Clean separation

2. **Core is portable**
   - `terminal/` works on all platforms
   - Parser, screen buffer, color handling
   - Can test independently

3. **Multiple renderer backends**
   - Metal on macOS (best performance)
   - OpenGL on Linux/Windows
   - Software fallback
   - Selected at compile time

4. **C library integration**
   - HarfBuzz for text shaping
   - FreeType for font rasterization
   - GTK, Cocoa for native UI
   - Uses `@cImport` and linking

5. **Config as code**
   - Zig-based configuration
   - Type-safe, validated at compile time

### Platform Selection in build.zig

```zig
const renderer = switch (target.os.tag) {
    .macos => "metal",
    .linux => "opengl",
    .windows => "opengl",
    else => "software",
};
```

### Why This Works

- Terminal core separated from rendering/UI
- Each platform gets native performance
- Clear boundaries for cross-platform code
- Easy to add new renderers/platforms

---

## 6. Mach Engine

**Repository:** https://github.com/hexops/mach
**Type:** Game Engine / Framework
**Size:** 40K+ LOC (modular)
**Dependencies:** glfw, freetype, opus (as submodules)

### Directory Structure

```
mach/
├── build.zig
├── build.zig.zon            # Modular dependencies
├── src/
│   ├── core/                # Core engine (minimal)
│   │   ├── Core.zig
│   │   └── module.zig
│   ├── gfx/                 # Graphics module
│   │   ├── gfx.zig
│   │   └── sprite.zig
│   ├── audio/               # Audio module
│   ├── ecs/                 # Entity Component System
│   │   ├── entities.zig
│   │   ├── components.zig
│   │   └── systems.zig
│   └── sysaudio/            # System audio backends
│       ├── wasapi.zig       # Windows
│       ├── coreaudio.zig    # macOS
│       └── pulseaudio.zig   # Linux
├── examples/                # Extensive examples
│   ├── core/
│   │   ├── triangle/
│   │   ├── textured-cube/
│   │   └── fractal/
│   ├── gfx/
│   └── audio/
└── libs/                    # Git submodules for C deps
```

### Key Patterns

1. **Modular architecture**
   - Can use just `core` without graphics
   - Can add `gfx` for 2D/3D rendering
   - Can add `audio` separately
   - Pick what you need

2. **Example-driven development**
   - Every feature has example code
   - Examples are tested in CI
   - Serves as documentation

3. **Composable modules**
   - Each module is independent
   - Declared in `build.zig.zon`
   - Users can depend on specific modules

4. **C dependencies as submodules**
   - Git submodules for exact versions
   - Reproducible builds
   - No system dependencies

5. **Cross-platform by default**
   - Uses WebGPU abstraction
   - Works on desktop, web (WASM), mobile
   - Platform code isolated in subdirs

### Module System

```zig
// build.zig.zon
.{
    .name = "mach",
    .version = "0.3.0",
    .dependencies = .{
        .mach_core = .{ .path = "src/core" },
        .mach_gfx = .{ .path = "src/gfx" },
        .mach_audio = .{ .path = "src/audio" },
    },
}
```

Users pick modules:
```zig
// User's build.zig.zon
.dependencies = .{
    .mach_core = .{ .url = "..." },  // Just core
    // or
    .mach = .{ .url = "..." },       // Everything
}
```

### Why This Works

- Game engines need modularity
- Examples show real usage patterns
- WebGPU abstraction = truly cross-platform
- Git submodules = reproducible C dependencies

---

## Common Patterns Matrix

| Pattern | Zig | TigerBeetle | ZLS | Bun | Ghostty | Mach |
|---------|-----|-------------|-----|-----|---------|------|
| **PascalCase.zig for types** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Feature directories** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Tests mirror src/** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Platform-specific subdirs** | ✅ | ✅ | ⚫ | ✅ | ✅ | ✅ |
| **Minimal dependencies** | ✅ | ✅ | ⚫ | ⚫ | ⚫ | ⚫ |
| **C interop layer** | ✅ | ⚫ | ⚫ | ✅ | ✅ | ✅ |
| **Extensive CI** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Examples in repo** | ✅ | ✅ | ⚫ | ✅ | ⚫ | ✅ |

Legend: ✅ Present | ⚫ Not applicable or minimal

---

## Anti-Patterns Observed

These are patterns we did NOT see in successful projects:

❌ **Deep nesting** - No project has `src/lib/core/internal/impl/utils/`
✅ **Instead:** Flatten structure, use clear names

❌ **Mixed naming** - No project mixes `myModule.zig` and `OtherMod.zig`
✅ **Instead:** Consistent PascalCase for types, snake_case for modules

❌ **God files** - No `utils.zig` with thousands of lines
✅ **Instead:** Split by domain: `string_utils.zig`, `math_utils.zig`

❌ **Circular deps** - Projects avoid module A imports B imports A
✅ **Instead:** Extract shared types to separate file

❌ **Scattered platform code** - Platform specifics are isolated
✅ **Instead:** `platform/windows/`, `platform/linux/`, etc.

❌ **Tests far from code** - Tests mirror source structure exactly
✅ **Instead:** `src/foo.zig` → `test/foo.zig`

---

## Key Takeaways for Chapter 0

1. **File Naming**
   - PascalCase.zig exports a single struct
   - snake_case.zig is a module
   - Directories are lowercase with underscores

2. **Organization**
   - Directories represent subsystems
   - Platform-specific code in subdirectories
   - Tests mirror source structure

3. **Dependencies**
   - Minimize external dependencies when possible
   - Use git submodules for C libraries (reproducibility)
   - Document all dependencies in build.zig.zon

4. **Build System**
   - Keep complexity in build.zig (not shell scripts)
   - Support cross-compilation from the start
   - Provide separate steps for different test types

5. **Testing**
   - Unit tests co-located with code
   - Integration tests in separate directory
   - Test against multiple Zig versions if needed

6. **Documentation**
   - README for getting started
   - ARCHITECTURE for detailed design
   - CONTRIBUTING for development guidelines
   - Examples show real usage

7. **CI/CD**
   - Test on all target platforms
   - Check formatting automatically
   - Automate releases
   - Cache build artifacts

These patterns will inform how we structure zighttp and explain project organization in Chapter 0.
