# Zig: Zero to Hero - Version Management Strategy

> Defines version support policy and update workflows for maintaining the guide.

---

## 1. Supported Zig Version

**Current Version:** Zig 0.15.2

This guide teaches modern Zig idioms and best practices using **Zig 0.15.2** — the latest stable version at time of writing. All code examples, runnable programs, and CI validation target this version.

**For Zig 0.14.1 users:** See Appendix A for quick-reference patterns and Appendix B for full migration guide.

### Validation

- **CI Testing:** All examples validated on Zig 0.15.2
- **Compilation:** 100% success rate (100 example files, 4,430+ lines)
- **Last updated:** November 2025

**Future Versions:** When new Zig versions are released (e.g., 0.16), the guide will be updated to target the new version. Migration guidance will be added to the appendices as needed.

---

## 2. Version Support Policy

**Current Policy:** Latest version only + migration appendices

The guide targets the latest stable Zig version (currently 0.15.2) with migration guidance in appendices for users on older versions.

**Rationale:**
- **Clean reading experience:** No version markers cluttering main content
- **Sustainable maintenance:** Single version to maintain and validate
- **Migration support:** Appendices provide upgrade path for older versions
- **Modern focus:** Always teaching current best practices

**When new versions release:**
1. Update all examples to new version
2. Add migration appendix (old → new) if breaking changes exist
3. Archive obsolete migration appendices after 12-18 months

---

## 3. Research Documentation Standards

### Location
- **Active research:** `sections/XX_name/research_notes.md`
- **Archived research:** `sections/XX_name/archive/research_notes_vX.X.md`

### Purpose
Research notes serve as:
1. Permanent record of sources and decisions
2. Audit trail for content choices
3. Context for future maintainers
4. Foundation for version updates

### Required Contents
Each `research_notes.md` should document:
- Version-specific findings with citations
- Code examples collected (with source URLs)
- Exemplar project patterns discovered
- Rationale for included examples
- Known limitations or gaps

### Retention Policy
- **Keep:** Current version research notes
- **Archive:** Research from previous guide versions in `archive/` subdirectory
- **Purpose:** Historical context for idiom evolution and decision-making

---

## 4. Update Workflow for New Zig Releases

When a new Zig version is released (e.g., 0.16):

### Phase 1: Assessment (1-2 hours)
1. Review release notes and breaking changes
2. Identify chapters affected by breaking changes
3. Determine if migration appendix needed
4. Estimate update effort

### Phase 2: Update Examples (2-4 hours)
1. Update all code examples to new version
2. Fix compilation errors
3. Test all examples in `examples/` directory
4. Update CI to test new version

### Phase 3: Update Content (2-6 hours)
1. Update chapter content for API changes
2. Update best practices if idioms changed
3. Add new features/patterns as appropriate
4. Update references to official docs

### Phase 4: Migration Appendix (4-8 hours, if needed)
1. Create new appendix (e.g., "Appendix D: 0.15 → 0.16")
2. Document breaking changes with before/after examples
3. Provide migration checklist
4. Update SUMMARY.md

### Phase 5: Validation (1-2 hours)
1. Verify all examples compile
2. Run full test suite
3. Update README and versioning.md
4. Archive old migration appendices if obsolete

**Total time per version:** 10-22 hours (vs 24-32h with multi-version approach)

---

## 5. Migration Appendix Lifecycle

**Retention policy:**
- Migration appendices remain for 12-18 months after version release
- Example: "0.14 → 0.15" appendix remains until ~May 2027
- After retention period, archive or remove based on usage

**Archival criteria:**
- Version adoption drops below 10% (community surveys/downloads)
- No recent questions about migration on forums/Discord
- New version has been stable for 12+ months

**Archive location:** `docs/archive/` for historical reference

---

## 6. Cross-Reference Updates

When this file is updated, ensure these files reference current policy:

- [README.md](README.md) - Version statement and 0.14 guidance
- [src/README.md](src/README.md) - Book introduction
- [SUMMARY.md](src/SUMMARY.md) - Appendix structure
- [style_guide.md](style_guide.md) - Writing guidelines

---

## 7. Summary

**Version strategy:** Latest version only (0.15.2) with migration appendices

**Benefits:**
- Clean, focused content (no version markers)
- Sustainable maintenance (10-22h vs 24-32h per version)
- Migration support via appendices
- Modern best practices only

**Trade-offs:**
- 0.14.1 users must mentally translate or upgrade
- Runnable examples target 0.15.2 only
- Historical patterns in appendices only

**This approach balances reader experience, maintenance sustainability, and backward support.**

---

**Last Updated:** 2025-11-14
**Next Review:** Upon Zig 0.16 release
