# Zig Developer Guide — Internal Style Guide

> Defines writing, formatting, and referencing conventions for all contributors and research agents.

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

### Reference Lists
At the end of each section, include a **References** block listing all URLs cited in that file.

---

## 4. Terminology & Style

- Use American English spelling (`initialization`, `behavior`, `color`).
- Format Zig keywords and symbols with backticks.
- Use “Zig standard library” or **stdlib** (lowercase) consistently.
- Avoid contractions (`don’t` → `do not`).
- Always include units (`bytes`, `ms`, `MiB`) for measurements.

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

This style guide is mandatory for all research agents and human contributors.
Adhering to it ensures the Zig Developer Guide remains consistent, verifiable, and idiomatically accurate.
