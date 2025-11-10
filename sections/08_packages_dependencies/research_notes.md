# Chapter 9: Packages & Dependencies (build.zig.zon) - Research Notes

**Research Date:** 2025-11-04
**Zig Versions Tested:** 0.14.1, 0.15.2
**Status:** Complete

## Executive Summary

Zig's package system uses content-addressed dependencies with cryptographic hash verification. Unlike npm (lock files), cargo (Cargo.lock), or go modules (go.sum), Zig uses a single `build.zig.zon` manifest without separate lock files. Dependencies are resolved at build time, cached globally by hash, and accessed through the `b.dependency()` API.

**Key Findings:**
- Hash-based integrity - Packages identified by SHA-256 hash, URLs are mirrors
- Lazy evaluation - Dependencies marked `.lazy = true` only fetched when used
- No lock files - Deterministic resolution from build.zig.zon alone
- Flexible sourcing - Git repos, tarballs, local paths all supported
- Fingerprint field - Globally unique package identity, auto-generated
- Build-time configuration - Pass options to dependencies via `b.dependency()`

## Project Analysis

### 1. ZLS Language Server

**File:** `/home/jack/workspace/zig_guide/reference_repos/zls/build.zig.zon` (41 lines)

**Structure:**
```zig
.{
    .name = .zls,
    .version = "0.16.0-dev",
    .minimum_zig_version = "0.16.0-dev.728+87c18945c",
    .dependencies = .{
        .known_folders = .{
            .url = "https://github.com/ziglibs/known-folders/archive/92defaee76b07487769ca352fd0ba95bc8b42a2f.tar.gz",
            .hash = "known_folders-0.0.0-Fy-PJkfRAAAVdptXWXBspIIC7EkVgLgWozU5zIk5Zgcy",
        },
        .tracy = .{
            .url = "https://github.com/wolfpld/tracy/archive/refs/tags/v0.11.1.tar.gz",
            .hash = "N-V-__8AAMeOlQEipHjcyu0TCftdAi9AQe7EXUDJOoVe0k-t",
            .lazy = true,
        },
    },
}
```

**Key Insights:**
- GitHub archive URLs pointing to specific commits (not tags)
- Mix of eager and lazy dependencies
- `.minimum_zig_version` field for compatibility
- Two hash formats: modern `name-version-base64` and legacy `N-V-__8AA...`

**Dependency Usage (build.zig:150-153):**
```zig
const known_folders_module = b.dependency("known_folders", .{
    .target = release_target,
    .optimize = optimize,
}).module("known-folders");
```

**Module Publishing (build.zig:190):**
```zig
b.modules.put("zls", zls_module) catch @panic("OOM");
```

**Citations:**
- build.zig.zon: Lines 1-41
- Dependency usage: `zls/build.zig:150-153, 192-195, 403-410`
- Module publishing: `zls/build.zig:190`

### 2. Ghostty Terminal

**File:** `/home/jack/workspace/zig_guide/reference_repos/ghostty/build.zig.zon` (124 lines)

**Structure - Remote Zig Libraries:**
```zig
.dependencies = .{
    .libxev = .{
        .url = "https://deps.files.ghostty.org/libxev-34fa50878aec6e5fa8f532867001ab3c36fae23e.tar.gz",
        .hash = "libxev-0.0.0-86vtc4IcEwCqEYxEYoN_3KXmc6A9VLcm22aVImfvecYs",
        .lazy = true,
    },
    .vaxis = .{
        .url = "https://github.com/rockorager/libvaxis/archive/7dbb9fd3122e4ffad262dd7c151d80d863b68558.tar.gz",
        .hash = "vaxis-0.5.1-BWNV_LosCQAGmCCNOLljCIw6j6-yt53tji6n6rwJ2BhS",
        .lazy = true,
    },
}
```

**Structure - Local C Libraries:**
```zig
.cimgui = .{ .path = "./pkg/cimgui", .lazy = true },
.fontconfig = .{ .path = "./pkg/fontconfig", .lazy = true },
.freetype = .{ .path = "./pkg/freetype", .lazy = true },
```

**Key Insights:**
- **Extensive lazy dependencies** - Almost all marked `.lazy = true`
- Custom mirror (deps.files.ghostty.org) for reliability
- Local path dependencies for internal C library wrappers
- `.minimum_zig_version = "0.15.2"`
- Comments indicate upstream sources

**Lazy Dependency Pattern (SharedDeps.zig:141-162):**
```zig
if (b.lazyDependency("freetype", .{
    .target = target,
    .optimize = optimize,
    .@"enable-libpng" = true,  // Custom option
})) |freetype_dep| {
    step.root_module.addImport("freetype", freetype_dep.module("freetype"));

    if (b.systemIntegrationOption("freetype", .{})) {
        step.linkSystemLibrary2("freetype2", dynamic_link_opts);
    } else {
        step.linkLibrary(freetype_dep.artifact("freetype"));
    }
}
```

**Transitive Dependencies (SharedDeps.zig:323-331):**
```zig
// Access dependency's dependency
if (sentry_dep.builder.lazyDependency("breakpad", .{
    .target = target,
    .optimize = optimize,
})) |breakpad_dep| {
    try static_libs.append(
        b.allocator,
        breakpad_dep.artifact("breakpad").getEmittedBin(),
    );
}
```

**Citations:**
- build.zig.zon: Lines 1-124
- Lazy pattern: `ghostty/src/build/SharedDeps.zig:141-162`
- Transitive deps: `ghostty/src/build/SharedDeps.zig:323-331`

### 3. Mach Game Engine

**File:** `/home/jack/workspace/zig_guide/reference_repos/mach/build.zig.zon` (82 lines)

**Structure:**
```zig
.{
    .name = "mach",
    .version = "0.4.0",
    .paths = .{
        "src",
        "build.zig",
        "build.zig.zon",
        "LICENSE",
        "LICENSE-APACHE",
        "LICENSE-MIT",
        "README.md",
    },
    .dependencies = .{
        .mach_freetype = .{
            .url = "https://pkg.machengine.org/mach-freetype/d63efa5534c17f3a12ed3d327e0ad42a64adc20a.tar.gz",
            .hash = "1220adfccce3dbc4e4fa8650fdaec110a676f6b8a1462ed6ef422815207f8288e9d2",
            .lazy = true,
        },
    },
}
```

**Key Insights:**
- Explicit `.paths` list (best practice for published packages)
- Custom package registry (pkg.machengine.org)
- Old-style multihash format: `1220...` (64 hex characters)
- Dual license files in paths
- Documented build options for consumers

**Dependency Usage (build.zig:125-139):**
```zig
if (want_mach) {
    if (b.lazyDependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        module.addImport("mach-freetype", dep.module("mach-freetype"));
        module.addImport("mach-harfbuzz", dep.module("mach-harfbuzz"));
    }
}
```

**Documented Options (build.zig:25-42):**
```zig
/// Examples:
///
/// b.dependency("mach", .{
///   .target = target,
///   .optimize = optimize,
///   .core = true,
///   .sysaudio = true,
/// });
```

**Citations:**
- build.zig.zon: Lines 1-82
- Usage: `mach/build.zig:125-139`
- Documentation: `mach/build.zig:25-42`

### 4. TigerBeetle Platform-Specific Tools

**File:** `/home/jack/workspace/zig_guide/reference_repos/tigerbeetle/src/docs_website/build.zig.zon` (28 lines)

**Structure:**
```zig
.{
    .name = .tigerbeetle_docs,
    .version = "0.0.0",
    .dependencies = .{
        .pandoc_macos_arm64 = .{
            .url = "https://github.com/jgm/pandoc/releases/download/3.4/pandoc-3.4-arm64-macOS.zip",
            .hash = "1220c2506a07845d667e7c127fd0811e4f5f7591e38ccc7fb4376450f3435048d87a",
            .lazy = true,
        },
        .pandoc_linux_amd64 = .{
            .url = "https://github.com/jgm/pandoc/releases/download/3.4/pandoc-3.4-linux-amd64.tar.gz",
            .hash = "1220139a44886509d8a61b44d8b8a79d03bad29ea95493dc97cd921d3f2eb208562c",
            .lazy = true,
        },
    },
}
```

**Platform Selection (build.zig:91-108):**
```zig
fn get_pandoc_bin(b: *std.Build) ?std.Build.LazyPath {
    const host = b.graph.host.result;
    const name = switch (host.os.tag) {
        .linux => switch (host.cpu.arch) {
            .x86_64 => "pandoc_linux_amd64",
            else => @panic("unsupported cpu arch"),
        },
        .macos => switch (host.cpu.arch) {
            .aarch64 => "pandoc_macos_arm64",
            else => @panic("unsupported cpu arch"),
        },
        else => @panic("unsupported os"),
    };
    if (b.lazyDependency(name, .{})) |dep| {
        return dep.path("bin/pandoc");
    }
    return null;
}
```

**Key Insights:**
- Pattern for platform-specific binaries
- All dependencies lazy (only fetch for current platform)
- Accessing files within dependencies via `.path()`
- Graceful handling when deps not available

**Citations:**
- build.zig.zon: Lines 1-28
- Platform selection: `tigerbeetle/src/docs_website/build.zig:91-108`

### 5. Zig Compiler (Internal Use)

**File:** `/home/jack/workspace/zig_guide/reference_repos/zig/build.zig.zon` (16 lines)

**Structure:**
```zig
.{
    .name = .zig,
    .version = "0.0.0",
    .dependencies = .{
        .standalone_test_cases = .{
            .path = "test/standalone",
        },
        .link_test_cases = .{
            .path = "test/link",
        },
    },
    .paths = .{""},
    .fingerprint = 0xc1ce108124179e16,
}
```

**Key Insights:**
- Uses local path dependencies for test cases
- Comment: "not intended to be consumed as a package"
- Demonstrates minimal build.zig.zon for internal use
- No remote dependencies

**Citations:**
- build.zig.zon: Lines 1-16

### 6. Nested Dependencies (Ghostty Packages)

**Harfbuzz (pkg/harfbuzz/build.zig.zon):**
```zig
.{
    .name = .harfbuzz,
    .version = "11.0.0",
    .dependencies = .{
        .harfbuzz = .{  // Upstream C library
            .url = "https://deps.files.ghostty.org/harfbuzz-11.0.0.tar.xz",
            .hash = "N-V-__8AAG02ugUcWec-Ndp-i7JTsJ0dgF8nnJRUInkGLG7G",
            .lazy = true,
        },
        .freetype = .{ .path = "../freetype" },  // Sibling dep
        .macos = .{ .path = "../macos" },
        .apple_sdk = .{ .path = "../apple-sdk" },
    },
}
```

**Key Insights:**
- Packages can have their own dependencies
- Mix of remote (C library) and local (sibling packages)
- Demonstrates transitive dependency graph

**Citations:**
- `ghostty/pkg/harfbuzz/build.zig.zon`
- `ghostty/pkg/freetype/build.zig.zon`
- `ghostty/pkg/libpng/build.zig.zon`

---

## Common Patterns

### build.zig.zon Structure

**Required Fields:**
- `.name` - Enum literal (symbol), max 32 bytes
- `.version` - Semantic version string, max 32 bytes
- `.paths` - List of files/directories to include
- `.fingerprint` - 64-bit unique identifier (auto-generated, never change)

**Optional Fields:**
- `.minimum_zig_version` - Minimum Zig version (advisory)
- `.dependencies` - Struct of dependency declarations

**Dependency Fields:**
- `.url` + `.hash` - Remote dependency
- `.path` - Local relative path
- `.lazy` - Boolean (default: false)

### Hash Formats

**Modern (Zig 0.15+):**
```
name-version-base64hash
Example: known_folders-0.0.0-Fy-PJkfRAAAVdptXWXBspIIC7EkVgLgWozU5zIk5Zgcy
```

**Legacy Multihash:**
```
1220[64 hex characters]
Example: 1220adfccce3dbc4e4fa8650fdaec110a676f6b8a1462ed6ef422815207f8288e9d2
```

**Nameless (for assets):**
```
N-V-__8AA[base64]
Example: N-V-__8AAMeOlQEipHjcyu0TCftdAi9AQe7EXUDJOoVe0k-t
```

### URL Sources

**GitHub Archive (commit):**
```zig
.url = "https://github.com/user/repo/archive/COMMIT_HASH.tar.gz"
```

**GitHub Releases:**
```zig
.url = "https://github.com/user/repo/releases/download/TAG/file.tar.gz"
```

**Custom Package Registries:**
```zig
.url = "https://pkg.machengine.org/package-name/hash.tar.gz"
.url = "https://deps.files.ghostty.org/package-hash.tar.gz"
```

### Lazy vs Eager Dependencies

**Lazy (preferred):**
```zig
.dependency = .{
    .url = "...",
    .hash = "...",
    .lazy = true,  // Only fetched if used
}
```

**Usage:**
```zig
if (b.lazyDependency("name", .{})) |dep| {
    // Use dep
}
```

**Eager (always fetched):**
```zig
.dependency = .{
    .url = "...",
    .hash = "...",
    // .lazy omitted
}
```

**Usage:**
```zig
const dep = b.dependency("name", .{});  // Panics if unavailable
```

### Passing Options to Dependencies

**Standard Options:**
```zig
const dep = b.dependency("name", .{
    .target = target,
    .optimize = optimize,
});
```

**Custom Options:**
```zig
const dep = b.dependency("freetype", .{
    .target = target,
    .optimize = optimize,
    .@"enable-libpng" = true,  // Custom boolean
});
```

### Accessing Dependency Artifacts

**Modules:**
```zig
dep.module("module-name")
```

**Compiled Libraries:**
```zig
dep.artifact("artifact-name")
```

**Files/Directories:**
```zig
dep.path("relative/path")
dep.namedLazyPath("name")
```

---

## zig fetch Workflow

### Command Usage

**Syntax:**
```bash
zig fetch [options] <url>
zig fetch [options] <path>
```

**Options:**
- `--save` - Add to build.zig.zon with auto-generated name
- `--save=name` - Add to build.zig.zon with custom name
- `--save-exact` - Store URL verbatim
- `--debug-hash` - Print verbose hash information

**Examples:**
```bash
# Add dependency with auto name
zig fetch --save https://github.com/user/repo/archive/COMMIT.tar.gz

# Add with custom name
zig fetch --save=mylib https://example.com/mylib.tar.gz

# Just print hash (don't modify zon)
zig fetch https://github.com/user/repo/archive/COMMIT.tar.gz
```

### Hash Generation

**Algorithm:**
- SHA-256 based
- Computed from file contents after applying `.paths` rules
- Format: `name-version-base64(hashplus)`
- `hashplus` = 33-byte array (32-byte SHA256 + 1-byte prefix)

**Key Properties:**
- Hash is source of truth
- Changing URL requires deleting hash (or mismatch error)
- Hash protects against adversarial content

### Global Cache

**Location:**
- Default: `~/.cache/zig` (Linux), `~/Library/Caches/zig` (macOS)
- Override: `ZIG_GLOBAL_CACHE_DIR` environment variable
- Override: `--global-cache-dir` flag

**Organization:**
- Packages stored by hash
- Deduplicated across projects
- Shared between all builds

**Source:** `/home/jack/workspace/zig_guide/reference_repos/zig/src/main.zig:6812-6836`

---

## Integration Patterns

### Basic Module Import

```zig
const dep = b.dependency("package_name", .{
    .target = target,
    .optimize = optimize,
});

module.addImport("import_name", dep.module("module_name"));
```

### Linking Library Artifacts

```zig
const dep = b.dependency("library", .{
    .target = target,
    .optimize = optimize,
});

step.linkLibrary(dep.artifact("library_name"));
```

### System Library Fallback

```zig
if (b.systemIntegrationOption("libname", .{})) {
    step.linkSystemLibrary2("system-name", .{});
} else if (b.lazyDependency("libname", .{
    .target = target,
    .optimize = optimize,
})) |dep| {
    step.linkLibrary(dep.artifact("libname"));
}
```

### Platform-Specific Selection

```zig
fn getDependency(b: *std.Build) ?*std.Build.Dependency {
    const host = b.graph.host.result;
    const name = switch (host.os.tag) {
        .linux => switch (host.cpu.arch) {
            .x86_64 => "pkg_linux_x64",
            .aarch64 => "pkg_linux_arm64",
            else => return null,
        },
        .macos => "pkg_macos_arm64",
        else => return null,
    };
    return b.lazyDependency(name, .{});
}
```

---

## Publishing Patterns

### Minimal Publishable Package

```zig
.{
    .name = .package_name,
    .version = "1.0.0",
    .minimum_zig_version = "0.14.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "LICENSE",
        "README.md",
    },
    .fingerprint = 0x...,  // Auto-generated
}
```

### Exposing Modules

**Pattern 1: Direct addModule:**
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("package-name", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
}
```

**Pattern 2: Via b.modules:**
```zig
const mod = b.createModule(.{ ... });
b.modules.put("package-name", mod) catch @panic("OOM");
```

### Build Options for Consumers

```zig
pub fn build(b: *std.Build) void {
    const simd_enabled = b.option(bool, "simd", "Enable SIMD") orelse true;

    // Document in comments
    /// Examples:
    ///
    /// b.dependency("mypackage", .{
    ///   .target = target,
    ///   .optimize = optimize,
    ///   .simd = true,
    /// });
}
```

### Tagging and Versioning

**Best Practices:**
- Use semver tags: `v1.0.0`, `v0.5.1`
- Reference specific commits for stability
- Update `.version` field when tagging
- Include version in URLs for debugging

---

## Version Differences

### Hash Format Evolution

**Legacy (pre-0.15):**
```
Multihash: 1220[64 hex chars]
```

**Modern (0.15+):**
```
Named: name-version-base64hash
```

**Nameless (assets):**
```
N-V-__8AA[base64]
```

### Lazy Dependencies

**Introduced:** Zig 0.12
- Must use `b.lazyDependency()` for lazy deps
- Using `b.dependency()` on lazy dep causes panic
- Better for conditional platform-specific deps

### Fingerprint Field

**Purpose:** Globally unique package identity
**Generation:** Auto-created on first `zig build`
**Security note:** Changing has trust implications

**Composition:**
- 32-bit ID component (random)
- 32-bit checksum (CRC32 of package name)

---

## Example Testing Results

All examples tested successfully in Zig 0.14.1 and 0.15.2:

1. ✅ **Local Dependency** - App consuming local library
2. ✅ **Publishing a Library** - Complete package with tests, example, docs
3. ✅ **Lazy Dependencies** - Optional features with conditional loading

**Note:** Fingerprint values must be unique per package. Examples use auto-generated values from `zig build`.

---

## Key Decisions

1. **Focus on practical workflows** - Show everyday dependency patterns
2. **Emphasize lazy loading** - Best practice for optional features
3. **Document hash formats** - Explain modern vs legacy
4. **Platform-specific patterns** - Show conditional dependency selection
5. **Publishing checklist** - What's needed to share a package

---

## References

### Primary Sources

**ZLS:**
- build.zig.zon: `/home/jack/workspace/zig_guide/reference_repos/zls/build.zig.zon:1-41`
- Dependency usage: `zls/build.zig:150-153, 192-195, 403-410`

**Ghostty:**
- build.zig.zon: `/home/jack/workspace/zig_guide/reference_repos/ghostty/build.zig.zon:1-124`
- SharedDeps.zig: `ghostty/src/build/SharedDeps.zig:141-162, 323-331`
- Nested packages: `ghostty/pkg/harfbuzz/`, `ghostty/pkg/freetype/`

**Mach:**
- build.zig.zon: `/home/jack/workspace/zig_guide/reference_repos/mach/build.zig.zon:1-82`
- Usage: `mach/build.zig:125-139`

**TigerBeetle:**
- Platform deps: `tigerbeetle/src/docs_website/build.zig.zon:1-28`
- Selection: `tigerbeetle/src/docs_website/build.zig:91-108`

**Zig Compiler:**
- build.zig.zon: `/home/jack/workspace/zig_guide/reference_repos/zig/build.zig.zon:1-16`
- zig fetch: `zig/src/main.zig:6812-6836`
- Package.zig: `zig/src/Package.zig:48-100`

### Official Documentation
- build.zig.zon spec: `zig/doc/build.zig.zon.md`
- Init template: `zig/lib/init/build.zig.zon`
- std.Build API: `zig/lib/std/Build.zig:2006-2042`

---

**Research Quality:** High confidence - all patterns verified in production code, examples tested in target versions, comprehensive coverage of package ecosystem.
