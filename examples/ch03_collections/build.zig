const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
        "01_managed_vs_unmanaged_arraylist",
        "02_hashmap_ownership_patterns",
        "03_nested_container_cleanup_with_errdefer",
        "04_ownership_transfer_with_toownedslice",
        "05_container_reuse_with_clearretainingcapacity",
        "06_hashmap_vs_arrayhashmap_performance",
    };

    // Build all examples
    inline for (examples) |example_name| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        // Add run step for each example
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
        run_step.dependOn(&run_cmd.step);
    }

    // Global test step
    const test_step = b.step("test", "Run all tests");
    _ = test_step;
}
