const std = @import("std");
const Config = @import("config.zig").Config;
const Processor = @import("processor.zig").Processor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ✅ 0.15+: stdout requires buffer, access via .interface
    var stdout_buf: [512]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);

    try stdout.interface.print("Text Processor v0.15\n", .{});
    try stdout.interface.print("====================\n\n", .{});
    try stdout.interface.flush();

    // Load configuration
    var config = try Config.init(allocator);
    defer config.deinit();

    try config.addPattern("TODO");
    try config.addPattern("FIXME");
    try config.addPattern("NOTE");

    try stdout.interface.print("Loaded {d} search patterns\n", .{config.patterns.items.len});
    try stdout.interface.flush();

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
    try stdout.interface.print("Found {d} matches\n\n", .{matches});
    try stdout.interface.flush();

    // Write results to file
    const output_file = try std.fs.cwd().createFile("results_015.txt", .{});
    defer output_file.close();

    var file_buf: [4096]u8 = undefined;
    var file_writer = output_file.writer(&file_buf);

    try file_writer.interface.print("Search Results\n", .{});
    try file_writer.interface.print("==============\n", .{});
    try file_writer.interface.print("Patterns: ", .{});
    for (config.patterns.items, 0..) |pattern, i| {
        if (i > 0) try file_writer.interface.print(", ", .{});
        try file_writer.interface.print("{s}", .{pattern});
    }
    try file_writer.interface.print("\nMatches found: {d}\n", .{matches});
    try file_writer.interface.flush(); // CRITICAL: flush before close

    try stdout.interface.print("Results written to results_015.txt\n", .{});
    try stdout.interface.flush();
}
