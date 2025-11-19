# Zig 0.15.2 API Review Findings

**Review Date:** 2025-11-19
**Reviewer:** Senior Staff Engineer
**Scope:** All code examples and CLI arguments in the Zig Guide

## Summary

Found **18+ issues** requiring fixes across markdown documentation and Zig source files.

## Critical Issues

### 1. Backwards Migration Instruction (HIGH PRIORITY)

**File:** `src/ch06_io_streams.md:4`
**Issue:** Migration direction is BACKWARDS
**Current:** "Use `std.io.getStdOut()` instead of `std.fs.File.stdout()`"
**Correct:** "Use `std.fs.File.stdout()` instead of `std.io.getStdOut()`"

### 2. Old I/O API in Documentation (MEDIUM PRIORITY)

**Affected Files:**
- `src/ch11_project_layout_ci.md:1385` - Uses `std.io.getStdOut().writer()`
- `src/ch12_interoperability.md:1605` - Uses `std.io.getStdOut().writer()`
- `src/ch13_testing_benchmarking.md:1728` - Uses `std.io.getStdOut().writer()`

**Issue:** Code examples use deprecated 0.14 API instead of 0.15.2 API

**Should be:**
```zig
const stdout = std.fs.File.stdout();
var buf: [256]u8 = undefined;
var writer = stdout.writer(&buf);
try writer.interface.print(...);
try writer.interface.flush();
```

### 3. ArrayList Initialization Issues (MEDIUM PRIORITY)

**Issue:** Using `std.ArrayList(T){}` instead of `std.ArrayList(T).empty`

**Affected Files:**
1. `examples/ch01_idioms/07_generic_stack.zig:17`
2. `examples/ch02_memory/02_arena_pattern.zig:10`
3. `examples/ch03_collections/01_managed_vs_unmanaged.zig:10`
4. `examples/ch03_collections/01_managed_vs_unmanaged.zig:29`
5. `examples/ch03_collections/01_managed_vs_unmanaged_arraylist.zig:15`
6. `examples/ch03_collections/01_managed_vs_unmanaged_arraylist.zig:34`
7. `examples/ch03_collections/03_nested_cleanup.zig:13`
8. `examples/ch03_collections/03_nested_cleanup.zig:30`
9. `examples/ch03_collections/03_nested_container_cleanup_with_errdefer.zig:18`
10. `examples/ch03_collections/03_nested_container_cleanup_with_errdefer.zig:35`
11. `examples/ch03_collections/04_ownership_transfer.zig:4`
12. `examples/ch03_collections/04_ownership_transfer.zig:19`
13. `examples/ch03_collections/04_ownership_transfer_with_toownedslice.zig:9`
14. `examples/ch03_collections/04_ownership_transfer_with_toownedslice.zig:24`
15. `examples/ch03_collections/05_container_reuse_with_clearretainingcapacity.zig:15`
16. `examples/ch05_errors/03_allocator_error_handling.zig:31`
17. `examples/ch11_testing_benchmarking/08_parameterized_tests.zig:53`
18. `examples/ch13_migration_guide/03_arraylist_migration.zig:13`
19. `examples/ch13_migration_guide/04_example_4.zig:13`

**Fix Required:**
```zig
// Current (works but not idiomatic)
var list = std.ArrayList(u32){};

// Correct (0.15.2 idiomatic)
var list = std.ArrayList(u32).empty;
```

## Verified Correct

✅ **Build System APIs** - All `build.zig` files correctly use `.root_module = b.createModule(...)`
✅ **Standard Library APIs** - All other std.* calls verified against Zig 0.15.2 source
✅ **Builtin Functions** - All @* builtins verified to exist in 0.15.2
✅ **CLI Commands** - zig build, zig run, zig test commands correctly documented
✅ **File I/O** - std.fs.cwd(), file.close(), etc. all correct
✅ **fixedBufferStream** - std.io.fixedBufferStream() is correct API

## Notes

- The `.empty` pattern is more explicit and matches Zig 0.15.2's stdlib tests
- While `{}` technically works, `.empty` is the documented pattern in stdlib
- All build.zig files are already correct for 0.15.2
- No actual .zig source files use the old I/O API (issues only in markdown docs)
