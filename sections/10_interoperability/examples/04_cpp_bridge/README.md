# Example 4: C++ Interoperability via Extern "C" Bridge

## Overview

This example demonstrates how to safely interoperate with C++ code from Zig using an `extern "C"` bridge layer. Since Zig cannot directly call C++ methods or use C++ classes, we create a C-compatible API wrapper.

## Learning Objectives

- Understand C++ interop limitations in Zig
- Create extern "C" wrapper functions for C++ APIs
- Use opaque pointers for C++ objects
- Handle C++ exceptions at the C boundary
- Manage C++ resources from Zig
- Convert between C++ std::string and C strings

## Architecture

```
Zig Code ←→ C Bridge ←→ C++ Implementation
```

The C bridge layer provides a C-compatible API that Zig can call, while internally using C++ classes and features.

## Key Concepts

### Extern "C" Linkage

C++ mangles function names for overloading. `extern "C"` prevents this:

```cpp
#ifdef __cplusplus
extern "C" {
#endif

void my_function(); // C-compatible linkage

#ifdef __cplusplus
}
#endif
```

### Opaque Pointers

C++ objects are hidden behind opaque pointers:

```cpp
// Header (C-compatible)
typedef struct MyCppClass_Opaque MyCppClass_Opaque;

// Implementation (C++)
static MyCppClass* cast(MyCppClass_Opaque* obj) {
    return reinterpret_cast<MyCppClass*>(obj);
}
```

### Exception Handling

C++ exceptions must not cross the C/Zig boundary:

```cpp
extern "C" int MyCppClass_getValue(const MyCppClass_Opaque* obj) {
    try {
        return cast(obj)->getValue();
    } catch (...) {
        return 0; // Safe default on error
    }
}
```

### Resource Management

Pair create/destroy functions:

```zig
const obj = c.MyCppClass_create(42);
defer c.MyCppClass_destroy(obj);
```

### String Conversion

C++ `std::string` → C string requires allocation:

```cpp
char* MyCppClass_getMessage(const MyCppClass_Opaque* obj) {
    std::string msg = cast(obj)->getMessage();
    char* result = malloc(msg.length() + 1);
    strcpy(result, msg.c_str());
    return result;
}

void MyCppClass_freeString(char* str) {
    free(str);
}
```

From Zig:

```zig
const msg = c.MyCppClass_getMessage(obj);
if (msg != null) {
    std.debug.print("{s}\n", .{msg});
    c.MyCppClass_freeString(msg); // Must free
}
```

## Building and Running

```bash
# Build the example
zig build

# Run the example
zig build run
```

## Expected Output

```
=== C++ Bridge Demo ===

Created C++ object
Initial value: 42
After increment: 43
After setValue(100): 100

Current message: Default message
Updated message: Hello from Zig!

Sum of values: 17.50

=== Demo Complete ===
```

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2
- Requires C++17 compiler (g++, clang++)

## Best Practices Demonstrated

1. **Clear boundaries**: C bridge completely separates Zig from C++
2. **Exception safety**: All C++ exceptions caught at boundary
3. **Resource safety**: Explicit create/destroy pairing
4. **Null safety**: Checking pointers before use
5. **Memory ownership**: Clear documentation of who frees what

## Common Pitfalls Avoided

1. **Exception leakage**: Never let C++ exceptions reach Zig
2. **Name mangling**: Using `extern "C"` for all bridge functions
3. **Memory leaks**: Providing free functions for allocated strings
4. **Object lifetime**: Using defer for cleanup
5. **Type exposure**: Hiding C++ types behind opaque pointers

## Limitations

- Cannot directly use C++ templates from Zig
- Cannot call C++ virtual methods directly
- Cannot use C++ operator overloading
- Cannot inherit from C++ classes
- Must manually create bridge for each C++ class

## Alternative Approaches

For extensive C++ integration, consider:
- Auto-generating bridge code
- Using existing C APIs when available
- Rewriting critical components in Zig

## References

- [Bun C++ Integration](https://github.com/oven-sh/bun) - Production example of Zig/C++ interop
- [Zig Language Reference - C Interop](https://ziglang.org/documentation/0.15.2/#C)
- [C++ ABI Compatibility](https://itanium-cxx-abi.github.io/cxx-abi/)
