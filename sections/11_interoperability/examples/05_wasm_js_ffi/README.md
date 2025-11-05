# Example 5: WebAssembly JavaScript FFI

## Overview

This example demonstrates compiling Zig to WebAssembly (WASM) and creating a bidirectional interface with JavaScript, including exporting Zig functions, importing JavaScript functions, and managing memory across the boundary.

## Learning Objectives

- Compile Zig to WebAssembly target
- Export Zig functions for JavaScript consumption
- Import JavaScript host functions into WASM
- Handle string passing between JavaScript and WASM
- Manage WASM linear memory from JavaScript
- Work with TypedArrays to access WASM memory

## Architecture

```
JavaScript <--> WASM Linear Memory <--> Zig Code
     ^                                    |
     |                                    |
     +-------- Host Functions ------------+
```

## Key Concepts

### WASM Target Compilation

```zig
const target = b.resolveTargetQuery(.{
    .cpu_arch = .wasm32,
    .os_tag = .freestanding,
});
exe.entry = .disabled; // No main() needed
exe.rdynamic = true;   // Export symbols
```

### Exporting Functions

Use the `export` keyword to make functions available to JavaScript:

```zig
export fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

From JavaScript:

```javascript
const result = wasmInstance.exports.add(5, 7);
```

### Importing Host Functions

Declare JavaScript functions with `extern`:

```zig
extern "c" fn consoleLog(ptr: [*]const u8, len: usize) void;

export fn greet() void {
    const msg = "Hello!";
    consoleLog(msg.ptr, msg.len);
}
```

Provide implementation in JavaScript:

```javascript
const importObject = {
    env: {
        consoleLog: (ptr, len) => {
            const str = readWasmString(ptr, len);
            console.log(str);
        }
    }
};
```

### String Handling

WASM uses linear memory. Pass strings as (pointer, length) pairs:

**From JavaScript to WASM:**

```javascript
function stringToWasm(str) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(str);
    // Copy to WASM memory
    const wasmPtr = new Uint8Array(wasmMemory.buffer, 0, bytes.length);
    wasmPtr.set(bytes);
    return { ptr: 0, len: bytes.length };
}
```

**From WASM to JavaScript:**

```javascript
function readWasmString(ptr, len) {
    const bytes = new Uint8Array(wasmMemory.buffer, ptr, len);
    const decoder = new TextDecoder();
    return decoder.decode(bytes);
}
```

### Memory Management

WASM has a linear memory model. Allocate in Zig, access from JavaScript:

```zig
export fn allocateAndSum(count: i32) [*]i32 {
    const allocator = std.heap.wasm_allocator;
    const slice = allocator.alloc(i32, @intCast(count)) catch return undefined;
    // ... use memory ...
    return slice.ptr;
}

export fn freeMemory(ptr: [*]i32, count: i32) void {
    const allocator = std.heap.wasm_allocator;
    const slice = ptr[0..@intCast(count)];
    allocator.free(slice);
}
```

From JavaScript:

```javascript
const ptr = wasmInstance.exports.allocateAndSum(10);
const view = new Int32Array(wasmMemory.buffer, ptr, 10);
// Use the data...
wasmInstance.exports.freeMemory(ptr, 10);
```

## Building and Running

```bash
# Build the WASM module
zig build

# Serve the web files (requires a local server for CORS)
cd web
python3 -m http.server 8000

# Open browser to http://localhost:8000
```

## Project Structure

```
05_wasm_js_ffi/
├── build.zig              # WASM build configuration
├── src/
│   └── main.zig           # Zig WASM module
└── web/
    ├── index.html         # Demo HTML page
    └── loader.js          # JavaScript loader and glue code
```

## Expected Behavior

The HTML page provides interactive buttons to test:

1. **Arithmetic**: Call exported add/multiply functions
2. **Fibonacci**: Calculate Fibonacci numbers in WASM
3. **String Operations**: Pass strings to WASM, count vowels
4. **Memory Operations**: Allocate/free WASM memory from JS
5. **Callbacks**: WASM calls back to JavaScript functions

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2
- Modern web browsers (Chrome, Firefox, Safari, Edge)
- Node.js 14+ (for server)

## Performance Considerations

1. **Minimize boundary crossings**: Batch operations when possible
2. **Memory allocation**: Reuse buffers instead of allocating repeatedly
3. **String conversion**: UTF-8 encoding/decoding has overhead
4. **Linear memory growth**: Growing memory is expensive

## Common Pitfalls Avoided

1. **String null termination**: WASM uses length-based strings
2. **Memory ownership**: Clear allocation/deallocation pairing
3. **CORS errors**: Using local server for development
4. **Type mismatches**: Using i32 for WASM integers
5. **Memory buffer invalidation**: Accessing correct memory view

## Security Considerations

- Validate all data passed from JavaScript
- Check array bounds before access
- Limit memory allocations
- Validate pointer offsets

## References

- [MDN WebAssembly Guide](https://developer.mozilla.org/en-US/docs/WebAssembly)
- [Zig Language Reference - WASM](https://ziglang.org/documentation/0.15.2/#WebAssembly)
- [WASM Specification](https://webassembly.github.io/spec/)
- [Mach WASM Examples](https://github.com/hexops/mach)
