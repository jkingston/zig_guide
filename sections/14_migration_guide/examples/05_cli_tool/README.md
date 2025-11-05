# Example 5: Complete CLI Tool Migration

This example demonstrates end-to-end migration of a complete CLI application, showing how all three major breaking changes interact in real code.

## Application Overview

**Text Processor**: A simple CLI tool that:
- Loads search patterns into a configuration
- Processes text to find pattern matches
- Writes results to both stdout and a file

**Components**:
- `main.zig`: CLI entry point with I/O
- `config.zig`: Configuration struct with ArrayList
- `processor.zig`: Text processing logic

## What Changed

This example demonstrates **all three major breaking changes** in a coordinated migration:

1. **Build system**: `build.zig` requires `.root_module`
2. **I/O API**: stdout and file writing require explicit buffering
3. **ArrayList**: Configuration patterns ArrayList is now unmanaged

## Migration Demonstrated

### 1. Build System (build.zig)

**0.14.1**:
```zig
const exe = b.addExecutable(.{
    .name = "textproc",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

**0.15.2**:
```zig
const exe = b.addExecutable(.{
    .name = "textproc",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

### 2. I/O in main.zig

**0.14.1**:
```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Text Processor v0.14\n", .{});

const file_writer = output_file.writer();
try file_writer.print("Results\n", .{});
```

**0.15.2**:
```zig
var stdout_buf: [512]u8 = undefined;
var stdout = std.fs.File.stdout().writer(&stdout_buf);
try stdout.interface.print("Text Processor v0.15\n", .{});
try stdout.interface.flush();

var file_buf: [4096]u8 = undefined;
var file_writer = output_file.writer(&file_buf);
try file_writer.interface.print("Results\n", .{});
try file_writer.interface.flush();  // CRITICAL
```

### 3. ArrayList in config.zig

**0.14.1**:
```zig
pub fn init(allocator: std.mem.Allocator) !Config {
    return Config{
        .patterns = std.ArrayList([]const u8).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Config) void {
    self.patterns.deinit();
}

pub fn addPattern(self: *Config, pattern: []const u8) !void {
    const owned = try self.allocator.dupe(u8, pattern);
    try self.patterns.append(owned);
}
```

**0.15.2**:
```zig
pub fn init(allocator: std.mem.Allocator) !Config {
    return Config{
        .patterns = std.ArrayList([]const u8).empty,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Config) void {
    self.patterns.deinit(self.allocator);  // Pass allocator
}

pub fn addPattern(self: *Config, pattern: []const u8) !void {
    const owned = try self.allocator.dupe(u8, pattern);
    try self.patterns.append(self.allocator, owned);  // Pass allocator
}
```

## Building and Running

### Zig 0.14.1 Version

```bash
cd 0.14.1
/path/to/zig-0.14.1/zig build run
cat results_014.txt
```

### Zig 0.15.2 Version

```bash
cd 0.15.2
/path/to/zig-0.15.2/zig build run
cat results_015.txt
```

### Expected Output (stdout)

```
Text Processor v0.14 / v0.15
====================

Loaded 3 search patterns
Found 3 matches

Results written to results_01x.txt
```

### Expected Output (results file)

```
Search Results
==============
Patterns: TODO, FIXME, NOTE
Matches found: 3
```

## Migration Strategy: Module-by-Module

### Step 1: Update build.zig (5 minutes)

**Required first** - project won't compile without this.

```bash
# Edit build.zig
# Add .root_module = b.createModule(...)
# Test compilation
zig build
```

### Step 2: Migrate I/O in main.zig (10-15 minutes)

1. Add buffer allocations
2. Update stdout API
3. Update file writer API
4. Add flush() calls
5. Test output

```bash
# Test after each change
zig build run
diff results_015.txt expected_results.txt
```

### Step 3: Migrate ArrayList in config.zig (10 minutes)

1. Change `.init()` to `.empty`
2. Add allocator to `deinit()`
3. Add allocator to `append()`
4. Test configuration loading

### Step 4: Verify No Changes Needed (5 minutes)

- processor.zig requires no changes (no I/O, no containers)
- This is common - not all modules need updates

### Step 5: Integration Testing (10 minutes)

1. Run full application
2. Verify stdout output matches
3. Verify file output matches
4. Check for memory leaks with allocator testing

**Total Migration Time**: 30-45 minutes

## Coordination Points

### Shared Allocator Pattern

Both `Config` and `Processor` share the same allocator from `main`:

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var config = try Config.init(allocator);  // Uses allocator
var processor = Processor.init(allocator);  // Uses allocator
```

This pattern is **easier** with unmanaged containers - no allocator stored in containers means less memory overhead.

### Buffer Management

Different buffer sizes for different purposes:

```zig
var stdout_buf: [512]u8 = undefined;    // Terminal: smaller buffer OK
var file_buf: [4096]u8 = undefined;     // File: optimal size
```

### Error Handling

flush() errors must be handled:

```zig
try file_writer.interface.flush() catch |err| {
    std.log.err("Failed to write results: {}", .{err});
    return err;
};
```

## Testing Strategy

### 1. Unit Tests Per Module

```zig
// config.zig
test "Config add pattern" {
    const allocator = std.testing.allocator;
    var config = try Config.init(allocator);
    defer config.deinit();

    try config.addPattern("TEST");
    try std.testing.expectEqual(1, config.patterns.items.len);
}
```

### 2. Integration Test

```zig
test "full pipeline" {
    const allocator = std.testing.allocator;

    var config = try Config.init(allocator);
    defer config.deinit();
    try config.addPattern("TEST");

    var processor = Processor.init(allocator);
    defer processor.deinit();

    const matches = try processor.findMatches("TEST data", config.patterns.items);
    try std.testing.expectEqual(1, matches);
}
```

### 3. File Output Verification

```zig
test "file output" {
    // Create file, write, flush, close
    // Read back and verify contents
    // Clean up
}
```

## Common Issues in Multi-Module Migration

### Issue 1: Inconsistent Migration State

**Problem**: Migrated `main.zig` but forgot `config.zig`

**Result**: Compile errors about ArrayList methods

**Solution**: Migrate all modules that use affected APIs together

### Issue 2: Forgetting flush() in One Place

**Problem**: Flushed stdout but not file writer

**Result**: Incomplete file output

**Solution**: Search for all `writer()` calls, ensure each has flush()

### Issue 3: Testing with Old Zig Version

**Problem**: Testing 0.15.2 code with 0.14.1 compiler

**Result**: Confusing errors about missing fields

**Solution**: Always verify Zig version:
```bash
zig version
```

## Migration Checklist

- [ ] Update build.zig with .root_module
- [ ] Compile to find all affected modules
- [ ] For each module with I/O:
  - [ ] Add buffer allocations
  - [ ] Update stdout/stderr/file APIs
  - [ ] Add .interface accessor
  - [ ] Add flush() calls
- [ ] For each module with ArrayList:
  - [ ] Change .init() to .empty
  - [ ] Add allocator to deinit()
  - [ ] Add allocator to mutation methods
- [ ] Run all unit tests
- [ ] Run integration tests
- [ ] Verify file outputs
- [ ] Check for memory leaks

## Performance Notes

**Memory**: Config struct saves 8 bytes (one allocator pointer removed)

**I/O Performance**:
- 0.14.1: Implicit buffering (performance varies)
- 0.15.2: Explicit 4KB buffering (consistent performance)

**Allocation Visibility**: Now clear which operations may allocate:
```zig
try config.addPattern("TEST");  // allocator parameter = may allocate
const matches = processor.findMatches(...);  // no allocator = won't allocate
```

## Next Steps

- See Example 6 for library migration patterns
- See Chapter 8 for more complex build.zig patterns
- See Chapter 4 for advanced container patterns

## Estimated Migration Time

**30-45 minutes for typical CLI applications**

More complex applications may take longer, but the patterns are the same.
