const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        "01_example_1",
        "02_example_2",
        "03_example_3",
    };

    // Create build_options module for examples that need it
    const build_options_mod = b.createModule(.{
        .root_source_file = b.path("build_options.zig"),
    });

    // Build all examples
    inline for (examples) |example_name| {
        const root_mod = b.createModule(.{
            .root_source_file = b.path(example_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add build_options module for examples 1 and 2
        if (std.mem.eql(u8, example_name, "01_example_1") or
            std.mem.eql(u8, example_name, "02_example_2")) {
            root_mod.addImport("build_options", build_options_mod);
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
    _ = test_step;
}
