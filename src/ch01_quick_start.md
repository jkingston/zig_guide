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

In `build.zig`, change the executable name from `"myproject"` to `"wordcount"`:

```zig
const exe = b.addExecutable(.{
    .name = "wordcount",  // Change this line
    .root_module = b.createModule(.{
        // ... rest stays the same
    }),
});
```

Replace `src/main.zig` with:

```zig
const std = @import("std");

pub fn main() !void {
    // Memory allocation with leak detection
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read from stdin
    const stdin = std.io.getStdIn();
    const content = try stdin.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Count words
    var count: usize = 0;
    var iter = std.mem.splitScalar(u8, content, ' ');
    while (iter.next()) |_| count += 1;

    std.debug.print("Words: {}\n", .{count});
}
```

**What this demonstrates:**
- **Memory allocation** (Chapter 4) - `GeneralPurposeAllocator` with leak detection
- **Error handling** (Chapter 7) - `!void` return type, `try` keyword
- **Resource cleanup** (Chapter 7) - `defer` ensures cleanup on all exit paths
- **I/O operations** (Chapter 6) - Reading from stdin with proper error handling
- **String processing** (Chapter 5) - Splitting and iteration

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
