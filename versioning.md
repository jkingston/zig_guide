# Zig: Zero to Hero - Version Management Strategy

> Defines version support policy, update workflows, and research documentation standards for maintaining the guide across Zig releases.

---

## 1. Supported Zig Versions

**Current Coverage:** Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2

This is a comprehensive Zig developer guide supporting multiple patch versions across the 0.14 and 0.15 series. The guide teaches Zig idioms and best practices applicable across these versions. When patterns differ, version markers clearly indicate compatibility requirements.

### Tested Versions

This guide has been validated against:
- **Zig 0.14.0** (released 2025-03-05)
- **Zig 0.14.1** (released 2025-05-21)
- **Zig 0.15.1** (released 2025-08-19)
- **Zig 0.15.2** (released 2025-10-11)

**Note:** Zig 0.15.0 was retracted and never officially released.

**Future Versions:** Subsequent patch releases (0.14.2+, 0.15.3+) will be evaluated and added to this guide after validation. The guide makes no guarantees about compatibility with untested versions.

---

## 2. Version Support Policy

**Status:** TBD - To be determined as the project matures

**Considerations for future policy:**
- **Sliding Window Approach:** Support latest N major versions (e.g., always cover most recent 2-3 versions)
- **Comprehensive Archive:** Maintain all historical versions with clear markers
- **Branched Versions:** Separate guide editions per major Zig version

**Decision factors:**
- Community adoption rates of new Zig versions
- Breaking change frequency in Zig releases
- Maintenance burden vs reader value

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

## 4. Version Marker Conventions

Defined in [style_guide.md](style_guide.md#2-structure--formatting), repeated here for reference:

- **✅ 0.15+** - Features or idioms introduced in Zig 0.15
- **🕐 0.14.x** - Legacy practices from Zig 0.14

When new versions are released, markers should be updated to reflect current vs legacy status.

**Example for future 0.16 release:**
- **✅ 0.16+** - New idioms
- **🕐 0.14-0.15** - Older patterns (if still functional)

---

## 5. Update Workflow for New Zig Releases

**Status:** Draft workflow - to be refined through practice

### Phase 1: Impact Assessment
1. New Zig version released (e.g., 0.16.0)
2. Create versioned research document: `sections/XX_name/research_notes_v0.16.md`
3. Research agent analyzes:
   - Release notes and breaking changes
   - Impact on existing code examples
   - New idioms or stdlib changes
   - Deprecations affecting guide content

### Phase 2: Update Planning
4. Generate section-by-section update plan:
   - Examples requiring modification
   - New examples to add
   - Version markers to update
   - Citations to verify/update
5. Prioritize sections by impact severity

### Phase 3: Content Updates
6. Update `content.md` files incrementally
7. Update `research_notes.md` with new findings
8. Archive old research notes to `archive/` subdirectory
9. Update `metadata/sections.yaml` if scope changes

### Phase 4: Validation
10. Verify all code examples compile in supported versions
11. Check version markers are consistent
12. Update References section with new official docs
13. Review cross-version consistency

---

## 6. Deprecation Process

**Status:** TBD - Policy to be established

Questions to resolve:
- When should examples be marked as legacy vs removed entirely?
- How long should legacy patterns remain in the guide?
- Should deprecated content move to appendices or be removed?

**Current approach:**
- Keep both legacy and modern patterns with clear version markers
- Explain migration path where applicable
- Reference Migration Guide (Section 14) for complex transitions

---

## 7. Cross-Reference Updates

When this file is updated, ensure these files reference current policy:

- [AGENTS.md](AGENTS.md) - Agent workflow requirements
- [README.md](README.md) - Project overview
- [style_guide.md](style_guide.md) - Version marker conventions

---

## 8. Future Considerations

Topics to address as the project matures:

- **Update Cadence:** How quickly to update guide after new Zig releases?
- **Beta/RC Coverage:** Should guide cover pre-release versions?
- **Community Input:** Process for incorporating version-specific feedback
- **Automated Validation:** Tools to verify examples across Zig versions
- **Version Matrix:** Tracking which examples work in which versions

---

**Last Updated:** 2025-11-02
**Next Review:** Upon Zig 0.16 release or major project milestone
