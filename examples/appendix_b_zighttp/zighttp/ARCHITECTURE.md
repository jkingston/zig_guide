# Architecture

This document describes the architecture and design decisions of zighttp.

## Overview

zighttp is designed as both a CLI tool and a reusable library. The codebase is organized into distinct modules, each with a single responsibility.

## Module Structure

### `src/main.zig` - CLI Entry Point

The CLI entry point handles:
- Command-line argument parsing coordination
- Error handling and user-facing messages
- Orchestrating the request-response flow
- Output formatting

**Design decisions:**
- Uses `GeneralPurposeAllocator` for safety (detects leaks)
- Prints help on error for better UX
- Separates concerns: parsing, requesting, formatting

### `src/root.zig` - Library Exports

The library root re-exports all public APIs for external consumers.

**Design decisions:**
- Re-exports common types for convenience
- Includes documentation examples
- Runs all module tests via `refAllDecls`

### `src/args.zig` - Argument Parsing

Handles command-line argument parsing with a simple state machine.

**Key types:**
- `Method` - HTTP method enum
- `Args` - Parsed arguments struct

**Design decisions:**
- Supports both short (`-X`) and long (`--method`) flags
- URL is the first non-flag argument
- Includes `deinit()` for proper cleanup
- Has unit tests for method parsing

### `src/http_client.zig` - HTTP Client

Wraps `std.http.Client` with a simpler interface.

**Key types:**
- `Response` - Status code and body

**Design decisions:**
- Uses standard library HTTP client (no external deps)
- Allocates response body on heap (caller owns)
- Sets reasonable User-Agent header
- Reads response in chunks to handle large bodies

### `src/json_formatter.zig` - JSON Formatting

Provides JSON pretty-printing and detection.

**Key functions:**
- `format()` - Pretty-print JSON with indentation
- `isJson()` - Heuristic to detect JSON content

**Design decisions:**
- Gracefully handles invalid JSON (returns original)
- Uses simple heuristic for detection (starts with `{` or `[`)
- Two-space indentation matches common style

## Build System

The `build.zig` creates three main artifacts:

1. **Static library** (`libzighttp.a`) - For linking into other projects
2. **Executable** (`zighttp`) - CLI tool
3. **Test executables** - Unit and integration tests

### Build Steps

- `zig build` - Build library and executable
- `zig build run` - Run the CLI
- `zig build test` - Run all tests
- `zig build test-unit` - Unit tests only
- `zig build test-integration` - Integration tests only

## Testing Strategy

### Unit Tests

Unit tests are co-located with source code using Zig's `test` blocks.

**Coverage:**
- `args.zig` - Method parsing, argument validation
- `http_client.zig` - Response structure
- `json_formatter.zig` - JSON detection and formatting

### Integration Tests

Integration tests live in `tests/` and test the full library API.

**Coverage:**
- Module imports and exports
- End-to-end workflows (without network calls)
- Error handling paths

**Note:** Real HTTP requests are commented out to avoid network dependency in tests.

## Error Handling

zighttp uses Zig's error unions throughout:

```zig
pub fn request(allocator: Allocator, args: Args) !Response
```

**Error types:**
- `error.MissingUrl` - No URL provided
- `error.InvalidMethod` - Unknown HTTP method
- `error.ShowHelp` - Help requested (not really an error)
- Network errors from `std.http.Client`

The CLI catches errors and provides user-friendly messages.

## Memory Management

All allocations use the allocator passed by the caller.

**Ownership rules:**
1. `Args.parse()` allocates - caller must call `deinit()`
2. `request()` allocates response body - caller must call `response.deinit()`
3. `formatJson()` allocates - caller must free

The CLI uses `GeneralPurposeAllocator` which detects memory leaks.

## Configuration Files

### `.zls.json`

Configures the Zig Language Server for optimal IDE support:
- Enables autofix, snippets, diagnostics
- Enables inlay hints for types and parameters
- Enables semantic tokens for better highlighting

### `.editorconfig`

Ensures consistent formatting across editors:
- UTF-8 encoding
- LF line endings
- 4-space indentation for Zig
- 2-space for YAML/JSON

### `.gitignore`

Excludes build artifacts and IDE files from version control.

## CI/CD

GitHub Actions workflows automate quality checks:

### `ci.yml` - Continuous Integration

Runs on every push and PR:
1. Format check (`zig fmt --check`)
2. Build library and executable
3. Run all tests
4. Test on Linux, macOS, Windows

### `release.yml` - Release Automation

Runs on version tags (`v*`):
1. Cross-compile for multiple platforms
2. Package binaries
3. Create GitHub release with artifacts

## Design Principles

1. **Simplicity** - Solve one problem well
2. **Standard library first** - Avoid external dependencies
3. **Explicit ownership** - Clear memory management
4. **Composability** - Usable as library or CLI
5. **Testing** - Comprehensive test coverage
6. **Documentation** - Explain the "why"

## Future Enhancements

Potential improvements (not currently implemented):

- [ ] Support for custom headers
- [ ] Request/response streaming for large bodies
- [ ] Retry logic with exponential backoff
- [ ] Configuration file support
- [ ] Response caching
- [ ] Progress indicators for large downloads
- [ ] HTTP/2 and HTTP/3 support (when std.http adds it)

## Performance Considerations

- Uses buffered I/O for reading responses
- Allocates response body once (not chunk-by-chunk concatenation)
- JSON formatting creates temporary parse tree (trade-off for simplicity)

For production use with large responses, consider streaming instead of buffering.

## Cross-Platform Support

zighttp works on all Zig-supported platforms:
- Linux (x86_64, aarch64)
- macOS (x86_64, aarch64/M1)
- Windows (x86_64)
- WebAssembly (with appropriate HTTP adapter)

The standard library `std.http.Client` handles platform differences.

## Version Compatibility

**Minimum Zig version:** 0.15.2

This version introduced important std library stabilizations:
- `std.http.Client` API
- `std.json` improvements
- Module system

Earlier versions are not supported.
