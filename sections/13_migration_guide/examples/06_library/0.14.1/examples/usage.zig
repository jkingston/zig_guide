const std = @import("std");
const mathlib = @import("mathlib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 🕐 0.14.x: Use old I/O API
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Math Library Example\n", .{});
    try stdout.print("====================\n\n", .{});

    // Factorial
    const fact10 = mathlib.factorial(10);
    try stdout.print("Factorial of 10: {d}\n", .{fact10});

    // Fibonacci
    const fib = try mathlib.fibonacci(10, allocator);
    defer allocator.free(fib);

    try stdout.print("First 10 Fibonacci numbers: ", .{});
    for (fib, 0..) |num, i| {
        if (i > 0) try stdout.print(", ", .{});
        try stdout.print("{d}", .{num});
    }
    try stdout.print("\n", .{});

    // Primes
    const prime_list = try mathlib.primes(50, allocator);
    defer allocator.free(prime_list);

    try stdout.print("Primes up to 50: ", .{});
    for (prime_list, 0..) |num, i| {
        if (i > 0) try stdout.print(", ", .{});
        try stdout.print("{d}", .{num});
    }
    try stdout.print("\n", .{});
}
