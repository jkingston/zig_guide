const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Check Zig version - examples 03 and 04 require 0.15+
    const is_zig_015_or_later = builtin.zig_version.minor >= 15;

    // Examples that work on all supported versions (0.14+)
    const examples_all = [_][]const u8{
        "01_example_1",
    };

    // Examples that require Zig 0.15+ (use std.fs.File.stdout() API)
    const examples_015 = [_][]const u8{
        "03_stdout_writer_changes_in_015",
        "04_example_4",
    };

    const test_files = [_][]const u8{
        "02_example_2",
    };

    // Build examples that work on all versions
    inline for (examples_all) |example_name| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
        run_step.dependOn(&run_cmd.step);
    }

    // Build 0.15+ specific examples only on compatible versions
    if (is_zig_015_or_later) {
        inline for (examples_015) |example_name| {
            const exe = b.addExecutable(.{
                .name = example_name,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(example_name ++ ".zig"),
                    .target = target,
                    .optimize = optimize,
                }),
            });
            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
            run_step.dependOn(&run_cmd.step);
        }
    }

    // Global test step
    const test_step = b.step("test", "Run all tests");
    inline for (test_files) |test_name| {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        test_step.dependOn(&b.addRunArtifact(test_exe).step);
    }
}
