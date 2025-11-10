const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose module for package consumers
    _ = b.addModule("mathlib", .{
        .root_source_file = b.path("src/mathlib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Tests for development
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/mathlib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);

    // Example executable (optional)
    const example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mathlib", .module = b.modules.get("mathlib").? },
            },
        }),
    });

    const example_install = b.addInstallArtifact(example, .{});
    const example_step = b.step("example", "Build example");
    example_step.dependOn(&example_install.step);
}
