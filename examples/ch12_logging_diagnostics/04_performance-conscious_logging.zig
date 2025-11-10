// Example 4: Performance-Conscious Logging
// 13 Logging Diagnostics
//
// Extracted from chapter content.md

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