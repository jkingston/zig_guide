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

    // Generate code
    const code =
        \\// Auto-generated file - do not edit
        \\const std = @import("std");
        \\
        \\pub const magic_number: u32 = 42;
        \\pub const greeting = "Hello from generated code!";
        \\
        \\pub fn getMessage() []const u8 {
        \\    return greeting;
        \\}
        \\
    ;

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(code);

    std.debug.print("Generated code at: {s}\n", .{path});
}
