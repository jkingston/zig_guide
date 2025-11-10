# Zig Developer Guide — Section Deep Research Prompt (v3)

**Section:** Language Idioms & Core Patterns
**Objective:** Document idiomatic Zig syntax, naming conventions, and core language patterns.

## Context within the Guide
Establishes a shared idiomatic baseline used by all subsequent chapters.

## Scope
Focus on idioms and patterns; avoid deep dives into allocators, I/O, or build system details.

## Key Topics
- naming conventions and style
- defer and errdefer basics
- error unions vs optionals (conceptual)
- comptime and reflection fundamentals
- module organization and imports

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
# Language Idioms & Core Patterns

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
