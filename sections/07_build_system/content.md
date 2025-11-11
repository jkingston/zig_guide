# Build System (build.zig)

> **TL;DR for build.zig:**
> - **Entry point:** `pub fn build(b: *std.Build) void` (runs at build time)
> - **0.15 breaking:** Must use `root_module` with `b.createModule()`, not `root_source_file`
> - **Common artifacts:** `b.addExecutable()`, `b.addStaticLibrary()`, `b.addTest()`
> - **Cross-compile:** `zig build -Dtarget=aarch64-linux` (any target from any host)
> - **Dependencies:** Managed via `build.zig.zon` (fetch from Git/HTTP)
> - **Jump to:** [Basic structure §7.2](#build-function-entry-point) | [Modules §7.3](#module-system-015) | [Dependencies §7.5](#dependencies-and-packages)

## Overview

The Zig build system provides deterministic, cross-platform project configuration through executable Zig code. Unlike declarative build tools (Make, CMake) or DSL-based systems (Gradle, Bazel), `build.zig` is a Zig program that runs at build time, compiling artifacts, running tests, and orchestrating multi-step build processes.

This chapter explains idiomatic `build.zig` patterns, the module system introduced in Zig 0.15, custom build steps, and multi-target compilation. Understanding these patterns is essential for structuring libraries, CLI tools, and complex multi-artifact projects.

## Core Concepts

### Build Function Entry Point

Every `build.zig` file exports a `build` function that receives a `*std.Build` allocator and configuration context:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);
}
```

**Key elements:**

- **`b.standardTargetOptions()`** — Parses `-Dtarget` from command line, defaults to native
- **`b.standardOptimizeOption()`** — Parses `-Doptimize`, defaults to Debug
- **`b.addExecutable()`** — Creates an executable compilation unit
- **`b.installArtifact()`** — Marks artifact for installation to `zig-out/bin/`

The build function runs every time you invoke `zig build`, configuring what gets compiled.[^1]

### Target and Optimization Modes

Zig supports cross-compilation from any platform to any target. The build system exposes this through target queries and optimization modes:

**Common targets** (format: `arch-os-abi`):

| Target | Architecture | OS | ABI | Use Case |
|--------|--------------|----|----|----------|
| `native` | Current machine | Auto-detected | Auto | Development builds |
| `x86_64-linux-gnu` | x86_64 | Linux | GNU libc | Linux servers, desktop |
| `x86_64-linux-musl` | x86_64 | Linux | musl libc | Static Linux binaries |
| `aarch64-macos` | ARM64 | macOS | none | Apple Silicon Macs |
| `x86_64-windows` | x86_64 | Windows | none | Windows desktop |
| `wasm32-wasi` | WebAssembly | WASI | none | Server-side WASM |
| `wasm32-freestanding` | WebAssembly | None | none | Browser WASM |

**Optimization modes:**

| Mode | Optimizations | Safety Checks | Debug Info | Best For | Binary Size | Production Use |
|------|---------------|---------------|------------|----------|-------------|----------------|
| `Debug` | None | ✅ Enabled | ✅ Full | Development, debugging | Largest | Dev only |
| `ReleaseSafe` | ✅ -O3 | ✅ Enabled | Minimal | Production (recommended) | Medium | ZLS, Ghostty |
| `ReleaseFast` | ✅ -O3 | ❌ Disabled | None | Performance-critical | Medium | TigerBeetle |
| `ReleaseSmall` | ✅ -Os | ❌ Disabled | None | Embedded, WASM | Smallest | Embedded systems |

Users specify targets at build time:

```bash
$ zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast
```

Your `build.zig` should always use `standardTargetOptions()` and `standardOptimizeOption()` to respect user choices.[^2]

### Module System (0.15+)

Zig 0.15 introduced an explicit module system replacing the older package paths. Every compilation unit (executable, library, test) has a root module that defines its source file, target, optimization level, and dependencies.

**Creating modules:**

```zig
// Public module for library users
const lib_mod = b.addModule("mathlib", .{
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});

// Internal module for executable
const exe_mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .imports = &.{
        .{ .name = "mathlib", .module = lib_mod },
    },
});
```

**Key differences:**

- `b.addModule()` — Creates a named module that can be imported by dependents
- `b.createModule()` — Creates an unnamed module for internal use
- `.imports` — Array of name-module pairs for dependencies

Modules are the primary abstraction for dependency management in modern Zig builds.[^3]

### Build Steps

Build steps define tasks that can be executed with `zig build <step>`. Common built-in steps:

- `install` — Default step, installs artifacts to `zig-out/`
- `test` — Run unit tests
- `run` — Execute an artifact

**Defining custom steps:**

```zig
const run_step = b.step("run", "Run the application");
const run_cmd = b.addRunArtifact(exe);
run_step.dependOn(&run_cmd.step);
```

This creates a `zig build run` command that executes the compiled binary. The `dependOn()` method establishes execution order—`run_cmd` must complete before `run_step` is considered done.[^4]

### Build Options

Build options provide compile-time configuration, enabling conditional compilation and version information:

```zig
const enable_logging = b.option(bool, "logging", "Enable debug logging") orelse false;

const build_options = b.addOptions();
build_options.addOption(bool, "enable_logging", enable_logging);
build_options.addOption([]const u8, "version", "1.0.0");

exe.root_module.addOptions("build_options", build_options);
```

**In source code:**

```zig
const build_options = @import("build_options");

pub fn main() void {
    if (build_options.enable_logging) {
        std.log.info("Version: {s}", .{build_options.version});
    }
}
```

**Usage:**

```bash
$ zig build -Dlogging=true
```

Options are resolved at build time and compiled into the binary, enabling zero-cost abstractions.[^5]

### Custom Build Steps

Custom steps extend the build system with code generation, asset processing, or external tool invocation:

```zig
// Code generator executable (runs on host)
const gen_exe = b.addExecutable(.{
    .name = "codegen",
    .root_module = b.createModule(.{
        .root_source_file = b.path("tools/gen.zig"),
        .target = b.graph.host, // Build for host, not target
        .optimize = .Debug,
    }),
});

// Run the generator
const gen_run = b.addRunArtifact(gen_exe);
gen_run.addArg("--output");
const generated_file = gen_run.addOutputFileArg("generated.zig");

// Use generated file in main executable
exe.root_module.addAnonymousImport("generated", .{
    .root_source_file = generated_file,
});
```

**Key patterns:**

- **Host target** — `b.graph.host` ensures tools build for the build machine, not the target architecture
- **Output files** — `addOutputFileArg()` captures stdout or writes to a file in the cache
- **Anonymous imports** — Integrate generated code without naming the module

This pattern is common for code generation, protocol buffer compilation, or asset embedding.[^6]

## Code Examples

### Example 1: Simple Executable

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

**Key teaching points:**

- **Standard options pattern** — Always use `standardTargetOptions()` and `standardOptimizeOption()`
- **Install dependency** — `run_cmd` depends on install step, ensuring binary exists
- **Argument forwarding** — `b.args` passes arguments after `--` to the executable: `zig build run -- --flag value`

This pattern matches the official `zig init` template and is the foundation for all Zig projects.[^7]

### Example 2: Library with Executable

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module
    const lib_mod = b.addModule("mathlib", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Executable using library
    const exe = b.addExecutable(.{
        .name = "calculator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mathlib", .module = lib_mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Tests for library
    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);

    // Run step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
```

**Key teaching points:**

- **Module separation** — Library is a named module, executable imports it
- **Import wiring** — `.imports` array connects modules declaratively
- **Testing pattern** — `addTest()` reuses the library module for testing

**Usage:**

```bash
$ zig build test           # Run tests
$ zig build run            # Run executable
$ zig build --help         # See available options
```

This pattern is common for libraries that include example programs or CLI frontends.[^8]

### Example 3: Build Options

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // User-configurable options
    const enable_logging = b.option(bool, "logging", "Enable debug logging") orelse false;
    const max_connections = b.option(u32, "max-connections", "Maximum connections") orelse 100;

    // Build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "enable_logging", enable_logging);
    build_options.addOption(u32, "max_connections", max_connections);
    build_options.addOption([]const u8, "version", "1.0.0");

    const exe = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "build_options", .module = build_options.createModule() },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the server");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
```

**In `src/main.zig`:**

```zig
const std = @import("std");
const build_options = @import("build_options");

pub fn main() void {
    std.debug.print("Server version: {s}\n", .{build_options.version});
    std.debug.print("Max connections: {}\n", .{build_options.max_connections});

    if (build_options.enable_logging) {
        std.debug.print("[DEBUG] Logging enabled\n", .{});
    }
}
```

**Usage:**

```bash
$ zig build run                                    # Default values
$ zig build run -Dlogging=true -Dmax-connections=500  # Override
$ zig build --help                                  # Lists all options
```

**Key teaching points:**

- **Default values** — `orelse` provides fallback when option not specified
- **Type safety** — Options are strongly typed (bool, u32, []const u8)
- **Discoverability** — `--help` automatically documents custom options

This pattern is widespread in Zig projects for feature flags, version strings, and configuration.[^9]

### Example 4: Custom Build Step (Code Generation)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Code generator executable (runs on host)
    const gen_exe = b.addExecutable(.{
        .name = "codegen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/gen.zig"),
            .target = b.graph.host, // Build for host system
            .optimize = .Debug,
        }),
    });

    // Run the generator
    const gen_run = b.addRunArtifact(gen_exe);
    gen_run.addArg("--output");
    const generated_file = gen_run.addOutputFileArg("generated.zig");

    // Main executable using generated code
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add generated file as anonymous import
    exe.root_module.addAnonymousImport("generated", .{
        .root_source_file = generated_file,
    });

    b.installArtifact(exe);
}
```

**Code generator (`tools/gen.zig`):**

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // program name

    var output_path: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--output")) {
            output_path = args.next();
        }
    }

    const path = output_path orelse return error.MissingOutputPath;

    const code =
        \\// Auto-generated file - do not edit
        \\pub const magic_number: u32 = 42;
        \\pub const greeting = "Hello from generated code!";
        \\
    ;

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(code);
}
```

**Key teaching points:**

- **Host vs target** — Generator builds for `b.graph.host`, ensuring it runs on the build machine even when cross-compiling
- **Output file capture** — `addOutputFileArg()` provides a path in the cache directory
- **Anonymous imports** — Generated code doesn't need a module name
- **Automatic dependencies** — Build system tracks that `exe` depends on `gen_run`

This pattern is common in TigerBeetle (client code generation), ZLS (syntax generation), and many other projects.[^10]

### Example 5: Multi-Target Build

```zig
const std = @import("std");

const ReleaseTarget = struct {
    arch: std.Target.Cpu.Arch,
    os: std.Target.Os.Tag,
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const release_targets = [_]ReleaseTarget{
        .{ .arch = .x86_64, .os = .linux },
        .{ .arch = .x86_64, .os = .windows },
        .{ .arch = .aarch64, .os = .linux },
        .{ .arch = .aarch64, .os = .macos },
    };

    const release_step = b.step("release", "Build for all release targets");

    for (release_targets) |rt| {
        const target = b.resolveTargetQuery(.{
            .cpu_arch = rt.arch,
            .os_tag = rt.os,
        });

        const exe = b.addExecutable(.{
            .name = b.fmt("myapp-{s}-{s}", .{
                @tagName(rt.arch),
                @tagName(rt.os),
            }),
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        const install = b.addInstallArtifact(exe, .{});
        release_step.dependOn(&install.step);
    }

    // Default single-target build
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);
}
```

**Usage:**

```bash
$ zig build release    # Builds all 4 targets
$ zig build            # Builds for current platform
```

**Output:**

```
zig-out/bin/
├── myapp
├── myapp-x86_64-linux
├── myapp-x86_64-windows.exe
├── myapp-aarch64-linux
└── myapp-aarch64-macos
```

**Key teaching points:**

- **Target queries** — `resolveTargetQuery()` creates target from arch/OS pair
- **Name formatting** — `b.fmt()` generates unique names per target
- **Parallel builds** — Each target builds independently, can run in parallel
- **Custom steps** — `release` step coordinates all targets

This pattern is common in projects like Ghostty and ZLS for generating release artifacts.[^11]

### Example 6: Test Configuration

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match filter",
    ) orelse &.{};

    // Library module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Unit tests
    const unit_tests = b.addTest(.{
        .name = "unit-tests",
        .root_module = lib_mod,
        .filters = test_filters,
    });

    // Integration tests
    const integration_tests = b.addTest(.{
        .name = "integration-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/integration.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .filters = test_filters,
    });

    // Test steps
    const test_step = b.step("test", "Run all tests");
    const unit_step = b.step("test:unit", "Run unit tests");
    const integration_step = b.step("test:integration", "Run integration tests");

    const run_unit = b.addRunArtifact(unit_tests);
    const run_integration = b.addRunArtifact(integration_tests);

    // Don't cache results when filtering
    if (test_filters.len > 0) {
        run_unit.has_side_effects = true;
        run_integration.has_side_effects = true;
    }

    unit_step.dependOn(&run_unit.step);
    integration_step.dependOn(&run_integration.step);
    test_step.dependOn(&run_unit.step);
    test_step.dependOn(&run_integration.step);
}
```

**Usage:**

```bash
$ zig build test                    # Run all tests
$ zig build test:unit               # Unit tests only
$ zig build test -- "hash"          # Filter by name
$ zig build test:integration        # Integration only
```

**Key teaching points:**

- **Test organization** — Separate unit and integration tests
- **Filter support** — `.filters` enables running subsets of tests
- **Cache invalidation** — `has_side_effects = true` prevents caching when filtering
- **Namespaced steps** — `test:unit` pattern for categorization

This pattern is common in TigerBeetle (multiple test categories), ZLS (fast unit tests vs slow integration), and other large projects.[^12]

## Common Pitfalls

### Using Deprecated 0.14.x APIs

The module system introduced in 0.15 replaced several setter methods:

**AVOID:**

```zig
// 🕐 0.14.x (DEPRECATED)
const exe = b.addExecutable("myapp", "src/main.zig");
exe.setTarget(target);
exe.setBuildMode(mode);
exe.addPackagePath("mylib", "lib/mylib.zig");
```

**USE:**

```zig
// ✅ 0.15+
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mylib", .module = mylib_mod },
        },
    }),
});
```

The new API provides better type safety, clearer ownership, and explicit dependency declarations.[^13]

### Forgetting Target and Optimize in Modules

Modules require explicit target and optimize settings. Omitting them causes confusing errors:

**AVOID:**

```zig
// ❌ Missing target/optimize
const mod = b.addModule("lib", .{
    .root_source_file = b.path("src/lib.zig"),
    // Tests using this module will fail!
});
```

**USE:**

```zig
// ✅ Always specify target and optimize
const mod = b.addModule("lib", .{
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});
```

This is especially important when modules are reused across multiple artifacts (libraries, executables, tests).

### Using Relative Paths

Relative paths are fragile and break when build.zig is invoked from different directories:

**AVOID:**

```zig
// ❌ Relative path
.root_source_file = .{ .path = "../src/main.zig" },
```

**USE:**

```zig
// ✅ Use b.path()
.root_source_file = b.path("src/main.zig"),
```

The `b.path()` method resolves paths relative to the `build.zig` file, regardless of where `zig build` is invoked.[^14]

### Not Handling Test Filters

If your build.zig doesn't support test filters, users cannot run specific tests:

**AVOID:**

```zig
// ❌ No filter support
const tests = b.addTest(.{
    .root_module = mod,
});
```

**USE:**

```zig
// ✅ Support test filters
const tests = b.addTest(.{
    .root_module = mod,
    .filters = b.args orelse &.{},
});
```

This allows `zig build test -- "specific test name"` for faster iteration during development.

### Circular Module Dependencies

Modules cannot have circular imports:

**AVOID:**

```zig
// ❌ Circular dependency
mod_a.addImport("b", mod_b);
mod_b.addImport("a", mod_a); // Circular!
```

**FIX:** Extract shared code into a third module that both can depend on.

### Not Using Lazy Dependencies

If you unconditionally load all dependencies, optional features increase build times:

**AVOID:**

```zig
// ❌ Always fetches, even if not needed
const dep = b.dependency("heavy-lib", .{});
```

**USE:**

```zig
// ✅ Only fetch when used
if (b.lazyDependency("heavy-lib", .{})) |dep| {
    // Use dep only if it's in build.zig.zon
}
```

Lazy dependencies are covered in depth in Chapter 9, but the pattern is important for optional features in build.zig.[^15]

## In Practice

### TigerBeetle: Strict Build Requirements

TigerBeetle enforces specific CPU features for cryptographic correctness:

```zig
// tigerbeetle/build.zig:13-42
fn resolve_target(b: *std.Build, target_requested: ?[]const u8) !std.Build.ResolvedTarget {
    const triples = .{ "aarch64-linux", "aarch64-macos", "x86_64-linux", "x86_64-windows" };
    const cpus = .{ "baseline+aes+neon", "baseline+aes+neon", "x86_64_v3+aes", "x86_64_v3+aes" };
    // Enforces AES instructions for cryptographic operations
}
```

This pattern ensures consistent performance characteristics and security guarantees across all deployments. The build fails if the target doesn't support required CPU features.[^16]

### Ghostty: Modular Build Organization

Large projects split `build.zig` across multiple files:

```zig
// ghostty/build.zig:17-34
const config = try buildpkg.Config.init(b, appVersion);
const deps = try buildpkg.SharedDeps.init(b, &config);
const mod = try buildpkg.GhosttyZig.init(b, &config, &deps);
```

Each `buildpkg` module handles a specific concern (configuration, dependencies, compilation). This keeps the main build file readable and delegates complexity to specialized modules.[^17]

### Mach: Optional Features

Mach uses feature flags to selectively compile subsystems:

```zig
// mach/build.zig:47-69
const want_mach = build_all or (build_mach orelse false);
const want_core = build_all or want_mach or (build_core orelse false);

const build_options = b.addOptions();
build_options.addOption(bool, "want_mach", want_mach);

if (b.lazyDependency("mach_freetype", .{ ... })) |dep| {
    module.addImport("mach-freetype", dep.module("mach-freetype"));
}
```

This pattern enables users to build only the GPU backend they need (Vulkan, DirectX, Metal) without pulling in all dependencies.[^18]

### ZLS: Git-Based Versioning

ZLS automatically determines version from git tags:

```zig
// zls/build.zig:333-390
fn getVersion(b: *Build) std.SemanticVersion {
    const git_describe = b.runAllowFail(&.{ "git", "describe", "--tags" }, ...) catch null;
    if (git_describe) |output| {
        // Parse version from git tag
        return std.SemanticVersion.parse(output) catch zls_version;
    }
    return zls_version; // Fallback to hardcoded version
}
```

This eliminates manual version bumping in source files and ensures consistency between releases and development builds.[^19]

### zig-gamedev: Complex C/C++ Library Integration

zig-gamedev demonstrates sophisticated build patterns for game development with multiple C/C++ dependencies:

**Multi-Library Dependency Management:**
```zig
// zig-gamedev/libs/build.zig structure
pub const Package = struct {
    zgui: *std.Build.Module,
    zgpu: *std.Build.Module,
    zphysics: *std.Build.Module,
    zaudio: *std.Build.Module,
    // ... 10+ libraries
};

pub fn link(b: *std.Build, artifact: *std.Build.Step.Compile) void {
    // Links ImGui, WebGPU/Dawn, PhysX, miniaudio, etc.
    artifact.linkLibrary(zgui);
    artifact.linkSystemLibrary("c++"); // Required for PhysX
}
```

**Key Patterns:**

1. **Centralized Library Builds:**
   - Single `libs/` directory with per-library build.zig
   - Shared build configuration across examples and samples
   - Consistent compiler flags for C/C++ code

2. **Platform-Specific Linking:**
   - Conditional system library linking (Windows: d3d12, Linux: X11/Wayland)
   - macOS Metal framework integration
   - Cross-compilation support for all desktop platforms

3. **Build Option Propagation:**
   - Feature flags cascade from root to dependencies
   - Debug/release builds affect C++ optimization levels
   - Selective library builds reduce compilation time

4. **External C++ Library Wrapping:**
   - Type-safe Zig APIs over C++ libraries (ImGui, PhysX)
   - Memory ownership clear at FFI boundary
   - Allocator threading through C++ allocators

**Example: Multi-Target Game Build:**
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libs = Package.init(b, target, optimize);

    const game = b.addExecutable(.{
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link all graphics, physics, audio libraries
    libs.link(b, game);

    b.installArtifact(game);
}
```

This pattern demonstrates production-grade build systems for complex projects with:
- 10+ external C/C++ libraries
- Platform-specific graphics APIs (D3D12, Vulkan, Metal)
- Cross-compilation to Windows, Linux, macOS from any host

> **See also:** Chapter 10 (Interoperability) for zig-gamedev's C++ library integration patterns with ImGui, PhysX, and WebGPU.

### Zig Compiler: Comprehensive Testing

The Zig compiler builds separate test suites for different categories:

```zig
// zig/build.zig:381-621
const test_step = b.step("test", "Run all tests");

const behavior_tests = b.addTest(.{ ... });
const stdlib_tests = b.addTest(.{ ... });
const standalone_tests = b.addTest(.{ ... });

test_step.dependOn(&behavior_tests.step);
test_step.dependOn(&stdlib_tests.step);
test_step.dependOn(&standalone_tests.step);
```

Each category can be run independently (`zig build test-behavior`), enabling fast iteration on specific subsystems.[^20]

## Summary

The Zig build system provides deterministic, type-safe project configuration through executable code. Key patterns:

**Fundamentals:**
- Always use `standardTargetOptions()` and `standardOptimizeOption()`
- Modules are the primary abstraction for dependency management
- Build steps coordinate task execution with explicit dependencies

**Advanced patterns:**
- Build options enable compile-time configuration with zero runtime cost
- Custom build steps support code generation and asset processing
- Multi-target builds produce release artifacts for all platforms in one command
- Test organization separates unit and integration tests with filtering support

**Migration:**
- Zig 0.15 introduced the module system, replacing setter methods with constructor structs
- Always specify `.target` and `.optimize` in modules to avoid cryptic errors
- Use `b.path()` instead of relative paths for portability

**Production practices:**
- Large projects split build.zig across multiple files for maintainability
- Feature flags with lazy dependencies reduce build times for optional functionality
- Git-based versioning eliminates manual version management
- CPU feature enforcement ensures performance and security guarantees

Understanding these patterns enables building libraries, CLI tools, and complex multi-artifact projects with confidence. The next chapter covers dependency management with `build.zig.zon`, completing the picture of Zig's build ecosystem.

## References

[^1]: Zig Build System documentation - https://ziglang.org/learn/build-system/
[^2]: Zig Language Reference: Cross-compilation - https://ziglang.org/documentation/master/#Cross-compilation
[^3]: Zig 0.15.0 Release Notes - https://github.com/ziglang/zig/releases/tag/0.15.0
[^4]: std.Build API documentation - https://ziglang.org/documentation/master/std/#std.Build
[^5]: Build Options guide - https://ziglang.org/learn/build-system/#build-options
[^6]: Custom Build Steps - https://ziglang.org/learn/build-system/#custom-build-steps
[^7]: Official Zig init template - https://github.com/ziglang/zig/blob/master/lib/init/build.zig
[^8]: Zig module system documentation - https://ziglang.org/documentation/master/#Modules
[^9]: ZLS build.zig build options pattern - https://github.com/zigtools/zls/blob/master/build.zig#L47-L91
[^10]: TigerBeetle code generation pattern - https://github.com/tigerbeetle/tigerbeetle/blob/main/build.zig#L1945-L1955
[^11]: Ghostty multi-platform builds - https://github.com/ghostty-org/ghostty/blob/main/build.zig
[^12]: TigerBeetle test organization - https://github.com/tigerbeetle/tigerbeetle/blob/main/build.zig#L853-L886
[^13]: Zig 0.15 migration guide - https://github.com/ziglang/zig/wiki/0.15.0-Release-Notes
[^14]: std.Build.path documentation - https://ziglang.org/documentation/master/std/#std.Build.path
[^15]: Lazy dependencies - Covered in Chapter 1: Packages & Dependencies
[^16]: TigerBeetle CPU feature enforcement - https://github.com/tigerbeetle/tigerbeetle/blob/main/build.zig#L13-L42
[^17]: Ghostty modular build organization - https://github.com/ghostty-org/ghostty/blob/main/build.zig#L17-L34
[^18]: Mach optional features - https://github.com/hexops/mach/blob/main/build.zig#L47-L69
[^19]: ZLS git-based versioning - https://github.com/zigtools/zls/blob/master/build.zig#L333-L390
[^20]: Zig compiler test organization - https://github.com/ziglang/zig/blob/master/build.zig#L381-L621
[^21]: zig-gamedev build system - https://github.com/michal-z/zig-gamedev - Multi-library C/C++ integration patterns
