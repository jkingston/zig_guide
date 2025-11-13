# Chapter 2: Language Idioms & Core Patterns - Examples

This directory contains runnable examples from Chapter 2 of Zig: Zero to Hero.

## Building Examples

Build all examples:
```bash
zig build
```

Run a specific example:
```bash
zig build run-01_naming_conventions
zig build run-02_defer_order
# etc...
```

Run tests:
```bash
zig build test
```

## Examples Overview

| File | Description | Key Concepts |
|------|-------------|--------------|
| `01_naming_conventions.zig` | Demonstrates PascalCase, camelCase, and snake_case naming | Naming conventions, type vs value functions |
| `02_defer_order.zig` | Shows LIFO execution order of defer statements | defer, execution order |
| `03_resource_cleanup.zig` | Resource acquisition with deferred cleanup | defer, file I/O, memory management |
| `04_errdefer.zig` | Partial failure cleanup with errdefer | errdefer, error handling, memory safety |
| `05_generic_function.zig` | Generic functions using comptime type parameters | comptime, generics, zero-cost abstractions |
| `06_copy_file.zig` | Combining defer with error handling (Example 1) | defer, error handling, file I/O |
| `07_generic_stack.zig` | Generic data structure implementation (Example 3) | comptime, generics, data structures |
| `08_defer_in_loops_wrong.zig` | ❌ WRONG: defer in loops (pitfall demonstration) | defer pitfalls, resource leaks |
| `09_defer_in_loops_correct.zig` | ✅ CORRECT: defer in loops with nested blocks | defer, scoping, best practices |

## Version Compatibility

All examples tested and verified on:
- ✅ Zig 0.15.2 (primary target)

### API Differences from Book

The examples have been updated for Zig 0.15.2 API changes:

- **ArrayList API**: `append()` now requires an allocator parameter
- **ArrayList initialization**: Use `std.ArrayList(T){}` instead of `.init()`
- **Build system**: Use `.root_module` with `createModule()` instead of `.root_source_file`

## Related Book Sections

These examples correspond to code blocks in:
- Chapter 2, sections: "Naming Conventions", "defer and errdefer", "comptime Fundamentals", "Common Pitfalls"

## Notes

- Examples 08 and 09 demonstrate the correct and incorrect way to use defer in loops
- Example 07 (generic stack) showcases proper allocator management in generic data structures
- All examples include cleanup code to avoid side effects
