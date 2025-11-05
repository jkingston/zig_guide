const std = @import("std");

// Import JavaScript host functions
extern "c" fn consoleLog(ptr: [*]const u8, len: usize) void;
extern "c" fn alertMessage(ptr: [*]const u8, len: usize) void;

// Export simple arithmetic function to JavaScript
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

// Export function that returns a value
export fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

// Export function that works with memory
export fn fibonacci(n: i32) i32 {
    if (n <= 1) return n;

    var a: i32 = 0;
    var b: i32 = 1;
    var i: i32 = 2;

    while (i <= n) : (i += 1) {
        const temp = a + b;
        a = b;
        b = temp;
    }

    return b;
}

// Export function that logs to JavaScript console
export fn greet(name_ptr: [*]const u8, name_len: usize) void {
    const greeting = "Hello, ";
    consoleLog(greeting.ptr, greeting.len);
    consoleLog(name_ptr, name_len);
    consoleLog("!", 1);
}

// Export function that demonstrates memory allocation
// Returns pointer to allocated memory containing sum
export fn allocateAndSum(count: i32) [*]i32 {
    const allocator = std.heap.wasm_allocator;

    const slice = allocator.alloc(i32, @intCast(count)) catch {
        return undefined;
    };

    var sum: i32 = 0;
    for (slice, 0..) |*item, i| {
        item.* = @intCast(i + 1);
        sum += item.*;
    }

    // Store sum at first position
    slice[0] = sum;

    return slice.ptr;
}

// Export function to free memory allocated by allocateAndSum
export fn freeMemory(ptr: [*]i32, count: i32) void {
    const allocator = std.heap.wasm_allocator;
    const slice = ptr[0..@intCast(count)];
    allocator.free(slice);
}

// Export function that processes a string from JavaScript
export fn processString(str_ptr: [*]const u8, str_len: usize) i32 {
    const str = str_ptr[0..str_len];

    var count: i32 = 0;
    for (str) |char| {
        if (char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u') {
            count += 1;
        }
    }

    return count;
}

// Export function that calls back to JavaScript
export fn demonstrateCallback(value: i32) void {
    const msg = "Callback from WASM with value: ";
    consoleLog(msg.ptr, msg.len);

    // Convert i32 to string and log
    var buf: [32]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{value}) catch "error";
    consoleLog(str.ptr, str.len);
}

// Memory information export
export fn getMemoryInfo() i32 {
    // Return current memory pages (each page is 64KB)
    return @intCast(@wasmMemorySize(0));
}
