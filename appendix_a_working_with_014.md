# Appendix A: Working with Zig 0.14.1

> **Quick reference for adapting book examples to Zig 0.14.1 codebases**

---

## About This Appendix

**This book teaches Zig 0.15.2.** If you're working with an existing Zig 0.14.1 codebase, this appendix shows you how to adapt the book's examples to your version.

**Recommendation:** Upgrade to Zig 0.15.2 (2-4h migration). See Appendix B for full migration guide.

---

## Key Differences

The book shows 0.15.2 patterns. Here are the 0.14.1 equivalents:

### Build System (Chapter 9)

**Book shows (0.15.2):**
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

**0.14.1 equivalent:**
```zig
const exe = b.addExecutable(.{
    .name = "app",
    .root_source_file = b.path("src/main.zig"),
    .target = target,      // At top level, not in module
    .optimize = optimize,  // At top level, not in module
});
```

**Key difference:** 0.14 doesn't require `root_module` wrapper.

---

### I/O and Writers (Chapter 6)

**Book shows (0.15.2):**
```zig
const stdout = std.fs.File.stdout();
var buf: [256]u8 = undefined;
var writer = stdout.writer(&buf);
try writer.interface.print("Hello\n", .{});
try writer.interface.flush();
```

**0.14.1 equivalent:**
```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Hello\n", .{});
// No buffer needed, no flush needed
```

**Key differences:**
1. Location: `std.io.getStdOut()` vs `std.fs.File.stdout()`
2. No buffer parameter in 0.14
3. No `.interface` accessor
4. No manual `flush()` required

---

### ArrayList (Chapter 5)

**Book shows (0.15.2):**
```zig
var list = std.ArrayList(u32).empty;
defer list.deinit(allocator);

try list.append(allocator, 42);
try list.appendSlice(allocator, &[_]u32{1, 2, 3});
```

**0.14.1 equivalent:**
```zig
var list = std.ArrayList(u32).init(allocator);
defer list.deinit();  // No allocator parameter

try list.append(42);  // No allocator parameter
try list.appendSlice(&[_]u32{1, 2, 3});  // No allocator parameter
```

**Key difference:** 0.14 stores allocator in container (managed).

---

### HashMap (Chapter 5)

**Book shows (0.15.2):**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit(allocator);  // Pass allocator

try map.put(allocator, 1, "one");  // Pass allocator
const value = map.get(1);
```

**0.14.1 equivalent:**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();  // No allocator parameter

try map.put(1, "one");  // No allocator parameter
const value = map.get(1);
```

**Key difference:** Same as ArrayList - 0.14 stores allocator.

---

## Translation Guide

When reading book examples, mentally apply these transformations:

### Build System

| Book (0.15.2) | 0.14.1 |
|---------------|--------|
| `.root_module = b.createModule(.{...})` | *(Remove wrapper)* |
| Inside `createModule`: `target`, `optimize` | At top level: `target`, `optimize` |

### I/O

| Book (0.15.2) | 0.14.1 |
|---------------|--------|
| `std.fs.File.stdout()` | `std.io.getStdOut()` |
| `std.fs.File.stderr()` | `std.io.getStdErr()` |
| `var buf: [N]u8 = undefined;` | *(Not needed)* |
| `file.writer(&buf)` | `file.writer()` |
| `writer.interface.print()` | `writer.print()` |
| `writer.interface.flush()` | *(Not needed, auto-flush)* |

### Containers

| Book (0.15.2) | 0.14.1 |
|---------------|--------|
| `.empty` or `.{}` | `.init(allocator)` |
| `.deinit(allocator)` | `.deinit()` |
| `.append(allocator, item)` | `.append(item)` |
| `.put(allocator, k, v)` | `.put(k, v)` |

---

## Common Reading Scenarios

### Scenario 1: "I'm reading about file I/O"

**Book example:**
```zig
const file = try std.fs.cwd().createFile("output.txt", .{});
defer file.close();

var buf: [4096]u8 = undefined;
var writer = file.writer(&buf);
try writer.interface.print("Data\n", .{});
try writer.interface.flush();
```

**Your 0.14.1 adaptation:**
```zig
const file = try std.fs.cwd().createFile("output.txt", .{});
defer file.close();

// No buffer needed
const writer = file.writer();
try writer.print("Data\n", .{});
// No flush needed
```

---

### Scenario 2: "I'm reading about ArrayList usage"

**Book example:**
```zig
var list = std.ArrayList(u8).empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, "Hello");
const owned = try list.toOwnedSlice(allocator);
defer allocator.free(owned);
```

**Your 0.14.1 adaptation:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();

try list.appendSlice("Hello");  // No allocator parameter
const owned = try list.toOwnedSlice();  // No allocator parameter
defer allocator.free(owned);
```

---

### Scenario 3: "I'm reading about build.zig structure"

**Book example:**
```zig
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mylib", .module = mylib_mod },
        },
    }),
});
```

**Your 0.14.1 adaptation:**
```zig
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("mylib", mylib_mod);
```

---

## Examples Won't Compile on 0.14.1

**All runnable examples in `examples/` target Zig 0.15.2.**

If you try to compile them on 0.14.1, you'll get errors like:

```
error: missing struct field: root_module
error: no field named 'interface' in struct 'fs.File.Writer'
error: expected 2 arguments, found 1
```

**Options:**
1. **Recommended:** Upgrade to 0.15.2 (see Appendix B)
2. Manually adapt examples using this appendix
3. Use the conceptual knowledge without running examples

---

## When to Upgrade

**Upgrade to 0.15.2 if:**
- You can spare 2-4 hours for migration
- You want to follow book examples directly
- Your team is open to version upgrades
- You want latest features and bug fixes

**Stay on 0.14.1 if:**
- Upgrade not approved by team
- Production system with strict version lock
- Migration time not available short-term

**Long-term:** Zig 0.14 support will eventually decrease as ecosystem moves forward. Plan migration within 6-12 months.

---

## Summary

**Using this book with Zig 0.14.1:**
- ✅ Learn modern Zig patterns (concepts apply to both versions)
- ✅ Use this appendix to translate examples
- ⚠️  Runnable examples won't compile (0.15.2 only)
- ⚠️  Requires mental translation while reading
- 💡 **Recommended:** Upgrade to 0.15.2 for best experience

**Translation pattern:**
- Build system: Remove `.root_module` wrapper
- I/O: Use `std.io.getStdOut()`, no buffers, no `.interface`
- Containers: Use `.init(allocator)`, remove allocator from method calls

For full migration guide, see **Appendix B**.

---

**Appendix A Complete**
