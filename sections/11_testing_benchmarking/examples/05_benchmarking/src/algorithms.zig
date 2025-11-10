const std = @import("std");

// ============================================================================
// Sum Algorithms: Naive vs Optimized
// ============================================================================

/// Naive sum: Simple loop, no optimizations
/// This is the baseline - straightforward but not optimized
pub fn sumNaive(data: []const i64) i64 {
    var sum: i64 = 0;
    for (data) |value| {
        sum += value;
    }
    return sum;
}

/// Optimized sum: Loop unrolling for better performance
/// This processes 4 elements at a time to reduce loop overhead
/// and enable better CPU pipeline utilization
pub fn sumOptimized(data: []const i64) i64 {
    var sum: i64 = 0;
    var i: usize = 0;

    // Process 4 elements at a time (loop unrolling)
    while (i + 4 <= data.len) : (i += 4) {
        sum += data[i];
        sum += data[i + 1];
        sum += data[i + 2];
        sum += data[i + 3];
    }

    // Handle remaining elements
    while (i < data.len) : (i += 1) {
        sum += data[i];
    }

    return sum;
}

/// SIMD-inspired sum: Process 8 elements with separate accumulators
/// This reduces data dependencies and enables better instruction-level parallelism
pub fn sumSIMD(data: []const i64) i64 {
    var sum0: i64 = 0;
    var sum1: i64 = 0;
    var sum2: i64 = 0;
    var sum3: i64 = 0;
    var sum4: i64 = 0;
    var sum5: i64 = 0;
    var sum6: i64 = 0;
    var sum7: i64 = 0;
    var i: usize = 0;

    // Process 8 elements at a time with separate accumulators
    while (i + 8 <= data.len) : (i += 8) {
        sum0 += data[i];
        sum1 += data[i + 1];
        sum2 += data[i + 2];
        sum3 += data[i + 3];
        sum4 += data[i + 4];
        sum5 += data[i + 5];
        sum6 += data[i + 6];
        sum7 += data[i + 7];
    }

    // Handle remaining elements
    while (i < data.len) : (i += 1) {
        sum0 += data[i];
    }

    return sum0 + sum1 + sum2 + sum3 + sum4 + sum5 + sum6 + sum7;
}

// ============================================================================
// String Search: Naive vs Optimized
// ============================================================================

/// Naive string search: Check every position
/// O(n*m) worst case where n=haystack length, m=needle length
pub fn searchNaive(haystack: []const u8, needle: []const u8) ?usize {
    if (needle.len == 0) return 0;
    if (needle.len > haystack.len) return null;

    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        if (std.mem.eql(u8, haystack[i .. i + needle.len], needle)) {
            return i;
        }
    }
    return null;
}

/// Optimized string search: First check first character, then full match
/// This avoids expensive comparisons when the first character doesn't match
pub fn searchOptimized(haystack: []const u8, needle: []const u8) ?usize {
    if (needle.len == 0) return 0;
    if (needle.len > haystack.len) return null;

    const first_char = needle[0];
    var i: usize = 0;

    while (i <= haystack.len - needle.len) : (i += 1) {
        // Fast path: check first character first
        if (haystack[i] == first_char) {
            // Only do full comparison if first character matches
            if (std.mem.eql(u8, haystack[i .. i + needle.len], needle)) {
                return i;
            }
        }
    }
    return null;
}

// ============================================================================
// Fibonacci: Recursive vs Iterative vs Memoized
// ============================================================================

/// Recursive fibonacci: Exponential time O(2^n)
/// This is intentionally slow to demonstrate the cost of naive recursion
pub fn fibRecursive(n: u32) u64 {
    if (n <= 1) return n;
    return fibRecursive(n - 1) + fibRecursive(n - 2);
}

/// Iterative fibonacci: Linear time O(n)
/// Much faster than recursive for larger values
pub fn fibIterative(n: u32) u64 {
    if (n <= 1) return n;

    var a: u64 = 0;
    var b: u64 = 1;
    var i: u32 = 2;

    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }

    return b;
}

/// Memoized fibonacci with compile-time cache size
/// O(n) time with O(n) space, but much faster for repeated calls
pub fn FibMemoized(comptime max_n: u32) type {
    return struct {
        cache: [max_n + 1]?u64,

        const Self = @This();

        pub fn init() Self {
            var self = Self{
                .cache = [_]?u64{null} ** (max_n + 1),
            };
            self.cache[0] = 0;
            self.cache[1] = 1;
            return self;
        }

        pub fn fib(self: *Self, n: u32) u64 {
            if (n > max_n) @panic("n exceeds max_n");

            if (self.cache[n]) |cached| {
                return cached;
            }

            const result = self.fib(n - 1) + self.fib(n - 2);
            self.cache[n] = result;
            return result;
        }
    };
}

// ============================================================================
// Hash Functions: Simple vs Optimized
// ============================================================================

/// Simple hash: Basic multiplicative hash
/// Easy to understand but not the fastest
pub fn hashSimple(data: []const u8) u64 {
    var hash: u64 = 0;
    for (data) |byte| {
        hash = hash *% 31 +% byte;
    }
    return hash;
}

/// Optimized hash: FNV-1a hash algorithm
/// Better distribution and faster than simple multiplicative hash
pub fn hashFNV1a(data: []const u8) u64 {
    const FNV_OFFSET: u64 = 14695981039346656037;
    const FNV_PRIME: u64 = 1099511628211;

    var hash: u64 = FNV_OFFSET;
    for (data) |byte| {
        hash ^= byte;
        hash *%= FNV_PRIME;
    }
    return hash;
}

/// Optimized hash: Process 8 bytes at a time
/// This is much faster for large inputs by reducing loop iterations
pub fn hashOptimized(data: []const u8) u64 {
    const FNV_OFFSET: u64 = 14695981039346656037;
    const FNV_PRIME: u64 = 1099511628211;

    var hash: u64 = FNV_OFFSET;
    var i: usize = 0;

    // Process 8 bytes at a time
    while (i + 8 <= data.len) : (i += 8) {
        const chunk = std.mem.readInt(u64, data[i..][0..8], .little);
        hash ^= chunk;
        hash *%= FNV_PRIME;
    }

    // Process remaining bytes
    while (i < data.len) : (i += 1) {
        hash ^= data[i];
        hash *%= FNV_PRIME;
    }

    return hash;
}

// ============================================================================
// Array Operations: Different Access Patterns
// ============================================================================

/// Row-major traversal: Cache-friendly for row-major matrices
pub fn sumMatrix2DRowMajor(matrix: []const []const i32) i64 {
    var sum: i64 = 0;
    for (matrix) |row| {
        for (row) |value| {
            sum += value;
        }
    }
    return sum;
}

/// Flat array traversal: Best cache locality
pub fn sumMatrixFlat(matrix: []const i32, width: usize) i64 {
    _ = width; // Just for documentation
    var sum: i64 = 0;
    for (matrix) |value| {
        sum += value;
    }
    return sum;
}

// ============================================================================
// Integer Operations: Division vs Multiplication
// ============================================================================

/// Division-based calculation: Slower on most CPUs
pub fn calculateWithDivision(n: u64) u64 {
    var result: u64 = 0;
    var i: u64 = 1;
    while (i <= n) : (i += 1) {
        result += i / 3; // Division is slow
    }
    return result;
}

/// Multiplication-based calculation: Faster alternative
/// When possible, replace division with multiplication and shift
pub fn calculateWithMultiplication(n: u64) u64 {
    var result: u64 = 0;
    var i: u64 = 1;
    while (i <= n) : (i += 1) {
        // Approximate i/3 using multiplication and shift
        // This is faster but note: this is an approximation
        result += (i * 0x55555556) >> 32; // Approximates /3
    }
    return result;
}

// ============================================================================
// Memory Allocation Patterns
// ============================================================================

/// Allocate many small objects: High allocation overhead
pub fn allocateManySmall(allocator: std.mem.Allocator, count: usize) !void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const ptr = try allocator.create(u64);
        std.mem.doNotOptimizeAway(ptr);
        allocator.destroy(ptr);
    }
}

/// Allocate one large object: Lower allocation overhead
pub fn allocateOneLarge(allocator: std.mem.Allocator, count: usize) !void {
    const ptr = try allocator.alloc(u64, count);
    defer allocator.free(ptr);
    std.mem.doNotOptimizeAway(&ptr);
}

// ============================================================================
// Comparison Functions for Benchmarking
// ============================================================================

/// Compare using branching
pub fn maxWithBranch(a: i64, b: i64) i64 {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

/// Compare using branchless approach
/// Can be faster on modern CPUs with branch prediction issues
pub fn maxBranchless(a: i64, b: i64) i64 {
    const diff = a - b;
    const sign_bit = @as(u64, @bitCast(diff)) >> 63;
    return if (sign_bit == 0) a else b;
}

// ============================================================================
// String Building: Concatenation vs ArrayList
// ============================================================================

/// Build string with concatenation: Many allocations
pub fn buildStringConcat(allocator: std.mem.Allocator, count: usize) ![]u8 {
    var result = try allocator.alloc(u8, 0);
    errdefer allocator.free(result);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const old_len = result.len;
        result = try allocator.realloc(result, old_len + 5);
        @memcpy(result[old_len..][0..5], "hello");
    }

    return result;
}

/// Build string with ArrayList: Amortized growth
pub fn buildStringArrayList(allocator: std.mem.Allocator, count: usize) ![]u8 {
    var list = std.ArrayList(u8).init(allocator);
    errdefer list.deinit();

    var i: usize = 0;
    while (i < count) : (i += 1) {
        try list.appendSlice("hello");
    }

    return list.toOwnedSlice();
}

// ============================================================================
// Bounds Checking: Safe vs Unsafe
// ============================================================================

/// Access with bounds checking (default in Zig)
pub fn sumWithBoundsCheck(data: []const i64) i64 {
    var sum: i64 = 0;
    for (data, 0..) |_, i| {
        sum += data[i];
    }
    return sum;
}

/// Access without bounds checking (only use when guaranteed safe)
pub fn sumWithoutBoundsCheck(data: []const i64) i64 {
    var sum: i64 = 0;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        // In ReleaseFast mode, this skips bounds checking
        sum += data[i];
    }
    return sum;
}
