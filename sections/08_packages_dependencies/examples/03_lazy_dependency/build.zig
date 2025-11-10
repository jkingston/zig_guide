const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // User option to enable advanced features
    const enable_advanced = b.option(
        bool,
        "advanced",
        "Enable advanced math features",
    ) orelse false;

    // Build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "advanced_enabled", enable_advanced);

    // Basic dependency (always loaded)
    const basic_dep = b.dependency("basic_math", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "build_options", .module = build_options.createModule() },
                .{ .name = "basic_math", .module = basic_dep.module("basic") },
            },
        }),
    });

    // Advanced dependency (lazy - only if enabled)
    if (enable_advanced) {
        if (b.lazyDependency("advanced_math", .{
            .target = target,
            .optimize = optimize,
        })) |advanced_dep| {
            exe.root_module.addImport("advanced_math", advanced_dep.module("advanced"));
        }
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&b.addRunArtifact(exe).step);
}
