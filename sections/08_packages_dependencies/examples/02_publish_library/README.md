# mathlib

A simple math library for Zig.

## Usage

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .mathlib = .{
        .url = "https://github.com/user/mathlib/archive/v2.0.0.tar.gz",
        .hash = "mathlib-2.0.0-HASH_HERE",
    },
},
```

In your `build.zig`:

```zig
const mathlib_dep = b.dependency("mathlib", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("mathlib", mathlib_dep.module("mathlib"));
```

In your code:

```zig
const mathlib = @import("mathlib");

pub fn main() void {
    const result = mathlib.add(2, 3);
}
```

## License

MIT
