const std = @import("std");

pub fn build(b: *std.Build) void {
    // WASI target
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "wasi_filesystem",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    // Note: To run this, you need a WASI runtime like wasmtime
    // Run with: wasmtime --dir=. ./zig-out/bin/wasi_filesystem.wasm
}
