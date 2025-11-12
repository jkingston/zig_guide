# Chapter 2: Syntax Essentials - Examples

This directory contains working examples demonstrating the syntax concepts covered in Chapter 2.

## Files

- `syntax_demo.zig` - Comprehensive demonstration of Zig syntax fundamentals including:
  - Types and declarations (integers, floats, booleans, bit-width integers)
  - Pointers, arrays, and slices
  - Optionals and error unions
  - Composite types (structs, enums, unions, packed structs)
  - Control flow (if, for, switch)
  - Builtin functions
  - Test cases

## Running the Examples

```bash
# Run the main demo
zig run syntax_demo.zig

# Run tests
zig test syntax_demo.zig
```

## Key Concepts Demonstrated

1. **Type System**: Explicit integer types, bit-width integers, floats
2. **Memory Safety**: Pointers require explicit dereferencing
3. **Composite Types**: Structs with methods, enums, tagged unions, packed structs
4. **Error Handling**: Error unions with `try` and `catch`
5. **Optionals**: Null-safe value handling with `?T` and `orelse`
6. **Control Flow**: If expressions, for loops with indexing, exhaustive switch
7. **Builtins**: Type introspection and conversion functions

Each section in the demo corresponds to a section in Chapter 2 of the guide.
