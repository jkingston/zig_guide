# Contributing to Zig: Zero to Hero

Thank you for your interest in contributing! This guide is a community effort to provide comprehensive, production-focused Zig documentation.

---

## Quick Links

- **Report Issues:** [GitHub Issues](https://github.com/jkingston/zig_guide/issues)
- **View Progress:** [todo.md](todo.md)
- **AI Agent Instructions:** [AGENTS.md](AGENTS.md) (for AI-generated content)

---

## Getting Started

### Prerequisites

- **Zig 0.15.2** (for building examples)
- **mdBook** (for building the book)
- **Python 3.11+** (for validation scripts)
- **Git**

### Setup

```bash
# Clone the repository
git clone https://github.com/jkingston/zig_guide.git
cd zig_guide

# Update reference repositories (optional, for research)
./scripts/update_reference_repos.sh

# Build all examples
zig build

# Build the book
bash scripts/prepare-mdbook.sh
mdbook build
```

---

## Project Structure

```
zig_guide/
├── README.md                    # Project overview
├── todo.md                      # Task tracking and roadmap
├── CONTRIBUTING.md              # This file
├── AGENTS.md                    # AI agent instructions
├── style_guide.md               # Writing standards
├── references.md                # Authoritative sources
├── versioning.md                # Version support policy
├── book.toml                    # mdBook configuration
│
├── sections/                    # Source content for select chapters (7-13)
│   ├── 07_build_system/
│   │   ├── prompt.md            # AI generation prompt
│   │   └── content.md           # Chapter content
│   ├── 08_packages_dependencies/
│   ├── ...
│   └── 13_migration_guide/
│
├── examples/                    # Runnable code examples for all chapters
│   ├── appendix_b_zighttp/
│   │   ├── build.zig
│   │   └── zighttp/             # Complete example project
│   ├── ch01_introduction/
│   ├── ch01_idioms/
│   ├── ch02_memory/
│   ├── ...
│   └── ch14_appendices/
│
├── src/                         # mdBook generated sources (15 chapters)
│   ├── SUMMARY.md               # Table of contents
│   ├── README.md                # Book introduction
│   ├── ch01_quick_start.md      # Quick Start chapter
│   ├── ch01_language_idioms.md
│   ├── ...
│   └── ch14_appendices.md
│
├── scripts/
│   ├── prepare-mdbook.sh        # Prepare mdBook sources
│   ├── validate_sync.sh         # Validate examples compile
│   ├── extract_code_blocks.py   # Analyze code blocks
│   └── update_reference_repos.sh # Clone reference projects
│
└── reference_repos/             # Exemplar projects (git-ignored)
    ├── zig/
    ├── bun/
    ├── tigerbeetle/
    └── ...
```

---

## How to Contribute

### Reporting Issues

Found a bug, typo, or technical error?

1. Check [existing issues](https://github.com/jkingston/zig_guide/issues)
2. Create a new issue with:
   - Clear description
   - Location (chapter, section, line number)
   - Expected vs. actual behavior
   - Zig version (if code-related)

### Suggesting Improvements

Have ideas for new content or improvements?

1. Check [TODO.md](TODO.md) to see if it's already planned
2. Open an issue describing:
   - The improvement
   - Why it's valuable
   - Where it should go

### Contributing Content

Want to write or improve content?

1. **Check todo.md** for planned work
2. **Open an issue** to discuss your contribution first
3. **Follow the workflow** below

---

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-contribution
```

### 2. Make Changes

#### Editing Chapter Content

Most chapter source lives in `src/chXX_*.md`. Some chapters (7-13) also have source content in `sections/XX_name/content.md`:

```bash
# Edit chapter markdown directly
vim src/ch01_language_idioms.md

# Or edit section content (for chapters 7-13)
vim sections/07_build_system/content.md
```

**Important:**
- Follow [style_guide.md](style_guide.md)
- Use version markers: `✅ 0.15+` and `🕐 0.14.x`
- Include footnotes for all factual claims
- See [references.md](references.md) for authoritative sources

#### Adding/Editing Examples

Code examples live in `examples/chXX_name/`:

```bash
# Edit or add example
vim examples/ch01_idioms/01_naming_conventions.zig

# Test it compiles
cd examples/ch01_idioms
zig build
```

**Requirements:**
- All examples must compile on Zig 0.15.2
- Include necessary imports
- Keep examples minimal but complete
- Add to chapter's `build.zig` if creating new files

### 3. Validate Your Changes

```bash
# Validate all examples compile
bash scripts/validate_sync.sh

# Analyze code blocks
python3 scripts/extract_code_blocks.py sections/

# Build the book
bash scripts/prepare-mdbook.sh
mdbook build

# Preview locally
mdbook serve
# Visit http://localhost:3000
```

### 4. Commit Changes

```bash
git add .
git commit -m "type: concise description

Detailed explanation of changes if needed."
```

**Commit message types:**
- `docs:` - Documentation changes
- `feat:` - New features or content
- `fix:` - Bug fixes or corrections
- `refactor:` - Code restructuring
- `test:` - Test additions or changes
- `chore:` - Maintenance tasks

### 5. Push and Create PR

```bash
git push origin feature/your-contribution
```

Then create a Pull Request with:
- Clear description of changes
- Reference to related issues
- Checklist of validation steps completed

---

## Code Standards

### Zig Code Style

- Follow [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- Use `zig fmt` to format code
- Prefer `snake_case` for functions and variables
- Prefer `PascalCase` for types
- Keep lines under 100 characters when possible

### Example Requirements

- **Compilable:** Must compile on Zig 0.15.2
- **Complete:** Include all necessary imports
- **Minimal:** No unnecessary code
- **Documented:** Brief comments for complex logic only
- **Tested:** Include in chapter's `build.zig`

### Example Template

```zig
const std = @import("std");

pub fn main() !void {
    // Brief comment if needed
    const allocator = std.heap.page_allocator;

    // Your example code here
    const result = try doSomething(allocator);

    std.debug.print("Result: {}\n", .{result});
}
```

---

## Documentation Standards

### Markdown Formatting

- Use ATX-style headers (`#`, `##`, `###`)
- Code blocks must specify language: ` ```zig `
- Use fenced code blocks, not indented
- Include command-line prefix: `$ zig build`
- No trailing whitespace

### Version Markers

Indicate version-specific content:

```markdown
### ✅ 0.15+ Modern Approach
\```zig
const value = try parseValue();
\```

### 🕐 0.14.x Legacy Approach
\```zig
const value = parseValue() catch |err| return err;
\```
```

### Cross-References

Use relative links for internal references:

```markdown
See [Memory & Allocators](../03_memory_allocators/content.md) for details.
```

### Citations

All factual claims require footnotes:

```markdown
Zig uses comptime for compile-time execution.[^1]

[^1]: [Zig Language Reference - Comptime](https://ziglang.org/documentation/0.15.2/#comptime)
```

---

## Review Process

### PR Checklist

Before submitting, ensure:

- [ ] All examples compile (`bash scripts/validate_sync.sh`)
- [ ] Code follows style guide
- [ ] Documentation follows [style_guide.md](style_guide.md)
- [ ] Version markers used correctly
- [ ] All claims have citations
- [ ] mdBook builds successfully (`mdbook build`)
- [ ] Commit messages are clear and descriptive
- [ ] No unrelated changes included

### CI/CD Pipeline

Pull requests automatically run:
1. **Example Validation:** All examples compile on Zig 0.15.2
2. **Code Block Analysis:** Verifies code block metadata
3. **mdBook Build:** Ensures book builds successfully

PRs must pass all checks before merging.

### Review Criteria

Reviewers check:
- Technical accuracy
- Code quality and completeness
- Documentation clarity
- Adherence to style guide
- Proper citations
- No breaking changes

---

## Getting Help

- **Questions:** Open a [GitHub Discussion](https://github.com/jkingston/zig_guide/discussions)
- **Issues:** Report via [GitHub Issues](https://github.com/jkingston/zig_guide/issues)
- **Zig Help:** Visit [Zig Community](https://github.com/ziglang/zig/wiki/Community)

---

## Code of Conduct

- Be respectful and professional
- Focus on technical merit
- Welcome newcomers
- Provide constructive feedback
- Follow GitHub's [Community Guidelines](https://docs.github.com/en/site-policy/github-terms/github-community-guidelines)

---

## License

By contributing, you agree that your contributions will be licensed under the same license as this project.

---

**Thank you for contributing to Zig: Zero to Hero!** 🎉
