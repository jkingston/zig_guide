// Example 1: Example 1
// 01 Introduction
//
// Extracted from chapter content.md

const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}