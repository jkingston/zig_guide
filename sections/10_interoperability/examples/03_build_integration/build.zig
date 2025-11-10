const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create wrapper module
    const wrapper_module = b.addModule("wrapper", .{
        .root_source_file = b.path("src/wrapper.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "build_integration",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "wrapper", .module = wrapper_module },
            },
        }),
    });

    // Add C source files to the build
    exe.addCSourceFiles(.{
        .files = &.{
            "c_lib/mylib.c",
        },
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-std=c99",
        },
    });

    // Add include directory for C headers
    exe.addIncludePath(b.path("c_lib"));

    // Link with C standard library
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the build integration example");
    run_step.dependOn(&run_cmd.step);
}
