# Packages & Dependencies (build.zig.zon)

> **TL;DR for Zig dependencies:**
> - **Manifest:** `build.zig.zon` defines deps with URL + hash (no separate lock file)
> - **Fetch:** `zig fetch --save https://github.com/user/pkg/archive/v1.0.tar.gz` adds dependency
> - **Use:** `b.dependency("pkg_name", .{})` in build.zig, then `@import("pkg_name")` in code
> - **Security:** Content-addressed with SHA-256 verification (prevents supply-chain attacks)
> - **Cache:** Global at `~/.cache/zig` (shared across all projects)
> - **Jump to:** [build.zig.zon §8.2](#buildzigzon-structure) | [Fetch workflow §8.3](#zig-fetch-workflow) | [Publishing §8.6](#publishing-packages)

## Overview

Zig's package system uses content-addressed dependencies with cryptographic hash verification, eliminating an entire class of supply-chain attacks common in other ecosystems. Unlike npm (package-lock.json), Cargo (Cargo.lock), or Go modules (go.sum), Zig uses a single `build.zig.zon` manifest without separate lock files. Dependencies are resolved deterministically at build time, cached globally by hash, and accessed through a uniform API.

This chapter explains the structure of `build.zig.zon`, the `zig fetch` workflow, lazy dependency loading, and patterns for publishing packages. Understanding these patterns enables consuming third-party libraries, managing transitive dependencies, and publishing reusable code.

## Core Concepts

### build.zig.zon Structure

Every Zig package declares its metadata in `build.zig.zon`, a Zig data file using struct literal syntax:

```zig
.{
    .name = .mypackage,
    .version = "1.0.0",
    .minimum_zig_version = "0.14.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "README.md",
        "LICENSE",
    },
    .dependencies = .{
        .known_folders = .{
            .url = "https://github.com/ziglibs/known-folders/archive/HASH.tar.gz",
            .hash = "known_folders-0.0.0-BASE64HASH",
        },
    },
    .fingerprint = 0x1234567890abcdef,
}
```

**Required fields:**

- **`.name`** — Enum literal (symbol), max 32 bytes, should not include "zig" suffix
- **`.version`** — Semantic version string (e.g., "1.0.0")
- **`.paths`** — Files/directories included when package is consumed
- **`.fingerprint`** — 64-bit unique identifier, auto-generated, **never** change manually

**Optional fields:**

- **`.minimum_zig_version`** — Minimum Zig version (advisory, not enforced)
- **`.dependencies`** — Struct of dependency declarations

The `.paths` field determines what gets hashed—excluding test files, examples, or build artifacts reduces hash changes and improves cacheability.[^1]

### Content-Addressed Dependencies

Dependencies are identified by cryptographic hash, not version numbers or URLs. The URL is a mirror location; the hash is the source of truth:

```zig
.dependencies = .{
    .mylib = .{
        .url = "https://github.com/user/repo/archive/abc123.tar.gz",
        .hash = "mylib-1.0.0-Fy-PJkfRAAAVdptXWXBspIIC7EkVgLgWozU5zIk5Zgcy",
    },
}
```

**Hash format (Zig 0.15+):**
```
name-version-base64hash
```

The hash is SHA-256 based, computed from file contents after applying `.paths` rules. This provides:

- **Immutability** — Content cannot change without hash changing
- **Integrity** — Detects corruption or tampering
- **Reproducibility** — Same hash always produces identical build

If you change the URL (e.g., switching mirrors), you must delete the hash—Zig will error if the URL content doesn't match the hash.[^2]

### Lazy Dependencies

Dependencies can be marked `.lazy = true`, deferring fetch until actually used:

```zig
.dependencies = .{
    .optional_feature = .{
        .url = "https://example.com/feature.tar.gz",
        .hash = "feature-1.0.0-HASH",
        .lazy = true,  // Only fetched if used
    },
}
```

**In build.zig:**

```zig
if (b.lazyDependency("optional_feature", .{})) |dep| {
    // Use dep only if build needs it
    exe.root_module.addImport("feature", dep.module("feature"));
}
```

Lazy dependencies are essential for:

- **Platform-specific binaries** — Fetch only for current platform
- **Optional features** — Users opt-in with build flags
- **Large assets** — Avoid downloading unused resources

Non-lazy (eager) dependencies are fetched unconditionally and accessed with `b.dependency()`, which panics if unavailable.[^3]

### zig fetch Workflow

The `zig fetch` command adds dependencies and generates hashes:

```bash
# Add dependency with auto-generated name
$ zig fetch --save https://github.com/user/repo/archive/COMMIT.tar.gz

# Add with custom name
$ zig fetch --save=mylib https://example.com/mylib.tar.gz

# Just print hash (don't modify build.zig.zon)
$ zig fetch https://github.com/user/repo/archive/COMMIT.tar.gz
```

**Workflow:**

1. `zig fetch` downloads the URL
2. Computes SHA-256 hash of contents
3. Adds entry to `build.zig.zon` (if `--save` specified)
4. Caches in global cache (`~/.cache/zig` or `ZIG_GLOBAL_CACHE_DIR`)

Subsequent builds reuse the cached package—no re-download unless hash changes.[^4]

### Dependency Integration in build.zig

Dependencies are loaded with `b.dependency()` or `b.lazyDependency()`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load dependency
    const mylib_dep = b.dependency("mylib", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mylib", .module = mylib_dep.module("mylib") },
            },
        }),
    });

    b.installArtifact(exe);
}
```

**Key points:**

- Pass `.target` and `.optimize` to dependencies for consistency
- Access modules with `dep.module("name")`
- Access artifacts (libraries) with `dep.artifact("name")`
- Access files with `dep.path("relative/path")`

Dependencies can also accept custom options (e.g., `.@"enable-feature" = true`) for build-time configuration.[^5]

### Local Path Dependencies

Development often requires local dependencies before publishing:

```zig
.dependencies = .{
    .mylib = .{
        .path = "./lib",  // Relative to build.zig.zon
    },
}
```

**Comparison: URL vs Path Dependencies**

| Aspect | URL Dependencies | Path Dependencies |
|--------|------------------|-------------------|
| **Declaration** | `.url` + `.hash` required | `.path` only (relative to build.zig.zon) |
| **Cache behavior** | Cached in `~/.cache/zig` by hash | No caching, always uses local files |
| **Change detection** | Hash must change to update | Changes reflected immediately |
| **Hash requirement** | ✅ Required (SHA-256) | ❌ Not needed |
| **Best for** | Published packages, production deps | Monorepos, in-development libraries |
| **Lazy loading** | `.lazy = true` supported | `.lazy = true` supported |
| **Conversion** | Can't change to path without hash removal | Can convert to URL when publishing |
| **Example** | `{.url = "...", .hash = "..."}` | `{.path = "./lib"}` |

Both URL and path dependencies can be marked `.lazy = true` for conditional loading.[^6]

### Fingerprint Field

The `.fingerprint` field is a 64-bit unique identifier auto-generated on first build:

```zig
.fingerprint = 0x1234567890abcdef,
```

**Purpose:**

- Globally unique package identity
- Prevents accidental name collisions
- Tracks package lineage across versions

**Rules:**

- Generated by `zig build` if missing
- **Never change manually** — has security and trust implications
- Different forks should have different fingerprints

The fingerprint combines a random 32-bit ID with a 32-bit CRC32 checksum of the package name.[^7]

## Code Examples

### Example 1: Local Path Dependency

```zig
// app/build.zig.zon
.{
    .name = .app,
    .version = "0.1.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
    .dependencies = .{
        .mylib = .{
            .path = "./lib",
        },
    },
    .fingerprint = 0xc96e70cfa118c414,
}
```

```zig
// app/build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load local dependency
    const mylib_dep = b.dependency("mylib", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mylib", .module = mylib_dep.module("mylib") },
            },
        }),
    });

    b.installArtifact(exe);
}
```

```zig
// lib/build.zig.zon
.{
    .name = .mylib,
    .version = "1.0.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
    .fingerprint = 0xe7f94929cda3434e,
}
```

```zig
// lib/build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose module for consumers
    _ = b.addModule("mylib", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
}
```

**Key teaching points:**

- **Relative paths** — `./lib` resolves relative to build.zig.zon location
- **Module naming** — `b.addModule("mylib", ...)` defines what consumers import
- **Separation** — Each package has its own build.zig.zon and fingerprint
- **Development workflow** — Changes to `lib/` reflected immediately without cache invalidation

This pattern is common during library development before publishing to a remote URL.[^8]

### Example 2: Publishing a Library

```zig
// build.zig.zon
.{
    .name = .mathlib,
    .version = "2.0.0",
    .minimum_zig_version = "0.14.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "README.md",
        "LICENSE",
    },
    .fingerprint = 0x102b5599e8da1422,
}
```

```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose module for package consumers
    _ = b.addModule("mathlib", .{
        .root_source_file = b.path("src/mathlib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Tests for development
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/mathlib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);

    // Example executable (optional)
    const example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mathlib", .module = b.modules.get("mathlib").? },
            },
        }),
    });

    const example_step = b.step("example", "Build example");
    example_step.dependOn(&b.addInstallArtifact(example, .{}).step);
}
```

```zig
// src/mathlib.zig
const std = @import("std");

pub const version = "2.0.0";

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn mul(a: i32, b: i32) i32 {
    return a * b;
}

test "arithmetic operations" {
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, 6), mul(2, 3));
}
```

**Publishing checklist:**

1. **`.paths` includes essentials** — build.zig, build.zig.zon, src, LICENSE, README.md
2. **`.minimum_zig_version`** — Declares compatibility requirements
3. **Module exposed** — `b.addModule("mathlib", ...)` for consumers
4. **Tests included** — `zig build test` validates functionality
5. **Documentation** — README.md with usage examples
6. **License** — LICENSE file in `.paths`

**Consumer usage:**

```bash
# Add dependency
$ zig fetch --save=mathlib https://github.com/user/mathlib/archive/v2.0.0.tar.gz

# In build.zig
const mathlib = b.dependency("mathlib", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("mathlib", mathlib.module("mathlib"));

# In source code
const mathlib = @import("mathlib");
const result = mathlib.add(10, 5);
```

This pattern is observed in published packages like ziglyph, known-folders, and zig-cli.[^9]

### Example 3: Lazy Dependencies with Optional Features

```zig
// build.zig.zon
.{
    .name = .app_with_features,
    .version = "0.1.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
    .dependencies = .{
        .basic_math = .{
            .path = "./features/basic_math",
        },
        .advanced_math = .{
            .path = "./features/advanced_math",
            .lazy = true,  // Only fetch if enabled
        },
    },
    .fingerprint = 0x1cb7bf439c5b61ae,
}
```

```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // User option to enable advanced features
    const enable_advanced = b.option(
        bool,
        "advanced",
        "Enable advanced math features",
    ) orelse false;

    // Build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "advanced_enabled", enable_advanced);

    // Basic dependency (always loaded)
    const basic_dep = b.dependency("basic_math", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "build_options", .module = build_options.createModule() },
                .{ .name = "basic_math", .module = basic_dep.module("basic") },
            },
        }),
    });

    // Advanced dependency (lazy - only if enabled)
    if (enable_advanced) {
        if (b.lazyDependency("advanced_math", .{
            .target = target,
            .optimize = optimize,
        })) |advanced_dep| {
            exe.root_module.addImport("advanced_math", advanced_dep.module("advanced"));
        }
    }

    b.installArtifact(exe);
}
```

```zig
// src/main.zig
const std = @import("std");
const build_options = @import("build_options");
const basic_math = @import("basic_math");

pub fn main() void {
    std.debug.print("Basic: add(10, 5) = {}\n", .{basic_math.add(10, 5)});

    if (build_options.advanced_enabled) {
        const advanced_math = @import("advanced_math");
        std.debug.print("Advanced: pow(2, 8) = {}\n", .{advanced_math.pow(2, 8)});
    } else {
        std.debug.print("Advanced features disabled (use -Dadvanced=true)\n", .{});
    }
}
```

**Usage:**

```bash
$ zig build run                    # Basic features only
$ zig build run -Dadvanced=true    # With advanced features
```

**Key teaching points:**

- **Lazy loading** — `advanced_math` not fetched unless `-Dadvanced=true`
- **Conditional imports** — Source code checks `build_options.advanced_enabled`
- **Build options bridge** — Connects build-time flag to runtime behavior
- **Optional feature pattern** — Common in libraries with heavy dependencies (e.g., Tracy profiler)

Projects like Ghostty use this pattern extensively—graphics libraries, font renderers, and platform-specific code are all lazy dependencies.[^10]

## Common Pitfalls

### Missing Fingerprint

Zig 0.15+ requires `.fingerprint` in all build.zig.zon files:

**AVOID:**

```zig
// ❌ Missing fingerprint
.{
    .name = .mypackage,
    .version = "1.0.0",
    .paths = .{""},
}
```

**FIX:**

```bash
$ zig build
error: missing top-level 'fingerprint' field; suggested value: 0x1234567890abcdef
```

Copy the suggested value into your build.zig.zon:

```zig
// ✅ With fingerprint
.{
    .name = .mypackage,
    .version = "1.0.0",
    .paths = .{""},
    .fingerprint = 0x1234567890abcdef,
}
```

The fingerprint is auto-generated and should never be changed manually.[^11]

### Incorrect Hash Format

Changing a URL without updating the hash causes verification failures:

**ERROR:**

```bash
$ zig build
error: hash mismatch
```

**FIX:**

Delete the `.hash` field and use `zig fetch` to regenerate:

```bash
$ zig fetch https://github.com/user/repo/archive/NEW_COMMIT.tar.gz
# Copy output hash to build.zig.zon
```

Or use `zig fetch --save=name <url>` to update automatically.

### Using b.dependency() on Lazy Dependencies

Lazy dependencies **must** use `b.lazyDependency()`:

**AVOID:**

```zig
// ❌ Panic if not available
const dep = b.dependency("lazy_dep", .{});
```

**USE:**

```zig
// ✅ Returns null if not available
if (b.lazyDependency("lazy_dep", .{})) |dep| {
    // Use dep
}
```

Using `b.dependency()` on a lazy dependency that isn't fetched will panic.[^12]

### Forgetting to Pass Target and Optimize

Dependencies should receive the same target and optimize settings:

**AVOID:**

```zig
// ❌ Dependency built for different target
const dep = b.dependency("mylib", .{});
```

**USE:**

```zig
// ✅ Consistent target and optimize
const dep = b.dependency("mylib", .{
    .target = target,
    .optimize = optimize,
});
```

Mismatched targets can cause linking errors or runtime incompatibilities.

### Circular Dependencies

Packages cannot depend on each other:

**AVOID:**

```
pkg_a depends on pkg_b
pkg_b depends on pkg_a  // ❌ Circular!
```

**FIX:** Extract shared code into a third package both can depend on.

### Not Including Essential Files in .paths

Missing files in `.paths` causes hash changes or consumer errors:

**AVOID:**

```zig
// ❌ Missing README, LICENSE
.paths = .{
    "build.zig",
    "src",
}
```

**USE:**

```zig
// ✅ Complete package
.paths = .{
    "build.zig",
    "build.zig.zon",
    "src",
    "README.md",
    "LICENSE",
}
```

Consumers expect documentation and license information.[^13]

## In Practice

### ZLS: Mix of Eager and Lazy Dependencies

ZLS uses lazy dependencies for optional Tracy profiler integration:

```zig
// zls/build.zig.zon
.dependencies = .{
    .known_folders = .{
        .url = "https://github.com/ziglibs/known-folders/archive/HASH.tar.gz",
        .hash = "known_folders-0.0.0-HASH",
        // Eager - always needed
    },
    .tracy = .{
        .url = "https://github.com/wolfpld/tracy/archive/v0.11.1.tar.gz",
        .hash = "N-V-__8AAMeOlQEipHjcyu0TCftdAi9AQe7EXUDJOoVe0k-t",
        .lazy = true,  // Only for profiling builds
    },
}
```

Tracy is a ~50MB dependency—making it lazy prevents unnecessary downloads for users not profiling ZLS.[^14]

### Ghostty: Extensive Lazy Loading

Ghostty marks almost all dependencies lazy, loading only what the build needs:

```zig
// ghostty/build.zig.zon
.dependencies = .{
    .libxev = .{ .url = "...", .hash = "...", .lazy = true },
    .vaxis = .{ .url = "...", .hash = "...", .lazy = true },
    .freetype = .{ .path = "./pkg/freetype", .lazy = true },
    .fontconfig = .{ .path = "./pkg/fontconfig", .lazy = true },
    // ~20 more lazy dependencies
}
```

This pattern:

- Reduces initial clone size
- Speeds up builds when features are disabled
- Supports platform-specific dependencies (macOS frameworks only on macOS)

The build.zig uses `b.lazyDependency()` throughout, gracefully handling missing deps.[^15]

### TigerBeetle: Platform-Specific Binaries

TigerBeetle's docs build uses lazy dependencies for platform-specific Pandoc binaries:

```zig
// tigerbeetle/src/docs_website/build.zig.zon
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
}
```

```zig
// build.zig
fn get_pandoc_bin(b: *std.Build) ?std.Build.LazyPath {
    const host = b.graph.host.result;
    const dep_name = switch (host.os.tag) {
        .linux => "pandoc_linux_amd64",
        .macos => "pandoc_macos_arm64",
        else => return null,
    };

    if (b.lazyDependency(dep_name, .{})) |dep| {
        return dep.path("bin/pandoc");
    }
    return null;
}
```

Only the current platform's binary is fetched, saving bandwidth and storage.[^16]

### Mach: Custom Package Registry

Mach hosts packages on a custom registry:

```zig
// mach/build.zig.zon
.dependencies = .{
    .mach_freetype = .{
        .url = "https://pkg.machengine.org/mach-freetype/d63efa5534c17f3a12ed3d327e0ad42a64adc20a.tar.gz",
        .hash = "1220adfccce3dbc4e4fa8650fdaec110a676f6b8a1462ed6ef422815207f8288e9d2",
        .lazy = true,
    },
}
```

Custom registries provide:

- **Reliability** — Controlled by project maintainers
- **Performance** — Optimized CDN distribution
- **Stability** — Guaranteed availability

This pattern is suitable for large projects with many dependencies.[^17]

## Summary

Zig's package system provides deterministic, content-addressed dependency management through `build.zig.zon` and the `zig fetch` workflow. Key patterns:

**Fundamentals:**
- Content-addressed by SHA-256 hash, not version numbers
- Single manifest file (`build.zig.zon`), no lock files
- Global cache prevents redundant downloads
- Fingerprint provides globally unique package identity

**Dependency patterns:**
- Lazy dependencies defer fetching until used
- Pass `.target` and `.optimize` for consistency
- Access modules with `dep.module()`, artifacts with `dep.artifact()`
- Local path dependencies for development

**Publishing:**
- Include essential files in `.paths` (source, docs, license)
- Expose modules with `b.addModule()`
- Tag releases with semantic versions
- Document build options for consumers

**Advanced patterns:**
- Platform-specific dependencies with conditional loading
- Custom package registries for large projects
- Transitive dependency access via `dep.builder.lazyDependency()`
- Build-time configuration through dependency options

**Migration notes:**
- Zig 0.15+ requires `.fingerprint` field
- Hash format evolved from multihash (`1220...`) to named (`name-version-base64`)
- Lazy dependencies introduced in 0.12, essential for modern workflows

Understanding these patterns enables consuming third-party libraries, managing complex dependency graphs, and publishing reusable packages. The next chapter covers project organization, cross-compilation, and CI integration—completing the picture of shipping production Zig software.

## References

[^1]: build.zig.zon specification - https://github.com/ziglang/zig/blob/master/doc/build.zig.zon.md
[^2]: Zig Package Hash Implementation - https://github.com/ziglang/zig/blob/master/src/Package.zig#L48-L100
[^3]: Lazy Dependencies Documentation - https://github.com/ziglang/zig/blob/master/lib/std/Build.zig#L2006-L2042
[^4]: zig fetch Command Documentation - https://github.com/ziglang/zig/blob/master/src/main.zig#L6812-L6836
[^5]: std.Build.dependency API - https://ziglang.org/documentation/master/std/#std.Build.dependency
[^6]: Local Path Dependencies - Official init template: https://github.com/ziglang/zig/blob/master/lib/init/build.zig.zon
[^7]: Fingerprint Field Documentation - https://github.com/ziglang/zig/blob/master/doc/build.zig.zon.md
[^8]: Zig init template pattern - https://github.com/ziglang/zig/tree/master/lib/init
[^9]: Publishing patterns observed in ziglyph, known-folders - https://github.com/jecolon/ziglyph, https://github.com/ziglibs/known-folders
[^10]: Ghostty lazy dependency pattern - https://github.com/ghostty-org/ghostty/blob/main/build.zig.zon
[^11]: Zig 0.15 fingerprint requirement - https://github.com/ziglang/zig/releases/tag/0.15.0
[^12]: lazy vs eager dependency behavior - https://github.com/ziglang/zig/blob/master/lib/std/Build.zig#L2006-L2042
[^13]: Package publishing best practices - https://github.com/ziglang/zig/blob/master/doc/build.zig.zon.md
[^14]: ZLS dependency structure - https://github.com/zigtools/zls/blob/master/build.zig.zon
[^15]: Ghostty extensive lazy loading - https://github.com/ghostty-org/ghostty/blob/main/build.zig.zon
[^16]: TigerBeetle platform-specific binaries - https://github.com/tigerbeetle/tigerbeetle/blob/main/src/docs_website/build.zig.zon
[^17]: Mach custom package registry - https://github.com/hexops/mach/blob/main/build.zig.zon
