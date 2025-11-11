# Quick Start

Get started with Zig in under 10 minutes. This chapter walks through installation, your first project, and essential development workflows.

---

## Installation

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

---

## Your First Project

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
- **String processing** (Chapter 2) - Splitting and iteration

**Build and run:**

```bash
zig build-exe src/main.zig
./wordcount README.md
# Output: Words: 42
```

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
├── build.zig          # Build configuration (see Chapter 7)
├── build.zig.zon      # Package manifest (see Chapter 8)
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

- **New to Zig idioms?** → Chapter 2 (Language Idioms & Core Patterns)
- **Coming from C/Rust?** → Chapter 2, then Chapter 3 (Memory & Allocators)
- **Want complete project tutorial?** → Appendix B (zighttp architectural analysis)
- **Need troubleshooting?** → Appendix D (Troubleshooting Guide)

**Key chapters for common tasks:**
- **Memory management** → Chapter 3 (Memory & Allocators)
- **Error handling** → Chapter 6 (Error Handling & Resource Cleanup)
- **File I/O** → Chapter 5 (I/O, Streams & Formatting)
- **Building projects** → Chapter 8 (Build System)
- **Testing** → Chapter 12 (Testing, Benchmarking & Profiling)
- **Project setup** → Chapter 10 (Project Layout, Cross-Compilation & CI)

---

## Summary

You've installed Zig, built your first working program, and seen key Zig concepts in action:
- Explicit memory allocation with leak detection
- Error handling with `try` and `!void`
- Resource cleanup with `defer`
- Compile-time execution with `comptime`

This Quick Start has given you a working foundation. Proceed to **Chapter 2: Language Idioms & Core Patterns** to explore Zig's unique patterns and mental models in depth.

---

## References

[^1]: [Zig.guide - Comptime](https://zig.guide/language-basics/comptime) — Compile-time execution
