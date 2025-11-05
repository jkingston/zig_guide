# Code Examples Summary: Chapter 13 - Logging, Diagnostics & Observability

## Overview

This document provides a quick reference for all code examples that will be developed for Chapter 13. Each example is designed to be runnable, educational, and demonstrate specific logging and observability patterns in Zig.

**Total Examples:** 6
**Target Audience:** Intermediate to advanced Zig developers
**Zig Versions:** 0.14.1 and 0.15.2

---

## Example 1: Basic Logging with std.log

**Directory:** `examples/01_basic_logging/`

**Purpose:**
Demonstrate fundamental std.log usage with different log levels and scopes.

**Learning Objectives:**
- Understand log level hierarchy (err, warn, info, debug)
- Use scoped logging for categorization
- Configure compile-time log filtering
- Implement basic logging patterns

**File Structure:**
```
examples/01_basic_logging/
├── build.zig              # Build configuration with log level option
├── README.md              # Usage instructions and explanation
└── src/
    ├── main.zig          # Main entry point demonstrating all levels
    ├── database.zig      # Database module with scoped logging
    └── network.zig       # Network module with scoped logging
```

**Key Features:**
- All log levels demonstrated (err, warn, info, debug)
- Multiple scopes (default, database, network)
- Build-time log level configuration
- Clear output showing different levels
- Version-compatible with 0.14.1 and 0.15.2

**Expected Output:**
```
[info] Application started
[database] [info] Connecting to database...
[database] [debug] Connection parameters: host=localhost port=5432
[network] [info] Sending request to https://api.example.com
[warn] Connection pool at 80% capacity
[err] Failed to connect: ConnectionRefused
```

**Build Commands:**
```bash
# Default (info level)
zig build run

# Debug level
zig build run -Dlog-level=debug

# Error only
zig build run -Dlog-level=err
```

**Estimated Complexity:** Low
**Development Time:** 1 hour

---

## Example 2: Custom Log Handlers

**Directory:** `examples/02_custom_handlers/`

**Purpose:**
Demonstrate implementing custom log handlers for different output formats and destinations.

**Learning Objectives:**
- Implement custom log handler functions
- Format log messages with timestamps
- Create JSON-formatted log output
- Handle multiple output destinations
- Ensure thread safety

**File Structure:**
```
examples/02_custom_handlers/
├── build.zig
├── README.md
└── src/
    ├── main.zig              # Demonstrates using different handlers
    └── handlers/
        ├── json_handler.zig        # JSON-formatted output
        ├── timestamped_handler.zig # Timestamped text output
        └── multi_handler.zig       # Multi-destination output
```

**Key Features:**
- Multiple custom handler implementations:
  1. **Timestamped Handler:** Adds Unix timestamp to each log
  2. **JSON Handler:** Outputs structured JSON logs
  3. **Multi-Destination Handler:** Writes to both stderr and file
- Thread-safe implementations
- Error handling in handlers
- Configurable via build options

**Handler Signatures:**
```zig
pub fn timestampedLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void { ... }

pub fn jsonLogFn(...) void { ... }
pub fn multiLogFn(...) void { ... }
```

**Expected JSON Output:**
```json
{"timestamp":1730860800,"level":"info","scope":"default","message":"Application started"}
{"timestamp":1730860801,"level":"debug","scope":"database","message":"Query: SELECT * FROM users"}
{"timestamp":1730860802,"level":"err","scope":"network","message":"Connection failed: timeout"}
```

**Build Commands:**
```bash
# Use timestamped handler
zig build run -Dhandler=timestamped

# Use JSON handler
zig build run -Dhandler=json

# Use multi-destination handler
zig build run -Dhandler=multi
```

**Estimated Complexity:** Medium
**Development Time:** 2 hours

---

## Example 3: Diagnostic Output in Tests and CI

**Directory:** `examples/03_diagnostic_testing/`

**Purpose:**
Show effective diagnostic patterns for testing and continuous integration environments.

**Learning Objectives:**
- Implement CI-friendly logging
- Use diagnostics in tests
- Generate helpful error context
- Create deterministic log output
- Debug test failures effectively

**File Structure:**
```
examples/03_diagnostic_testing/
├── build.zig
├── README.md
├── src/
│   ├── main.zig
│   └── parser.zig        # Parser module to test
└── tests/
    ├── parser_test.zig   # Tests with diagnostic output
    └── test_helpers.zig  # Shared test utilities
```

**Key Features:**
- Test-specific logging patterns
- CI-friendly output format (parseable, structured)
- Helpful failure messages with context
- Stack trace integration
- Reproducible output
- Test helper utilities

**Test Diagnostic Pattern:**
```zig
fn expectParsed(input: []const u8, expected: i32) !void {
    const result = parseValue(input) catch |err| {
        log.err("Parse failed for input: '{s}'", .{input});
        log.err("Error: {s}", .{@errorName(err)});
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
```

**Expected Test Output:**
```
[test] === Starting test suite ===
[test] Running parser tests...
[test] [info] Test passed: parseInt("42") = 42
[test] [info] Test passed: parseInt("100") = 100
[test] [err] Parse failed for input: 'invalid'
[test] [err] Error: InvalidCharacter
[test] === Test completed in 15ms ===
```

**Build Commands:**
```bash
# Run tests
zig build test

# Run with verbose diagnostics
zig build test -Dlog-level=debug
```

**Estimated Complexity:** Medium
**Development Time:** 1.5 hours

---

## Example 4: Structured Logging with JSON

**Directory:** `examples/04_structured_logging/`

**Purpose:**
Demonstrate structured logging patterns for machine-readable output and log aggregation.

**Learning Objectives:**
- Implement JSON-formatted logging
- Add contextual information to logs
- Use correlation IDs for request tracing
- Structure error information
- Design log schemas

**File Structure:**
```
examples/04_structured_logging/
├── build.zig
├── README.md
└── src/
    ├── main.zig           # Demo HTTP server simulation
    ├── structured_log.zig # Structured logging implementation
    └── http_server.zig    # Example server with request handling
```

**Key Features:**
- JSON log output format (valid, parseable)
- Contextual fields:
  - Correlation ID for request tracing
  - User ID for user tracking
  - Request path for debugging
  - Timestamp for ordering
  - Log level for filtering
- Request lifecycle tracking
- Machine-parseable format

**LogContext Implementation:**
```zig
pub const LogContext = struct {
    correlation_id: ?[]const u8 = null,
    user_id: ?u32 = null,
    request_path: ?[]const u8 = null,

    pub fn logInfo(self: LogContext, comptime format: []const u8, args: anytype) void {
        // JSON output with context
    }

    pub fn logError(self: LogContext, comptime format: []const u8, args: anytype) void {
        // JSON error with context
    }
};
```

**Expected Output:**
```json
{"timestamp":1730860800123,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request started"}
{"timestamp":1730860800150,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Querying database for user 42"}
{"timestamp":1730860800245,"level":"info","correlation_id":"req-12345-abcde","user_id":42,"path":"/api/users/42","message":"Request completed in 123ms"}
```

**Use Cases:**
- Log aggregation (ELK, Loki, CloudWatch)
- Distributed tracing
- Metrics extraction
- Request tracking

**Build Commands:**
```bash
# Run structured logging demo
zig build run

# Output can be piped to jq for parsing
zig build run | jq '.level,.message'
```

**Estimated Complexity:** Medium
**Development Time:** 2 hours

---

## Example 5: Production Logging Strategies

**Directory:** `examples/05_production_logging/`

**Purpose:**
Show production-ready logging patterns with performance considerations, sampling, and observability hooks.

**Learning Objectives:**
- Implement efficient production logging
- Use sampling to reduce log volume
- Add health check instrumentation
- Track error rates and metrics
- Handle high-throughput logging

**File Structure:**
```
examples/05_production_logging/
├── build.zig
├── README.md
└── src/
    ├── main.zig            # Production logging demo
    ├── sampled_logger.zig  # Sampling implementation
    ├── metrics.zig         # Error rate tracking
    └── health_check.zig    # Health monitoring
```

**Key Features:**
- **Sampling:** Log every Nth message to reduce volume
- **Rate Limiting:** Limit logs per time period
- **Error Rate Tracking:** Monitor error percentage
- **Health Checks:** Expose health metrics
- **Performance:** Minimal overhead design
- **Graceful Degradation:** Handle logging failures

**Components:**

1. **SampledLogger:**
```zig
pub const SampledLogger = struct {
    counter: Atomic(u64),
    sample_rate: u64,

    pub fn shouldLog(self: *SampledLogger) bool {
        const count = self.counter.fetchAdd(1, .monotonic);
        return count % self.sample_rate == 0;
    }
};
```

2. **ErrorRateTracker:**
```zig
pub const ErrorRateTracker = struct {
    error_count: Atomic(u64),
    total_count: Atomic(u64),

    pub fn recordError(self: *ErrorRateTracker, err: anyerror) void { ... }
    pub fn getErrorRate(self: *ErrorRateTracker) f64 { ... }
};
```

3. **HealthCheck:**
```zig
pub const HealthCheck = struct {
    tracker: *ErrorRateTracker,

    pub fn isHealthy(self: HealthCheck) bool {
        return self.tracker.getErrorRate() < 0.05; // 5% threshold
    }
};
```

**Expected Output:**
```
[info] Processing item 0
[info] Processing item 100
[err] Operation failed: SimulatedFailure
[info] Processing item 200
[info] Health check: error_rate=2.00% healthy=true
[info] Final health status: true
```

**Performance Characteristics:**
- Sampling reduces log volume by configured factor
- Atomic operations for thread-safe counters
- Minimal memory overhead
- All errors always logged (no sampling)

**Build Commands:**
```bash
# Run with default sampling (1/100)
zig build run

# Run with custom sampling rate
zig build run -Dsample-rate=50
```

**Estimated Complexity:** Medium-High
**Development Time:** 2.5 hours

---

## Example 6: Observability Integration

**Directory:** `examples/06_observability/`

**Purpose:**
Demonstrate integration patterns with external observability tools and distributed tracing.

**Learning Objectives:**
- Output formats for log aggregators
- Distributed tracing concepts
- Metric exposition
- Integration patterns
- Correlation across services

**File Structure:**
```
examples/06_observability/
├── build.zig
├── README.md
└── src/
    ├── main.zig              # Observability demo
    ├── otel_logs.zig         # OpenTelemetry-style logs
    ├── prometheus_metrics.zig # Prometheus metric format
    └── trace_context.zig     # Distributed tracing context
```

**Key Features:**
- **OpenTelemetry-compatible logs:** Industry-standard format
- **Trace Context:** Propagate trace_id and span_id
- **Distributed Tracing:** Correlation across services
- **Metric Exposition:** Counter/gauge/histogram patterns
- **Standard Formats:** Compatible with common tools

**Components:**

1. **TraceContext:**
```zig
pub const TraceContext = struct {
    trace_id: [16]u8,  // 128-bit trace ID
    span_id: [8]u8,    // 64-bit span ID

    pub fn generate() TraceContext { ... }
    pub fn hexTraceId(self: TraceContext) [32]u8 { ... }
};
```

2. **OpenTelemetry Log Format:**
```json
{
  "timestamp": 1730860800000000000,
  "severity_text": "INFO",
  "body": "Starting operation",
  "resource": {
    "service.name": "zig-service"
  },
  "scope": {
    "name": "default"
  },
  "attributes": {
    "trace_id": "a1b2c3d4e5f6...",
    "span_id": "1234567890abcdef"
  }
}
```

3. **Prometheus Metrics:**
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/api/users"} 42

# HELP error_rate Current error rate
# TYPE error_rate gauge
error_rate 0.02
```

**Expected Output:**
```
[info] Starting operation trace_id=a1b2c3d4e5f6... span_id=1234567890abcdef
[debug] Processing request trace_id=a1b2c3d4e5f6...
[debug] Request processing complete trace_id=a1b2c3d4e5f6...
[info] Operation completed trace_id=a1b2c3d4e5f6...
```

**Integration Targets:**
- Jaeger (distributed tracing)
- Prometheus (metrics)
- Grafana Loki (log aggregation)
- OpenTelemetry Collector
- DataDog, New Relic (APM)

**Build Commands:**
```bash
# Run observability demo
zig build run

# Output OpenTelemetry format
zig build run -Dformat=otel

# Output Prometheus metrics
zig build run -Dformat=prometheus
```

**Estimated Complexity:** High
**Development Time:** 3 hours

---

## Development Timeline

### Week 1: Basic Examples
- **Day 1:** Example 1 (Basic Logging) - 1 hour
- **Day 2:** Example 2 (Custom Handlers) - 2 hours
- **Day 3:** Example 3 (Diagnostic Testing) - 1.5 hours

### Week 2: Advanced Examples
- **Day 1:** Example 4 (Structured Logging) - 2 hours
- **Day 2:** Example 5 (Production Patterns) - 2.5 hours
- **Day 3:** Example 6 (Observability) - 3 hours

**Total Development Time:** 12 hours

---

## Testing Checklist

For each example:
- [ ] Compiles on Zig 0.14.1
- [ ] Compiles on Zig 0.15.2
- [ ] Runs without errors
- [ ] Produces expected output
- [ ] README is clear and complete
- [ ] Build configuration works
- [ ] Code is well-commented
- [ ] Examples are educational

---

## Common Patterns Across Examples

### 1. Thread Safety
All custom handlers must use:
```zig
std.debug.lockStdErr();
defer std.debug.unlockStdErr();
```

### 2. Error Handling
Handlers gracefully handle errors:
```zig
stderr.print(...) catch return;  // Fail gracefully
```

### 3. Build Configuration
All examples have:
```zig
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});
```

### 4. README Structure
Each README includes:
- Overview and purpose
- Building instructions
- Running instructions
- Expected output
- Learning points
- Version compatibility notes

---

## Integration with Content

Examples will be referenced from content.md:
- **Section 2 (Core Concepts):** Examples 1-2
- **Section 3 (Code Examples):** All examples with full listings
- **Section 4 (Common Pitfalls):** Anti-patterns from all examples
- **Section 5 (In Practice):** Example 5-6
- **Section 6 (Advanced Topics):** Example 4-6

---

## Version Compatibility Notes

### Zig 0.14.1 vs 0.15.2 Considerations

**Known Compatible:**
- std.log API is stable
- Log handler signature unchanged
- Build system configuration stable
- std.debug utilities stable

**Potential Differences:**
- JSON library usage (std.json)
- Atomic operations API
- File I/O patterns
- Stack trace format

**Testing Strategy:**
Test all examples on both versions to identify any incompatibilities and add version markers where needed.

---

**Status:** Examples specification complete
**Next Step:** Begin example development
**Priority Order:** 1 → 2 → 3 → 4 → 5 → 6
