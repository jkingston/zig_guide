const std = @import("std");

pub fn build(b: *std.Build) void {
    // Define target platforms for cross-compilation
    const targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .wasm32, .os_tag = .wasi },
    };

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    // Build for all targets
    inline for (targets) |target_query| {
        const target = b.resolveTargetQuery(target_query);

        const exe = b.addExecutable(.{
            .name = "crossapp",
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Generate target-specific binary names
        const target_output = b.fmt(
            "crossapp-{s}-{s}{s}",
            .{
                @tagName(target.result.cpu.arch),
                @tagName(target.result.os.tag),
                if (target.result.os.tag == .windows) ".exe" else "",
            },
        );

        // Install with target-specific name
        const install_step = b.addInstallArtifact(exe, .{
            .dest_sub_path = target_output,
        });
        b.getInstallStep().dependOn(&install_step.step);
    }

    // Native build for local testing
    const native_target = b.standardTargetOptions(.{});
    const native_exe = b.addExecutable(.{
        .name = "crossapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = native_target,
            .optimize = optimize,
        }),
    });

    // Run step for native binary
    const run_cmd = b.addRunArtifact(native_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the native app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{
        .root_module = native_exe.root_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
