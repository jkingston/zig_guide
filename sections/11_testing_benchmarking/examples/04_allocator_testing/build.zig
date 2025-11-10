const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main executable
    const exe = b.addExecutable(.{
        .name = "allocator_testing_demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    // Create run step for the executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the allocator testing demo");
    run_step.dependOn(&run_cmd.step);

    // Create test executables for each module
    const buffer_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/buffer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const string_builder_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/string_builder.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const cache_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cache.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Run all tests
    const run_buffer_tests = b.addRunArtifact(buffer_tests);
    const run_string_builder_tests = b.addRunArtifact(string_builder_tests);
    const run_cache_tests = b.addRunArtifact(cache_tests);

    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&run_buffer_tests.step);
    test_step.dependOn(&run_string_builder_tests.step);
    test_step.dependOn(&run_cache_tests.step);

    // Individual test steps
    const buffer_test_step = b.step("test-buffer", "Run buffer tests");
    buffer_test_step.dependOn(&run_buffer_tests.step);

    const string_builder_test_step = b.step("test-string-builder", "Run string builder tests");
    string_builder_test_step.dependOn(&run_string_builder_tests.step);

    const cache_test_step = b.step("test-cache", "Run cache tests");
    cache_test_step.dependOn(&run_cache_tests.step);
}
