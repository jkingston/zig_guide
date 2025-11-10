const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        "01_naming_conventions",
        "02_defer_order",
        "03_resource_cleanup",
        "04_errdefer",
        "05_generic_function",
        "06_copy_file",
        "07_generic_stack",
        "08_defer_in_loops_wrong",
        "09_defer_in_loops_correct",
    };

    // Build all examples
    inline for (examples) |example_name| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        // Add run step for each example
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
        run_step.dependOn(&run_cmd.step);
    }

    // Add tests for examples with test blocks
    const test_examples = [_][]const u8{
        "05_generic_function",
        "07_generic_stack",
    };

    inline for (test_examples) |example_name| {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        const test_run = b.addRunArtifact(test_exe);
        const test_step = b.step("test-" ++ example_name, "Run tests for " ++ example_name);
        test_step.dependOn(&test_run.step);
    }

    // Global test step
    const test_step = b.step("test", "Run all tests");
    inline for (test_examples) |example_name| {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        test_step.dependOn(&b.addRunArtifact(test_exe).step);
    }
}
