# Chapter 8: Build System (build.zig) - Research Notes

**Research Date:** 2025-11-03
**Zig Versions Tested:** 0.14.1, 0.15.2
**Status:** Complete

## Executive Summary

This chapter documents idiomatic `build.zig` patterns based on analysis of major Zig projects (Zig compiler, TigerBeetle, Ghostty, Bun, Mach, ZLS). The build system underwent significant API redesign between 0.14.x and 0.15+, introducing the module system and moving from setter methods to constructor structs.

**Key Findings:**
- Module system is central to 0.15+ builds
- All major projects use `b.standardTargetOptions()` and `b.standardOptimizeOption()`
- Build options modules enable compile-time configuration
- Custom build steps are common for code generation
- Production projects emphasize version enforcement and feature flags

## Project Analysis

### 1. Zig Compiler Build System

**File:** `/home/jack/workspace/zig_guide/reference_repos/zig/build.zig` (1470+ lines)

**Key Patterns:**

1. **Version Enforcement** (lines 13-61)
   - Comptime validation of Zig version compatibility
   - Hard requirement for specific major.minor.patch versions

2. **Build Options Module** (lines 221-356)
   - Extensive configuration: git commit hash, feature flags, platform options
   - LLVM backend toggling, Tracy profiling, debug extensions

3. **Test Matrix** (lines 381-621)
   - Cross-platform testing with filters
   - Multiple optimization modes tested in parallel
   - Separate test categories: unit, integration, behavior, stdlib

4. **Module Architecture** (lines 700-729)
   - Reusable compiler module with dependencies
   - Stack size configuration (46 MB for compiler!)

**Citations:**
- Version checking: `zig/build.zig:13-61`
- Build options: `zig/build.zig:221-356`
- Test matrix: `zig/build.zig:381-621`

### 2. TigerBeetle Database

**File:** `/home/jack/workspace/zig_guide/reference_repos/tigerbeetle/build.zig` (~2000 lines)

**Key Patterns:**

1. **Strict CPU Feature Requirements** (lines 13-42)
   - Enforces specific CPU features for cryptographic operations
   - `x86_64_v3+aes` for x86-64, `baseline+aes+neon` for ARM

2. **Multiversion Build** (lines 685-760)
   - Custom binary packing embedding multiple release versions
   - Uses `llvm-objcopy` for binary manipulation
   - Fat binaries on macOS (universal x86_64 + aarch64)

3. **Module System** (lines 354-386)
   - Reusable VSR module factory with options
   - Returns both options and module for flexible reuse

4. **CI Integration** (lines 398-510)
   - Comprehensive CI modes: smoke, test, fuzz, aof, clients, devhub
   - Custom error handling (hide stderr unless step fails)

**Citations:**
- CPU features: `tigerbeetle/build.zig:13-42`
- Multiversion: `tigerbeetle/build.zig:685-760`
- Module factory: `tigerbeetle/build.zig:354-386`

### 3. Ghostty Terminal

**File:** `/home/jack/workspace/zig_guide/reference_repos/ghostty/build.zig`

**Key Patterns:**

1. **Modular Organization**
   - Build split across multiple files in `src/build/`
   - Delegates to specialized modules (Config, SharedDeps, etc.)

2. **Conditional Features** (lines 66-77)
   - i18n support, documentation generation, webdata bundling
   - Platform-specific artifacts (macOS app, xcframework)

3. **Resource Installation** (lines 127-129)
   - Separate resources step for non-code assets
   - Environment variable passing for runtime resource location

4. **macOS Integration** (lines 149-179)
   - XCFramework for iOS/macOS development
   - Native app building via xcodebuild integration

**Citations:**
- Modular structure: `ghostty/build.zig:17-34`
- Features: `ghostty/build.zig:66-77`
- macOS: `ghostty/build.zig:149-179`

### 4. Mach Game Engine

**File:** `/home/jack/workspace/zig_guide/reference_repos/mach/build.zig`

**Key Patterns:**

1. **Optional Feature Flags** (lines 47-62)
   - Build options for selective compilation
   - Lazy dependency loading for unused features

2. **Platform-Specific Linking** (lines 263-376)
   - Separate functions: `linkSysgpu()`, `linkCore()`, `linkSysaudio()`
   - Framework linking on macOS, system libraries on Linux/Windows

3. **Version Enforcement** (lines 477-482)
   - Comptime check for exact Zig version match
   - Custom Zig builds (mach-nominated versions)

**Citations:**
- Features: `mach/build.zig:47-62`
- Platform linking: `mach/build.zig:263-376`
- Version check: `mach/build.zig:477-482`

### 5. Bun JavaScript Runtime

**File:** `/home/jack/workspace/zig_guide/reference_repos/bun/build.zig`

**Key Patterns:**

1. **Target Resolution** (lines 168-184)
   - Custom OS/arch refinement logic
   - Platform-specific CPU model selection

2. **Build Options Struct** (lines 39-117)
   - Centralized configuration with caching
   - Cached module for reuse across artifacts

3. **Check Steps** (lines 329-428)
   - Semantic analysis without code generation
   - Multi-platform check matrix for CI

4. **Import Propagation** (lines 802-818)
   - Share imports across all modules in dependency graph
   - Queue-based traversal for transitive imports

**Citations:**
- Target resolution: `bun/build.zig:168-184`
- Options struct: `bun/build.zig:39-117`
- Check steps: `bun/build.zig:329-428`

### 6. ZLS Language Server

**File:** `/home/jack/workspace/zig_guide/reference_repos/zls/build.zig`

**Key Patterns:**

1. **Git-Based Versioning** (lines 333-390)
   - Automatic version detection from git describe
   - Parse dev versions vs tagged releases

2. **Multiple Option Modules** (lines 47-91)
   - Separate concerns: build_options, exe_options, test_options, tracy_options
   - Named steps for clarity

3. **Module Factory** (lines 392-436)
   - Reusable module creation with platform-specific configuration
   - System library linking based on target

4. **Release Pipeline** (lines 483-598)
   - Reproducible tarball generation
   - release.json metadata for version tracking

**Citations:**
- Versioning: `zls/build.zig:333-390`
- Options: `zls/build.zig:47-91`
- Module factory: `zls/build.zig:392-436`

### 7. Official Template (zig init)

**File:** `/home/jack/workspace/zig_guide/reference_repos/zig/lib/init/build.zig`

**Key Patterns:**

1. **Module Separation**
   - Library module + executable pattern
   - Explicit import wiring

2. **Run Step Pattern**
   - Standard executable runner with args support
   - Dependency on install step

3. **Dual Test Setup**
   - Module tests + executable tests
   - Comprehensive coverage

**Citations:**
- Template file: `zig/lib/init/build.zig`

## Common Patterns Across Projects

### Build Function Structure

```zig
pub fn build(b: *std.Build) void {
    // 1. Parse options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 2. Create build options module (optional)
    const build_options = b.addOptions();

    // 3. Define steps
    const run_step = b.step("run", "Run the app");

    // 4. Create artifacts
    const exe = b.addExecutable(.{ ... });

    // 5. Wire dependencies
    b.installArtifact(exe);
}
```

### Target and Optimize Options

**Standard pattern** (universal across all projects):
```zig
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});
```

### Module System (0.15+)

**Creating modules:**
```zig
// Public API
const mod = b.addModule("mylib", .{
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});

// Internal use
const exe_mod = b.createModule(.{ ... });
```

**Wiring imports:**
```zig
.imports = &.{
    .{ .name = "mylib", .module = mod },
}
```

### Build Options Pattern

```zig
const build_options = b.addOptions();
build_options.addOption(bool, "enable_logging", true);
build_options.addOption([]const u8, "version", "1.0.0");

// Add to module
exe.root_module.addOptions("build_options", build_options);
```

## Anti-Patterns to Avoid

### 1. Version-Specific Anti-Patterns

**AVOID: Old 0.14.x APIs**
```zig
// ❌ 0.14.x (DEPRECATED)
exe.setTarget(target);
exe.setBuildMode(mode);
```

**USE: 0.15+ Constructor**
```zig
// ✅ 0.15+
const exe = b.addExecutable(.{
    .root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    }),
});
```

### 2. Module Anti-Patterns

**AVOID: Missing target/optimize**
```zig
// ❌ Will cause issues
const mod = b.addModule("lib", .{
    .root_source_file = b.path("src/lib.zig"),
    // Missing target!
});
```

### 3. Path Anti-Patterns

**AVOID: Relative paths**
```zig
// ❌ Fragile
.root_source_file = .{ .path = "../src/main.zig" },

// ✅ Use b.path()
.root_source_file = b.path("src/main.zig"),
```

## Version Differences: 0.14.x vs 0.15+

### Major Breaking Changes

**API Removal:**
- `setTarget()` / `setBuildMode()` → Constructor options
- `addExecutable(name, root_source)` → Struct with named fields
- Direct field access → Module system

**Module System Introduction:**
- All compilation units are now modules
- Explicit import wiring required
- `root_module` field on all artifacts

### Migration Patterns

**0.14.x:**
```zig
const exe = b.addExecutable("myapp", "src/main.zig");
exe.setTarget(target);
exe.setBuildMode(mode);
exe.addPackagePath("mylib", "lib/mylib.zig");
```

**0.15+:**
```zig
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

## Example Code Testing

All 6 code examples were tested successfully in both Zig 0.14.1 and 0.15.2:

1. ✅ **Simple Executable** - Basic build.zig structure
2. ✅ **Library + Executable** - Module system and testing
3. ✅ **Build Options** - Compile-time configuration
4. ✅ **Custom Step** - Code generation with custom build steps
5. ✅ **Multi-Target** - Cross-compilation matrix
6. ✅ **Test Configuration** - Advanced test organization

**Note:** Examples use `std.debug.print()` instead of stdout writer API to avoid I/O version differences (which are covered in Chapter 5).

## Key Decisions

1. **Focus on 0.15+ patterns** - Show modern module system, mark legacy patterns
2. **Use std.debug.print()** - Avoid I/O API version differences in build examples
3. **Real-world grounding** - All patterns extracted from production code
4. **Graduated complexity** - Start simple (hello world) → advanced (multi-target)

## References

### Primary Sources
- Zig compiler: `/home/jack/workspace/zig_guide/reference_repos/zig/build.zig`
- TigerBeetle: `/home/jack/workspace/zig_guide/reference_repos/tigerbeetle/build.zig`
- Ghostty: `/home/jack/workspace/zig_guide/reference_repos/ghostty/build.zig`
- Mach: `/home/jack/workspace/zig_guide/reference_repos/mach/build.zig`
- Bun: `/home/jack/workspace/zig_guide/reference_repos/bun/build.zig`
- ZLS: `/home/jack/workspace/zig_guide/reference_repos/zls/build.zig`
- Official template: `/home/jack/workspace/zig_guide/reference_repos/zig/lib/init/build.zig`

### Documentation
- Zig Build System documentation (to be cited in content.md)
- std.Build API documentation (to be cited in content.md)

## Production Patterns Summary

**From TigerBeetle:**
- Strict CPU feature enforcement for cryptographic correctness
- Multiversion binary packing for upgrades
- Module factories for reusable components

**From Ghostty:**
- Modular build organization for large projects
- Platform-specific artifact generation
- Resource installation and environment configuration

**From Mach:**
- Optional feature flags for selective compilation
- Lazy dependency loading
- Platform-specific linking abstractions

**From Bun:**
- Custom target resolution logic
- Build options struct with caching
- Check steps for CI without full compilation

**From ZLS:**
- Git-based automatic versioning
- Multiple option modules for different concerns
- Reproducible release pipeline

**From Zig Compiler:**
- Comprehensive test matrices
- Version enforcement
- Complex LLVM integration

---

**Research Quality:** High confidence - all patterns verified in production code, examples tested in both target versions.
