// Example 3: Example 3
// 08 Build System
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // program name

    var output_path: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--output")) {
            output_path = args.next();
        }
    }

    const path = output_path orelse return error.MissingOutputPath;

    const code =
        \\// Auto-generated file - do not edit
        \\pub const magic_number: u32 = 42;
        \\pub const greeting = "Hello from generated code!";
        \\
    ;

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(code);
}