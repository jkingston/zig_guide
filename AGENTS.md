# Zig: Zero to Hero

AI-assisted technical writing project for comprehensive Zig 0.14.x-0.15.x guide targeting experienced developers.

**What you'll work on:** Generating technical documentation content following strict citation and code standards.

---

## Core Commands

```bash
# Build all examples
zig build

# Validate examples compile
bash scripts/validate_sync.sh

# Analyze code blocks
python3 scripts/extract_code_blocks.py sections/

# Build the book
bash scripts/prepare-mdbook.sh && mdbook build

# Serve locally (preview)
mdbook serve

# Update reference repos (for research)
./scripts/update_reference_repos.sh
```

---

## Project Layout

```
sections/XX_name/
  ├── prompt.md       # Your instructions for this chapter
  └── content.md      # Generated content goes here

examples/           # Runnable examples (must compile on Zig 0.15.2)
  ├── ch01_introduction/
  ├── ch01_idioms/
  ├── ...
  └── appendix_b_zighttp/  # Each with build.zig files

Key files:
├── style_guide.md    # Writing standards (READ THIS)
├── references.md     # Authoritative sources only (READ THIS)
└── versioning.md     # Version support policy
```

---

## Development Patterns

### Content Generation Workflow
```
1. Read sections/XX_name/prompt.md
2. Generate content following standards below
3. Save to sections/XX_name/content.md
4. Validate using checklist
```

### Critical Rules

**Citations:**
- All factual claims require footnoted sources
- Source hierarchy: Official Zig docs → ziglang/zig GitHub → Community sources → Exemplar projects
- Format: `Claim.[^1]` then `[^1]: [Source](url)`

**Code:**
- Always use ` ```zig ` language specifier
- Must compile on Zig 0.15.2 (or be version-marked)
- Include imports, keep minimal but complete
- No `...` ellipses

**Version Markers:**
- `✅ 0.15+` for Zig 0.15+ features
- `🕐 0.14.x` for legacy practices

**Style:**
- Active voice, neutral tone
- No contractions ("do not" not "don't")
- No metaphors or marketing language
- Specify units (bytes, ms, MiB)
- Command examples: `$ zig build`

---

## Git Workflow Essentials

**Before committing:**
- Validate all examples compile: `bash scripts/validate_sync.sh`
- Check style guide adherence
- Verify all citations present

**Branch naming:** Descriptive names for content work

---

## Key Files - Read Before Contributing

1. **[style_guide.md](style_guide.md)** - Writing and formatting standards (CRITICAL)
2. **[references.md](references.md)** - Authoritative sources only (CRITICAL)
3. **[versioning.md](versioning.md)** - Version support policy
4. **`sections/XX_name/prompt.md`** - Section-specific instructions

---

## Detailed Standards Reference

### Code Example Template

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const list = std.ArrayList(i32).init(allocator);
    defer list.deinit();
}
```

### Version Marker Usage

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

### Validation Checklist

**Before Generation:**
- [ ] Read `sections/XX_name/prompt.md`
- [ ] Read [style_guide.md](style_guide.md)
- [ ] Identified sources from [references.md](references.md)

**After Generation:**
- [ ] All claims have footnoted sources
- [ ] Sources follow citation hierarchy
- [ ] Code examples compile on Zig 0.15.2
- [ ] Code blocks use ` ```zig `
- [ ] Version markers applied correctly
- [ ] No speculation or unverifiable statements
- [ ] Consistent heading hierarchy (H1 → H2 → H3)
- [ ] No contractions, marketing language, metaphors
- [ ] Command-line examples use `$` prefix
- [ ] Units specified (bytes, ms, etc.)

### Reference Repositories

The `reference_repos/` directory contains exemplar Zig projects for pattern research.

**Primary Exemplar Projects** (deeply integrated with 476+ citations in guide):
- **TigerBeetle** (164 citations) - Testing, correctness, data integrity patterns
- **Ghostty** (101 citations) - Cross-platform abstractions, C/Swift interop
- **Bun** (97 citations) - Async I/O, concurrency, high-performance patterns
- **ZLS** (87 citations) - Tooling, build integration, testing utilities
- **Mach** (27+ citations) - Game engine architecture, modular design
- **zig** (40+ citations) - Compiler and stdlib, canonical idiomatic patterns

**Additional References** (domain-specific examples):
- zig-gamedev, zap, zigimg, zig-ci-template

**Learning Resources** (not architectural exemplars):
- ziglings, awesome-zig

Clone/update with: `./scripts/update_reference_repos.sh`

---

## Complete File Structure

```
zig_guide/
├── README.md                    # Project overview
├── todo.md                      # Task tracking
├── AGENTS.md                    # This file
├── CONTRIBUTING.md              # Human contributor guide
├── style_guide.md               # Writing standards (CRITICAL)
├── references.md                # Authoritative sources (CRITICAL)
├── versioning.md                # Version support policy
├── metadata/sections.yaml       # Section definitions
├── scripts/
│   ├── update_reference_repos.sh
│   ├── validate_sync.sh
│   ├── prepare-mdbook.sh
│   └── extract_code_blocks.py
├── reference_repos/             # Exemplar projects (git-ignored)
├── examples/                    # Runnable code examples for all chapters
│   ├── appendix_b_zighttp/
│   ├── ch01_introduction/
│   ├── ch01_idioms/
│   ├── ch02_memory/
│   ├── ...
│   └── ch14_appendices/
├── sections/                    # Source content for select chapters (7-13)
│   ├── 07_build_system/
│   │   ├── prompt.md            # Section prompt
│   │   └── content.md           # Chapter content
│   ├── 08_packages_dependencies/
│   ├── ...
│   └── 13_migration_guide/
└── src/                         # mdBook generated sources (15 chapters)
    ├── SUMMARY.md               # Table of contents
    ├── ch01_quick_start.md
    ├── ch01_language_idioms.md
    ├── ...
    └── ch14_appendices.md
```

---

## Key Principles

1. **Authoritative sourcing** - All claims verifiable from official sources
2. **Version awareness** - Mark version-specific content
3. **Practical examples** - Runnable, minimal code
4. **Neutral tone** - No marketing, metaphors, speculation
5. **Systematic validation** - Use checklists

---

**Last Updated:** 2025-11-11
