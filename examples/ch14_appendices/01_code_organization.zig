// Example 1: Code Organization
// 15 Appendices
//
// Extracted from chapter content.md

// ✅ GOOD: Consistent ordering (from Zig stdlib)
const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const testing = std.testing;

// Type definitions
pub const Config = struct { ... };
pub const Error = error { ... };

// Public functions
pub fn init(allocator: Allocator) !Config { ... }
pub fn deinit(self: *Config) void { ... }

// Private functions
fn validateConfig(config: *const Config) bool { ... }

// Tests
test "config initialization" { ... }