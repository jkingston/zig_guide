# Example 1: Simple Build.zig Migration

This example demonstrates the most basic but critical migration: updating `build.zig` to use the required `root_module` field in Zig 0.15.2.

## What Changed

In Zig 0.15.2, the `root_module` field became **required** (not optional) in `addExecutable()`, `addTest()`, and `addLibrary()`. All deprecated convenience fields were removed.

### Key Changes

1. **root_module required**: Must use `b.createModule()` to create module explicitly
2. **Deprecated fields removed**: `root_source_file`, `target`, `optimize` no longer accepted directly
3. **Configuration moved**: Target and optimize settings now passed inside `createModule()`

## Migration Steps

1. **Identify the old pattern**:
   ```zig
   const exe = b.addExecutable(.{
       .name = "app",
       .root_source_file = b.path("src/main.zig"),
       .target = target,
       .optimize = optimize,
   });
   ```

2. **Wrap configuration in createModule()**:
   ```zig
   const exe = b.addExecutable(.{
       .name = "app",
       .root_module = b.createModule(.{
           .root_source_file = b.path("src/main.zig"),
           .target = target,
           .optimize = optimize,
       }),
   });
   ```

3. **Move target and optimize**: These parameters move from `addExecutable()` to `createModule()`

## Building and Running

### Zig 0.14.1 Version

```bash
cd 0.14.1
/path/to/zig-0.14.1/zig build run
```

Expected output:
```
Hello from Zig 0.14.1!
This example demonstrates basic build.zig migration.
```

### Zig 0.15.2 Version

```bash
cd 0.15.2
/path/to/zig-0.15.2/zig build run
```

Expected output:
```
Hello from Zig 0.15.2!
This example demonstrates basic build.zig migration.
```

## Common Errors

### Error 1: Missing root_module Field

```
error: missing struct field: root_module
    const exe = b.addExecutable(.{
                                 ^
```

**Solution**: Add `.root_module = b.createModule(...)`

### Error 2: No Field Named 'root_source_file'

```
error: no field named 'root_source_file' in struct 'std.Build.ExecutableOptions'
    .root_source_file = b.path("src/main.zig"),
    ^
```

**Solution**: Move `root_source_file` inside `createModule()`

### Error 3: No Field Named 'target'

```
error: no field named 'target' in struct 'std.Build.ExecutableOptions'
    .target = target,
    ^
```

**Solution**: Move `target` and `optimize` inside `createModule()`

## Why This Change?

- **Explicit module configuration**: Makes the module creation step explicit and visible
- **Better build graph analysis**: Build system can better analyze dependencies
- **Forward compatibility**: Prepares for future enhancements to the module system
- **Consistency**: All artifacts now created through the same pattern

## Next Steps

- See Example 2 for I/O migration patterns
- See Example 6 for library build.zig migration with modules
- Review Chapter 8 for more build system patterns

## Estimated Migration Time

**5 minutes per build.zig file**

Simple find-and-replace pattern once you understand the change.
