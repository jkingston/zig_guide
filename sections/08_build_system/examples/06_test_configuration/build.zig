const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match filter",
    ) orelse &.{};

    // Library module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Unit tests
    const unit_tests = b.addTest(.{
        .name = "unit-tests",
        .root_module = lib_mod,
        .filters = test_filters,
    });

    // Integration tests
    const integration_tests = b.addTest(.{
        .name = "integration-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/integration.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .filters = test_filters,
    });

    // Test steps
    const test_step = b.step("test", "Run all tests");
    const unit_step = b.step("test:unit", "Run unit tests");
    const integration_step = b.step("test:integration", "Run integration tests");

    const run_unit = b.addRunArtifact(unit_tests);
    const run_integration = b.addRunArtifact(integration_tests);

    // Don't cache results when filtering
    if (test_filters.len > 0) {
        run_unit.has_side_effects = true;
        run_integration.has_side_effects = true;
    }

    unit_step.dependOn(&run_unit.step);
    integration_step.dependOn(&run_integration.step);
    test_step.dependOn(&run_unit.step);
    test_step.dependOn(&run_integration.step);
}
