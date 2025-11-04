const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("advanced", .{
        .root_source_file = b.path("src/advanced.zig"),
        .target = target,
        .optimize = optimize,
    });
}
