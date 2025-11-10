const std = @import("std");

// Memory-intensive operations for heap profiling
// These functions are designed to:
// 1. Show clear patterns in heap profilers (Massif)
// 2. Demonstrate different allocation patterns
// 3. Show heap growth and shrinkage
// 4. Demonstrate peak memory usage

/// Allocate a large buffer
/// Expected profiler behavior:
/// - Visible spike in heap usage when called
/// - Shows allocation location in stack trace
/// - Peak memory usage attribution
pub fn allocateLargeBuffer(allocator: std.mem.Allocator, size: usize) ![]u8 {
    return try allocator.alloc(u8, size);
}

pub fn freeLargeBuffer(allocator: std.mem.Allocator, buffer: []u8) void {
    allocator.free(buffer);
}

/// Fill buffer with data (demonstrates memory writes)
/// Expected profiler behavior:
/// - CPU cache effects may be visible
/// - Memory bandwidth usage
pub fn fillBuffer(buffer: []u8, value: u8) void {
    @memset(buffer, value);
}

/// Allocate many small chunks
/// Expected profiler behavior:
/// - Shows allocation pattern overhead
/// - Many small allocations visible in stack trace
/// - Allocator metadata overhead becomes visible
/// - Good for seeing allocation hotspots
pub fn allocateManySmall(
    allocator: std.mem.Allocator,
    count: usize,
    size_each: usize,
) !std.ArrayList([]u8) {
    var chunks = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (chunks.items) |chunk| {
            allocator.free(chunk);
        }
        chunks.deinit();
    }

    for (0..count) |_| {
        const chunk = try allocator.alloc(u8, size_each);
        try chunks.append(chunk);
    }

    return chunks;
}

pub fn freeManySmall(allocator: std.mem.Allocator, chunks: std.ArrayList([]u8)) void {
    for (chunks.items) |chunk| {
        allocator.free(chunk);
    }
    chunks.deinit();
}

/// Copy data between buffers (demonstrates memory bandwidth)
/// Expected profiler behavior:
/// - Memory copy overhead
/// - Cache effects
pub fn copyData(src: []const u8, dst: []u8) void {
    std.debug.assert(dst.len >= src.len);
    @memcpy(dst[0..src.len], src);
}

/// Build a complex data structure
/// Expected profiler behavior:
/// - Heap growth over time
/// - Multiple allocation sites in call stack
/// - HashMap allocation overhead
/// - String duplication overhead
pub fn buildDataStructure(
    allocator: std.mem.Allocator,
    entry_count: usize,
) !std.StringHashMap(DataEntry) {
    var map = std.StringHashMap(DataEntry).init(allocator);
    errdefer map.deinit();

    for (0..entry_count) |i| {
        // Create key (allocates)
        const key = try std.fmt.allocPrint(allocator, "key_{d}", .{i});
        errdefer allocator.free(key);

        // Create value (allocates)
        const value = DataEntry{
            .id = i,
            .data = try allocator.alloc(u8, 100),
            .name = try std.fmt.allocPrint(allocator, "entry_{d}", .{i}),
        };
        errdefer {
            allocator.free(value.data);
            allocator.free(value.name);
        }

        // Initialize data
        @memset(value.data, @intCast(i % 256));

        try map.put(key, value);
    }

    return map;
}

pub fn destroyDataStructure(allocator: std.mem.Allocator, map: std.StringHashMap(DataEntry)) void {
    var it = map.iterator();
    while (it.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        allocator.free(entry.value_ptr.data);
        allocator.free(entry.value_ptr.name);
    }
    map.deinit();
}

pub const DataEntry = struct {
    id: usize,
    data: []u8,
    name: []const u8,
};

/// Allocate and grow an ArrayList progressively
/// Expected profiler behavior:
/// - Shows ArrayList reallocation pattern
/// - Heap growth in steps (capacity doubling)
/// - Memory usage over time
pub fn growArrayList(allocator: std.mem.Allocator, target_size: usize) !std.ArrayList(u64) {
    var list = std.ArrayList(u64).init(allocator);
    errdefer list.deinit();

    for (0..target_size) |i| {
        try list.append(i);
    }

    return list;
}

/// Create a linked list structure
/// Expected profiler behavior:
/// - Many individual allocations (one per node)
/// - Shows linked structure overhead
/// - Pointer chasing effects
pub fn createLinkedList(allocator: std.mem.Allocator, length: usize) !*Node {
    if (length == 0) return error.InvalidLength;

    var head = try allocator.create(Node);
    head.* = Node{
        .value = 0,
        .next = null,
    };

    var current = head;
    for (1..length) |i| {
        const node = try allocator.create(Node);
        node.* = Node{
            .value = i,
            .next = null,
        };
        current.next = node;
        current = node;
    }

    return head;
}

pub fn destroyLinkedList(allocator: std.mem.Allocator, head: *Node) void {
    var current: ?*Node = head;
    while (current) |node| {
        const next = node.next;
        allocator.free(node);
        current = next;
    }
}

pub const Node = struct {
    value: usize,
    next: ?*Node,
};

/// Allocate a tree structure
/// Expected profiler behavior:
/// - Shows recursive allocation pattern
/// - Tree depth visible in allocation stack traces
/// - Memory usage growth with tree size
pub fn createBinaryTree(allocator: std.mem.Allocator, depth: usize) !*TreeNode {
    if (depth == 0) return error.InvalidDepth;

    var root = try allocator.create(TreeNode);
    root.* = TreeNode{
        .value = 0,
        .left = null,
        .right = null,
    };

    if (depth > 1) {
        root.left = try createBinaryTree(allocator, depth - 1);
        root.right = try createBinaryTree(allocator, depth - 1);
    }

    return root;
}

pub fn destroyBinaryTree(allocator: std.mem.Allocator, node: *TreeNode) void {
    if (node.left) |left| {
        destroyBinaryTree(allocator, left);
    }
    if (node.right) |right| {
        destroyBinaryTree(allocator, right);
    }
    allocator.free(node);
}

pub const TreeNode = struct {
    value: i32,
    left: ?*TreeNode,
    right: ?*TreeNode,
};

/// Create fragmented memory pattern
/// Expected profiler behavior:
/// - Shows interleaved allocations
/// - Memory fragmentation effects
/// - Allocator overhead
pub fn createFragmentedAllocation(
    allocator: std.mem.Allocator,
    iterations: usize,
) !std.ArrayList([]u8) {
    var chunks = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (chunks.items) |chunk| {
            allocator.free(chunk);
        }
        chunks.deinit();
    }

    for (0..iterations) |i| {
        // Alternate between large and small allocations
        const size = if (i % 2 == 0) 1024 else 32;
        const chunk = try allocator.alloc(u8, size);
        try chunks.append(chunk);
    }

    return chunks;
}

/// Demonstrate memory leak scenario (for educational purposes)
/// WARNING: This intentionally leaks memory for demonstration
/// Expected profiler behavior:
/// - Shows memory not being freed
/// - Heap usage continues to grow
/// - Allocation site visible in profiler
pub fn demonstrateMemoryLeak(allocator: std.mem.Allocator, size: usize) !void {
    // Intentional leak - allocated but never freed
    const leaked = try allocator.alloc(u8, size);
    _ = leaked; // Suppress unused warning

    // In a real application, you would need to keep track of this
    // allocation and free it later. This is for demonstration only.
}

/// Allocate temporary buffers in a loop
/// Expected profiler behavior:
/// - Shows allocation churn
/// - Sawtooth pattern in heap usage
/// - Allocator overhead from repeated alloc/free
pub fn temporaryAllocations(allocator: std.mem.Allocator, iterations: usize) !void {
    for (0..iterations) |i| {
        const buffer = try allocator.alloc(u8, 4096);
        defer allocator.free(buffer);

        // Do some work with the buffer
        @memset(buffer, @intCast(i % 256));
    }
}

/// Demonstrate arena allocator pattern
/// Expected profiler behavior:
/// - Single large allocation for arena
/// - Many sub-allocations within arena
/// - Bulk deallocation at end
pub fn useArenaAllocator(backing_allocator: std.mem.Allocator, operations: usize) !void {
    var arena = std.heap.ArenaAllocator.init(backing_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Many allocations within the arena
    for (0..operations) |i| {
        const buffer = try allocator.alloc(u8, 128);
        @memset(buffer, @intCast(i % 256));
        // Note: individual allocations don't need to be freed
    }

    // All freed at once when arena is deinitialized
}

test "large buffer allocation" {
    const buffer = try allocateLargeBuffer(std.testing.allocator, 1024);
    defer freeLargeBuffer(std.testing.allocator, buffer);

    try std.testing.expectEqual(@as(usize, 1024), buffer.len);
}

test "many small allocations" {
    var chunks = try allocateManySmall(std.testing.allocator, 10, 32);
    defer freeManySmall(std.testing.allocator, chunks);

    try std.testing.expectEqual(@as(usize, 10), chunks.items.len);
    for (chunks.items) |chunk| {
        try std.testing.expectEqual(@as(usize, 32), chunk.len);
    }
}

test "data structure building" {
    var data = try buildDataStructure(std.testing.allocator, 10);
    defer destroyDataStructure(std.testing.allocator, data);

    try std.testing.expectEqual(@as(usize, 10), data.count());
}

test "linked list creation" {
    const head = try createLinkedList(std.testing.allocator, 5);
    defer destroyLinkedList(std.testing.allocator, head);

    var count: usize = 0;
    var current: ?*Node = head;
    while (current) |node| : (current = node.next) {
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 5), count);
}

test "binary tree creation" {
    const root = try createBinaryTree(std.testing.allocator, 3);
    defer destroyBinaryTree(std.testing.allocator, root);

    // Tree with depth 3 should have 7 nodes (1 + 2 + 4)
    try std.testing.expect(root.left != null);
    try std.testing.expect(root.right != null);
}
