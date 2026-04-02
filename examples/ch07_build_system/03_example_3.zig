// Example 3: Example 3
// 08 Build System
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .{ .backing_allocator = std.heap.smp_allocator };
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const io = init.io;
    var args_iter = std.process.Args.Iterator.init(init.minimal.args);
    _ = args_iter.next(); // program name

    var output_path: ?[]const u8 = null;
    while (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--output")) {
            output_path = args_iter.next();
        }
    }

    _ = allocator;

    const path = output_path orelse return error.MissingOutputPath;

    const code =
        \\// Auto-generated file - do not edit
        \\pub const magic_number: u32 = 42;
        \\pub const greeting = "Hello from generated code!";
        \\
    ;

    const cwd = std.Io.Dir.cwd();
    const file = try cwd.createFile(io, path, .{});
    defer file.close(io);

    try file.writeStreamingAll(io, code);
}
