# Agent Instructions

**Target:** AI agents generating content for the Zig Developer Guide.

**Scope:** Zig versions 0.14.0, 0.14.1, 0.15.1, 0.15.2 targeting intermediate-to-advanced developers.

---

## Required Reading

Before generating content, read:
1. **[style_guide.md](style_guide.md)** - Writing and formatting standards (CRITICAL)
2. **[references.md](references.md)** - Authoritative sources only (CRITICAL)
3. **[VERSIONING.md](VERSIONING.md)** - Version support policy

---

## Content Generation

### Workflow
```
sections/XX_name/prompt.md → [Generate content] → sections/XX_name/content.md
```

### Process
1. Read `sections/XX_name/prompt.md`
2. Generate content following standards below
3. Validate using checklist

### Reference Repositories
```bash
./scripts/update_reference_repos.sh
```
Clones exemplar projects to `reference_repos/` for pattern research.

---

## Standards

### Citations
All factual claims require footnotes. Source hierarchy:
1. Official Zig docs/stdlib/release notes
2. ziglang/zig GitHub (proposals, issues)
3. Community sources (Zig.guide, ZigLearn)
4. Exemplar projects (TigerBeetle, Ghostty, Bun, Mach)

**Format:**
```markdown
Factual claim.[^1]

[^1]: [Source Name](https://url)
```

### Code Examples
- Always use ` ```zig ` language specifier
- Must compile on Zig 0.15.2 (or be version-marked)
- Include necessary imports
- Minimal, complete, runnable
- Avoid `...` ellipses

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const list = std.ArrayList(i32).init(allocator);
    defer list.deinit();
}
```

### Version Markers
- **✅ 0.15+** - Features/idioms in Zig 0.15+
- **🕐 0.14.x** - Legacy practices (pre-0.15)

**Example:**
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

### Formatting
- Active voice
- Neutral, professional tone
- No contractions ("do not" not "don't")
- No metaphors
- American English
- Oxford comma
- Specify units (bytes, ms, MiB)
- Command-line examples use `$` prefix

---

## Validation Checklist

### Before Generation
- [ ] Read `sections/XX_name/prompt.md`
- [ ] Read [style_guide.md](style_guide.md)
- [ ] Identified sources from [references.md](references.md)

### After Generation
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

---

## File Structure

```
zig_guide/
├── README.md                    # Project overview
├── TODO.md                      # Task tracking
├── AGENTS.md                    # This file
├── CONTRIBUTING.md              # Human contributor guide
├── style_guide.md               # Writing standards (CRITICAL)
├── references.md                # Authoritative sources (CRITICAL)
├── VERSIONING.md                # Version policy
├── metadata/sections.yaml       # Section definitions
├── scripts/
│   ├── update_reference_repos.sh
│   └── validate_sync.sh
├── reference_repos/             # Exemplar projects (git-ignored)
├── examples/                    # 16 chapter example directories
│   ├── ch00_professional_setup/
│   ├── ch01_introduction/
│   ├── ...
│   └── ch15_appendices/
└── sections/                    # 16 chapter directories
    ├── 00_professional_setup/
    │   ├── prompt.md            # Generated section prompt
    │   └── content.md           # Agent-generated content
    ├── 01_introduction/
    ├── ...
    └── 15_appendices/
```

---

## Key Principles

1. **Authoritative sourcing** - All claims verifiable from official sources
2. **Version awareness** - Mark version-specific content
3. **Practical examples** - Runnable, minimal code
4. **Neutral tone** - No marketing, metaphors, speculation
5. **Systematic validation** - Use checklists

---

**Last Updated:** 2025-11-09
