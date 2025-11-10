const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "profiling_demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // CRITICAL PROFILING CONFIGURATION
    // These settings are essential for meaningful profiling results

    // 1. Keep debug symbols - required for profilers to show function names
    //    and source code locations
    exe.root_module.strip = false;

    // 2. Keep frame pointers - improves stack trace quality in profilers
    //    Some profilers (like perf) can work without this using DWARF unwinding,
    //    but frame pointers are more reliable and faster
    exe.root_module.omit_frame_pointer = false;

    // Note: We don't override the optimize mode here - use the command line:
    //   zig build -Doptimize=ReleaseSafe   # Good balance for profiling
    //   zig build -Doptimize=ReleaseFast   # Profile optimized code
    //   zig build -Doptimize=Debug         # Profile with all debug info (slower)

    b.installArtifact(exe);

    // Run command for easy execution
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the profiling demo");
    run_step.dependOn(&run_cmd.step);

    // Test step
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Additional test for compute module
    const compute_tests = b.addTest(.{
        .root_source_file = b.path("src/compute.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_compute_tests = b.addRunArtifact(compute_tests);
    test_step.dependOn(&run_compute_tests.step);

    // Additional test for memory module
    const memory_tests = b.addTest(.{
        .root_source_file = b.path("src/memory.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_memory_tests = b.addRunArtifact(memory_tests);
    test_step.dependOn(&run_memory_tests.step);
}

// PROFILING CONFIGURATION NOTES:
//
// Optimization Modes for Profiling:
// ---------------------------------
//
// Debug (-Doptimize=Debug):
//   + Maximum debug information
//   + All assertions enabled
//   + No inlining (easier to understand)
//   - Very slow (not representative of production)
//   - Use only for debugging specific issues
//
// ReleaseSafe (-Doptimize=ReleaseSafe): [RECOMMENDED FOR PROFILING]
//   + Good balance of performance and debuggability
//   + Safety checks enabled (catches bugs)
//   + Some optimizations applied
//   + Debug symbols preserved
//   - Slightly slower than ReleaseFast
//   - Use this for most profiling work
//
// ReleaseFast (-Doptimize=ReleaseFast):
//   + Maximum performance
//   + Aggressive optimizations
//   - Safety checks disabled
//   - Some debug info may be harder to interpret
//   - Use when profiling final optimized build
//
// ReleaseSmall (-Doptimize=ReleaseSmall):
//   + Optimizes for size
//   - May not be representative of performance goals
//   - Use only when profiling for binary size
//
// Why strip = false is Critical:
// -----------------------------
// Debug symbols contain:
// - Function names
// - Source file paths and line numbers
// - Variable names and types
// - Inlining information
//
// Without debug symbols, profilers show:
// - Memory addresses instead of function names
// - "??" instead of source locations
// - Incomplete call graphs
//
// Why omit_frame_pointer = false Helps:
// -------------------------------------
// Frame pointers enable:
// - Faster stack unwinding in profilers
// - More reliable backtraces
// - Lower profiling overhead
//
// Trade-off: Slight performance cost (~1-3%)
// Worth it for accurate profiling!
//
// Build Commands for Profiling:
// -----------------------------
//
// General profiling:
//   zig build -Doptimize=ReleaseSafe
//
// Profile optimized code:
//   zig build -Doptimize=ReleaseFast
//
// Profile with maximum debug info:
//   zig build -Doptimize=Debug
//
// Then run profiling scripts:
//   ./scripts/profile_callgrind.sh
//   ./scripts/profile_perf.sh
//   ./scripts/profile_massif.sh
