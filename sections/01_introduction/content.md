# Introduction

This guide teaches practical Zig idioms and best practices for developers using Zig **0.14.0, 0.14.1, 0.15.1, or 0.15.2**. Most patterns work identically across all supported versions. When they differ, version markers clearly indicate which code applies to which version.

---

## Who This Guide Is For

**This guide is designed for:**
- Systems programmers learning Zig from C, C++, or Rust backgrounds
- Developers building Zig applications on 0.14.x or 0.15.x
- Teams evaluating Zig for production use
- Contributors to Zig open-source projects

**This guide is NOT:**
- A beginner programming tutorial (assumes prior systems programming experience)
- A comprehensive language reference (see [official documentation](https://ziglang.org/documentation/0.15.2/))
- Focused on language internals or compiler implementation
- Limited to a single Zig version

---

## Quick Start

Get started with Zig in under 10 minutes. For a complete project tutorial, see **Appendix B: Architectural Analysis - zighttp**.

### Installation

Download Zig from the [official website](https://ziglang.org/download/):

```bash
# Verify installation
zig version
# Should show: 0.15.2 (or your installed version)
```

**Install ZLS (Zig Language Server)** for IDE support:
- Download from [ZLS releases](https://github.com/zigtools/zls/releases)
- ⚠️ Use matching tagged releases of Zig and ZLS (or both nightly). See [ZLS compatibility guide](https://github.com/zigtools/zls#compatibility)
- See **Appendix A: Development Setup** for detailed editor configuration

### Your First Project

Create a simple word counter that demonstrates core Zig concepts:

```bash
mkdir wordcount && cd wordcount
zig init
```

Replace `src/main.zig` with:

```zig
const std = @import("std");

pub fn main() !void {
    // Memory allocation with leak detection
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: wordcount <file>\n", .{});
        return;
    }

    // Read file with automatic cleanup
    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Count words
    var count: usize = 0;
    var iter = std.mem.splitScalar(u8, content, ' ');
    while (iter.next()) |_| count += 1;

    std.debug.print("Words: {}\n", .{count});
}
```

**What this demonstrates:**
- **Memory allocation** (Chapter 2) - `GeneralPurposeAllocator` with leak detection
- **Error handling** (Chapter 5) - `!void` return type, `try` keyword
- **Resource cleanup** (Chapter 5) - `defer` ensures cleanup on all exit paths
- **I/O operations** (Chapter 4) - File reading with proper error handling
- **String processing** (Chapter 1) - Splitting and iteration

**Build and run:**

```bash
zig build-exe src/main.zig
./wordcount README.md
# Output: Words: 42
```

### Development Workflow

Essential commands for day-to-day development:

```bash
# Initialize project structure
zig init

# Build project
zig build

# Run tests
zig build test

# Format code (automatic style enforcement)
zig fmt .

# Build and run
zig build run

# Cross-compile for different targets
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast
```

**Project structure created by `zig init`:**

```
myproject/
├── build.zig          # Build configuration (see Chapter 7)
├── build.zig.zon      # Package manifest (see Chapter 8)
├── src/
│   ├── main.zig       # Executable entry point
│   └── root.zig       # Library exports
└── .gitignore         # Excludes zig-cache/, zig-out/
```

### Next Steps

**Choose your learning path:**

- **New to Zig idioms?** → Chapter 1 (Language Idioms & Core Patterns)
- **Coming from C/Rust?** → Chapter 1, then Chapter 2 (Memory & Allocators)
- **Want complete project tutorial?** → Appendix B (zighttp architectural analysis)
- **Need troubleshooting?** → Appendix D (Troubleshooting Guide)

**Key chapters for common tasks:**
- **Memory management** → Chapter 2 (Memory & Allocators)
- **Error handling** → Chapter 5 (Error Handling & Resource Cleanup)
- **File I/O** → Chapter 4 (I/O, Streams & Formatting)
- **Building projects** → Chapter 7 (Build System)
- **Testing** → Chapter 11 (Testing, Benchmarking & Profiling)
- **Project setup** → Chapter 9 (Project Layout, Cross-Compilation & CI)

---

## How to Read This Guide

### Version Markers

Most code examples work across all supported Zig versions (0.14.0, 0.14.1, 0.15.1, 0.15.2). When patterns differ, version markers indicate compatibility:

- **🕐 0.14.x** — Code specific to Zig 0.14.0 and 0.14.1
- **✅ 0.15.1+** — Code specific to Zig 0.15.1 and later (0.15.0 was retracted)
- **No marker** — Code that works in all supported versions

For example, ArrayList initialization changed between versions:

```zig
// 🕐 0.14.x
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();

// ✅ 0.15.1+
var list: std.ArrayList(u8) = .empty;
defer list.deinit(allocator);
```

The 0.15 change reflects Zig's shift toward explicit allocator passing, making memory costs visible at every call site.

### Code Examples

All examples are self-contained and runnable unless otherwise noted. To run an example, save it to a file (e.g., `example.zig`) and execute:

```bash
$ zig run example.zig
```

For test examples, use:

```bash
$ zig test example.zig
```

Examples follow these conventions:[^1]
- **Imports are explicit** — Every example shows required `@import` statements
- **Minimal boilerplate** — Focus on the pattern being demonstrated
- **Real-world context** — Examples reflect actual usage patterns
- **Source attribution** — Examples cite authoritative sources in footnotes

### Guide Structure

The guide is organized into 14 chapters covering language features, standard library patterns, tooling, and project organization. Each chapter follows a consistent structure:

1. **Overview** — Why this topic matters
2. **Core Concepts** — Key ideas with examples
3. **Code Examples** — Runnable demonstrations
4. **Common Pitfalls** — Mistakes to avoid
5. **In Practice** — Real-world usage from exemplar projects
6. **Summary** — Reinforcing the mental model
7. **References** — Citations for all sources

Chapters can be read sequentially or consulted independently. Cross-references link related topics throughout.

---

## What Makes Zig Unique

Zig's `comptime` keyword enables computation at compile time:[^2]

```zig
const std = @import("std");

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "comptime execution" {
    const x = comptime fibonacci(10);
    try std.testing.expect(x == 55);
}
```

The `comptime` annotation forces evaluation during compilation. The result is a compile-time constant with zero runtime cost. Later chapters explore comptime metaprogramming in depth.

---

## Chapter Overview

**Chapter 1: Language Idioms** — Zig-specific patterns for error handling, memory management, resource cleanup, control flow, and comptime programming. Establishes mental models for how Zig differs from C and C++.

**Chapter 2: Memory & Allocators** — Allocator strategies (arena, general-purpose, fixed-buffer), memory ownership patterns, and debugging memory issues.

**Chapter 3: Collections & Containers** — Standard library data structures (ArrayList, HashMap, etc.) with version-specific API differences where they exist.

**Chapter 4: I/O & Streams** — File operations, network I/O, the 0.15 Writer/Reader changes, buffering strategies, and error handling.

**Chapter 5: Error Handling** — Advanced error patterns including error sets, payload capture, and idiomatic propagation across API boundaries.

**Chapter 6: Async & Concurrency** — Thread management, synchronization primitives, and async removal in 0.15 with future directions.

**Chapter 7: Build System** — `build.zig` structure, dependency management, cross-compilation, and 0.15 build system changes.

**Chapter 8: Packages & Dependencies** — Package layout conventions, vendoring strategies, and integration with third-party code.

**Chapter 9: Project Layout & CI** — Directory structures, testing strategies, continuous integration setup, and production project patterns.

**Chapter 10: Interoperability** — C interop patterns, calling conventions, and integrating Zig into existing C/C++ projects.

**Chapter 11: Testing & Benchmarking** — Test organization, property-based testing, and performance measurement techniques.

**Chapter 12: Logging & Diagnostics** — Structured logging patterns, debugging techniques, and production observability.

**Chapter 13: Migration Guide** — Detailed 0.14 → 0.15 migration checklist with automated tooling recommendations.

**Chapter 14: Appendices** — Development setup, complete project analysis, release checklist, troubleshooting guide, and reference material.

---

## In Practice

Real-world Zig projects demonstrate these patterns at scale:

**TigerBeetle**[^3] is a distributed financial transaction database prioritizing safety and correctness. Its [TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md) establishes rigorous engineering standards including minimum 2 assertions per function and comprehensive "why" comments.

**Ghostty**[^4] is a GPU-accelerated terminal emulator written primarily in Zig with Swift integration for macOS. The project demonstrates cross-platform abstractions and modular architecture.

**Bun**[^5] is a JavaScript runtime and bundler demonstrating large-scale Zig usage with multi-language interop. Its codebase shows practical patterns for organizing complex projects.

Additional exemplars include **zap** (high-performance HTTP server), **zigimg** (image format parsing), **zig-gamedev** (complex C++ library integration), and **zig-bootstrap** (official CI/CD reference). These projects are referenced throughout the guide as exemplars of production Zig patterns.

---

## Getting Help

**Official Resources:**
- [Zig Language Reference](https://ziglang.org/documentation/0.15.2/) — Comprehensive language specification
- [Standard Library Documentation](https://ziglang.org/documentation/0.15.2/std/) — API reference for `std`
- [Zig Download Page](https://ziglang.org/download/) — Installation and release notes

**Community Resources:**
- [Zig.guide](https://zig.guide) — Beginner-friendly tutorials and examples
- [Ziggit Forum](https://ziggit.dev) — Community discussions and support
- [Zig Discord](https://discord.gg/zig) — Real-time chat

**Exemplar Projects:**
- [TigerBeetle](https://github.com/tigerbeetle/tigerbeetle) — Safety-first database patterns
- [Ghostty](https://github.com/ghostty-org/ghostty) — Terminal emulator architecture
- [Bun](https://github.com/oven-sh/bun) — Large-scale runtime implementation

### Finding the Right Exemplar

The guide references production Zig projects throughout. Use this quick reference to find examples for specific patterns:

| If you need... | Study this project | See Chapter |
|----------------|-------------------|-------------|
| **HTTP server patterns** | [zap](https://github.com/zigzap/zap) | 4 (I/O), 6 (Concurrency) |
| **Binary format parsing** | [zigimg](https://github.com/zigimg/zigimg) | 4 (I/O) |
| **Complex C++ interop** | [zig-gamedev](https://github.com/michal-z/zig-gamedev) | 7 (Build), 10 (Interop) |
| **Official CI/CD patterns** | [zig-bootstrap](https://github.com/ziglang/zig-bootstrap) | 9 (CI/CD) |
| **CLI tool design** | [zigup](https://github.com/marler8997/zigup) | References |
| **Database architecture** | [TigerBeetle](https://github.com/tigerbeetle/tigerbeetle) | Multiple chapters |
| **Terminal emulation** | [Ghostty](https://github.com/ghostty-org/ghostty) | Multiple chapters |
| **JavaScript runtime** | [Bun](https://github.com/oven-sh/bun) | Multiple chapters |
| **Game/graphics framework** | [Mach](https://github.com/hexops/mach) | 7 (Build) |
| **Language server** | [ZLS](https://github.com/zigtools/zls) | 6 (Concurrency), 9 (CI/CD) |

See the [**References**](../references.md) document for the complete list of exemplar projects with detailed descriptions.

---

## Summary

This guide teaches Zig idioms and best practices for developers using versions 0.14.0, 0.14.1, 0.15.1, or 0.15.2. It is organized into 14 chapters, each focusing on a specific aspect of Zig development.

Most patterns work identically across all supported versions. When APIs differ, version markers (🕐 0.14.x, ✅ 0.15.1+) clearly indicate compatibility. The guide assumes familiarity with systems programming and intermediate experience.

This introduction has oriented you to the guide structure, version markers, and provided a working Quick Start example. You've seen a glimpse of Zig's compile-time execution with `comptime` and understand when version-specific differences appear.

Proceed to Chapter 1 to explore Zig's language idioms in depth, including error handling, memory management, resource cleanup, and the patterns that make Zig unique among systems programming languages.

---

## References

[^1]: [Zig Official Style Guide](https://ziglang.org/documentation/0.15.2/#Style-Guide) — Naming conventions and formatting standards
[^2]: [Zig.guide - Comptime](https://zig.guide/language-basics/comptime) — Compile-time execution
[^3]: [TigerBeetle Repository](https://github.com/tigerbeetle/tigerbeetle) — Distributed database in Zig
[^4]: [Ghostty Repository](https://github.com/ghostty-org/ghostty) — Terminal emulator
[^5]: [Bun Repository](https://github.com/oven-sh/bun) — JavaScript runtime
