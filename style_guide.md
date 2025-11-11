# Zig Developer Guide — Internal Style Guide

> Defines writing, formatting, and referencing conventions for all contributors and research agents.

---

## 0. Audience & Scope

This guide is intended for contributors and research agents working on the Zig Developer Guide. It assumes readers have intermediate-to-advanced knowledge of systems programming and familiarity with Zig. The guide focuses on internal consistency, clarity, and technical accuracy rather than introductory explanations.

---

## 1. Tone & Voice

- Use **neutral, professional technical English**.
- Write for an audience of **intermediate-to-advanced developers** familiar with systems programming.
- Avoid marketing language, metaphors, or anthropomorphism.
- Prefer active voice: “Use `defer` to release resources” rather than “`defer` should be used…”.

---

## 2. Structure & Formatting

### Headings
- Each section starts with `# Section Title` followed by a short summary.
- Use `##` and `###` for subsections; avoid deeper nesting unless strictly necessary.

### Code Blocks
- All code examples must specify the language:  
  ```zig
  const std = @import("std");
  ```
- Show concise, runnable examples; avoid ellipses (`...`) except for irrelevant boilerplate.
- Use inline comments sparingly for emphasis.
- Runnable means the example should compile and run without modification in the specified Zig version, demonstrating the concept clearly.
- Include necessary imports, variable declarations, and minimal setup.
- Avoid dependencies on external files or complex environment setup.
- When demonstrating output, include expected results immediately after the code block or in a separate output block.
- If the output is non-trivial, provide a brief explanation.

### Output and Logs
- Outputs and logs should be shown in fenced code blocks without language specifiers.
- Prefix command-line inputs or shell prompts with `$` to distinguish user input from program output.
- Example:
  ```
  $ zig run main.zig
  Hello, world!
  ```

### Diagrams
- Use Mermaid syntax for diagrams where appropriate, enclosed in fenced code blocks with `mermaid` language tag.
- ASCII diagrams are acceptable for simple illustrations.
- Diagrams should not exceed 80 characters in width for readability.

### Lists
- Use ordered lists for sequences, unordered for related items.
- Keep list items concise (one sentence per bullet, ideally).

### Callouts
- Use version markers:
  - ✅ **0.15+** for features or idioms introduced in Zig 0.15
  - 🕐 **0.14.x** for legacy practices
- For differences, provide a short comparative snippet or explanation.

---

## 3. Referencing & Citations

### Source Hierarchy
When asserting facts, cite the most authoritative available source in this order:
1. Official Zig documentation or release notes
2. Official Zig GitHub repositories
3. Reputable community sources (Zig.guide, ZigLearn, Zig by Example)
4. Recognized open-source exemplars (TigerBeetle, Ghostty, Bun, Mach)

### Inline Citations
Use markdown footnotes or link-style references immediately after the relevant statement:

Example:
> Zig uses a single global allocator for `std.heap.page_allocator`.[^1]

[^1]: [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)

### Internal Cross-References
Link between sections within the guide using markdown links with section anchors. Use consistent section titles for clarity and maintainability. For example:
> See [2. Structure & Formatting](#2-structure--formatting) for formatting rules.

---

## 4. Terminology & Style

- Use American English spelling (`initialization`, `behavior`, `color`).
- Format Zig keywords and symbols with backticks.
- Use “Zig standard library” or **stdlib** (lowercase) consistently.
- Avoid contractions (`don’t` → `do not`).
- Always include units (`bytes`, `ms`, `MiB`) for measurements.

### Grammar & Punctuation
- Use the Oxford comma in lists for clarity.
- Spell out abbreviations on first use, followed by the abbreviation in parentheses if used repeatedly.
- Use en dashes (–) for ranges (e.g., “pages 10–15”) and hyphens (-) for compound words.

---

## 5. Cross-Version Consistency

When describing APIs or idioms that differ between Zig 0.14 and 0.15:
- Present both side by side where possible.
- Explain *why* a change occurred (e.g., improved safety, simpler semantics).
- Include a small migration example when feasible.

Example:
```zig
// 🕐 0.14.x
const allocator = std.heap.ArenaAllocator.init(gpa);

// ✅ 0.15+
const allocator = std.heap.ArenaAllocator.initDefault();
```

For differing outputs between versions, label each output with the version marker:

```text
// 🕐 0.14.x output
Error: expected type 'u32', found 'i32'

// ✅ 0.15+ output
error: expected 'u32', got 'i32'
```

---

## 6. Review & Verification Checklist

Before finalizing a section:
- [ ] All factual claims have footnoted sources.
- [ ] Code examples compile under both 0.14.1 and 0.15.2 (if applicable).
- [ ] No speculative or unverifiable statements.
- [ ] Consistent heading hierarchy and markdown formatting.
- [ ] All version markers correctly applied.
- [ ] References section included.

---

## 7. Example Citation Block (end of section)

```markdown
---

### References

1. [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/)
2. [TigerBeetle GitHub Repository](https://github.com/tigerbeetle/tigerbeetle)
3. [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)
4. [Zig Build System Guide](https://zig.guide/build-system/)
```

---

## 8. Metadata Conventions

All guide sections should begin with a YAML metadata header specifying title, authors, and date. Example:

```yaml
---
title: "Section Title"
authors:
  - "Contributor Name"
date: "YYYY-MM-DD"
---
```

---

## 9. Accessibility & Readability

- Use short paragraphs and sentences to improve readability.
- Avoid jargon unless defined or widely understood.
- Use high-contrast colors for any syntax highlighting or diagrams.
- Ensure diagrams and code blocks are accessible with screen readers where possible.

---

## 10. Contributor Notes

Contributors may include an optional footer with notes or acknowledgments at the end of a section, separated by a horizontal rule. This is not mandatory and should not contain technical content.

---

This style guide is mandatory for all research agents and human contributors.
Adhering to it ensures the Zig Developer Guide remains consistent, verifiable, and idiomatically accurate.
