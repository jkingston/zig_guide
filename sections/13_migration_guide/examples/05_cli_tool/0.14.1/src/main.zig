const std = @import("std");
const Config = @import("config.zig").Config;
const Processor = @import("processor.zig").Processor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 🕐 0.14.x: stdout uses old I/O API
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Text Processor v0.14\n", .{});
    try stdout.print("====================\n\n", .{});

    // Load configuration
    var config = try Config.init(allocator);
    defer config.deinit();

    try config.addPattern("TODO");
    try config.addPattern("FIXME");
    try config.addPattern("NOTE");

    try stdout.print("Loaded {d} search patterns\n", .{config.patterns.items.len});

    // Process text
    var processor = Processor.init(allocator);
    defer processor.deinit();

    const sample_text =
        \\TODO: Implement feature X
        \\This is regular text
        \\FIXME: Bug in module Y
        \\NOTE: Remember to update docs
    ;

    const matches = try processor.findMatches(sample_text, config.patterns.items);
    try stdout.print("Found {d} matches\n\n", .{matches});

    // Write results to file
    const output_file = try std.fs.cwd().createFile("results_014.txt", .{});
    defer output_file.close();

    const file_writer = output_file.writer();
    try file_writer.print("Search Results\n", .{});
    try file_writer.print("==============\n", .{});
    try file_writer.print("Patterns: ", .{});
    for (config.patterns.items, 0..) |pattern, i| {
        if (i > 0) try file_writer.print(", ", .{});
        try file_writer.print("{s}", .{pattern});
    }
    try file_writer.print("\nMatches found: {d}\n", .{matches});

    try stdout.print("Results written to results_014.txt\n", .{});
}
