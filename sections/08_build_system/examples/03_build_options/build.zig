const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // User-configurable options
    const enable_logging = b.option(bool, "logging", "Enable debug logging") orelse false;
    const max_connections = b.option(u32, "max-connections", "Maximum connections") orelse 100;

    // Build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "enable_logging", enable_logging);
    build_options.addOption(u32, "max_connections", max_connections);
    build_options.addOption([]const u8, "version", "1.0.0");

    const exe = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "build_options", .module = build_options.createModule() },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the server");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
