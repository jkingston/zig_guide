# Zig Developer Guide — Section Deep Research Prompt (v3)

**Section:** Packages & Dependencies (build.zig.zon)
**Objective:** Explain Zig’s package and dependency management using build.zig.zon.

## Context within the Guide
Covers reproducible dependency graphs and the everyday developer workflow.

## Scope
build.zig.zon structure, zig fetch workflow, checksums and locking, local vs remote packages.

## Key Topics
- build.zig.zon anatomy
- zig fetch workflow
- checksums and locks
- integrating deps in build.zig

---

### Instructions
- Use tone/formatting from `style_guide.md` (global for the book).
- Cite sources from `references.md` where possible; include URLs in a final `## References` section.
- Output **only Markdown** suitable for publication (no meta commentary).
- Provide **4–6 runnable Zig examples** and explain them inline.
- Label any version-specific code with ✅ 0.15+ or 🕐 0.14.x.
- Prefer examples grounded in official docs or well-known OSS projects referenced in `references.md`.
- Use the Key Topics as a starting point, if there's anything missing or incorrect use your judgement to add it.

### Required Chapter Structure
```markdown
# Packages & Dependencies (build.zig.zon)

## Overview
Explain the purpose of this chapter and why it matters in Zig development.

## Core Concepts
Teach the key ideas listed above with clear, example-driven exposition.

## Code Examples
Provide multiple runnable Zig snippets and explain what each demonstrates.

## Common Pitfalls
List frequent mistakes or legacy practices and show safer alternatives.

## In Practice
Briefly point to real-world usage (link to repos or files cited in references).

## Summary
Reinforce the mental model and when to use which patterns.

## References
Numbered list of URLs for all citations used in this chapter.
```
