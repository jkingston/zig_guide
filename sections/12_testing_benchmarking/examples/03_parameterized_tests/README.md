# Example 3: Parameterized Tests

This example demonstrates **parameterized testing** patterns in Zig, showing how to write data-driven tests that validate functions with multiple inputs efficiently. Learn how to use table-driven tests, runtime parameterization, and comptime test generation to reduce boilerplate and increase test coverage.

## Learning Objectives

By studying this example, you will learn:

1. **What parameterized tests are** and why they're valuable
2. **Three approaches to parameterization** in Zig:
   - Runtime table-driven tests (most common)
   - Loop-based parameterized tests
   - Comptime test generation
3. **How to structure test data** for readability and maintainability
4. **How to add failure context** so you know which test case failed
5. **When to use each approach** based on your testing needs
6. **Best practices** for organizing and documenting test cases
7. **How to test different return types**: bool, enum, error unions
8. **Edge case and boundary testing** patterns

## What Are Parameterized Tests?

**Parameterized tests** are tests that run the same test logic with multiple different inputs. Instead of writing separate test functions for each input, you define the test logic once and provide a table of test cases.

### Without Parameterization (Repetitive)

```zig
test "parseInt: zero" {
    const result = try parseInt("0");
    try testing.expectEqual(@as(i32, 0), result);
}

test "parseInt: positive" {
    const result = try parseInt("42");
    try testing.expectEqual(@as(i32, 42), result);
}

test "parseInt: negative" {
    const result = try parseInt("-123");
    try testing.expectEqual(@as(i32, -123), result);
}

// ... 20 more similar tests
```

### With Parameterization (Concise)

```zig
test "parseInt: valid integers" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .input = "0", .expected = 0 },
        .{ .input = "42", .expected = 42 },
        .{ .input = "-123", .expected = -123 },
        // ... 20 more cases
    };

    for (cases) |case| {
        const result = try parseInt(case.input);
        try testing.expectEqual(case.expected, result);
    }
}
```

### Benefits

- **Less boilerplate**: Write test logic once, apply to many inputs
- **Better coverage**: Easy to add more test cases
- **Easier maintenance**: Change test logic in one place
- **Better organization**: Group related test cases together
- **Clear test data**: Test cases are data, separate from logic

## Project Structure

```
03_parameterized_tests/
├── src/
│   ├── main.zig           # Demo app + basic parameterized test examples
│   ├── calculator.zig     # Calculator with comptime test generation (35+ tests)
│   ├── parser.zig         # Parser with table-driven tests (15 test blocks, 80+ cases)
│   ├── validator.zig      # Validator with parameterized tests (12+ test blocks)
├── build.zig              # Build configuration
└── README.md              # This file
```

## Three Approaches to Parameterized Tests

### Approach 1: Runtime Table-Driven Tests (Most Common)

**Best for**: Most testing scenarios, especially when you have many test cases.

**Pattern**:
```zig
test "function: category of tests" {
    const TestCase = struct {
        input: InputType,
        expected: OutputType,
        description: []const u8,  // Optional but helpful
    };

    const cases = [_]TestCase{
        .{ .input = ..., .expected = ..., .description = "..." },
        .{ .input = ..., .expected = ..., .description = "..." },
        // More cases...
    };

    for (cases) |case| {
        const result = functionUnderTest(case.input);
        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Failed for {s}: input={}, expected={}\n", .{
                case.description, case.input, case.expected
            });
            return err;
        };
    }
}
```

**Example from parser.zig**:
```zig
test "parseInt: valid integers" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{ .input = "0", .expected = 0, .description = "zero" },
        .{ .input = "42", .expected = 42, .description = "two digits" },
        .{ .input = "-123", .expected = -123, .description = "negative three digits" },
        .{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
        .{ .input = "-2147483648", .expected = -2147483648, .description = "min i32" },
    };

    for (cases) |case| {
        const result = parseInt(case.input) catch |err| {
            std.debug.print("Failed to parse '{s}' ({s}): {}\n", .{
                case.input, case.description, err
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for '{s}' ({s}): got {}, expected {}\n", .{
                case.input, case.description, result, case.expected
            });
            return err;
        };
    }
}
```

**When to use**:
- Testing with many different inputs
- Need to categorize test cases (valid, invalid, edge cases)
- Want clear failure messages showing which case failed
- Testing complex scenarios requiring multiple fields

**Pros**:
- Very readable test data
- Easy to add new cases
- Can include description field for context
- Flexible - can test any function signature

**Cons**:
- Slight runtime overhead (minimal)
- All cases in one test (if one fails, test stops)

### Approach 2: Loop-Based Parameterized Tests

**Best for**: Simple scenarios where you only need to iterate over inputs.

**Pattern**:
```zig
test "function: simple loop" {
    const inputs = [_]InputType{ value1, value2, value3 };

    for (inputs) |input| {
        const result = functionUnderTest(input);
        try testing.expectEqual(expectedValue(input), result);
    }
}
```

**Example from main.zig**:
```zig
test "loop-based parameterized test" {
    const inputs = [_]i32{ 0, 1, 2, 3, 4, 5 };

    for (inputs) |input| {
        const result = input * 2;
        try testing.expectEqual(input + input, result);
    }
}
```

**When to use**:
- Simple tests with minimal test case structure
- Quick validation of a list of values
- Testing error conditions with similar inputs

**Pros**:
- Simplest syntax
- Minimal boilerplate
- Quick to write

**Cons**:
- Less context in failures
- Limited structure (just the input values)
- Harder to document what each case tests

### Approach 3: Comptime Test Generation

**Best for**: Reducing boilerplate when you have many similar tests that should be separate test cases.

**Pattern**:
```zig
// Helper function to generate tests at comptime
fn testOperation(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = operation(a, b);
    try testing.expectEqual(expected, result);
}

// Generate individual test cases
test "add: 2 + 3 = 5" { try testOperation(2, 3, 5); }
test "add: 0 + 0 = 0" { try testOperation(0, 0, 0); }
test "add: -1 + 1 = 0" { try testOperation(-1, 1, 0); }
```

**Example from calculator.zig**:
```zig
/// Helper function to generate addition tests at comptime
fn testAddition(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = add(a, b);
    try testing.expectEqual(expected, result);
}

test "add: 0 + 0 = 0" {
    try testAddition(0, 0, 0);
}

test "add: 2 + 3 = 5" {
    try testAddition(2, 3, 5);
}

test "add: -5 + 5 = 0" {
    try testAddition(-5, 5, 0);
}

test "add: 100 + (-50) = 50" {
    try testAddition(100, -50, 50);
}
```

**When to use**:
- Want separate test cases (appears as individual tests in output)
- Testing simple operations with different values
- Need to ensure consistent test structure
- Value test isolation (one failure doesn't stop others)

**Pros**:
- Each test case is a separate test
- Shows in test output individually
- Failures are isolated
- Consistent test structure enforced by helper

**Cons**:
- More verbose (one test block per case)
- Only works with comptime-known values
- Requires helper function

## Adding Failure Context

One of the most important aspects of parameterized tests is **providing context when tests fail**. Without context, you won't know which test case caused the failure.

### Without Context (Bad)

```zig
test "parseInt: multiple cases" {
    const cases = [_]TestCase{ /* ... */ };

    for (cases) |case| {
        const result = try parseInt(case.input);
        try testing.expectEqual(case.expected, result);
        // If this fails, you don't know which case failed!
    }
}
```

### With Context (Good)

```zig
test "parseInt: multiple cases" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{ /* ... */ };

    for (cases) |case| {
        const result = parseInt(case.input) catch |err| {
            std.debug.print("Failed to parse '{s}' ({s}): {}\n", .{
                case.input, case.description, err
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for '{s}' ({s}): got {}, expected {}\n", .{
                case.input, case.description, result, case.expected
            });
            return err;
        };
    }
}
```

**Techniques for adding context**:

1. **Description field**: Add a description to your TestCase struct
2. **Print input values**: Show what input caused the failure
3. **Print expected vs actual**: Show what you expected and what you got
4. **Use catch blocks**: Catch errors and print context before returning

## Testing Different Return Types

### Testing Functions Returning Bool

```zig
test "validateEmail: valid emails" {
    const valid_emails = [_][]const u8{
        "user@example.com",
        "test@test.co.uk",
        // ...
    };

    for (valid_emails) |email| {
        const result = validateEmail(email);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid email: '{s}'\n", .{email});
            return err;
        };
    }
}

test "validateEmail: invalid emails" {
    const invalid_emails = [_][]const u8{
        "not-an-email",
        "@example.com",
        // ...
    };

    for (invalid_emails) |email| {
        const result = validateEmail(email);
        testing.expect(!result) catch |err| {
            std.debug.print("Expected invalid email: '{s}'\n", .{email});
            return err;
        };
    }
}
```

### Testing Functions Returning Enum

```zig
test "validatePassword: strong passwords" {
    const TestCase = struct {
        password: []const u8,
        reason: []const u8,
    };

    const strong_passwords = [_]TestCase{
        .{ .password = "Pass1234!@#$", .reason = "12+ chars with all types" },
        .{ .password = "MyP@ssw0rd!!", .reason = "12+ chars, mixed case, special" },
        // ...
    };

    for (strong_passwords) |case| {
        const result = validatePassword(case.password);
        testing.expectEqual(PasswordStrength.Strong, result) catch |err| {
            std.debug.print("Expected strong password for '{s}' ({s}), got {}\n", .{
                case.password, case.reason, result
            });
            return err;
        };
    }
}
```

### Testing Functions Returning Errors

```zig
test "parseInt: invalid input" {
    const ErrorCase = struct {
        input: []const u8,
        expected_error: ParseError,
        description: []const u8,
    };

    const cases = [_]ErrorCase{
        .{ .input = "", .expected_error = error.EmptyInput, .description = "empty string" },
        .{ .input = "abc", .expected_error = error.InvalidInput, .description = "letters only" },
        .{ .input = "99999999999", .expected_error = error.Overflow, .description = "too large" },
    };

    for (cases) |case| {
        const result = parseInt(case.input);
        testing.expectError(case.expected_error, result) catch |err| {
            std.debug.print("Expected error {} for '{s}' ({s})\n", .{
                case.expected_error, case.input, case.description
            });
            return err;
        };
    }
}
```

### Testing Functions with Complex Output

```zig
test "parseList: valid lists" {
    const TestCase = struct {
        input: []const u8,
        expected: []const []const u8,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{
            .input = "apple,banana,cherry",
            .expected = &[_][]const u8{ "apple", "banana", "cherry" },
            .description = "simple list",
        },
        // ...
    };

    for (cases) |case| {
        const result = try parseList(case.input, testing.allocator);
        defer freeList(result, testing.allocator);

        try testing.expectEqual(case.expected.len, result.len);

        for (case.expected, result, 0..) |expected_item, result_item, i| {
            testing.expectEqualStrings(expected_item, result_item) catch |err| {
                std.debug.print("Wrong item at index {} for '{s}': got '{s}', expected '{s}'\n", .{
                    i, case.input, result_item, expected_item
                });
                return err;
            };
        }
    }
}
```

## Organizing Test Data

### Category-Based Organization

Group test cases by category: valid, invalid, edge cases.

```zig
test "parseInt: valid integers" {
    const cases = [_]TestCase{
        // Basic positive numbers
        .{ .input = "0", .expected = 0, .description = "zero" },
        .{ .input = "42", .expected = 42, .description = "two digits" },

        // Negative numbers
        .{ .input = "-1", .expected = -1, .description = "negative one" },
        .{ .input = "-123", .expected = -123, .description = "negative three digits" },

        // Edge cases
        .{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
        .{ .input = "-2147483648", .expected = -2147483648, .description = "min i32" },
    };

    // Test logic...
}

test "parseInt: invalid input" {
    const cases = [_]ErrorCase{
        // Empty input
        .{ .input = "", .expected_error = error.EmptyInput, .description = "empty string" },

        // Invalid characters
        .{ .input = "abc", .expected_error = error.InvalidInput, .description = "letters only" },
        .{ .input = "12.34", .expected_error = error.InvalidInput, .description = "decimal point" },

        // Overflow
        .{ .input = "99999999999", .expected_error = error.Overflow, .description = "too large" },
    };

    // Test logic...
}
```

### Using Comments for Structure

```zig
const cases = [_]TestCase{
    // ========================================
    // Valid URLs with different protocols
    // ========================================
    .{ .input = "http://example.com", .expected = true },
    .{ .input = "https://example.com", .expected = true },

    // ========================================
    // URLs with paths and query parameters
    // ========================================
    .{ .input = "http://example.com/path", .expected = true },
    .{ .input = "https://example.com?key=value", .expected = true },

    // ========================================
    // Invalid URLs
    // ========================================
    .{ .input = "ftp://example.com", .expected = false },
    .{ .input = "not-a-url", .expected = false },
};
```

### Descriptive Field Names

Use clear, descriptive field names in your TestCase struct:

```zig
// Good
const TestCase = struct {
    input: []const u8,
    expected: i32,
    description: []const u8,
};

// Also good - very specific
const DivisionTestCase = struct {
    dividend: i32,
    divisor: i32,
    expected_quotient: i32,
    description: []const u8,
};

// Less clear
const TestCase = struct {
    a: []const u8,  // What is 'a'?
    b: i32,         // What is 'b'?
    c: []const u8,  // What is 'c'?
};
```

## Code Examples by Module

### calculator.zig - Comptime Test Generation

**Demonstrates**: Using comptime helper functions to generate individual test cases.

```zig
/// Helper function to generate addition tests at comptime
fn testAddition(comptime a: i32, comptime b: i32, comptime expected: i32) !void {
    const result = add(a, b);
    try testing.expectEqual(expected, result);
}

// Each of these is a separate test
test "add: 2 + 3 = 5" { try testAddition(2, 3, 5); }
test "add: 0 + 0 = 0" { try testAddition(0, 0, 0); }
test "add: -1 + 1 = 0" { try testAddition(-1, 1, 0); }

// Table-driven test for division
test "divide: valid operations" {
    const TestCase = struct {
        a: i32,
        b: i32,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        .{ .a = 10, .b = 2, .expected = 5, .description = "simple division" },
        .{ .a = 7, .b = 2, .expected = 3, .description = "truncated division" },
        .{ .a = -10, .b = 2, .expected = -5, .description = "negative dividend" },
    };

    for (cases) |case| {
        const result = try divide(case.a, case.b);
        try testing.expectEqual(case.expected, result);
    }
}
```

**Key features**:
- 35+ tests using comptime generation
- Separate tests for each operation (add, subtract, multiply, power)
- Table-driven tests for division (error handling)
- Tests for modulo operation

### parser.zig - Table-Driven Tests

**Demonstrates**: Comprehensive table-driven testing with extensive test data.

```zig
test "parseInt: valid integers" {
    const TestCase = struct {
        input: []const u8,
        expected: i32,
        description: []const u8,
    };

    const cases = [_]TestCase{
        // Basic positive numbers
        .{ .input = "0", .expected = 0, .description = "zero" },
        .{ .input = "42", .expected = 42, .description = "two digits" },

        // Negative numbers
        .{ .input = "-1", .expected = -1, .description = "negative one" },

        // Edge cases
        .{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
        .{ .input = "-2147483648", .expected = -2147483648, .description = "min i32" },
    };

    for (cases) |case| {
        const result = parseInt(case.input) catch |err| {
            std.debug.print("Failed to parse '{s}' ({s}): {}\n", .{
                case.input, case.description, err
            });
            return err;
        };

        testing.expectEqual(case.expected, result) catch |err| {
            std.debug.print("Wrong result for '{s}' ({s}): got {}, expected {}\n", .{
                case.input, case.description, result, case.expected
            });
            return err;
        };
    }
}
```

**Key features**:
- 15+ test blocks with 80+ test cases total
- Tests for parseInt, parseFloat, parseBool, parseList, parseHex
- Separate tests for valid inputs, invalid inputs, edge cases
- Clear failure context with descriptions
- Tests for functions with different return types

### validator.zig - Parameterized Validation Tests

**Demonstrates**: Testing validators with bool, enum, and complex return types.

```zig
test "validateEmail: valid emails" {
    const valid_emails = [_][]const u8{
        "user@example.com",
        "test@test.co.uk",
        "name.surname@domain.org",
        // ... more cases
    };

    for (valid_emails) |email| {
        const result = validateEmail(email);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid email: '{s}'\n", .{email});
            return err;
        };
    }
}

test "validatePassword: strong passwords" {
    const TestCase = struct {
        password: []const u8,
        reason: []const u8,
    };

    const strong_passwords = [_]TestCase{
        .{ .password = "Pass1234!@#$", .reason = "12+ chars with all types" },
        .{ .password = "MyP@ssw0rd!!", .reason = "12+ chars, mixed case, special" },
    };

    for (strong_passwords) |case| {
        const result = validatePassword(case.password);
        testing.expectEqual(PasswordStrength.Strong, result) catch |err| {
            std.debug.print("Expected strong for '{s}' ({s}), got {}\n", .{
                case.password, case.reason, result
            });
            return err;
        };
    }
}
```

**Key features**:
- 12+ test blocks with extensive test data
- Tests for email, URL, phone, password, username validation
- Testing bool return values (valid/invalid)
- Testing enum return values (password strength)
- Boundary testing (minimum/maximum lengths)
- Integration test combining multiple validators

### main.zig - Basic Examples

**Demonstrates**: Simple examples of each parameterization pattern.

```zig
test "basic table-driven test" {
    const TestCase = struct {
        input: i32,
        expected: i32,
    };

    const cases = [_]TestCase{
        .{ .input = 0, .expected = 0 },
        .{ .input = 1, .expected = 1 },
        .{ .input = 5, .expected = 5 },
    };

    for (cases) |case| {
        try testing.expectEqual(case.expected, case.input);
    }
}

test "loop-based parameterized test" {
    const inputs = [_]i32{ 0, 1, 2, 3, 4, 5 };

    for (inputs) |input| {
        const result = input * 2;
        try testing.expectEqual(input + input, result);
    }
}
```

**Key features**:
- Demo application showing all modules
- Basic examples of each pattern
- String operation tests
- Math operation tests
- Integration tests combining multiple modules

## Common Pitfalls

### 1. Forgetting to Add Failure Context

**Problem**: Test fails but you don't know which case failed.

```zig
// Bad - no context
for (cases) |case| {
    const result = try parseInt(case.input);
    try testing.expectEqual(case.expected, result);
}
```

**Solution**: Add catch blocks with debug prints.

```zig
// Good - shows which case failed
for (cases) |case| {
    const result = parseInt(case.input) catch |err| {
        std.debug.print("Failed for input: '{s}'\n", .{case.input});
        return err;
    };

    testing.expectEqual(case.expected, result) catch |err| {
        std.debug.print("Wrong result for '{s}': got {}, expected {}\n", .{
            case.input, result, case.expected
        });
        return err;
    };
}
```

### 2. Too Many Test Cases in One Test

**Problem**: Hundreds of test cases in a single test block makes it slow and hard to debug.

**Solution**: Split into multiple test blocks by category.

```zig
// Instead of one giant test with 200 cases:
test "parseInt: all cases" {
    // 200 test cases...
}

// Split into logical groups:
test "parseInt: valid integers" {
    // 50 valid cases
}

test "parseInt: invalid input" {
    // 50 invalid cases
}

test "parseInt: overflow cases" {
    // 20 overflow cases
}

test "parseInt: edge cases" {
    // 10 edge cases
}
```

### 3. Not Categorizing Test Data

**Problem**: Test cases are randomly ordered, hard to understand coverage.

**Solution**: Use comments and organization to group related cases.

```zig
const cases = [_]TestCase{
    // Basic cases
    .{ .input = "simple", ... },

    // Edge cases
    .{ .input = "edge_case", ... },

    // Error cases
    .{ .input = "error_case", ... },
};
```

### 4. Unclear TestCase Field Names

**Problem**: Field names like `a`, `b`, `c` don't convey meaning.

**Solution**: Use descriptive field names.

```zig
// Bad
const TestCase = struct { a: i32, b: i32, c: i32 };

// Good
const TestCase = struct {
    dividend: i32,
    divisor: i32,
    expected_quotient: i32,
};
```

### 5. Testing Error Cases Without Expected Error

**Problem**: Just checking that an error occurred, not which error.

```zig
// Bad - any error passes
const result = parseInt(input);
try testing.expect(std.meta.isError(result));
```

**Solution**: Check for the specific expected error.

```zig
// Good - checks for specific error
const result = parseInt(input);
try testing.expectError(error.InvalidInput, result);
```

## Best Practices

### 1. Organize Test Data Clearly

Use comments, blank lines, and consistent formatting:

```zig
const cases = [_]TestCase{
    // ========================================
    // Basic positive numbers
    // ========================================
    .{ .input = "0", .expected = 0, .description = "zero" },
    .{ .input = "1", .expected = 1, .description = "one" },

    // ========================================
    // Negative numbers
    // ========================================
    .{ .input = "-1", .expected = -1, .description = "negative one" },

    // ========================================
    // Boundary values
    // ========================================
    .{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
};
```

### 2. Use Descriptive TestCase Field Names

Make it obvious what each field represents:

```zig
const TestCase = struct {
    input: []const u8,              // What we're parsing
    expected: i32,                   // What we expect to get
    description: []const u8,         // Why this case matters
};
```

### 3. Add Comments for Edge Cases

Explain why edge cases are important:

```zig
.{ .input = "", .expected_error = error.EmptyInput, .description = "empty string" },
// ^ Important: empty input should be rejected, not crash

.{ .input = "2147483647", .expected = 2147483647, .description = "max i32" },
// ^ Boundary: largest valid i32, should not overflow

.{ .input = "2147483648", .expected_error = error.Overflow, .description = "max + 1" },
// ^ Boundary: one over max i32, should overflow
```

### 4. Keep Test Data Readable

Format test cases consistently, align fields:

```zig
const cases = [_]TestCase{
    .{ .input = "0",     .expected = 0,     .description = "zero"         },
    .{ .input = "42",    .expected = 42,    .description = "two digits"   },
    .{ .input = "-123",  .expected = -123,  .description = "negative"     },
};
```

### 5. Provide Helpful Failure Messages

Include all relevant information in failure messages:

```zig
testing.expectEqual(case.expected, result) catch |err| {
    std.debug.print("Test case failed:\n", .{});
    std.debug.print("  Description: {s}\n", .{case.description});
    std.debug.print("  Input: {s}\n", .{case.input});
    std.debug.print("  Expected: {}\n", .{case.expected});
    std.debug.print("  Got: {}\n", .{result});
    return err;
};
```

### 6. Group Related Tests

Put related test cases in the same test block:

```zig
test "parseInt: valid integers" { /* all valid cases */ }
test "parseInt: invalid input" { /* all invalid cases */ }
test "parseInt: overflow" { /* all overflow cases */ }
```

### 7. Test Both Success and Failure Paths

Don't just test the happy path:

```zig
test "divide: valid operations" {
    // Test successful division
}

test "divide: division by zero errors" {
    // Test error handling
}
```

## Comparison: Parameterized vs Individual Tests

| Aspect | Parameterized Tests | Individual Tests |
|--------|-------------------|------------------|
| **Boilerplate** | Low - write logic once | High - repeat logic per test |
| **Coverage** | Easy to add more cases | Requires new test function |
| **Isolation** | Cases in one test | Each test is isolated |
| **Failure Context** | Need to add manually | Test name provides context |
| **Test Output** | One test, multiple cases | Multiple tests in output |
| **Debugging** | May need to find which case | Easy to identify failed test |
| **Best For** | Many similar test cases | Few distinct test scenarios |

**Recommendation**: Use parameterized tests when you have many similar test cases. Use individual tests when each case is significantly different or you want maximum isolation.

## Running the Example

### Build and Run Demo

```bash
# Build the demo application
zig build

# Run the demo
zig build run
```

Output shows all modules working:
```
=== Parameterized Tests Demo ===

Calculator Operations:
  2 + 3 = 5
  10 - 4 = 6
  5 * 6 = 30
  ...

Parser Operations:
  parseInt('42') = 42
  parseFloat('3.14') = 3.14
  ...

Validator Operations:
  validateEmail('user@example.com') = true
  ...
```

### Run Tests

```bash
# Run all tests
zig build test

# Run tests with verbose output
zig build test --summary all

# Run tests for specific module
zig test src/parser.zig
zig test src/calculator.zig
zig test src/validator.zig
```

### Test Statistics

This example includes:
- **70+ total test blocks**
- **150+ individual test cases** in tables
- **4 modules** with different testing patterns
- **3 parameterization approaches** demonstrated

### Expected Test Output

```
Test [1/70] basic table-driven test... OK
Test [2/70] loop-based parameterized test... OK
Test [3/70] parseInt: valid integers... OK
Test [4/70] parseInt: invalid input... OK
...
All 70 tests passed.
```

## Compatibility

- **Zig Version**: 0.15.1 or later
- **Platform**: All platforms (Linux, macOS, Windows)
- **Standard Library**: Uses only std.testing, std.fmt, std.mem

## Key Takeaways

1. **Parameterized tests reduce boilerplate** by separating test logic from test data
2. **Three approaches**: table-driven (most common), loop-based (simple), comptime (isolated tests)
3. **Always add failure context** so you know which test case failed
4. **Organize test data clearly** with comments, categories, and descriptive names
5. **Test different return types** appropriately (bool, enum, errors, complex types)
6. **Split tests by category** for better organization and debugging
7. **Use descriptive field names** in TestCase structs for clarity

## Further Reading

- **Zig Testing Documentation**: https://ziglang.org/documentation/master/#toc-Testing
- **Example 1**: Basic Testing - Foundation concepts
- **Example 2**: Test Organization - Structuring tests
- **Example 4**: Mocking & Fakes (next) - Testing with dependencies
- **Example 5**: Benchmarking - Performance testing

## Summary

Parameterized tests are a powerful pattern for writing comprehensive, maintainable tests with minimal boilerplate. By using table-driven tests, loop-based tests, or comptime test generation, you can achieve excellent test coverage while keeping your test code DRY (Don't Repeat Yourself). Always remember to provide clear failure context, organize your test data logically, and choose the right approach for your specific testing needs.
