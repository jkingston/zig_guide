# zighttp

A simple HTTP client CLI tool built with Zig 0.15.2, demonstrating professional project structure and best practices.

## Features

- 🚀 Simple HTTP requests (GET, POST, PUT, DELETE)
- 🎨 Automatic JSON pretty-printing
- 📦 Usable as both CLI tool and library
- ✅ Comprehensive test suite
- 🔧 Professional project structure
- 🤖 CI/CD with GitHub Actions

## Installation

### From Source

Requires Zig 0.15.2 or later.

```bash
git clone https://github.com/yourusername/zighttp.git
cd zighttp
zig build -Doptimize=ReleaseFast
```

The binary will be in `zig-out/bin/zighttp`.

### From Pre-built Binaries

Download from the [releases page](https://github.com/yourusername/zighttp/releases).

## Usage

### CLI

Basic GET request:
```bash
zighttp https://api.github.com/users/ziglang
```

POST request with data:
```bash
zighttp -X POST https://httpbin.org/post -d '{"key":"value"}'
```

Disable JSON pretty-printing:
```bash
zighttp --no-pretty https://api.github.com/users/ziglang
```

Show help:
```bash
zighttp --help
```

### Library

```zig
const std = @import("std");
const zighttp = @import("zighttp");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = zighttp.Args{
        .url = "https://api.github.com/users/ziglang",
        .method = .GET,
    };

    var response = try zighttp.request(allocator, args);
    defer response.deinit();

    std.debug.print("Status: {d}\n", .{response.status_code});
    std.debug.print("Body: {s}\n", .{response.body});
}
```

## Development

### Prerequisites

- Zig 0.15.2 or later
- (Optional) ZLS for editor support

### Building

Build in debug mode:
```bash
zig build
```

Build optimized release:
```bash
zig build -Doptimize=ReleaseFast
```

Run the CLI:
```bash
zig build run -- https://example.com
```

### Testing

Run all tests:
```bash
zig build test
```

Run only unit tests:
```bash
zig build test-unit
```

Run only integration tests:
```bash
zig build test-integration
```

Test with verbose output:
```bash
zig build test --summary all
```

### Code Quality

Format code:
```bash
zig fmt .
```

Check formatting without modifying:
```bash
zig fmt --check .
```

## Project Structure

```
zighttp/
├── .github/
│   └── workflows/       # CI/CD pipelines
│       ├── ci.yml      # Build and test
│       └── release.yml # Release automation
├── src/
│   ├── main.zig        # CLI entry point
│   ├── root.zig        # Library exports
│   ├── args.zig        # Argument parsing
│   ├── http_client.zig # HTTP logic
│   └── json_formatter.zig # JSON formatting
├── tests/
│   └── integration_test.zig # Integration tests
├── build.zig           # Build configuration
├── build.zig.zon       # Package manifest
├── .zls.json           # ZLS configuration
├── .editorconfig       # Editor settings
└── .gitignore          # Git ignore rules
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Learn More

This project demonstrates professional Zig development practices covered in the [Zig Developer Guide](https://github.com/jkingston/zig_guide), specifically Chapter 0: Professional Project Setup.

### Key Patterns Demonstrated

- ✅ Standard project structure with `zig init`
- ✅ Modular code organization
- ✅ Comprehensive testing (unit + integration)
- ✅ Professional build system configuration
- ✅ CI/CD with GitHub Actions
- ✅ Cross-compilation support
- ✅ Editor integration (ZLS)
- ✅ Code formatting and style consistency
- ✅ Complete documentation
