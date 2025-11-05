# Example 2: Idiomatic Zig Style Demonstration

This example demonstrates idiomatic Zig style patterns extracted from production codebases: TigerBeetle, Ghostty, Bun, ZLS, and the Zig standard library.

## Style Patterns Demonstrated

### Naming Conventions

**✅ Functions: snake_case**
```zig
pub fn calculate_total_price(items: []const Item) f64
```

**✅ Types: PascalCase**
```zig
pub const Customer = struct { ... }
```

**✅ Constants: snake_case (with units last)**
```zig
const latency_ms_max: u64 = 1000;  // Not max_latency_ms
const buffer_size_bytes: usize = 4096;
```

### Code Organization

**✅ Import ordering: std first, then local**
```zig
const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

// Then local imports
const utils = @import("utils.zig");
```

### Function Patterns

**✅ Allocator as first parameter**
```zig
pub fn process_data(allocator: Allocator, data: []const u8) ![]u8
```

**✅ Options struct for multiple parameters**
```zig
pub fn connect(allocator: Allocator, options: struct {
    host: []const u8,
    port: u16,
    timeout_ms: u64 = 5000,
}) !Connection
```

**✅ Self parameter patterns**
- `*Self` for mutation
- `*const Self` for reading only
- `Self` for consuming/moving

### Error Handling

**✅ defer immediately after allocation**
```zig
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();
```

**✅ errdefer for multi-step initialization**
```zig
const buffer1 = try allocator.alloc(u8, 100);
errdefer allocator.free(buffer1);

const buffer2 = try allocator.alloc(u8, 200);
errdefer allocator.free(buffer2);
```

### Memory Management

**✅ Arena for temporary allocations**
```zig
var arena = std.heap.ArenaAllocator.init(gpa);
defer arena.deinit();

// All temporary allocations use arena
const temp = try arena.allocator().alloc(u8, 100);
// No individual cleanup needed
```

**✅ Descriptive allocator names**
- `gpa` - General Purpose Allocator (requires explicit cleanup)
- `arena` - Arena allocator (bulk cleanup)

### Assertions (TigerBeetle Pattern)

**✅ Split compound assertions**
```zig
// Good
std.debug.assert(list.items.len == old_len + 1);
std.debug.assert(list.items[old_len] == value);

// Bad: harder to debug
// std.debug.assert(list.items.len == old_len + 1 and list.items[old_len] == value);
```

### Documentation

**✅ Doc comments with examples**
```zig
/// Calculate the sum of all items in the list.
/// Returns 0 for empty lists.
/// Time complexity: O(n)
///
/// Example:
/// ```zig
/// const items = [_]i32{1, 2, 3, 4};
/// const total = sum_items(&items);
/// // total == 10
/// ```
pub fn sum_items(items: []const i32) i64
```

## Anti-Patterns to Avoid

❌ **CamelCase for functions**
```zig
pub fn CalculateTotalPrice() // Wrong
pub fn calculate_total_price() // Correct
```

❌ **Units first in variable names**
```zig
const max_latency_ms // Wrong
const latency_ms_max // Correct (TigerBeetle style)
```

❌ **Individual allocations in loops**
```zig
// Wrong: many syscalls
for (items) |item| {
    const buf = try allocator.alloc(u8, 100);
    defer allocator.free(buf);
}

// Correct: use arena
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
for (items) |item| {
    const buf = try arena.allocator().alloc(u8, 100);
}
```

❌ **Compound assertions**
```zig
assert(a and b and c); // Hard to debug which failed
assert(a); assert(b); assert(c); // Clear
```

## Running the Example

```bash
# Compile and run
zig build-exe src/main.zig
./main

# Run tests
zig test src/main.zig
```

## Expected Output

```
Total price: $41.49
Connected to localhost:8080
✅ All style patterns demonstrated successfully!
```

## Style Guide Sources

This example synthesizes patterns from:
- **TigerBeetle**: TIGER_STYLE.md (most rigorous)
- **Zig Standard Library**: Canonical patterns
- **Ghostty**: Application-level organization
- **ZLS**: Tooling conventions
- **Bun**: Performance-oriented patterns

## Key Takeaways

1. **Consistency matters**: snake_case dominates Zig conventions
2. **Explicit is better**: Name allocators meaningfully (gpa vs arena)
3. **Units last**: Allows variable alignment (latency_ms_max)
4. **Defer immediately**: Place cleanup code right after acquisition
5. **Split assertions**: Multiple simple assertions > one compound
6. **Arena for temporary**: Simplifies cleanup for scoped allocations

## Cross-References

- **Chapter 2**: Language Idioms (defer, errdefer, error handling)
- **Chapter 3**: Memory & Allocators (arena pattern, allocator selection)
- **Chapter 6**: Error Handling (cleanup patterns)
- **Appendices**: Style Checklist (complete reference)

This example serves as a practical style reference demonstrating production-verified Zig conventions.
