const std = @import("std");

pub fn build(b: *std.Build) void {
    // WASM target - freestanding means no OS
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "wasm_js_ffi",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // WASM-specific settings
    exe.entry = .disabled; // No main entry point for WASM library
    exe.rdynamic = true; // Export symbols

    b.installArtifact(exe);
}
