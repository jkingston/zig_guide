const std = @import("std");

/// Calculate factorial of n
pub fn factorial(n: u32) u64 {
    if (n == 0) return 1;
    var result: u64 = 1;
    var i: u32 = 1;
    while (i <= n) : (i += 1) {
        result *= i;
    }
    return result;
}

/// Generate Fibonacci sequence up to n terms
/// Caller owns returned slice
pub fn fibonacci(n: u32, allocator: std.mem.Allocator) ![]const u64 {
    // ✅ 0.15+: ArrayList is unmanaged, no stored allocator
    var list = std.ArrayList(u64).empty;
    errdefer list.deinit(allocator);

    if (n == 0) return list.toOwnedSlice(allocator);

    try list.append(allocator, 0);
    if (n == 1) return list.toOwnedSlice(allocator);

    try list.append(allocator, 1);
    if (n == 2) return list.toOwnedSlice(allocator);

    var i: u32 = 2;
    while (i < n) : (i += 1) {
        const prev1 = list.items[list.items.len - 1];
        const prev2 = list.items[list.items.len - 2];
        try list.append(allocator, prev1 + prev2);
    }

    return list.toOwnedSlice(allocator);
}

/// Generate all prime numbers up to limit
/// Caller owns returned slice
pub fn primes(limit: u32, allocator: std.mem.Allocator) ![]const u32 {
    // ✅ 0.15+: ArrayList is unmanaged, no stored allocator
    var list = std.ArrayList(u32).empty;
    errdefer list.deinit(allocator);

    if (limit < 2) return list.toOwnedSlice(allocator);

    var n: u32 = 2;
    while (n <= limit) : (n += 1) {
        if (isPrime(n)) {
            try list.append(allocator, n);
        }
    }

    return list.toOwnedSlice(allocator);
}

fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    var i: u32 = 3;
    while (i * i <= n) : (i += 2) {
        if (n % i == 0) return false;
    }
    return true;
}
