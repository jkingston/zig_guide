const std = @import("std");

const ReleaseTarget = struct {
    arch: std.Target.Cpu.Arch,
    os: std.Target.Os.Tag,
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const release_targets = [_]ReleaseTarget{
        .{ .arch = .x86_64, .os = .linux },
        .{ .arch = .x86_64, .os = .windows },
        .{ .arch = .aarch64, .os = .linux },
        .{ .arch = .aarch64, .os = .macos },
    };

    const release_step = b.step("release", "Build for all release targets");

    for (release_targets) |rt| {
        const target = b.resolveTargetQuery(.{
            .cpu_arch = rt.arch,
            .os_tag = rt.os,
        });

        const exe = b.addExecutable(.{
            .name = b.fmt("myapp-{s}-{s}", .{
                @tagName(rt.arch),
                @tagName(rt.os),
            }),
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        const install = b.addInstallArtifact(exe, .{});
        release_step.dependOn(&install.step);
    }

    // Default single-target build
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
