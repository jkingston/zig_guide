const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        "01_file_organization_patterns",
        // "02_example_2",  // Test-only file, handled separately
        // "03_example_3",  // Requires missing ../src/math.zig file, conceptual example
        // "04_example_4",  // Test-only file, handled separately
        // "05_example_5",  // Requires missing module 'myproject'
        "06_example_6",
        // "07_example_7",  // Test-only file, handled separately
        // "08_example_8",  // Requires missing module 'core'
    };

    const test_files = [_][]const u8{
        "02_example_2",
        "04_example_4",
        "07_example_7",
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
