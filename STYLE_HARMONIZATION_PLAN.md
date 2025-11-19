# Zig Guide: Style Harmonization Implementation Plan

**Created:** 2025-11-19
**Based on:** STYLE_REVIEW_REPORT.md
**Estimated Total Effort:** 7-12 hours
**Target Completion:** [To be determined]

---

## Plan Overview

This plan addresses all 12 categories of style inconsistencies identified in the comprehensive style review. Work is organized into 3 phases based on priority and dependencies.

### Success Criteria
- [ ] All TL;DR sections follow standardized format
- [ ] Version markers (🕐/✅) used consistently throughout
- [ ] All "In Practice" sections use uniform structure
- [ ] Code examples use standardized ❌/✅ annotations
- [ ] Heading capitalization follows title case rules
- [ ] References use consistent citation format
- [ ] Cross-references follow standardized patterns
- [ ] Summary sections use standardized structure
- [ ] Tables formatted consistently
- [ ] Emoji usage standardized
- [ ] Example files organized in consistent directory structure
- [ ] Minor style issues resolved (punctuation, spacing, line length)

---

## Phase 1: High Priority (Critical for Readability)
**Estimated Effort:** 4-6 hours
**Focus:** Reader-facing elements that affect comprehension

### Task 1.1: Standardize TL;DR Sections (2 hours)

**Scope:** All chapter files (ch01-ch14, appendices)

**Standard Template:**
```markdown
> **TL;DR for [target audience]:**
> - **[Key concept 1]:** Brief description with code example
> - **[Key concept 2]:** Brief description with code example
> - **[Key concept 3]:** Brief description with code example
> - **[Breaking change/important note]:** Version-specific information
> - **[Performance/pattern tip]:** Practical guidance
> - **Jump to:** [Section §X.Y](#anchor) | [Section §X.Z](#anchor) | [Section §X.W](#anchor)
```

**Files to Update:**
- [ ] `src/README.md` - Add TL;DR if missing
- [ ] `src/ch01_quick_start.md` - Standardize format
- [ ] `src/ch02_syntax_essentials.md` - Standardize format
- [ ] `src/ch03_language_idioms.md` - Standardize format
- [ ] `src/ch04_memory_allocators.md` - Standardize format
- [ ] `src/ch05_collections_containers.md` - Standardize format
- [ ] `src/ch06_io_streams.md` - Already good, verify completeness
- [ ] `src/ch07_error_handling.md` - Standardize format
- [ ] `src/ch08_async_concurrency.md` - Already good, verify completeness
- [ ] `src/ch09_build_system.md` - Standardize format
- [ ] `src/ch10_packages_dependencies.md` - Standardize format
- [ ] `src/ch11_project_layout_ci.md` - Expand to full format
- [ ] `src/ch12_interoperability.md` - Standardize format
- [ ] `src/ch13_testing_benchmarking.md` - Already good, verify completeness
- [ ] `src/ch14_logging_diagnostics.md` - Standardize format
- [ ] `src/appendix_a_working_with_014.md` - Add TL;DR
- [ ] `src/appendix_b_migration_014_015.md` - Add TL;DR
- [ ] `src/ch16_appendices.md` - Verify TL;DR format

**Implementation Steps:**
1. Extract existing TL;DR content from each chapter
2. Identify 5-7 key concepts per chapter
3. Add version-specific notes where applicable
4. Create 3-4 jump links to critical sections
5. Format consistently with template
6. Verify anchor links work correctly

**Validation:**
- All chapters have TL;DR sections
- Each TL;DR has 5-7 bullet points
- Each includes jump links (3-4 minimum)
- Version-specific content marked clearly
- Formatting matches template exactly

---

### Task 1.2: Standardize Version Markers (1 hour)

**Scope:** All code examples with version-specific differences

**Standard Usage:**
```markdown
🕐 **0.14.x:**
```zig
// Old pattern code
```

✅ **0.15+:**
```zig
// New pattern code
```
```

**Files to Audit:**
- [ ] `src/ch04_memory_allocators.md` - Add version markers to allocator examples
- [ ] `src/ch05_collections_containers.md` - Mark managed vs unmanaged patterns
- [ ] `src/ch06_io_streams.md` - Already good, verify consistency
- [ ] `src/ch09_build_system.md` - Mark build.zig API changes
- [ ] `src/ch10_packages_dependencies.md` - Mark module system changes
- [ ] `src/ch11_project_layout_ci.md` - Verify version markers
- [ ] `src/ch12_interoperability.md` - Add markers where missing
- [ ] `src/appendix_a_working_with_014.md` - Verify all examples marked
- [ ] `src/appendix_b_migration_014_015.md` - Verify all examples marked

**Implementation Steps:**
1. Search for version-specific code examples
2. Add 🕐 **0.14.x:** before legacy patterns
3. Add ✅ **0.15+:** before current patterns
4. Ensure both versions shown where API changed
5. Add explanatory text about why change occurred

**Validation:**
- All version-specific code has emoji markers
- Both versions shown for breaking changes
- Markers used consistently (not just section headers)
- Brief explanation provided for major changes

---

### Task 1.3: Standardize "In Practice" Sections (2 hours)

**Scope:** All chapters with production codebase examples

**Standard Structure:**
```markdown
## In Practice

### [Project Name]: [Overall Pattern/Theme]

**[Specific Pattern Name]:**

[Brief description of the pattern and why it's used]

**Source:** [`src/path/file.zig:L123-L456`](https://github.com/org/repo/blob/commit/src/path/file.zig#L123-L456)

```zig
// Relevant code excerpt (10-30 lines)
```

**Key Patterns:**
- Pattern 1: Description
- Pattern 2: Description
- Pattern 3: Description

**Rationale:** Why this approach works for this project

---

### [Next Project Name]: [Pattern/Theme]
...
```

**Files to Update:**
- [ ] `src/ch04_memory_allocators.md` - Restructure "In Practice"
- [ ] `src/ch05_collections_containers.md` - Restructure "In Practice"
- [ ] `src/ch06_io_streams.md` - Standardize existing structure
- [ ] `src/ch07_error_handling.md` - Restructure "In Practice"
- [ ] `src/ch08_async_concurrency.md` - Already good, minor adjustments
- [ ] `src/ch09_build_system.md` - Restructure "In Practice"
- [ ] `src/ch10_packages_dependencies.md` - Already good, verify format
- [ ] `src/ch11_project_layout_ci.md` - Restructure "In Practice"
- [ ] `src/ch12_interoperability.md` - Standardize mixed structure
- [ ] `src/ch13_testing_benchmarking.md` - Restructure "In Practice"
- [ ] `src/ch14_logging_diagnostics.md` - Restructure "In Practice"

**Implementation Steps:**
1. Identify all "In Practice" sections
2. Group by project, then by pattern within project
3. Add source citations with exact line numbers
4. Extract or trim code excerpts to 10-30 lines
5. Add "Key Patterns" bullet list
6. Add "Rationale" explanation
7. Verify all GitHub links work

**Validation:**
- Consistent project → pattern → source structure
- All code excerpts have GitHub links with line numbers
- Key patterns summarized in bullets
- Rationale explains why pattern chosen
- No mixed organizational approaches

---

### Task 1.4: Standardize Code Example Annotations (1 hour)

**Scope:** All code examples showing good vs bad patterns

**Standard Format:**
```markdown
// ❌ BAD: Brief explanation of why this is wrong
```zig
// Anti-pattern code
```

// ✅ GOOD: Brief explanation of why this is correct
```zig
// Correct pattern code
```
```

**Files to Audit:**
- [ ] `src/ch03_language_idioms.md` - Standardize annotations
- [ ] `src/ch04_memory_allocators.md` - Standardize annotations
- [ ] `src/ch05_collections_containers.md` - Standardize annotations
- [ ] `src/ch06_io_streams.md` - Already good, verify consistency
- [ ] `src/ch07_error_handling.md` - Standardize annotations
- [ ] `src/ch08_async_concurrency.md` - Standardize annotations
- [ ] `src/ch09_build_system.md` - Standardize annotations
- [ ] `src/ch11_project_layout_ci.md` - Standardize annotations
- [ ] `src/ch12_interoperability.md` - Standardize mixed styles
- [ ] `src/ch13_testing_benchmarking.md` - Standardize annotations
- [ ] `src/ch16_appendices.md` - Standardize annotations (many examples)

**Implementation Steps:**
1. Search for all ❌/✅ usage
2. Ensure consistent labels: "BAD" or "WRONG" / "GOOD" or "CORRECT"
3. Add brief "why" explanation after colon
4. Ensure bad example shown before good example
5. Group related examples together

**Validation:**
- All anti-patterns use ❌ BAD or ❌ WRONG
- All correct patterns use ✅ GOOD or ✅ CORRECT
- Brief explanation provided after colon
- Bad examples always precede good examples
- No orphaned annotations without code

---

## Phase 2: Medium Priority (Professional Appearance)
**Estimated Effort:** 2-4 hours
**Focus:** Consistency and professional polish

### Task 2.1: Standardize Heading Capitalization (45 minutes)

**Scope:** All headings in all files

**Standard:** Title Case
- Capitalize: Major words, first/last words, Zig keywords
- Lowercase: Articles (a, an, the), conjunctions (and, but, or), short prepositions (in, on, at, for, to)

**Examples:**
- ✅ "Collections and Containers"
- ✅ "The Build System"
- ✅ "Working with std.testing Module"
- ❌ "Collections And Containers"
- ❌ "The build system"
- ❌ "working with std.testing module"

**Files to Audit:**
- [ ] All chapter files (ch01-ch14)
- [ ] All appendix files
- [ ] SUMMARY.md
- [ ] README.md

**Implementation Steps:**
1. Use regex to find all markdown headings: `^#{1,4} .+$`
2. Review each heading for title case compliance
3. Fix capitalization errors
4. Special attention to Zig-specific terms (keep original case)

**Validation:**
- All headings use title case
- Zig keywords/modules capitalized correctly
- Consistent across all files

---

### Task 2.2: Standardize Reference Formatting (1 hour)

**Scope:** All footnotes and citations

**Standard Format:**
```markdown
[^N]: [Source Title](URL) — Brief description
```

**Examples:**
```markdown
[^1]: [Zig Language Reference 0.15.2](https://ziglang.org/documentation/0.15.2/#cImport) — @cImport builtin documentation
[^2]: [TigerBeetle src/io/linux.zig:L1433-L1570](https://github.com/tigerbeetle/tigerbeetle/blob/dafb825b.../src/io/linux.zig#L1433-L1570) — Direct I/O implementation
```

**Files to Update:**
- [ ] `src/ch04_memory_allocators.md` - Standardize references
- [ ] `src/ch05_collections_containers.md` - Standardize references
- [ ] `src/ch06_io_streams.md` - Update to standard format
- [ ] `src/ch07_error_handling.md` - Standardize references
- [ ] `src/ch08_async_concurrency.md` - Update to standard format
- [ ] `src/ch09_build_system.md` - Standardize references
- [ ] `src/ch10_packages_dependencies.md` - Standardize references
- [ ] `src/ch11_project_layout_ci.md` - Standardize references
- [ ] `src/ch12_interoperability.md` - Update to standard format
- [ ] `src/ch13_testing_benchmarking.md` - Standardize references
- [ ] `src/ch14_logging_diagnostics.md` - Standardize references
- [ ] `src/ch16_appendices.md` - Standardize references

**Implementation Steps:**
1. Locate all footnote references: `[^N]:`
2. Reformat to standard: `[Source Title](URL) — Description`
3. Ensure all URLs are valid and accessible
4. Add brief descriptions where missing
5. Renumber footnotes sequentially if needed

**Validation:**
- All footnotes use standard format
- All URLs valid and working
- Brief descriptions present
- Sequential numbering per chapter

---

### Task 2.3: Standardize Cross-References (30 minutes)

**Scope:** Internal links between chapters/sections

**Standard Formats:**

**Major cross-references (blockquote):**
```markdown
> **See also:** Chapter 4 (Memory & Allocators) for allocator patterns used in image decoding.
```

**Minor cross-references (parenthetical):**
```markdown
Error handling with defer (see Chapter 7) ensures proper cleanup.
```

**Section-specific:**
```markdown
See [§4.2 Allocator Patterns](#allocator-patterns) for details.
```

**Files to Audit:**
- [ ] All chapter files for cross-references
- [ ] Verify all anchor links work

**Implementation Steps:**
1. Find all cross-references using grep
2. Categorize as major or minor
3. Apply appropriate format
4. Verify anchor links exist and are correct
5. Add missing links where helpful

**Validation:**
- Major cross-references use blockquote format
- Minor cross-references use parenthetical format
- All anchor links verified working
- Consistent chapter reference format

---

### Task 2.4: Standardize Summary Sections (1 hour)

**Scope:** All chapter summary sections

**Standard Structure:**
```markdown
## Summary

[One-sentence chapter recap]

**[Topic 1]:**
- Key point 1
- Key point 2
- Key point 3

**[Topic 2]:**
- Key point 1
- Key point 2

**When to use:**
- Use X when [condition]
- Use Y when [condition]

**Common pitfalls:**
- Avoid A because [reason]
- Remember B to prevent [issue]

**Looking ahead:**
[Optional: Brief transition to next chapter topic]
```

**Files to Update:**
- [ ] `src/ch01_quick_start.md` - Restructure summary
- [ ] `src/ch02_syntax_essentials.md` - Restructure summary
- [ ] `src/ch03_language_idioms.md` - Restructure summary
- [ ] `src/ch04_memory_allocators.md` - Restructure summary
- [ ] `src/ch05_collections_containers.md` - Restructure summary
- [ ] `src/ch06_io_streams.md` - Update to standard structure
- [ ] `src/ch07_error_handling.md` - Restructure summary
- [ ] `src/ch08_async_concurrency.md` - Update to standard structure
- [ ] `src/ch09_build_system.md` - Restructure summary
- [ ] `src/ch10_packages_dependencies.md` - Restructure summary
- [ ] `src/ch11_project_layout_ci.md` - Update to standard structure
- [ ] `src/ch12_interoperability.md` - Restructure summary
- [ ] `src/ch13_testing_benchmarking.md` - Restructure summary
- [ ] `src/ch14_logging_diagnostics.md` - Restructure summary

**Implementation Steps:**
1. Extract key concepts from each chapter
2. Organize into thematic subsections
3. Add "When to use" decision framework
4. Add "Common pitfalls" reminders
5. Add optional "Looking ahead" transition

**Validation:**
- One-sentence opening recap
- 2-4 thematic subsections with bullets
- "When to use" decision guidance
- "Common pitfalls" section
- Consistent structure across all chapters

---

## Phase 3: Low Priority (Polish & Fine Details)
**Estimated Effort:** 1-2 hours
**Focus:** Visual consistency and fine-tuning

### Task 3.1: Standardize Table Formatting (30 minutes)

**Scope:** All markdown tables

**Standard Format:**
```markdown
| Left Column | Right Column | Numeric |
|:------------|:-------------|--------:|
| Text value  | Text value   |      42 |
| Text value  | Text value   |     100 |
```

**Rules:**
- Left-align text columns (`:---`)
- Right-align numeric columns (`---:`)
- Center-align when semantically appropriate (`:---:`)
- Keep tables under 120 characters wide
- Use consistent spacing

**Files to Audit:**
- [ ] `src/ch05_collections_containers.md` - Format tables
- [ ] `src/ch06_io_streams.md` - Verify table formatting
- [ ] `src/ch09_build_system.md` - Format tables
- [ ] `src/ch11_project_layout_ci.md` - Format tables
- [ ] `src/ch12_interoperability.md` - Format tables
- [ ] `src/ch16_appendices.md` - Format many reference tables
- [ ] `src/appendix_a_working_with_014.md` - Format comparison tables
- [ ] `src/appendix_b_migration_014_015.md` - Format migration tables

**Implementation Steps:**
1. Find all markdown tables
2. Adjust column alignment markers
3. Ensure consistent spacing
4. Verify width under 120 characters
5. Consider splitting overly wide tables

**Validation:**
- All tables have proper alignment markers
- Consistent spacing throughout
- No tables exceed 120 character width
- Headers clearly separated from content

---

### Task 3.2: Standardize Emoji Usage (20 minutes)

**Scope:** All files using emoji markers

**Standard Usage:**
- ✅ Good/correct patterns
- ❌ Bad/incorrect patterns
- ⚠️ Warnings and important notes
- 💡 Tips and best practices
- 🕐 Legacy/deprecated (0.14.x)

**Avoid:**
- Excessive emoji decoration
- Emoji in headings
- Emoji in technical terms

**Files to Audit:**
- [ ] All chapter files for consistent emoji use
- [ ] Remove excessive/decorative emoji
- [ ] Ensure warnings use ⚠️

**Implementation Steps:**
1. Search for all emoji usage
2. Verify appropriate context
3. Replace inconsistent emoji with standard set
4. Remove decorative emoji
5. Ensure warnings marked with ⚠️

**Validation:**
- Only standard emoji set used
- Emoji used in appropriate contexts
- No emoji in headings or technical terms
- Warnings consistently marked with ⚠️

---

### Task 3.3: Organize Example Files (40 minutes)

**Scope:** Create consistent examples directory structure

**Target Structure:**
```
examples/
  ch01_quick_start/
    01_hello_world/
      src/main.zig
      build.zig
      README.md
    02_basic_types/
      src/main.zig
      build.zig
      README.md
  ch02_syntax_essentials/
    01_variables/
      src/main.zig
      README.md
    ...
  ch03_language_idioms/
    ...
  [etc for all chapters]
```

**Files to Create:**
- [ ] Create `examples/` directory structure
- [ ] Write README.md for each example
- [ ] Extract inline examples to files where appropriate
- [ ] Create build.zig for each example
- [ ] Verify all examples compile

**Implementation Steps:**
1. Create directory structure
2. Identify inline examples suitable for extraction
3. Create example files with proper imports
4. Write descriptive README for each
5. Add build.zig where needed
6. Test compilation of all examples
7. Update chapter references to point to examples/

**Validation:**
- Consistent directory structure
- All examples have README.md
- All examples compile successfully
- Chapter references updated to point to examples/

---

### Task 3.4: Fix Minor Style Issues (30 minutes)

**Scope:** Punctuation, spacing, line length

**Issues to Address:**
1. **Oxford comma** - Use consistently in lists
2. **Heading punctuation** - No colons at end of headings
3. **Quotation marks** - Use straight quotes in markdown
4. **List spacing** - Consistent blank lines around lists
5. **Line length** - Wrap prose at ~100 characters
6. **Code fence tags** - Always specify language

**Files to Audit:**
- [ ] All chapter files for minor issues
- [ ] Run automated checks where possible

**Implementation Steps:**
1. Search for list items and verify Oxford comma
2. Remove colons from headings
3. Replace curly quotes with straight quotes
4. Standardize spacing around lists
5. Wrap long lines (preserve code blocks)
6. Add language tags to bare code fences

**Validation:**
- Oxford comma used consistently
- No colons in headings
- Straight quotes throughout
- Consistent list spacing
- Prose wrapped appropriately
- All code fences have language tags

---

## Phase 4: Validation & Testing
**Estimated Effort:** 1 hour
**Focus:** Ensure all changes work correctly

### Task 4.1: Automated Checks (20 minutes)

**Checks to Run:**
- [ ] Markdown linting (markdownlint)
- [ ] Link validation (check all internal/external links)
- [ ] Spell check (with technical dictionary)
- [ ] Code fence language tag validation

**Tools:**
```bash
# Install tools
npm install -g markdownlint-cli
npm install -g markdown-link-check

# Run checks
markdownlint src/**/*.md
find src -name "*.md" -exec markdown-link-check {} \;
```

**Validation:**
- No markdown linting errors
- All links functional
- No spelling errors (excluding technical terms)
- All code fences have language tags

---

### Task 4.2: Manual Review (20 minutes)

**Review Checklist:**
- [ ] Sample 3 chapters for TL;DR consistency
- [ ] Verify version markers in ch06, ch10
- [ ] Check "In Practice" structure in ch08, ch14
- [ ] Verify code annotations in ch03, ch07
- [ ] Review heading capitalization across chapters
- [ ] Spot-check reference formatting
- [ ] Verify cross-references work
- [ ] Check summary structure in 3 chapters

**Validation:**
- All sampled items meet standards
- No obvious inconsistencies remain

---

### Task 4.3: Build & Compile Examples (20 minutes)

**Compilation Tests:**
```bash
# Test all examples compile
for dir in examples/*/*/; do
    echo "Testing $dir"
    cd "$dir"
    if [ -f "build.zig" ]; then
        zig build || echo "FAILED: $dir"
    else
        zig build-exe src/main.zig || echo "FAILED: $dir"
    fi
    cd -
done
```

**Validation:**
- All examples compile successfully
- No compilation errors or warnings
- Examples produce expected output

---

## Style Guide Updates

**File:** `style_guide.md`

Add new sections based on implementation:

### Section 2.1: TL;DR Format
Document the standard TL;DR template with examples.

### Section 2.2: Version Markers
Document emoji usage for version-specific content.

### Section 2.3: Code Example Annotations
Document ❌/✅ annotation standards.

### Section 2.4: "In Practice" Structure
Document production codebase example format.

### Section 3.1: Citation Format
Document standard footnote and reference format.

### Section 3.2: Cross-Reference Format
Document internal linking conventions.

### Section 3.3: Summary Structure
Document standard summary section format.

---

## Implementation Timeline

### Week 1: Phase 1 (High Priority)
- **Day 1-2:** Task 1.1 - TL;DR standardization (2 hours)
- **Day 2:** Task 1.2 - Version markers (1 hour)
- **Day 3-4:** Task 1.3 - "In Practice" sections (2 hours)
- **Day 4:** Task 1.4 - Code annotations (1 hour)

### Week 2: Phase 2 (Medium Priority)
- **Day 1:** Task 2.1 - Heading capitalization (45 min)
- **Day 1-2:** Task 2.2 - Reference formatting (1 hour)
- **Day 2:** Task 2.3 - Cross-references (30 min)
- **Day 3:** Task 2.4 - Summary sections (1 hour)

### Week 3: Phase 3 (Low Priority) + Validation
- **Day 1:** Task 3.1 - Table formatting (30 min)
- **Day 1:** Task 3.2 - Emoji standardization (20 min)
- **Day 2:** Task 3.3 - Example file organization (40 min)
- **Day 2:** Task 3.4 - Minor style fixes (30 min)
- **Day 3:** Phase 4 - Validation & testing (1 hour)

**Total Calendar Time:** ~3 weeks (part-time work)
**Total Effort:** 7-12 hours

---

## Rollout Strategy

### Option 1: Big Bang (All at Once)
**Pros:** Single large PR, all changes at once
**Cons:** Difficult to review, high risk

### Option 2: Phase-by-Phase (Recommended)
**Pros:** Easier review, incremental improvement
**Cons:** Multiple PRs, longer calendar time

**Recommendation:** Phase-by-phase approach
- PR 1: Phase 1 (High Priority) - 4-6 hours
- PR 2: Phase 2 (Medium Priority) - 2-4 hours
- PR 3: Phase 3 (Low Priority) + Validation - 1-2 hours
- PR 4: Style guide updates

### Option 3: File-by-File
**Pros:** Minimal risk, very granular
**Cons:** Too many PRs, slow progress

---

## Risk Mitigation

### Risks & Mitigations

**Risk:** Breaking existing anchor links
**Mitigation:** Validate all links before committing

**Risk:** Introducing technical errors while reformatting
**Mitigation:** Only change formatting, not content; review carefully

**Risk:** Inconsistent application of standards
**Mitigation:** Use checklists, automated linting where possible

**Risk:** Examples fail to compile after changes
**Mitigation:** Test all examples before committing

**Risk:** Time overrun
**Mitigation:** Prioritize ruthlessly, Phase 3 is optional

---

## Success Metrics

### Quantitative
- [ ] 100% of chapters have standardized TL;DR
- [ ] 100% of version-specific code has emoji markers
- [ ] 100% of "In Practice" sections follow standard structure
- [ ] 100% of code examples use ❌/✅ annotations
- [ ] 0 markdown linting errors
- [ ] 0 broken internal links
- [ ] 100% of examples compile successfully

### Qualitative
- [ ] Reader feedback indicates improved consistency
- [ ] Technical reviewers approve standardization
- [ ] New contributors can follow patterns easily
- [ ] Book feels professionally polished

---

## Appendix: Tools & Resources

### Markdown Linting
```bash
# Install
npm install -g markdownlint-cli

# Configure
cat > .markdownlint.json <<EOF
{
  "MD013": false,
  "MD033": false,
  "MD041": false
}
EOF

# Run
markdownlint src/**/*.md
```

### Link Checking
```bash
# Install
npm install -g markdown-link-check

# Run
find src -name "*.md" -exec markdown-link-check {} \;
```

### Example Compilation Script
```bash
#!/bin/bash
# test_examples.sh
set -e

for chapter_dir in examples/*/; do
    for example_dir in "$chapter_dir"*/; do
        echo "Testing: $example_dir"
        cd "$example_dir"

        if [ -f "build.zig" ]; then
            zig build
        elif [ -f "src/main.zig" ]; then
            zig build-exe src/main.zig
        fi

        cd - > /dev/null
    done
done

echo "All examples compiled successfully!"
```

### Search & Replace Patterns

**Find headers for capitalization:**
```bash
grep -rn "^#\+ " src/ | less
```

**Find version-specific code:**
```bash
grep -rn "0\.14\|0\.15" src/ | less
```

**Find code fences without language:**
```bash
grep -rn "^\`\`\`$" src/ | less
```

---

## Conclusion

This plan provides a comprehensive, phased approach to resolving all style inconsistencies identified in the review. Following this plan will:

1. **Improve reader experience** through consistent structure
2. **Enhance professional appearance** through uniform formatting
3. **Increase maintainability** through standardized patterns
4. **Preserve technical accuracy** while improving presentation

The phase-by-phase approach balances thoroughness with manageable scope, allowing for incremental improvement and easier review.

**Recommended Next Steps:**
1. Review and approve this plan
2. Create GitHub issues for each phase
3. Begin Phase 1 implementation
4. Iterate based on feedback

---

**Plan Status:** Ready for Implementation
**Last Updated:** 2025-11-19
