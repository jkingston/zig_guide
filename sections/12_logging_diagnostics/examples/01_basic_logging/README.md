# Example 1: Basic Logging with std.log

This example demonstrates fundamental `std.log` usage with different log levels and scoped logging.

## Learning Objectives

- Understand the four log levels (err, warn, info, debug)
- Use scoped logging to categorize messages by subsystem
- Configure compile-time log filtering via build options
- See how log output differs by level

## Building and Running

### Default (info level in release, debug level in debug mode)

```bash
zig build run
```

### With specific log level (compile-time filtering)

```bash
# Show only errors
zig build run -Dlog-level=err

# Show errors and warnings
zig build run -Dlog-level=warn

# Show errors, warnings, and info (default for release)
zig build run -Dlog-level=info

# Show all logs including debug
zig build run -Dlog-level=debug
```

### Debug build (includes debug logs by default)

```bash
zig build run -Doptimize=Debug
```

## Expected Output

### With `-Dlog-level=info`:

```
info: Application started
info: Server listening on port 8080
error: This is an error message - something went wrong
warning: This is a warning - potential issue detected
info: This is an info message - general state info
info(database): Connecting to database...
info(database): Database connection established
info(network): Sending HTTP request to https://api.example.com/data
info(network): Request completed successfully
warning: Memory usage high: 85.5%
error(database): Invalid SQL syntax detected
error: Query failed: InvalidSQL
info: Application shutting down
```

### With `-Dlog-level=debug`:

```
info: Application started
debug: Debug mode enabled
info: Server listening on port 8080
error: This is an error message - something went wrong
warning: This is a warning - potential issue detected
info: This is an info message - general state info
debug: This is a debug message - detailed diagnostics
info(database): Connecting to database...
debug(database): Connection parameters: host=localhost port=5432
info(database): Database connection established
debug(database): Executing query: SELECT * FROM users
debug(database): Query completed successfully
info(network): Sending HTTP request to https://api.example.com/data
debug(network): Request headers: User-Agent=ZigHTTP/1.0
debug(network): Received response: 200 OK
info(network): Request completed successfully
warning: Memory usage high: 85.5%
debug(database): Executing query: INVALID SQL
error(database): Invalid SQL syntax detected
error: Query failed: InvalidSQL
info: Application shutting down
```

### With `-Dlog-level=err`:

```
error: This is an error message - something went wrong
error(database): Invalid SQL syntax detected
error: Query failed: InvalidSQL
```

## Key Concepts Demonstrated

### 1. Default Scope Logging

```zig
const log = std.log;
log.info("Application started", .{});
```

Uses the `.default` scope, appears as `info:` without scope prefix.

### 2. Scoped Logging

```zig
// In database.zig
const log = std.log.scoped(.database);
log.info("Connecting to database...", .{});
```

Creates a scoped logger for the `.database` subsystem, appears as `info(database):`.

### 3. Log Levels

- `err`: Errors requiring attention (always shown in production)
- `warn`: Potential issues worth investigating
- `info`: Important state changes and events
- `debug`: Detailed diagnostics (development only)

### 4. Compile-Time Filtering

When you specify `-Dlog-level=warn`, all `info` and `debug` logs are **completely removed** from the compiled binary—they have zero runtime cost.

## File Structure

```
01_basic_logging/
├── build.zig              # Build configuration with log level option
├── README.md              # This file
└── src/
    ├── main.zig          # Main entry point with default scope
    ├── database.zig      # Database module with .database scope
    └── network.zig       # Network module with .network scope
```

## Zig Version Compatibility

- ✅ Zig 0.14.0
- ✅ Zig 0.14.1
- ✅ Zig 0.15.1
- ✅ Zig 0.15.2

## Next Steps

- **Example 2**: Custom log handlers for different output formats
- **Example 3**: Diagnostic output in tests and CI
- **Example 4**: Structured logging with JSON
