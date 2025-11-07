# Contributing to zighttp

Thank you for your interest in contributing! This document provides guidelines for development.

## Getting Started

### Prerequisites

- Zig 0.15.2 or later
- Git
- (Optional) ZLS for editor integration
- (Optional) `act` for testing GitHub Actions locally

### Setup

1. Fork and clone the repository:
```bash
git clone https://github.com/yourusername/zighttp.git
cd zighttp
```

2. Verify your setup:
```bash
zig version  # Should be 0.15.2 or later
zig build
zig build test
```

3. Configure your editor:
   - VS Code: Install the official Zig extension
   - Neovim: Configure ZLS with nvim-lspconfig
   - Others: See ZLS documentation

## Development Workflow

### Making Changes

1. Create a feature branch:
```bash
git checkout -b feature/your-feature-name
```

2. Make your changes, following the code style guidelines below

3. Run tests frequently:
```bash
zig build test
```

4. Format your code:
```bash
zig fmt .
```

5. Commit with a clear message:
```bash
git commit -m "Add feature: description of change"
```

### Code Style

zighttp follows standard Zig conventions:

**Naming:**
- `camelCase` for functions and variables
- `PascalCase` for types (structs, enums)
- `SCREAMING_SNAKE_CASE` for constants

**Structure:**
- 4-space indentation (enforced by `zig fmt`)
- Max 100 characters per line (soft limit)
- Group related functions together
- Put tests at the bottom of the file

**Documentation:**
- Use `///` doc comments for public APIs
- Explain the "why" not just the "what"
- Include usage examples for complex functions
- Document memory ownership and lifetimes

**Example:**
```zig
/// Makes an HTTP request with the given arguments.
///
/// Returns a Response struct containing status code and body.
/// Caller owns returned memory and must call response.deinit().
///
/// Example:
/// ```zig
/// const response = try request(allocator, args);
/// defer response.deinit();
/// ```
pub fn request(allocator: Allocator, args: Args) !Response {
    // Implementation
}
```

### Testing Guidelines

**Unit Tests:**
- Co-locate tests with code using `test` blocks
- Test public APIs and error cases
- Keep tests focused and fast
- Use descriptive test names

**Integration Tests:**
- Place in `tests/` directory
- Test cross-module interactions
- Avoid network dependencies when possible
- Mock external dependencies

**Test Coverage:**
Aim for high coverage of:
- Happy paths
- Error conditions
- Edge cases
- Memory management (no leaks)

**Example:**
```zig
test "parse GET request" {
    const allocator = std.testing.allocator;

    const args = Args{
        .url = try allocator.dupe(u8, "https://example.com"),
        .method = .GET,
    };
    defer args.deinit(allocator);

    try std.testing.expectEqual(Method.GET, args.method);
}
```

### Commit Messages

Follow conventional commits format:

```
type(scope): short description

Longer explanation if needed.

Fixes #123
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test additions or fixes
- `refactor:` Code restructuring
- `perf:` Performance improvements
- `chore:` Build system, dependencies

**Examples:**
```
feat(client): add support for custom headers
fix(json): handle empty strings correctly
docs(readme): update installation instructions
test(args): add test for multiple flags
```

## Pull Request Process

1. **Update tests** - Add tests for new features or bug fixes

2. **Update documentation** - Keep README and ARCHITECTURE.md in sync

3. **Run quality checks:**
```bash
zig fmt --check .    # Code formatting
zig build test       # All tests pass
zig build            # Builds successfully
```

4. **Create pull request:**
   - Use a clear, descriptive title
   - Reference related issues
   - Describe what changed and why
   - Include testing notes

5. **Respond to feedback** - Address review comments promptly

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed the code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] Tests pass locally
- [ ] No new compiler warnings
```

## Project Structure

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

Quick reference:
- `src/main.zig` - CLI entry point
- `src/root.zig` - Library exports
- `src/args.zig` - Argument parsing
- `src/http_client.zig` - HTTP logic
- `src/json_formatter.zig` - JSON utilities
- `tests/` - Integration tests
- `build.zig` - Build configuration

## Common Tasks

### Adding a New Feature

1. Create new module in `src/` if substantial
2. Add to `src/root.zig` exports if public API
3. Write unit tests in the module
4. Add integration test in `tests/`
5. Update `build.zig` if needed
6. Document in README.md and ARCHITECTURE.md

### Fixing a Bug

1. Add a failing test that reproduces the bug
2. Fix the bug
3. Verify the test now passes
4. Add regression test if needed
5. Update documentation if behavior changed

### Improving Performance

1. Benchmark current performance
2. Make changes
3. Benchmark again to verify improvement
4. Ensure tests still pass
5. Document performance characteristics

## Release Process

(For maintainers)

1. Update version in `build.zig.zon`
2. Update CHANGELOG.md
3. Tag release: `git tag v0.x.y`
4. Push tag: `git push origin v0.x.y`
5. GitHub Actions automatically builds and publishes release

## Getting Help

- **Questions:** Open a GitHub Discussion
- **Bugs:** Open a GitHub Issue with reproduction steps
- **Features:** Open a GitHub Issue with use case description
- **Chat:** Join the Zig Discord server (#help channel)

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to learn and build great software.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
