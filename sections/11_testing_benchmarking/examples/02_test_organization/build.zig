const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================================================================
    // Executable
    // ========================================================================

    // Create shared modules for test imports
    const database_module = b.createModule(.{
        .root_source_file = b.path("src/database.zig"),
        .target = target,
        .optimize = optimize,
    });

    const api_module = b.createModule(.{
        .root_source_file = b.path("src/api.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "database", .module = database_module },
        },
    });

    const exe = b.addExecutable(.{
        .name = "test-organization-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "database", .module = database_module },
                .{ .name = "api", .module = api_module },
            },
        }),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the demo application");
    run_step.dependOn(&run_cmd.step);

    // ========================================================================
    // Tests - Organized by Module
    // ========================================================================

    // Create a test step that runs all tests
    const test_step = b.step("test", "Run all tests");

    const test_helpers_module = b.createModule(.{
        .root_source_file = b.path("tests/test_helpers.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "database", .module = database_module },
            .{ .name = "api", .module = api_module },
        },
    });

    // Database unit tests
    const database_tests = b.addTest(.{
        .name = "database-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/database_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "database", .module = database_module },
                .{ .name = "test_helpers", .module = test_helpers_module },
            },
        }),
    });

    const run_database_tests = b.addRunArtifact(database_tests);
    test_step.dependOn(&run_database_tests.step);

    // API unit tests
    const api_tests = b.addTest(.{
        .name = "api-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/api_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "database", .module = database_module },
                .{ .name = "api", .module = api_module },
                .{ .name = "test_helpers", .module = test_helpers_module },
            },
        }),
    });

    const run_api_tests = b.addRunArtifact(api_tests);
    test_step.dependOn(&run_api_tests.step);

    // Integration tests
    const integration_tests = b.addTest(.{
        .name = "integration-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "database", .module = database_module },
                .{ .name = "api", .module = api_module },
                .{ .name = "test_helpers", .module = test_helpers_module },
            },
        }),
    });

    const run_integration_tests = b.addRunArtifact(integration_tests);
    test_step.dependOn(&run_integration_tests.step);

    // ========================================================================
    // Individual Test Steps (optional, for running specific test suites)
    // ========================================================================

    const test_database_step = b.step("test-database", "Run database tests only");
    test_database_step.dependOn(&run_database_tests.step);

    const test_api_step = b.step("test-api", "Run API tests only");
    test_api_step.dependOn(&run_api_tests.step);

    const test_integration_step = b.step("test-integration", "Run integration tests only");
    test_integration_step.dependOn(&run_integration_tests.step);
}
