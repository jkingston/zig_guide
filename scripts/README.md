# Zig Guide Scripts

This directory contains utility scripts for managing the Zig Guide project.

## Zig Version Management

### download_zig_versions.sh

Downloads multiple Zig versions for testing code examples across versions.

**Usage:**
```bash
./scripts/download_zig_versions.sh
```

**Downloaded versions:**
- Zig 0.14.0
- Zig 0.14.1
- Zig 0.15.1
- Zig 0.15.2

**Install location:** `zig_versions/` (gitignored)

**Features:**
- Automatic platform detection (Linux/macOS, x86_64/aarch64)
- Retry logic for failed downloads
- Verification of installed versions

### test_example.sh

Tests a Zig code example against one or more installed versions.

**Usage:**
```bash
# Test against all installed versions
./scripts/test_example.sh sections/05_io_streams/example_basic_writer.zig

# Test against specific versions
./scripts/test_example.sh sections/05_io_streams/example_basic_writer.zig 0.15.1 0.15.2

# Run examples after compilation (optional)
RUN_EXAMPLES=1 ./scripts/test_example.sh sections/05_io_streams/example_basic_writer.zig
```

**Output:**
- Compilation results for each version
- Success/failure summary
- Exit code 1 if any compilation fails

## Reference Repository Management

### update_reference_repos.sh

Clones or updates reference repositories used for research.

**Usage:**
```bash
./scripts/update_reference_repos.sh
```

**Cloned repositories:**
- zig (compiler with docs)
- tigerbeetle, ghostty, bun, mach, zls (production projects)
- ziglings, zigmod, awesome-zig (learning resources)

**Install location:** `reference_repos/` (gitignored)

## Examples

**Download all Zig versions before testing:**
```bash
./scripts/download_zig_versions.sh
```

**Test an example across all versions:**
```bash
./scripts/test_example.sh sections/05_io_streams/example_file_io.zig
```

**Test and run an example:**
```bash
RUN_EXAMPLES=1 ./scripts/test_example.sh sections/05_io_streams/example_buffering.zig 0.15.2
```

**Use a specific Zig version manually:**
```bash
zig_versions/zig-0.14.0/zig build-exe example.zig
zig_versions/zig-0.15.2/zig build-exe example.zig
```
