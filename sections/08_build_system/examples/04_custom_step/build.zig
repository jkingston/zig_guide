const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Code generator executable (runs on host)
    const gen_exe = b.addExecutable(.{
        .name = "codegen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/gen.zig"),
            .target = b.graph.host, // Build for host system
            .optimize = .Debug,
        }),
    });

    // Run the generator
    const gen_run = b.addRunArtifact(gen_exe);
    gen_run.addArg("--output");
    const generated_file = gen_run.addOutputFileArg("generated.zig");

    // Main executable using generated code
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add generated file as anonymous import
    exe.root_module.addAnonymousImport("generated", .{
        .root_source_file = generated_file,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
