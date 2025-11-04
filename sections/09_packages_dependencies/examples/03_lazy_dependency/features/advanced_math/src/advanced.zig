const std = @import("std");

pub fn pow(base: i32, exp: u32) i32 {
    var result: i32 = 1;
    var i: u32 = 0;
    while (i < exp) : (i += 1) {
        result *= base;
    }
    return result;
}

pub fn factorial(n: u32) u32 {
    if (n == 0) return 1;
    return n * factorial(n - 1);
}
