const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add log level option for compile-time filtering
    const log_level_option = b.option(
        std.log.Level,
        "log-level",
        "Set the log level (err, warn, info, debug)",
    );

    const exe = b.addExecutable(.{
        .name = "basic_logging",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Configure log level if specified
    if (log_level_option) |log_level| {
        const options = b.addOptions();
        options.addOption(std.log.Level, "log_level", log_level);
        exe.root_module.addOptions("build_options", options);
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the basic logging example");
    run_step.dependOn(&run_cmd.step);
}
