# Example 6: WASI Filesystem Operations

## Overview

This example demonstrates WebAssembly System Interface (WASI) capabilities in Zig, focusing on filesystem operations, command-line arguments, environment variables, and the capability-based security model.

## Learning Objectives

- Compile Zig to wasm32-wasi target
- Use WASI filesystem interfaces
- Work with command-line arguments in WASI
- Access environment variables
- Understand WASI capability model
- Handle file I/O safely in WASI

## Prerequisites

Install a WASI runtime:

```bash
# Install wasmtime (recommended)
curl https://wasmtime.dev/install.sh -sSf | bash

# Or use wasmer
curl https://get.wasmer.io -sSf | sh
```

## What is WASI?

WASI (WebAssembly System Interface) is a standardized API for WebAssembly to interact with:
- Filesystem
- Environment variables
- Command-line arguments
- Clocks and random numbers
- Network (in WASI preview2)

It uses a **capability-based security model** where access to resources must be explicitly granted.

## Key Concepts

### WASI Target Compilation

```zig
const target = b.resolveTargetQuery(.{
    .cpu_arch = .wasm32,
    .os_tag = .wasi,
});
```

### Capability-Based Security

WASI programs can only access resources they are explicitly granted:

```bash
# Grant read/write access to current directory
wasmtime --dir=. program.wasm

# Grant access to specific directory
wasmtime --dir=/tmp program.wasm

# Multiple directories
wasmtime --dir=. --dir=/tmp program.wasm

# Grant with different mount point
wasmtime --mapdir=/app::/path/to/app program.wasm
```

### Filesystem Operations

Standard Zig filesystem operations work in WASI:

```zig
const cwd = std.fs.cwd();

// Create file
const file = try cwd.createFile("test.txt", .{});
defer file.close();
try file.writeAll("content");

// Read file
const contents = try file.readToEndAlloc(allocator, max_size);
defer allocator.free(contents);

// Directory operations
try cwd.makeDir("mydir");
var dir = try cwd.openDir("mydir", .{ .iterate = true });
```

### Command-Line Arguments

```zig
var args = try std.process.argsWithAllocator(allocator);
defer args.deinit();

while (args.next()) |arg| {
    std.debug.print("{s}\n", .{arg});
}
```

Pass arguments to WASI program:

```bash
wasmtime --dir=. program.wasm arg1 arg2 arg3
```

### Environment Variables

```zig
const env_map = try std.process.getEnvMap(allocator);
defer env_map.deinit();

var iter = env_map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
}
```

Set environment variables:

```bash
wasmtime --dir=. --env MY_VAR=value program.wasm
```

### Standard I/O

WASI provides standard input, output, and error streams:

```zig
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();
const stdin = std.io.getStdIn().reader();

try stdout.print("Output\n", .{});
try stderr.print("Error\n", .{});
```

## Building and Running

```bash
# Build the WASI module
zig build

# Run with wasmtime (requires directory access)
wasmtime --dir=. ./zig-out/bin/wasi_filesystem.wasm

# Run with additional arguments
wasmtime --dir=. ./zig-out/bin/wasi_filesystem.wasm arg1 arg2

# Run with environment variables
wasmtime --dir=. --env TEST=value ./zig-out/bin/wasi_filesystem.wasm

# Run with wasmer (alternative runtime)
wasmer run --dir=. ./zig-out/bin/wasi_filesystem.wasm
```

## Expected Output

```
=== WASI Filesystem Demo ===

1. Command-line arguments:
   arg[0]: ./zig-out/bin/wasi_filesystem.wasm

2. Environment variables:
   PATH=/usr/bin:...
   HOME=/home/user
   (Total: X variables)

3. Current directory operations:
   Creating file: wasi_test_output.txt
   Reading file back:
   --- File contents ---
   Hello from WASI!
   This file was created by Zig running in WASI.
   Demonstrating filesystem capabilities.
   --- End of file ---

   File metadata:
   Size: 123 bytes
   Kind: file

4. Directory operations:
   Creating directory: wasi_test_dir
   Created nested file: wasi_test_dir/nested_file.txt
   Listing directory contents:
   - nested_file.txt (file)

5. Error handling:
   Expected error: FileNotFound

6. Cleaning up:
   Deleting nested file
   Deleting directory
   Deleting test file

=== Demo Complete ===
```

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2
- Wasmtime 1.0+
- Wasmer 3.0+
- Node.js 16+ (with WASI support)

## WASI Versions

This example uses **WASI Preview 1** (snapshot_preview1), the current stable version.

**WASI Preview 2** (in development) will add:
- Component model
- Better modularity
- Network sockets
- HTTP client/server

## Common Pitfalls Avoided

1. **Missing capabilities**: Always grant `--dir=.` when using filesystem
2. **Path resolution**: Using relative paths from granted directory
3. **Resource cleanup**: Using `defer` for file handles
4. **Buffer sizes**: Allocating appropriate sizes for file contents
5. **Error handling**: Properly handling filesystem errors

## Security Benefits

WASI's capability model prevents:
- Unauthorized filesystem access
- Unexpected network connections
- Time-of-check-time-of-use (TOCTOU) attacks
- Ambient authority problems

Each capability must be explicitly granted at runtime.

## Use Cases

- **Sandboxed plugins**: Safe execution of untrusted code
- **Serverless functions**: Isolated execution environments
- **CLI tools**: Cross-platform tools without recompilation
- **Edge computing**: Running on CDN edge nodes
- **Development tools**: Safe execution of build scripts

## References

- [WASI Specification](https://github.com/WebAssembly/WASI)
- [Wasmtime Documentation](https://docs.wasmtime.dev/)
- [Zig stdlib std/os/wasi.zig](https://github.com/ziglang/zig/blob/master/lib/std/os/wasi.zig)
- [Zig Language Reference - WASI](https://ziglang.org/documentation/0.15.2/#WASI)
- [WASI Tutorial](https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-tutorial.md)
