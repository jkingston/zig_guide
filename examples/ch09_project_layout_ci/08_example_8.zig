// Example 8: Example 8
// 10 Project Layout Ci
//
// Extracted from chapter content.md

const std = @import("std");
const core = @import("core");

pub fn main() !void {
    var buf: [256]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&buf);

    try stdout.interface.print("Workspace App v{}\n", .{core.version});
    try core.greet(&stdout.interface, "Workspace");

    const result = core.calculate(10, 5);
    try stdout.interface.print("Calculate(10, 5) = {d}\n", .{result});
    try stdout.interface.flush();
}

test "app uses core correctly" {
    const result = core.calculate(10, 5);
    try std.testing.expectEqual(@as(i32, 25), result);
}