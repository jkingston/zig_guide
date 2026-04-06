# Recipes

::: {.callout-tip}
## TL;DR

- **CLI tools** → arg parsing, env vars, signals, subprocesses
- **Data processing** → JSON, crypto, embedded files
- **File processing** → directory walking, paths
- **Web services** → HTTP client, HTTP server, database
- **Ecosystem** → curated library recommendations
- **Jump to:** [CLI Tools §](#building-a-cli-tool) | [Data §](#working-with-data) | [Files §](#file-processing) | [Web §](#web-services) | [Ecosystem §](#ecosystem-guide)
:::

This chapter provides opinionated recipes for common tasks. Each recipe names the right tool — stdlib or ecosystem library — and shows working code.

---

## Building a CLI Tool

### Argument Parsing

**Simple flags** — use `std.process.argsWithAllocator`:

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var args = try std.process.argsWithAllocator(init.gpa);
    defer args.deinit();
    _ = args.next(); // skip program name

    var verbose = false;
    var output: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            verbose = true;
        } else if (std.mem.startsWith(u8, arg, "--output=")) {
            output = arg["--output=".len..];
        }
    }

    if (verbose) std.debug.print("Output: {s}\n", .{output orelse "(stdout)"});
}
```

**Complex CLIs** — use **zig-clap**, the community standard. The help text IS the schema, parsed at comptime:

```zig
const clap = @import("clap");

const params = comptime clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\-v, --verbose          Enable verbose output.
    \\-o, --output <PATH>    Output file path.
    \\<FILE>...              Input files to process.
    \\
);
```

zig-clap auto-generates `--help` output from the parameter declarations. Add it via `build.zig.zon` (see Chapter 10).

### Environment Variables

```zig
// Read with fallback
const port_str = std.process.getEnvVarOwned(init.gpa, "PORT") catch |err| switch (err) {
    error.EnvironmentVariableNotFound => try init.gpa.dupe(u8, "8080"),
    else => return err,
};
defer init.gpa.free(port_str);
const port = try std.fmt.parseInt(u16, port_str, 10);
```

`getEnvVarOwned` returns owned memory — caller frees. For zero-alloc reads on POSIX, `std.posix.getenv` returns a borrowed `?[]const u8`. There is no `setenv` in the standard library.

### Signal Handling & Graceful Shutdown

Set an atomic flag from the signal handler, check it in the main loop. POSIX only (Linux, macOS).

```zig
const std = @import("std");

var shutdown = std.atomic.Value(bool).init(false);

fn onSignal(_: c_int) callconv(.c) void {
    shutdown.store(true, .release);
}

pub fn main(init: std.process.Init) !void {
    _ = init;

    var sa: std.posix.Sigaction = .{
        .handler = .{ .handler = onSignal },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    try std.posix.sigaction(std.posix.SIG.INT, &sa, null);
    try std.posix.sigaction(std.posix.SIG.TERM, &sa, null);

    while (!shutdown.load(.acquire)) {
        // ... do work ...
    }

    std.debug.print("Shutting down gracefully...\n", .{});
}
```

Signal handlers must be `callconv(.c)` and async-signal-safe — no allocations, no locks, no printing. The atomic flag pattern is the standard approach. See Chapter 8 for atomic ordering details.

### Running Subprocesses

Spawn a command, capture its output, check the exit code:

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var child = std.process.Child.init(
        .{ .argv = &.{ "git", "rev-parse", "HEAD" } },
        init.gpa,
    );
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(init.gpa, 1 << 20);
    defer init.gpa.free(stdout);
    const term = try child.wait();

    if (term.Exited == 0) {
        const hash = std.mem.trimRight(u8, stdout, "\n");
        std.debug.print("Commit: {s}\n", .{hash});
    }
}
```

Configure `.stdout_behavior` and `.stderr_behavior` before calling `.spawn()`. Always call `.wait()` to avoid zombie processes. Use `.Inherit` when you want the child to share the parent's terminal.

---

## Working with Data

### JSON

**Parse a config file into a struct:**

```zig
const std = @import("std");

const Config = struct {
    host: []const u8,
    port: u16,
    debug: bool = false,
};

pub fn main(init: std.process.Init) !void {
    const bytes = try std.fs.cwd().readFileAlloc(init.gpa, "config.json", 1 << 20);
    defer init.gpa.free(bytes);

    var parsed = try std.json.parseFromSlice(Config, init.gpa, bytes, .{});
    defer parsed.deinit();

    const config = parsed.value;
    std.debug.print("Connecting to {s}:{d}\n", .{ config.host, config.port });
}
```

**Serialize a value to JSON:**

```zig
var buf = std.ArrayList(u8).init(init.gpa);
defer buf.deinit(init.gpa);
try std.json.stringify(config, .{ .whitespace = .indent_2 }, buf.writer());
```

**Dynamic JSON** when the schema is unknown:

```zig
var parsed = try std.json.parseFromSlice(std.json.Value, init.gpa, bytes, .{});
defer parsed.deinit();
const name = parsed.value.object.get("name").?.string;
```

Key points:

- `parsed.deinit()` frees all parsed strings — copy anything you need to keep
- Use `.ignore_unknown_fields = true` for lenient parsing
- Define `jsonStringify` and `jsonParse` methods on your types for custom serialization

### Hashing & Crypto

```zig
const std = @import("std");

pub fn main() !void {
    const data = "hello, world";

    // SHA-256
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(data, &digest, .{});
    std.debug.print("sha256: {x}\n", .{digest});

    // Secure random bytes
    var token: [32]u8 = undefined;
    std.crypto.random.bytes(&token);

    // HMAC-SHA256
    var key: [32]u8 = undefined;
    std.crypto.random.bytes(&key);
    var tag: [std.crypto.auth.hmac.sha2.HmacSha256.mac_length]u8 = undefined;
    std.crypto.auth.hmac.sha2.HmacSha256.create(&tag, data, &key);
}
```

Always use `std.crypto.timing_safe.eql` to compare tags — never `std.mem.eql`. The `std.crypto.random` source is cryptographically secure (backed by OS entropy). Also available: Blake3, AES-GCM, ChaCha20, Curve25519.

### Embedding Files

Bundle static assets — templates, SQL migrations, certificates — directly into the binary:

```zig
const default_config = @embedFile("defaults/config.json");
const html_template = @embedFile("templates/index.html");

const migrations = [_][]const u8{
    @embedFile("migrations/001_create_users.sql"),
    @embedFile("migrations/002_add_email.sql"),
};
```

`@embedFile` returns `*const [N:0]u8` — a comptime-known, null-terminated byte array that lives in the binary's read-only section. The path is relative to the source file. Zero runtime cost.

For embedding entire directories, use a build step that iterates files and generates an index module.

---

## File Processing

### Walking Directories

**Recursive traversal** — find all `.zig` files under `src/`:

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var dir = try std.fs.cwd().openDir("src", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(init.gpa);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".zig")) continue;
        std.debug.print("{s}\n", .{entry.path});
    }
}
```

**Single-level listing:**

```zig
var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
defer dir.close();

var iter = dir.iterate();
while (try iter.next()) |entry| {
    std.debug.print("{s} ({s})\n", .{ entry.name, @tagName(entry.kind) });
}
```

You **must** pass `.iterate = true` when opening a directory — forgetting this is the most common mistake. Note that `entry.path` is invalidated on the next `.next()` call; copy it if you need to keep it.

### Path Manipulation

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Join path components (allocates)
    const full = try std.fs.path.join(init.gpa, &.{ "project", "src", "main.zig" });
    defer init.gpa.free(full);

    // Extract parts (no allocation — returns slices into the input)
    const name = std.fs.path.basename("/home/user/file.zig");   // "file.zig"
    const parent = std.fs.path.dirname("/home/user/file.zig");  // "/home/user"

    // Resolve relative paths (allocates)
    const abs = try std.fs.path.resolve(init.gpa, &.{ ".", "src", "../lib" });
    defer init.gpa.free(abs);

    std.debug.print("{s} -> {s}, {s}\n", .{ full, name, parent orelse "" });
    std.debug.print("resolved: {s}\n", .{abs});
}
```

Cross-platform — handles both POSIX and Windows path separators. `join` and `resolve` allocate; `basename` and `dirname` return slices into the input string.

---

## Web Services

### HTTP Client

Make outbound requests with `std.http.Client`:

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var client: std.http.Client = .{ .allocator = init.gpa };
    defer client.deinit();

    var buf: [8192]u8 = undefined;
    var req = try client.open(.GET, try std.Uri.parse("https://httpbin.org/get"), .{
        .server_header_buffer = &buf,
    });
    defer req.deinit();

    try req.send();
    try req.wait();

    const body = try req.reader().readAllAlloc(init.gpa, 1 << 20);
    defer init.gpa.free(body);

    std.debug.print("Response ({d} bytes):\n{s}\n", .{ body.len, body });
}
```

`std.http.Client` supports HTTP/1.1, TLS, and connection pooling. For POST requests, set `.transfer_encoding = .chunked`, write the body with `req.writer()`, call `.finish()`, then `.wait()`.

### HTTP Server → http.zig

For HTTP servers, use **http.zig** (karlseguin). Lightweight, production-tested (~140K req/s).

```zig
const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .{
        .backing_allocator = std.heap.smp_allocator,
    };
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try httpz.Server(void).init(allocator, .{
        .address = .localhost(8080),
    }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/health", handleHealth, .{});
    router.get("/users/:id", handleGetUser, .{});

    std.debug.print("Listening on :8080\n", .{});
    try server.listen();
}

fn handleHealth(_: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .status = "ok" }, .{});
}

fn handleGetUser(req: *httpz.Request, res: *httpz.Response) !void {
    const id = req.param("id") orelse {
        res.status = 404;
        return;
    };
    try res.json(.{ .user_id = id }, .{});
}
```

http.zig provides per-request arena allocators via `req.arena`, path parameters with `:name` syntax, JSON serialization, and WebSocket support. Add it via `build.zig.zon` (see Chapter 10).

For a full-stack web framework with file-based routing, templates, sessions, and a database layer, see **Jetzig** — it builds on http.zig.

### Database → zqlite.zig / pg.zig

**SQLite** — use **zqlite.zig** (karlseguin). Bundles SQLite source, no system dependency.

```zig
const std = @import("std");
const zqlite = @import("zqlite");

pub fn main(init: std.process.Init) !void {
    var db = try zqlite.open(init.gpa, "app.db", .{});
    defer db.close() catch {};

    try db.exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)");
    try db.exec("INSERT INTO users (name) VALUES (?)", .{"Alice"});

    var rows = try db.rows("SELECT id, name FROM users WHERE name = ?", .{"Alice"});
    defer rows.deinit();

    while (rows.next()) |row| {
        std.debug.print("User {d}: {s}\n", .{ row.int(0), row.text(1) });
    }
}
```

**PostgreSQL** — use **pg.zig** (karlseguin). Native driver with connection pooling and struct row mapping:

```zig
const pg = @import("pg");

var pool = try pg.Pool.init(allocator, .{
    .size = 5,
    .auth = .{
        .username = "app",
        .password = "secret",
        .database = "mydb",
    },
});
defer pool.deinit();

var conn = try pool.acquire();
defer pool.release(conn);

if (try conn.row("SELECT id, name FROM users WHERE id = $1", .{user_id})) |row| {
    defer row.deinit();
    std.debug.print("User: {s}\n", .{row.get([]const u8, 1)});
}
```

Both libraries are thin wrappers over C code, linked via `build.zig`. See Chapter 12 for C interop patterns.

---

## Ecosystem Guide

Packages are discoverable via **Zigistry** ([zigistry.dev](https://zigistry.dev)) and **awesome-zig** ([github.com/zigcc/awesome-zig](https://github.com/zigcc/awesome-zig)).

### Recommended Libraries

| Need | Use | Notes |
|------|-----|-------|
| CLI argument parsing | **zig-clap** | Community standard, comptime help strings |
| HTTP server | **http.zig** | Lightweight, ~140K req/s |
| Web framework | **Jetzig** | Full-stack: routing, templates, DB |
| SQLite | **zqlite.zig** | Bundles SQLite, zero system deps |
| PostgreSQL | **pg.zig** | Native driver, connection pooling |
| Date/time | **zdt** | Timezone database, ISO 8601 |
| Terminal UI | **libvaxis** | Modern Kitty protocol, widgets |

The Zig ecosystem is evolving rapidly. Check each library's repository for the latest version compatibility before adding it to your project.

---

## Summary

This chapter covered the practical building blocks for common Zig applications:

- **CLI tools**: Parse arguments with `std.process` or zig-clap, read env vars, handle signals with atomic flags, spawn subprocesses
- **Data processing**: Parse and serialize JSON with `std.json`, hash with `std.crypto`, embed static files with `@embedFile`
- **File operations**: Walk directories with `std.fs.Dir.walk`, manipulate paths with `std.fs.path`
- **Web services**: Make HTTP requests with `std.http.Client`, serve with http.zig, query databases with zqlite.zig or pg.zig

For deeper coverage of the underlying concepts, see the referenced chapters throughout this guide.
