# Collections & Containers

## Overview

Zig's standard library provides dynamic collection types that integrate with the explicit allocator model covered in Chapter 3. This chapter examines container types including ArrayList, HashMap, and their variants, focusing on the distinction between managed and unmanaged containers, ownership semantics, and cleanup responsibilities.

Understanding container ownership is critical for correct memory management. Unlike languages with garbage collection or implicit resource management, Zig requires developers to explicitly handle container lifecycles. The choice between managed and unmanaged containers affects memory overhead, API clarity, and program correctness.

As of Zig 0.15, the standard library has shifted toward unmanaged containers as the default pattern.[^1] This change reflects a broader philosophy: explicit allocator parameters make allocation sites visible, reduce per-container memory overhead, and enable better composition of container-heavy data structures.

## Core Concepts

### Managed vs Unmanaged Containers

Zig containers exist in two variants that differ in how they handle allocator storage and memory management.

**Managed containers** store an allocator as a struct field. Methods use this stored allocator implicitly. Prior to Zig 0.15, `std.ArrayList(T)` defaulted to this managed variant. The managed pattern provides a simpler API at the cost of increased memory usage per container instance.

**Unmanaged containers** do not store an allocator. Instead, methods that require allocation accept an allocator parameter explicitly. As of Zig 0.15, `std.ArrayList(T)` defaults to the unmanaged variant.[^1] This pattern reduces memory overhead and makes allocation sites visible in the code.

The memory difference is measurable. On 64-bit systems, each managed container stores an 8-byte allocator pointer. For data structures containing many containers, this overhead accumulates. A struct with ten ArrayLists saves 80 bytes by using unmanaged variants.

Consider a simple comparison:

```zig
const std = @import("std");

// 🕐 0.14.x - Managed (default)
const ManagedList = struct {
    data: std.ArrayList(u32),
};

// ✅ 0.15+ - Unmanaged (new default)
const UnmanagedList = struct {
    data: std.ArrayList(u32),
};
```

In Zig 0.14.x, `ManagedList.data` internally stores an allocator field. In Zig 0.15+, `UnmanagedList.data` does not store an allocator, requiring explicit passing to methods like `append()` and `deinit()`.

The shift to unmanaged defaults reflects community consensus that explicit allocator passing improves code clarity.[^2] When a method signature includes an allocator parameter, readers immediately know that allocation may occur. With managed containers, allocation is hidden inside the method implementation.

### Container Type Taxonomy

Zig's standard library provides several core container types, each available in both managed and unmanaged variants.

**ArrayList** provides a dynamic array with automatic growth. The unmanaged variant exposes this structure:

```zig
pub fn Aligned(comptime T: type, comptime alignment: ?u29) type {
    return struct {
        items: Slice = &[_]T{},
        capacity: usize = 0,
    };
}
```

The absence of an allocator field characterizes the unmanaged pattern.[^3] Methods that allocate memory accept an allocator parameter:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 42);  // Allocator explicit
defer list.deinit(allocator);    // Allocator required for cleanup
```

**HashMap** provides key-value storage with O(1) average-case lookup. The standard library offers six primary hash map variants:

- `HashMap` and `HashMapUnmanaged` - Custom hash context
- `AutoHashMap` and `AutoHashMapUnmanaged` - Automatic hashing for supported types
- `StringHashMap` and `StringHashMapUnmanaged` - Optimized for string keys

The `Auto` prefix indicates automatic hash function selection. `StringHashMap` treats string keys by content rather than pointer equality.[^4]

```zig
var users = std.AutoHashMapUnmanaged(u32, User).init();
try users.put(allocator, 1, user_instance);
defer users.deinit(allocator);
```

**ArrayHashMap** maintains insertion order and provides O(1) indexing through contiguous storage. This variant trades slightly slower insertion for dramatically faster iteration compared to standard HashMap.[^4]

```zig
var ordered = std.AutoArrayHashMapUnmanaged(u32, []const u8).init();
try ordered.put(allocator, 1, "first");
try ordered.put(allocator, 2, "second");

// Iteration over contiguous memory is cache-friendly
var it = ordered.iterator();
while (it.next()) |entry| {
    std.debug.print("{}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
}
```

Less common but useful container types include `PriorityQueue` for heap operations, `MultiArrayList` for structure-of-arrays layouts, and `SegmentedList` for stable pointer semantics across resizing.

### Ownership Transfer and Borrowing

Container ownership follows the same principles as other Zig resources: explicit ownership transfer and clear borrowing boundaries.

**Direct value storage** means the container owns the values it stores. When storing non-pointer types, `deinit()` frees the container's internal arrays but not the values themselves, as they are embedded directly:

```zig
const User = struct {
    id: u32,
    age: u8,
};

var users = std.AutoHashMapUnmanaged(u32, User).init();
try users.put(allocator, 1, User{ .id = 1, .age = 30 });
defer users.deinit(allocator);  // Frees hash map structure
```

However, if `User` contains allocated fields, cleanup becomes the developer's responsibility:

```zig
const User = struct {
    id: u32,
    name: []u8,  // Allocated separately

    fn deinit(self: *User, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
    }
};

var users = std.AutoHashMapUnmanaged(u32, User).init();
defer {
    var it = users.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.deinit(allocator);  // Clean user's name
    }
    users.deinit(allocator);  // Clean hash map structure
}
```

**Pointer storage** detaches value lifetime from container lifetime. The container stores only pointers; pointed-to values require separate cleanup:

```zig
var users = std.AutoHashMapUnmanaged(u32, *User).init();
defer {
    var it = users.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.*.deinit(allocator);  // Clean user object
        allocator.destroy(entry.value_ptr.*);  // Free pointer
    }
    users.deinit(allocator);  // Clean map structure
}
```

This pattern is described in the community resources as "the lifetime of the values is detached from the lifetime of the hash map."[^5]

**Ownership transfer** through `toOwnedSlice()` transfers an ArrayList's internal buffer to the caller:

```zig
var list = std.ArrayList(u8).init(allocator);
try list.appendSlice(allocator, "Hello");

const owned = try list.toOwnedSlice(allocator);
defer allocator.free(owned);  // Caller must free

// list is now empty: items.len == 0, capacity == 0
```

The list becomes empty after the transfer. This pattern enables functions to return dynamically-sized data without copying.[^3]

### Deinit Responsibilities

Every container that allocates memory must call `deinit()` with the same allocator used for initialization. Failure to do so causes memory leaks.

**Basic cleanup** requires matching `init()` with `deinit()`:

```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);  // Required

try list.append(allocator, 42);
```

The `defer` statement ensures cleanup occurs even on early return or error paths.

**Nested containers** require cleanup in reverse order of initialization:

```zig
var outer = std.ArrayList(std.ArrayList(u32)).init(allocator);
defer {
    for (outer.items) |*inner| {
        inner.deinit(allocator);  // Clean each inner list first
    }
    outer.deinit(allocator);  // Clean outer list last
}
```

**Error-path cleanup** uses `errdefer` to handle partial initialization failures. The TigerBeetle codebase demonstrates this pattern extensively:[^6]

```zig
pub fn init(allocator: std.mem.Allocator, options: Options) !CacheMap {
    var cache: ?Cache = if (options.cache_value_count_max == 0)
        null
    else
        try Cache.init(allocator, options.cache_value_count_max, .{ .name = options.name });
    errdefer if (cache) |*c| c.deinit(allocator);

    var stash: Map = .{};
    try stash.ensureTotalCapacity(allocator, options.stash_value_count_max);
    errdefer stash.deinit(allocator);

    var scope_rollback_log = try std.ArrayListUnmanaged(Value).initCapacity(
        allocator,
        options.scope_value_count_max,
    );
    errdefer scope_rollback_log.deinit(allocator);

    return CacheMap{
        .cache = cache,
        .stash = stash,
        .scope_rollback_log = scope_rollback_log,
        .options = options,
    };
}
```

Each allocation is immediately followed by `errdefer` cleanup. If any subsequent allocation fails, previously initialized resources are automatically freed in reverse order (LIFO).

**Arena allocators** provide bulk cleanup for containers with similar lifetimes:

```zig
var arena = std.heap.ArenaAllocator.init(page_allocator);
defer arena.deinit();  // Frees everything at once
const arena_alloc = arena.allocator();

var list1 = std.ArrayList(u8).init(arena_alloc);
var list2 = std.ArrayList(u32).init(arena_alloc);

// No individual deinit needed - arena cleanup handles all
try list1.appendSlice(arena_alloc, "data");
try list2.append(arena_alloc, 42);
```

The arena pattern is common in request-scoped or phase-based processing where many containers share the same lifetime.[^7]

### Container Selection Guidance

Choosing the appropriate container requires understanding performance characteristics and usage patterns.

**ArrayList vs fixed arrays vs slices:**

- ArrayList: Unknown size at compile time, needs growth
- Fixed array `[N]T`: Known size at compile time, stack allocation
- Slice `[]T`: Borrows existing data, no ownership

```zig
// ArrayList: Unknown size, heap allocation
var dynamic = std.ArrayList(u8).init(allocator);
defer dynamic.deinit(allocator);

// Fixed array: Known size, stack allocation
var fixed: [128]u8 = undefined;

// Slice: Borrows data
const borrowed: []const u8 = "static string";
```

**HashMap vs ArrayHashMap:**

HashMap provides O(1) average-case lookup with unordered storage. ArrayHashMap maintains insertion order and offers O(1) indexing with faster iteration due to contiguous memory layout.[^4]

Choose HashMap when:
- Insertion order does not matter
- Lookup performance is critical
- Memory layout is less important

Choose ArrayHashMap when:
- Iteration is frequent
- Insertion order matters
- Array-like indexing is needed
- Cache-friendly traversal is beneficial

**Pre-allocation strategies** avoid repeated reallocation during container growth:

```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);

// Pre-allocate known capacity
try list.ensureTotalCapacity(allocator, 100);

// Append without allocation
for (0..100) |i| {
    list.appendAssumeCapacity(@intCast(i));  // No allocation
}
```

The Ghostty terminal emulator demonstrates this pattern with a documented rationale:[^8]

```zig
var args: std.ArrayList([:0]const u8) = try .initCapacity(
    alloc,
    // This capacity is chosen based on what we'd need to
    // execute a shell command (very common). We can/will
    // grow if necessary for a longer command (uncommon).
    9,
);
defer args.deinit(alloc);
```

The comment explains why 9 is chosen: it covers the common case (shell execution) while allowing growth for uncommon cases.

**Container reuse** with `clearRetainingCapacity()` avoids allocation churn in loops:

```zig
var buffer = std.ArrayList(u8).init(allocator);
defer buffer.deinit(allocator);

try buffer.ensureTotalCapacity(allocator, 1024);

for (requests) |request| {
    buffer.clearRetainingCapacity();  // Clear contents, keep capacity
    try processRequest(request, &buffer);
}
```

This pattern is common in performance-critical code, particularly when processing repeated requests or iterations.[^9]

## Code Examples

### Example 1: Managed vs Unmanaged ArrayList

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ✅ 0.15+ Unmanaged ArrayList (default)
    std.debug.print("=== Unmanaged ArrayList ===\n", .{});
    var unmanaged_list = std.ArrayList(u32).init(allocator);
    defer unmanaged_list.deinit(allocator);  // Allocator required

    try unmanaged_list.append(allocator, 10);  // Allocator required
    try unmanaged_list.append(allocator, 20);
    try unmanaged_list.append(allocator, 30);

    std.debug.print("Items: ", .{});
    for (unmanaged_list.items) |item| {
        std.debug.print("{} ", .{item});
    }
    std.debug.print("\n", .{});
    std.debug.print("Capacity: {}, Length: {}\n", .{ unmanaged_list.capacity, unmanaged_list.items.len });

    // Show struct size difference
    std.debug.print("Unmanaged struct size: {} bytes\n\n", .{@sizeOf(@TypeOf(unmanaged_list))});

    // Pre-allocation pattern
    std.debug.print("=== Pre-allocation Pattern ===\n", .{});
    var preallocated = std.ArrayList(u32).init(allocator);
    defer preallocated.deinit(allocator);

    // Allocate exact capacity upfront (no reallocation needed)
    try preallocated.ensureTotalCapacity(allocator, 100);
    std.debug.print("Pre-allocated capacity: {}\n", .{preallocated.capacity});

    // Fast append without allocation
    for (0..100) |i| {
        preallocated.appendAssumeCapacity(@intCast(i));
    }
    std.debug.print("After 100 appends, capacity: {}\n", .{preallocated.capacity});
}
```

This example demonstrates the unmanaged ArrayList API where allocators must be passed to every method. Pre-allocation with `ensureTotalCapacity()` enables zero-allocation appends using `appendAssumeCapacity()`.

### Example 2: HashMap Ownership Patterns

```zig
const std = @import("std");

const User = struct {
    id: u32,
    name: []u8,
    score: i32,

    pub fn init(allocator: std.mem.Allocator, id: u32, name: []const u8, score: i32) !User {
        return .{
            .id = id,
            .name = try allocator.dupe(u8, name),
            .score = score,
        };
    }

    pub fn deinit(self: *User, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Pattern 1: Direct value storage
    std.debug.print("=== Pattern 1: Direct Value Storage ===\n", .{});
    var users_direct = std.AutoHashMapUnmanaged(u32, User).init();
    defer {
        // Must clean up allocated fields within values
        var it = users_direct.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(allocator);
        }
        users_direct.deinit(allocator);
    }

    var user1 = try User.init(allocator, 1, "Alice", 100);
    try users_direct.put(allocator, user1.id, user1);

    if (users_direct.get(1)) |user| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user.name, user.score });
    }

    // Pattern 2: Pointer storage (detached lifetime)
    std.debug.print("=== Pattern 2: Pointer Storage ===\n", .{});
    var users_ptr = std.AutoHashMapUnmanaged(u32, *User).init();
    defer {
        // Must free both the pointed-to objects AND the pointers
        var it = users_ptr.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit(allocator);
            allocator.destroy(entry.value_ptr.*);
        }
        users_ptr.deinit(allocator);
    }

    var user2 = try allocator.create(User);
    user2.* = try User.init(allocator, 2, "Bob", 200);
    try users_ptr.put(allocator, user2.id, user2);

    if (users_ptr.get(2)) |user_ptr| {
        std.debug.print("Found user: {s}, score: {}\n\n", .{ user_ptr.name, user_ptr.score });
    }

    // Pattern 3: HashMap as Set (void value)
    std.debug.print("=== Pattern 3: HashMap as Set ===\n", .{});
    var seen_ids = std.AutoHashMapUnmanaged(u32, void).init();
    defer seen_ids.deinit(allocator);

    try seen_ids.put(allocator, 42, {});
    try seen_ids.put(allocator, 100, {});

    std.debug.print("Contains 42? {}\n", .{seen_ids.contains(42)});
    std.debug.print("Contains 99? {}\n", .{seen_ids.contains(99)});
}
```

This example illustrates three HashMap ownership patterns. Pattern 1 stores values directly, requiring cleanup of allocated fields. Pattern 2 stores pointers with detached lifetimes, requiring both object and pointer cleanup. Pattern 3 demonstrates the set idiom using `void` values.

### Example 3: Nested Container Cleanup with errdefer

```zig
const std = @import("std");

const Database = struct {
    tables: std.ArrayList(Table),
    allocator: std.mem.Allocator,

    const Table = struct {
        name: []u8,
        rows: std.ArrayList([]u8),
    };

    pub fn init(allocator: std.mem.Allocator, table_names: []const []const u8) !Database {
        var tables = std.ArrayList(Table).init(allocator);
        errdefer {
            // Clean up any successfully initialized tables on error
            for (tables.items) |*table| {
                for (table.rows.items) |row| {
                    allocator.free(row);
                }
                table.rows.deinit(allocator);
                allocator.free(table.name);
            }
            tables.deinit(allocator);
        }

        for (table_names) |name| {
            const table_name = try allocator.dupe(u8, name);
            errdefer allocator.free(table_name);  // If rows allocation fails

            var rows = std.ArrayList([]u8).init(allocator);
            errdefer rows.deinit(allocator);  // If append to tables fails

            try tables.append(allocator, .{
                .name = table_name,
                .rows = rows,
            });
        }

        return .{
            .tables = tables,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        for (self.tables.items) |*table| {
            for (table.rows.items) |row| {
                self.allocator.free(row);
            }
            table.rows.deinit(self.allocator);
            self.allocator.free(table.name);
        }
        self.tables.deinit(self.allocator);
    }

    pub fn addRow(self: *Database, table_idx: usize, data: []const u8) !void {
        if (table_idx >= self.tables.items.len) return error.InvalidTable;

        const row = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(row);

        try self.tables.items[table_idx].rows.append(self.allocator, row);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Nested Container with errdefer ===\n", .{});

    // Success case
    const table_names = [_][]const u8{ "users", "products", "orders" };
    var db = try Database.init(allocator, &table_names);
    defer db.deinit();

    try db.addRow(0, "Alice");
    try db.addRow(0, "Bob");
    try db.addRow(1, "Widget");

    for (db.tables.items, 0..) |table, i| {
        std.debug.print("Table {s} has {} rows\n", .{ table.name, table.rows.items.len });
    }

    std.debug.print("\nDatabase cleaned up successfully\n", .{});
}
```

This example demonstrates cascading `errdefer` for multi-level nested containers. Each allocation is followed by cleanup code that runs only on error paths, preventing leaks during partial initialization.

### Example 4: Ownership Transfer with toOwnedSlice

```zig
const std = @import("std");

fn buildMessage(allocator: std.mem.Allocator, parts: []const []const u8) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    // Note: No defer here - ownership transferred via toOwnedSlice

    for (parts, 0..) |part, i| {
        try list.appendSlice(allocator, part);
        if (i < parts.len - 1) {
            try list.append(allocator, ' ');
        }
    }

    // Transfer ownership to caller
    return list.toOwnedSlice(allocator);
}

fn processData(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u32) {
    var numbers = std.ArrayList(u32).init(allocator);
    errdefer numbers.deinit(allocator);  // Clean up on error

    for (input) |byte| {
        if (byte >= '0' and byte <= '9') {
            try numbers.append(allocator, byte - '0');
        }
    }

    // Transfer ownership by returning the ArrayList directly
    return numbers;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Ownership Transfer Patterns ===\n\n", .{});

    // Pattern 1: toOwnedSlice (ArrayList → Slice)
    std.debug.print("Pattern 1: toOwnedSlice\n", .{});
    const parts = [_][]const u8{ "Hello", "from", "Zig" };
    const message = try buildMessage(allocator, &parts);
    defer allocator.free(message);  // Caller owns and must free

    std.debug.print("Message: {s}\n\n", .{message});

    // Pattern 2: Return ArrayList directly
    std.debug.print("Pattern 2: Return ArrayList\n", .{});
    var numbers = try processData(allocator, "a1b2c3d4e5");
    defer numbers.deinit(allocator);  // Caller owns and must deinit

    std.debug.print("Numbers: ", .{});
    for (numbers.items) |num| {
        std.debug.print("{} ", .{num});
    }
    std.debug.print("\n\n", .{});

    // Pattern 3: fromOwnedSlice (Slice → ArrayList)
    std.debug.print("Pattern 3: fromOwnedSlice\n", .{});
    const raw_data = try allocator.alloc(u8, 5);
    for (raw_data, 0..) |*byte, i| {
        byte.* = @intCast('A' + i);
    }

    var list_from_slice = std.ArrayList(u8).fromOwnedSlice(allocator, raw_data);
    defer list_from_slice.deinit(allocator);  // Now list owns the data

    try list_from_slice.append(allocator, 'F');  // Can grow
    std.debug.print("From slice: {s}\n", .{list_from_slice.items});
}
```

This example shows three ownership transfer patterns. `toOwnedSlice()` transfers buffer ownership to the caller. Returning an ArrayList directly transfers the entire container. `fromOwnedSlice()` allows an ArrayList to take ownership of an existing slice.

### Example 5: Container Reuse with clearRetainingCapacity

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Reusing Containers Across Iterations ===\n\n", .{});

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit(allocator);

    // Pre-allocate reasonable capacity
    try buffer.ensureTotalCapacity(allocator, 1024);

    const requests = [_][]const u8{ "request1", "request2", "request3" };

    for (requests, 0..) |request, i| {
        // Clear contents but keep capacity
        buffer.clearRetainingCapacity();

        std.debug.print("Iteration {}: ", .{i});
        std.debug.print("Length: {}, Capacity: {}\n", .{ buffer.items.len, buffer.capacity });

        // Build response using existing capacity
        try buffer.appendSlice(allocator, "Response to ");
        try buffer.appendSlice(allocator, request);

        std.debug.print("  Built: {s}\n", .{buffer.items});
        std.debug.print("  Final length: {}, Capacity: {}\n\n", .{ buffer.items.len, buffer.capacity });
    }

    std.debug.print("No reallocations occurred - capacity stayed constant\n", .{});

    // HashMap example
    std.debug.print("\n=== HashMap Reset Pattern ===\n\n", .{});

    var cache = std.AutoHashMapUnmanaged(u32, []const u8).init();
    defer cache.deinit(allocator);

    try cache.ensureTotalCapacity(allocator, 100);

    for (0..3) |batch| {
        std.debug.print("Batch {}: ", .{batch});

        // Populate cache
        for (0..10) |i| {
            try cache.put(allocator, @intCast(i), "data");
        }

        std.debug.print("Count: {}, Capacity: {}\n", .{ cache.count(), cache.capacity() });

        // Reset for next batch
        cache.clearRetainingCapacity();
    }

    std.debug.print("\nCache reused across batches without reallocation\n", .{});
}
```

This example demonstrates `clearRetainingCapacity()` for efficient container reuse. Pre-allocation followed by clearing avoids repeated allocation/deallocation cycles in iterative processing.

### Example 6: HashMap vs ArrayHashMap Performance

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const iterations = 1000;

    // HashMap vs ArrayHashMap iteration performance
    std.debug.print("=== HashMap vs ArrayHashMap Iteration ===\n", .{});

    var hash_map = std.AutoHashMapUnmanaged(u32, u32).init();
    defer hash_map.deinit(allocator);

    var array_hash_map = std.AutoArrayHashMapUnmanaged(u32, u32).init();
    defer array_hash_map.deinit(allocator);

    // Populate both
    for (0..100) |i| {
        try hash_map.put(allocator, @intCast(i), @intCast(i * 2));
        try array_hash_map.put(allocator, @intCast(i), @intCast(i * 2));
    }

    // Iterate HashMap
    var timer = try std.time.Timer.start();
    var sum1: u64 = 0;
    for (0..iterations) |_| {
        var it1 = hash_map.iterator();
        while (it1.next()) |entry| {
            sum1 += entry.value_ptr.*;
        }
    }
    const hash_map_time = timer.read();

    // Iterate ArrayHashMap
    timer.reset();
    var sum2: u64 = 0;
    for (0..iterations) |_| {
        var it2 = array_hash_map.iterator();
        while (it2.next()) |entry| {
            sum2 += entry.value_ptr.*;
        }
    }
    const array_hash_map_time = timer.read();

    std.debug.print("HashMap iteration: {} ns (sum: {})\n", .{ hash_map_time, sum1 });
    std.debug.print("ArrayHashMap iteration: {} ns (sum: {})\n", .{ array_hash_map_time, sum2 });

    if (array_hash_map_time > 0) {
        const speedup = @as(f64, @floatFromInt(hash_map_time)) / @as(f64, @floatFromInt(array_hash_map_time));
        std.debug.print("ArrayHashMap is {d:.2}x faster for iteration\n", .{speedup});
    }
}
```

This example compares HashMap and ArrayHashMap iteration performance. ArrayHashMap's contiguous memory layout provides better cache locality, resulting in faster iteration over the same data.

## Common Pitfalls

### Pitfall 1: Forgetting Container deinit()

Containers that allocate memory must call `deinit()` before going out of scope. Without this cleanup, memory leaks occur.

**Problem:**
```zig
fn processData(allocator: std.mem.Allocator) !void {
    var list = std.ArrayList(u8).init(allocator);
    try list.append(allocator, 'A');
    // Forgot: defer list.deinit(allocator);
    if (someCondition) return error.Failed;  // Leak!
}
```

**Detection:**
Use `std.testing.allocator` in tests. This allocator detects memory leaks automatically:

```zig
test "container cleanup" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit(std.testing.allocator);
    try list.append(std.testing.allocator, 'A');
}
```

If the `defer` is omitted, the test fails with a leak detection error.

**Solution:**
Place `defer` immediately after initialization:

```zig
fn processData(allocator: std.mem.Allocator) !void {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit(allocator);  // Placed immediately
    try list.append(allocator, 'A');
    if (someCondition) return error.Failed;  // No leak
}
```

### Pitfall 2: Incomplete Nested Container Cleanup

Containers containing other containers require multi-level cleanup. Calling `deinit()` on the outer container does not automatically clean inner containers.

**Problem:**
```zig
var outer = std.ArrayList(std.ArrayList(u8)).init(allocator);
defer outer.deinit(allocator);  // Only frees outer, not inner lists!

var inner = std.ArrayList(u8).init(allocator);
try inner.append(allocator, 1);
try outer.append(allocator, inner);
```

**Solution:**
Iterate and clean inner containers before cleaning the outer:

```zig
var outer = std.ArrayList(std.ArrayList(u8)).init(allocator);
defer {
    for (outer.items) |*inner_list| {
        inner_list.deinit(allocator);  // Free each inner
    }
    outer.deinit(allocator);  // Free outer
}
```

### Pitfall 3: HashMap with Allocated Keys or Values

HashMap `deinit()` frees the hash table structure but not allocated keys or values stored as pointers.

**Problem:**
```zig
var cache = std.StringHashMapUnmanaged(*User).init();
defer cache.deinit(allocator);  // Doesn't free User pointers!
```

**Solution:**
Iterate and free values before calling `deinit()`:

```zig
var cache = std.StringHashMapUnmanaged(*User).init();
defer {
    var it = cache.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.*.deinit();  // Clean user object
        allocator.destroy(entry.value_ptr.*);  // Free pointer
    }
    cache.deinit(allocator);  // Free map
}
```

This pattern appears in community documentation on HashMap ownership.[^5]

### Pitfall 4: Pointer Invalidation After Growth

Pointers into container storage become invalid when the container reallocates during growth.

**Problem:**
```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 1);
const ptr = &list.items[0];  // Get pointer to first element

try list.append(allocator, 2);  // May reallocate!
ptr.* = 10;  // Pointer may be invalid
```

If the `append()` causes reallocation, `ptr` points to freed memory. Dereferencing it invokes undefined behavior.

**Solution:**
Use indices instead of pointers:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(allocator, 1);
const index = 0;

try list.append(allocator, 2);
list.items[index] = 10;  // Safe
```

Alternatively, pre-allocate capacity to prevent reallocation:

```zig
var list = std.ArrayList(u32).init(allocator);
try list.ensureTotalCapacity(allocator, 10);
const ptr = &list.items[0];  // Safe until capacity exceeded
try list.append(allocator, 1);
```

### Pitfall 5: Version Migration API Confusion

Code written for Zig 0.14.x fails to compile under Zig 0.15+ due to the unmanaged default change.

**Problem (0.14.x → 0.15+):**
```zig
// This worked in 0.14.x (managed)
var list = std.ArrayList(u32).init(allocator);
defer list.deinit();  // 0.15+: missing allocator parameter
try list.append(42);  // 0.15+: missing allocator parameter
```

**Migration Strategy:**
Search the codebase for container method calls and add allocator parameters:

1. Search for `\.deinit\(\)` without allocator
2. Search for `\.append\(` without allocator as first parameter
3. Search for `\.put\(` in HashMap code without allocator

**Solution:**
Add allocator parameters to all methods:

```zig
// ✅ 0.15+ (unmanaged)
var list = std.ArrayList(u32).init(allocator);
defer list.deinit(allocator);  // Pass allocator
try list.append(allocator, 42);  // Pass allocator
```

Test with `std.testing.allocator` to catch remaining leaks from missed cleanup calls.

## In Practice

Production codebases demonstrate these container patterns at scale.

### TigerBeetle: Static Allocation and Unmanaged Containers

TigerBeetle's architecture mandates static allocation: all memory is allocated at startup, with no dynamic allocation during operation.[^10] This constraint shapes their container usage.

The LSM tree implementation demonstrates extensive use of unmanaged containers with pre-allocated capacity:[^6]

```zig
var scope_rollback_log = try std.ArrayListUnmanaged(Value).initCapacity(
    allocator,
    options.scope_value_count_max,
);
```

Capacity is determined at initialization and never exceeded. The `ArrayListUnmanaged` pattern saves memory overhead while maintaining deterministic allocation behavior.

HashMap usage follows similar patterns, with `HashMapUnmanaged` for sets:[^6]

```zig
pub const Map = std.HashMapUnmanaged(
    Value,
    void,  // Set pattern: no associated data
    struct {
        pub inline fn eql(_: @This(), a: Value, b: Value) bool {
            return key_from_value(&a) == key_from_value(&b);
        }
        pub inline fn hash(_: @This(), value: Value) u64 {
            return stdx.hash_inline(key_from_value(&value));
        }
    },
    50,  // 50% max load factor
);
```

The `void` value type creates a set (membership testing without associated data). Custom hash and equality functions enable value-based rather than pointer-based comparison.

### Ghostty: Capacity Optimization

The Ghostty terminal emulator demonstrates capacity pre-allocation with documented rationale:[^8]

```zig
var args: std.ArrayList([:0]const u8) = try .initCapacity(
    alloc,
    9,  // Covers shell execution (common case)
);
```

The comment explains the design choice: optimize for the common case (shell execution requiring 9 arguments) while allowing growth for uncommon cases. This balances memory efficiency with performance.

### Bun: Arena Allocators with Containers

Bun's snapshot testing implementation uses arena allocators for temporary containers:[^11]

```zig
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();

var result_text = std.ArrayList(u8).init(arena.allocator());
```

The arena provides bulk cleanup. When processing completes, a single `arena.deinit()` frees all containers and their contents at once. This pattern is common in request-scoped or phase-based processing.

### ZLS: MultiArrayList and SegmentedList

The Zig Language Server uses specialized container types for compiler data structures:[^12]

```zig
items: std.MultiArrayList(Item) = .empty,
extra: std.ArrayList(u32) = .empty,
decls: std.SegmentedList(Decl, 0) = .{},
```

`MultiArrayList` uses structure-of-arrays layout for cache efficiency. `SegmentedList` provides stable pointers across resizing, critical for compiler IR where nodes reference each other.

### Mach: Unmanaged Container Aggregation

The Mach game engine's shader compiler demonstrates a struct containing many unmanaged containers:[^13]

```zig
allocator: std.mem.Allocator,
instructions: std.AutoArrayHashMapUnmanaged(Inst, void) = .{},
refs: std.ArrayListUnmanaged(InstIndex) = .{},
strings: std.ArrayListUnmanaged(u8) = .{},
values: std.ArrayListUnmanaged(u8) = .{},
scratch: std.ArrayListUnmanaged(InstIndex) = .{},
global_var_refs: std.AutoArrayHashMapUnmanaged(InstIndex, void) = .{},
globals: std.ArrayListUnmanaged(InstIndex) = .{},
```

Seven unmanaged containers share a single allocator field. This pattern saves 56 bytes compared to using managed variants (7 containers × 8 bytes per allocator pointer). The memory savings are significant for performance-critical graphics code.

## Summary

Zig containers integrate with the explicit allocator model, requiring developers to manage ownership and cleanup. The shift from managed to unmanaged containers as of Zig 0.15 reflects a broader philosophy: explicit allocation sites improve code clarity and reduce memory overhead.

**Key takeaways:**

1. **Unmanaged is default (0.15+):** ArrayList, HashMap, and related containers no longer store allocators. Methods require explicit allocator parameters.

2. **Ownership determines cleanup:** Direct value storage requires cleaning allocated fields. Pointer storage requires both object and pointer cleanup. The container's `deinit()` only frees its internal structure.

3. **Pre-allocate when possible:** `ensureTotalCapacity()` avoids reallocation overhead. Combine with `appendAssumeCapacity()` or `putAssumeCapacity()` for zero-allocation operations.

4. **Reuse containers:** `clearRetainingCapacity()` resets contents while preserving allocated memory, avoiding allocation churn in loops.

5. **Use appropriate variants:** ArrayHashMap for iteration-heavy workloads, HashMap for lookup-heavy. SegmentedList when pointer stability matters. MultiArrayList for cache efficiency.

6. **Arena for bulk cleanup:** When containers share lifetimes, an arena allocator simplifies cleanup by freeing everything at once.

Production codebases demonstrate these patterns at scale. TigerBeetle uses static pre-allocation with unmanaged containers. Ghostty optimizes capacity for common cases. Bun employs arenas for request-scoped processing. ZLS uses specialized containers for compiler data structures. Mach aggregates many unmanaged containers to reduce memory overhead.

The transition from managed to unmanaged containers represents a maturation of Zig's approach to explicit resource management. By making allocation sites visible and eliminating per-container overhead, unmanaged containers provide better composability and clearer code.

## References

[^1]: [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
[^2]: [Ziggit: Embracing Unmanaged](https://ziggit.dev/t/embracing-unmanaged-plans-with-eg-autohashmap/11934)
[^3]: [Zig Standard Library - array_list.zig](https://github.com/ziglang/zig/blob/master/lib/std/array_list.zig)
[^4]: [Hexops - Zig Hashmaps Explained](https://devlog.hexops.com/2022/zig-hashmaps-explained/)
[^5]: [OpenMyMind - Zig's HashMap Part 2](https://www.openmymind.net/Zigs-HashMap-Part-2/)
[^6]: [TigerBeetle lsm/cache_map.zig](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/cache_map.zig)
[^7]: [Bun test/snapshot.zig](https://github.com/oven-sh/bun/blob/main/src/bun.js/test/snapshot.zig)
[^8]: [Ghostty termio/Exec.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig)
[^9]: [Krut's Blog: Memory Leak in Zig](https://iamkroot.github.io/blog/zig-memleak)
[^10]: [TigerBeetle TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
[^11]: [Bun test/snapshot.zig:239](https://github.com/oven-sh/bun/blob/main/src/bun.js/test/snapshot.zig#L239)
[^12]: [ZLS analyser/InternPool.zig](https://github.com/zigtools/zls/blob/master/src/analyser/InternPool.zig)
[^13]: [Mach sysgpu/shader/AstGen.zig](https://github.com/hexops/mach/blob/main/src/sysgpu/shader/AstGen.zig)
