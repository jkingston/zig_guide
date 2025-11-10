# Example 2: Test Organization

This example demonstrates effective test organization strategies for larger Zig projects with multiple modules, separate test files, shared test utilities, and test fixtures.

## Learning Objectives

- **Separate Test Files**: Organize tests in a dedicated `tests/` directory instead of colocating them with source code
- **Test Fixtures**: Implement setup/teardown patterns for consistent test initialization
- **Shared Test Utilities**: Create reusable test infrastructure and helper functions
- **Test Isolation**: Ensure each test is independent with its own state
- **Integration Testing**: Test multiple modules working together
- **Build System**: Configure `build.zig` to support separate test files and test suites
- **Test Organization**: Understand when to use separate test files vs colocated tests

## Project Structure

```
02_test_organization/
├── src/
│   ├── main.zig           # Entry point with demo application
│   ├── database.zig       # Mock database module (business logic only)
│   └── api.zig            # Mock API module (business logic only)
├── tests/
│   ├── test_helpers.zig   # Shared test utilities and fixtures
│   ├── database_test.zig  # Database unit tests (24 tests)
│   ├── api_test.zig       # API unit tests (24 tests)
│   └── integration_test.zig # Integration tests (10 tests)
├── build.zig              # Build configuration with test setup
└── README.md              # This file
```

## Why Organize Tests Separately?

### Colocated Tests (in src/ files)

```zig
// src/math.zig

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "add two numbers" {
    const result = add(2, 3);
    try std.testing.expectEqual(5, result);
}
```

**Pros:**
- Simple for small modules
- Tests are right next to the code they test
- Easy to find related tests
- Quick iteration during development

**Cons:**
- Tests compile into production binary (unless using `@setEvalBranchQuota`)
- Hard to share test utilities between modules
- Can't easily run subsets of tests
- Mixes concerns (business logic + test code)

### Separate Test Files (in tests/ directory)

```zig
// src/math.zig
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

// tests/math_test.zig
const math = @import("../src/math.zig");

test "add two numbers" {
    const result = math.add(2, 3);
    try std.testing.expectEqual(5, result);
}
```

**Pros:**
- Clean separation of concerns
- Tests never compile into production code
- Easy to share test utilities across test files
- Can run specific test suites independently
- Better for larger projects with many tests
- Enables integration testing across modules

**Cons:**
- Slightly more boilerplate
- Need to configure `build.zig` properly
- Import paths are a bit longer

## Running the Demo

```bash
# Run the demo application
zig build run

# Run all tests
zig build test

# Run specific test suites
zig build test-database      # Database tests only
zig build test-api            # API tests only
zig build test-integration    # Integration tests only
```

## Key Concepts

### 1. Test Fixtures

Test fixtures provide a consistent setup and teardown pattern for tests:

```zig
// tests/test_helpers.zig
pub const TestContext = struct {
    allocator: std.mem.Allocator,
    db: Database,
    api: ApiServer,

    pub fn init(allocator: std.mem.Allocator) TestContext {
        var db = Database.init(allocator);
        const api = ApiServer.init(allocator, &db);
        return .{ .allocator = allocator, .db = db, .api = api };
    }

    pub fn deinit(self: *TestContext) void {
        self.db.deinit();
    }
};

// Usage in tests
test "example test with fixture" {
    var ctx = TestContext.init(std.testing.allocator);
    defer ctx.deinit();

    // Use ctx.db and ctx.api
    try ctx.api.createUser(user);
}
```

**Benefits:**
- Consistent test setup across all tests
- Automatic cleanup with `defer`
- Reduces boilerplate in individual tests
- Ensures proper resource management

### 2. Fixture Functions

For more flexibility, use fixture functions that take test code as a parameter:

```zig
// tests/test_helpers.zig
pub fn withTestDatabase(
    comptime testFn: fn (*Database) anyerror!void,
) !void {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();
    try testFn(&db);
}

// Usage in tests
test "example test with fixture function" {
    try helpers.withTestDatabase(struct {
        fn testFn(db: *Database) !void {
            try db.insert("key", "value");
            try std.testing.expectEqual(1, db.count());
        }
    }.testFn);
}
```

### 3. Shared Test Utilities

Create reusable test helpers to reduce duplication:

```zig
// tests/test_helpers.zig

// Test data
pub const TestUsers = struct {
    pub const alice = User{
        .id = "alice_123",
        .name = "Alice Test",
        .email = "alice@test.com",
    };
    // ... more test users
};

// Helper functions
pub fn expectUser(actual: User, expected: User) !void {
    try std.testing.expectEqualStrings(expected.id, actual.id);
    try std.testing.expectEqualStrings(expected.name, actual.name);
    try std.testing.expectEqualStrings(expected.email, actual.email);
}

pub fn populateTestUsers(api: *ApiServer) !void {
    try api.createUser(TestUsers.alice);
    try api.createUser(TestUsers.bob);
    try api.createUser(TestUsers.charlie);
}
```

### 4. Test Isolation

Each test should be independent with its own state:

❌ **Bad: Shared mutable state**
```zig
var global_db: Database = undefined;

test "test 1" {
    global_db = Database.init(allocator);  // Initializes global state
    // ... test code
}

test "test 2" {
    // Depends on test 1 running first - FRAGILE!
    try global_db.insert("key", "value");
}
```

✅ **Good: Each test creates its own state**
```zig
test "test 1" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();
    // ... test code with isolated db
}

test "test 2" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();
    // ... test code with its own isolated db
}
```

### 5. Integration Testing

Integration tests verify multiple modules working together:

```zig
// tests/integration_test.zig
test "Integration: complete user lifecycle" {
    var ctx = helpers.TestContext.init(std.testing.allocator);
    defer ctx.deinit();

    // Create user (API -> Database)
    try ctx.api.createUser(TestUsers.alice);
    try std.testing.expectEqual(1, ctx.db.count());

    // Retrieve user (API -> Database)
    const user = try ctx.api.getUser(TestUsers.alice.id);
    try helpers.expectUser(user, TestUsers.alice);

    // Update user (API -> Database)
    const updated = User{ .id = "alice_123", .name = "Alice Updated", ... };
    try ctx.api.updateUser(updated);

    // Delete user (API -> Database)
    try ctx.api.deleteUser(TestUsers.alice.id);
    try std.testing.expectEqual(0, ctx.db.count());
}
```

### 6. Build System Configuration

The `build.zig` file defines how tests are organized and run:

```zig
pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Run all tests");

    // Database tests
    const database_tests = b.addTest(.{
        .name = "database-tests",
        .root_source_file = b.path("tests/database_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_database_tests = b.addRunArtifact(database_tests);
    test_step.dependOn(&run_database_tests.step);

    // API tests
    const api_tests = b.addTest(.{
        .name = "api-tests",
        .root_source_file = b.path("tests/api_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_api_tests = b.addRunArtifact(api_tests);
    test_step.dependOn(&run_api_tests.step);

    // Integration tests
    const integration_tests = b.addTest(.{
        .name = "integration-tests",
        .root_source_file = b.path("tests/integration_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_integration_tests = b.addRunArtifact(integration_tests);
    test_step.dependOn(&run_integration_tests.step);
}
```

This allows running all tests with `zig build test` or specific suites individually.

## Test Organization Patterns

### Unit Tests (database_test.zig, api_test.zig)

- Test a single module in isolation
- Mock or stub dependencies
- Focus on one function or method at a time
- Fast execution
- High test count (many small tests)

Example structure:
```zig
// ============================================================================
// Basic Operations Tests
// ============================================================================

test "Database: insert single entry" { ... }
test "Database: insert multiple entries" { ... }
test "Database: insert returns DuplicateKey error" { ... }

// ============================================================================
// State Management Tests
// ============================================================================

test "Database: count tracks entries correctly" { ... }
test "Database: clear removes all entries" { ... }
```

### Integration Tests (integration_test.zig)

- Test multiple modules working together
- Exercise full workflows
- Verify data flows correctly between layers
- May be slower than unit tests
- Fewer tests, but more comprehensive

Example structure:
```zig
// ============================================================================
// Full Stack Integration Tests
// ============================================================================

test "Integration: complete user lifecycle" { ... }
test "Integration: multiple users coexist independently" { ... }

// ============================================================================
// Error Propagation Tests
// ============================================================================

test "Integration: database errors propagate through API" { ... }
```

## Common Patterns and Best Practices

### 1. Test Organization by Category

Group related tests with comments:

```zig
// ============================================================================
// Basic Operations Tests
// ============================================================================

test "feature 1" { ... }
test "feature 2" { ... }

// ============================================================================
// Error Handling Tests
// ============================================================================

test "error case 1" { ... }
test "error case 2" { ... }
```

### 2. Descriptive Test Names

Use clear, descriptive test names that explain what is being tested:

❌ **Bad:**
```zig
test "test1" { ... }
test "db test" { ... }
test "it works" { ... }
```

✅ **Good:**
```zig
test "Database: insert returns DuplicateKey error for existing key" { ... }
test "ApiServer: createUser adds user to database" { ... }
test "Integration: complete user lifecycle (CRUD)" { ... }
```

### 3. Test Naming Convention

Use a consistent naming convention for test files:

```
module_name_test.zig    // Tests for module_name.zig
feature_test.zig        // Tests for a specific feature
integration_test.zig    // Integration tests
```

### 4. Use std.testing.allocator

Always use `std.testing.allocator` in tests to detect memory leaks:

```zig
test "memory leak detection" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();  // If you forget this, test will fail!

    // ... test code
}
```

### 5. Setup and Teardown Pattern

Use `defer` for cleanup to ensure resources are freed even if tests fail:

```zig
test "proper cleanup with defer" {
    var ctx = TestContext.init(std.testing.allocator);
    defer ctx.deinit();  // Always runs, even on test failure

    // If this fails, deinit() still runs
    try ctx.api.createUser(user);
}
```

## Common Pitfalls

### 1. Test Dependencies

❌ **Don't:** Create tests that depend on execution order
```zig
var shared_state: i32 = 0;

test "increment" {
    shared_state += 1;  // Assumes shared_state starts at 0
}

test "check value" {
    try expectEqual(1, shared_state);  // Assumes "increment" ran first!
}
```

✅ **Do:** Make each test independent
```zig
test "increment" {
    var state: i32 = 0;
    state += 1;
    try expectEqual(1, state);
}

test "check value" {
    var state: i32 = 0;
    // ... independent test logic
}
```

### 2. Shared Mutable State

❌ **Don't:** Use global mutable state in tests
```zig
var global_db: Database = undefined;

test "test 1" {
    global_db = Database.init(allocator);
    // ...
}
```

✅ **Do:** Create state locally or use fixtures
```zig
test "test 1" {
    var ctx = TestContext.init(std.testing.allocator);
    defer ctx.deinit();
    // ...
}
```

### 3. Not Cleaning Up Resources

❌ **Don't:** Forget to clean up allocated resources
```zig
test "memory leak" {
    var db = Database.init(std.testing.allocator);
    // Oops, forgot db.deinit() - test will fail!
}
```

✅ **Do:** Always use defer for cleanup
```zig
test "proper cleanup" {
    var db = Database.init(std.testing.allocator);
    defer db.deinit();
    // ...
}
```

### 4. Testing Implementation Details

❌ **Don't:** Test internal implementation details
```zig
test "database uses HashMap internally" {
    var db = Database.init(allocator);
    defer db.deinit();

    // Testing internal data structure - brittle!
    try expectEqual(0, db.data.count());
}
```

✅ **Do:** Test public API and behavior
```zig
test "database starts empty" {
    var db = Database.init(allocator);
    defer db.deinit();

    // Testing public behavior - stable!
    try expectEqual(0, db.count());
}
```

## When to Use Colocated vs Separate Tests

### Use Colocated Tests (in src/) When:

- Small, simple modules (single file)
- Quick prototyping or experimentation
- Library code where tests serve as examples
- Tests are minimal and don't need shared utilities

### Use Separate Tests (in tests/) When:

- Multiple modules that interact
- Need shared test utilities or fixtures
- Want to run specific test suites independently
- Large codebase with many tests
- Integration testing across modules
- Production code should not include test code

## Project Example Breakdown

### src/database.zig

A mock key-value database with:
- `insert()`, `get()`, `update()`, `delete()`, `exists()`
- Proper error handling (DuplicateKey, KeyNotFound)
- Memory management with allocator
- 24 unit tests in `tests/database_test.zig`

### src/api.zig

A mock API server that uses the database:
- `createUser()`, `getUser()`, `updateUser()`, `deleteUser()`
- Request handling with `handleRequest()`
- User serialization/deserialization
- 24 unit tests in `tests/api_test.zig`

### tests/test_helpers.zig

Shared test infrastructure:
- `TestContext` fixture for setup/teardown
- `TestUsers` with predefined test data
- Helper functions like `expectUser()`, `populateTestUsers()`
- Fixture functions like `withTestDatabase()`

### tests/integration_test.zig

Integration tests verifying:
- Complete user lifecycle (CRUD operations)
- Error propagation across modules
- Data consistency end-to-end
- Bulk operations and stress testing

## Compatibility Notes

This example is compatible with Zig 0.15.1+.

### Zig 0.14.1 vs 0.15.2 Differences

The main difference is in `build.zig`:

**Zig 0.14.1:**
```zig
.root_source_file = .{ .path = "tests/database_test.zig" },
```

**Zig 0.15.1+:**
```zig
.root_source_file = b.path("tests/database_test.zig"),
```

The test code itself is identical across versions.

## Summary

This example demonstrates:

1. ✅ **Separate test files** in `tests/` directory for better organization
2. ✅ **Test fixtures** with `TestContext` for consistent setup/teardown
3. ✅ **Shared test utilities** in `test_helpers.zig` for reusable code
4. ✅ **Test isolation** with independent state per test
5. ✅ **Integration tests** verifying multiple modules together
6. ✅ **Build system configuration** with separate test suites
7. ✅ **Best practices** for naming, organization, and error handling

Total: **58 tests** (24 database + 24 API + 10 integration)

All tests pass, demonstrate memory safety with `std.testing.allocator`, and show effective patterns for organizing tests in larger Zig projects.
