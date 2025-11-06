// Example 11: Example 11
// 12 Testing Benchmarking
//
// Extracted from chapter content.md

const std = @import("std");
const Snap = @import("snaptest.zig").Snap;
const snap = Snap.snap_fn("src");

fn complexComputation() i32 {
    return 42;
}

test "complex output" {
    const result = complexComputation();
    try snap(@src(),
        \\Expected output line 1
        \\Expected output line 2
    ).diff_fmt("{}", .{result});
}