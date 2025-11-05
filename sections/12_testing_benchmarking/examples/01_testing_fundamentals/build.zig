const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Executable
    const exe = b.addExecutable(.{
        .name = "testing_fundamentals",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the testing fundamentals demo");
    run_step.dependOn(&run_cmd.step);

    // Tests
    // Test main.zig (imports other modules, so tests all of them)
    const main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    // Test math.zig separately
    const math_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/math.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_math_tests = b.addRunArtifact(math_tests);

    // Test string_utils.zig separately
    const string_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/string_utils.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_string_tests = b.addRunArtifact(string_tests);

    // Test step that runs all tests
    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&run_main_tests.step);
    test_step.dependOn(&run_math_tests.step);
    test_step.dependOn(&run_string_tests.step);
}
