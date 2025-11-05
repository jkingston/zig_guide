const std = @import("std");

// CPU-intensive functions that create hotspots for profilers
// These functions are designed to:
// 1. Show up clearly in CPU profilers (Callgrind, perf)
// 2. Demonstrate different call patterns (recursive, iterative, nested loops)
// 3. Have measurable performance characteristics
// 4. Show call graph relationships

/// Recursive Fibonacci - creates deep call stack, excellent for profiler demos
/// Expected profiler behavior:
/// - Deep call tree visible in call graph
/// - High instruction count
/// - Many function calls
/// - Shows recursive overhead
pub fn fibonacci(n: u32) u64 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

/// Generate prime numbers up to limit
/// Expected profiler behavior:
/// - High CPU time in isPrime function
/// - Nested loop overhead visible
/// - ArrayList append operations visible
pub fn generatePrimes(allocator: std.mem.Allocator, limit: u32, primes: *std.ArrayList(u32)) !void {
    if (limit < 2) return;

    try primes.append(2);

    var candidate: u32 = 3;
    while (candidate <= limit) : (candidate += 2) {
        if (isPrime(candidate)) {
            try primes.append(candidate);
        }
    }
}

/// Check if a number is prime (CPU-intensive for large numbers)
/// Expected profiler behavior:
/// - Shows up as a hot function
/// - High instruction count
/// - Called many times from generatePrimes
fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    var i: u32 = 3;
    const limit = @as(u32, @intFromFloat(@sqrt(@as(f64, @floatFromInt(n))))) + 1;
    while (i <= limit) : (i += 2) {
        if (n % i == 0) return false;
    }
    return true;
}

/// Matrix operations - demonstrates nested loops and cache effects
/// Expected profiler behavior:
/// - High instruction count in inner loops
/// - Cache miss effects may be visible in some profilers
/// - Memory access patterns visible

pub fn createMatrix(allocator: std.mem.Allocator, size: usize) ![][]f64 {
    var matrix = try allocator.alloc([]f64, size);
    errdefer allocator.free(matrix);

    for (matrix, 0..) |*row, i| {
        row.* = try allocator.alloc(f64, size);
        errdefer {
            for (matrix[0..i]) |prev_row| {
                allocator.free(prev_row);
            }
        }

        // Initialize with some values
        for (row.*, 0..) |*cell, j| {
            cell.* = @floatFromInt((i + j) % 100);
        }
    }

    return matrix;
}

pub fn destroyMatrix(allocator: std.mem.Allocator, matrix: [][]f64) void {
    for (matrix) |row| {
        allocator.free(row);
    }
    allocator.free(matrix);
}

/// Matrix multiplication - classic CPU-intensive operation
/// Expected profiler behavior:
/// - Dominant function in CPU time
/// - Nested loop overhead clearly visible
/// - Good demonstration of O(n^3) complexity
pub fn multiplyMatrices(
    allocator: std.mem.Allocator,
    a: [][]f64,
    b: [][]f64,
    size: usize,
) ![][]f64 {
    var result = try allocator.alloc([]f64, size);
    errdefer allocator.free(result);

    for (result, 0..) |*row, i| {
        row.* = try allocator.alloc(f64, size);
        errdefer {
            for (result[0..i]) |prev_row| {
                allocator.free(prev_row);
            }
        }

        for (row.*, 0..) |*cell, j| {
            var sum: f64 = 0.0;
            for (0..size) |k| {
                sum += a[i][k] * b[k][j];
            }
            cell.* = sum;
        }
    }

    return result;
}

/// String processing - demonstrates allocation and iteration patterns
/// Expected profiler behavior:
/// - Shows string iteration overhead
/// - Branch prediction effects in whitespace checks
/// - Good for demonstrating real-world text processing
pub fn countWords(text: []const u8) usize {
    var count: usize = 0;
    var in_word = false;

    for (text) |c| {
        if (isWhitespace(c)) {
            in_word = false;
        } else if (!in_word) {
            in_word = true;
            count += 1;
        }
    }

    return count;
}

fn isWhitespace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

/// Compute hash of data - demonstrates bit operations and loops
/// Expected profiler behavior:
/// - Shows bit operation overhead
/// - Loop iteration costs
/// - Integer arithmetic patterns
pub fn computeHash(data: []const u8) u64 {
    var hash: u64 = 5381;

    for (data) |byte| {
        hash = ((hash << 5) +% hash) +% byte; // hash * 33 + byte
    }

    return hash;
}

/// Bubble sort - intentionally inefficient for demonstration
/// Expected profiler behavior:
/// - High instruction count
/// - Nested loop overhead
/// - Branch misprediction costs
/// - Good example of what NOT to optimize without profiling first
pub fn bubbleSort(array: []i32) void {
    if (array.len <= 1) return;

    var swapped = true;
    while (swapped) {
        swapped = false;
        for (0..array.len - 1) |i| {
            if (array[i] > array[i + 1]) {
                const temp = array[i];
                array[i] = array[i + 1];
                array[i + 1] = temp;
                swapped = true;
            }
        }
    }
}

/// Simulate complex calculation with multiple function calls
/// Expected profiler behavior:
/// - Call graph showing relationships
/// - Distribution of time across helper functions
/// - Demonstrates profiling call chains
pub fn complexCalculation(x: f64, y: f64) f64 {
    const step1 = helperFunction1(x);
    const step2 = helperFunction2(y);
    const step3 = helperFunction3(step1, step2);
    return step3;
}

fn helperFunction1(x: f64) f64 {
    var result = x;
    for (0..100) |_| {
        result = @sqrt(result + 1.0);
    }
    return result;
}

fn helperFunction2(y: f64) f64 {
    var result = y;
    for (0..100) |_| {
        result = @sin(result) * @cos(result);
    }
    return result;
}

fn helperFunction3(a: f64, b: f64) f64 {
    return @exp(a) + @log(b + 1.0);
}

test "fibonacci correctness" {
    try std.testing.expectEqual(@as(u64, 0), fibonacci(0));
    try std.testing.expectEqual(@as(u64, 1), fibonacci(1));
    try std.testing.expectEqual(@as(u64, 1), fibonacci(2));
    try std.testing.expectEqual(@as(u64, 55), fibonacci(10));
}

test "prime generation" {
    var primes = std.ArrayList(u32).init(std.testing.allocator);
    defer primes.deinit();

    try generatePrimes(std.testing.allocator, 20, &primes);

    const expected = [_]u32{ 2, 3, 5, 7, 11, 13, 17, 19 };
    try std.testing.expectEqualSlices(u32, &expected, primes.items);
}

test "word counting" {
    try std.testing.expectEqual(@as(usize, 0), countWords(""));
    try std.testing.expectEqual(@as(usize, 1), countWords("hello"));
    try std.testing.expectEqual(@as(usize, 5), countWords("the quick brown fox jumps"));
    try std.testing.expectEqual(@as(usize, 3), countWords("  spaced   out  "));
}
