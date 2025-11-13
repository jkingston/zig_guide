# Chapter 3: Memory & Allocators - Examples

This directory contains runnable examples from Chapter 3 of Zig: Zero to Hero.

## Building Examples

Build all examples:
```bash
zig build
```

Run a specific example:
```bash
zig build run-01_allocator_interface
zig build run-02_arena_pattern
# etc...
```

## Examples Overview

| File | Description | Key Concepts |
|------|-------------|--------------|
| `01_allocator_interface.zig` | Core allocator interface demonstration | alloc, create, destroy, aligned allocation, leak detection |
| `02_arena_pattern.zig` | Arena allocator for request-scoped allocations | ArenaAllocator, bulk cleanup, reset |
| `03_fixed_buffer.zig` | FixedBufferAllocator for stack-based operations | Zero-syscall allocation, bounded memory |
| `04_errdefer_cleanup.zig` | Cascading errdefer for multi-step initialization | errdefer, error-path cleanup, resource safety |
| `05_allocator_selection.zig` | Choosing allocators based on use case | Allocator patterns, selection guide |

## Version Compatibility

All examples tested and verified on:
- ✅ Zig 0.15.2 (primary target)

### API Differences from Book

The examples have been updated for Zig 0.15.2 API changes:

- **Aligned allocation**: Use `std.mem.Alignment.fromByteUnits(N)` instead of integer literal
- **ArrayList**: Use `std.ArrayList(T){}` initialization and pass allocator to methods
- **Arena reset**: Use `.reset(.{ .retain_with_limit = N })` instead of `.reset()`

## Allocator Selection Guide

| Scenario | Recommended Allocator | Example |
|----------|----------------------|---------|
| Testing | `std.testing.allocator` | Automatic leak detection |
| Development | `GeneralPurposeAllocator` | Safety features, debugging |
| Request handling | `ArenaAllocator` | Bulk cleanup, scoped lifetime |
| Known max size | `FixedBufferAllocator` | No syscalls, bounded |
| Release builds | `c_allocator` | Performance |

## Related Book Sections

These examples correspond to code blocks in:
- Chapter 3, sections: "Allocator Interface", "Allocator Types", "Cleanup Idioms", "Code Examples"

## Key Patterns

### Memory Safety
- ✅ Pair allocation with immediate `defer` cleanup
- ✅ Use `errdefer` for multi-step initialization
- ✅ Always free with the same allocator used for allocation
- ✅ Use `GeneralPurposeAllocator` in development for leak detection

### Ownership
- **Caller-owns**: Function borrows memory, doesn't free it
- **Callee-returns**: Function allocates, caller must free
- **Init/deinit**: Struct manages lifetime with paired methods

### Performance
- Use `ArenaAllocator` for request-scoped allocations (no individual frees)
- Use `FixedBufferAllocator` for known-size, stack-based allocations
- Switch to `c_allocator` in release builds for maximum performance
