# Project Layout, Cross-Compilation & CI

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

### Target Query API ✅ 0.15+

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

### Ghostty: Platform-Specific Artifacts

Ghostty produces different artifact types per platform:[^28]

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

Mach organizes related packages in a monorepo:[^29]

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

Bun combines Zig, C++, and CMake:[^30]

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
[^28]: Ghostty Release Tag Workflow - https://github.com/ghostty-org/ghostty/blob/main/.github/workflows/release-tag.yml
[^29]: Mach Build System - https://github.com/hexops/mach/blob/main/build.zig
[^30]: Bun Build System - https://github.com/oven-sh/bun/blob/main/build.zig
