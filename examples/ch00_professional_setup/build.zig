const std = @import("std");

// This is a wrapper build file for CI validation
// The actual zighttp project lives in ./zighttp/ subdirectory
// This wrapper ensures the CI can discover and build the chapter examples

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Fetch dependencies (needed for zighttp which uses zig-clap)
    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    // ===== zighttp Project =====

    // Library
    const zighttp_lib = b.addStaticLibrary(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zighttp/src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    zighttp_lib.root_module.addImport("clap", clap.module("clap"));
    b.installArtifact(zighttp_lib);

    // Executable
    const zighttp_exe = b.addExecutable(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zighttp/src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    zighttp_exe.root_module.addImport("clap", clap.module("clap"));
    b.installArtifact(zighttp_exe);

    // Run step
    const run_cmd = b.addRunArtifact(zighttp_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the zighttp CLI");
    run_step.dependOn(&run_cmd.step);

    // ===== Tests =====

    const test_step = b.step("test", "Run all tests");

    // Library tests
    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("zighttp/src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    lib_unit_tests.root_module.addImport("clap", clap.module("clap"));
    test_step.dependOn(&b.addRunArtifact(lib_unit_tests).step);

    // Module tests
    const modules = [_][]const u8{
        "args",
        "http_client",
        "json_formatter",
    };

    inline for (modules) |module_name| {
        const module_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("zighttp/src/" ++ module_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        module_tests.root_module.addImport("clap", clap.module("clap"));
        test_step.dependOn(&b.addRunArtifact(module_tests).step);
    }

    // Integration tests
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("zighttp/tests/integration_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    integration_tests.root_module.addImport("zighttp", &zighttp_lib.root_module);
    integration_tests.root_module.addImport("clap", clap.module("clap"));
    test_step.dependOn(&b.addRunArtifact(integration_tests).step);
}
