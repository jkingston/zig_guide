# Research Notes: Chapter 13 - Logging, Diagnostics & Observability

## Document Information
- **Chapter**: 13 - Logging, Diagnostics & Observability
- **Research Date**: 2025-11-05
- **Zig Versions**: 0.14.0, 0.14.1, 0.15.1, 0.15.2
- **Status**: Complete

---

## Table of Contents
1. [std.log Architecture and Design](#1-stdlog-architecture-and-design)
2. [Log Levels and Hierarchy](#2-log-levels-and-hierarchy)
3. [Scoped Logging Patterns](#3-scoped-logging-patterns)
4. [Custom Log Handlers](#4-custom-log-handlers)
5. [std.debug Diagnostic Utilities](#5-stddebug-diagnostic-utilities)
6. [Production Logging Patterns](#6-production-logging-patterns)
7. [Reference Project Analysis](#7-reference-project-analysis)
8. [Structured Logging Approaches](#8-structured-logging-approaches)
9. [Common Pitfalls and Solutions](#9-common-pitfalls-and-solutions)
10. [Best Practices Summary](#10-best-practices-summary)

---

## 1. std.log Architecture and Design

### 1.1 Core Design Philosophy

The Zig standard library's logging system (`std.log`) is designed with compile-time optimization as a primary goal. Unlike runtime logging frameworks in other languages, Zig's logging has zero cost when disabled at compile time[^1].

**Key Design Principles:**
- **Compile-time filtering**: Log calls are completely removed from the binary when filtered out
- **Scope-based organization**: Logs can be categorized by scope (subsystem)
- **Customizable output**: Log handlers can be overridden via `std.options.logFn`
- **Thread-safe by default**: Built-in locking for concurrent log output
- **Minimal dependencies**: No heap allocations in default implementation

### 1.2 Source Code Analysis

From `zig_versions/zig-0.15.2/lib/std/log.zig`:

```zig
//! std.log is a standardized interface for logging which allows for the logging
//! of programs and libraries using this interface to be formatted and filtered
//! by the implementer of the `std.options.logFn` function.
```

The logging system consists of:

1. **Level enum** (lines 78-99):
```zig
pub const Level = enum {
    /// Error: something has gone wrong
    err,
    /// Warning: uncertain if something has gone wrong
    warn,
    /// Info: general messages about the state of the program
    info,
    /// Debug: messages only useful for debugging
    debug,

    pub fn asText(comptime self: Level) []const u8 {
        return switch (self) {
            .err => "error",
            .warn => "warning",
            .info => "info",
            .debug => "debug",
        };
    }
};
```

2. **Default log level** based on build mode (lines 102-105):
```zig
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
};
```

3. **Compile-time filtering** (lines 116-125):
```zig
fn log(
    comptime message_level: Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime !logEnabled(message_level, scope)) return;

    std.options.logFn(message_level, scope, format, args);
}
```

The key insight: The `if (comptime !logEnabled(...))` ensures that filtered logs are **completely removed** at compile time—they have zero runtime cost[^1].

### 1.3 Performance Characteristics

**Zero-Cost Abstractions:**
- Filtered logs: **0 bytes**, **0 cycles** (removed at compile time)
- Enabled logs: Only the cost of the log handler function
- Default handler: ~64 byte stack buffer, no heap allocations

**Thread Safety:**
- Uses `std.debug.lockStdErr()` / `unlockStdErr()` for serialized access
- Mutex-protected stderr output
- Safe for concurrent logging from multiple threads

### 1.4 Configuration via std.options

Logging behavior is configured through `std.Options`:

```zig
pub const std_options: std.Options = .{
    // Set the log level (default is based on build mode)
    .log_level = .info,

    // Set per-scope log levels
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .network, .level = .debug },
        .{ .scope = .database, .level = .warn },
    },

    // Custom log handler function
    .logFn = customLogFn,
};
```

**Configuration Options:**[^2]
- `log_level`: Global minimum log level
- `log_scope_levels`: Per-scope log level overrides
- `logFn`: Custom log handler function

---

## 2. Log Levels and Hierarchy

### 2.1 Level Hierarchy

Zig defines four log levels in order of severity:

| Level | Integer Value | When to Use | Production? |
|-------|--------------|-------------|-------------|
| `err` | 0 | Errors requiring attention | ✅ Always |
| `warn` | 1 | Potential issues worth investigating | ✅ Yes |
| `info` | 2 | Important state changes and events | ⚠️  Sampled |
| `debug` | 3 | Detailed diagnostic information | ❌ Dev only |

### 2.2 Level Selection Guidelines

**err - Errors:**
```zig
log.err("Database connection failed: {s}", .{@errorName(err)});
log.err("Fatal: corrupted superblock checksum", .{});
```

Use for:
- Unrecoverable errors
- Resource failures (connection, file I/O)
- Data corruption detected
- Security violations

**warn - Warnings:**
```zig
log.warn("Connection pool at 90% capacity", .{});
log.warn("Deprecated API used: {s}", .{api_name});
```

Use for:
- Approaching resource limits
- Deprecated functionality usage
- Recoverable errors
- Configuration issues

**info - Informational:**
```zig
log.info("Server started on port {d}", .{port});
log.info("Request completed in {d}ms", .{duration});
```

Use for:
- Application lifecycle events (start, stop)
- Significant state changes
- Request/transaction completion
- Performance milestones

**debug - Debugging:**
```zig
log.debug("Cache hit for key: {s}", .{key});
log.debug("Parsed config: {any}", .{config});
```

Use for:
- Internal state inspection
- Algorithm trace information
- Cache behavior
- Development-time diagnostics

### 2.3 Compile-Time Filtering

Log level filtering happens at compile time, removing unused logs from the binary:

```zig
// logEnabled determines if a log should be compiled
pub fn logEnabled(comptime message_level: Level, comptime scope: @TypeOf(.enum_literal)) bool {
    // Check scope-specific levels first
    inline for (scope_levels) |scope_level| {
        if (scope_level.scope == scope)
            return @intFromEnum(message_level) <= @intFromEnum(scope_level.level);
    }
    // Fall back to global level
    return @intFromEnum(message_level) <= @intFromEnum(level);
}
```

Example: With `.log_level = .warn`, all `info` and `debug` logs are **removed from the binary**[^1].

---

## 3. Scoped Logging Patterns

### 3.1 Creating Scoped Loggers

Scopes provide namespacing for log messages, allowing categorization by subsystem:

```zig
const log = std.log.scoped(.database);
const net_log = std.log.scoped(.network);
const auth_log = std.log.scoped(.auth);
```

The `scoped()` function returns a new type with the same logging interface:

```zig
// From std/log.zig lines 159-202
pub fn scoped(comptime scope: @TypeOf(.enum_literal)) type {
    return struct {
        pub fn err(comptime format: []const u8, args: anytype) void {
            @branchHint(.cold);  // Hint that errors are unlikely
            log(.err, scope, format, args);
        }

        pub fn warn(comptime format: []const u8, args: anytype) void {
            log(.warn, scope, format, args);
        }

        pub fn info(comptime format: []const u8, args: anytype) void {
            log(.info, scope, format, args);
        }

        pub fn debug(comptime format: []const u8, args: anytype) void {
            log(.debug, scope, format, args);
        }
    };
}
```

### 3.2 Scope Naming Conventions

Based on analysis of production codebases, scope names should be:

**Characteristics:**
- Lowercase identifiers
- Represent subsystems or modules
- Concise (1-2 words)
- Descriptive of functionality

**Common Patterns:**
- Module-based: `.database`, `.network`, `.cache`
- Feature-based: `.auth`, `.sync`, `.compaction`
- Layer-based: `.io`, `.storage`, `.replication`

### 3.3 Real-World Usage from TigerBeetle

TigerBeetle uses extensive scoped logging throughout the codebase[^3]:

```zig
// reference_repos/tigerbeetle/src/vsr.zig:5
const log = std.log.scoped(.vsr);

// reference_repos/tigerbeetle/src/vsr/superblock.zig:39
const log = std.log.scoped(.superblock);

// reference_repos/tigerbeetle/src/vsr/journal.zig:14
const log = std.log.scoped(.journal);

// reference_repos/tigerbeetle/src/vsr/grid_scrubber.zig:27
const log = std.log.scoped(.grid_scrubber);

// reference_repos/tigerbeetle/src/io/linux.zig:9
const log = std.log.scoped(.io);

// reference_repos/tigerbeetle/src/trace.zig:100
const log = std.log.scoped(.trace);

// reference_repos/tigerbeetle/src/lsm/compaction.zig:38
const log = std.log.scoped(.compaction);
```

**Key Observation:** TigerBeetle uses one scoped logger per module, with scope names matching the module's primary responsibility.

### 3.4 Per-Scope Log Level Configuration

You can set different log levels for different scopes:

```zig
pub const std_options: std.Options = .{
    .log_level = .info,  // Global default
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .network, .level = .debug },  // Verbose network logs
        .{ .scope = .cache, .level = .warn },     // Only cache warnings
    },
};
```

This allows fine-grained control: debug a specific subsystem while keeping others quiet.

---

## 4. Custom Log Handlers

### 4.1 Handler Function Signature

Custom log handlers must match this signature:

```zig
pub fn customLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Handler implementation
}
```

**Parameters:**
- `level`: Log level (comptime known)
- `scope`: Log scope (comptime known)
- `format`: Format string (comptime known)
- `args`: Runtime arguments tuple

**Requirements:**
- Must be thread-safe (use locking if needed)
- Should handle errors gracefully (don't panic)
- Should not block indefinitely

### 4.2 Default Log Handler

The default implementation from `std/log.zig` (lines 145-157):

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
- 64-byte stack buffer (no heap allocation)
- Thread-safe via `lockStderrWriter`
- Silently ignores write errors
- Outputs to stderr

**Output Format:**
```
error: Database connection failed
warning(network): High latency detected
info(main): Application started
debug(cache): Hit for key "user:123"
```

### 4.3 Production Examples

**TigerBeetle's Timestamped Logger:**

From `reference_repos/tigerbeetle/src/scripts.zig`[^4]:

```zig
fn log_fn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime !std.log.logEnabled(message_level, scope)) return;
    stdx.log_with_timestamp(message_level, scope, format, args);
}

pub const std_options: std.Options = .{ .logFn = log_fn };
```

**Ghostty's Platform-Aware Logger:**

From `reference_repos/ghostty/src/main_ghostty.zig`[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime level.asText();
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // On Mac, use unified logging system
    if (builtin.target.os.tag.isDarwin()) {
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
    switch (state.logging) {
        .disabled => {},
        .stderr => {
            var buffer: [1024]u8 = undefined;
            var stderr = std.fs.File.stderr().writer(&buffer);
            const writer = &stderr.interface;
            nosuspend writer.print(level_txt ++ prefix ++ format ++ "\n", args) catch return;
            writer.flush() catch {};
        },
    }
}
```

**Key Insights:**
- Ghostty integrates with macOS Unified Logging
- Uses larger buffer (1024 bytes) for complex logs
- Provides runtime control (disabled vs stderr)
- Handles platform-specific logging APIs

### 4.4 JSON Log Handler Pattern

For machine-readable structured logs:

```zig
pub fn jsonLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const stderr = std.io.getStdErr().writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Format the message
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

        // Escape the message for JSON
        for (message) |c| {
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
    };
}
```

Output:
```json
{"timestamp":1730860800,"level":"info","scope":"default","message":"Application started"}
{"timestamp":1730860801,"level":"error","scope":"database","message":"Connection failed"}
```

---

## 5. std.debug Diagnostic Utilities

### 5.1 Core Diagnostic Functions

From `zig_versions/zig-0.15.2/lib/std/debug.zig`:

**Thread-Safe Stderr Access:**

```zig
/// Allows the caller to freely write to stderr until `unlockStdErr` is called.
pub fn lockStdErr() void {
    std.Progress.lockStdErr();
}

pub fn unlockStdErr() void {
    std.Progress.unlockStdErr();
}

/// Returns a Writer with empty buffer (unbuffered)
pub fn lockStderrWriter(buffer: []u8) *Writer {
    return std.Progress.lockStderrWriter(buffer);
}
```

**Quick Debug Printing:**

```zig
/// Print to stderr, silently returning on failure.
/// Intended for use in "printf debugging". Use `std.log` for proper logging.
pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buffer: [64]u8 = undefined;
    const bw = lockStderrWriter(&buffer);
    defer unlockStderrWriter();
    nosuspend bw.print(fmt, args) catch return;
}
```

**Usage Note:** `std.debug.print` is for temporary debugging, not production logging. Use `std.log` for structured logging[^6].

### 5.2 Stack Trace Functionality

```zig
/// Tries to print the current stack trace to stderr, unbuffered
pub fn dumpCurrentStackTrace(start_addr: ?usize) void {
    const stderr = lockStderrWriter(&.{});
    defer unlockStderrWriter();
    nosuspend dumpCurrentStackTraceToWriter(start_addr, stderr) catch return;
}

/// Prints the current stack trace to the provided writer
pub fn dumpCurrentStackTraceToWriter(start_addr: ?usize, writer: *Writer) !void {
    if (builtin.target.cpu.arch.isWasm()) {
        if (native_os == .wasi) {
            try writer.writeAll("Unable to dump stack trace: not implemented for Wasm\n");
        }
        return;
    }
    if (builtin.strip_debug_info) {
        try writer.writeAll("Unable to dump stack trace: debug info stripped\n");
        return;
    }

    const debug_info = getSelfDebugInfo() catch |err| {
        try writer.print("Unable to dump stack trace: Unable to open debug info: {s}\n", .{@errorName(err)});
        return;
    };

    writeCurrentStackTrace(writer, debug_info, io.tty.detectConfig(.stderr()), start_addr) catch |err| {
        try writer.print("Unable to dump stack trace: {s}\n", .{@errorName(err)});
        return;
    };
}
```

**Limitations:**
- Requires debug symbols (doesn't work with stripped binaries)
- Not available on all architectures (WASM, BPF, some MIPS)
- Performance overhead in debug builds

### 5.3 Hex Dump Utility

```zig
/// Prints a hexadecimal view of the bytes
pub fn dumpHex(bytes: []const u8) void {
    const bw = lockStderrWriter(&.{});
    defer unlockStderrWriter();
    const ttyconf = std.io.tty.detectConfig(.stderr());
    dumpHexFallible(bw, ttyconf, bytes) catch {};
}
```

Output format (from test at line 305):
```
7ffc12345678  00 11 22 33 44 55 66 77  88 99 AA BB CC DD EE FF  .."3DUfw........
7ffc12345688  01 12 13                                          ...
```

Useful for:
- Debugging binary protocols
- Inspecting corrupted data
- Understanding memory layout

### 5.4 Assertion Mechanisms

While `std.debug` provides assertions, they're separate from logging:

```zig
const assert = std.debug.assert;

// Only active in Debug and ReleaseSafe modes
assert(value > 0);  // Panics if false

// Alternative: Manual check with log
if (value <= 0) {
    log.err("Invalid value: {d}", .{value});
    return error.InvalidValue;
}
```

**Best Practice:** Use assertions for invariants, logging for observable events.

---

## 6. Production Logging Patterns

### 6.1 Performance Considerations

**Zero-Cost Filtering:**

```zig
// In ReleaseFast with .log_level = .warn:
log.debug("Expensive: {}", .{computeExpensiveData()});
// ^ This entire line is REMOVED from the binary

// BUT this is NOT optimized away:
log.info("Data: {}", .{computeExpensiveData()});
// ^ computeExpensiveData() still runs even if info is filtered!
```

**Guard Expensive Operations:**

```zig
// ❌ Incorrect - computation happens regardless
log.debug("Expensive result: {}", .{expensiveFunction()});

// ✅ Correct - guard with runtime check
if (std.log.defaultLogEnabled(.debug)) {
    log.debug("Expensive result: {}", .{expensiveFunction()});
}

// ✅ Better - for critical paths, check comptime
if (comptime std.log.defaultLogEnabled(.debug)) {
    log.debug("Expensive result: {}", .{expensiveFunction()});
}
```

### 6.2 Sampling Patterns

For high-frequency events, use sampling to reduce log volume:

```zig
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

// Usage:
var sampled = SampledLogger.init(100); // Log 1/100 events

for (items) |item| {
    sampled.logInfo("Processing item {d}", .{item.id});
    processItem(item);
}
```

### 6.3 Error Rate Tracking

Combine logging with metrics:

```zig
const ErrorRateTracker = struct {
    error_count: std.atomic.Value(u64),
    total_count: std.atomic.Value(u64),

    pub fn init() ErrorRateTracker {
        return .{
            .error_count = std.atomic.Value(u64).init(0),
            .total_count = std.atomic.Value(u64).init(0),
        };
    }

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

### 6.4 TigerBeetle's Trace System

TigerBeetle implements a sophisticated tracing system on top of std.log[^7]:

From `reference_repos/tigerbeetle/src/trace.zig`:

```zig
const log = std.log.scoped(.trace);

pub const Tracer = struct {
    time: Time,
    process_id: ProcessID,
    options: Options,
    buffer: []u8,
    statsd: StatsD,

    events_started: [EventTracing.stack_count]?stdx.Instant = @splat(null),
    events_metric: []?EventMetricAggregate,
    events_timing: []?EventTimingAggregate,

    pub const Options = struct {
        writer: ?std.io.AnyWriter = null,
        statsd_options: union(enum) {
            log,
            udp: struct {
                io: *IO,
                address: std.net.Address,
            },
        } = .log,
        log_trace: bool = true,
    };

    // ... event tracking implementation
};
```

**Key Features:**
- Structured event logging
- StatsD metrics integration
- Optional writer for trace output
- Timing and metric aggregation
- Process ID tracking for distributed context

This shows how std.log can be layered with application-specific tracing infrastructure.

---

## 7. Reference Project Analysis

### 7.1 TigerBeetle: Deterministic Event Logging

**Project:** [TigerBeetle](https://github.com/tigerbeetle/tigerbeetle) - Distributed financial transaction database
**Focus:** Correctness-critical logging for deterministic replay

**Scoped Logging Usage:**

TigerBeetle uses scoped loggers extensively for different subsystems[^3]:

| Scope | Module | Purpose |
|-------|--------|---------|
| `.vsr` | `src/vsr.zig` | Viewstamped Replication protocol |
| `.superblock` | `src/vsr/superblock.zig` | Superblock operations |
| `.journal` | `src/vsr/journal.zig` | Write-ahead logging |
| `.grid_scrubber` | `src/vsr/grid_scrubber.zig` | Storage verification |
| `.io` | `src/io/*.zig` | I/O subsystem (platform-specific) |
| `.trace` | `src/trace.zig` | Tracing infrastructure |
| `.compaction` | `src/lsm/compaction.zig` | LSM compaction |
| `.forest` | `src/lsm/forest.zig` | LSM forest |
| `.manifest_log` | `src/lsm/manifest_log.zig` | Manifest logging |
| `.message_bus` | `src/message_bus.zig` | Message routing |
| `.statsd` | `src/trace/statsd.zig` | StatsD integration |

**Pattern:**
- One scoped logger per module
- Scope names match functional responsibility
- Consistent across entire codebase
- Enables filtering by subsystem

**Custom Log Handler with Timestamps:**

From `reference_repos/tigerbeetle/src/scripts.zig:25-34`[^4]:

```zig
fn log_fn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime !std.log.logEnabled(message_level, scope)) return;
    stdx.log_with_timestamp(message_level, scope, format, args);
}

pub const std_options: std.Options = .{ .logFn = log_fn };
```

The `stdx.log_with_timestamp` function adds timestamps to every log entry, critical for debugging distributed systems where event ordering matters.

**Trace System Architecture:**

TigerBeetle layers a sophisticated event tracing system on top of std.log[^7]:

```zig
// Event types for structured logging
pub const Event = enum {
    message_bus_batch_enqueue,
    message_bus_batch_dequeue,
    replica_checkpoint,
    replica_commit,
    replica_compact,
    grid_read,
    grid_write,
    // ... many more
};

pub const EventTiming = struct {
    event: Event,
    timestamp_start: u64,
    timestamp_end: u64,
};

pub const EventMetric = struct {
    event: Event,
    value: u64,
};
```

This provides:
- Deterministic event replay
- Performance profiling
- Distributed tracing
- StatsD metrics integration

### 7.2 Ghostty: Platform-Aware Application Logging

**Project:** [Ghostty](https://github.com/ghostty-org/ghostty) - GPU-accelerated terminal emulator
**Focus:** User-facing diagnostics with platform integration

**Custom Log Handler:**

From `reference_repos/ghostty/src/main_ghostty.zig:121-168`[^5]:

```zig
fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime level.asText();
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Mac-specific: Use unified logging system
    if (builtin.target.os.tag.isDarwin()) {
        const mac_level: macos.os.LogType = switch (level) {
            .debug => .debug,
            .info => .info,
            .warn => .err,      // Map warn to err level
            .err => .fault,      // Map err to fault level
        };

        const logger = macos.os.Log.create(build_config.bundle_id, @tagName(scope));
        defer logger.release();
        logger.log(std.heap.c_allocator, mac_level, format, args);
    }

    // Also output to stderr (configurable)
    switch (state.logging) {
        .disabled => {},
        .stderr => {
            var buffer: [1024]u8 = undefined;
            var stderr = std.fs.File.stderr().writer(&buffer);
            const writer = &stderr.interface;
            nosuspend writer.print(level_txt ++ prefix ++ format ++ "\n", args) catch return;
            writer.flush() catch {};
        },
    }
}

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = logFn,
};
```

**Key Features:**
- **Platform Integration:** Uses macOS Unified Logging when available
  - Viewable with: `sudo log stream --level debug --predicate 'subsystem=="com.mitchellh.ghostty"'`
- **Runtime Control:** Can disable logging or route to stderr
- **Larger Buffer:** 1024 bytes for potentially complex terminal-related logs
- **Level Mapping:** Maps Zig levels to platform-specific levels

**Scoped Logging Examples:**

Found in Ghostty source:
- `.termio` - Terminal I/O operations
- `.terminal` - Terminal emulation
- `.unicode` - Unicode handling
- `.renderer` - Rendering subsystem
- `.font` - Font management

### 7.3 Bun: High-Performance Runtime Logging

**Project:** [Bun](https://github.com/oven-sh/bun) - JavaScript runtime
**Focus:** Minimal overhead for high-performance runtime

**Configuration:**

From `reference_repos/bun/src/main.zig:2`[^8]:

```zig
pub const std_options = std.Options{
    .log_level = if (builtin.mode == .Debug) .debug else .warn,
    // Bun has its own logging infrastructure in most cases
};
```

**Observation:** Bun sets a high threshold (`.warn`) in release mode, relying on custom logging infrastructure for most output. This minimizes std.log overhead in the hot path.

**Pattern:** For performance-critical runtimes:
- Use std.log for errors/warnings only
- Implement custom lightweight logging for frequent events
- Avoid logging in performance-critical code paths

### 7.4 ZLS: Language Server Diagnostics

**Project:** [ZLS](https://github.com/zigtools/zls) - Zig Language Server
**Focus:** Rich diagnostic output for development tools

**Configuration:**

From `reference_repos/zls/src/main.zig:35`[^9]:

```zig
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    // Uses default log handler
};
```

**Scoped Logging in ZLS:**

ZLS uses scoped logging for different analysis components:
- `.analysis` - Code analysis
- `.diagnostics` - Diagnostic generation
- `.completions` - Autocomplete
- `.goto` - Go-to-definition
- `.inlay_hints` - Inlay hint generation

**Use Case:** Language servers benefit from detailed logging to diagnose protocol issues, but need to avoid polluting LSP JSON-RPC communication. ZLS routes logs to stderr, separate from stdout LSP communication.

### 7.5 Comparative Analysis

| Project | Log Level (Release) | Custom Handler | Scoped Logging | Special Features |
|---------|---------------------|----------------|----------------|------------------|
| **TigerBeetle** | `.info` | ✅ (Timestamps) | ✅ Extensive | Trace system, StatsD |
| **Ghostty** | `.info` | ✅ (Platform-aware) | ✅ Moderate | macOS integration |
| **Bun** | `.warn` | ❌ Default | ❌ Minimal | Custom infra for perf |
| **ZLS** | `.info` | ❌ Default | ✅ Moderate | Protocol isolation |

**Insights:**
- **Correctness-critical systems** (TigerBeetle): Extensive logging with structured events
- **User-facing apps** (Ghostty): Platform integration, runtime control
- **Performance-critical** (Bun): Minimal std.log usage, custom infrastructure
- **Development tools** (ZLS): Detailed diagnostics, protocol separation

---

## 8. Structured Logging Approaches

### 8.1 Contextual Logging Pattern

For request tracing and correlation:

```zig
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
        const stderr = std.io.getStdErr().writer();
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();

        nosuspend {
            // JSON structured output
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
            stderr.print(format, args) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll("}\n") catch return;
        };
    }
};

// Usage:
const ctx = LogContext{
    .correlation_id = "req-12345-abcde",
    .user_id = 42,
    .request_path = "/api/users/42",
};

ctx.logInfo("Request started", .{});
ctx.logInfo("Querying database", .{});
ctx.logInfo("Request completed in {d}ms", .{duration});
```

Output:
```json
{"timestamp":1730860800123,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request started"}
{"timestamp":1730860800150,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Querying database"}
{"timestamp":1730860800245,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request completed in 123ms"}
```

### 8.2 Distributed Tracing Context

For tracing across service boundaries:

```zig
pub const TraceContext = struct {
    trace_id: [16]u8,  // 128-bit trace ID
    span_id: [8]u8,    // 64-bit span ID
    parent_span_id: ?[8]u8 = null,

    pub fn generate() TraceContext {
        var trace_id: [16]u8 = undefined;
        var span_id: [8]u8 = undefined;
        std.crypto.random.bytes(&trace_id);
        std.crypto.random.bytes(&span_id);
        return .{
            .trace_id = trace_id,
            .span_id = span_id,
        };
    }

    pub fn hexTraceId(self: TraceContext) [32]u8 {
        var buf: [32]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "{s}", .{
            std.fmt.fmtSliceHexLower(&self.trace_id)
        }) catch unreachable;
        return buf;
    }

    pub fn hexSpanId(self: TraceContext) [16]u8 {
        var buf: [16]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "{s}", .{
            std.fmt.fmtSliceHexLower(&self.span_id)
        }) catch unreachable;
        return buf;
    }
};

// Usage:
const trace_ctx = TraceContext.generate();
const trace_id_hex = trace_ctx.hexTraceId();

std.log.info("Starting operation trace_id={s}", .{trace_id_hex});
// ... operation ...
std.log.info("Operation complete trace_id={s}", .{trace_id_hex});
```

This enables correlation across distributed services by propagating trace IDs.

### 8.3 OpenTelemetry-Compatible Format

For integration with observability platforms:

```zig
pub fn otelLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const stderr = std.io.getStdErr().writer();
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    var buf: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

    // OpenTelemetry Log Record format
    nosuspend {
        stderr.writeAll("{") catch return;

        // Timestamp in nanoseconds
        stderr.writeAll("\"timestamp\":") catch return;
        stderr.print("{d}", .{std.time.nanoTimestamp()}) catch return;

        // Severity
        stderr.writeAll(",\"severity_text\":\"") catch return;
        stderr.writeAll(level.asText()) catch return;
        stderr.writeAll("\"") catch return;

        stderr.writeAll(",\"severity_number\":") catch return;
        const severity_number: u8 = switch (level) {
            .debug => 5,  // DEBUG
            .info => 9,   // INFO
            .warn => 13,  // WARN
            .err => 17,   // ERROR
        };
        stderr.print("{d}", .{severity_number}) catch return;

        // Body (message)
        stderr.writeAll(",\"body\":\"") catch return;
        stderr.writeAll(message) catch return;
        stderr.writeAll("\"") catch return;

        // Resource attributes
        stderr.writeAll(",\"resource\":{\"service.name\":\"zig-service\"}") catch return;

        // Scope attributes
        stderr.writeAll(",\"scope\":{\"name\":\"") catch return;
        stderr.writeAll(@tagName(scope)) catch return;
        stderr.writeAll("\"}") catch return;

        stderr.writeAll("}\n") catch return;
    };
}
```

Output:
```json
{"timestamp":1730860800000000000,"severity_text":"info","severity_number":9,"body":"Application started","resource":{"service.name":"zig-service"},"scope":{"name":"default"}}
```

This format is compatible with OpenTelemetry collectors and can be ingested by Jaeger, Grafana, DataDog, etc.

---

## 9. Common Pitfalls and Solutions

### 9.1 Expensive Computation in Log Arguments

**Problem:** Log arguments are always evaluated, even if the log is filtered out at runtime.

```zig
// ❌ Incorrect - expensiveFunction() always runs
log.debug("Result: {}", .{expensiveFunction()});
```

**Solution 1:** Guard with runtime check

```zig
// ✅ Correct - only compute if logging
if (std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

**Solution 2:** Use comptime check (zero cost if filtered at compile time)

```zig
// ✅ Better - compile-time eliminated if debug disabled
if (comptime std.log.defaultLogEnabled(.debug)) {
    log.debug("Result: {}", .{expensiveFunction()});
}
```

### 9.2 Logging Sensitive Information

**Problem:** Accidentally logging passwords, tokens, or PII.

```zig
// ❌ NEVER DO THIS
log.info("User login: user={s} password={s}", .{username, password});
log.info("API request: token={s}", .{api_token});
```

**Solution:** Never log sensitive data; redact or hash if necessary

```zig
// ✅ Correct - only log non-sensitive information
log.info("User login: user={s}", .{username});

// ✅ For debugging, hash sensitive data
const hashed = std.crypto.hash.sha256.hash(password);
log.debug("Password hash: {x}", .{std.fmt.fmtSliceHexLower(&hashed)});
```

### 9.3 Non-Thread-Safe Custom Handlers

**Problem:** Custom log handlers without proper locking cause data races.

```zig
// ❌ Incorrect - not thread-safe
var log_buffer: [4096]u8 = undefined;
var log_len: usize = 0;

pub fn unsafeLogFn(...) void {
    // Multiple threads can corrupt log_buffer and log_len
    const msg = std.fmt.bufPrint(log_buffer[log_len..], ...) catch return;
    log_len += msg.len;
}
```

**Solution:** Always use locking

```zig
// ✅ Correct - thread-safe with locking
pub fn safeLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    stderr.print("[{s}] ({s}): " ++ format ++ "\n", .{
        level.asText(), @tagName(scope)
    } ++ args) catch return;
}
```

### 9.4 High-Frequency Logging Without Sampling

**Problem:** Logging on every iteration of a hot loop creates excessive output.

```zig
// ❌ Incorrect - logs millions of times
for (items) |item| {
    log.debug("Processing {d}", .{item.id});
    processItem(item);
}
```

**Solution:** Use sampling or periodic logging

```zig
// ✅ Correct - sample every 100th item
var sampler = SampledLogger.init(100);
for (items) |item| {
    sampler.logDebug("Processing {d}", .{item.id});
    processItem(item);
}

// ✅ Alternative - log periodically
log.info("Processing {} items", .{items.len});
for (items) |item| {
    processItem(item);
}
log.info("Completed processing", .{});
```

### 9.5 Invalid JSON in Structured Logs

**Problem:** Unescaped strings break JSON parsing.

```zig
// ❌ Incorrect - breaks if msg contains quotes
pub fn badJsonLog(msg: []const u8) void {
    stderr.print("{{\"message\":\"{s}\"}}\n", .{msg});
    // If msg = "He said \"hello\"", output is invalid JSON
}
```

**Solution:** Properly escape JSON strings

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
            else => if (c >= 32 and c <= 126) {
                stderr.writeByte(c) catch return;
            } else {
                stderr.print("\\u{x:0>4}", .{c}) catch return;
            },
        }
    }
    stderr.writeAll("\"}\n") catch return;
}
```

### 9.6 Blocking I/O in Log Handlers

**Problem:** Network I/O or file writes block the entire application.

```zig
// ❌ Incorrect - blocks on network I/O
pub fn slowLogFn(...) void {
    const socket = connectToLogServer() catch return; // Blocks!
    defer socket.close();
    socket.send(...) catch return; // Also blocks!
}
```

**Solution:** Use buffering or async logging

```zig
// ✅ Correct - buffer logs and ship asynchronously
const AsyncLogBuffer = struct {
    buffer: std.ArrayList(u8),
    mutex: std.Thread.Mutex,

    pub fn append(self: *AsyncLogBuffer, msg: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.buffer.appendSlice(msg);
    }

    pub fn flush(self: *AsyncLogBuffer) !void {
        // Called periodically by background thread
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.buffer.items.len == 0) return;

        // Ship logs to remote server
        const socket = try connectToLogServer();
        defer socket.close();
        try socket.writeAll(self.buffer.items);

        self.buffer.clearRetainingCapacity();
    }
};
```

### 9.7 Missing Context in Structured Logs

**Problem:** Logs lack sufficient context for debugging.

```zig
// ❌ Incorrect - minimal context
log.err("Operation failed", .{});
```

**Solution:** Include rich context

```zig
// ✅ Correct - rich context for debugging
const ctx = LogContext{
    .correlation_id = request.id,
    .user_id = request.user,
    .operation = "update_profile",
    .duration_ms = timer.read() / std.time.ns_per_ms,
};
ctx.logError("Operation failed: {s}", .{@errorName(err)});
```

### 9.8 Non-Deterministic Test Output

**Problem:** Timestamps or random values in logs make tests flaky.

```zig
// ❌ Incorrect - timestamp makes tests non-deterministic
test "operation logging" {
    const output = captureLogOutput();
    try testing.expectEqualStrings(
        "[2025-01-15 10:23:45] Operation started",
        output
    );
}
```

**Solution:** Test log content without volatile data

```zig
// ✅ Correct - test message content only
test "operation logging" {
    const output = captureLogOutput();
    try testing.expect(std.mem.indexOf(u8, output, "Operation started") != null);
}

// ✅ Or mock time for deterministic tests
test "operation logging with mock time" {
    var mock_time: u64 = 1730860800;
    const output = captureLogOutputWithTime(&mock_time);
    try testing.expectEqualStrings(
        "[1730860800] Operation started",
        output
    );
}
```

---

## 10. Best Practices Summary

### 10.1 Development vs Production

**Development (Debug mode):**
- Log level: `.debug`
- Extensive logging for all subsystems
- Detailed stack traces on errors
- Verbose diagnostic output
- Quick iteration with `std.debug.print`

**Production (Release modes):**
- Log level: `.info` or `.warn`
- Sample high-frequency logs
- Critical errors always logged
- Structured output for aggregation
- Performance-conscious logging

### 10.2 Scope Naming Guidelines

1. **One scope per module:** Match scope to module responsibility
2. **Lowercase identifiers:** `.database`, not `.Database`
3. **Concise names:** 1-2 words maximum
4. **Avoid abbreviations:** `.network` not `.net` (unless conventional)
5. **Functional names:** Describe what the module does

### 10.3 Log Level Selection

**Use `err` when:**
- Operation cannot continue
- Data corruption detected
- Resource exhaustion
- Security violations

**Use `warn` when:**
- Approaching resource limits
- Unexpected but handleable conditions
- Deprecated functionality used
- Configuration issues

**Use `info` when:**
- Application lifecycle events
- Significant state changes
- Request completion (sampled in production)
- Periodic health checks

**Use `debug` when:**
- Internal state inspection
- Cache behavior
- Algorithm tracing
- Development-only diagnostics

### 10.4 Performance Guidelines

1. **Guard expensive operations:**
   ```zig
   if (comptime std.log.defaultLogEnabled(.debug)) {
       log.debug("Result: {}", .{expensiveOp()});
   }
   ```

2. **Sample high-frequency logs:**
   ```zig
   if (counter % 100 == 0) {
       log.info("Processed {} items", .{counter});
   }
   ```

3. **Avoid logging in hot paths:**
   - Only log errors in critical loops
   - Use counters and log periodically
   - Consider trace points instead

4. **Use compile-time filtering:**
   - Set appropriate log levels in `std_options`
   - Unused logs are completely removed from binary

### 10.5 Structured Logging Checklist

- [ ] Use consistent JSON format
- [ ] Include timestamps (prefer ISO 8601 or Unix epoch)
- [ ] Add correlation IDs for request tracing
- [ ] Escape special characters properly
- [ ] Include severity level
- [ ] Add scope/component identifier
- [ ] Provide contextual fields (user_id, request_path, etc.)
- [ ] Make logs parseable by standard tools

### 10.6 Testing Guidelines

1. **Test with logging enabled:**
   ```zig
   pub const std_options: std.Options = .{
       .log_level = .debug,  // In test builds
   };
   ```

2. **Capture log output in tests:**
   ```zig
   test "verify logging" {
       var buffer = std.ArrayList(u8).init(testing.allocator);
       defer buffer.deinit();

       // Redirect stderr to buffer
       // ... test code ...

       const output = buffer.items;
       try testing.expect(std.mem.containsAtLeast(u8, output, 1, "Expected log"));
   }
   ```

3. **Avoid time-dependent assertions:**
   - Test message content, not timestamps
   - Use mock time sources if needed

### 10.7 Security Considerations

1. **Never log:**
   - Passwords or password hashes (without strong hashing)
   - API tokens or keys
   - Personally Identifiable Information (PII)
   - Credit card numbers
   - Session IDs

2. **Be cautious with:**
   - User inputs (potential log injection)
   - Error messages that leak implementation details
   - Stack traces in production (information disclosure)

3. **Consider:**
   - Log redaction for sensitive fields
   - Rate limiting to prevent log flooding
   - Log rotation to manage disk space

---

## Citations and References

[^1]: [Zig Language Reference 0.15.2: std.log](https://ziglang.org/documentation/0.15.2/std/#std.log) - Official documentation for the standard library logging module. Details the compile-time optimization and log level filtering mechanisms.

[^2]: [Zig Language Reference 0.15.2: std.Options](https://ziglang.org/documentation/0.15.2/std/#std.Options) - Documentation for std.Options structure, including log configuration fields.

[^3]: [TigerBeetle Source: Scoped Logging Usage](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr.zig#L5) - Example of scoped logger declaration: `const log = std.log.scoped(.vsr);`. TigerBeetle uses scoped logging extensively across all modules.

[^4]: [TigerBeetle Source: Custom Log Handler](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/scripts.zig#L25-L34) - Implementation of custom log handler with timestamp support.

[^5]: [Ghostty Source: Platform-Aware Log Handler](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L121-L168) - Custom log handler integrating with macOS Unified Logging system.

[^6]: [Zig std.debug Source Code](../../zig_versions/zig-0.15.2/lib/std/debug.zig) - Local Zig 0.15.2 stdlib implementation showing debug utilities including print, stack traces, and hex dump functions.

[^7]: [TigerBeetle Source: Trace System](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace.zig#L100) - Sophisticated tracing infrastructure layered on top of std.log with StatsD integration and event tracking.

[^8]: [Bun Source: Log Configuration](https://github.com/oven-sh/bun/blob/main/src/main.zig#L2) - Bun's minimal std.log configuration, setting warn-level logging in release mode.

[^9]: [ZLS Source: Log Configuration](https://github.com/zigtools/zls/blob/main/src/main.zig#L35) - ZLS log configuration using default handler with debug level in debug builds.

[^10]: [Zig std.log Source Code](../../zig_versions/zig-0.15.2/lib/std/log.zig) - Local Zig 0.15.2 stdlib implementation of the logging system.

[^11]: [TigerBeetle: IO Logging (Linux)](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L9) - Platform-specific I/O logging with `.io` scope.

[^12]: [TigerBeetle: Superblock Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/superblock.zig#L39) - Superblock operations logging with `.superblock` scope.

[^13]: [TigerBeetle: Journal Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/vsr/journal.zig#L14) - Write-ahead log logging with `.journal` scope.

[^14]: [TigerBeetle: Compaction Logging](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/lsm/compaction.zig#L38) - LSM compaction logging with `.compaction` scope.

[^15]: [Ghostty Source: Log Configuration](https://github.com/ghostty-org/ghostty/blob/main/src/main_ghostty.zig#L170-L178) - std_options configuration with build-mode-dependent log levels.

---

## Additional Resources

### Official Documentation
- [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)
- [Zig Standard Library Documentation](https://ziglang.org/documentation/0.15.2/std/)
- [Zig 0.14.1 Documentation](https://ziglang.org/documentation/0.14.1/)

### Community Resources
- [Zig.guide: Logging](https://zig.guide/) - Community guide with logging examples
- [Zig Learn: std.log](https://ziglearn.org/) - Tutorial-style learning resource

### Observability Standards
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/) - Industry standard for observability
- [Structured Logging Best Practices](https://www.honeycomb.io/blog/structured-logging-best-practices) - General structured logging guidance
- [StatsD Protocol](https://github.com/statsd/statsd/blob/master/docs/metric_types.md) - Metrics format used by TigerBeetle

### Reference Projects
- [TigerBeetle GitHub Repository](https://github.com/tigerbeetle/tigerbeetle)
- [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)
- [Bun GitHub Repository](https://github.com/oven-sh/bun)
- [ZLS GitHub Repository](https://github.com/zigtools/zls)

---

**Research Complete: 2025-11-05**
**Total Citations: 15 primary + 5 supplementary**
**Source Files Analyzed: 30+**
**Code Examples: 25+**
