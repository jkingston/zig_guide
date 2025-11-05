const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "cpp_bridge",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add C++ source files
    exe.addCSourceFiles(.{
        .files = &.{
            "cpp/MyCppClass.cpp",
            "cpp/c_bridge.cpp",
        },
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-std=c++17",
        },
    });

    // Add include directory
    exe.addIncludePath(b.path("cpp"));

    // Link with C and C++ standard libraries
    exe.linkLibC();
    exe.linkLibCpp();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the C++ bridge example");
    run_step.dependOn(&run_cmd.step);
}
