# Agent Workflow Guide

This document provides comprehensive instructions for AI agents working on the Zig Developer Guide project. It defines content generation workflows, quality standards, and validation procedures.

**Target Audience:** AI agents and human collaborators generating or reviewing technical content for this guide.

---

## Project Overview

The **Zig Developer Guide** is an in-progress technical book focused on idioms and best practices for Zig programming language versions **0.14.0, 0.14.1, 0.15.1, and 0.15.2**. The guide targets intermediate-to-advanced developers familiar with systems programming who need practical, authoritative guidance on idiomatic Zig development.

This is a comprehensive guide to Zig development, not a migration guide. Most content applies across all supported versions. When patterns differ between versions, the guide clearly marks version-specific code.

For complete project context, see [README.md](README.md).

---

## Content Generation Workflow

The project uses a template-driven approach to generate section-specific prompts:

```
metadata/sections.yaml
         ↓
scripts/generate_prompts_v3.py
         ↓
sections/XX_name/prompt.md
         ↓
[Agent generates content]
         ↓
sections/XX_name/content.md (or similar output)
```

### Step-by-Step Process

1. **Read Section Metadata**
   - Open [metadata/sections.yaml](metadata/sections.yaml)
   - Locate the section you are working on by `id` (e.g., `01_introduction`)
   - Review the section's `title`, `objective`, `overview`, `scope`, and `key_topics`

2. **Use Generated Prompt**
   - Navigate to the section directory (e.g., `sections/01_introduction/`)
   - Read the `prompt.md` file (generated from the template)
   - This prompt contains section-specific instructions for content generation

3. **Generate Content**
   - Follow the instructions in `prompt.md`
   - Adhere to all requirements in [style_guide.md](style_guide.md)
   - Use only authoritative sources from [references.md](references.md)

4. **Validate Output**
   - Self-review against the validation checklist (see below)
   - Ensure all code examples are runnable
   - Verify all citations are properly formatted

---

## Required Reading

Before generating any content, agents **must** review these documents:

| Document | Purpose | Priority |
|----------|---------|----------|
| [style_guide.md](style_guide.md) | Comprehensive writing and formatting standards | **Critical** |
| [references.md](references.md) | Authoritative sources and exemplar projects | **Critical** |
| [VERSIONING.md](VERSIONING.md) | Version support policy and update workflow | High |
| [templates/section_prompt_v3.md](templates/section_prompt_v3.md) | Template structure for understanding prompts | High |
| [README.md](README.md) | Project overview and requirements | High |

---

## Quality Standards

### Citation Requirements

All factual claims must have footnoted sources. Use the following source hierarchy (in order of preference):

1. **Official Zig Documentation**
   - Language reference
   - Standard library documentation
   - Release notes

2. **Official Zig GitHub Repositories**
   - ziglang/zig
   - Accepted proposals
   - Issue discussions

3. **Reputable Community Sources**
   - Zig.guide
   - ZigLearn
   - Community-maintained resources

4. **Recognized Open-Source Exemplars**
   - TigerBeetle
   - Ghostty
   - Bun
   - Mach engine

**Citation Format:**
```markdown
This is a factual claim requiring a citation.[^1]

[^1]: [Zig Language Reference](https://ziglang.org/documentation/0.15.2/)
```

### Code Example Standards

| Requirement | Standard |
|-------------|----------|
| **Language Specifier** | All code blocks must use ` ```zig ` |
| **Runnability** | Examples must compile under both 0.14.1 and 0.15.2 (or be version-marked) |
| **Completeness** | Include necessary imports and minimal setup |
| **Comments** | Use sparingly; prefer self-documenting code |
| **Ellipses** | Avoid `...` except for irrelevant boilerplate |

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const list = std.ArrayList(i32).init(allocator);
    defer list.deinit();
}
```

### Version Marker Usage

Use version markers to indicate version-specific features or changes:

- **✅ 0.15+** - Features/idioms introduced in Zig 0.15
- **🕐 0.14.x** - Legacy practices (pre-0.15)

**Example:**
```markdown
### ✅ 0.15+ Modern Approach

```zig
const value = try parseValue();
```

### 🕐 0.14.x Legacy Approach

```zig
const value = parseValue() catch |err| return err;
```
```

### Formatting Conventions

| Element | Convention |
|---------|-----------|
| **Voice** | Active voice preferred |
| **Tone** | Neutral, professional technical English |
| **Contractions** | Avoid (use "do not" instead of "don't") |
| **Metaphors** | Avoid; use literal technical descriptions |
| **Lists** | Use Oxford comma |
| **Spelling** | American English |
| **Units** | Always specify (bytes, ms, MiB) |
| **Commands** | Prefix with `$` for command-line examples |

---

## Validation Checklist

### Pre-Generation Checklist

Before starting content generation:

- [ ] Reviewed the section's `prompt.md` file
- [ ] Read [style_guide.md](style_guide.md) in full
- [ ] Identified authoritative sources from [references.md](references.md)
- [ ] Understood the section's `objective` and `scope` from [metadata/sections.yaml](metadata/sections.yaml)

### Post-Generation Validation

After generating content:

- [ ] All factual claims have footnoted sources
- [ ] All sources follow the citation hierarchy
- [ ] Code examples compile under both 0.14.1 and 0.15.2 (if applicable)
- [ ] Code blocks specify language (` ```zig `)
- [ ] Version markers are correctly applied (✅ 0.15+, 🕐 0.14.x)
- [ ] No speculative or unverifiable statements
- [ ] Consistent heading hierarchy (H1 → H2 → H3)
- [ ] No contractions, marketing language, or metaphors
- [ ] References section included at the end
- [ ] Cross-references use correct markdown anchor syntax
- [ ] Command-line examples use `$` prefix
- [ ] All units are specified (bytes, ms, etc.)

---

## Common Workflows

### Setting Up Reference Repositories

Before starting work on a section, ensure reference repositories are available:

```bash
./scripts/update_reference_repos.sh
```

This clones exemplar projects (zig, bun, tigerbeetle, ghostty, mach, zls, ziglings, zigmod, awesome-zig) to `reference_repos/` for pattern research. Run this once per session or when researching specific patterns.

### Generating a New Section

1. Ensure `sections/XX_name/prompt.md` exists (run `generate_prompts_v3.py` if needed)
2. Read the prompt file
3. Generate content following the required chapter structure
4. Place output in the section directory (e.g., `sections/XX_name/content.md`)
5. Run validation checklist

### Adding Cross-References

Use markdown anchor syntax for cross-references:

```markdown
See [Memory & Allocators](#03_memory_allocators) for details on allocator patterns.

For more information, refer to the [Error Handling section](sections/06_error_handling/content.md).
```

### Updating Content for Version Changes

When documenting version-specific changes:

1. Show **side-by-side comparisons** with version markers
2. Explain **why** the change occurred (not just what changed)
3. Provide **migration guidance** where applicable
4. Use the **Migration Guide (Section 14)** for complex version transitions

---

## File Structure Reference

```
zig_guide/
├── README.md                    # Project overview and agent requirements
├── AGENTS.md                    # This file - agent workflow guide
├── style_guide.md               # Writing and formatting standards (CRITICAL)
├── references.md                # Authoritative sources and exemplars (CRITICAL)
├── metadata/
│   └── sections.yaml            # Section definitions (source of truth)
├── templates/
│   └── section_prompt_v3.md     # Reusable template with placeholders
├── scripts/
│   ├── generate_prompts_v3.py           # Generates prompt.md from sections.yaml
│   └── update_reference_repos.sh        # Clones/updates exemplar projects
├── reference_repos/             # Cloned exemplar projects (git-ignored)
├── sections/                    # 15 chapter directories
│   ├── 01_introduction/
│   │   ├── prompt.md            # Generated section prompt
│   │   └── [content output]     # Agent-generated content goes here
│   ├── 02_language_idioms/
│   ├── 03_memory_allocators/
│   ├── 04_collections_containers/
│   ├── 05_io_streams/
│   ├── 06_error_handling/
│   ├── 07_async_concurrency/
│   ├── 08_build_system/
│   ├── 09_packages_dependencies/
│   ├── 10_project_layout_ci/
│   ├── 11_interoperability/
│   ├── 12_testing_benchmarking/
│   ├── 13_logging_diagnostics/
│   ├── 14_migration_guide/
│   └── 15_appendices/
├── references/                  # Placeholder for reference materials
└── assets/                      # Placeholder for images/diagrams
```

### Output Placement

- **Section Content**: Place in `sections/XX_name/` directory
- **Diagrams**: Place in `assets/` directory (use Mermaid syntax when possible)
- **Reference Materials**: Place in `references/` directory

---

## Key Principles

1. **Authoritative Sourcing**: All claims must be verifiable from official sources
2. **Version Awareness**: Clearly mark version-specific content
3. **Practical Examples**: Provide runnable, minimal code examples
4. **Neutral Tone**: Avoid marketing language, metaphors, and speculation
5. **Systematic Validation**: Use the checklists to ensure quality

---

## References

[^1]: [Zig Programming Language](https://ziglang.org/)
[^2]: [Zig 0.14.1 Documentation](https://ziglang.org/documentation/0.14.1/)
[^3]: [Zig 0.15.2 Documentation](https://ziglang.org/documentation/0.15.2/)
[^4]: [Zig Language Reference - Master](https://ziglang.org/documentation/master/)

---

**Last Updated**: 2025-11-02
