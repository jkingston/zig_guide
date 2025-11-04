const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build the core library
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });
    const core_mod = core_dep.module("core");

    // Build the app executable using core
    const app_exe = b.addExecutable(.{
        .name = "workspace-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("packages/app/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "core", .module = core_mod },
            },
        }),
    });
    b.installArtifact(app_exe);

    // Run step
    const run_cmd = b.addRunArtifact(app_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Test step for all packages
    const test_step = b.step("test", "Run all tests");

    // Test core
    const core_tests = b.addTest(.{
        .root_module = core_mod,
    });
    const run_core_tests = b.addRunArtifact(core_tests);
    test_step.dependOn(&run_core_tests.step);

    // Test app
    const app_tests = b.addTest(.{
        .root_module = app_exe.root_module,
    });
    const run_app_tests = b.addRunArtifact(app_tests);
    test_step.dependOn(&run_app_tests.step);
}
