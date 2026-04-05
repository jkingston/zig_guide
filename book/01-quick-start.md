# Quick Start

::: {.callout-tip}
## TL;DR for getting started

- **Installation:** Download from [ziglang.org](https://ziglang.org/download/), install matching ZLS for IDE support
- **First project:** `zig init` creates structure, `zig build` compiles, `zig build run` executes
- **Memory management:** `process.Init` provides `init.gpa` allocator with automatic leak detection
- **Error handling:** `!void` return type, `try` propagates errors, `defer` ensures cleanup on all paths
- **Cross-compilation:** `zig build -Dtarget=x86_64-linux` — compile for any target from any host
- **Jump to:** [Installation](#installation) | [First Project](#your-first-project) | [Development Workflow](#development-workflow)
:::

Get started with Zig in under 10 minutes. This chapter walks through installation, your first project, and essential development workflows.

---

## Installation

This guide targets **Zig 0.16.0-dev** (master). Grab the latest dev build from the [official downloads page](https://ziglang.org/download/) — scroll past the stable releases to the **master** section.

Alternatively, use a version manager:

```bash
# Using mise (https://mise.jdx.dev)
mise use -g zig@master

# Verify installation
zig version
# Should show: 0.16.0-dev.XXXX+<hash>
```

**Install ZLS (Zig Language Server)** for IDE support:
- Download the **nightly** build from [ZLS releases](https://github.com/zigtools/zls/releases) to match Zig master
- See [ZLS compatibility guide](https://github.com/zigtools/zls#compatibility) for version matching
- See **Appendix A: Development Setup** for detailed editor configuration

---

## Your First Project

Create a simple word counter that demonstrates core Zig concepts:

```bash
mkdir wordcount && cd wordcount
zig init
```

The `zig init` command creates a project structure with `build.zig` already configured to use the directory name (`"wordcount"`) as the executable name.

Replace `src/main.zig` with:

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Read from stdin
    const stdin = std.Io.File.stdin();
    var rbuf: [4096]u8 = undefined;
    var reader = stdin.reader(init.io, &rbuf);
    const content = try reader.interface.readAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Count words
    var count: usize = 0;
    var iter = std.mem.splitScalar(u8, content, ' ');
    while (iter.next()) |_| count += 1;

    std.debug.print("Words: {}\n", .{count});
}
```

**What this demonstrates:**
- **process.Init** (Appendix C) - `init.gpa` provides a pre-initialized allocator with leak detection
- **Error handling** (Chapter 7) - `!void` return type, `try` keyword
- **Resource cleanup** (Chapter 7) - `defer` ensures cleanup on all exit paths
- **I/O operations** (Chapter 6) - Reading from stdin with proper error handling
- **String processing** (Chapter 5) - Splitting and iteration

> **0.16+ note:** Zig 0.16 introduces `process.Init` ("juicy main"), which provides a pre-initialized allocator, arena, and I/O interface. The classic `pub fn main() !void` still works, but `process.Init` eliminates boilerplate. `init.gpa` is a `GeneralPurposeAllocator`-backed allocator; `init.arena` provides scratch space; `init.io` provides async I/O. See Appendix C for full details.

**Build and run:**

```bash
# Build the executable (creates zig-out/bin/wordcount)
zig build

# Pipe text to the program
echo "hello world from Zig" | zig-out/bin/wordcount
# Output: Words: 4

# Or use zig build run
echo "hello world from Zig" | zig build run
# Output: Words: 4
```

The `zig init` command creates a `build.zig` file that configures your project. The `.name = "wordcount"` field in that file controls the executable name. Chapter 9 covers the build system in depth.

---

## Development Workflow

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
├── build.zig          # Build configuration (see Chapter 9)
├── build.zig.zon      # Package manifest (see Chapter 10)
├── src/
│   ├── main.zig       # Executable entry point
│   └── root.zig       # Library exports
└── .gitignore         # Excludes zig-cache/, zig-out/
```

---

## What Makes Zig Unique

Zig's `comptime` keyword enables computation at compile time:[^1]

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

## Next Steps

**Choose your learning path:**

- **New to Zig idioms?** → Chapter 3 (Language Idioms & Core Patterns)
- **Coming from C/Rust?** → Chapter 3, then Chapter 4 (Memory & Allocators)
- **Want complete project tutorial?** → Appendix B (zighttp architectural analysis)
- **Need troubleshooting?** → Appendix D (Troubleshooting Guide)

**Key chapters for common tasks:**
- **Memory management** → Chapter 4 (Memory & Allocators)
- **Error handling** → Chapter 7 (Error Handling & Resource Cleanup)
- **File I/O** → Chapter 6 (I/O, Streams & Formatting)
- **Building projects** → Chapter 9 (Build System)
- **Testing** → Chapter 13 (Testing, Benchmarking & Profiling)
- **Project setup** → Chapter 11 (Project Layout, Cross-Compilation & CI)

---

## Summary

You've installed Zig, built your first working program, and seen key Zig concepts in action:
- Explicit memory allocation with leak detection
- Error handling with `try` and `!void`
- Resource cleanup with `defer`
- Compile-time execution with `comptime`

This Quick Start has given you a working foundation. Proceed to **Chapter 3: Language Idioms & Core Patterns** to explore Zig's unique patterns and mental models in depth.

---

## References

[^1]: [Zig.guide - Comptime](https://zig.guide/language-basics/comptime) — Compile-time execution
