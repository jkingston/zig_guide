const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Core library module
    const lib_source_file = b.path("src/lib.zig");
    const mod = b.addModule("core", .{
        .root_source_file = lib_source_file,
        .target = target,
    });

    // Shared library
    const lib = b.addSharedLibrary(.{
        .name = "core",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });
    b.installArtifact(lib);

    // Tests
    const tests = b.addTest(.{
        .root_module = mod,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run core tests");
    test_step.dependOn(&run_tests.step);
}
