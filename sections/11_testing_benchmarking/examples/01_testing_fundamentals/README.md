# Example 1: Testing Fundamentals

This example demonstrates the fundamental concepts of Zig's testing framework, including test blocks, assertions, memory leak detection, and doctest integration.

## Learning Objectives

After working through this example, you will understand:

1. **Test Block Syntax** - How to write test blocks and when they are executed
2. **Assertion Functions** - Complete coverage of `std.testing` assertion API
3. **Memory Leak Detection** - How `std.testing.allocator` automatically detects leaks
4. **Error Testing** - How to test functions that return errors
5. **Type Testing** - Testing structs, enums, unions, and other complex types
6. **Doctest Integration** - Inline documentation examples that serve as tests
7. **Float Comparison** - Proper techniques for testing floating-point values
8. **Comptime Testing** - Testing compile-time evaluation

## Project Structure

```
01_testing_fundamentals/
├── src/
│   ├── main.zig           # Main demo + comprehensive test suite
│   ├── math.zig           # Math functions with tests and doctests
│   └── string_utils.zig   # String utilities with tests
├── build.zig              # Build configuration
└── README.md              # This file
```

## Running the Example

### Run the Demo Application

```bash
zig build run
```

This demonstrates the math and string functions in action.

### Run All Tests

```bash
zig build test
```

This runs all test blocks across all files. You'll see output like:

```
All 3 tests passed.
```

### Run Tests for a Specific File

```bash
# Test only math functions
zig test src/math.zig

# Test only string utilities
zig test src/string_utils.zig

# Test main file (includes integration tests)
zig test src/main.zig
```

### Filter Tests by Name

```bash
# Run only tests with "memory" in the name
zig test src/main.zig --test-filter memory

# Run tests matching a pattern
zig test src/math.zig --test-filter factorial
```

## Key Concepts Demonstrated

### 1. Test Block Syntax

Test blocks are defined with the `test` keyword:

```zig
test "description of what is being tested" {
    // Test code here
    try testing.expect(true);
}
```

**Important Notes:**
- Tests are only compiled when running `zig test`
- Test names must be unique within a file
- Tests run in undefined order - they must be independent
- Tests can call `try` to propagate errors

### 2. Common Assertion Functions

#### `expect` - Boolean Condition
```zig
try testing.expect(true);
try testing.expect(2 + 2 == 4);
```

#### `expectEqual` - Exact Value Comparison
```zig
try testing.expectEqual(@as(i32, 42), actual_value);
```

**Note**: You must specify the expected type explicitly to avoid ambiguous types.

#### `expectError` - Error Testing
```zig
try testing.expectError(error.DivisionByZero, divide(10, 0));
```

#### `expectEqualSlices` - Slice Comparison
```zig
try testing.expectEqualSlices(u8, &[_]u8{1, 2, 3}, actual_slice);
```

#### `expectEqualStrings` - String Comparison
```zig
try testing.expectEqualStrings("expected", actual_string);
```

#### `expectApproxEqAbs` - Floating Point (Absolute Tolerance)
```zig
try testing.expectApproxEqAbs(0.3, 0.1 + 0.2, 0.0001);
```

#### `expectApproxEqRel` - Floating Point (Relative Tolerance)
```zig
try testing.expectApproxEqRel(1000.0, 1000.1, 0.001);
```

### 3. Memory Leak Detection

`std.testing.allocator` is a special allocator that tracks allocations and detects leaks:

```zig
test "memory management" {
    const allocator = testing.allocator;

    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    // If you forget 'defer', the test will fail with a leak detection message
}
```

**What Gets Detected:**
- Missing `free()` calls
- Double-free errors (attempting to free the same memory twice)
- Use-after-free (caught by debug builds)

**Why It's Important:**
- Ensures your code properly manages memory
- Catches resource leaks early in development
- Provides clear error messages showing what wasn't freed

### 4. Testing Error Cases

Zig's error handling integrates seamlessly with testing:

```zig
pub fn divide(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    return @divTrunc(a, b);
}

test "error cases" {
    // Test successful case
    try testing.expectEqual(@as(i32, 5), try divide(10, 2));

    // Test error case
    try testing.expectError(error.DivisionByZero, divide(10, 0));
}
```

### 5. Doctests

Doctests are code examples in documentation comments that can be tested:

```zig
/// Add two integers together.
///
/// Example usage:
/// ```zig
/// const result = add(2, 3);
/// try testing.expectEqual(@as(i32, 5), result);
/// ```
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

While Zig's doctest support is evolving, documenting your functions with example usage is good practice and helps ensure your documentation stays accurate.

### 6. Floating Point Comparison

Never use `expectEqual` for floating point values due to rounding errors:

```zig
test "float comparison - WRONG" {
    const a = 0.1 + 0.2;
    const b = 0.3;
    // This may fail due to floating point imprecision!
    // try testing.expectEqual(b, a);
}

test "float comparison - CORRECT" {
    const a = 0.1 + 0.2;
    const b = 0.3;
    try testing.expectApproxEqAbs(b, a, 0.0001);
}
```

**Guidelines:**
- Use `expectApproxEqAbs` for absolute tolerance (good for small numbers)
- Use `expectApproxEqRel` for relative tolerance (good for large numbers)
- Choose tolerance based on your precision requirements

### 7. Comptime Testing

You can test compile-time behavior:

```zig
test "comptime evaluation" {
    comptime {
        const result = add(2, 3);
        if (result != 5) {
            @compileError("Math is broken!");
        }
    }
}
```

This ensures your comptime functions work correctly at compile time.

### 8. Testing Different Types

The example includes tests for:
- **Primitives**: integers, floats, booleans
- **Structs**: value equality
- **Enums**: variant equality
- **Unions**: tagged unions with payloads
- **Optionals**: null and value cases
- **Error Unions**: success and error paths
- **Arrays and Slices**: element-wise comparison

## Common Pitfalls

### ❌ Wrong: Forgetting Type Annotation
```zig
try testing.expectEqual(42, value); // Ambiguous type!
```

### ✅ Correct: Explicit Type
```zig
try testing.expectEqual(@as(i32, 42), value);
```

---

### ❌ Wrong: Missing Memory Cleanup
```zig
test "leak" {
    const buffer = try testing.allocator.alloc(u8, 100);
    // Forgot defer! Test will fail.
}
```

### ✅ Correct: Always Use Defer
```zig
test "no leak" {
    const buffer = try testing.allocator.alloc(u8, 100);
    defer testing.allocator.free(buffer);
}
```

---

### ❌ Wrong: Exact Float Comparison
```zig
try testing.expectEqual(0.3, 0.1 + 0.2); // May fail!
```

### ✅ Correct: Approximate Comparison
```zig
try testing.expectApproxEqAbs(0.3, 0.1 + 0.2, 0.0001);
```

---

### ❌ Wrong: Tests With Side Effects
```zig
var global_counter: i32 = 0;

test "first" {
    global_counter += 1;
}

test "second" {
    // This assumes "first" ran! Tests run in undefined order.
    try testing.expectEqual(1, global_counter);
}
```

### ✅ Correct: Independent Tests
```zig
test "independent" {
    var local_counter: i32 = 0;
    local_counter += 1;
    try testing.expectEqual(1, local_counter);
}
```

## Exploring Further

### Experiment 1: Trigger a Memory Leak

In `src/main.zig`, find the test `"memory leak detection demonstration"` and uncomment the lines that allocate without freeing:

```zig
const leaked = try allocator.alloc(u8, 100);
// Forgot to free!
```

Run the test and observe the detailed leak detection message.

### Experiment 2: Test Failure Messages

Modify a test to fail and observe the output:

```zig
test "deliberately fail" {
    try testing.expectEqual(@as(i32, 100), 42);
}
```

You'll see clear diagnostics showing expected vs actual values.

### Experiment 3: Add Your Own Tests

Try adding tests for edge cases:
- What happens with very large numbers in factorial?
- How does string reversal handle Unicode?
- What if you call `isPrime` with 0?

## Version Compatibility

✅ **Zig 0.14.1** - Fully compatible
✅ **Zig 0.15.1** - Fully compatible
✅ **Zig 0.15.2** - Fully compatible

The testing API is stable across these versions. The only difference is in `build.zig` syntax:

- **0.14.x**: Uses `.{ .path = "src/main.zig" }`
- **0.15+**: Uses `b.path("src/main.zig")` and `root_module` field

## Summary

This example covers the essential testing patterns you'll use in every Zig project:

1. **Test blocks** define independent test cases
2. **std.testing.allocator** catches memory leaks automatically
3. **Multiple assertion functions** handle different comparison needs
4. **Error testing** validates failure paths
5. **Floating point comparisons** require approximate equality
6. **Tests must be independent** - no shared state or execution order dependencies

Master these fundamentals, and you'll be well-equipped to write comprehensive test suites for your Zig applications.

## Next Steps

- **Example 2**: Learn how to organize tests across multiple files with shared utilities
- **Example 3**: Explore parameterized and table-driven test patterns
- **Example 4**: Deep dive into allocator testing and failure injection
- **Example 5**: Learn micro-benchmarking techniques
- **Example 6**: Integrate profiling tools for performance analysis

## References

- [Zig Language Reference - Testing](https://ziglang.org/documentation/master/#Testing)
- [std.testing Documentation](https://ziglang.org/documentation/master/std/#std.testing)
- [Zig Test Documentation](https://ziglearn.org/chapter-1/#tests)
