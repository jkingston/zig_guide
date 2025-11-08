const std = @import("std");

// Wrapper build file for CI validation of the zighttp project
// This allows CI to discover and build the nested zighttp example

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load zighttp as a local dependency
    // This automatically reads zighttp/build.zig.zon and fetches its dependencies (zig-clap)
    const zighttp_dep = b.dependency("zighttp", .{
        .target = target,
        .optimize = optimize,
    });

    // Install the zighttp executable from the dependency
    const zighttp_artifact = zighttp_dep.artifact("zighttp");
    b.installArtifact(zighttp_artifact);

    // Create a run step
    const run_cmd = b.addRunArtifact(zighttp_artifact);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the zighttp CLI");
    run_step.dependOn(&run_cmd.step);
}
