# Example 2: SQLite3 Library Integration

## Overview

This example demonstrates integration with a real-world C library (SQLite3), showing practical patterns for using external libraries, handling C APIs, and managing resources safely.

## Learning Objectives

- Link external system libraries
- Handle C library APIs and error codes
- Use prepared statements for safe SQL
- Manage C library resources with defer
- Work with C opaque pointers (?*c.sqlite3)

## Prerequisites

Install SQLite3 development libraries:

```bash
# Debian/Ubuntu
sudo apt-get install libsqlite3-dev

# macOS
brew install sqlite3

# Arch Linux
sudo pacman -S sqlite
```

## Key Concepts

### Linking System Libraries

In `build.zig`, specify external library dependencies:

```zig
exe.linkLibC();
exe.linkSystemLibrary("sqlite3");
```

### C Opaque Pointers

SQLite uses opaque pointer types that are represented as optional C pointers:

```zig
var db: ?*c.sqlite3 = null;
var stmt: ?*c.sqlite3_stmt = null;
```

### Error Handling

C libraries use integer error codes. Convert to Zig errors:

```zig
if (rc != c.SQLITE_OK) {
    std.debug.print("Error: {s}\n", .{c.sqlite3_errmsg(db)});
    return error.DatabaseError;
}
```

### Resource Management

Always pair resource acquisition with cleanup using `defer`:

```zig
var db: ?*c.sqlite3 = null;
defer _ = c.sqlite3_close(db);

var stmt: ?*c.sqlite3_stmt = null;
defer _ = c.sqlite3_finalize(stmt);
```

### Prepared Statements

SQLite prepared statements prevent SQL injection and improve performance:

```zig
const insert_sql = "INSERT INTO users (name, age) VALUES (?, ?)";
var stmt: ?*c.sqlite3_stmt = null;
_ = c.sqlite3_prepare_v2(db, insert_sql, -1, &stmt, null);

_ = c.sqlite3_bind_text(stmt, 1, "Alice", -1, c.SQLITE_TRANSIENT);
_ = c.sqlite3_bind_int(stmt, 2, 30);
_ = c.sqlite3_step(stmt);
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
=== SQLite3 Interoperability Demo ===

Opened in-memory SQLite database
SQLite version: 3.x.x

Table created successfully
Inserted: Alice, age 30
Inserted: Bob, age 25

Query results:
  ID: 1, Name: Alice, Age: 30
  ID: 2, Name: Bob, Age: 25

Database closed successfully

=== Demo Complete ===
```

## Compatibility

- Zig 0.14.1, 0.14.0
- Zig 0.15.1, 0.15.2
- Requires SQLite3 3.x

## Best Practices Demonstrated

1. **Resource safety**: Using `defer` for cleanup
2. **Error handling**: Checking return codes and reporting errors
3. **Prepared statements**: Safer than string concatenation
4. **Const strings**: Using C string literals correctly
5. **Type safety**: Using C-compatible pointer types

## Common Pitfalls Avoided

1. **Memory leaks**: Finalizing statements and closing database
2. **Null pointer dereference**: Checking database handle
3. **Error propagation**: Converting C errors to Zig errors
4. **SQL injection**: Using prepared statements with binding

## References

- [SQLite C API Documentation](https://www.sqlite.org/c3ref/intro.html)
- [Zig Language Reference - C Interop](https://ziglang.org/documentation/0.15.2/#C)
- [Ghostty passwd.zig](https://github.com/ghostty-org/ghostty/blob/main/src/os/passwd.zig) - Production example of C library usage
