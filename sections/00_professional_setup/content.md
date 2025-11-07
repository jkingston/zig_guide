# Professional Project Setup: From Zero to Production-Ready

## Overview

Most Zig tutorials show you how to write "Hello, World" - but then you're on your own when it comes to structuring a real project. This chapter bridges that gap by building a complete, production-ready CLI tool from scratch, incorporating all the professional practices used by major Zig projects.

By the end of this chapter, you'll have:
- A working HTTP client CLI tool (`zighttp`)
- Complete understanding of professional project structure
- Configured development tools (ZLS, formatting, CI/CD)
- A template you can adapt for your own projects

**Who this chapter is for:**
- Developers setting up their first Zig project
- Teams evaluating Zig and need a project template
- Anyone wanting to understand how professional Zig projects are organized

**What we'll build:**

`zighttp` - A simple but complete HTTP client that demonstrates:
- ✅ Standard project structure
- ✅ Modular code organization
- ✅ Comprehensive testing (unit + integration)
- ✅ Professional build system
- ✅ CI/CD automation
- ✅ Cross-compilation support
- ✅ Complete documentation

This chapter complements the deep-dive chapters that follow. Where Chapter 8 explains build system concepts and Chapter 10 covers project layout theory, this chapter shows you the complete setup process from start to finish.

---

## 0.1 Project Initialization

### Starting with `zig init`

Zig provides a standard project template via `zig init`. This command generates a conventional directory structure that tooling expects.[^1]

Let's start by creating our project:

```bash
$ mkdir zighttp && cd zighttp
$ zig init
info: Created build.zig
info: Created build.zig.zon
info: Created src/main.zig
info: Created src/root.zig
```

> **💡 TIP:** Choose project names carefully - they appear in `build.zig.zon`, imports, and command-line tools. Use lowercase with hyphens or underscores. The project name becomes your package name if you publish it to the Zig package registry.

### Understanding the Generated Structure

The `zig init` command creates four essential files:

```
zighttp/
├── build.zig          # Build configuration
├── build.zig.zon      # Package manifest
└── src/
    ├── main.zig       # Executable entry point
    └── root.zig       # Library module root
```

Let's examine each file:

**`build.zig` - Build Configuration**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

**Key elements:**
- **`standardTargetOptions()`** - Accepts `-Dtarget=` from command line for cross-compilation
- **`standardOptimizeOption()`** - Accepts `-Doptimize=` (Debug, ReleaseFast, ReleaseSafe, ReleaseSmall)
- **`addExecutable()`** - Defines an executable artifact
- **`installArtifact()`** - Marks for installation to `zig-out/bin/`
- **`addRunArtifact()`** - Creates a run step that executes the binary

> **📝 NOTE:** Cross-compilation is first-class in Zig. Build for any platform from any platform: `zig build -Dtarget=x86_64-windows`, `zig build -Dtarget=aarch64-macos`, etc. No cross-compiler toolchain needed!

**`build.zig.zon` - Package Manifest**

```zig
.{
    .name = "zighttp",
    .version = "0.1.0",
    .minimum_zig_version = "0.15.2",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "README.md",
        "LICENSE",
    },
}
```

**Purpose:**
- Declares package metadata (name, version)
- Specifies minimum Zig version compatibility
- Lists files to include when published as a package
- Can declare dependencies (we'll add these later if needed)

**`src/main.zig` - Executable Entry Point**

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, World!\n", .{});
}
```

The `main()` function is the entry point for executables. It can return `void`, `!void` (for errors), or `u8` (for exit codes).

**`src/root.zig` - Library Module Root**

```zig
const std = @import("std");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
```

The `root.zig` file defines your library's public API. Functions marked `pub` are accessible to dependents.

### First Build

Verify the project works:

```bash
$ zig build
$ ./zig-out/bin/zighttp
Hello, World!
```

Run tests:

```bash
$ zig build test
All 1 tests passed.
```

Run the executable directly via build system:

```bash
$ zig build run
Hello, World!
```

### Build Artifacts and Caching

Zig creates two directories:
- **`zig-cache/`** - Local build cache (incremental compilation)
- **`zig-out/`** - Output directory for built artifacts

Both should be excluded from version control (we'll add `.gitignore` soon).

> **⚠️ WARNING:** Never commit `zig-cache/` or `zig-out/` to Git. They contain machine-specific binaries and can be gigabytes in size. Always add them to `.gitignore` before your first commit. Committing them causes merge conflicts and bloats repository history.

### What Makes This Structure Standard?

The `zig init` layout follows conventions established by the Zig community and major projects:[^2]

1. **`build.zig` at project root** - All Zig projects use this name
2. **`src/` for source files** - Consistent across projects
3. **`main.zig` for executables** - Expected entry point name
4. **`root.zig` for libraries** - Expected library root

These conventions enable:
- **ZLS** can find project root by locating `build.zig`
- **Build tools** know where to look for configuration
- **Developers** can navigate unfamiliar projects easily
- **Package managers** understand project structure

### Customizing for Our Project

Our `zighttp` project will be both a library and a CLI tool. The default structure already supports this:
- `src/main.zig` - CLI interface
- `src/root.zig` - Library exports for programmatic use

We'll expand this structure in the next sections by adding:
- Additional modules (`args.zig`, `http_client.zig`, `json_formatter.zig`)
- Test directory (`tests/`)
- Configuration files (`.zls.json`, `.editorconfig`, `.gitignore`)
- CI/CD workflows (`.github/workflows/`)
- Documentation (`README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`)

---

## 0.2 Editor Setup & Developer Tools

With our project structure in place, let's configure the development environment. Professional tooling accelerates development and catches errors early.

This section covers setting up Zig Language Server (ZLS), code formatting, and editor integration.

### Installing and Configuring ZLS

The Zig Language Server (ZLS) provides IDE features like autocomplete, go-to-definition, hover documentation, and inline diagnostics.[^3]

> **📝 NOTE:** ZLS versions must match your Zig version closely. Using ZLS 0.13.0 with Zig 0.15.2 will cause errors. Always download the ZLS version that matches your Zig installation. Check compatibility at the ZLS version support matrix.[^5]

**Installation**

Option 1: From releases (recommended)

```bash
# Download latest release for your platform
# https://github.com/zigtools/zls/releases

# macOS/Linux
wget https://github.com/zigtools/zls/releases/download/0.13.0/zls-x86_64-linux.tar.gz
tar -xzf zls-x86_64-linux.tar.gz
sudo mv zls /usr/local/bin/

# Verify
zls --version
```

Option 2: Build from source

```bash
git clone https://github.com/zigtools/zls.git
cd zls
zig build -Doptimize=ReleaseSafe
sudo cp zig-out/bin/zls /usr/local/bin/
```

**Configuration**

Create `.zls.json` in your project root:

```json
{
  "enable_autofix": true,
  "enable_snippets": true,
  "enable_ast_check_diagnostics": true,
  "warn_style": true,
  "semantic_tokens": "full",
  "enable_inlay_hints": true,
  "inlay_hints_show_variable_type_hints": true,
  "inlay_hints_show_parameter_name": true,
  "inlay_hints_show_builtin": true,
  "inlay_hints_exclude_single_argument": true,
  "operator_completions": true,
  "include_at_in_builtins": false
}
```

**Key settings explained:**

- **`enable_autofix`** - Automatically apply fixes for common issues
- **`enable_ast_check_diagnostics`** - Show errors as you type
- **`warn_style`** - Highlight style violations
- **`semantic_tokens`** - Enhanced syntax highlighting
- **`enable_inlay_hints`** - Show inferred types inline
- **`inlay_hints_show_parameter_name`** - Show parameter names in function calls

This configuration enables aggressive IDE assistance while coding.

### Editor Integration

**VS Code**

1. Install the official Zig extension:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Zig Language"
   - Install the official extension by zigtools

2. Configure in `.vscode/settings.json`:

```json
{
  "zig.zls.enabled": true,
  "zig.formattingProvider": "zls",
  "zig.initialSetupDone": true,
  "editor.formatOnSave": true,
  "[zig]": {
    "editor.defaultFormatter": "ziglang.vscode-zig",
    "editor.formatOnSave": true
  }
}
```

**Neovim**

Using `nvim-lspconfig`:

```lua
-- lua/lsp/init.lua
local lspconfig = require('lspconfig')

lspconfig.zls.setup{
  cmd = { "zls" },
  filetypes = { "zig", "zir" },
  root_dir = lspconfig.util.root_pattern("build.zig", ".git"),
  settings = {
    zls = {
      enable_autofix = true,
      enable_snippets = true,
      warn_style = true,
    }
  }
}
```

**Emacs**

Using `lsp-mode`:

```elisp
;; .emacs or init.el
(use-package lsp-mode
  :hook (zig-mode . lsp)
  :commands lsp)

(setq lsp-zig-zls-executable "/usr/local/bin/zls")
```

### Code Formatting with `zig fmt`

Zig has a built-in code formatter that enforces consistent style.[^4]

**Usage:**

Format all files:
```bash
zig fmt .
```

Check formatting without modifying:
```bash
zig fmt --check .
```

Format specific file:
```bash
zig fmt src/main.zig
```

**What it enforces:**
- 4-space indentation
- Consistent spacing around operators
- Proper line breaks
- Trailing commas in multiline lists
- No trailing whitespace

**Before formatting:**
```zig
const x=10;
const  y  =  20  ;
const z=x+y;
```

**After `zig fmt`:**
```zig
const x = 10;
const y = 20;
const z = x + y;
```

Most editors can run `zig fmt` on save (configure via settings above). This prevents formatting drift and makes code reviews focus on logic, not style.

### EditorConfig for Consistency

Create `.editorconfig` for cross-editor consistency:

```ini
# EditorConfig is awesome: https://editorconfig.org

root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.zig]
indent_style = space
indent_size = 4

[*.zon]
indent_style = space
indent_size = 4

[*.{yml,yaml}]
indent_style = space
indent_size = 2

[*.{json,md}]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

Most editors respect EditorConfig automatically. This ensures consistent formatting even for contributors using different editors.

> **💡 TIP:** `.editorconfig` prevents "tab vs spaces" and "LF vs CRLF" debates that waste team time. It's especially valuable for open-source projects where contributors use varied editors. Most modern editors (VS Code, IntelliJ, Vim, Emacs) support EditorConfig automatically - no plugins needed.

### Git Configuration

Create `.gitignore`:

```
# Zig build artifacts
zig-out/
zig-cache/
.zig-cache/

# Compiled binaries
*.o
*.a
*.so
*.dylib
*.dll
*.exe
*.pdb

# Editor and IDE files
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Test artifacts
test-results/
coverage/

# Local environment
.env
.env.local
```

This prevents committing build artifacts and editor-specific files.

### Verifying Your Setup

Test that everything works:

1. **ZLS is running:**
   - Open a `.zig` file
   - Hover over a function - you should see documentation
   - Ctrl+Space should show autocomplete

2. **Formatting works:**
   ```bash
   echo "const x=10;" > test.zig
   zig fmt test.zig
   cat test.zig  # Should show "const x = 10;"
   rm test.zig
   ```

3. **Git ignores artifacts:**
   ```bash
   zig build
   git status  # Should not show zig-out/ or zig-cache/
   ```

With these tools configured, you have a professional Zig development environment. Next, we'll put these tools to use building a complete project.

---

## 0.3 Building zighttp: Project Structure & Code Organization

Now let's build something real. This section demonstrates professional project organization by implementing `zighttp`, a complete HTTP client with both CLI and library interfaces. You'll see how modular design, clear responsibilities, and proper separation of concerns come together in practice.

### Project Design

**zighttp** will:
- Make HTTP GET/POST/PUT/DELETE requests
- Pretty-print JSON responses
- Support command-line arguments
- Be usable as both a library and CLI tool
- Have comprehensive tests

### Module Organization

We'll organize code into focused modules:

```
zighttp/
├── src/
│   ├── main.zig           # CLI entry point
│   ├── root.zig           # Library exports
│   ├── args.zig           # Argument parsing
│   ├── http_client.zig    # HTTP logic
│   └── json_formatter.zig # JSON utilities
└── tests/
    └── integration_test.zig
```

Each module has a single, clear responsibility - a pattern we saw in ZLS.

### Module 1: args.zig - Argument Parsing

This module parses command-line arguments into a structured format.

```zig
const std = @import("std");

/// HTTP methods supported
pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,

    pub fn fromString(s: []const u8) !Method {
        if (std.mem.eql(u8, s, "GET")) return .GET;
        if (std.mem.eql(u8, s, "POST")) return .POST;
        if (std.mem.eql(u8, s, "PUT")) return .PUT;
        if (std.mem.eql(u8, s, "DELETE")) return .DELETE;
        return error.InvalidMethod;
    }
};

/// Parsed command-line arguments
pub const Args = struct {
    url: []const u8,
    method: Method = .GET,
    body: ?[]const u8 = null,
    pretty: bool = true,

    pub fn parse(allocator: std.mem.Allocator) !Args {
        var args_iter = try std.process.argsWithAllocator(allocator);
        defer args_iter.deinit();

        // Skip program name
        _ = args_iter.skip();

        var result = Args{ .url = "" };
        var next_is_method = false;
        var next_is_body = false;

        while (args_iter.next()) |arg| {
            if (next_is_method) {
                result.method = try Method.fromString(arg);
                next_is_method = false;
            } else if (next_is_body) {
                result.body = try allocator.dupe(u8, arg);
                next_is_body = false;
            } else if (std.mem.eql(u8, arg, "-X") or std.mem.eql(u8, arg, "--method")) {
                next_is_method = true;
            } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--data")) {
                next_is_body = true;
            } else if (std.mem.eql(u8, arg, "--no-pretty")) {
                result.pretty = false;
            } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                return error.ShowHelp;
            } else if (result.url.len == 0) {
                result.url = try allocator.dupe(u8, arg);
            }
        }

        if (result.url.len == 0) return error.MissingUrl;
        return result;
    }

    pub fn deinit(self: Args, allocator: std.mem.Allocator) void {
        if (self.url.len > 0) allocator.free(self.url);
        if (self.body) |body| allocator.free(body);
    }
};

test "method from string" {
    try std.testing.expectEqual(Method.GET, try Method.fromString("GET"));
    try std.testing.expectEqual(Method.POST, try Method.fromString("POST"));
    try std.testing.expectError(error.InvalidMethod, Method.fromString("INVALID"));
}
```

**Key design decisions:**
- Enum for HTTP methods (type-safe)
- Allocator passed explicitly (Zig 0.15 style)
- `deinit()` for cleanup (RAII pattern)
- Unit tests co-located with code

### Module 2: http_client.zig - HTTP Requests

This module wraps `std.http.Client` with a simpler interface.

> **📝 NOTE:** The `std.http.Client` API changed significantly in Zig 0.15. Key differences from 0.14: `client.open()` now takes explicit `.headers`, `req.send()` is separate from `.finish()`, and `Headers` must be deinitialized. If you're porting code from older Zig versions, check the standard library documentation for the current API.

```zig
const std = @import("std");
const args_mod = @import("args.zig");
const Args = args_mod.Args;
const Method = args_mod.Method;

pub const Response = struct {
    status_code: u16,
    body: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Response) void {
        self.allocator.free(self.body);
    }
};

pub fn request(allocator: std.mem.Allocator, request_args: Args) !Response {
    // Parse URL
    const uri = try std.Uri.parse(request_args.url);

    // Create HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Convert to std.http.Method
    const method: std.http.Method = switch (request_args.method) {
        .GET => .GET,
        .POST => .POST,
        .PUT => .PUT,
        .DELETE => .DELETE,
    };

    // Prepare headers
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("User-Agent", "zighttp/0.1.0");
    try headers.append("Accept", "*/*");

    var server_header_buffer: [8192]u8 = undefined;

    // Make request
    var req = try client.open(method, uri, .{
        .server_header_buffer = &server_header_buffer,
        .headers = headers,
    });
    defer req.deinit();

    try req.send();

    // Send body if provided
    if (request_args.body) |body| {
        try req.writeAll(body);
    }

    try req.finish();
    try req.wait();

    // Read response
    const status_code = @intFromEnum(req.response.status);

    var response_body = std.ArrayList(u8).init(allocator);
    defer response_body.deinit();

    var buf: [4096]u8 = undefined;
    while (true) {
        const bytes_read = try req.readAll(&buf);
        if (bytes_read == 0) break;
        try response_body.appendSlice(buf[0..bytes_read]);
    }

    return Response{
        .status_code = @intCast(status_code),
        .body = try response_body.toOwnedSlice(),
        .allocator = allocator,
    };
}
```

**Key design decisions:**
- Uses `std.http.Client` (no external dependencies)
- Reads response in chunks (handles large bodies)
- Caller owns response memory (must call `deinit()`)
- Custom User-Agent header

> **⚠️ WARNING:** Memory ownership is explicit in Zig. The `Response` struct stores the allocator that allocated its memory. If you call `deinit()` with the wrong allocator, you'll get undefined behavior or crashes. Always call `response.deinit()` (uses stored allocator) or pass the same allocator you used for creation. Never mix allocators!

### Module 3: json_formatter.zig - JSON Pretty-Printing

This module detects and formats JSON.

```zig
const std = @import("std");

pub fn format(allocator: std.mem.Allocator, json_str: []const u8) ![]const u8 {
    // Parse JSON
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_str, .{}) catch {
        // If parsing fails, return original
        return try allocator.dupe(u8, json_str);
    };
    defer parsed.deinit();

    // Re-serialize with pretty printing
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    try std.json.stringify(parsed.value, .{
        .whitespace = .indent_2,
    }, output.writer());

    return try output.toOwnedSlice();
}

pub fn isJson(s: []const u8) bool {
    if (s.len == 0) return false;
    const trimmed = std.mem.trim(u8, s, " \t\n\r");
    if (trimmed.len == 0) return false;
    return trimmed[0] == '{' or trimmed[0] == '[';
}

test "format valid JSON" {
    const allocator = std.testing.allocator;
    const input = "{\"name\":\"John\",\"age\":30}";
    const formatted = try format(allocator, input);
    defer allocator.free(formatted);
    
    try std.testing.expect(std.mem.indexOf(u8, formatted, "  ") != null);
}

test "isJson detection" {
    try std.testing.expect(isJson("{\"test\":1}"));
    try std.testing.expect(isJson("[1,2,3]"));
    try std.testing.expect(!isJson("not json"));
}
```

**Key design decisions:**
- Gracefully handles invalid JSON
- Simple heuristic for detection
- Two-space indentation (common convention)

### Module 4: main.zig - CLI Entry Point

The CLI orchestrates all modules:

```zig
const std = @import("std");
const args = @import("args.zig");
const http_client = @import("http_client.zig");
const json_formatter = @import("json_formatter.zig");

const version = "0.1.0";

fn printHelp() void {
    const help =
        \\zighttp v{s} - Simple HTTP client CLI
        \\
        \\Usage: zighttp [options] <url>
        \\
        \\Options:
        \\  -X, --method <METHOD>  HTTP method (GET, POST, PUT, DELETE)
        \\  -d, --data <DATA>      Request body data
        \\  --no-pretty            Disable JSON pretty-printing
        \\  -h, --help             Show this help
        \\
        \\Examples:
        \\  zighttp https://api.github.com/users/ziglang
        \\  zighttp -X POST https://httpbin.org/post -d '{"key":"value"}'
        \\
    ;
    std.debug.print(help, .{version});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse arguments
    const parsed_args = args.Args.parse(allocator) catch |err| {
        if (err == error.ShowHelp) {
            printHelp();
            return;
        }
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer parsed_args.deinit(allocator);

    // Make request
    var response = http_client.request(allocator, parsed_args) catch |err| {
        std.debug.print("HTTP request failed: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer response.deinit();

    // Print response
    const stdout = std.io.getStdOut().writer();
    try stdout.print("HTTP {d}\n", .{response.status_code});
    try stdout.writeAll("---\n");

    // Format JSON if applicable
    if (parsed_args.pretty and json_formatter.isJson(response.body)) {
        const formatted = json_formatter.format(allocator, response.body) catch response.body;
        defer if (formatted.ptr != response.body.ptr) allocator.free(formatted);
        try stdout.writeAll(formatted);
    } else {
        try stdout.writeAll(response.body);
    }
    try stdout.writeAll("\n");
}
```

**Key design decisions:**
- `GeneralPurposeAllocator` for leak detection
- Friendly error messages
- Help on error
- Clean separation of concerns

### Module 5: root.zig - Library Exports

The library root re-exports everything for external use:

```zig
const std = @import("std");

pub const args = @import("args.zig");
pub const http_client = @import("http_client.zig");
pub const json_formatter = @import("json_formatter.zig");

// Re-export common types
pub const Args = args.Args;
pub const Method = args.Method;
pub const Response = http_client.Response;
pub const request = http_client.request;
pub const formatJson = json_formatter.format;
pub const isJson = json_formatter.isJson;

test {
    std.testing.refAllDecls(@This());
}
```

**Why this structure works:**
- Each module has one job
- Clean dependency graph
- Easy to test independently
- Can use as library or CLI

This modular structure follows the patterns we saw in ZLS, where each feature gets its own file.

> **💡 TIP:** Organize imports from most general to most specific: `std` imports first, then third-party dependencies, then local modules. Use `pub const` re-exports in `root.zig` to provide a clean API - library users import `zighttp` and get everything they need without knowing internal module structure.

---

## 0.4 Testing Strategy

With `zighttp` implemented, we need to ensure it works correctly across different scenarios and platforms. Testing isn't optional in professional projects - it's how you maintain confidence as code evolves. This section covers both unit tests (testing individual components) and integration tests (testing the complete system).

> **📝 NOTE:** Zig makes testing a first-class feature. Tests run with the same compiler that builds your code, use the same syntax, and integrate into the build system. There's no separate test framework to learn - if you can write Zig, you can write tests. This simplicity encourages comprehensive testing.

### Unit Tests

Unit tests are co-located with code using Zig's `test` blocks. We already added some in our modules. Let's review the strategy:

**In `args.zig`:**
```zig
test "method from string" {
    try std.testing.expectEqual(Method.GET, try Method.fromString("GET"));
    try std.testing.expectEqual(Method.POST, try Method.fromString("POST"));
    try std.testing.expectError(error.InvalidMethod, Method.fromString("INVALID"));
}
```

**In `http_client.zig`:**
```zig
test "response structure" {
    const allocator = std.testing.allocator;
    const body = try allocator.dupe(u8, "test body");
    var response = Response{
        .status_code = 200,
        .body = body,
        .allocator = allocator,
    };
    defer response.deinit();

    try std.testing.expectEqual(@as(u16, 200), response.status_code);
}
```

**In `json_formatter.zig`:**
```zig
test "format valid JSON" {
    const allocator = std.testing.allocator;
    const input = "{\"name\":\"John\"}";
    const formatted = try format(allocator, input);
    defer allocator.free(formatted);
    
    try std.testing.expect(std.mem.indexOf(u8, formatted, "  ") != null);
}

test "isJson detection" {
    try std.testing.expect(isJson("{\"test\":1}"));
    try std.testing.expect(!isJson("plain text"));
}
```

> **💡 TIP:** Co-locate unit tests with the code they test. This makes tests easy to find, encourages developers to write tests (they're right there!), and ensures tests stay updated when code changes. Tests in `src/` test implementation details; tests in `tests/` test public APIs. This mirrors the pattern used by the Zig compiler itself.

### Integration Tests

Integration tests live in `tests/integration_test.zig` and test the full library API:

```zig
const std = @import("std");
const zighttp = @import("zighttp");

test "library imports work" {
    _ = zighttp.Args;
    _ = zighttp.Method;
    _ = zighttp.Response;
    _ = zighttp.request;
    _ = zighttp.formatJson;
    _ = zighttp.isJson;
}

test "args parsing logic" {
    const allocator = std.testing.allocator;
    
    const get = try zighttp.Method.fromString("GET");
    try std.testing.expectEqual(zighttp.Method.GET, get);
    
    const post = try zighttp.Method.fromString("POST");
    try std.testing.expectEqual(zighttp.Method.POST, post);
}

test "json formatter" {
    const allocator = std.testing.allocator;
    
    const input = "{\"name\":\"test\",\"value\":123}";
    const formatted = try zighttp.formatJson(allocator, input);
    defer allocator.free(formatted);
    
    try std.testing.expect(std.mem.indexOf(u8, formatted, "  ") != null);
    
    try std.testing.expect(zighttp.isJson("{\"test\":1}"));
    try std.testing.expect(!zighttp.isJson("plain text"));
}

test "response structure creation" {
    const allocator = std.testing.allocator;
    
    const body = try allocator.dupe(u8, "test response");
    var response = zighttp.Response{
        .status_code = 200,
        .body = body,
        .allocator = allocator,
    };
    defer response.deinit();
    
    try std.testing.expectEqual(@as(u16, 200), response.status_code);
}
```

**Note on network tests:**
Real HTTP requests are difficult to test reliably (require network, external services). In production code, you'd either:
1. Mock the HTTP layer
2. Spin up a local test server
3. Test against a stable API endpoint

For zighttp, we focus on unit tests for each component.

> **⚠️ WARNING:** Avoid network-dependent tests in CI. They're flaky (network outages, rate limits, API changes), slow, and can fail spuriously. TigerBeetle's simulator approach (deterministic testing) is the gold standard for distributed systems. For HTTP clients, either mock the network layer or mark network tests as manual-only (not run in CI).

### Running Tests

The `build.zig` provides several test commands:

```bash
# Run all tests
zig build test

# Run just unit tests
zig build test-unit

# Run just integration tests
zig build test-integration

# Verbose output
zig build test --summary all
```

### Test Organization Best Practices

From our analysis of real projects, we follow these patterns:

1. **Unit tests co-located** - Test blocks in source files
2. **Integration tests separate** - `tests/` directory
3. **One test = one assertion concept** - Focused tests
4. **Descriptive names** - "test format valid JSON" not "test 1"
5. **Clean up resources** - Use `defer` for test allocations

---

## 0.5 Build System Configuration

Tests are only useful if they run reliably and efficiently. Zig's build system ties everything together - compiling code, running tests, and enabling cross-compilation. Let's configure `build.zig` to handle our library, executable, and test targets professionally.

### Complete build.zig

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ===== Library =====
    const lib = b.addStaticLibrary(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(lib);

    // ===== Executable =====
    const exe = b.addExecutable(.{
        .name = "zighttp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    // ===== Run Step =====
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the zighttp CLI");
    run_step.dependOn(&run_cmd.step);

    // ===== Unit Tests =====
    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    
    // Test individual modules
    const modules = [_][]const u8{
        "args",
        "http_client",
        "json_formatter",
    };
    
    inline for (modules) |module_name| {
        const module_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/" ++ module_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        
        const run_module_tests = b.addRunArtifact(module_tests);
        run_lib_unit_tests.step.dependOn(&run_module_tests.step);
    }

    // ===== Integration Tests =====
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/integration_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    integration_tests.root_module.addImport("zighttp", &lib.root_module);
    
    const run_integration_tests = b.addRunArtifact(integration_tests);

    // ===== Test Steps =====
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);
    
    const unit_test_step = b.step("test-unit", "Run unit tests only");
    unit_test_step.dependOn(&run_lib_unit_tests.step);
    
    const integration_test_step = b.step("test-integration", "Run integration tests only");
    integration_test_step.dependOn(&run_integration_tests.step);
}
```

### Key Features

**1. Multiple artifacts:**
- Static library (`libzighttp.a`)
- Executable (`zighttp`)
- Test executables (multiple)

**2. Custom build steps:**
- `zig build` - Build library and executable
- `zig build run` - Run the CLI
- `zig build test` - Run all tests
- `zig build test-unit` - Unit tests only
- `zig build test-integration` - Integration tests only

**3. Cross-compilation support:**
```bash
# Build for Linux
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast

# Build for macOS
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast

# Build for Windows
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast
```

**4. Optimization modes:**
- `Debug` - No optimization, all safety checks
- `ReleaseSafe` - Optimized, keeps safety checks
- `ReleaseFast` - Maximum speed, removes safety
- `ReleaseSmall` - Minimize binary size

### Build Options (Advanced)

For compile-time configuration, you can add build options:

```zig
const build_options = b.addOptions();
build_options.addOption([]const u8, "version", "0.1.0");
build_options.addOption(bool, "enable_logging", optimize == .Debug);

exe.root_module.addOptions("build_options", build_options);
```

Then use in code:
```zig
const build_options = @import("build_options");

pub fn main() !void {
    std.debug.print("zighttp v{s}\n", .{build_options.version});
}
```

---

## 0.6 Learning from Real Zig Projects

You've now built a complete project from scratch. To level up further, let's study how major Zig projects tackle organization at scale. These aren't arbitrary patterns - they evolved to solve real problems in production codebases handling 40K to 500K+ lines of code.

We'll analyze six projects representing different archetypes: compiler, database, developer tool, runtime, GUI app, and game engine. Understanding when and why to use each pattern will help you make better architectural decisions.

> **📝 NOTE:** Learning from production codebases is one of the fastest ways to internalize best practices. The patterns you see here weren't invented arbitrarily - they evolved to solve real organizational challenges at scale. Don't feel obligated to adopt all patterns immediately; understand the problems they solve first.

### Zig Compiler - Pipeline Architecture

**Repository:** ziglang/zig[^6] | **Size:** 300K+ LOC

**Structure:**
```
zig/
├── src/
│   ├── Compilation.zig    # Single struct per file
│   ├── Sema.zig           # Semantic analysis
│   ├── AstGen.zig         # AST generation
│   ├── codegen/           # Subsystem directory
│   │   ├── llvm.zig
│   │   └── c.zig
│   ├── link/              # Linker backends
│   │   ├── Elf.zig
│   │   └── MachO.zig
│   └── arch/              # Platform-specific
│       ├── x86_64/
│       └── aarch64/
└── test/
    ├── behavior/          # Language semantics tests
    ├── cases/             # Compilation scenarios
    └── standalone/        # Complete project tests
```

**Key patterns:**

1. **Single-file structs:** Files like `Compilation.zig` export one primary type using `const Compilation = @This();`. This makes navigation trivial - see `Compilation` in code, know it's in `Compilation.zig`.

2. **Stage directories:** The compiler pipeline (source → AST → ZIR → AIR → machine code) maps to directory structure. Each stage is isolated and testable.

3. **Test by purpose:** Tests organize by what they test, not code location. This enables testing language features end-to-end.

4. **Minimal dependencies:** Only LLVM/Clang for backends. Parser, semantic analyzer, linker all self-hosted in Zig.

> **💡 TIP:** Use single-file structs (like `Compilation.zig`) when a type is substantial (300+ lines) and self-contained. For smaller types or closely related types, group them in a module (like `types.zig`). The pattern makes large codebases navigable: seeing `@import("Parser.zig")` immediately tells you what the file contains.

**When to use:** Building compilers, interpreters, or any pipeline-based processing system where stages are clearly defined.

### TigerBeetle - Zero-Dependency Database

**Repository:** tigerbeetle/tigerbeetle[^7] | **Size:** 100K+ LOC | **Dependencies:** None

**Structure:**
```
tigerbeetle/
├── src/
│   ├── vsr.zig            # Viewstamped Replication
│   ├── lsm/               # Log-Structured Merge tree
│   ├── storage.zig
│   ├── io.zig             # Async I/O
│   ├── clients/           # Language bindings
│   │   ├── c/
│   │   ├── java/
│   │   └── node/
│   └── simulator.zig      # Deterministic testing
├── docs/
│   ├── DESIGN.md
│   ├── PROTOCOL.md
│   └── INTERNALS.md
```

**Key patterns:**

1. **Zero dependencies:** Everything implemented from scratch - networking, crypto, data structures, I/O. Every line is auditable. This is rare and only justified for systems where correctness is more important than development speed.

2. **Simulator-first development:** `simulator.zig` enables deterministic testing of distributed consensus. Can replay exact failure conditions. Finds bugs traditional testing misses.

3. **Co-located clients:** Language bindings live in same repo, ensuring all clients stay synchronized with protocol changes. Single source of truth.

4. **Design documentation:** `docs/` explains the "why" behind decisions, not just "how". Critical for contributors understanding trade-offs.

> **⚠️ WARNING:** Zero dependencies is NOT a universal best practice. TigerBeetle's requirements (financial correctness, auditability, deterministic behavior) justify implementing everything from scratch. Most projects should use well-tested dependencies - reimplementing cryptography, networking, or compression introduces risk and maintenance burden. Only go dependency-free if you have TigerBeetle-level requirements.

**When to use:** Financial systems, databases, or systems where every line must be auditable and deterministic behavior is critical.

### ZLS - Feature-Per-File Organization

**Repository:** zigtools/zls[^3] | **Size:** 50K+ LOC

**Structure:**
```
zls/
├── src/
│   ├── Server.zig          # Core type
│   ├── DocumentStore.zig   # Core type
│   ├── completions.zig     # Feature file
│   ├── goto.zig            # Feature file
│   ├── hover.zig           # Feature file
│   ├── references.zig      # Feature file
│   ├── signature_help.zig  # Feature file
│   └── Config.zig          # Core type
├── tests/
│   ├── lsp_features/
│   └── toolchains/         # Multi-version testing
└── schema.json             # Config validation
```

**Key patterns:**

1. **Feature-per-file:** Each LSP feature gets its own file. Want to fix autocomplete? Look in `completions.zig`. Need hover docs? Check `hover.zig`. Makes features easy to find and prevents "god files".

2. **Core types separated:** Major types like `Server`, `DocumentStore`, and `Config` get dedicated files using PascalCase naming.

3. **Schema-driven configuration:** `schema.json` enables editors to validate `.zls.json` files, preventing configuration errors before runtime.

4. **Multi-version compatibility:** CI tests against Zig 0.13, 0.14, 0.15, and master. Critical for tools that must support multiple language versions.

> **💡 TIP:** Feature-per-file organization (like ZLS) works excellently for projects with distinct, independent features. If you're building a CLI tool with subcommands, an LSP with features, or a web framework with middleware, this pattern keeps code discoverable and prevents files from becoming dumping grounds.

**When to use:** Developer tools, CLI tools with subcommands, plugin systems, or any tool with independent features.

### Bun - Multi-Language Integration

**Repository:** oven-sh/bun[^8] | **Size:** 500K+ LOC (Zig + C++ + JS)

**Structure:**
```
bun/
├── build.zig             # Zig build
├── CMakeLists.txt        # C++ build
├── src/
│   ├── cli/              # CLI (Zig)
│   ├── install/          # Package manager (Zig)
│   ├── bun.js/           # JS runtime (C++)
│   │   └── bindings/     # FFI layer
│   └── deps/             # Vendored C deps
│       ├── mimalloc/
│       └── zstd/
```

**Key patterns:**

1. **Language boundaries:** Each language chosen for its strengths - Zig for CLI/networking (performance + simplicity), C++ for JS engine (reusing JavaScriptCore), JS for bundler logic.

2. **Isolated FFI layer:** All Zig ↔ C++ interop goes through `bindings/` directory. Prevents FFI code from spreading throughout codebase. Makes integration points explicit and testable.

3. **Dual build systems:** `build.zig` handles Zig, `CMakeLists.txt` handles C++, coordinated at top level. Each language uses its native tooling.

4. **Vendored dependencies:** `deps/` contains exact versions of C libraries. Ensures reproducible builds, no system dependency surprises.

**When to use:** Projects requiring C/C++ interop or reusing existing libraries written in other languages.

### Ghostty - Platform Abstraction

**Repository:** ghostty-org/ghostty[^9] | **Size:** 80K+ LOC

**Structure:**
```
ghostty/
├── src/
│   ├── terminal/         # Platform-agnostic core
│   │   ├── Terminal.zig
│   │   ├── Screen.zig
│   │   └── parser.zig
│   ├── renderer/         # Platform-specific
│   │   ├── metal.zig     # macOS
│   │   ├── opengl.zig    # Linux/Windows
│   │   └── software.zig  # Fallback
│   ├── gui/              # Platform UI
│   │   ├── gtk/          # Linux
│   │   ├── cocoa/        # macOS
│   │   └── windows/      # Windows
│   └── pty/              # Platform PTY
│       ├── unix.zig
│       └── windows.zig
```

**Key patterns:**

1. **Core is portable:** Terminal emulation logic in `terminal/` works identically on all platforms. Can be tested without any OS-specific code.

2. **Platform subdirectories:** Platform-specific code isolated in subdirectories. Each platform gets optimal implementation (Metal on macOS, OpenGL on Linux).

3. **Compile-time selection:** `switch (target.os.tag)` at compile time selects appropriate implementation. Zero runtime overhead.

4. **C library integration:** Uses established C libraries (HarfBuzz for text shaping, FreeType for fonts) via `@cImport`. Don't rewrite complex algorithms.

**When to use:** Cross-platform GUI applications or any tool with platform-specific APIs (graphics, audio, file watching).

### Mach - Modular Architecture

**Repository:** hexops/mach[^10] | **Size:** 40K+ LOC

**Structure:**
```
mach/
├── src/
│   ├── core/             # Minimal core module
│   ├── gfx/              # Graphics module
│   ├── audio/            # Audio module
│   └── ecs/              # Entity-component system
├── examples/             # Example per feature
│   ├── core/triangle/
│   ├── gfx/sprite/
│   └── audio/playback/
└── libs/                 # Git submodules
    ├── glfw/
    └── freetype/
```

**Key patterns:**

1. **Composable modules:** Users depend only on needed modules. Building a simple 2D game? Use `mach_core` + `mach_gfx`. Need audio? Add `mach_audio`. Each module independently versioned.

2. **Example-driven development:** Every feature has a working example. Examples serve triple duty: documentation (show real usage), integration tests (verified in CI), starting points for users.

3. **Independent versioning:** Modules released separately. Core can be at v0.3, graphics at v0.5. Users not forced to upgrade everything.

4. **WebGPU abstraction:** Single rendering API (WebGPU) works on desktop, web (WebAssembly), and mobile. Write once, run everywhere.

**When to use:** Libraries, frameworks, or any system where users need subsets of features (not a monolithic "all or nothing").

### Pattern Summary

| Pattern | Use When |
|---------|----------|
| Single-file structs (`Parser.zig`) | Type is substantial (300+ lines) and self-contained |
| Feature-per-file (`completions.zig`) | Building CLI with subcommands or tool with distinct features |
| Platform subdirectories (`renderer/metal.zig`) | Need platform-specific implementations |
| Zero dependencies | Auditability/correctness is paramount (rare!) |
| Example directory | Building library/framework users will integrate |
| FFI isolation (`bindings/`) | Integrating with C/C++ libraries |

### Anti-Patterns to Avoid

❌ **Deep nesting:** `src/lib/core/internal/impl/util.zig` - hard to navigate
✅ **Instead:** Flatten structure, use descriptive names

❌ **God files:** `utils.zig` with 5000 lines of unrelated functions
✅ **Instead:** Split by domain: `string_utils.zig`, `math_utils.zig`

❌ **Mixed naming:** `myModule.zig` + `OtherMod.zig` + `another_one.zig`
✅ **Instead:** PascalCase for types, snake_case for modules, consistently

❌ **Circular dependencies:** Module A imports B imports A
✅ **Instead:** Extract shared types to `types.zig`

❌ **Platform code scattered:** Windows-specific code mixed throughout
✅ **Instead:** Isolate in `platform/windows/`, `platform/linux/`

### Key Principles

Apply these to your own projects:

**File naming:**
- `PascalCase.zig` exports a single primary struct (`const Foo = @This();`)
- `snake_case.zig` is a module with multiple exports
- Directories use lowercase with underscores

**Organization:**
- Directories represent subsystems (features, platforms, stages)
- Tests mirror source structure (`src/foo.zig` → `test/foo.zig`)
- Platform-specific code in subdirectories, not mixed with portable code

**Dependencies:**
- Prefer standard library over external dependencies
- If using C libraries, vendor them (git submodules) for reproducibility
- Document all dependencies in `build.zig.zon`

**Build system:**
- Keep complexity in `build.zig`, not shell scripts
- Support cross-compilation from the start with `-Dtarget`
- Provide separate test targets (`test-unit`, `test-integration`)

Now that we understand professional patterns, let's apply them building zighttp.

---
## 0.7 CI/CD with GitHub Actions

Manual testing on your local machine isn't enough - code that works on your laptop might fail on different platforms or configurations. Continuous Integration and Continuous Deployment (CI/CD) automates testing across multiple platforms and handles releases. Let's configure GitHub Actions to catch issues early and ship reliably.

> **📝 NOTE:** CI/CD prevents "works on my machine" problems. GitHub Actions is free for public repos and provides runners for Linux, macOS, and Windows. Every push triggers automated testing across all platforms, catching platform-specific bugs early. This is how ZLS, Zig compiler, and other major projects maintain quality.

### CI Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:

jobs:
  format:
    name: Check Formatting
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2
      
      - name: Check formatting
        run: zig fmt --check .

  test:
    name: Build and Test
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
      fail-fast: false
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2
      
      - name: Cache Zig artifacts
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/zig
            zig-cache
          key: ${{ runner.os }}-zig-${{ hashFiles('build.zig.zon') }}
      
      - name: Build
        run: zig build
      
      - name: Run tests
        run: zig build test --summary all

  build-artifacts:
    name: Build Release Artifacts
    needs: [format, test]
    if: github.event_name != 'pull_request'
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: x86_64-linux
          - os: macos-latest
            target: aarch64-macos
          - os: windows-latest
            target: x86_64-windows
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2
      
      - name: Build for ${{ matrix.target }}
        run: zig build -Dtarget=${{ matrix.target }} -Doptimize=ReleaseFast
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: zighttp-${{ matrix.target }}
          path: zig-out/bin/zighttp*
          retention-days: 7
```

### Release Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    outputs:
      upload_url: ${{ steps.create_release.outputs.upload_url }}
    steps:
      - uses: actions/create-release@v1
        id: create_release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

> **⚠️ WARNING:** `GITHUB_TOKEN` is automatically provided by GitHub Actions - never manually create or commit tokens. For custom secrets (API keys, signing keys), use GitHub's encrypted secrets feature (Settings → Secrets). Never hardcode secrets in workflow files or source code - they'll be visible in git history forever, even if you delete them later.

  build:
    name: Build Release Artifacts
    needs: create-release
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: x86_64-linux
            archive: tar.gz
          - os: macos-latest
            target: aarch64-macos
            archive: tar.gz
          - os: windows-latest
            target: x86_64-windows
            archive: zip
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2
      
      - name: Build for ${{ matrix.target }}
        run: zig build -Dtarget=${{ matrix.target }} -Doptimize=ReleaseFast
      
      - name: Package (Unix)
        if: matrix.archive == 'tar.gz'
        run: |
          cd zig-out/bin
          tar czf ../../zighttp-${{ matrix.target }}.tar.gz zighttp
          cd ../..
          sha256sum zighttp-${{ matrix.target }}.tar.gz > zighttp-${{ matrix.target }}.tar.gz.sha256
      
      - name: Package (Windows)
        if: matrix.archive == 'zip'
        shell: bash
        run: |
          cd zig-out/bin
          7z a ../../zighttp-${{ matrix.target }}.zip zighttp.exe
          cd ../..
          sha256sum zighttp-${{ matrix.target }}.zip > zighttp-${{ matrix.target }}.zip.sha256
      
      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ needs.create-release.outputs.upload_url }}
          asset_path: ./zighttp-${{ matrix.target }}.${{ matrix.archive }}
          asset_name: zighttp-${{ matrix.target }}.${{ matrix.archive }}
          asset_content_type: application/octet-stream
```

### What This Gives You

**CI Workflow (on every push/PR):**
1. ✅ Format check
2. ✅ Build on Linux, macOS, Windows
3. ✅ Run all tests on all platforms
4. ✅ Cache build artifacts for speed
5. ✅ Build release binaries (non-PR only)

**Release Workflow (on git tags):**
1. ✅ Triggered by pushing a tag: `git tag v0.1.0 && git push origin v0.1.0`
2. ✅ Cross-compiles for multiple platforms
3. ✅ Creates archives with checksums
4. ✅ Creates GitHub release
5. ✅ Uploads all artifacts

---

## 0.8 Documentation & Polish

Professional projects need professional documentation. Good docs are as important as good code - they're how users discover, understand, and contribute to your project.

### README.md - Your Project's Front Door

The README is the first thing users see. A good README answers three questions immediately:

1. **What is this?** - One-sentence description + longer explanation
2. **How do I use it?** - Installation and quick start
3. **Why should I care?** - Key features, benefits, use cases

**Essential README sections:**

```markdown
# zighttp

Simple HTTP client for Zig. CLI tool and reusable library.

[![CI](https://github.com/user/zighttp/workflows/CI/badge.svg)](...)
[![Zig](https://img.shields.io/badge/zig-0.15.2-orange.svg)](...)

## Features

- ✅ GET, POST, PUT, DELETE requests
- ✅ JSON auto-formatting
- ✅ Cross-platform (Linux, macOS, Windows)
- ✅ Usable as CLI or library

## Installation

### As CLI tool
```bash
# From releases
wget https://github.com/user/zighttp/releases/download/v0.1.0/zighttp-linux.tar.gz
tar xf zighttp-linux.tar.gz
sudo mv zighttp /usr/local/bin/

# From source
git clone https://github.com/user/zighttp
cd zighttp
zig build -Doptimize=ReleaseFast
sudo cp zig-out/bin/zighttp /usr/local/bin/
```

### As library
```zig
// build.zig.zon
.dependencies = .{
    .zighttp = .{
        .url = "https://github.com/user/zighttp/archive/v0.1.0.tar.gz",
        .hash = "1220...",
    },
}
```

## Usage

### CLI
```bash
zighttp https://api.github.com/users/ziglang
zighttp -X POST https://httpbin.org/post -d '{"key":"value"}'
```

### Library
```zig
const zighttp = @import("zighttp");

const response = try zighttp.request(allocator, .{
    .url = "https://api.github.com",
    .method = .GET,
});
defer response.deinit();
```

## Documentation

- [Architecture](ARCHITECTURE.md) - Design decisions
- [Contributing](CONTRIBUTING.md) - Development guide
- [Examples](examples/) - Usage examples

## License

MIT License - see [LICENSE](LICENSE)
```

**README best practices:**
- Add CI badges (build status, Zig version)
- Include GIFs/screenshots for visual tools
- Keep quick start < 5 minutes
- Link to detailed docs for advanced usage

### ARCHITECTURE.md - Design Rationale

Documents **why** decisions were made, not just what code does:

```markdown
# Architecture

## Overview

zighttp is designed as both CLI and library...

## Module Structure

### src/main.zig - CLI Entry Point

**Responsibility:** Coordinate CLI workflow

**Key decisions:**
- Uses GeneralPurposeAllocator for leak detection
- Prints help on error for better UX
- Separates concerns: parsing, requesting, formatting

**Why this approach:**
Keeping CLI thin makes the library testable independently...

### src/http_client.zig - HTTP Logic

**Responsibility:** Wrap std.http.Client with simpler API

**Key decisions:**
- Allocates response body on heap (caller owns)
- Reads in chunks (handles large responses)
- Custom User-Agent header

**Trade-offs:**
- Pro: Simple API, handles large responses
- Con: Buffers entire response in memory
- Alternative: Streaming API (future enhancement)
```

**What to document:**
- **Design decisions:** Why this structure over alternatives?
- **Trade-offs:** What did you optimize for? What did you sacrifice?
- **Patterns:** Single-file structs, error handling, memory ownership
- **Performance:** Where are the hot paths? Known bottlenecks?
- **Future work:** What would you change if starting over?

### CONTRIBUTING.md - Onboarding Contributors

Make it easy for others to contribute:

**Essential sections:**
1. **Development setup** - How to get started (dependencies, build, test)
2. **Code style** - Naming conventions, formatting, documentation standards
3. **Testing guidelines** - What tests to write, how to run them
4. **Commit message format** - Conventional commits, examples
5. **Pull request process** - Steps from fork to merge

**Example snippet:**
```markdown
## Making Changes

1. Fork and create feature branch: `git checkout -b feature/your-feature`
2. Make changes following code style (see below)
3. Add tests: `zig build test`
4. Format code: `zig fmt .`
5. Commit with clear message: `feat(client): add timeout support`
6. Push and create PR

## Code Style

**Naming:**
- `camelCase` for functions and variables
- `PascalCase` for types (structs, enums)
- `SCREAMING_SNAKE_CASE` for constants

**Documentation:**
Use `///` doc comments for public APIs:

```zig
/// Makes an HTTP request with the given arguments.
///
/// Caller owns returned memory and must call response.deinit().
///
/// Example:
/// ```zig
/// const response = try request(allocator, args);
/// defer response.deinit();
/// ```
pub fn request(allocator: Allocator, args: Args) !Response
```

### Code Documentation - Doc Comments

Zig supports doc comments with `///`:

**What to document:**
- **Purpose:** What does this function/type do?
- **Parameters:** What do they mean? Valid ranges?
- **Return value:** What does it return? Error conditions?
- **Memory ownership:** Who allocates? Who frees?
- **Examples:** Show real usage

**Bad doc comment:**
```zig
/// Parse arguments
pub fn parse(allocator: Allocator) !Args
```

**Good doc comment:**
```zig
/// Parses command-line arguments into structured Args.
///
/// Accepts flags: -X/--method, -d/--data, -h/--help
/// First non-flag argument is treated as URL.
///
/// Returns error.MissingUrl if no URL provided.
/// Returns error.ShowHelp if -h/--help specified.
///
/// Caller owns returned Args and must call deinit(allocator).
///
/// Example:
/// ```zig
/// const args = try Args.parse(allocator);
/// defer args.deinit(allocator);
/// ```
pub fn parse(allocator: Allocator) !Args
```

### CHANGELOG.md - Track Changes

Document changes between versions:

```markdown
# Changelog

All notable changes to zighttp will be documented here.

Format based on Keep a Changelog.[^11]

## [Unreleased]

### Added
- Custom header support (#12)

### Fixed
- Handle empty response bodies (#15)

## [0.1.0] - 2024-01-15

### Added
- Initial release
- GET, POST, PUT, DELETE support
- JSON auto-formatting
- CLI and library API
- CI/CD workflows

[Unreleased]: https://github.com/user/zighttp/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/user/zighttp/releases/tag/v0.1.0
```

**Categories:**
- `Added` - New features
- `Changed` - Changes to existing features
- `Deprecated` - Soon-to-be-removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security fixes

### LICENSE - Legal Foundation

Choose appropriate license:

- **MIT** - Permissive, most popular for Zig projects
- **Apache 2.0** - Permissive with patent grant
- **GPL** - Copyleft, requires derivatives to be open-source
- **Unlicense / Public Domain** - No restrictions

Most Zig projects use MIT for simplicity and compatibility.

### Polish Checklist

Before releasing, verify:

- [ ] README complete with badges, examples, installation
- [ ] ARCHITECTURE.md documents design decisions
- [ ] CONTRIBUTING.md guides new contributors
- [ ] LICENSE file present
- [ ] CHANGELOG.md tracks versions
- [ ] All public APIs have doc comments
- [ ] Code formatted (`zig fmt .`)
- [ ] No TODO/FIXME/HACK comments in committed code
- [ ] Version updated in `build.zig.zon`
- [ ] CI passes on all platforms

**Documentation generates trust.** Users evaluate projects by documentation quality. Invest time here - it pays dividends in adoption and contributions.

---

## 0.9 Release Checklist & Next Steps

You've built a complete professional project with code, tests, CI/CD, and documentation. Now it's time to share it with the world. This section covers security considerations, the final checklist before release, and where to go next.

### Security Considerations

Before releasing any software, review security implications:

**1. Dependency Security**

- **Audit dependencies:** Review all external dependencies in `build.zig.zon`
- **Pin versions:** Always specify exact versions, not ranges (e.g., `0.1.0`, not `>=0.1.0`)
- **Verify hashes:** Zig package manager verifies hashes automatically - never bypass this
- **Minimize attack surface:** Fewer dependencies = smaller attack surface (TigerBeetle's zero-dependency approach is extreme but instructive)

**2. Secrets Management**

- **Never commit secrets:** No API keys, passwords, tokens in source code or git history
- **Use environment variables:** `std.process.getEnvVarOwned()` for runtime secrets
- **Check `.gitignore`:** Ensure `.env`, `credentials.json`, `secrets/` are ignored
- **Scan history:** Use tools like `git-secrets` to find accidentally committed secrets
- **Rotate leaked secrets:** If you accidentally commit a secret, revoke and rotate immediately

**3. Input Validation**

- **Validate all external input:** URLs, file paths, user data, network responses
- **Use Zig's type system:** Leverage enums, comptime validation, and explicit error types
- **Bounds checking:** Zig's safety features (bounds checking, integer overflow detection) catch many issues in Debug and ReleaseSafe modes
- **Sanitize for display:** Escape output when rendering user input (prevent injection attacks)

**4. Memory Safety**

- **Use SafetyRelease for production:** Keeps bounds checking, overflow detection while optimizing
- **Test with allocators:** `std.testing.allocator` detects leaks, `GeneralPurposeAllocator` with `.safety = true` catches use-after-free
- **Review unsafe code:** Search for `@ptrCast`, `@intCast`, `@bitCast` - these bypass safety checks
- **Avoid undefined behavior:** Never access freed memory, never dereference null pointers

**5. Network Security (for HTTP clients like zighttp)**

- **Validate TLS certificates:** Don't disable certificate validation in production
- **Use HTTPS:** Warn users if they're making unencrypted requests to sensitive APIs
- **Timeout configuration:** Set reasonable timeouts to prevent DoS via slowloris attacks
- **Rate limiting:** Implement client-side rate limiting for API requests
- **URL parsing:** Use `std.Uri.parse()` - manual parsing invites injection vulnerabilities

**6. CI/CD Security**

- **Protect workflow files:** `.github/workflows/` should have review requirements
- **Use `GITHUB_TOKEN` sparingly:** Limit permissions to minimum required
- **Never store secrets in workflows:** Use GitHub encrypted secrets (Settings → Secrets)
- **Pin action versions:** Use commit SHAs for actions, not `@latest` (e.g., `actions/checkout@v4.1.1` or `actions/checkout@abc123`)
- **Review PR changes carefully:** Malicious PRs can modify workflows to exfiltrate secrets

**7. Binary Distribution**

- **Sign releases:** Use GPG or code signing for download integrity verification
- **Provide checksums:** SHA256 checksums for all release artifacts (we do this in release workflow)
- **Reproducible builds:** Document build environment (Zig version, OS, dependencies)
- **Security policy:** Add `SECURITY.md` explaining how to report vulnerabilities responsibly

**8. Common Zig-Specific Issues**

- **Allocator mismatches:** Using wrong allocator for `deinit()` causes undefined behavior
- **Undefined behavior in ReleaseFast:** Safety checks removed - only use after thorough testing
- **Comptime evaluation pitfalls:** Comptime code can still have bugs, test it separately
- **Cross-compilation trust:** Test on actual hardware, not just QEMU

**Security Checklist:**

- [ ] All dependencies audited and pinned to specific versions
- [ ] No secrets in source code or `.git` history
- [ ] Input validation on all external data
- [ ] Using ReleaseSafe (not ReleaseFast) for initial releases
- [ ] HTTPS enforced for network requests
- [ ] CI/CD workflows use minimal permissions
- [ ] Release artifacts include SHA256 checksums
- [ ] `SECURITY.md` file documents vulnerability reporting
- [ ] Reviewed all `@ptrCast`, `@bitCast` usage for correctness
- [ ] Tested with `GeneralPurposeAllocator` for memory issues

**Resources:**
- OWASP Top 10: Industry-standard security risks
- Zig Security: Track security issues at github.com/ziglang/zig/labels/security
- CWE Database: Common Weakness Enumeration for vulnerability patterns

Security is a continuous process, not a one-time checklist. Stay informed about vulnerabilities in dependencies and update regularly.

### Pre-Release Checklist

Before releasing zighttp v0.1.0:

- [x] All code formatted (`zig fmt .`)
- [x] All tests passing (`zig build test`)
- [x] CI passing on all platforms
- [x] Documentation complete (README, ARCHITECTURE, CONTRIBUTING)
- [x] License file added
- [x] Version set in `build.zig.zon`
- [x] CHANGELOG.md created (optional but recommended)
- [ ] Tagged release (`git tag v0.1.0`)
- [ ] Pushed to remote (`git push origin v0.1.0`)

### Creating Your First Release

> **💡 TIP:** Use semantic versioning (semver): `MAJOR.MINOR.PATCH`. Increment MAJOR for breaking changes, MINOR for new features (backwards compatible), PATCH for bug fixes. Start at `0.1.0` for initial development. Once API is stable, release `1.0.0`. This matches the versioning used by Zig packages and helps users understand compatibility at a glance.

```bash
# Update version in build.zig.zon
# Commit all changes
git add .
git commit -m "chore: prepare v0.1.0 release"

# Tag the release
git tag v0.1.0

# Push including tags
git push origin main --tags

# GitHub Actions will automatically:
# - Build for multiple platforms
# - Create GitHub release
# - Upload binaries
```

### What You've Built

Congratulations! You now have a **production-ready** Zig project with:

✅ **Professional Structure**
- Standard project layout
- Modular code organization
- Clear separation of concerns

✅ **Development Tools**
- ZLS for IDE support
- Formatting automation
- Git configuration

✅ **Testing Infrastructure**
- Unit tests (co-located)
- Integration tests (separate)
- Test automation in CI

✅ **Build System**
- Library and executable
- Multiple test targets
- Cross-compilation support

✅ **CI/CD Automation**
- Automated testing on 3 platforms
- Release automation
- Artifact generation

✅ **Complete Documentation**
- User-facing (README)
- Developer-facing (ARCHITECTURE, CONTRIBUTING)
- Code documentation (doc comments)

### Using zighttp as a Template

The `zighttp` project serves as a template for your own projects:

```bash
# Copy the structure
cp -r examples/ch00_professional_setup/zighttp my-project
cd my-project

# Customize
# - Update build.zig.zon (name, version)
# - Update README.md
# - Replace modules with your own code
# - Update GitHub Actions workflows

# Start developing!
```

### Next Steps

Now that you have a professional project structure:

**Learn More:**
- Chapter 2: Language Idioms - Write idiomatic Zig
- Chapter 3: Memory & Allocators - Master memory management
- Chapter 8: Build System - Advanced build.zig patterns
- Chapter 10: Project Layout & CI - Deep dive into organization
- Chapter 12: Testing & Benchmarking - Comprehensive testing strategies

**Enhance zighttp:**
- Add custom headers support
- Implement retry logic
- Add configuration file support
- Implement response streaming
- Add progress indicators
- Support HTTP/2 when std.http adds it

**Build Your Own:**
- Use zighttp as a template
- Apply patterns from Section 0.2 (real projects)
- Follow the professional setup checklist
- Automate everything with CI/CD

### Key Lessons

From zero to production-ready, we learned:

1. **Structure matters** - Consistent layout helps everyone
2. **Tooling is essential** - ZLS, formatting, CI/CD save time
3. **Testing is non-negotiable** - Both unit and integration tests
4. **Documentation is code** - Good docs make projects usable
5. **Automation prevents mistakes** - CI catches issues early
6. **Patterns are portable** - Learn from major projects

You're now equipped to build professional Zig projects. Welcome to the Zig community!

---

## Summary

This chapter took you from an empty directory to a complete, production-ready CLI tool. Along the way, you learned:

**Project Initialization:**
- Using `zig init` for standard structure
- Understanding generated files
- Basic build system setup

**Real Project Analysis:**
- Studied 6 major Zig projects
- Identified common patterns
- Learned when to use each pattern

**Development Environment:**
- Configured ZLS for IDE support
- Set up formatting automation
- Established Git workflow

**Code Organization:**
- Modular architecture
- Clear responsibilities per file
- Dependency management

**Testing:**
- Co-located unit tests
- Separate integration tests
- Multiple test targets

**Build System:**
- Library and executable artifacts
- Cross-compilation support
- Multiple build targets

**CI/CD:**
- Automated testing on multiple platforms
- Release automation
- Artifact generation

**Documentation:**
- User documentation (README)
- Developer documentation (ARCHITECTURE, CONTRIBUTING)
- Code documentation (comments)

You now have both theoretical knowledge (how major projects are structured) and practical experience (building zighttp). Use this foundation for all your Zig projects!

---

## 0.10 Troubleshooting Common Issues

Even with clear instructions, setup can hit unexpected issues - wrong versions, missing dependencies, platform differences. This section documents solutions to the most common problems you'll encounter. Before searching elsewhere, check here first - these are the issues that trip up new Zig developers most frequently.

### Build Errors

**Problem: "zig: command not found"**

```bash
$ zig build
bash: zig: command not found
```

**Solution:**
- Verify Zig is installed: Download from official releases[^12]
- Add to PATH: `export PATH=$PATH:/path/to/zig`
- Check version: `zig version` should show 0.15.2

**Problem: "error: FileNotFound - build.zig"**

```bash
$ zig build
error: FileNotFound
```

**Solution:**
- You're not in the project directory
- `cd` into the directory containing `build.zig`
- Check: `ls build.zig` should find the file

**Problem: "unable to find std.Build"**

```zig
error: unable to find 'std.Build'
```

**Solution:**
- Your Zig version is too old (< 0.11)
- Upgrade to Zig 0.15.2
- The build system API changed significantly in 0.11+

### ZLS (Language Server) Issues

**Problem: ZLS not providing completions**

**Symptoms:**
- No autocomplete in editor
- No go-to-definition
- No hover documentation

**Solution:**
1. **Verify ZLS is running:**
   ```bash
   ps aux | grep zls
   # Should show zls process
   ```

2. **Check ZLS version matches Zig:**
   ```bash
   zls --version  # Should match Zig version closely
   zig version    # e.g., 0.15.2
   ```

3. **Restart language server:**
   - VS Code: `Ctrl+Shift+P` → "Reload Window"
   - Neovim: `:LspRestart`

4. **Check `.zls.json` is in project root:**
   ```bash
   ls .zls.json  # Should exist
   ```

**Problem: "ZLS crashed" or constant errors**

**Solution:**
- Version mismatch between ZLS and Zig
- Download matching ZLS from official releases[^13]
- Check ZLS version support matrix[^5]

### Cross-Compilation Issues

**Problem: "unable to find libc installation"**

```bash
$ zig build -Dtarget=x86_64-windows
error: unable to find libc installation
```

**Solution:**
- This usually means you're trying to link with system libc
- For Windows, use `-Dtarget=x86_64-windows-gnu` (MinGW)
- Or avoid libc by using only Zig stdlib

**Problem: Binary works locally but fails on target platform**

**Symptoms:**
- "Illegal instruction" error
- "Cannot execute binary file"
- Segfault on different platform

**Solution:**
1. **Check target triple:**
   ```bash
   # Wrong - missing OS
   zig build -Dtarget=x86_64

   # Correct - full triple
   zig build -Dtarget=x86_64-linux
   ```

2. **Verify optimization mode:**
   - Debug builds include assertions that might fail
   - Use ReleaseSafe for safety checks on all platforms
   - ReleaseFast removes safety (use cautiously)

3. **Test on actual hardware:**
   - Emulators (QEMU, Docker) can hide issues
   - CI on real platforms catches these (see Section 0.7)

### Test Failures

**Problem: "Tests pass locally, fail in CI"**

**Solution:**
1. **Platform-specific behavior:**
   ```zig
   test "path separator" {
       // Fails on Windows if you assume '/'
       const sep = if (builtin.os.tag == .windows) '\\' else '/';
   }
   ```

2. **Time-dependent tests:**
   ```zig
   test "cache expires" {
       // Flaky - depends on timing
       std.time.sleep(100 * std.time.ns_per_ms);
       try std.testing.expect(cache.isExpired());
   }
   ```
   Make tests deterministic or use longer timeouts.

3. **File system differences:**
   - Case sensitivity (Linux yes, macOS/Windows no)
   - Path separators (`/` vs `\`)
   - Line endings (LF vs CRLF)

**Problem: "Memory leak detected"**

```bash
$ zig build test
error: memory leak detected
```

**Solution:**
1. **Check defer statements:**
   ```zig
   test "no leak" {
       const data = try allocator.alloc(u8, 100);
       defer allocator.free(data);  // Don't forget!
       // ... test code
   }
   ```

2. **Verify all deinit() calls:**
   ```zig
   var list = std.ArrayList(u8).init(allocator);
   defer list.deinit();  // Required!
   ```

3. **Use testing.allocator:**
   ```zig
   const allocator = std.testing.allocator;
   // Automatically detects leaks
   ```

### CI/CD Issues

**Problem: "CI fails but local build works"**

**Common causes:**
1. **Cached artifacts:**
   - CI starts fresh, you have local cache
   - Solution: `rm -rf zig-cache/ zig-out/` and rebuild

2. **Missing files in git:**
   ```bash
   git status  # Check for untracked files
   git add <missing-file>
   ```

3. **Wrong Zig version:**
   - Check `.github/workflows/ci.yml` version
   - Match it locally: `zig version`

**Problem: "Release workflow not triggering"**

**Solution:**
1. **Check tag format:**
   ```bash
   # Wrong
   git tag 0.1.0

   # Correct - must start with 'v'
   git tag v0.1.0
   ```

2. **Push tags:**
   ```bash
   git push origin v0.1.0  # Don't forget to push the tag!
   ```

3. **Check workflow file:**
   - Ensure `on: push: tags: - 'v*'` in `.github/workflows/release.yml`

### Installation Issues

**Problem: "Permission denied" when copying binary**

```bash
$ sudo cp zig-out/bin/zighttp /usr/local/bin/
cp: cannot create regular file: Permission denied
```

**Solution:**
1. **Use sudo:**
   ```bash
   sudo cp zig-out/bin/zighttp /usr/local/bin/
   ```

2. **Or install to user directory:**
   ```bash
   mkdir -p ~/.local/bin
   cp zig-out/bin/zighttp ~/.local/bin/
   export PATH=$PATH:~/.local/bin
   ```

**Problem: "Library not found" when running binary**

```bash
$ ./zighttp
error while loading shared libraries: libfoo.so.1
```

**Solution:**
- You linked with dynamic libraries
- For portable binaries, prefer static linking
- Or bundle libraries with binary

### Performance Issues

**Problem: "Build is very slow"**

**Solution:**
1. **Use caching:**
   - Zig caches by default in `zig-cache/`
   - Don't delete cache between builds

2. **Check optimization mode:**
   ```bash
   # Slow - full debug info
   zig build

   # Faster - less debug info
   zig build -Doptimize=ReleaseFast
   ```

3. **Incremental builds:**
   - Only `zig build` (not `zig build clean`)
   - Zig's caching is very good

**Problem: "Tests take forever"**

**Solution:**
- Run subset: `zig build test-unit` (skip integration tests)
- Parallelize in CI (matrix strategy)
- Profile slow tests: Add timing prints

### Getting Help

When troubleshooting doesn't work:

1. **Check Zig version compatibility:**
   - This guide targets Zig 0.15.2
   - APIs change between versions

2. **Search GitHub issues:**
   - Zig issue tracker[^14]
   - Often someone hit the same problem

3. **Ask in Zig community:**
   - Discord[^15]
   - Ziggit forum[^16]
   - Reddit: r/Zig

4. **Provide complete error context:**
   - Full error message
   - Zig version (`zig version`)
   - OS and architecture
   - Minimal reproduction

**Remember:** Most issues come from version mismatches (Zig vs ZLS) or platform differences. Check these first.

---

## Summary

This chapter took you from an empty directory to a complete, production-ready CLI tool. Along the way, you learned:

**Project Initialization:**
- Using `zig init` for standard structure
- Understanding generated files
- Basic build system setup

**Real Project Analysis:**
- Studied 6 major Zig projects
- Identified common patterns
- Learned when to use each pattern

**Development Environment:**
- Configured ZLS for IDE support
- Set up formatting automation
- Established Git workflow

**Code Organization:**
- Modular architecture
- Clear responsibilities per file
- Dependency management

**Testing:**
- Co-located unit tests
- Separate integration tests
- Multiple test targets

**Build System:**
- Library and executable artifacts
- Cross-compilation support
- Multiple build targets

**CI/CD:**
- Automated testing on multiple platforms
- Release automation
- Artifact generation

**Documentation:**
- User documentation (README)
- Developer documentation (ARCHITECTURE, CONTRIBUTING)
- Code documentation (comments)

You now have both theoretical knowledge (how major projects are structured) and practical experience (building zighttp). Use this foundation for all your Zig projects!

---

## References

[^1]: Zig Standard Library - Build System, https://ziglang.org/documentation/0.15.2/#Build-System
[^2]: Zig Community - Project Structure Conventions, https://github.com/ziglang/zig/wiki/FAQ
[^3]: ZLS (Zig Language Server), https://github.com/zigtools/zls
[^4]: Zig Documentation - zig fmt, https://ziglang.org/documentation/0.15.2/#zig-fmt
[^5]: ZLS Version Support Matrix, https://github.com/zigtools/zls#version-support-matrix
[^6]: Zig Compiler Repository, https://github.com/ziglang/zig
[^7]: TigerBeetle Repository, https://github.com/tigerbeetle/tigerbeetle
[^8]: Bun Repository, https://github.com/oven-sh/bun
[^9]: Ghostty Repository, https://github.com/ghostty-org/ghostty
[^10]: Mach Engine Repository, https://github.com/hexops/mach
[^11]: Keep a Changelog, https://keepachangelog.com/
[^12]: Zig Downloads, https://ziglang.org/download/
[^13]: ZLS Releases, https://github.com/zigtools/zls/releases
[^14]: Zig Issue Tracker, https://github.com/ziglang/zig/issues
[^15]: Zig Discord Community, https://discord.gg/zig
[^16]: Ziggit Forum, https://ziggit.dev

