const std = @import("std");

pub fn build(b: *std.Build) void {
    // Discover all chapter example directories
    const example_chapters = [_][]const u8{
        "ch01_introduction",
        "ch02_idioms",
        "ch03_memory",
        "ch04_collections",
        "ch05_io",
        "ch06_errors",
        "ch07_async",
        "ch08_build_system",
        "ch09_packages_dependencies",
        "ch10_project_layout_ci",
        "ch11_interoperability",
        "ch12_testing_benchmarking",
        "ch13_logging_diagnostics",
        "ch14_migration_guide",
        "ch15_appendices",
    };

    // Build each chapter's examples
    inline for (example_chapters) |chapter| {
        // Create a step to build all examples for this chapter
        const chapter_step = b.step(chapter, "Build all examples for " ++ chapter);

        // For now, we delegate to chapter-specific build.zig files
        // Future: Could auto-discover .zig files and build them directly
        const chapter_build = b.addSystemCommand(&[_][]const u8{
            "zig",
            "build",
            "--build-file",
            "examples/" ++ chapter ++ "/build.zig",
        });

        chapter_step.dependOn(&chapter_build.step);
    }

    // Global test step - runs tests from all chapters
    const test_step = b.step("test", "Run all tests");

    // Add chapter tests
    inline for (example_chapters) |chapter| {
        const chapter_test = b.addSystemCommand(&[_][]const u8{
            "zig",
            "build",
            "test",
            "--build-file",
            "examples/" ++ chapter ++ "/build.zig",
        });
        test_step.dependOn(&chapter_test.step);
    }

    // Validation step - compile all examples to ensure they work
    const validate_step = b.step("validate", "Validate all examples compile");

    inline for (example_chapters) |chapter| {
        const chapter_validate = b.addSystemCommand(&[_][]const u8{
            "zig",
            "build",
            "--build-file",
            "examples/" ++ chapter ++ "/build.zig",
            "--summary",
            "all",
        });
        validate_step.dependOn(&chapter_validate.step);
    }

    // Default step
    b.default_step = b.step("all", "Build all examples");
    b.default_step.dependOn(validate_step);
}
