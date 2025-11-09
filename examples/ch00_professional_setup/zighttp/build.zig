const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Fetch dependencies
    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    // Library module for external consumption
    const lib = b.addLibrary(.{
        .name = "libzighttp",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    lib.root_module.addImport("clap", clap.module("clap"));
    b.installArtifact(lib);

    // CLI executable
    const exe = b.addExecutable(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("clap", clap.module("clap"));
    b.installArtifact(exe);

    // Run step for the CLI
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Pass arguments from command line
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the zighttp CLI");
    run_step.dependOn(&run_cmd.step);

    // Unit tests for the library
    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    lib_unit_tests.root_module.addImport("clap", clap.module("clap"));

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Unit tests for individual modules
    const modules = [_][]const u8{
        "args",
        "http_client",
        "json_formatter",
    };

    inline for (modules) |module_name| {
        const module_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/" ++ module_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        module_tests.root_module.addImport("clap", clap.module("clap"));

        const run_module_tests = b.addRunArtifact(module_tests);
        run_lib_unit_tests.step.dependOn(&run_module_tests.step);
    }

    // Integration tests
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/integration_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Give integration tests access to the library and dependencies
    integration_tests.root_module.addImport("zighttp", lib.root_module);
    integration_tests.root_module.addImport("clap", clap.module("clap"));

    const run_integration_tests = b.addRunArtifact(integration_tests);

    // Test step that runs all tests
    const test_step = b.step("test", "Run all unit and integration tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);

    // Separate step for just unit tests
    const unit_test_step = b.step("test-unit", "Run unit tests only");
    unit_test_step.dependOn(&run_lib_unit_tests.step);

    // Separate step for just integration tests
    const integration_test_step = b.step("test-integration", "Run integration tests only");
    integration_test_step.dependOn(&run_integration_tests.step);
}
