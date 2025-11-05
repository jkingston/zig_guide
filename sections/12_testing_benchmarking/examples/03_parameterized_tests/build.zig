const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================================================================
    // Executable
    // ========================================================================

    const exe = b.addExecutable(.{
        .name = "parameterized_tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
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

    const run_step = b.step("run", "Run the parameterized tests demo");
    run_step.dependOn(&run_cmd.step);

    // ========================================================================
    // Tests
    // ========================================================================

    // Main tests
    const main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Calculator tests
    const calculator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/calculator.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Parser tests
    const parser_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/parser.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Validator tests
    const validator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/validator.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Run all tests
    const run_main_tests = b.addRunArtifact(main_tests);
    const run_calculator_tests = b.addRunArtifact(calculator_tests);
    const run_parser_tests = b.addRunArtifact(parser_tests);
    const run_validator_tests = b.addRunArtifact(validator_tests);

    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&run_main_tests.step);
    test_step.dependOn(&run_calculator_tests.step);
    test_step.dependOn(&run_parser_tests.step);
    test_step.dependOn(&run_validator_tests.step);
}
