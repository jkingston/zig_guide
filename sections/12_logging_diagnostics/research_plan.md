# Research Plan: Chapter 13 - Logging, Diagnostics & Observability

## Document Information
- **Chapter**: 13 - Logging, Diagnostics & Observability
- **Target Zig Versions**: 0.14.0, 0.14.1, 0.15.1, 0.15.2
- **Created**: 2025-11-05
- **Status**: Planning

## 1. Objectives

This research plan outlines the methodology for creating comprehensive documentation on Zig's logging facilities, diagnostic instrumentation, and observability patterns. The chapter provides practical guidance for instrumenting Zig programs for development debugging, production monitoring, and operational diagnostics.

**Primary Goals:**
1. Document std.log module capabilities and usage patterns
2. Explain logging levels, scopes, and custom log handlers
3. Demonstrate diagnostic output in development and CI environments
4. Show structured logging approaches for machine-readable output
5. Cover integration with external observability tools
6. Provide minimal-overhead instrumentation techniques
7. Present real-world examples from production codebases
8. Document version-specific differences in logging features

**Strategic Approach:**
- Focus on pragmatic logging patterns suitable for production
- Show minimal-overhead instrumentation techniques
- Document development vs production logging strategies
- Demonstrate structured logging for automated analysis
- Cover diagnostic patterns used in TigerBeetle, Ghostty, Bun, and ZLS
- Balance observability needs with performance constraints
- Maintain version compatibility through clear markers
- Emphasize deterministic, testable logging patterns

## 2. Scope Definition

### In Scope

**std.log Framework Topics:**
- std.log module architecture and design
- Log levels (err, warn, info, debug)
- Log scopes for categorizing output
- Default log handler behavior
- Custom log handler implementation
- Compile-time log level filtering
- Runtime log configuration
- Log format customization
- Thread-safe logging patterns
- Performance characteristics and overhead

**Diagnostic Instrumentation Topics:**
- Diagnostic output during development
- Debugging with log statements
- Assertion-based diagnostics (std.debug.assert)
- Stack trace generation (std.debug.dumpStackTrace)
- Diagnostic output in tests
- CI-friendly logging patterns
- Error context propagation
- Panic handlers and diagnostic output
- Build-time diagnostic configuration
- Conditional compilation for diagnostics

**Structured Logging Topics:**
- JSON-formatted log output
- Key-value pair logging
- Structured error context
- Machine-readable diagnostic formats
- Log aggregation strategies
- Correlation IDs and request tracing
- Contextual logging patterns
- Metric extraction from logs
- Integration with log aggregators (Loki, ElasticSearch, etc.)
- Observability best practices

**Production Observability Topics:**
- Production logging strategies
- Performance impact mitigation
- Sampling and rate limiting
- Async logging patterns
- Log rotation and management
- Remote logging integration
- Monitoring and alerting hooks
- Health check instrumentation
- Metrics and telemetry collection
- Distributed tracing basics

### Out of Scope

- Specific log aggregation platform setup (focus on patterns)
- Full distributed tracing implementations (basic patterns only)
- APM (Application Performance Monitoring) platform integration details
- Log shipping infrastructure (focus on output formats)
- Detailed metrics systems (cover basics only)
- GUI-based log viewers (focus on formats and patterns)
- Security/compliance aspects of logging (PII redaction, etc.)
- Log encryption and secure transport (focus on generation)

### Version-Specific Handling

**0.14.x and 0.15+ Differences:**
- std.log API changes or additions
- Default log handler implementation changes
- Build system log configuration API changes
- std.debug utilities modifications
- Performance characteristics differences
- Stack trace format changes

**Common Patterns (all versions):**
- Core std.log design is stable
- Log level hierarchy is consistent
- Custom log handler pattern is stable
- Diagnostic patterns work across versions

## 3. Core Topics

### Topic 1: std.log Fundamentals and Architecture

**Concepts to Cover:**
- std.log module design philosophy (compile-time vs runtime)
- Log level hierarchy (err, warn, info, debug)
- Scope-based logging for categorization
- Default log handler implementation
- How log calls are compiled away when disabled
- Thread safety guarantees
- Performance characteristics and zero-cost abstractions
- Integration with std.debug utilities
- Log output destinations (stderr by default)
- When to use logging vs assertions

**Research Sources:**
- Zig Language Reference 0.15.2: std.log documentation
- std/log.zig source code analysis
- std/debug.zig for diagnostic utilities
- TigerBeetle: logging patterns in distributed systems
- Ghostty: application logging strategies
- Bun: high-performance logging approaches
- Community discussions on logging best practices

**Example Ideas:**
- Basic logging at different levels
- Scoped logging demonstration
- Compile-time log level filtering
- Custom log scope creation

**Version-Specific Notes:**
- Check for std.log API changes between versions
- Document any default handler behavior changes
- Note performance characteristic differences

### Topic 2: Log Levels, Scopes, and Filtering

**Concepts to Cover:**
- Understanding the log level hierarchy
- When to use each log level (err, warn, info, debug)
- Creating and using log scopes
- Compile-time log level filtering with build options
- Runtime log level configuration strategies
- Filtering logs by scope
- Best practices for log level selection
- Avoiding log spam and noise
- Log level conventions in production
- Performance implications of different levels

**Research Sources:**
- std/log.zig: log level implementation
- TigerBeetle: production logging levels
- Ghostty: debug vs release logging
- Bun: high-throughput logging strategies
- ZLS: language server diagnostic logging
- Community conventions and discussions

**Example Ideas:**
- Demonstrating all log levels
- Scoped logging for subsystems
- Compile-time filtering configuration
- Dynamic log level adjustment

**Version-Specific Notes:**
- Log level API consistency check
- Build option changes for filtering
- Default log level differences

### Topic 3: Custom Log Handlers

**Concepts to Cover:**
- Implementing custom log handler functions
- Log handler signature and requirements
- Formatting log messages
- Adding timestamps and metadata
- Thread-safe custom handlers
- Multiple output destinations
- Buffered vs unbuffered logging
- Async log handler patterns
- Error handling in log handlers
- Testing custom log handlers
- Performance considerations

**Research Sources:**
- std/log.zig: default handler implementation
- TigerBeetle: custom logging implementation
- Bun: performance-optimized logging
- Ghostty: application-specific log formats
- Community custom handler examples
- Production logging patterns

**Example Ideas:**
- JSON-formatted log handler
- Timestamped log handler
- Multi-destination log handler
- Buffered async log handler

**Version-Specific Notes:**
- Log handler API changes
- Thread safety guarantees
- Performance characteristics

### Topic 4: Diagnostic Output in Development and Testing

**Concepts to Cover:**
- Development-time diagnostic strategies
- Using std.debug.print for quick debugging
- Assertion-based diagnostics (std.debug.assert)
- Stack trace generation and formatting
- Diagnostic output in test code
- CI-friendly logging patterns
- Conditional compilation for diagnostics
- Debug vs release diagnostic differences
- Memory leak diagnostics
- Performance profiling integration
- Error context and stack traces

**Research Sources:**
- std/debug.zig: diagnostic utilities
- std/testing.zig: test diagnostic patterns
- TigerBeetle: deterministic testing with logging
- Ghostty: debug builds and diagnostics
- ZLS: language server diagnostics
- Zig compiler: internal diagnostic patterns

**Example Ideas:**
- Debug assertions and diagnostics
- Test-specific logging
- CI-friendly output formats
- Stack trace demonstration

**Version-Specific Notes:**
- std.debug API changes
- Stack trace format differences
- Testing integration changes

### Topic 5: Structured Logging and Machine-Readable Formats

**Concepts to Cover:**
- Structured logging principles
- JSON log output format
- Key-value pair logging
- Contextual information in logs
- Correlation IDs and request tracing
- Structured error context
- Log parsing and aggregation
- Integration with log aggregators
- Metrics extraction from structured logs
- Best practices for structured data
- Performance overhead of structured logging
- Schema design for log events

**Research Sources:**
- TigerBeetle: deterministic event logging
- Bun: runtime telemetry and logging
- Ghostty: structured diagnostic output
- Industry best practices (OpenTelemetry concepts)
- Log aggregation platforms (patterns only)
- Community structured logging libraries

**Example Ideas:**
- JSON-formatted log handler
- Request tracing with correlation IDs
- Structured error context
- Metrics extraction patterns

**Version-Specific Notes:**
- JSON library usage (std.json changes)
- Formatting API differences
- Performance characteristics

### Topic 6: Production Logging Strategies and Observability

**Concepts to Cover:**
- Production logging best practices
- Balancing observability and performance
- Sampling and rate limiting
- Async logging for high-throughput systems
- Log levels in production
- Performance monitoring integration
- Health check instrumentation
- Error rate tracking
- Distributed system logging patterns
- Alert-worthy log events
- Log volume management
- Operational metrics collection
- Graceful degradation of logging

**Research Sources:**
- TigerBeetle: production database logging
- Bun: runtime observability
- Ghostty: application telemetry
- ZLS: language server diagnostics
- Industry best practices
- Production logging war stories

**Example Ideas:**
- Production log handler
- Sampling implementation
- Health check logging
- Error rate monitoring

**Version-Specific Notes:**
- Performance differences
- Async patterns availability
- Build configuration options

## 4. Code Examples Specification

### Example 1: Basic Logging with std.log

**Purpose:**
Demonstrate fundamental std.log usage with different log levels and scopes.

**Learning Objectives:**
- Understand log level hierarchy
- Use scoped logging
- Configure compile-time log filtering
- Implement basic log patterns

**Technical Requirements:**
- All log levels demonstrated (err, warn, info, debug)
- Scoped logging examples
- Compile-time filtering configuration
- Build.zig log level control
- Clear output showing different levels

**File Structure:**
```
examples/01_basic_logging/
  src/
    main.zig
    database.zig
    network.zig
  build.zig
  README.md
```

**Success Criteria:**
- Compiles on Zig 0.14.1 and 0.15.2
- Demonstrates all log levels clearly
- Shows scoped logging benefits
- Configurable via build options

**Example Code Sketch:**
```zig
const std = @import("std");
const log = std.log;

// Default scope
pub fn main() !void {
    log.err("This is an error message", .{});
    log.warn("This is a warning message", .{});
    log.info("This is an info message", .{});
    log.debug("This is a debug message", .{});

    // With formatted values
    const user_id: u32 = 42;
    log.info("User logged in: {d}", .{user_id});
}

// Scoped logging
const db_log = std.log.scoped(.database);

pub const Database = struct {
    pub fn connect() !void {
        db_log.info("Connecting to database...", .{});
        // Connection logic
        db_log.debug("Connection parameters: host=localhost port=5432", .{});
    }

    pub fn query(sql: []const u8) !void {
        db_log.debug("Executing query: {s}", .{sql});
        // Query execution
    }
};

// Scoped logging for network module
const net_log = std.log.scoped(.network);

pub const Network = struct {
    pub fn sendRequest(url: []const u8) !void {
        net_log.info("Sending request to {s}", .{url});
        net_log.debug("Request headers: ...", .{});
    }
};
```

**build.zig Configuration:**
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Log level configuration option
    const log_level = b.option(
        std.log.Level,
        "log-level",
        "Set the log level (err, warn, info, debug)",
    ) orelse .info;

    const exe = b.addExecutable(.{
        .name = "basic_logging",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Configure log level
    const options = b.addOptions();
    options.addOption(std.log.Level, "log_level", log_level);
    exe.root_module.addOptions("build_options", options);

    b.installArtifact(exe);
}
```

### Example 2: Custom Log Handlers

**Purpose:**
Demonstrate implementing custom log handlers for different output formats and destinations.

**Learning Objectives:**
- Implement custom log handler functions
- Format log messages with timestamps
- Create JSON-formatted log output
- Handle multiple output destinations
- Understand thread safety requirements

**Technical Requirements:**
- Multiple custom log handler implementations
- Timestamp formatting
- JSON output format
- File and stderr output
- Thread-safe handler design
- Error handling in handlers

**File Structure:**
```
examples/02_custom_handlers/
  src/
    main.zig
    handlers/
      json_handler.zig
      timestamped_handler.zig
      multi_handler.zig
  build.zig
  README.md
```

**Success Criteria:**
- Compiles on both Zig versions
- Multiple handler formats demonstrated
- Thread-safe implementation
- Clear output examples

**Example Code Sketch:**
```zig
const std = @import("std");

// Timestamped log handler
pub fn timestampedLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = if (scope == .default) "" else "(" ++ @tagName(scope) ++ ")";
    const level_txt = comptime level.asText();

    // Get current timestamp
    const timestamp = std.time.timestamp();

    // Thread-safe output
    const stderr = std.io.getStdErr().writer();
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    nosuspend stderr.print(
        "[{d}] {s}{s}: " ++ format ++ "\n",
        .{timestamp, level_txt, scope_prefix} ++ args,
    ) catch return;
}

// JSON log handler
pub fn jsonLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const stderr = std.io.getStdErr().writer();
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Format message
    var buf: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

    // Output JSON
    nosuspend {
        stderr.writeAll("{\"timestamp\":") catch return;
        stderr.print("{d}", .{std.time.timestamp()}) catch return;
        stderr.writeAll(",\"level\":\"") catch return;
        stderr.writeAll(level.asText()) catch return;
        stderr.writeAll("\",\"scope\":\"") catch return;
        stderr.writeAll(@tagName(scope)) catch return;
        stderr.writeAll("\",\"message\":\"") catch return;
        stderr.writeAll(message) catch return;
        stderr.writeAll("\"}\n") catch return;
    };
}

// Configure custom handler in build options
pub const std_options = struct {
    pub const logFn = timestampedLogFn;
};

pub fn main() !void {
    const log = std.log;

    log.info("Application started", .{});
    log.debug("Debug info: value={d}", .{42});
    log.warn("Warning: low memory", .{});
    log.err("Error occurred: {s}", .{"connection failed"});
}
```

### Example 3: Diagnostic Output in Tests and CI

**Purpose:**
Show effective diagnostic patterns for testing and continuous integration environments.

**Learning Objectives:**
- Implement CI-friendly logging
- Use diagnostics in tests
- Generate helpful error context
- Create deterministic log output
- Debug test failures effectively

**Technical Requirements:**
- Test-specific logging patterns
- CI-friendly output format
- Diagnostic helpers for tests
- Stack trace integration
- Reproducible output

**File Structure:**
```
examples/03_diagnostic_testing/
  src/
    main.zig
    parser.zig
  tests/
    parser_test.zig
    test_helpers.zig
  build.zig
  README.md
```

**Success Criteria:**
- Effective test diagnostics
- CI-parseable output
- Helpful failure messages
- Deterministic output

**Example Code Sketch:**
```zig
const std = @import("std");
const testing = std.testing;
const log = std.log.scoped(.test);

// Test helper with diagnostic output
fn expectParsed(
    input: []const u8,
    expected: i32,
) !void {
    const result = parseValue(input) catch |err| {
        log.err("Parse failed for input: '{s}'", .{input});
        log.err("Error: {s}", .{@errorName(err)});

        // Dump stack trace for debugging
        std.debug.dumpCurrentStackTrace(null);
        return err;
    };

    if (result != expected) {
        log.err("Assertion failed:", .{});
        log.err("  Input: '{s}'", .{input});
        log.err("  Expected: {d}", .{expected});
        log.err("  Got: {d}", .{result});
        return error.TestFailed;
    }
}

test "parser with diagnostics" {
    try expectParsed("42", 42);
    try expectParsed("100", 100);
    try expectParsed("-5", -5);

    // This will fail with helpful diagnostics
    // try expectParsed("invalid", 0);
}

// CI-friendly test output
const ci_log = std.log.scoped(.ci);

test "CI diagnostic example" {
    const start_time = std.time.milliNanos();

    ci_log.info("=== Starting test suite ===", .{});

    // Run tests...
    const test_result = runComplexTest() catch |err| {
        ci_log.err("TEST FAILED: {s}", .{@errorName(err)});
        return err;
    };

    const duration = std.time.milliNanos() - start_time;
    ci_log.info("=== Test completed in {d}ms ===", .{duration / 1_000_000});

    try testing.expect(test_result);
}

fn runComplexTest() !bool {
    // Complex test logic
    return true;
}

fn parseValue(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10);
}
```

### Example 4: Structured Logging with JSON

**Purpose:**
Demonstrate structured logging patterns for machine-readable output and log aggregation.

**Learning Objectives:**
- Implement JSON-formatted logging
- Add contextual information to logs
- Use correlation IDs for request tracing
- Structure error information
- Design log schemas

**Technical Requirements:**
- JSON log output format
- Contextual fields (correlation ID, user ID, etc.)
- Structured error information
- Machine-parseable format
- Performance-conscious implementation

**File Structure:**
```
examples/04_structured_logging/
  src/
    main.zig
    structured_log.zig
    http_server.zig
  build.zig
  README.md
```

**Success Criteria:**
- Valid JSON output
- Rich contextual information
- Request tracing demonstrated
- Parseable by log aggregators

**Example Code Sketch:**
```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const LogContext = struct {
    correlation_id: ?[]const u8 = null,
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
            stderr.writeAll("{") catch return;

            // Timestamp
            stderr.writeAll("\"timestamp\":") catch return;
            stderr.print("{d}", .{std.time.milliTimestamp()}) catch return;

            // Level
            stderr.writeAll(",\"level\":\"") catch return;
            stderr.writeAll(level.asText()) catch return;
            stderr.writeAll("\"") catch return;

            // Context fields
            if (self.correlation_id) |id| {
                stderr.writeAll(",\"correlation_id\":\"") catch return;
                stderr.writeAll(id) catch return;
                stderr.writeAll("\"") catch return;
            }

            if (self.user_id) |uid| {
                stderr.writeAll(",\"user_id\":") catch return;
                stderr.print("{d}", .{uid}) catch return;
            }

            if (self.request_path) |path| {
                stderr.writeAll(",\"path\":\"") catch return;
                stderr.writeAll(path) catch return;
                stderr.writeAll("\"") catch return;
            }

            // Message
            stderr.writeAll(",\"message\":\"") catch return;
            stderr.print(format, args) catch return;
            stderr.writeAll("\"") catch return;

            stderr.writeAll("}\n") catch return;
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

    // Error with context
    const error_ctx = LogContext{
        .correlation_id = "req-67890-fghij",
        .user_id = 99,
        .request_path = "/api/orders/invalid",
    };

    error_ctx.logError("Validation failed: {s}", .{"invalid order ID"});
}
```

### Example 5: Production Logging Strategies

**Purpose:**
Show production-ready logging patterns with performance considerations, sampling, and observability hooks.

**Learning Objectives:**
- Implement efficient production logging
- Use sampling to reduce log volume
- Add health check instrumentation
- Track error rates and metrics
- Handle high-throughput logging

**Technical Requirements:**
- Sampling implementation
- Rate limiting for high-frequency logs
- Health check endpoints
- Error rate tracking
- Minimal performance overhead
- Graceful degradation

**File Structure:**
```
examples/05_production_logging/
  src/
    main.zig
    sampled_logger.zig
    metrics.zig
    health_check.zig
  build.zig
  README.md
```

**Success Criteria:**
- Low overhead logging
- Effective sampling
- Production-ready patterns
- Observable behavior

**Example Code Sketch:**
```zig
const std = @import("std");
const Atomic = std.atomic.Value;

// Sampled logger (only logs every N messages)
pub const SampledLogger = struct {
    counter: Atomic(u64),
    sample_rate: u64,

    pub fn init(sample_rate: u64) SampledLogger {
        return .{
            .counter = Atomic(u64).init(0),
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

// Error rate tracker
pub const ErrorRateTracker = struct {
    error_count: Atomic(u64),
    total_count: Atomic(u64),

    pub fn init() ErrorRateTracker {
        return .{
            .error_count = Atomic(u64).init(0),
            .total_count = Atomic(u64).init(0),
        };
    }

    pub fn recordSuccess(self: *ErrorRateTracker) void {
        _ = self.total_count.fetchAdd(1, .monotonic);
    }

    pub fn recordError(self: *ErrorRateTracker, err: anyerror) void {
        _ = self.error_count.fetchAdd(1, .monotonic);
        _ = self.total_count.fetchAdd(1, .monotonic);

        // Always log errors (don't sample)
        std.log.err("Operation failed: {s}", .{@errorName(err)});
    }

    pub fn getErrorRate(self: *ErrorRateTracker) f64 {
        const errors = self.error_count.load(.monotonic);
        const total = self.total_count.load(.monotonic);

        if (total == 0) return 0.0;
        return @as(f64, @floatFromInt(errors)) / @as(f64, @floatFromInt(total));
    }
};

// Health check with metrics
pub const HealthCheck = struct {
    tracker: *ErrorRateTracker,

    pub fn isHealthy(self: HealthCheck) bool {
        const error_rate = self.tracker.getErrorRate();
        const is_healthy = error_rate < 0.05; // 5% threshold

        std.log.info("Health check: error_rate={d:.2}% healthy={}",
            .{error_rate * 100, is_healthy});

        return is_healthy;
    }
};

var sampled_logger = SampledLogger.init(100); // Log every 100th message
var error_tracker = ErrorRateTracker.init();

pub fn main() !void {
    // Simulate high-throughput operations
    var i: u64 = 0;
    while (i < 1000) : (i += 1) {
        // High-frequency log (sampled)
        sampled_logger.logInfo("Processing item {d}", .{i});

        // Simulate occasional errors
        if (i % 50 == 0) {
            error_tracker.recordError(error.SimulatedFailure);
        } else {
            error_tracker.recordSuccess();
        }
    }

    // Health check
    const health = HealthCheck{ .tracker = &error_tracker };
    const is_healthy = health.isHealthy();
    std.log.info("Final health status: {}", .{is_healthy});
}

const error = error{
    SimulatedFailure,
};
```

### Example 6: Observability Integration

**Purpose:**
Demonstrate integration patterns with external observability tools and distributed tracing.

**Learning Objectives:**
- Output formats for log aggregators
- Distributed tracing concepts
- Metric exposition
- Integration patterns
- Correlation across services

**Technical Requirements:**
- Log aggregator-compatible output
- Trace ID propagation
- Metric collection points
- External system integration patterns
- Standard observability formats

**File Structure:**
```
examples/06_observability/
  src/
    main.zig
    otel_logs.zig      // OpenTelemetry-style logs
    prometheus_metrics.zig
    trace_context.zig
  build.zig
  README.md
```

**Success Criteria:**
- Industry-standard log formats
- Traceable request flows
- Metric extraction
- Integration-ready patterns

**Example Code Sketch:**
```zig
const std = @import("std");

// Trace context for distributed tracing
pub const TraceContext = struct {
    trace_id: [16]u8,
    span_id: [8]u8,

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
        _ = std.fmt.bufPrint(&buf, "{s}", .{std.fmt.fmtSliceHexLower(&self.trace_id)})
            catch unreachable;
        return buf;
    }

    pub fn hexSpanId(self: TraceContext) [16]u8 {
        var buf: [16]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "{s}", .{std.fmt.fmtSliceHexLower(&self.span_id)})
            catch unreachable;
        return buf;
    }
};

// OpenTelemetry-compatible log output
pub fn otelLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const stderr = std.io.getStdErr().writer();
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    var buf: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, format, args) catch "format error";

    // OpenTelemetry log format
    nosuspend {
        stderr.writeAll("{") catch return;
        stderr.writeAll("\"timestamp\":") catch return;
        stderr.print("{d}", .{std.time.nanoTimestamp()}) catch return;
        stderr.writeAll(",\"severity_text\":\"") catch return;
        stderr.writeAll(level.asText()) catch return;
        stderr.writeAll("\",\"body\":\"") catch return;
        stderr.writeAll(message) catch return;
        stderr.writeAll("\",\"resource\":{\"service.name\":\"zig-service\"}") catch return;
        stderr.writeAll(",\"scope\":{\"name\":\"") catch return;
        stderr.writeAll(@tagName(scope)) catch return;
        stderr.writeAll("\"}") catch return;
        stderr.writeAll("}\n") catch return;
    };
}

pub fn main() !void {
    // Distributed tracing example
    const trace_ctx = TraceContext.generate();

    const trace_id_hex = trace_ctx.hexTraceId();
    const span_id_hex = trace_ctx.hexSpanId();

    std.log.info("Starting operation trace_id={s} span_id={s}",
        .{trace_id_hex, span_id_hex});

    // Simulate service call
    try processRequest(trace_ctx);

    std.log.info("Operation completed trace_id={s}", .{trace_id_hex});
}

fn processRequest(trace_ctx: TraceContext) !void {
    const trace_id_hex = trace_ctx.hexTraceId();
    std.log.debug("Processing request trace_id={s}", .{trace_id_hex});

    // Simulate work
    std.time.sleep(10 * std.time.ns_per_ms);

    std.log.debug("Request processing complete trace_id={s}", .{trace_id_hex});
}
```

## 5. Research Methodology

### Phase 1: Official Documentation Review

**Objective:** Establish authoritative baseline knowledge of Zig's logging and diagnostic capabilities.

**Tasks:**
1. Read Zig Language Reference 0.15.2:
   - std.log module documentation
   - std.debug module utilities
   - Stack trace functionality
   - Compile-time configuration

2. Study std.log source code:
   - Log level implementation
   - Scope mechanism
   - Default handler
   - Thread safety guarantees
   - Performance characteristics

3. Examine std.debug utilities:
   - Stack trace generation
   - Assertion mechanisms
   - Diagnostic print functions
   - Thread-safe output

4. Review build system docs:
   - Log configuration options
   - Conditional compilation
   - Build-time filtering

**Deliverables:**
- Annotated notes on std.log architecture
- Complete API reference for logging
- Diagnostic utilities documentation
- Version difference notes

**Timeline:** 1-2 hours

### Phase 2: Analyze TigerBeetle Logging Patterns

**Objective:** Study production logging patterns from a correctness-critical distributed database.

**Research Focus:**
1. Logging strategy:
   - Production logging approach
   - Diagnostic vs operational logs
   - Deterministic logging patterns
   - Performance considerations

2. Structured logging:
   - Event logging structure
   - Correlation and tracing
   - Replay and debugging
   - Audit logging

3. Observability:
   - Metrics extraction
   - Health monitoring
   - Performance tracking
   - Error reporting

**Specific Files to Review:**
- Logging infrastructure code
- Event log implementation
- Diagnostic utilities
- Test logging patterns

**Key Questions:**
- How does TigerBeetle balance observability and performance?
- What logging patterns support deterministic replay?
- How are logs structured for debugging?
- What operational metrics are logged?

**Deliverables:**
- Production logging pattern catalog
- Deterministic logging techniques
- Structured event logging examples
- Code citations with GitHub links

**Timeline:** 2-3 hours

### Phase 3: Analyze Ghostty Logging Patterns

**Objective:** Study application logging from a cross-platform terminal emulator.

**Research Focus:**
1. Application logging:
   - User-facing diagnostics
   - Debug vs release logging
   - Platform-specific considerations
   - Performance-sensitive logging

2. Development diagnostics:
   - Debug build instrumentation
   - Issue reproduction
   - User bug reports
   - Diagnostic data collection

3. Error handling:
   - Error logging and context
   - User-facing error messages
   - Developer diagnostics
   - Crash reporting

**Specific Files to Review:**
- Logging configuration
- Diagnostic output
- Error handling patterns
- Debug utilities

**Key Questions:**
- How does Ghostty structure application logs?
- What diagnostics help with user bug reports?
- How are errors logged and reported?
- What performance trade-offs exist?

**Deliverables:**
- Application logging patterns
- User-facing diagnostic strategies
- Error logging best practices
- Code examples with citations

**Timeline:** 2-3 hours

### Phase 4: Analyze Bun Logging Patterns

**Objective:** Study high-performance logging from a JavaScript runtime.

**Research Focus:**
1. High-throughput logging:
   - Performance optimization
   - Minimal overhead patterns
   - Async logging strategies
   - Sampling techniques

2. Runtime diagnostics:
   - Runtime event logging
   - Performance telemetry
   - Error tracking
   - Resource monitoring

3. Observability:
   - Metrics collection
   - Tracing integration
   - Production monitoring
   - Performance profiling

**Specific Files to Review:**
- Logging infrastructure
- Performance telemetry
- Error tracking
- Diagnostic output

**Key Questions:**
- How does Bun minimize logging overhead?
- What async logging patterns are used?
- How are high-frequency events handled?
- What observability hooks exist?

**Deliverables:**
- High-performance logging patterns
- Async logging techniques
- Sampling strategies
- Observability integration examples

**Timeline:** 2-3 hours

### Phase 5: Analyze ZLS Logging Patterns

**Objective:** Study diagnostic logging from the Zig Language Server.

**Research Focus:**
1. Language server diagnostics:
   - LSP protocol logging
   - Editor integration diagnostics
   - Request/response tracing
   - Performance logging

2. Development tooling:
   - Debug output
   - Issue diagnosis
   - User problem reporting
   - Trace logging

3. Incremental compilation:
   - Compilation event logging
   - Cache diagnostics
   - Performance tracking
   - Build system logging

**Specific Files to Review:**
- Logging configuration
- LSP diagnostics
- Trace logging
- Debug utilities

**Key Questions:**
- How does ZLS structure diagnostic output?
- What logging helps debug LSP issues?
- How are compilation events logged?
- What performance diagnostics exist?

**Deliverables:**
- Tooling diagnostic patterns
- LSP logging strategies
- Development debug techniques
- Code citations

**Timeline:** 1-2 hours

### Phase 6: Document Structured Logging and Observability

**Objective:** Research industry-standard observability patterns and their application to Zig.

**Research Focus:**
1. Structured logging standards:
   - JSON logging formats
   - OpenTelemetry concepts
   - Industry best practices
   - Log aggregation patterns

2. Distributed tracing:
   - Trace context propagation
   - Span and trace IDs
   - Correlation patterns
   - Service mesh integration

3. Metrics and monitoring:
   - Log-derived metrics
   - Health checks
   - Error rate tracking
   - SLI/SLO monitoring

4. Integration patterns:
   - Log aggregator formats
   - Prometheus metrics
   - Tracing systems
   - APM integration

**Research Sources:**
- OpenTelemetry documentation (concepts)
- Industry logging best practices
- Log aggregation platforms (patterns)
- Distributed tracing concepts
- Production observability guides

**Key Questions:**
- What structured formats are most useful?
- How to implement distributed tracing?
- What metrics should be logged?
- How to integrate with external tools?

**Deliverables:**
- Structured logging best practices
- Observability pattern catalog
- Integration guidelines
- Industry standard examples

**Timeline:** 2-3 hours

### Phase 7: Create and Test All Examples

**Objective:** Develop, test, and validate all 6 code examples.

**Tasks:**
1. Example 1: Basic logging
   - Implement all log levels
   - Demonstrate scoped logging
   - Configure build options
   - Test on both versions

2. Example 2: Custom handlers
   - JSON log handler
   - Timestamped handler
   - Multi-destination handler
   - Thread safety verification

3. Example 3: Diagnostic testing
   - Test logging patterns
   - CI-friendly output
   - Error diagnostics
   - Stack trace integration

4. Example 4: Structured logging
   - JSON output implementation
   - Contextual logging
   - Request tracing
   - Schema design

5. Example 5: Production patterns
   - Sampling implementation
   - Error rate tracking
   - Health checks
   - Performance validation

6. Example 6: Observability
   - External tool integration
   - Trace propagation
   - Metric exposition
   - Standard formats

**Validation Criteria:**
- All examples compile on 0.14.1 and 0.15.2
- Output is clear and correct
- Performance is acceptable
- Documentation is complete

**Deliverables:**
- 6 complete, tested examples
- README for each example
- Build configuration
- Expected output samples

**Timeline:** 4-6 hours

### Phase 8: Synthesize Findings into research_notes.md

**Objective:** Consolidate all research into comprehensive notes for content writing.

**Tasks:**
1. Organize all findings by topic
2. Add deep citations (25+ references)
3. Include code snippets from reference projects
4. Document version differences
5. Create pattern catalog
6. Summarize key insights

**Structure:**
1. std.log Fundamentals
   - Architecture and design
   - API reference
   - Performance characteristics
   - Citations

2. Log Levels and Scopes
   - Level hierarchy
   - Scope patterns
   - Filtering strategies
   - Examples from projects

3. Custom Log Handlers
   - Implementation patterns
   - Thread safety
   - Performance considerations
   - Real-world examples

4. Diagnostic Instrumentation
   - Development diagnostics
   - Test logging
   - CI patterns
   - Stack traces

5. Structured Logging
   - JSON formats
   - Contextual logging
   - Tracing patterns
   - Integration examples

6. Production Observability
   - Performance strategies
   - Sampling patterns
   - Metrics collection
   - Monitoring integration

7. Common Pitfalls and Solutions
   - Logging mistakes
   - Performance issues
   - Integration problems
   - Best practices

**Deliverables:**
- research_notes.md (800-1000 lines minimum)
- 25+ deep GitHub/documentation citations
- Code examples from production projects
- Version compatibility notes
- Pattern catalog

**Timeline:** 2-3 hours

## 6. Reference Projects Analysis

### Analysis Matrix

| Project | Primary Focus | Files to Review | Key Patterns |
|---------|--------------|-----------------|--------------|
| **TigerBeetle** | Deterministic logging, event logs | Logging infrastructure, event recording | Structured events, deterministic replay, audit logs |
| **Ghostty** | Application diagnostics, debug builds | Logging config, error reporting | User diagnostics, debug vs release, error context |
| **Bun** | High-performance logging, telemetry | Runtime logging, performance tracking | Minimal overhead, async patterns, sampling |
| **ZLS** | Tooling diagnostics, LSP logging | Diagnostic output, trace logging | Protocol logging, debug output, incremental logs |
| **Zig Compiler** | Internal diagnostics, error reporting | Compiler diagnostics, error messages | Rich error context, staged diagnostics |
| **Zig stdlib** | Canonical logging patterns | std/log.zig, std/debug.zig | Default patterns, log handler examples |

### Detailed Analysis Plan

**For Each Project:**
1. Clone/update to latest stable version
2. Review logging infrastructure and patterns
3. Identify diagnostic approaches
4. Extract representative code snippets
5. Document observability strategies
6. Note version-specific behaviors

**Citation Format:**
```markdown
[Project: Pattern description](https://github.com/owner/repo/blob/commit/path/to/file.zig#L123-L145)
```

## 7. Key Research Questions

### std.log Fundamentals
1. **How is std.log designed and architected?**
   - What is the compile-time vs runtime design?
   - How are log calls optimized away?
   - What thread safety guarantees exist?

2. **What are the performance characteristics?**
   - What is the overhead of logging?
   - How does filtering affect performance?
   - When are logs zero-cost?

3. **How do log scopes work?**
   - What is the scope mechanism?
   - How are scopes compiled?
   - What are scope best practices?

### Custom Handlers
4. **How do you implement a custom log handler?**
   - What is the handler signature?
   - What thread safety is required?
   - How to handle errors in handlers?

5. **What are common handler patterns?**
   - JSON formatting
   - Timestamping
   - Multi-destination output
   - Buffering strategies

6. **How to ensure handler performance?**
   - Minimizing overhead
   - Async patterns
   - Buffering strategies

### Diagnostic Patterns
7. **What diagnostic utilities exist?**
   - Stack trace generation
   - Assertions
   - Debug printing
   - Memory diagnostics

8. **How to structure test diagnostics?**
   - Test-specific logging
   - CI-friendly output
   - Failure context
   - Reproducibility

9. **What are debug vs release considerations?**
   - Conditional compilation
   - Debug-only diagnostics
   - Performance impact
   - User-facing errors

### Structured Logging
10. **How to implement structured logging?**
    - JSON output format
    - Key-value patterns
    - Schema design
    - Performance overhead

11. **What contextual information to include?**
    - Correlation IDs
    - User context
    - Request metadata
    - Error context

12. **How to integrate with log aggregators?**
    - Output format requirements
    - Parsing considerations
    - Standard formats
    - Best practices

### Production Logging
13. **What are production logging strategies?**
    - Log level selection
    - Volume management
    - Sampling patterns
    - Rate limiting

14. **How to minimize performance impact?**
    - Async logging
    - Buffering
    - Filtering
    - Graceful degradation

15. **What observability hooks to add?**
    - Health checks
    - Metrics
    - Error rates
    - Performance tracking

### Observability Integration
16. **How to implement distributed tracing?**
    - Trace context
    - Span propagation
    - Correlation
    - Standards

17. **What metrics to expose?**
    - Log-derived metrics
    - Error rates
    - Latency tracking
    - Resource usage

18. **How to integrate with external tools?**
    - Log aggregators
    - APM platforms
    - Tracing systems
    - Monitoring tools

### Version Differences
19. **What changed in logging between versions?**
    - std.log API changes
    - Handler interface changes
    - Performance differences

20. **Are there build system changes?**
    - Configuration options
    - Filtering mechanisms
    - Build-time settings

## 8. Common Pitfalls to Document

### Basic Logging Pitfalls

**Pitfall 1.1: Expensive Computation in Log Arguments**
```zig
// ❌ Incorrect - computation happens even if log is filtered out
log.debug("Complex data: {s}", .{expensiveComputation()});

// ✅ Correct - guard expensive operations
if (std.log.level == .debug) {
    log.debug("Complex data: {s}", .{expensiveComputation()});
}
```

**Pitfall 1.2: Not Using Scoped Logging**
```zig
// ❌ Incorrect - all logs in default scope
log.info("Database connected", .{});
log.info("HTTP request received", .{});

// ✅ Correct - use scopes for categorization
const db_log = std.log.scoped(.database);
const http_log = std.log.scoped(.http);

db_log.info("Database connected", .{});
http_log.info("Request received", .{});
```

**Pitfall 1.3: Logging Sensitive Information**
```zig
// ❌ Incorrect - logging passwords
log.info("User login: user={s} pass={s}", .{username, password});

// ✅ Correct - never log sensitive data
log.info("User login: user={s}", .{username});
```

### Custom Handler Pitfalls

**Pitfall 2.1: Not Thread-Safe Handler**
```zig
// ❌ Incorrect - non-thread-safe handler
var log_buffer: [4096]u8 = undefined;
var log_len: usize = 0;

pub fn unsafeLogFn(...) void {
    // Multiple threads can corrupt log_buffer
    const msg = std.fmt.bufPrint(log_buffer[log_len..], ...) catch return;
    log_len += msg.len;
}

// ✅ Correct - use locking
pub fn safeLogFn(...) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    // Thread-safe output
    const stderr = std.io.getStdErr().writer();
    stderr.print(...) catch return;
}
```

**Pitfall 2.2: Handler That Can Fail**
```zig
// ❌ Incorrect - handler panics on error
pub fn badLogFn(...) void {
    const file = std.fs.cwd().openFile("log.txt", .{.mode = .write_only}) catch unreachable;
    defer file.close();
    file.writer().print(...) catch unreachable;
}

// ✅ Correct - handle errors gracefully
pub fn goodLogFn(...) void {
    const file = std.fs.cwd().openFile("log.txt", .{.mode = .write_only}) catch {
        // Fall back to stderr if file unavailable
        const stderr = std.io.getStdErr().writer();
        stderr.print(...) catch return;
        return;
    };
    defer file.close();
    file.writer().print(...) catch return;
}
```

### Structured Logging Pitfalls

**Pitfall 3.1: Invalid JSON in Logs**
```zig
// ❌ Incorrect - unescaped quotes break JSON
pub fn badJsonLog(msg: []const u8) void {
    stderr.print("{{\"message\":\"{s}\"}}\n", .{msg});
    // If msg contains quotes, JSON is invalid
}

// ✅ Correct - properly escape strings
pub fn goodJsonLog(msg: []const u8) void {
    stderr.writeAll("{\"message\":\"") catch return;
    for (msg) |c| {
        if (c == '"') {
            stderr.writeAll("\\\"") catch return;
        } else {
            stderr.writeByte(c) catch return;
        }
    }
    stderr.writeAll("\"}\n") catch return;
}
```

**Pitfall 3.2: Missing Context in Structured Logs**
```zig
// ❌ Incorrect - minimal context
log.err("Operation failed", .{});

// ✅ Correct - rich context for debugging
const ctx = LogContext{
    .correlation_id = request.id,
    .user_id = request.user,
    .operation = "update_profile",
};
ctx.logError("Operation failed: {s}", .{@errorName(err)});
```

### Performance Pitfalls

**Pitfall 4.1: High-Frequency Logging Without Sampling**
```zig
// ❌ Incorrect - logs on every iteration
for (items) |item| {
    log.debug("Processing {d}", .{item.id});
    processItem(item);
}

// ✅ Correct - sample high-frequency logs
var logger = SampledLogger.init(100); // Every 100th
for (items) |item| {
    logger.logDebug("Processing {d}", .{item.id});
    processItem(item);
}
```

**Pitfall 4.2: Blocking I/O in Log Handler**
```zig
// ❌ Incorrect - blocking network I/O in handler
pub fn slowLogFn(...) void {
    const socket = connectToLogServer() catch return; // Blocks!
    socket.send(...) catch return;
}

// ✅ Correct - async or buffered logging
pub fn asyncLogFn(...) void {
    // Add to buffer, async thread ships logs
    log_buffer.append(...) catch return;
}
```

### Testing and CI Pitfalls

**Pitfall 5.1: Non-Deterministic Log Output in Tests**
```zig
// ❌ Incorrect - timestamps make tests non-deterministic
test "operation logging" {
    const output = captureLogOutput();
    try testing.expectEqualStrings("[2025-01-15 10:23:45] Started", output);
}

// ✅ Correct - test without timestamps or mock time
test "operation logging" {
    const output = captureLogOutput();
    try testing.expect(std.mem.containsAtLeast(u8, output, 1, "Started"));
}
```

**Pitfall 5.2: Excessive Test Logging**
```zig
// ❌ Incorrect - logs spam CI output
test "many operations" {
    for (0..1000) |i| {
        log.debug("Iteration {d}", .{i}); // 1000 lines!
        doWork(i);
    }
}

// ✅ Correct - minimal test logging
test "many operations" {
    log.info("Running 1000 iterations", .{});
    for (0..1000) |i| {
        doWork(i);
    }
    log.info("Completed all iterations", .{});
}
```

### Production Pitfalls

**Pitfall 6.1: No Log Rotation**
```zig
// ❌ Incorrect - logs grow unbounded
pub fn initLogging() !void {
    log_file = try std.fs.cwd().createFile("app.log", .{});
    // File grows forever
}

// ✅ Correct - implement rotation or use external tools
pub fn initLogging() !void {
    // Open in append mode
    // Use external log rotation (logrotate, etc.)
    // Or implement size-based rotation
}
```

**Pitfall 6.2: Logging in Hot Path**
```zig
// ❌ Incorrect - debug logs in critical path
fn processPacket(packet: Packet) void {
    log.debug("Processing packet {d}", .{packet.id});
    // Critical performance path
    fastProcessing(packet);
}

// ✅ Correct - minimal logging in hot path
fn processPacket(packet: Packet) void {
    // Only log errors or sampled events
    fastProcessing(packet);
}
```

## 9. Success Criteria

### Content Quality
- [ ] All major logging and diagnostic patterns documented
- [ ] 4-6 runnable, tested examples provided
- [ ] Common pitfalls section with solutions
- [ ] Clear logging best practices guidelines
- [ ] Real-world patterns from production projects
- [ ] Performance considerations addressed

### Citations and References
- [ ] 25+ authoritative citations minimum
- [ ] Deep GitHub links to actual code
- [ ] Official documentation references
- [ ] Community resource links
- [ ] Version-specific documentation

### Technical Accuracy
- [ ] All code examples compile on Zig 0.14.1
- [ ] All code examples compile on Zig 0.15.2
- [ ] Examples produce expected output
- [ ] Performance claims validated
- [ ] Thread safety verified

### Completeness
- [ ] All topics from prompt.md covered
- [ ] std.log thoroughly explained
- [ ] Custom handlers demonstrated
- [ ] Structured logging shown
- [ ] Production patterns documented
- [ ] Version differences marked

### Educational Value
- [ ] Clear learning progression
- [ ] Practical, actionable guidance
- [ ] Pitfall prevention strategies
- [ ] Best practices highlighted
- [ ] Production patterns demonstrated

## 10. Validation and Testing

### Code Example Validation

**For Each Example:**
1. **Compilation Test:**
   ```bash
   # Test on Zig 0.14.1
   /path/to/zig-0.14.1/zig build

   # Test on Zig 0.15.2
   /path/to/zig-0.15.2/zig build
   ```

2. **Output Validation:**
   ```bash
   # Run and verify output
   zig build run

   # Test different log levels
   zig build run -Dlog-level=debug
   zig build run -Dlog-level=info
   ```

3. **Performance Validation:**
   ```bash
   # Verify minimal overhead
   zig build -Doptimize=ReleaseFast
   # Benchmark with and without logging
   ```

### Logging-Specific Validation

**Quality Checks:**
- [ ] Log output is well-formatted
- [ ] Thread safety verified
- [ ] Performance overhead acceptable
- [ ] Structured logs are valid JSON
- [ ] Error handling is graceful
- [ ] Sampling works correctly

## 11. Timeline and Milestones

### Week 1: Research and Documentation Foundation

**Days 1-2: Official Documentation and Core Concepts**
- Phase 1: Official documentation review (1-2 hours)
- Establish baseline knowledge of std.log
- Create API reference

**Days 3-5: Reference Project Analysis**
- Phase 2: TigerBeetle analysis (2-3 hours)
- Phase 3: Ghostty analysis (2-3 hours)
- Phase 4: Bun analysis (2-3 hours)
- Phase 5: ZLS analysis (1-2 hours)

**Milestone 1: Research notes foundation complete**

### Week 2: Structured Logging and Example Development

**Days 1-2: Observability Research**
- Phase 6: Structured logging and observability (2-3 hours)
- Research integration patterns
- Document best practices

**Days 3-5: Core Examples**
- Example 1: Basic logging (1 hour)
- Example 2: Custom handlers (2 hours)
- Example 3: Diagnostic testing (1 hour)

**Milestone 2: Core examples complete**

### Week 3: Advanced Examples and Content Creation

**Days 1-2: Advanced Examples**
- Example 4: Structured logging (2 hours)
- Example 5: Production patterns (2 hours)
- Example 6: Observability (2 hours)

**Day 3: Synthesis**
- Phase 8: research_notes.md synthesis (2-3 hours)

**Days 4-5: Content Writing**
- Write content.md (1000-1500 lines)
- Integrate all examples
- Add citations (25+ minimum)

**Milestone 3: Content draft complete**

### Week 4: Review and Refinement

**Days 1-2: Technical Review**
- Validate all code examples
- Test on both versions
- Verify citations

**Days 3-4: Polish**
- Proofread content
- Improve clarity
- Final validation

**Day 5: Final QA**
- Complete checklist
- Final test runs
- Documentation review

**Milestone 4: Chapter complete**

### Total Estimated Time: 30-40 hours

## 12. Deliverables Checklist

### Research Phase Deliverables
- [X] research_plan.md (this document)
- [ ] research_notes.md (800-1000 lines, 25+ citations)
- [ ] std.log API reference
- [ ] Pattern catalog from reference projects
- [ ] Common pitfalls documentation
- [ ] Observability integration guide

### Code Example Deliverables
- [ ] Example 1: Basic logging (complete with README)
- [ ] Example 2: Custom handlers (complete with README)
- [ ] Example 3: Diagnostic testing (complete with README)
- [ ] Example 4: Structured logging (complete with README)
- [ ] Example 5: Production patterns (complete with README)
- [ ] Example 6: Observability (complete with README)

### Final Content Deliverables
- [ ] content.md (1000-1500 lines minimum)
- [ ] All examples tested on 0.14.1 and 0.15.2
- [ ] 25+ authoritative citations
- [ ] Version markers where applicable
- [ ] Complete References section

### Quality Assurance
- [ ] All code compiles without warnings
- [ ] Log output is correct
- [ ] Performance is acceptable
- [ ] Thread safety verified
- [ ] Documentation clarity review
- [ ] Citation accuracy verified

---

## Notes for Execution

When executing this research plan:

1. **Start with official docs** to establish authoritative baseline
2. **Focus on practical patterns** over theoretical completeness
3. **Prioritize production use cases** - real-world observability needs
4. **Show performance-conscious patterns** - minimal overhead is key
5. **Cite deeply** - link to specific production code
6. **Test thoroughly** - all examples must work correctly
7. **Document pitfalls** - help developers avoid mistakes
8. **Consider both versions** - mark differences clearly
9. **Think about observability** - make systems observable in production
10. **Balance detail and overhead** - right level of instrumentation

The goal is to teach **effective logging and observability practices** for production Zig code, not just explain the API.

**Key Themes:**
- **Logging:** Structured, performant, actionable
- **Diagnostics:** Clear, reproducible, helpful
- **Observability:** Production-ready, minimal overhead, integrated

---

**Status:** Planning complete, ready for execution
**Next Step:** Begin Phase 1 (Official Documentation Review)
