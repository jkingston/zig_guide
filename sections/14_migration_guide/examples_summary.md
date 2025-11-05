# Migration Examples Summary

**Chapter**: 14 - Migration Guide (0.14.1 → 0.15.2)
**Total Examples**: 6
**Purpose**: Demonstrate migration patterns with working before/after code
**Testing**: Each example compiles on both Zig 0.14.1 and 0.15.2

---

## Example 1: Simple Build.zig Migration

**Directory**: `examples/01_build_simple/`
**Complexity**: Beginner
**Migration Time**: 5 minutes
**Purpose**: Show basic build system migration

### File Structure
```
01_build_simple/
├── 0.14.1/
│   ├── build.zig       # Old syntax with deprecated fields
│   └── src/main.zig    # Simple hello world
├── 0.15.2/
│   ├── build.zig       # New syntax with root_module
│   └── src/main.zig    # Same source code (unchanged)
└── README.md           # Migration guide
```

### Key Changes Demonstrated
- `.root_source_file` → `.root_module = b.createModule()`
- Moving `target` and `optimize` into module
- Updated `addExecutable()` call pattern

### Source Code

**src/main.zig** (same for both versions):
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello from Zig!\n", .{});
}
```

**0.14.1 build.zig**:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "simple",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

**0.15.2 build.zig**:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "simple",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

### Expected Output
```
$ zig build run
Hello from Zig!
```

### README Topics
- What changed in the build system
- Why root_module is now required
- Step-by-step migration
- Common errors and fixes

**Estimated Lines**: ~30 total

---

## Example 2: I/O Migration - stdout/stderr

**Directory**: `examples/02_io_stdout/`
**Complexity**: Beginner-Intermediate
**Migration Time**: 10-15 minutes
**Purpose**: Show I/O API changes and buffering

### File Structure
```
02_io_stdout/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig    # Old I/O API
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig    # New I/O API with buffering
└── README.md
```

### Key Changes Demonstrated
- `std.io.getStdOut()` → `std.fs.File.stdout()`
- `writer()` → `writer(buffer)` with explicit buffer
- `.interface.print()` accessor
- Buffered vs unbuffered writers
- `flush()` requirement

### Source Code

**0.14.1 src/main.zig**:
```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stdout.print("Regular output\n", .{});
    try stdout.print("Value: {d}\n", .{42});

    try stderr.print("Error message\n", .{});
}
```

**0.15.2 src/main.zig**:
```zig
const std = @import("std");

pub fn main() !void {
    // Buffered stdout for better performance
    var stdout_buf: [256]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    // Unbuffered stderr for immediate error visibility
    var stderr = std.fs.File.stderr().writer(&.{});

    try stdout.interface.print("Regular output\n", .{});
    try stdout.interface.print("Value: {d}\n", .{42});
    try stdout.interface.flush();  // Ensure output is visible

    try stderr.interface.print("Error message\n", .{});
}
```

### Expected Output
```
Regular output
Value: 42
Error message
```

### README Topics
- stdout/stderr relocation
- Buffering explained
- When to use buffered vs unbuffered
- flush() requirements
- Performance implications

**Estimated Lines**: ~60 total

---

## Example 3: ArrayList Migration

**Directory**: `examples/03_arraylist/`
**Complexity**: Intermediate
**Migration Time**: 15-20 minutes
**Purpose**: Show ArrayList managed→unmanaged migration

### File Structure
```
03_arraylist/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig    # Managed ArrayList
├── 0.15.2/
│   ├── build.zig
│   ├── src/main.zig           # Unmanaged ArrayList
│   └── src/main_managed.zig   # Using deprecated managed wrapper
└── README.md
```

### Key Changes Demonstrated
- `.init(allocator)` → `.empty` or `.{}`
- `deinit()` → `deinit(allocator)`
- `append(item)` → `append(allocator, item)`
- Allocator passing patterns
- Optional: managed wrapper for minimal changes

### Source Code

**0.14.1 src/main.zig**:
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.ArrayList(u32).init(allocator);
    defer list.deinit();

    try list.append(10);
    try list.append(20);
    try list.append(30);
    try list.appendSlice(&[_]u32{40, 50});

    std.debug.print("List contents: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}
```

**0.15.2 src/main.zig** (recommended unmanaged):
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.ArrayList(u32).empty;
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);
    try list.appendSlice(allocator, &[_]u32{40, 50});

    std.debug.print("List contents: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}
```

**0.15.2 src/main_managed.zig** (deprecated but minimal changes):
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Using deprecated managed wrapper for minimal code changes
    var list = std.array_list.AlignedManaged(u32, null).init(allocator);
    defer list.deinit();

    try list.append(10);
    try list.append(20);
    try list.append(30);
    try list.appendSlice(&[_]u32{40, 50});

    std.debug.print("List contents: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}
```

### Expected Output
```
List contents: 10 20 30 40 50
```

### README Topics
- Why ArrayList default changed
- Managed vs unmanaged explanation
- Memory savings (8 bytes per container)
- Migration decision tree
- Allocator passing patterns

**Estimated Lines**: ~80 total

---

## Example 4: File I/O with Buffering

**Directory**: `examples/04_file_io/`
**Complexity**: Intermediate
**Migration Time**: 15-20 minutes
**Purpose**: Show file I/O buffering and performance

### File Structure
```
04_file_io/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig    # Old file I/O
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig    # New file I/O with explicit buffering
└── README.md
```

### Key Changes Demonstrated
- File writer buffering
- Buffer size selection
- flush() before close
- Performance comparison
- Error handling

### Source Code

**0.14.1 src/main.zig**:
```zig
const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    const writer = file.writer();

    try writer.print("Writing to file\n", .{});
    for (0..100) |i| {
        try writer.print("Line {d}\n", .{i});
    }
}
```

**0.15.2 src/main.zig**:
```zig
const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    var buf: [4096]u8 = undefined;  // Buffer for performance
    var writer = file.writer(&buf);

    try writer.interface.print("Writing to file\n", .{});
    for (0..100) |i| {
        try writer.interface.print("Line {d}\n", .{i});
    }
    try writer.interface.flush();  // CRITICAL: flush before close
}
```

### Expected Output
Creates `output.txt` with:
```
Writing to file
Line 0
Line 1
...
Line 99
```

### README Topics
- File buffering explained
- Buffer size guidelines (4KB for files)
- Performance benchmarks
- flush() requirement
- Silent data loss prevention

**Estimated Lines**: ~90 total

---

## Example 5: Complete CLI Tool Migration

**Directory**: `examples/05_cli_tool/`
**Complexity**: Intermediate-Advanced
**Migration Time**: 30-45 minutes
**Purpose**: Show end-to-end migration of real application

### File Structure
```
05_cli_tool/
├── 0.14.1/
│   ├── build.zig
│   └── src/
│       ├── main.zig          # CLI entry point
│       ├── config.zig        # Config with ArrayList
│       └── processor.zig     # File processing with I/O
├── 0.15.2/
│   ├── build.zig
│   └── src/
│       ├── main.zig
│       ├── config.zig
│       └── processor.zig
└── README.md
```

### Key Changes Demonstrated
- Build system migration
- I/O migration (file + stdout)
- ArrayList migration in struct fields
- Coordinated changes across modules
- Real-world application structure

### Source Code Overview

**Application**: Simple text processor that reads config, processes files, outputs results

**main.zig**: CLI argument parsing, stdout output
**config.zig**: Configuration struct with ArrayList of patterns
**processor.zig**: File reading/writing with buffering

### Migration Points
1. **build.zig**: Add `.root_module` with imports
2. **config.zig**: Update ArrayList to unmanaged, pass allocator
3. **processor.zig**: Update file I/O with buffering and flush
4. **main.zig**: Update stdout with buffering

### Expected Output
```
$ zig build run -- input.txt
Processing: input.txt
Found 5 matches
Output written to: output.txt
```

### README Topics
- End-to-end migration strategy
- Module-by-module approach
- Testing between changes
- Common coordination issues
- Migration checklist

**Estimated Lines**: ~150 total

---

## Example 6: Library with Module System

**Directory**: `examples/06_library/`
**Complexity**: Advanced
**Migration Time**: 20-30 minutes
**Purpose**: Show library and module migration

### File Structure
```
06_library/
├── 0.14.1/
│   ├── build.zig
│   ├── src/
│   │   └── mathlib.zig   # Library implementation
│   └── examples/
│       └── usage.zig      # Example using library
├── 0.15.2/
│   ├── build.zig
│   ├── src/
│   │   └── mathlib.zig
│   └── examples/
│       └── usage.zig
└── README.md
```

### Key Changes Demonstrated
- Library build with modules
- Module exports via `addModule()`
- Example executable importing library
- Public API patterns
- Testing library code

### Source Code Overview

**mathlib.zig**: Math utility library with ArrayList-based operations

**Library API**:
```zig
pub fn factorial(n: u32) u64;
pub fn fibonacci(n: u32, allocator: Allocator) ![]const u64;
pub fn primes(limit: u32, allocator: Allocator) ![]const u32;
```

**usage.zig**: Example program using the library

### Migration Points
1. **build.zig**: Create library with `.root_module`, use `addModule()` for export
2. **mathlib.zig**: Update ArrayList usage to unmanaged
3. **usage.zig**: Import library, use with unmanaged containers
4. **Tests**: Update test configuration

### Expected Output
```
$ zig build run
Factorial of 10: 3628800
Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
Primes up to 100: 2, 3, 5, 7, 11, 13, ...
```

### README Topics
- Library build patterns
- Module export via addModule()
- Using library in dependent code
- Testing library code
- API design for 0.15.2

**Estimated Lines**: ~100 total

---

## Testing Strategy

### Compilation Testing

For each example:
1. Test 0.14.1 version with Zig 0.14.1
   ```bash
   cd examples/XX_name/0.14.1
   /path/to/zig-0.14.1/zig build
   ```

2. Test 0.15.2 version with Zig 0.15.2
   ```bash
   cd examples/XX_name/0.15.2
   /path/to/zig-0.15.2/zig build
   ```

3. Verify both versions produce same output
   ```bash
   diff <(cd 0.14.1 && zig build run) <(cd 0.15.2 && zig build run)
   ```

### Functional Testing

- Verify all outputs match expected results
- Test error cases where applicable
- Ensure no warnings in either version
- Check memory usage (for Example 3)
- Performance comparison (for Example 4)

### README Quality

Each README must include:
- Clear explanation of what changed
- Why the change was made
- Step-by-step migration instructions
- Common errors and fixes
- Build/run commands for both versions
- Expected output

---

## Total Statistics

| Metric | Value |
|--------|-------|
| Total Examples | 6 |
| Total Files | ~36 (including READMEs) |
| Total Lines of Code | ~510 |
| Beginner Examples | 2 (Examples 1, 2) |
| Intermediate Examples | 3 (Examples 3, 4, 5) |
| Advanced Examples | 1 (Example 6) |
| Estimated Creation Time | 3-4 hours |
| Estimated Testing Time | 1-2 hours |

---

## Implementation Order

1. **Example 1** (Simple Build) - Foundation for all others
2. **Example 2** (I/O) - Independent, common pattern
3. **Example 3** (ArrayList) - Independent, critical change
4. **Example 4** (File I/O) - Builds on Example 2
5. **Example 5** (CLI Tool) - Integrates Examples 1-3
6. **Example 6** (Library) - Most complex, builds on all previous

---

**Document Status**: Complete specification
**Ready for Implementation**: Yes
**Next Step**: Create working code for each example
