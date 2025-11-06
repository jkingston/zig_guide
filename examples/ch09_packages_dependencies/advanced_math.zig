// Stub advanced_math module for Ch09 examples

pub fn pow(base: i32, exp: u32) i32 {
    var result: i32 = 1;
    var i: u32 = 0;
    while (i < exp) : (i += 1) {
        result *= base;
    }
    return result;
}
