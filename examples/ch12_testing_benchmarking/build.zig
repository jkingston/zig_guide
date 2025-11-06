const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        // "01_example_1",  // Test-only, handled separately
        // "02_example_2",  // Test-only, handled separately
        // "03_example_3",  // Test-only, handled separately
        "04_benchmarking_best_practices",
        // "05_testing_fundamentals",  // Test-only, handled separately
        // "06_example_6",  // Test-only, handled separately
        // "07_example_7",  // Test-only, handled separately
        // "08_parameterized_tests",  // Test-only, handled separately
        // "09_allocator_testing",  // Test-only, handled separately
        "10_example_10",
        // "11_example_11",  // Test-only, handled separately
    };

    const test_files = [_][]const u8{
        "01_example_1",
        "02_example_2",
        "03_example_3",
        "05_testing_fundamentals",
        "06_example_6",
        "07_example_7",
        "08_parameterized_tests",
        "09_allocator_testing",
        "11_example_11",
    };

    // Create stub modules
    const benchmark_mod = b.createModule(.{
        .root_source_file = b.path("benchmark.zig"),
    });

    const snaptest_mod = b.createModule(.{
        .root_source_file = b.path("snaptest.zig"),
    });

    // Build all examples
    inline for (examples) |example_name| {
        const root_mod = b.createModule(.{
            .root_source_file = b.path(example_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add module imports for example 10
        if (std.mem.eql(u8, example_name, "10_example_10")) {
            root_mod.addImport("benchmark", benchmark_mod);
        }

        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = root_mod,
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
        const test_mod = b.createModule(.{
            .root_source_file = b.path(test_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add snaptest module for example 11
        if (std.mem.eql(u8, test_name, "11_example_11")) {
            test_mod.addImport("snaptest", snaptest_mod);
        }

        const test_exe = b.addTest(.{
            .root_module = test_mod,
        });
        test_step.dependOn(&b.addRunArtifact(test_exe).step);
    }
}
