const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 🕐 0.14.x: Export library module (old syntax)
    _ = b.addModule("mathlib", .{
        .root_source_file = b.path("src/mathlib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Example executable using the library
    const example = b.addExecutable(.{
        .name = "mathlib_example",
        .root_source_file = b.path("examples/usage.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Import the library
    const mathlib_mod = b.createModule(.{
        .root_source_file = b.path("src/mathlib.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("mathlib", mathlib_mod);

    b.installArtifact(example);

    const run_cmd = b.addRunArtifact(example);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);
}
