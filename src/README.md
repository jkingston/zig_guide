# Zig Developer Guide

A comprehensive guide to Zig development focused on idioms and best practices for **Zig 0.14.x and 0.15.x**.

## About This Guide

This guide teaches practical Zig idioms and best practices for developers using Zig 0.14.0, 0.14.1, 0.15.1, or 0.15.2. Most patterns work identically across all supported versions. When they differ, version markers clearly indicate which code applies to which version.

**Who This Guide Is For:**
- Systems programmers learning Zig from C, C++, or Rust backgrounds
- Developers building Zig applications on 0.14.x or 0.15.x
- Teams evaluating Zig for production use
- Contributors to Zig open-source projects

**This guide assumes:**
- Prior systems programming experience
- Familiarity with basic programming concepts
- Understanding of memory management principles

## Version Markers

Throughout this guide, you'll see version markers indicating compatibility:

- **🕐 0.14.x** — Code specific to Zig 0.14.0 and 0.14.1
- **✅ 0.15+** — Code specific to Zig 0.15.1 and later
- **No marker** — Code that works in all supported versions

## What You'll Learn

This guide covers 15 comprehensive chapters spanning:

1. **Foundations**: Language idioms, memory management, and core patterns
2. **Data & I/O**: Collections, containers, streams, and formatting
3. **Error Handling**: Error sets, cleanup strategies, and resource management
4. **Concurrency**: Async patterns, threading, and performance optimization
5. **Build System**: build.zig, packages, dependencies, and cross-compilation
6. **Interoperability**: Working with C, C++, WASI, and WebAssembly
7. **Quality**: Testing, benchmarking, profiling, and diagnostics
8. **Migration**: Practical guide for upgrading from 0.14.x to 0.15.x

## Code Examples

All code examples are runnable and tested. You can find the complete source code examples in the [GitHub repository](https://github.com/jkingston/zig_guide).

---

Ready to get started? Head to the [Introduction](ch01_introduction.md) or choose a specific chapter from the navigation menu.
