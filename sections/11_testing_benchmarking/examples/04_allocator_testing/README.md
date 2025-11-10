# Example 4: Allocator Testing

This example demonstrates comprehensive patterns for testing code that uses allocators in Zig. It covers memory leak detection, allocation failure testing, proper resource cleanup verification, and various allocator testing strategies.

## Learning Objectives

By studying this example, you will learn:

- **Using `std.testing.allocator`** for automatic memory leak detection in tests
- **Testing allocation failure paths** with `FailingAllocator` to ensure robustness
- **Verifying proper cleanup** with defer patterns and explicit resource management
- **Testing with different allocator types** (GeneralPurposeAllocator, ArenaAllocator, etc.)
- **Understanding allocator test patterns** and best practices in Zig
- **Detecting and preventing memory leaks** during development
- **Ensuring error paths clean up properly** to avoid resource leaks

## Key Concepts

### 1. std.testing.allocator

`std.testing.allocator` is a special allocator designed specifically for unit tests. It's a `GeneralPurposeAllocator` configured to detect memory leaks automatically.

**Key features:**
- Tracks all allocations and deallocations
- Fails the test if any memory is leaked
- Provides detailed error messages showing where leaks occurred
- Catches use-after-free and double-free errors

**Example:**
```zig
test "basic allocation test" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit(); // If forgotten, test fails!

    // Use the buffer...
}
```

### 2. FailingAllocator

`FailingAllocator` simulates allocation failures, allowing you to test error handling paths. This is crucial for writing robust code that handles out-of-memory conditions gracefully.

**Configuration:**
```zig
test "allocation failure handling" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0, // Fail on first allocation
    });
    const allocator = failing.allocator();

    const result = Buffer.init(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

The `fail_index` parameter specifies which allocation should fail:
- `0` = first allocation fails
- `1` = second allocation fails
- `n` = (n+1)th allocation fails

### 3. ArenaAllocator

`ArenaAllocator` allocates memory that is all freed at once when the arena is destroyed. Useful for testing bulk allocation patterns.

**Pattern:**
```zig
test "using arena allocator" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit(); // Frees everything at once

    const allocator = arena.allocator();

    // Multiple allocations, no individual cleanup needed
    var buffer1 = try Buffer.init(allocator, 10);
    var buffer2 = try Buffer.init(allocator, 20);

    // arena.deinit() cleans up both buffers
}
```

### 4. Memory Leak Detection

Zig's testing allocator automatically detects memory leaks. When a test completes, if any allocated memory hasn't been freed, the test fails with detailed information.

**What gets detected:**
- Allocated memory not freed
- Memory allocated in error paths
- Forgotten cleanup in defer statements
- Leaked resources from early returns

**Example output when a leak occurs:**
```
[gpa] (err): memory address 0x7f1234567890 leaked:
/path/to/file.zig:123:45: 0x12345678 in functionName (test)
    const data = try allocator.alloc(u8, 100);
```

### 5. Defer Patterns for Cleanup

The `defer` keyword ensures cleanup happens even when errors occur. Always use `defer` immediately after allocating resources.

**Best practice:**
```zig
test "proper defer pattern" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit(); // Cleanup happens no matter what

    // Even if this fails, deinit is called
    try buffer.append('x');
}
```

**Common mistake:**
```zig
test "WRONG - delayed defer" {
    var buffer = try Buffer.init(testing.allocator, 100);

    try buffer.append('x'); // If this fails, we leak!

    defer buffer.deinit(); // TOO LATE - won't be called if append fails
}
```

### 6. Testing Resource Ownership

Understanding who owns what memory is crucial. Resources can be:
- **Borrowed** - caller retains ownership
- **Owned** - callee takes ownership
- **Transferred** - ownership changes hands

**Example with ownership transfer:**
```zig
test "ownership transfer" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("test");

    // toString creates a new owned copy
    const str = try builder.toString();
    defer testing.allocator.free(str); // WE own this and must free it

    // builder still owns its internal buffer
}
```

### 7. Testing Error Path Cleanup

Ensure that cleanup happens even when operations fail:

```zig
test "cleanup on error" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 2,
    });
    const allocator = failing.allocator();

    var builder = try StringBuilder.init(allocator);
    defer builder.deinit(); // Called even if append fails

    const result = builder.append("test");
    if (result) |_| {
        // Success path
    } else |err| {
        // Error path - deinit still called via defer
        try testing.expectEqual(error.OutOfMemory, err);
    }
}
```

## Code Examples

### Basic Test with Leak Detection

```zig
test "Buffer basic allocation" {
    // Create a buffer with testing.allocator
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit(); // CRITICAL: Must free memory

    try testing.expectEqual(@as(usize, 100), buffer.capacity);

    // If 'defer buffer.deinit()' is forgotten, this test will FAIL
    // with a memory leak error
}
```

**What happens without defer:**
```
Test [1/1] test.Buffer basic allocation...
[gpa] (err): memory address 0x... leaked:
FAIL (MemoryLeakDetected)
```

### Intentional Leak Example (What Happens)

```zig
// This test is COMMENTED OUT because it intentionally fails
// Uncomment to see leak detection in action
//
// test "LEAK DEMO - forgot deinit" {
//     var buffer = try Buffer.init(testing.allocator, 100);
//     // Missing: defer buffer.deinit();
//
//     try buffer.appendSlice("This will leak!");
//
//     // Output:
//     // [gpa] (err): memory address 0x... leaked:
//     // [gpa] (err):   /path/to/buffer.zig:15:45: ...
//     // Test [1/1] test.LEAK DEMO... FAIL (MemoryLeakDetected)
// }
```

### Testing Allocation Failures

```zig
test "Buffer handles allocation failure gracefully" {
    // Create a failing allocator that fails immediately
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });
    const allocator = failing.allocator();

    // This should fail with OutOfMemory
    const result = Buffer.init(allocator, 100);
    try testing.expectError(error.OutOfMemory, result);

    // No cleanup needed - init failed, so nothing was allocated
}
```

### Testing with Different Allocators

```zig
test "Buffer works with page_allocator" {
    const allocator = std.heap.page_allocator;

    var buffer = try Buffer.init(allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    // Works, but no leak detection (page_allocator doesn't track)
}

test "Buffer works with ArenaAllocator" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Create multiple buffers
    var buffer1 = try Buffer.init(allocator, 10);
    var buffer2 = try Buffer.init(allocator, 20);

    // No individual deinit needed - arena.deinit() frees everything
    try buffer1.appendSlice("test1");
    try buffer2.appendSlice("test2");
}

test "Buffer with testing.allocator (recommended)" {
    // This is the RECOMMENDED pattern for tests
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    // Leak detection is automatic!
}
```

### Complex Cleanup Scenarios

```zig
test "StringBuilder cleanup on toString" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit(); // Cleanup builder's internal buffer

    try builder.appendSlice("test");

    // toString creates a NEW allocation
    const str = try builder.toString();
    defer testing.allocator.free(str); // Must free this separately!

    try testing.expectEqualSlices(u8, "test", str);

    // Both cleanups happen:
    // 1. testing.allocator.free(str) - frees the duplicate
    // 2. builder.deinit() - frees the internal buffer
}
```

```zig
test "Cache with owned keys and values" {
    // Cache that owns both keys and values
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit(); // Frees ALL keys and values

    // These string literals are duplicated by the cache
    try cache.put("key1", "value1");
    try cache.put("key2", "value2");

    // cache.deinit() will:
    // 1. Free duplicated "key1" and "value1"
    // 2. Free duplicated "key2" and "value2"
    // 3. Free the HashMap itself
}
```

### Testing Cleanup in Error Paths

```zig
test "Buffer cleans up even when operations fail" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 2, // Fail on third allocation
    });
    const allocator = failing.allocator();

    var buffer = try Buffer.init(allocator); // 1st allocation succeeds
    defer buffer.deinit(); // ALWAYS cleanup

    try buffer.append('A'); // 2nd allocation succeeds

    const result = buffer.append('B'); // 3rd allocation FAILS

    if (result) |_| {
        // Success - not reached in this test
    } else |err| {
        try testing.expectEqual(error.OutOfMemory, err);
        // defer still calls deinit, cleaning up the first two allocations
    }
}
```

## Common Pitfalls and Solutions

### Pitfall 1: Forgetting defer for cleanup

❌ **Wrong:**
```zig
test "WRONG - forgot defer" {
    var buffer = try Buffer.init(testing.allocator, 100);
    try buffer.appendSlice("test");
    // buffer.deinit() is never called - LEAK!
}
```

✅ **Correct:**
```zig
test "CORRECT - immediate defer" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit(); // Cleanup guaranteed
    try buffer.appendSlice("test");
}
```

**Why:** `defer` ensures cleanup happens even if later operations fail.

### Pitfall 2: Not testing allocation failure paths

❌ **Wrong:**
```zig
test "INCOMPLETE - only tests success path" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    try buffer.append('x');
    // What if allocation fails? Not tested!
}
```

✅ **Correct:**
```zig
test "COMPLETE - tests success path" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    try buffer.append('x');
}

test "COMPLETE - tests failure path" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });
    const result = Buffer.init(failing.allocator(), 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

**Why:** Real-world code can run out of memory. Test that your code handles it gracefully.

### Pitfall 3: Assuming allocations always succeed

❌ **Wrong:**
```zig
pub fn processData(allocator: Allocator) void {
    const buffer = allocator.alloc(u8, 1000); // What if this fails?
    defer allocator.free(buffer);
    // ... use buffer ...
}
```

✅ **Correct:**
```zig
pub fn processData(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u8, 1000); // Propagate error
    defer allocator.free(buffer);
    // ... use buffer ...
}
```

**Why:** Allocations can fail. Always handle errors properly.

### Pitfall 4: Not testing deinit thoroughly

❌ **Wrong:**
```zig
test "INCOMPLETE - doesn't verify cleanup" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key", "value");
    // Assumes deinit works - but does it free everything?
}
```

✅ **Correct:**
```zig
test "COMPLETE - verifies cleanup works" {
    var cache = Cache.init(testing.allocator, true, true);
    defer cache.deinit();

    try cache.put("key1", "value1");
    try cache.put("key2", "value2");
    try cache.put("key3", "value3");

    // If deinit doesn't free everything, testing.allocator will detect it
}

test "THOROUGH - tests cleanup explicitly" {
    {
        var cache = Cache.init(testing.allocator, true, true);
        defer cache.deinit();
        try cache.put("key", "value");
    }
    // Scope ends, deinit called
    // If anything leaked, next allocation will detect it

    {
        var cache = Cache.init(testing.allocator, true, true);
        defer cache.deinit();
        try cache.put("key", "value");
    }
}
```

**Why:** Proper cleanup is critical. Let `testing.allocator` verify it for you.

### Pitfall 5: Memory leaks in error paths

❌ **Wrong:**
```zig
pub fn createBuffer(allocator: Allocator) !Buffer {
    const data = try allocator.alloc(u8, 100);

    // Do some validation
    if (someCondition) {
        return error.InvalidData; // LEAK! data is not freed
    }

    return Buffer{ .data = data, ... };
}
```

✅ **Correct:**
```zig
pub fn createBuffer(allocator: Allocator) !Buffer {
    const data = try allocator.alloc(u8, 100);
    errdefer allocator.free(data); // Cleanup on error

    // Do some validation
    if (someCondition) {
        return error.InvalidData; // data is freed via errdefer
    }

    return Buffer{ .data = data, ... };
}
```

**Why:** `errdefer` ensures cleanup happens only when an error is returned.

### Pitfall 6: Confusing ownership models

❌ **Wrong:**
```zig
test "WRONG - unclear ownership" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit();

    try builder.appendSlice("test");
    const str = try builder.toString();
    // Who owns str? Did I forget to free it?
}
```

✅ **Correct:**
```zig
test "CORRECT - clear ownership" {
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit(); // Frees builder's internal buffer

    try builder.appendSlice("test");

    const str = try builder.toString(); // Creates NEW owned allocation
    defer testing.allocator.free(str); // WE own this, WE free it

    // Two separate resources, two separate cleanups
}
```

**Why:** Always be clear about who owns what. Document ownership in function signatures.

## Best Practices

### 1. Always use std.testing.allocator in tests

```zig
// ✅ GOOD
test "good test" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    // ...
}

// ❌ BAD - no leak detection
test "bad test" {
    var buffer = try Buffer.init(std.heap.page_allocator, 100);
    defer buffer.deinit();
    // ...
}
```

**Why:** `testing.allocator` provides automatic leak detection. Always use it unless you have a specific reason not to.

### 2. Test both success and failure paths

```zig
test "success path" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    try buffer.append('x');
}

test "failure path" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 0,
    });
    const result = Buffer.init(failing.allocator(), 100);
    try testing.expectError(error.OutOfMemory, result);
}
```

**Why:** Comprehensive testing catches bugs in error handling code.

### 3. Verify cleanup happens in error cases

```zig
test "cleanup on error" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 2,
    });

    var builder = try StringBuilder.init(failing.allocator());
    defer builder.deinit(); // Still cleans up partial allocations

    _ = builder.appendSlice("test") catch |err| {
        try testing.expectEqual(error.OutOfMemory, err);
        return; // deinit is called
    };
}
```

**Why:** Ensure resources are freed even when operations fail.

### 4. Test with minimal allocations first

```zig
test "minimal allocation test" {
    var buffer = try Buffer.init(testing.allocator, 1);
    defer buffer.deinit();
    // Test with smallest possible allocation first
}

test "normal allocation test" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    // Then test with typical sizes
}

test "large allocation test" {
    var buffer = try Buffer.init(testing.allocator, 1024 * 1024);
    defer buffer.deinit();
    // Finally test with large sizes
}
```

**Why:** Start simple, then increase complexity. Makes debugging easier.

### 5. Use defer immediately after allocation

```zig
// ✅ GOOD - defer right after allocation
test "good pattern" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit(); // Immediate defer

    try buffer.append('x');
    try buffer.append('y');
}

// ❌ BAD - defer too late
test "bad pattern" {
    var buffer = try Buffer.init(testing.allocator, 100);

    try buffer.append('x'); // If this fails, we leak!

    defer buffer.deinit(); // Too late
}
```

**Why:** Immediate defer prevents leaks if subsequent operations fail.

### 6. Test resource cleanup explicitly

```zig
test "explicit cleanup verification" {
    // Allocate and cleanup in separate scopes
    {
        var cache = Cache.init(testing.allocator, true, true);
        defer cache.deinit();

        try cache.put("key1", "value1");
        try cache.put("key2", "value2");
        try cache.put("key3", "value3");
    }
    // Scope ends - if anything leaked, we'll know

    // Allocate again to verify no leaks from previous scope
    {
        var cache = Cache.init(testing.allocator, true, true);
        defer cache.deinit();

        try cache.put("key4", "value4");
    }
}
```

**Why:** Multiple allocation/cleanup cycles verify cleanup is complete.

### 7. Document ownership in types and functions

```zig
/// Creates a new Buffer. Caller owns the returned memory.
/// Call deinit() to free.
pub fn init(allocator: Allocator, capacity: usize) !Buffer {
    // ...
}

/// Converts to an owned slice, transferring ownership to caller.
/// Caller must free the returned slice.
/// After calling, the Buffer is in an invalid state.
pub fn toOwnedSlice(self: *Buffer) ![]u8 {
    // ...
}
```

**Why:** Clear documentation prevents ownership confusion and leaks.

### 8. Use errdefer for cleanup in error paths

```zig
pub fn complexOperation(allocator: Allocator) !ComplexType {
    const buffer1 = try allocator.alloc(u8, 100);
    errdefer allocator.free(buffer1);

    const buffer2 = try allocator.alloc(u8, 200);
    errdefer allocator.free(buffer2);

    // If anything fails, both are cleaned up

    return ComplexType{
        .buffer1 = buffer1,
        .buffer2 = buffer2,
    };
}
```

**Why:** `errdefer` ensures cleanup only on error, not success.

## Different Allocator Types

### When to use testing.allocator

**Use for:** All unit tests (unless you have a specific reason not to)

**Features:**
- Automatic leak detection
- Detailed error messages
- Catches use-after-free
- Catches double-free

**Example:**
```zig
test "standard test pattern" {
    var buffer = try Buffer.init(testing.allocator, 100);
    defer buffer.deinit();
    // ...
}
```

### When to use ArenaAllocator in tests

**Use for:** Testing bulk allocation patterns where many small allocations are made and freed together

**Features:**
- Fast allocation
- Bulk deallocation
- No individual free needed
- Still wraps testing.allocator for leak detection

**Example:**
```zig
test "bulk allocations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Many allocations
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        _ = try allocator.alloc(u8, 10);
    }
    // All freed at once by arena.deinit()
}
```

### When to test with page_allocator

**Use for:** Testing that code works with different allocator types (allocator-agnostic code)

**Features:**
- Simple, direct OS allocation
- No leak detection
- Good for integration tests
- Tests portability

**Example:**
```zig
test "works with page_allocator" {
    var buffer = try Buffer.init(std.heap.page_allocator, 100);
    defer buffer.deinit();

    try buffer.appendSlice("test");
    // Verifies no dependency on testing.allocator specifics
}
```

**Warning:** Only use this when specifically testing allocator independence. Prefer `testing.allocator` for regular tests.

### When to use FailingAllocator

**Use for:** Testing error handling paths and out-of-memory conditions

**Features:**
- Simulates allocation failures
- Configurable fail point
- Wraps another allocator
- Tests robustness

**Example:**
```zig
test "handles allocation failure" {
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 2,
    });
    const allocator = failing.allocator();

    var buffer = try Buffer.init(allocator, 10); // 1st alloc OK
    defer buffer.deinit();

    try buffer.append('A'); // 2nd alloc OK

    const result = buffer.append('B'); // 3rd alloc FAILS
    try testing.expectError(error.OutOfMemory, result);
}
```

### When to use FixedBufferAllocator in tests

**Use for:** Testing with limited memory or embedded scenarios

**Features:**
- Fixed-size buffer
- No OS allocation
- Predictable behavior
- Good for testing resource constraints

**Example:**
```zig
test "works with fixed buffer" {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var my_buffer = try Buffer.init(allocator, 100);
    defer my_buffer.deinit();

    // Tests that code works with limited memory
}
```

## Testing Patterns

### Pattern 1: Basic Allocation Test

**Purpose:** Verify basic allocation and deallocation works correctly.

```zig
test "basic allocation pattern" {
    // 1. Allocate with testing.allocator
    var resource = try ResourceType.init(testing.allocator, params);

    // 2. Immediate defer for cleanup
    defer resource.deinit();

    // 3. Verify allocation succeeded
    try testing.expect(resource.isValid());

    // 4. Use the resource
    try resource.doSomething();

    // 5. Cleanup happens automatically via defer
    //    If anything leaks, test fails
}
```

**Key points:**
- Use `testing.allocator`
- Defer immediately
- Testing allocator verifies cleanup

### Pattern 2: Leak Detection Test

**Purpose:** Demonstrate and verify leak detection works.

```zig
test "leak detection pattern" {
    // Test that SHOULD pass (proper cleanup)
    {
        var buffer = try Buffer.init(testing.allocator, 100);
        defer buffer.deinit(); // Cleanup happens
        try buffer.appendSlice("test");
    }

    // If we forgot defer, we could demonstrate the leak:
    // (Keep commented out - this would fail)
    //
    // {
    //     var buffer = try Buffer.init(testing.allocator, 100);
    //     // Missing: defer buffer.deinit();
    //     try buffer.appendSlice("leak!");
    //     // Test would FAIL with leak detection error
    // }
}
```

**Key points:**
- Show correct pattern
- Comment out leak demonstrations
- Document what would happen

### Pattern 3: Failure Path Test

**Purpose:** Test that allocation failures are handled correctly.

```zig
test "failure path pattern" {
    // 1. Create FailingAllocator
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = N, // Choose which allocation fails
    });
    const allocator = failing.allocator();

    // 2. Attempt operation that should fail
    const result = OperationThatAllocates(allocator);

    // 3. Verify correct error
    try testing.expectError(error.OutOfMemory, result);

    // 4. Verify no leaks (FailingAllocator wraps testing.allocator)
}
```

**Variations:**
```zig
// Fail immediately
.fail_index = 0  // 1st allocation fails

// Fail on second allocation
.fail_index = 1  // 2nd allocation fails

// Test partial success then failure
.fail_index = 3  // 4th allocation fails (some succeed first)
```

### Pattern 4: Complex Resource Test

**Purpose:** Test complex scenarios with multiple resources and cleanup.

```zig
test "complex resource pattern" {
    // 1. Create primary resource
    var resource1 = try Resource.init(testing.allocator, ...);
    defer resource1.deinit(); // Cleanup guaranteed

    // 2. Create secondary resource
    var resource2 = try Resource.init(testing.allocator, ...);
    defer resource2.deinit(); // Independent cleanup

    // 3. Perform operations that allocate
    const owned_data = try resource1.extractData();
    defer testing.allocator.free(owned_data); // Own this allocation

    // 4. Transfer ownership
    try resource2.takeOwnership(resource1.releaseData());
    // resource2 now owns that data

    // 5. All cleanup happens in reverse order:
    //    - testing.allocator.free(owned_data)
    //    - resource2.deinit() (includes transferred data)
    //    - resource1.deinit()
}
```

**Key points:**
- Multiple independent resources
- Track ownership carefully
- Document what cleans up what
- Defers execute in reverse order

### Pattern 5: Arena Allocator Test

**Purpose:** Test bulk allocation patterns.

```zig
test "arena allocator pattern" {
    // 1. Create arena wrapping testing.allocator
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit(); // Frees everything at once

    const allocator = arena.allocator();

    // 2. Make many allocations
    var resources = std.ArrayList(*Resource).init(testing.allocator);
    defer resources.deinit();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const resource = try Resource.init(allocator, ...);
        try resources.append(resource);
        // No individual deinit needed!
    }

    // 3. Use all resources
    for (resources.items) |resource| {
        try resource.process();
    }

    // 4. arena.deinit() frees everything at once
    // 5. testing.allocator verifies no leaks
}
```

**Benefits:**
- Fast allocation
- Simple cleanup
- Still get leak detection
- Good for many small allocations

### Pattern 6: Ownership Transfer Test

**Purpose:** Test proper ownership transfer between components.

```zig
test "ownership transfer pattern" {
    // 1. Create resource that will transfer ownership
    var builder = StringBuilder.init(testing.allocator);
    defer builder.deinit(); // Frees internal buffer

    try builder.appendSlice("data");

    // 2. Transfer ownership to caller
    const owned_string = try builder.toString(); // NEW allocation
    defer testing.allocator.free(owned_string); // WE own this

    // 3. Original builder still valid
    builder.clear();
    try builder.appendSlice("more data");

    // 4. Both owned_string and builder are independent
    //    Both need separate cleanup

    // 5. Cleanup happens:
    //    - testing.allocator.free(owned_string)
    //    - builder.deinit()
}
```

**Key points:**
- Distinguish between borrowed and owned
- Document ownership clearly
- Test that both resources clean up independently

### Pattern 7: Error Path Cleanup Test

**Purpose:** Verify cleanup happens even when errors occur.

```zig
test "error path cleanup pattern" {
    // 1. Setup failing allocator for specific allocation
    var failing = testing.FailingAllocator.init(testing.allocator, .{
        .fail_index = 2, // 3rd allocation fails
    });
    const allocator = failing.allocator();

    // 2. Create resource (1st allocation)
    var resource = try Resource.init(allocator);
    defer resource.deinit(); // CRITICAL: cleanup even on error

    // 3. Perform operation that might fail
    const result = resource.operation(); // Might allocate and fail

    // 4. Handle error
    if (result) |value| {
        // Success path
        try testing.expect(value > 0);
    } else |err| {
        // Error path
        try testing.expectEqual(error.OutOfMemory, err);
        // defer resource.deinit() STILL called
    }

    // 5. Verify no leaks despite error
    //    testing.allocator (wrapped by failing) checks this
}
```

**Key points:**
- Use defer BEFORE operations that might fail
- Test that partial allocations are cleaned up
- Verify behavior in both success and error cases

## File Structure

```
04_allocator_testing/
├── src/
│   ├── main.zig           # Demo application (no tests)
│   ├── buffer.zig         # Buffer with 25 tests
│   ├── string_builder.zig # StringBuilder with 20 tests
│   └── cache.zig          # Cache with 20 tests
├── build.zig              # Build configuration
└── README.md              # This file
```

## Running the Example

### Build and run the demo application:

```bash
zig build run
```

**Expected output:**
```
=== Allocator Testing Demo ===

--- Buffer Demo ---
Created buffer with capacity: 16
Buffer contents: Hello, World!
Buffer length: 13
After appending 20 'x's, capacity: 32
Buffer length: 33

--- StringBuilder Demo ---
Built string: Name: Alice, Age: 30
Length: 21
Owned copy: Name: Alice, Age: 30
After clear and reuse: Reused: 10 + 20 = 30

--- Cache Demo ---
Cache size: 4
User 1 name: Alice
User 2 email: bob@example.com
Updated User 1 name: Alice Smith
Removed user:2:name: true
Cache size after removal: 3

=== All demos completed successfully ===
```

### Run all tests:

```bash
zig build test
```

**Expected output:**
```
Test [1/25] test.Buffer: basic initialization and cleanup... PASS
Test [2/25] test.Buffer: initialization with different sizes... PASS
Test [3/25] test.Buffer: append single byte... PASS
...
Test [25/25] test.Buffer: large allocation stress test... PASS

Test [1/20] test.StringBuilder: basic initialization and cleanup... PASS
Test [2/20] test.StringBuilder: append single character... PASS
...
Test [20/20] test.StringBuilder: stress test many operations... PASS

Test [1/20] test.Cache: basic initialization and cleanup... PASS
Test [2/20] test.Cache: basic initialization with ownership... PASS
...
Test [20/20] test.Cache: empty cache operations... PASS

All 65 tests passed.
```

### Run tests for specific modules:

```bash
# Buffer tests only
zig build test-buffer

# StringBuilder tests only
zig build test-string-builder

# Cache tests only
zig build test-cache
```

### See leak detection in action:

To see what happens when memory leaks occur, uncomment one of the intentionally failing tests in any of the source files and run the tests:

```bash
# 1. Edit src/buffer.zig
# 2. Uncomment one of the "LEAK DEMO" tests at the bottom
# 3. Run tests:
zig build test-buffer
```

**You'll see output like:**
```
[gpa] (err): memory address 0x... leaked:
/path/to/buffer.zig:123:45: 0x... in Buffer.init (test)
    const data = try allocator.alloc(u8, initial_capacity);

Test [24/25] test.Buffer: LEAK DEMO... FAIL (MemoryLeakDetected)
```

This demonstrates Zig's automatic leak detection!

## Module Details

### Buffer (src/buffer.zig)

A dynamic byte buffer implementation demonstrating:
- Basic allocation/deallocation patterns
- Automatic growth on append
- Resize operations
- Ownership transfer with `toOwnedSlice()`

**25 tests covering:**
- Initialization with various sizes
- Append operations (single byte and slices)
- Clear and reuse
- Resize operations (grow, shrink, errors)
- Automatic growth on overflow
- Ownership transfer
- Multiple independent buffers
- Using different allocators (testing, arena)
- Allocation failure handling
- Stress testing

**Key test examples:**
- `test "Buffer: using std.testing.allocator detects leaks"` - Shows leak detection
- `test "Buffer: allocation failure on init"` - Tests FailingAllocator
- `test "Buffer: testing with ArenaAllocator"` - Tests arena pattern
- Commented leak demonstrations

### StringBuilder (src/string_builder.zig)

A string builder for efficient string concatenation demonstrating:
- Building strings incrementally
- Formatted printing with `print()`
- Creating owned copies with `toString()`
- Clear and reuse patterns

**20 tests covering:**
- Character and slice appending
- Formatted printing
- Clear and reuse
- Ownership with `toString()` and `toOwnedSlice()`
- Empty builder operations
- Large string concatenation
- Multiple independent builders
- Allocation failure handling
- Using with ArenaAllocator

**Key test examples:**
- `test "StringBuilder: toString creates owned copy"` - Ownership transfer
- `test "StringBuilder: allocation failure on toString"` - Error handling
- `test "StringBuilder: using with ArenaAllocator"` - Arena pattern
- Commented leak demonstrations

### Cache (src/cache.zig)

A string key-value cache with configurable ownership demonstrating:
- Managing both keys and values
- Optional ownership (can own keys, values, both, or neither)
- Complex cleanup scenarios
- HashMap-based storage

**20 tests covering:**
- Initialization with various ownership models
- Put, get, contains, remove operations
- Clear and reuse
- Updating existing entries
- Multiple entries
- All ownership combinations
- Dynamic string allocation
- Multiple independent caches
- Allocation failures
- Stress testing with many entries

**Key test examples:**
- `test "Cache: ownership combinations"` - All four ownership models
- `test "Cache: using dynamically allocated strings"` - Complex ownership
- `test "Cache: allocation failure on put"` - Error handling
- Commented leak demonstrations

## Compatibility Notes

**Zig Version:** 0.15.1 or later

**Key APIs used:**
- `std.testing.allocator` - Leak-detecting test allocator
- `std.testing.FailingAllocator` - Allocation failure simulation
- `std.heap.ArenaAllocator` - Bulk allocation
- `std.ArrayList` - Dynamic array
- `std.StringHashMap` - String key hash map

**Platform support:** All platforms supported by Zig

## Summary

This example demonstrates:

1. **Automatic leak detection** with `std.testing.allocator`
2. **Allocation failure testing** with `FailingAllocator`
3. **Proper cleanup patterns** with `defer` and `errdefer`
4. **Different allocator types** and when to use each
5. **Common pitfalls** and how to avoid them
6. **Best practices** for allocator testing in Zig

**Total tests:** 65 tests across three modules

**Key takeaways:**
- Always use `std.testing.allocator` in tests
- Use `defer` immediately after allocation
- Test both success and failure paths
- Let the testing allocator verify cleanup
- Document ownership clearly
- Test error path cleanup explicitly

By studying these patterns, you'll learn how to write robust, leak-free Zig code with comprehensive allocator testing.
