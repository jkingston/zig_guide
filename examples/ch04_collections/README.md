# 04 Collections Containers - Examples

This directory contains runnable examples extracted from 04 Collections Containers.

## Building Examples

Build all examples:
```bash
zig build
```

Run a specific example:
```bash
zig build run-01_managed_vs_unmanaged_arraylist
# etc...
```

## Examples Overview

| File | Description | Lines | Source |
|------|-------------|-------|--------|
| `01_managed_vs_unmanaged_arraylist.zig` | Managed vs Unmanaged ArrayList | 41 | Lines 327-369 |
| `02_hashmap_ownership_patterns.zig` | HashMap Ownership Patterns | 76 | Lines 375-452 |
| `03_nested_container_cleanup_with_errdefer.zig` | Nested Container Cleanup with errdefer | 87 | Lines 458-546 |
| `04_ownership_transfer_with_toownedslice.zig` | Ownership Transfer with toOwnedSlice | 70 | Lines 552-623 |
| `05_container_reuse_with_clearretainingcapacity.zig` | Container Reuse with clearRetainingCapacity | 58 | Lines 629-688 |
| `06_hashmap_vs_arrayhashmap_performance.zig` | HashMap vs ArrayHashMap Performance | 54 | Lines 694-749 |

## Version Compatibility

All examples tested and verified on:
- ✅ Zig 0.15.2 (primary target)

## Related Book Sections

These examples correspond to code blocks in the chapter's content.md file.
