const std = @import("std");
const core = @import("core");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Workspace App v{}\n", .{core.version});
    try core.greet(stdout, "Workspace");

    const result = core.calculate(10, 5);
    try stdout.print("Calculate(10, 5) = {d}\n", .{result});
}

test "app uses core correctly" {
    const result = core.calculate(10, 5);
    try std.testing.expectEqual(@as(i32, 25), result);
}
