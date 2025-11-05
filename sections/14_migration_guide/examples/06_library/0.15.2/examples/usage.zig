const std = @import("std");
const mathlib = @import("mathlib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ✅ 0.15+: Use new I/O API with buffering
    var stdout_buf: [512]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    try stdout.interface.print("Math Library Example\n", .{});
    try stdout.interface.print("====================\n\n", .{});

    // Factorial
    const fact10 = mathlib.factorial(10);
    try stdout.interface.print("Factorial of 10: {d}\n", .{fact10});

    // Fibonacci
    const fib = try mathlib.fibonacci(10, allocator);
    defer allocator.free(fib);

    try stdout.interface.print("First 10 Fibonacci numbers: ", .{});
    for (fib, 0..) |num, i| {
        if (i > 0) try stdout.interface.print(", ", .{});
        try stdout.interface.print("{d}", .{num});
    }
    try stdout.interface.print("\n", .{});

    // Primes
    const prime_list = try mathlib.primes(50, allocator);
    defer allocator.free(prime_list);

    try stdout.interface.print("Primes up to 50: ", .{});
    for (prime_list, 0..) |num, i| {
        if (i > 0) try stdout.interface.print(", ", .{});
        try stdout.interface.print("{d}", .{num});
    }
    try stdout.interface.print("\n", .{});

    try stdout.interface.flush();
}
