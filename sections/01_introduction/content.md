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

// ✅ 0.15+
var list: std.ArrayList(u8) = .empty;
defer list.deinit(allocator);
```

The 0.15 change reflects Zig's shift toward explicit allocator passing, making memory costs visible at every call site.

### Code Examples

All examples are self-contained and runnable unless otherwise noted. To run an example, save it to a file (e.g., `example.zig`) and execute:

```
$ zig run example.zig
```

For test examples, use:

```
$ zig test example.zig
```

Examples follow these conventions:[^1]
- **Imports are explicit** — Every example shows required `@import` statements
- **Minimal boilerplate** — Focus on the pattern being demonstrated
- **Real-world context** — Examples reflect actual usage patterns
- **Source attribution** — Examples cite authoritative sources in footnotes

### Guide Structure

The guide is organized into 15 chapters covering language features, standard library patterns, tooling, and project organization. Each chapter follows a consistent structure:

1. **Overview** — Why this topic matters
2. **Core Concepts** — Key ideas with examples
3. **Code Examples** — Runnable demonstrations
4. **Common Pitfalls** — Mistakes to avoid
5. **In Practice** — Real-world usage from exemplar projects
6. **Summary** — Reinforcing the mental model
7. **References** — Citations for all sources

Chapters can be read sequentially or consulted independently. Cross-references link related topics throughout.

---

## Your First Zig Program

The simplest Zig program demonstrates imports, entry points, and format strings:[^2]

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}
```

**What this shows:**
- `const std = @import("std")` imports the standard library
- `pub fn main() void` is the public entry point
- `std.debug.print` writes to stderr (unbuffered, thread-safe)
- `{s}` is a format specifier for UTF-8 text
- `.{"World"}` is an anonymous tuple providing format arguments

This example works identically in all supported versions (0.14.0, 0.14.1, 0.15.1, 0.15.2).

---

## What Makes Zig Unique

Zig's `comptime` keyword enables computation at compile time:[^3]

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

## Version Awareness

Zig 0.15 introduced breaking changes to several core APIs. This guide supports developers using either version by teaching patterns first, then noting version-specific differences where they exist.

### stdout Writer Changes in 0.15

One significant breaking change is the stdout Writer interface:[^4]

**🕐 0.14.x — Unbuffered stdout**
```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello from 0.14!\n", .{});
}
```

**✅ 0.15+ — Buffered stdout**
```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello from 0.15!\n", .{});
    try stdout.context.flush();
}
```

**Why this changed:** Buffered I/O reduces system calls for bulk output. Explicit flushing makes buffering costs visible. Forgetting `.flush()` causes missing output—a common migration pitfall.

### When Version Markers Appear

Version markers appear only when APIs differ between the 0.14.x and 0.15.x series. Most Zig code works identically across all supported versions. For comprehensive migration guidance, see Chapter 14 (Migration Guide).

---

## Chapter Overview

**Chapter 2: Language Idioms** — Zig-specific patterns for error handling, memory management, resource cleanup, control flow, and comptime programming. Establishes mental models for how Zig differs from C and C++.

**Chapter 3: Memory & Allocators** — Allocator strategies (arena, general-purpose, fixed-buffer), memory ownership patterns, and debugging memory issues.

**Chapter 4: Collections & Containers** — Standard library data structures (ArrayList, HashMap, etc.) with version-specific API differences where they exist.

**Chapter 5: I/O & Streams** — File operations, network I/O, the 0.15 Writer/Reader changes, buffering strategies, and error handling.

**Chapter 6: Error Handling** — Advanced error patterns including error sets, payload capture, and idiomatic propagation across API boundaries.

**Chapter 7: Async & Concurrency** — Thread management, synchronization primitives, and async removal in 0.15 with future directions.

**Chapter 8: Build System** — `build.zig` structure, dependency management, cross-compilation, and 0.15 build system changes.

**Chapter 9: Packages & Dependencies** — Package layout conventions, vendoring strategies, and integration with third-party code.

**Chapter 10: Project Layout & CI** — Directory structures, testing strategies, and continuous integration setup for Zig projects.

**Chapter 11: Interoperability** — C interop patterns, calling conventions, and integrating Zig into existing C/C++ projects.

**Chapter 12: Testing & Benchmarking** — Test organization, property-based testing, and performance measurement techniques.

**Chapter 13: Logging & Diagnostics** — Structured logging patterns, debugging techniques, and production observability.

**Chapter 14: Migration Guide** — Detailed 0.14 → 0.15 migration checklist with automated tooling recommendations.

**Chapter 15: Appendices** — Quick reference tables, naming conventions, and links to community resources.

---

## In Practice

Real-world Zig projects demonstrate these patterns at scale:

**TigerBeetle**[^5] is a distributed financial transaction database prioritizing safety and correctness. Its [TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md) establishes rigorous engineering standards including minimum 2 assertions per function and comprehensive "why" comments.

**Ghostty**[^6] is a GPU-accelerated terminal emulator written primarily in Zig with Swift integration for macOS. The project demonstrates cross-platform abstractions and modular architecture.

**Bun**[^7] is a JavaScript runtime and bundler demonstrating large-scale Zig usage with multi-language interop. Its codebase shows practical patterns for organizing complex projects.

These projects are referenced throughout the guide as exemplars of production Zig patterns.

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

---

## Summary

This guide teaches Zig idioms and best practices for developers using versions 0.14.0, 0.14.1, 0.15.1, or 0.15.2. It is organized into 15 chapters, each focusing on a specific aspect of Zig development.

Most patterns work identically across all supported versions. When APIs differ, version markers (🕐 0.14.x, ✅ 0.15.1+) clearly indicate compatibility. The guide assumes familiarity with systems programming and intermediate experience.

Chapter 1 has oriented you to the guide structure, version markers, and provided a working Hello World example. You have seen a glimpse of Zig's compile-time execution with `comptime` and understand when version-specific differences appear.

Proceed to Chapter 2 to explore Zig's language idioms in depth, including error handling, memory management, resource cleanup, and the patterns that make Zig unique among systems programming languages.

---

## References

[^1]: [Zig Official Style Guide](https://ziglang.org/documentation/0.15.2/#Style-Guide) — Naming conventions and formatting standards
[^2]: [Zig.guide - Hello World](https://zig.guide/getting-started/hello-world) — Basic program structure
[^3]: [Zig.guide - Comptime](https://zig.guide/language-basics/comptime) — Compile-time execution
[^4]: [Zig 0.15.1 I/O Overhaul Explained](https://dev.to/bkataru/zig-0151-io-overhaul-understanding-the-new-readerwriter-interfaces-30oe) — Writer interface changes
[^5]: [TigerBeetle Repository](https://github.com/tigerbeetle/tigerbeetle) — Distributed database in Zig
[^6]: [Ghostty Repository](https://github.com/ghostty-org/ghostty) — Terminal emulator
[^7]: [Bun Repository](https://github.com/oven-sh/bun) — JavaScript runtime
