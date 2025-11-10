# Example 3: ArrayList Migration

This example demonstrates the ArrayList default change from managed to unmanaged in Zig 0.15.2 - one of the most pervasive breaking changes.

## What Changed

**Critical Breaking Change**: In Zig 0.15.2, `std.ArrayList(T)` now returns an **unmanaged** container by default.

### 0.14.1 Behavior (Managed)

```zig
// ArrayList stores allocator internally (8 bytes overhead on 64-bit)
var list = std.ArrayList(u32).init(allocator);  // Stores allocator
defer list.deinit();  // Uses stored allocator

try list.append(42);  // Uses stored allocator
```

### 0.15.2 Behavior (Unmanaged)

```zig
// ArrayList does NOT store allocator (zero overhead)
var list = std.ArrayList(u32).empty;  // No stored allocator
defer list.deinit(allocator);  // Must pass allocator

try list.append(allocator, 42);  // Must pass allocator
```

## Why This Change?

1. **Memory Savings**: 8 bytes per container (64-bit systems)
   - Struct with 3 containers: saves 24 bytes per instance
   - Large array of containers: significant total savings

2. **Allocation Visibility**: Every allocation site is explicit
   ```zig
   try list.append(allocator, item);  // Clear this may allocate
   ```

3. **Better Composition**: Multiple containers can share one allocator field
   ```zig
   const Container = struct {
       items: ArrayList(u32),    // No allocator field
       names: ArrayList([]u8),   // No allocator field
       allocator: Allocator,     // Single allocator for both
   };
   ```

4. **Community Consensus**: Ziggit discussion "Embracing Unmanaged"

## Migration Steps

### Step 1: Change Initialization

```zig
// 🕐 0.14.x
var list = std.ArrayList(T).init(allocator);

// ✅ 0.15+
var list = std.ArrayList(T).empty;
// Or: var list: std.ArrayList(T) = .{};
// Or: var list = std.ArrayList(T){};
```

### Step 2: Update deinit() Call

```zig
// 🕐 0.14.x
defer list.deinit();

// ✅ 0.15+
defer list.deinit(allocator);
```

### Step 3: Add Allocator to All Mutation Methods

```zig
// 🕐 0.14.x
try list.append(item);
try list.appendSlice(items);
try list.insert(0, item);
_ = list.pop();  // No allocator needed (doesn't allocate)

// ✅ 0.15+
try list.append(allocator, item);
try list.appendSlice(allocator, items);
try list.insert(allocator, 0, item);
_ = list.pop();  // Unchanged (doesn't allocate)
```

### Step 4: Update toOwnedSlice()

```zig
// 🕐 0.14.x
const slice = try list.toOwnedSlice();

// ✅ 0.15+
const slice = try list.toOwnedSlice(allocator);
```

## Building and Running

### Zig 0.14.1 Version

```bash
cd 0.14.1
/path/to/zig-0.14.1/zig build run
```

### Zig 0.15.2 Version

```bash
cd 0.15.2
/path/to/zig-0.15.2/zig build run
```

### Expected Output (Both Versions)

```
List contents: 10 20 30 40 50
List length: 5
List capacity: 7
```

## Common Errors

### Error 1: Missing Allocator in deinit()

```zig
var list = std.ArrayList(u32).empty;
defer list.deinit();  // ❌ Compile error
```

```
error: expected 2 arguments, found 1
defer list.deinit();
      ^~~~~~~~~~~~
```

**Fix**:
```zig
defer list.deinit(allocator);  // ✅ Pass allocator
```

### Error 2: Missing Allocator in append()

```zig
var list = std.ArrayList(u32).empty;
try list.append(42);  // ❌ Compile error
```

```
error: expected 3 arguments, found 2
try list.append(42);
    ^~~~~~~~~~~~~~~
```

**Fix**:
```zig
try list.append(allocator, 42);  // ✅ Pass allocator
```

### Error 3: Using .init() with Unmanaged

```zig
var list = std.ArrayList(u32).init(allocator);  // ❌ Compile error
```

```
error: no member named 'init' in struct 'array_list.Aligned(...)'
```

**Fix**:
```zig
var list = std.ArrayList(u32).empty;  // ✅ Use .empty or .{}
```

### Error 4: Allocator Lifetime Issues

```zig
fn getBrokenList() !std.ArrayList(u32) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = std.ArrayList(u32).empty;
    try list.append(allocator, 42);

    return list;  // ❌ Caller can't deinit - no allocator access!
}
```

**Fix Option 1**: Pass allocator as parameter
```zig
fn getList(allocator: std.mem.Allocator) !std.ArrayList(u32) {
    var list = std.ArrayList(u32).empty;
    try list.append(allocator, 42);
    return list;  // ✅ Caller has allocator
}

// Usage:
var list = try getList(allocator);
defer list.deinit(allocator);
```

**Fix Option 2**: Return owned slice instead
```zig
fn getSlice(allocator: std.mem.Allocator) ![]const u32 {
    var list = std.ArrayList(u32).empty;
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    return list.toOwnedSlice(allocator);  // ✅ Transfer ownership
}

// Usage:
const slice = try getSlice(allocator);
defer allocator.free(slice);
```

## Alternative: Using Deprecated Managed Wrapper

If you need minimal code changes temporarily (NOT RECOMMENDED):

```zig
// Use deprecated managed wrapper
var list = std.array_list.AlignedManaged(u32, null).init(allocator);
defer list.deinit();
try list.append(42);
```

**Warning**: This API is deprecated and will be removed in future Zig versions.

## Memory Comparison

### 0.14.1 (Managed)

```zig
const Container = struct {
    items: ArrayList(u32),    // includes allocator (8 bytes)
    names: ArrayList([]u8),   // includes allocator (8 bytes)
    allocator: Allocator,     // 8 bytes
    // Total: 3 allocator pointers = 24 bytes overhead
};
```

### 0.15.2 (Unmanaged)

```zig
const Container = struct {
    items: ArrayList(u32),    // NO allocator stored
    names: ArrayList([]u8),   // NO allocator stored
    allocator: Allocator,     // 8 bytes
    // Total: 1 allocator pointer = 8 bytes overhead
    // SAVES: 16 bytes per instance!
};
```

## Methods That Don't Change

Some methods don't require allocator because they don't allocate:

```zig
// These work the same in both versions:
_ = list.pop();
_ = list.popOrNull();
const item = list.orderedRemove(index);
const item = list.swapRemove(index);
list.clearRetainingCapacity();
// Reading: list.items, list.items.len, list.capacity
```

## Migration Checklist

- [ ] Find all `.init(allocator)` → change to `.empty` or `.{}`
- [ ] Find all `.deinit()` → add allocator parameter
- [ ] Find all `.append(` → add allocator as first parameter
- [ ] Find all `.appendSlice(` → add allocator as first parameter
- [ ] Find all `.insert(` → add allocator as first parameter
- [ ] Find all `.toOwnedSlice()` → add allocator parameter
- [ ] Check functions returning ArrayList - ensure allocator accessibility
- [ ] Test with allocator testing to catch lifetime issues

## Migration Time

**15-20 minutes per module**

Most changes caught by compiler. Main risk is allocator lifetime issues which may only appear at runtime.

## Next Steps

- See Example 4 for ArrayList in struct fields
- See Example 5 for ArrayList in complete applications
- Review Chapter 4 for more container patterns

## Further Reading

- Chapter 4: Collections & Containers (explains managed vs unmanaged in depth)
- Ziggit discussion: "Embracing Unmanaged" (community consensus on this change)
