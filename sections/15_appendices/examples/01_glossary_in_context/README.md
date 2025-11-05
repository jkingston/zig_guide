# Example 1: Glossary Terms in Context

This example demonstrates how Zig glossary terms appear in real code. Each section is annotated with the glossary term being illustrated.

## Glossary Terms Demonstrated

### Memory Management
- **Allocator**: Interface for memory allocation
- **GPA (GeneralPurposeAllocator)**: Production allocator with safety checks
- **ArenaAllocator**: Bulk cleanup allocator
- **defer**: Execute code at scope exit (LIFO order)

### Type System
- **Slice** (`[]T`): Runtime-sized view into memory
- **Optional** (`?T`): Type that may or may not contain a value
- **Error Union** (`!T`): Type combining error set with success type
- **anytype**: Generic parameter inferred at compile time

### Standard Library
- **ArrayList**: Dynamic array container
- **HashMap**: Key-value storage
- **Writer**: Generic I/O interface for output
- **std.testing.allocator**: Test allocator with leak detection

### Language Features
- **comptime**: Compile-time execution
- **try**: Error propagation keyword
- **catch**: Error handling keyword
- **orelse**: Optional default value operator
- **@errorName**: Convert error to string

### Patterns
- **init/deinit**: Standard resource management pattern
- **Self parameter**: `*Self` for mutation, `*const Self` for reading
- **test block**: Unit testing embedded in source
- **Sentinel-terminated**: Null-terminated strings ([*:0]const u8)

## Running the Example

```bash
# Compile and run
zig build-exe src/main.zig
./main

# Run tests
zig test src/main.zig
```

## Expected Output

```
List last value: 255
Factorial of 10 (computed at comptime): 3628800
Caught error: InvalidInput
Key 1 maps to: first
C string: C compatible string
Resources initialized
Resource 1 initialized
Resource 2 initialized
Resource 2 deinitialized
Resource 1 deinitialized
Writing to stdout using Writer interface
Value: 42
Value: Hello
Value: 3.14e0
```

## Cross-References

- **Chapter 2**: Language Idioms (defer, error handling, comptime)
- **Chapter 3**: Memory & Allocators (allocator types, arena pattern)
- **Chapter 4**: Collections & Containers (ArrayList, HashMap)
- **Chapter 5**: I/O & Streams (Writer interface)
- **Chapter 6**: Error Handling (error unions, try/catch)
- **Chapter 12**: Testing (test blocks, assertions)

## Version Compatibility

This example works on both Zig 0.14.x and 0.15.x with minor adjustments:

**0.15+ changes:**
- ArrayList.deinit() requires allocator parameter
- Use `defer list.deinit(arena_allocator);` instead of `defer list.deinit();`

The example demonstrates how glossary terms interconnect in real Zig code, providing a practical reference for the terminology defined in the Appendices chapter.
