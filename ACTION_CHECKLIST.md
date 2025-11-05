# Zig Developer Guide — Editorial Action Checklist

**Based on:** EDITORIAL_REVIEW.md (2025-11-05)  
**Purpose:** Quick reference for implementing recommendations

---

## 🔴 CRITICAL - Must Complete Before Any Publication

### 1. Build Integration [COMPLETED ✅]
- [x] Run `./scripts/prepare-mdbook.sh` 
- [ ] Install mdbook: `cargo install mdbook`
- [ ] Verify build: `mdbook build`
- [ ] Test serve: `mdbook serve`
- [ ] Update README.md with build instructions

**Script to add to README.md:**
```markdown
## Building the Book

### Prerequisites
- Install Rust and Cargo
- Install mdBook: `cargo install mdbook`

### Build Steps
1. Prepare sources: `./scripts/prepare-mdbook.sh`
2. Build the book: `mdbook build`
3. Serve locally: `mdbook serve --open`

The built book will be available in `book/index.html`.
```

---

### 2. Code Example Validation [TODO]
- [ ] Create `scripts/test_all_examples.sh`
- [ ] Download Zig 0.14.1 and 0.15.2 binaries
- [ ] Test standalone examples (sections/*/example_*.zig)
- [ ] Test build projects (sections/*/examples/*/build.zig)
- [ ] Document results in `TEST_RESULTS.md`
- [ ] Fix any failing examples
- [ ] Add CI workflow (`.github/workflows/validate-examples.yml`)

**Files to test:**
```
sections/05_io_streams/example_*.zig (5 files)
sections/06_error_handling/example_*.zig (6 files)
sections/07_async_concurrency/example_*.zig (5 files)
sections/11_interoperability/examples/*/ (6 directories)
sections/14_migration_guide/examples/*/ (3 directories)
```

---

### 3. Citation Standardization [TODO]

#### Chapter 5 - I/O, Streams & Formatting
- [ ] Review all inline citations in sections/05_io_streams/content.md
- [ ] Convert to footnote format `[^N]`
- [ ] Add footnote definitions before References section
- [ ] Verify all 11 references are cited

#### All Chapters
- [ ] Run citation audit script
- [ ] Fix mismatched reference/definition counts
- [ ] Standardize footnote numbering (sequential from [^1])

**Commands:**
```bash
# Check for mismatches
for file in sections/*/content.md; do
    echo "=== $(basename $(dirname $file)) ==="
    echo -n "References: "
    grep -o '\[^[0-9]\+\]' "$file" | wc -l
    echo -n "Definitions: "
    grep -c '^\[^[0-9]\+\]:' "$file"
done

# Fix Chapter 5 specifically
vim sections/05_io_streams/content.md
# Then re-run prepare-mdbook.sh
```

---

## 🟡 HIGH PRIORITY - Before 1.0 Release

### 4. Version Marker Audit [TODO]
**Focus chapters:**
- [ ] Chapter 6 (Error Handling) - check error set changes
- [ ] Chapter 9 (Packages) - check build.zig.zon changes
- [ ] Chapter 11 (Interoperability) - check C FFI changes
- [ ] Chapter 12 (Testing) - check test framework changes
- [ ] Chapter 13 (Logging) - check std.log API changes

**Process:**
1. Review Zig 0.15.x release notes
2. Identify breaking changes affecting each chapter
3. Add version markers where APIs differ
4. Provide side-by-side comparisons
5. Update VERSIONING.md with findings

---

### 5. Cross-Reference Enhancement [TODO]
- [ ] Chapter 1: Add references to all subsequent chapters
- [ ] Chapter 2 → 3 (Language Idioms → Memory)
- [ ] Chapter 3 → 4 (Memory → Collections)
- [ ] Chapter 4 → 5 (Collections → I/O)
- [ ] Chapter 5 → 6 (I/O → Error Handling)
- [ ] Chapter 6 → 3 (Error Handling → Memory for cleanup)
- [ ] Chapter 14: Reference all affected chapters
- [ ] Add "See Also" sections at chapter ends

**Format:**
```markdown
## See Also

- [Memory & Allocators](ch03_memory_allocators.md) - Allocator patterns
- [Error Handling](ch06_error_handling.md#cleanup-patterns) - Resource cleanup
```

---

### 6. Code Block Formatting [TODO]
- [ ] Audit all code blocks for language specifiers
- [ ] Add ```zig to Zig code if missing
- [ ] Add ```yaml for build.zig.zon examples
- [ ] Add ```toml for config examples
- [ ] Add ```bash for shell scripts
- [ ] Verify terminal output uses ``` (no specifier)

**Chapters to focus on:**
- Chapter 7 (9 blocks need review)
- Chapter 8 (7 blocks need review)
- Chapter 9 (8 blocks need review)
- Chapter 10 (18 blocks need review)
- Chapter 11 (29 blocks need review)
- Chapter 12 (29 blocks need review)

---

## 🟢 MEDIUM PRIORITY - Quality Improvements

### 7. YAML Metadata [TODO]
- [ ] Add frontmatter to Chapter 1
- [ ] Add frontmatter to Chapters 2-14
- [ ] Add frontmatter to Chapter 15
- [ ] Include version compatibility in metadata
- [ ] Add creation/update dates

**Template:**
```yaml
---
title: "Chapter Title"
authors:
  - "Zig Developer Guide Contributors"
date_created: "2025-XX-XX"
date_updated: "2025-11-05"
zig_versions: ["0.14.0", "0.14.1", "0.15.1", "0.15.2"]
status: "published"
---
```

---

### 8. Chapter 15 Enhancement [TODO]
- [ ] Create consolidated bibliography (all works cited in ch1-14)
- [ ] Add comprehensive glossary of Zig terms
- [ ] Create index of code examples with page numbers
- [ ] Add quick reference cards for common patterns

---

### 9. Documentation Updates [TODO]
- [ ] Update README.md with build instructions
- [ ] Add CONTRIBUTING.md with guidelines
- [ ] Update VERSIONING.md with audit findings
- [ ] Add LICENSE file if needed
- [ ] Create CHANGELOG.md for version tracking

---

## 🔵 LOW PRIORITY - Nice to Have

### 10. Automation [TODO]
- [ ] Create Makefile with common tasks
- [ ] Add pre-commit hook for prepare-mdbook.sh
- [ ] Set up GitHub Actions for publishing
- [ ] Add link checker to CI
- [ ] Automate version marker validation

---

### 11. Enhanced Examples [TODO]
- [ ] Extract more inline examples from chapters
- [ ] Create examples/ repository with full projects
- [ ] Add README to each example directory
- [ ] Consider video walkthroughs (optional)

---

### 12. Community Engagement [TODO]
- [ ] Create issue templates (.github/ISSUE_TEMPLATE/)
- [ ] Set up GitHub Discussions
- [ ] Create PR template
- [ ] Solicit technical reviews from Zig community
- [ ] Post to Ziggit forum for feedback

---

## Quick Commands Reference

### Build the book
```bash
./scripts/prepare-mdbook.sh && mdbook build
```

### Serve locally
```bash
mdbook serve --open
```

### Test an example
```bash
zig test sections/05_io_streams/example_basic_writer.zig
```

### Check citation counts
```bash
./scripts/check_citations.sh  # If created
```

### Find chapters missing version markers
```bash
for f in sections/*/content.md; do
    count=$(grep -c '🕐\|✅' "$f")
    [ $count -eq 0 ] && echo "$(basename $(dirname $f)): No version markers"
done
```

### Build a specific example project
```bash
cd sections/11_interoperability/examples/01_basic_c_interop
zig build
```

---

## Progress Tracking

**Status Key:** ✅ Done | 🚧 In Progress | ⏳ Waiting | ❌ Blocked

| Item | Priority | Status | Assignee | Due Date |
|------|----------|--------|----------|----------|
| Build Integration | 🔴 Critical | ✅ Done | - | 2025-11-05 |
| Code Validation | 🔴 Critical | ⏳ Waiting | - | - |
| Citation Fixes | 🔴 Critical | ⏳ Waiting | - | - |
| Version Markers | 🟡 High | ⏳ Waiting | - | - |
| Cross-References | 🟡 High | ⏳ Waiting | - | - |
| Code Block Format | 🟡 High | ⏳ Waiting | - | - |
| YAML Metadata | 🟢 Medium | ⏳ Waiting | - | - |
| Chapter 15 | 🟢 Medium | ⏳ Waiting | - | - |
| Documentation | 🟢 Medium | ⏳ Waiting | - | - |
| Automation | 🔵 Low | ⏳ Waiting | - | - |

---

## Estimation Summary

- **Critical Items:** 32-56 hours (1-2 weeks)
- **High Priority:** 24-36 hours (3-5 days)
- **Medium Priority:** 16-24 hours (2-3 days)
- **Total to 1.0:** ~72-116 hours (2-3 weeks with dedicated team)

---

**Last Updated:** 2025-11-05  
**Next Review:** After completing CRITICAL items
