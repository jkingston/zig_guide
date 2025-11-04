# Workspace Example

Demonstrates a multi-package Zig workspace with local dependencies.

## Structure

```
workspace/
├── build.zig              # Root build file
├── build.zig.zon          # Workspace manifest with local dependencies
├── packages/
│   ├── core/              # Shared library package
│   │   ├── build.zig
│   │   ├── build.zig.zon
│   │   └── src/lib.zig
│   └── app/               # Application package
│       └── src/main.zig
└── shared/                # Shared resources (if needed)
```

## Building

```bash
# Build everything
zig build

# Run the app
zig build run

# Test all packages
zig build test
```

## How It Works

1. The workspace root `build.zig.zon` declares `core` as a local path dependency
2. The root `build.zig` uses `b.dependency("core", ...)` to access the core module
3. The app imports and uses the core module
4. Tests run across both packages
