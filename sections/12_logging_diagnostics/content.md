# Logging, Diagnostics & Observability

> **TL;DR for production logging:**
> - **std.log:** Built-in logging with compile-time levels (err, warn, info, debug)
> - **Compile-time filtering:** Disabled logs have zero runtime cost
> - **Usage:** `std.log.info("msg {d}", .{val})` or scoped: `const log = std.log.scoped(.network);`
> - **Custom loggers:** Implement `pub fn log(...)` for custom formatting/output (JSON, metrics)
> - **Production:** std.log to stderr by default, override for structured logging
> - **Jump to:** [Basic logging §12.2](#stdlog-usage) | [Scopes §12.3](#log-scopes) | [Custom loggers §12.4](#custom-log-implementations)

## Overview

Production systems require visibility into their runtime behavior to debug issues, monitor health, and understand performance characteristics. Zig provides `std.log` as its standard logging facility, designed with compile-time optimization and zero-cost abstractions as core principles.

Unlike runtime logging frameworks in other languages, Zig's logging system leverages compile-time evaluation to completely remove filtered log statements from compiled binaries. This design eliminates the traditional trade-off between observability and performance—developers can instrument code freely without impacting production performance when logs are disabled.

**Key Characteristics:**

- **Compile-time filtering**: Disabled logs have zero runtime cost
- **Scope-based organization**: Categorize logs by subsystem
- **Customizable output**: Override log handlers for structured formats
- **Thread-safe by default**: Built-in synchronization for concurrent access
- **Minimal overhead**: Default handler uses stack-only buffers

This chapter covers practical logging patterns for development debugging, testing diagnostics, and production observability. We examine real-world usage from production Zig codebases including TigerBeetle, Ghostty, Bun, and ZLS to demonstrate proven approaches.

### Why Logging Matters

**Development:** Logging provides runtime visibility during active development, helping developers understand program flow, inspect state, and diagnose unexpected behavior without a debugger.

**Testing:** Test-specific logging improves failure diagnostics, making it easier to understand why a test failed and reproduce issues in CI environments.

**Production:** Operational logging enables monitoring, alerting, debugging customer issues, and understanding system behavior at scale.

**Zig's Approach:** The std.log system balances these needs through compile-time configuration—verbose logging during development, focused logging in production, all with minimal runtime cost.

### Chapter Roadmap

This chapter covers six major topics:

1. **std.log Fundamentals** - Architecture, log levels, and core API
2. **Scoped Logging** - Organizing logs by subsystem
3. **Custom Log Handlers** - Structured output and platform integration
4. **Diagnostic Patterns** - Testing and development diagnostics
5. **Production Strategies** - Performance-conscious production logging
6. **Observability Integration** - Structured logging and distributed tracing

---

## Core Concepts

### The std.log Module

Zig's logging system is defined in `std/log.zig` and provides a standardized interface that libraries and applications can use consistently[^1]. The core design principle is compile-time optimization: log statements filtered out at compile time are completely removed from the binary.

**Architecture Overview:**

```zig
const std = @import("std");
const log = std.log;

pub fn main() void {
    log.err("Error: critical failure", .{});
    log.warn("Warning: approaching limit", .{});
    log.info("Info: request completed", .{});
    log.debug("Debug: cache hit", .{});
}
```

Each log level represents a different severity:

- **err**: Errors that require attention
- **warn**: Potential issues worth investigating
- **info**: Important state changes and events
- **debug**: Detailed diagnostics for development

**Compile-Time Filtering:**

The `std.log.logEnabled()` function determines at compile time whether a log statement should be included:

```zig
fn log(
    comptime message_level: Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Compile-time check - filtered logs are completely removed
    if (comptime !logEnabled(message_level, scope)) return;

    std.options.logFn(message_level, scope, format, args);
}
```

When a log is filtered out, the entire function call—including argument evaluation—is eliminated during compilation. This provides true zero-cost abstraction for disabled logs[^1].

### Log Levels and Hierarchy

Zig defines four log levels with increasing verbosity:

```zig
pub const Level = enum {
    err,    // 0 - Highest priority
    warn,   // 1
    info,   // 2
    debug,  // 3 - Lowest priority
};
```

The numeric values determine filtering: a log level setting of `.warn` enables `err` and `warn` but filters out `info` and `debug`.

**Default Log Level:**

The default log level depends on the build mode[^1]:

```zig
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,                              // All logs enabled
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,  // Debug logs filtered out
};
```

This provides verbose logging during development (Debug mode) while automatically reducing log volume in release builds.

**Level Selection Guidelines:**

| Level | Use Case | Production? | Example |
|-------|----------|-------------|---------|
| `err` | Unrecoverable errors, data corruption, resource failures | Always enabled | `log.err("Database connection failed: {s}", .{@errorName(err)})` |
| `warn` | Approaching limits, deprecated usage, recoverable errors | Usually enabled | `log.warn("Connection pool at 90% capacity", .{})` |
| `info` | Lifecycle events, state changes, request completion | Selectively enabled (may be sampled) | `log.info("Server started on port {d}", .{port})` |
| `debug` | Internal state, algorithm traces, cache behavior | Development only | `log.debug("Cache hit for key: {s}", .{key})` |

**Configuring Log Levels:**

Set the global log level through `std.Options`:

```zig
pub const std_options: std.Options = .{
    .log_level = .info,  // Filter out debug logs
};
```

For finer control, set per-scope levels:

```zig
pub const std_options: std.Options = .{
    .log_level = .info,  // Global default
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .network, .level = .debug },  // Verbose network logs
        .{ .scope = .cache, .level = .warn },     // Only cache warnings
    },
};
```

This enables debugging specific subsystems without flooding logs with output from other components.

### Scoped Logging

Scopes provide a namespacing mechanism for categorizing log messages by subsystem or module. Each scope creates a separate logging namespace with its own filtering rules.

**Creating Scoped Loggers:**

```zig
const database_log = std.log.scoped(.database);
const network_log = std.log.scoped(.network);
const auth_log = std.log.scoped(.auth);

pub fn connectDatabase() !void {
    database_log.info("Connecting to database...", .{});
    database_log.debug("Connection string: {s}", .{conn_str});
}

pub fn handleRequest(req: Request) !void {
    network_log.info("GET {s}", .{req.path});

    if (req.needsAuth()) {
        auth_log.debug("Validating credentials", .{});
    }
}
```

**Output Format:**

Scoped logs include the scope name in the output:

```
info: Application started                    # Default scope
info(database): Connecting to database...     # Database scope
debug(database): Connection string: ...       # Database scope
info(network): GET /api/users                  # Network scope
debug(auth): Validating credentials           # Auth scope
```

The scope prefix makes it easy to filter logs by subsystem when debugging or analyzing production issues.

**Real-World Usage:**

TigerBeetle uses scoped logging extensively, with one scoped logger per module[^3]:

```zig
// In src/vsr.zig
const log = std.log.scoped(.vsr);

// In src/vsr/superblock.zig
const log = std.log.scoped(.superblock);

// In src/vsr/journal.zig
const log = std.log.scoped(.journal);

// In src/io/linux.zig
const log = std.log.scoped(.io);
```

This pattern enables filtering by subsystem during development (e.g., only show storage logs) while maintaining organized log output in production.

**Scope Naming Conventions:**

Based on analysis of production codebases, effective scope names are:

- Lowercase identifiers: `.database` not `.Database`
- Concise (1-2 words): `.network` not `.network_layer_handler`
- Functionally descriptive: `.auth` not `.module_3`
- Module-aligned: One scope per logical module

### Custom Log Handlers

The default log handler outputs to stderr with a simple format, but applications can override this behavior by providing a custom `logFn` in `std.Options`[^2].

**Handler Signature:**

```zig
pub fn customLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Custom handler implementation
}
```

The handler receives compile-time known level, scope, and format, plus runtime arguments. This enables optimization while providing flexibility.

**Default Handler Implementation:**

The standard library's default handler is instructive[^1]:

```zig
pub fn defaultLog(
    comptime message_level: Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderrWriter(&buffer);
    defer std.debug.unlockStderrWriter();

    nosuspend stderr.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}
```

**Key Features:**
- Uses 64-byte stack buffer (no heap allocation)
- Thread-safe via stderr locking
- Silently ignores write errors
- Outputs to stderr (keeps stdout clean for program output)

**Thread Safety Requirements:**

Custom handlers **must** be thread-safe. Use `std.debug.lockStdErr()` / `unlockStdErr()` to serialize access:

⚠️ **Version Note:** Custom log handlers require explicit buffer management in Zig 0.15+. The examples below show both the legacy 0.14.x API and the current 0.15+ buffered writer pattern. Buffering improves performance but requires appropriate buffer sizes for your logging needs. For real-time logging where immediate output is critical, use smaller buffers or call `.flush()` after writing.

```zig
pub fn threadSafeLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    // Safe to write to stderr while locked
    stderr.interface.print("[{s}] ({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

**Timestamped Handler:**

Adding timestamps helps correlate logs with external events:

```zig
pub fn timestampedLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    const timestamp = std.time.timestamp();

    nosuspend stderr.interface.print("[{d}] {s}({s}): " ++ format ++ "\n", .{
        timestamp,
        level.asText(),
        @tagName(scope),
    } ++ args) catch return;
}

pub const std_options: std.Options = .{
    .logFn = timestampedLogFn,
};
```

Output:
```
[1730860800] info(default): Application started
[1730860801] error(database): Connection failed
```

**JSON Structured Handler:**

For machine-parseable logs, output JSON:

```zig
pub fn jsonLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [2048]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
    const stderr = &stderr_writer.interface;

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Format message into buffer
    var buf: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

    nosuspend {
        stderr.writeAll("{\"timestamp\":") catch return;
        stderr.print("{d}", .{std.time.timestamp()}) catch return;
        stderr.writeAll(",\"level\":\"") catch return;
        stderr.writeAll(level.asText()) catch return;
        stderr.writeAll("\",\"scope\":\"") catch return;
        stderr.writeAll(@tagName(scope)) catch return;
        stderr.writeAll("\",\"message\":\"") catch return;

        // Escape special characters for valid JSON
        for (message) |c| {
            switch (c) {
                '"' => stderr.writeAll("\\\"") catch return,
                '\\' => stderr.writeAll("\\\\") catch return,
                '\n' => stderr.writeAll("\\n") catch return,
                else => stderr.writeByte(c) catch return,
            }
        }

        stderr.writeAll("\"}\n") catch return;
        stderr.flush() catch return;
    };
}
```

Output:
```json
{"timestamp":1730860800,"level":"info","scope":"default","message":"Application started"}
{"timestamp":1730860801,"level":"error","scope":"database","message":"Connection failed"}
```

This format integrates with log aggregation tools like Elasticsearch, Loki, and CloudWatch Logs.

**Platform-Specific Integration:**

Ghostty demonstrates platform-aware logging by integrating with macOS Unified Logging[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    if (builtin.target.os.tag.isDarwin()) {
        // Map Zig levels to macOS levels
        const mac_level: macos.os.LogType = switch (level) {
            .debug => .debug,
            .info => .info,
            .warn => .err,
            .err => .fault,
        };

        const logger = macos.os.Log.create(bundle_id, @tagName(scope));
        defer logger.release();
        logger.log(std.heap.c_allocator, mac_level, format, args);
    }

    // Also output to stderr
    var buffer: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&buffer);
    nosuspend stderr.print("{s}({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

This enables viewing logs via the macOS Console app or `log stream` command while maintaining cross-platform stderr output.

### Diagnostic Utilities

The `std.debug` module provides additional diagnostic tools complementing std.log[^6].

**Debug Printing:**

For quick printf-style debugging:

```zig
const std = @import("std");

pub fn debugExample() void {
    const value = 42;
    std.debug.print("Value: {d}\n", .{value});
}
```

**Important:** `std.debug.print` is for temporary debugging only. Use `std.log` for permanent instrumentation—it provides scoping, filtering, and consistent output format.

**Stack Traces:**

Generate stack traces for diagnostic output:

```zig
pub fn diagnoseError() void {
    std.log.err("Error occurred, dumping stack trace:", .{});
    std.debug.dumpCurrentStackTrace(null);
}
```

This prints a full stack trace showing the call chain leading to the current location. Useful for debugging unexpected code paths or error conditions.

**Limitations:**
- Requires debug symbols (doesn't work with stripped binaries)
- Not available on all platforms (WASM, some embedded targets)
- Performance overhead in debug builds

**Hex Dump:**

For inspecting binary data:

```zig
const data = [_]u8{ 0x48, 0x65, 0x6c, 0x6c, 0x6f };
std.debug.dumpHex(&data);
```

Output:
```
7ffc12345678  48 65 6c 6c 6f  Hello
```

Useful for debugging serialization, network protocols, or file formats.

**Assertions vs Logging:**

Assertions check invariants and panic if violated:

```zig
const assert = std.debug.assert;
assert(value > 0);  // Panics if false (in Debug/ReleaseSafe)
```

Logging reports observable events:

```zig
if (value <= 0) {
    log.err("Invalid value: {d}", .{value});
    return error.InvalidValue;
}
```

**Best Practice:** Use assertions for invariants that should never fail. Use logging for expected error conditions and observable state changes.

---

## Code Examples

### Example 1: Basic Logging with Scopes

This example demonstrates fundamental std.log usage with different levels and scopes.

**main.zig:**

```zig
const std = @import("std");
const database = @import("database.zig");
const network = @import("network.zig");

pub fn main() !void {
    const log = std.log;

    // Default scope logging
    log.info("Application started", .{});
    log.debug("Debug mode enabled", .{});

    const port: u16 = 8080;
    log.info("Server listening on port {d}", .{port});

    // Demonstrate all log levels
    log.err("This is an error message", .{});
    log.warn("This is a warning message", .{});
    log.info("This is an info message", .{});
    log.debug("This is a debug message", .{});

    // Use scoped logging from other modules
    try database.connect();
    try database.query("SELECT * FROM users");

    try network.sendRequest("https://api.example.com/data");

    log.info("Application shutting down", .{});
}
```

**database.zig:**

```zig
const std = @import("std");
const log = std.log.scoped(.database);

pub fn connect() !void {
    log.info("Connecting to database...", .{});
    log.debug("Connection parameters: host=localhost port=5432", .{});
    log.info("Database connection established", .{});
}

pub fn query(sql: []const u8) !void {
    log.debug("Executing query: {s}", .{sql});

    if (std.mem.indexOf(u8, sql, "INVALID") != null) {
        log.err("Invalid SQL syntax detected", .{});
        return error.InvalidSQL;
    }

    log.debug("Query completed successfully", .{});
}
```

**network.zig:**

```zig
const std = @import("std");
const log = std.log.scoped(.network);

pub fn sendRequest(url: []const u8) !void {
    log.info("Sending HTTP request to {s}", .{url});
    log.debug("Request headers: User-Agent=ZigHTTP/1.0", .{});
    log.debug("Received response: 200 OK", .{});
    log.info("Request completed successfully", .{});
}
```

**Output (with log_level = .info):**

```
info: Application started
info: Server listening on port 8080
error: This is an error message
warning: This is a warning message
info: This is an info message
info(database): Connecting to database...
info(database): Database connection established
info(network): Sending HTTP request to https://api.example.com/data
info(network): Request completed successfully
info: Application shutting down
```

**Output (with log_level = .debug):**

```
info: Application started
debug: Debug mode enabled
info: Server listening on port 8080
error: This is an error message
warning: This is a warning message
info: This is an info message
debug: This is a debug message
info(database): Connecting to database...
debug(database): Connection parameters: host=localhost port=5432
info(database): Database connection established
debug(database): Executing query: SELECT * FROM users
debug(database): Query completed successfully
info(network): Sending HTTP request to https://api.example.com/data
debug(network): Request headers: User-Agent=ZigHTTP/1.0
debug(network): Received response: 200 OK
info(network): Request completed successfully
info: Application shutting down
```

**Key Observations:**

- Scoped logs show subsystem name: `info(database):` vs `info:`
- Debug logs are only visible when `log_level = .debug`
- Each module has its own scoped logger
- Output goes to stderr (keeps stdout clean)

### Example 2: Structured Logging with Context

For production systems, structured logging enables automated analysis and correlation:

```zig
const std = @import("std");

pub const LogContext = struct {
    correlation_id: []const u8,
    user_id: ?u32 = null,
    request_path: ?[]const u8 = null,

    pub fn logInfo(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.info, format, args);
    }

    pub fn logError(
        self: LogContext,
        comptime format: []const u8,
        args: anytype,
    ) void {
        self.logWithLevel(.err, format, args);
    }

    fn logWithLevel(
        self: LogContext,
        level: std.log.Level,
        comptime format: []const u8,
        args: anytype,
    ) void {
        // 🕐 **0.14.x:**
        // const stderr = std.io.getStdErr().writer();

        // ✅ **0.15+:**
        var stderr_buf: [2048]u8 = undefined;
        var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
        const stderr = &stderr_writer.interface;

        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();

        var buf: [4096]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

        nosuspend {
            stderr.writeAll("{") catch return;

            stderr.writeAll("\"timestamp\":") catch return;
            stderr.print("{d}", .{std.time.milliTimestamp()}) catch return;

            stderr.writeAll(",\"level\":\"") catch return;
            stderr.writeAll(level.asText()) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll(",\"correlation_id\":\"") catch return;
            stderr.writeAll(self.correlation_id) catch return;
            stderr.writeAll("\"") catch return;

            if (self.user_id) |uid| {
                stderr.writeAll(",\"user_id\":") catch return;
                stderr.print("{d}", .{uid}) catch return;
            }

            if (self.request_path) |path| {
                stderr.writeAll(",\"path\":\"") catch return;
                stderr.writeAll(path) catch return;
                stderr.writeAll("\"") catch return;
            }

            stderr.writeAll(",\"message\":\"") catch return;
            stderr.writeAll(message) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll("}\n") catch return;
            stderr.flush() catch return;
        };
    }
};

pub fn main() !void {
    // Simulate HTTP request handling
    const ctx = LogContext{
        .correlation_id = "req-12345-abcde",
        .user_id = 42,
        .request_path = "/api/users/42",
    };

    ctx.logInfo("Request started", .{});
    ctx.logInfo("Querying database for user {d}", .{42});
    ctx.logInfo("Request completed in {d}ms", .{123});
}
```

**Output:**

```json
{"timestamp":1730860800123,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request started"}
{"timestamp":1730860800150,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Querying database for user 42"}
{"timestamp":1730860800273,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request completed in 123ms"}
```

This format is parseable by standard log aggregators and enables:
- Request tracing via correlation IDs
- User activity tracking
- Performance analysis (duration)
- Automated alerting on error rates

### Example 3: Performance-Conscious Logging

For high-throughput systems, sample frequent events to control log volume:

```zig
const std = @import("std");

const SampledLogger = struct {
    counter: std.atomic.Value(u64),
    sample_rate: u64,

    pub fn init(sample_rate: u64) SampledLogger {
        return .{
            .counter = std.atomic.Value(u64).init(0),
            .sample_rate = sample_rate,
        };
    }

    pub fn shouldLog(self: *SampledLogger) bool {
        const count = self.counter.fetchAdd(1, .monotonic);
        return count % self.sample_rate == 0;
    }

    pub fn logInfo(
        self: *SampledLogger,
        comptime format: []const u8,
        args: anytype,
    ) void {
        if (self.shouldLog()) {
            std.log.info(format, args);
        }
    }
};

pub fn main() !void {
    var sampled = SampledLogger.init(100); // Log 1/100 events

    // High-frequency loop
    var i: u64 = 0;
    while (i < 10000) : (i += 1) {
        // Only logs 100 times (1/100)
        sampled.logInfo("Processing item {d}", .{i});

        processItem(i);
    }
}

fn processItem(id: u64) void {
    // Process the item...
    _ = id;
}
```

This reduces log volume from 10,000 lines to 100 lines while maintaining visibility into system operation.

**Error Rate Tracking:**

Combine sampling with always-logged errors:

```zig
const ErrorRateTracker = struct {
    error_count: std.atomic.Value(u64),
    total_count: std.atomic.Value(u64),

    pub fn recordSuccess(self: *ErrorRateTracker) void {
        _ = self.total_count.fetchAdd(1, .monotonic);
    }

    pub fn recordError(self: *ErrorRateTracker, err: anyerror) void {
        _ = self.error_count.fetchAdd(1, .monotonic);
        _ = self.total_count.fetchAdd(1, .monotonic);

        // Always log errors (no sampling)
        std.log.err("Operation failed: {s}", .{@errorName(err)});
    }

    pub fn getErrorRate(self: *ErrorRateTracker) f64 {
        const errors = self.error_count.load(.monotonic);
        const total = self.total_count.load(.monotonic);
        if (total == 0) return 0.0;
        return @as(f64, @floatFromInt(errors)) / @as(f64, @floatFromInt(total));
    }
};
```

This ensures errors are always visible while sampling routine operations.

---

## Common Pitfalls

### Expensive Computation in Log Arguments

**Problem:** Log arguments are always evaluated, even if the log is filtered at runtime.

```zig
// ❌ Incorrect - expensiveFunction() always runs
log.debug("Result: {}", .{expensiveFunction()});
```

Even if debug logging is disabled at runtime, `expensiveFunction()` still executes.

**Solution:** Guard expensive operations with a runtime check:

```zig
// ✅ Correct - only compute if logging enabled
if (std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

For compile-time filtering (zero cost when disabled):

```zig
// ✅ Best - compile-time eliminated if debug disabled globally
if (comptime std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

### Logging Sensitive Information

**Problem:** Accidentally logging passwords, API tokens, or personally identifiable information.

```zig
// ❌ NEVER DO THIS
log.info("User login: user={s} password={s}", .{username, password});
log.debug("API request with token: {s}", .{api_token});
```

Logs often persist in log aggregation systems and may be accessed by operations teams.

**Solution:** Never log sensitive data:

```zig
// ✅ Correct - only log non-sensitive information
log.info("User login: user={s}", .{username});
log.debug("API request sent", .{});
```

For debugging, hash sensitive values:

```zig
// ✅ For debugging - hash sensitive data
const hash = std.crypto.hash.sha256.hash(password);
log.debug("Password hash: {x}", .{std.fmt.fmtSliceHexLower(&hash)});
```

### Non-Thread-Safe Custom Handlers

**Problem:** Custom log handlers without locking cause data races.

```zig
// ❌ Incorrect - NOT thread-safe
var log_buffer: [4096]u8 = undefined;
var log_len: usize = 0;

pub fn unsafeLogFn(...) void {
    // Multiple threads can corrupt log_buffer
    const msg = std.fmt.bufPrint(log_buffer[log_len..], ...) catch return;
    log_len += msg.len;
}
```

**Solution:** Always use locking:

```zig
// ✅ Correct - thread-safe with current API (0.15+)
pub fn safeLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // 🕐 **0.14.x:**
    // const stderr = std.io.getStdErr().writer();

    // ✅ **0.15+:**
    var stderr_buf: [1024]u8 = undefined;
    var stderr = std.fs.File.stderr().writer(&stderr_buf);

    stderr.interface.print("[{s}]({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope),
    } ++ args) catch return;
}
```

### High-Frequency Logging Without Sampling

**Problem:** Logging on every iteration creates excessive output.

```zig
// ❌ Incorrect - logs millions of times
for (items) |item| {
    log.debug("Processing {d}", .{item.id});
    processItem(item);
}
```

**Solution:** Use sampling or periodic logging:

```zig
// ✅ Correct - sample every 100th item
var sampler = SampledLogger.init(100);
for (items) |item| {
    sampler.logDebug("Processing {d}", .{item.id});
    processItem(item);
}

// ✅ Alternative - log summary
log.info("Processing {d} items", .{items.len});
for (items) |item| {
    processItem(item);
}
log.info("Completed processing {d} items", .{items.len});
```

### Invalid JSON in Structured Logs

**Problem:** Unescaped strings break JSON parsing.

```zig
// ❌ Incorrect - breaks if msg contains quotes
pub fn badJsonLog(msg: []const u8) void {
    stderr.print("{{\"message\":\"{s}\"}}\n", .{msg});
    // If msg = "He said \"hello\"", output is invalid JSON
}
```

**Solution:** Properly escape JSON strings:

```zig
// ✅ Correct - escape special characters
pub fn goodJsonLog(msg: []const u8) void {
    stderr.writeAll("{\"message\":\"") catch return;
    for (msg) |c| {
        switch (c) {
            '"' => stderr.writeAll("\\\"") catch return,
            '\\' => stderr.writeAll("\\\\") catch return,
            '\n' => stderr.writeAll("\\n") catch return,
            '\r' => stderr.writeAll("\\r") catch return,
            '\t' => stderr.writeAll("\\t") catch return,
            else => stderr.writeByte(c) catch return,
        }
    }
    stderr.writeAll("\"}\n") catch return;
}
```

### Blocking I/O in Log Handlers

**Problem:** Network I/O or synchronous file writes block the application.

```zig
// ❌ Incorrect - blocks on network I/O
pub fn slowLogFn(...) void {
    const socket = connectToLogServer() catch return; // Blocks!
    defer socket.close();
    socket.send(...) catch return;
}
```

**Solution:** Use buffering or asynchronous logging:

```zig
// ✅ Correct - buffer logs, ship asynchronously
const AsyncLogBuffer = struct {
    buffer: std.ArrayList(u8),
    mutex: std.Thread.Mutex,

    pub fn append(self: *AsyncLogBuffer, msg: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.buffer.appendSlice(msg);
    }

    // Called periodically by background thread
    pub fn flush(self: *AsyncLogBuffer) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.buffer.items.len == 0) return;

        const socket = try connectToLogServer();
        defer socket.close();
        try socket.writeAll(self.buffer.items);

        self.buffer.clearRetainingCapacity();
    }
};
```

---

## In Practice

Real-world Zig projects demonstrate diverse logging strategies adapted to their specific needs.

### TigerBeetle: Deterministic Event Logging

TigerBeetle, a distributed financial database, uses scoped logging extensively to organize output by subsystem[^3][^4]:

```zig
// One scoped logger per module
const log = std.log.scoped(.vsr);          // Viewstamped Replication
const log = std.log.scoped(.superblock);   // Storage metadata
const log = std.log.scoped(.journal);      // Write-ahead log
const log = std.log.scoped(.grid_scrubber); // Data verification
const log = std.log.scoped(.compaction);    // LSM compaction
```

TigerBeetle also implements a sophisticated trace system layered on top of std.log[^7]:

```zig
pub const Tracer = struct {
    time: Time,
    process_id: ProcessID,
    options: Options,

    pub const Options = struct {
        writer: ?std.io.AnyWriter = null,
        statsd_options: union(enum) {
            log,
            udp: struct {
                io: *IO,
                address: std.net.Address,
            },
        } = .log,
    };

    // Event tracking for deterministic replay...
};
```

This trace system provides:
- Structured event logging for deterministic replay
- StatsD metrics integration for monitoring
- Process ID tracking for distributed correlation
- Optional writer for trace output

**Key Insight:** TigerBeetle demonstrates layering application-specific tracing on top of std.log while maintaining the benefits of compile-time filtering and scoped organization.

### Ghostty: Platform-Aware Logging

Ghostty, a GPU-accelerated terminal emulator, integrates with platform-specific logging APIs[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (builtin.target.os.tag.isDarwin()) {
        // Use macOS Unified Logging
        const mac_level: macos.os.LogType = switch (level) {
            .debug => .debug,
            .info => .info,
            .warn => .err,
            .err => .fault,
        };

        const logger = macos.os.Log.create(build_config.bundle_id, @tagName(scope));
        defer logger.release();
        logger.log(std.heap.c_allocator, mac_level, format, args);
    }

    // Also output to stderr
    // ... stderr output code ...
}
```

This approach enables:
- Native platform integration (macOS Console.app)
- Cross-platform stderr fallback
- Consistent API regardless of platform

Ghostty configures log levels based on build mode[^15]:

```zig
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = logFn,
};
```

### Bun: Minimal Overhead for Performance

Bun, a JavaScript runtime, sets a high log threshold in release builds to minimize overhead[^8]:

```zig
pub const std_options = std.Options{
    .log_level = if (builtin.mode == .Debug) .debug else .warn,
};
```

By setting `.warn` in release mode, Bun filters out info and debug logs, relying on custom infrastructure for performance-critical logging.

**Pattern:** High-performance runtimes minimize std.log usage in hot paths, using it primarily for errors and warnings while implementing custom lightweight logging for frequent events.

### ZLS: Development Tool Diagnostics

The Zig Language Server uses scoped logging for different analysis components[^9]:

```zig
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};
```

ZLS routes logs to stderr, keeping them separate from LSP JSON-RPC communication on stdout. Scoped loggers organize diagnostic output:

- `.analysis` - Code analysis diagnostics
- `.diagnostics` - Compiler diagnostic generation
- `.completions` - Autocomplete debugging
- `.goto` - Go-to-definition tracing

This demonstrates logging in development tools where:
- Rich diagnostics help debug protocol issues
- Logs must not interfere with primary communication channel
- Filtering by component aids development

---

## Summary

Zig's logging system provides a pragmatic balance between developer observability and runtime performance through compile-time filtering and customizable output.

**Core Principles:**

1. **Compile-time optimization**: Filtered logs have zero runtime cost
2. **Scoped organization**: Categorize logs by subsystem for clarity
3. **Customizable handlers**: Adapt output format to deployment needs
4. **Thread safety**: Built-in synchronization for concurrent access
5. **Minimal dependencies**: No heap allocation in default implementation

**When to Use What:**

| Scenario | Tool | Reason |
|----------|------|--------|
| Temporary debugging | `std.debug.print` | Quick, no setup required |
| Permanent instrumentation | `std.log` | Filtering, scoping, consistent format |
| Error conditions | `log.err` | Always visible, indicates problems |
| State transitions | `log.info` | Important events, may sample in production |
| Internal diagnostics | `log.debug` | Development only, filtered in release |
| Invariant violations | `std.debug.assert` | Panic on violation (Debug/ReleaseSafe) |
| Stack inspection | `std.debug.dumpCurrentStackTrace` | Deep debugging, error diagnosis |

**Production Checklist:**

- [ ] Set appropriate log level (`.info` or `.warn`)
- [ ] Use scoped logging for subsystem organization
- [ ] Sample high-frequency events
- [ ] Always log errors (no sampling)
- [ ] Never log sensitive data (passwords, tokens, PII)
- [ ] Ensure thread-safe custom handlers
- [ ] Consider structured output (JSON) for aggregation
- [ ] Add correlation IDs for request tracing
- [ ] Test log volume under load
- [ ] Plan for log rotation and retention

**Development vs Production:**

**Development (Debug mode):**
- Log level: `.debug` (all logs enabled)
- Use `std.debug.print` for quick diagnostics
- Enable verbose logging for all subsystems
- Include detailed error context and stack traces

**Production (Release modes):**
- Log level: `.info` or `.warn` (filter debug logs)
- Sample high-frequency info logs
- Always capture errors with context
- Use structured output for automated analysis
- Monitor log volume and performance impact

**Key Takeaway:** Zig's logging system enables comprehensive instrumentation during development while maintaining production performance through compile-time elimination of unused logs. This design eliminates the traditional observability-performance trade-off, allowing developers to instrument freely without impacting production systems.

---

## References

[^1]: [Zig Language Reference 0.15.2: std.log](https://ziglang.org/documentation/0.15.2/std/#std.log) - Official documentation for the standard library logging module.

[^2]: [Zig Language Reference 0.15.2: std.Options](https://ziglang.org/documentation/0.15.2/std/#std.Options) - Documentation for std.Options structure including log configuration.

[^3]: [TigerBeetle Source: Scoped Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig#L5) - Example scoped logger: `const log = std.log.scoped(.vsr);`

[^4]: [TigerBeetle Source: Custom Log Handler](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/scripts.zig#L25-L34) - Custom log handler with timestamp support.

[^5]: [Ghostty Source: Platform-Aware Log Handler](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L121-L168) - macOS Unified Logging integration.

[^6]: [Zig std.debug Source](../../zig_versions/zig-0.15.2/lib/std/debug.zig) - Standard library debug utilities.

[^7]: [TigerBeetle Source: Trace System](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace.zig#L100) - Event tracing with StatsD integration.

[^8]: [Bun Source: Log Configuration](https://github.com/oven-sh/bun/blob/main/src/main.zig#L2) - Minimal std.log usage for performance.

[^9]: [ZLS Source: Log Configuration](https://github.com/zigtools/zls/blob/main/src/main.zig#L35) - Language server logging setup.

[^10]: [Zig std.log Source](../../zig_versions/zig-0.15.2/lib/std/log.zig) - Local Zig 0.15.2 stdlib logging implementation.

[^11]: [TigerBeetle: Superblock Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/superblock.zig#L39) - Superblock operations with `.superblock` scope.

[^12]: [TigerBeetle: Journal Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/journal.zig#L14) - Write-ahead log with `.journal` scope.

[^13]: [TigerBeetle: Compaction Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/compaction.zig#L38) - LSM compaction with `.compaction` scope.

[^14]: [TigerBeetle: IO Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L9) - Platform-specific I/O with `.io` scope.

[^15]: [Ghostty: Log Level Configuration](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L170-L178) - Build-mode dependent log levels.
