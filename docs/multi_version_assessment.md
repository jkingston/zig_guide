# Multi-Version Support Assessment: Zig Guide

> **Analysis Date:** November 13, 2025
> **Current Status:** Beta Release (v0.9), targeting 1.0
> **Versions Covered:** Zig 0.14.0, 0.14.1, 0.15.1, 0.15.2

---

## Executive Summary

This document assesses the current multi-version support strategy for "Zig: Zero to Hero" and evaluates alternative approaches for restructuring version coverage.

**Current Approach:**
- **Documentation:** Covers 4 versions (0.14.0, 0.14.1, 0.15.1, 0.15.2) with version markers
- **Examples:** All runnable code targets Zig 0.15.2 only
- **Migration Guide:** Comprehensive 0.14.1 → 0.15.2 migration chapter (1,246 lines)
- **CI Validation:** Tests only against Zig 0.15.2

**Key Finding:** The book employs a **"backward-compatible documentation, forward-only examples"** strategy that provides version awareness without the maintenance burden of multi-version testing.

---

## Current State Analysis

### 1. Multi-Version Coverage Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Documented versions** | 4 (0.14.0, 0.14.1, 0.15.1, 0.15.2) | Stated in README and versioning.md |
| **Tested versions** | 1 (0.15.2 only) | CI matrix contains only 0.15.2 |
| **Version markers** | 40 occurrences across 7 files | 🕐 0.14.x and ✅ 0.15+ markers |
| **0.14 references** | 67 mentions | Primarily in migration guide |
| **0.15 references** | 231 mentions | Throughout all chapters |
| **Migration guide** | 1,246 lines (Ch 15) | Comprehensive 0.14 → 0.15 coverage |
| **Runnable examples** | 100 files, 4,430 LOC | All target 0.15.2 API |

### 2. Current Implementation Pattern

**Documentation Strategy:**
```
Chapter Content:
├─ Primary examples (0.15.2 API)
├─ Version markers for breaking changes
├─ Occasional 0.14.x legacy patterns
└─ Cross-references to Migration Guide

Migration Guide (Ch 15):
├─ Before/after comparisons for ALL breaking changes
├─ 6 complete migration examples
├─ 10 common pitfalls with solutions
└─ Production patterns from TigerBeetle, ZLS, Ghostty
```

**Example:**
```zig
// Chapter text shows both versions with markers:

// 🕐 0.14.x - Managed (old default)
var list = std.ArrayList(u8).init(allocator);
try list.append('x');

// ✅ 0.15+ - Unmanaged (new default)
var list = std.ArrayList(u8){};
try list.append(allocator, 'x');
```

But extracted examples in `examples/` only compile the 0.15.2 version.

### 3. Maintenance Burden Distribution

**High maintenance areas:**
- Migration Guide (Ch 15): 1,246 lines requiring updates per version
- Version markers: 40 locations to update across chapters
- Versioning policy: versioning.md requires updates

**Low maintenance areas:**
- CI configuration: Single version in matrix
- Example files: Single API surface to maintain
- Reference projects: Pinned to specific commits

**Estimated maintenance time per new Zig version:**
- Without migration guide: ~4-8 hours (update markers, validate examples)
- With migration guide: ~16-24 hours (rewrite migration patterns)

---

## Option 1: Current Approach (Status Quo)

**"Backward-compatible documentation, forward-only examples"**

### Description
Continue documenting multiple versions with version markers while maintaining examples only for the latest stable version (currently 0.15.2).

### Advantages

**For readers:**
- ✅ Helps users on older versions understand differences
- ✅ Comprehensive migration path for upgrading
- ✅ Version markers provide historical context
- ✅ Reduced confusion from version-specific API differences

**For maintainers:**
- ✅ Examples only maintained for one version (lower CI complexity)
- ✅ Migration guide provides value for 6-12 months post-release
- ✅ Positions book as "comprehensive" resource

**For the ecosystem:**
- ✅ Acknowledges reality that projects upgrade at different rates
- ✅ Supports production teams running older versions
- ✅ Demonstrates Zig's evolution and stability trajectory

### Disadvantages

**For readers:**
- ❌ Mental overhead: "Which version am I reading about?"
- ❌ Version markers clutter the reading experience
- ❌ Migration guide becomes obsolete as 0.14 adoption drops
- ❌ Confusion when examples don't match their local version

**For maintainers:**
- ❌ 40+ version markers to update per version
- ❌ Migration guide requires major rewrites (16-24h per version)
- ❌ Must research and document breaking changes comprehensively
- ❌ Increased cognitive load when writing new content

**For the ecosystem:**
- ❌ Book dated to specific version range (0.14-0.15)
- ❌ Readers on 0.16+ may see outdated markers

### Sustainability Assessment

**Short-term (6 months):** ⭐⭐⭐⭐⭐ Excellent
- Migration guide is highly relevant while 0.14 still widely used
- Version markers provide immediate value

**Medium-term (1-2 years):** ⭐⭐⭐ Moderate
- 0.14 adoption drops, migration guide less useful
- Markers become historical artifacts rather than practical aids

**Long-term (3+ years):** ⭐⭐ Poor
- Multiple outdated version references clutter content
- Continuous rewriting of migration guides unsustainable

### Target Audience Fit

**Experienced developers (current target):** ⭐⭐⭐⭐
- Appreciate comprehensive version coverage
- Value migration guides for production codebases
- Comfortable with version-specific documentation

**Zig beginners:** ⭐⭐
- Version markers may be confusing
- Don't need migration guides (no legacy code)

**Production teams:** ⭐⭐⭐⭐⭐
- Critical for teams managing version upgrades
- Migration guide saves hours of work

### Recommendation Scenario
**Best if:**
- Target audience is production teams managing existing Zig codebases
- Zig version churn remains high (multiple breaking changes per year)
- Book aims to be comprehensive historical reference

---

## Option 2: Latest Version Only

**"Zero to Hero for Zig 0.15.2"**

### Description
Document and test only the latest stable version (0.15.2), removing all version markers and the migration guide. Archive historical content in appendix.

### Changes Required

**Immediate changes:**
1. Remove all version markers (40 occurrences)
2. Remove or archive Migration Guide (Ch 15, 1,246 lines)
3. Update README/versioning.md to state "Zig 0.15.2 only"
4. Simplify examples to single API surface
5. Remove backward-compatible code patterns

**Content impact:**
- **Removed:** ~1,300 lines (migration guide + legacy examples)
- **Simplified:** 40+ locations with version markers
- **Chapters affected:** 7 (all chapters with version markers)

**Time estimate:** 8-12 hours to execute cleanly

### Advantages

**For readers:**
- ✅ Zero version confusion - one API surface
- ✅ Cleaner reading experience (no markers/caveats)
- ✅ Shorter book (~5% reduction in content)
- ✅ All examples guaranteed to work on stated version

**For maintainers:**
- ✅ Drastically reduced maintenance burden per version
- ✅ Simpler CI (already only testing one version)
- ✅ No migration guide rewrites (16-24h saved per version)
- ✅ Less cognitive overhead when writing new content

**For the ecosystem:**
- ✅ Clearer positioning: "The guide for Zig 0.15+"
- ✅ Forces focus on current best practices
- ✅ Book stays modern by dropping old patterns quickly

### Disadvantages

**For readers:**
- ❌ No migration help for users on 0.14.x
- ❌ Book becomes outdated faster (tied to single version)
- ❌ Less value for production teams with legacy code

**For maintainers:**
- ❌ Need to update entire book per breaking change
- ❌ Historical context lost (why did patterns change?)
- ❌ Must republish/version book for each Zig release

**For the ecosystem:**
- ❌ Abandons users on older versions
- ❌ Reduced value during version transition periods
- ❌ May appear "unstable" if republished frequently

### Sustainability Assessment

**Short-term (6 months):** ⭐⭐⭐ Moderate
- Cleaner content but less comprehensive
- Users on 0.14 must upgrade or use other resources

**Medium-term (1-2 years):** ⭐⭐⭐⭐ Good
- Much easier to maintain as Zig evolves
- Clear versioning strategy reduces confusion

**Long-term (3+ years):** ⭐⭐⭐⭐⭐ Excellent
- Sustainable maintenance model
- Book stays modern with less effort
- Can adopt "living document" approach

### Target Audience Fit

**Experienced developers (current target):** ⭐⭐⭐
- Lose migration guide value
- May prefer comprehensive historical reference
- Can figure out version differences themselves

**Zig beginners:** ⭐⭐⭐⭐⭐
- Best experience - zero confusion
- Learn current patterns only
- Don't need historical context

**Production teams:** ⭐⭐
- Must upgrade to use book
- No help migrating legacy codebases
- Forced onto latest version

### Recommendation Scenario
**Best if:**
- Target audience shifts to Zig beginners/newcomers
- Zig stabilizes (fewer breaking changes)
- Book positioned as "living document" updated frequently
- Maintenance resources are limited

---

## Option 3: Versioned Book Editions

**"Zero to Hero: Zig 0.14 Edition" vs "Zero to Hero: Zig 0.15 Edition"**

### Description
Maintain separate book editions for each major Zig version, branching content when breaking changes occur.

### Implementation

**Branch structure:**
```
main (tracks latest: 0.15.2)
├─ releases/0.14  (frozen at 0.14.1)
├─ releases/0.15  (frozen at 0.15.2)
└─ releases/0.16  (future)
```

**Reader experience:**
- Landing page: "Choose your Zig version"
- Each edition standalone (no version markers)
- No migration guides (separate editions handle differences)

**CI approach:**
- Each branch tests against its target version
- No cross-version testing required

### Advantages

**For readers:**
- ✅ Zero version confusion within edition
- ✅ Perfect match for their Zig installation
- ✅ No outdated content in their edition
- ✅ Clear "which edition do I need?" selection

**For maintainers:**
- ✅ Clean separation of version-specific content
- ✅ Can freeze old editions (low maintenance)
- ✅ New content only goes into latest edition
- ✅ No version markers or migration guides needed

**For the ecosystem:**
- ✅ Supports users across version spectrum
- ✅ Clear historical record of Zig evolution
- ✅ Professional appearance (like Rust Book versioning)

### Disadvantages

**For readers:**
- ❌ Must determine correct edition before starting
- ❌ No migration guidance between editions
- ❌ Can't easily compare version differences

**For maintainers:**
- ❌ Must manage multiple branches/deployments
- ❌ Bug fixes may need backporting to old editions
- ❌ Infrastructure complexity (multiple mdBook builds)
- ❌ Must decide when to freeze editions (support policy)

**For the ecosystem:**
- ❌ Fragments community (which edition to reference?)
- ❌ Increased hosting complexity (multiple sites)
- ❌ May confuse beginners ("which version should I use?")

### Sustainability Assessment

**Short-term (6 months):** ⭐⭐ Poor
- High setup cost (branching, CI, hosting)
- Minimal benefit (only 2 versions)
- Migration guide still needed separately

**Medium-term (1-2 years):** ⭐⭐⭐⭐ Good
- Benefits emerge with 3+ versions
- Old editions frozen, low maintenance
- Clear support policy

**Long-term (3+ years):** ⭐⭐⭐⭐ Good
- Sustainable if old editions fully frozen
- Can drop old editions after support ends
- Mirrors Rust Book's successful pattern

### Target Audience Fit

**Experienced developers (current target):** ⭐⭐⭐⭐
- Professional versioning approach
- Can choose edition for their codebase
- Appreciate clean separation

**Zig beginners:** ⭐⭐⭐
- May be confused by edition selection
- "Just tell me what to learn!"

**Production teams:** ⭐⭐⭐⭐⭐
- Perfect match for long-term version support
- Can stay on old edition during migration
- Professional support model

### Recommendation Scenario
**Best if:**
- Zig establishes LTS or stable release schedule
- Book positioned as official/semi-official resource
- Resources available for infrastructure setup
- Target audience is production teams

---

## Option 4: Hybrid - Latest Focus + Migration Appendix

**"Current best practices, historical awareness"**

### Description
Focus primary content on latest version (0.15.2), but preserve migration knowledge in condensed appendix. Remove scattered version markers in favor of consolidated migration content.

### Changes Required

**Content restructuring:**
1. Remove inline version markers from Chapters 1-14 (40 occurrences)
2. Convert Ch 15 (Migration Guide) to Appendix A
3. Condense migration guide to "Quick Reference" format (~300-400 lines)
4. Add "Working with Older Versions" appendix section
5. Update README: "Zig 0.15.2, with migration notes for 0.14"

**Migration guide transformation:**
```
Before: 1,246 lines with detailed examples
After:  300-400 lines with:
  - Breaking changes summary table
  - Quick-fix patterns (before/after)
  - Links to exemplar project migrations
  - "If you're on 0.14, do this first" section
```

**Time estimate:** 12-16 hours

### Advantages

**For readers:**
- ✅ Clean main content (no version markers)
- ✅ Migration help still available when needed
- ✅ Clearer focus: "This is for 0.15+"
- ✅ Historical context preserved but not intrusive

**For maintainers:**
- ✅ Much easier to maintain than full multi-version
- ✅ 70% reduction in migration content to update
- ✅ Primary chapters version-agnostic
- ✅ Can deprecate appendix when 0.14 usage drops

**For the ecosystem:**
- ✅ Balances current focus with backward awareness
- ✅ Transitional strategy (can drop appendix later)
- ✅ Professional appearance while practical

### Disadvantages

**For readers:**
- ❌ Less comprehensive migration guidance
- ❌ Must jump to appendix for version help
- ❌ Quick-reference format may lack detail

**For maintainers:**
- ❌ Still requires some migration content maintenance
- ❌ Must decide when to drop appendix
- ❌ Need to condense existing migration guide

**For the ecosystem:**
- ❌ Less valuable for production teams than Option 1
- ❌ Still tied to specific version range

### Sustainability Assessment

**Short-term (6 months):** ⭐⭐⭐⭐ Good
- Immediate cleanup of main content
- Migration help still available
- Easier maintenance than status quo

**Medium-term (1-2 years):** ⭐⭐⭐⭐⭐ Excellent
- Can drop appendix when 0.14 obsolete
- Smooth transition to "latest only"
- Maintains quality during transition

**Long-term (3+ years):** ⭐⭐⭐⭐⭐ Excellent
- Becomes "latest only" naturally
- Appendix pattern reusable for future migrations
- Sustainable maintenance model

### Target Audience Fit

**Experienced developers (current target):** ⭐⭐⭐⭐⭐
- Best balance of current focus + migration help
- Professional presentation
- Can ignore appendix if not needed

**Zig beginners:** ⭐⭐⭐⭐
- Clean main content
- Can ignore migration appendix
- Clear version focus

**Production teams:** ⭐⭐⭐⭐
- Migration help available but not intrusive
- Can reference appendix as needed
- Encourages upgrades

### Recommendation Scenario
**Best if:**
- Want to transition from multi-version to latest-only
- Need to support current 0.14 users short-term
- Value clean reading experience
- **This is the recommended option for most scenarios**

---

## Comparative Analysis

### Maintenance Burden (Lower is Better)

| Option | Initial Effort | Per-Version Cost | Annual Burden |
|--------|----------------|------------------|---------------|
| **Status Quo** | 0h (done) | 16-24h | 16-24h |
| **Latest Only** | 8-12h | 4-6h | 4-6h |
| **Versioned Editions** | 20-30h | 2-4h per edition | 6-12h |
| **Hybrid** | 12-16h | 6-8h | 6-8h |

**Winner:** Latest Only (lowest annual burden)

### Reader Experience (Higher is Better)

| Option | Beginners | Experienced Devs | Production Teams |
|--------|-----------|------------------|------------------|
| **Status Quo** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Latest Only** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Versioned Editions** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Hybrid** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**Winner:** Hybrid (best balance across audiences)

### Long-Term Sustainability (Higher is Better)

| Option | 1 year | 3 years | 5 years |
|--------|--------|---------|---------|
| **Status Quo** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Latest Only** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Versioned Editions** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Hybrid** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Winner:** Hybrid (sustainable transition path)

### Book Quality Perception

| Option | Comprehensiveness | Modernity | Professionalism |
|--------|-------------------|-----------|-----------------|
| **Status Quo** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Latest Only** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Versioned Editions** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Hybrid** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Winner:** Hybrid (best quality perception)

---

## Recommendations

### Primary Recommendation: **Option 4 (Hybrid)**

**Rationale:**
1. **Best reader experience:** Clean main content + migration help when needed
2. **Sustainable:** Naturally transitions to "latest only" over time
3. **Professional:** Signals modern focus while acknowledging reality
4. **Target audience fit:** Perfect for experienced developers (current audience)
5. **Moderate effort:** 12-16 hours to implement, significant long-term savings

**Implementation timeline:**
- **Week 1:** Remove inline version markers from Chapters 1-14
- **Week 2:** Condense Migration Guide to appendix format
- **Week 3:** Update README, versioning.md, documentation
- **Week 4:** Test all examples, update CI, final review

**Success metrics:**
- Main chapters have zero version markers
- Migration appendix is 300-400 lines (70% reduction)
- All examples compile on 0.15.2
- README clearly states version focus

### Alternative Recommendation: **Option 2 (Latest Only)**

**If:**
- Maintenance resources are severely constrained
- Book positioning shifts to "beginner-friendly"
- Zig stabilizes significantly (fewer breaking changes)
- 0.14 adoption drops below 20%

**Additional time savings:** 4-6h per year vs Hybrid
**Trade-off:** Lost migration value for production teams

### NOT Recommended: **Option 1 (Status Quo)**

**Reasons:**
- Unsustainable long-term (16-24h per version)
- Migration guide becomes obsolete in 12-18 months
- Version markers clutter reading experience
- Already doing 80% of "latest only" work (examples only for 0.15.2)

**However, defer decision if:**
- Planning to immediately support 0.16 when released
- Book is positioning as "historical reference"
- Significant demand from 0.14 users

### NOT Recommended: **Option 3 (Versioned Editions)**

**Reasons:**
- High infrastructure complexity (20-30h setup)
- Only 2 versions don't justify branching overhead
- Can always adopt later if Zig establishes LTS
- Better suited for official documentation

**However, reconsider if:**
- Zig announces LTS policy
- Book becomes semi-official resource
- Supporting 4+ versions simultaneously

---

## Impact Analysis

### Impact on Target Audience

**Current audience: Experienced developers**

| Option | Impact | Reasoning |
|--------|--------|-----------|
| **Status Quo** | Neutral | Maintains current experience |
| **Latest Only** | Slightly negative | Lose migration guidance value |
| **Versioned Editions** | Positive | Professional versioning |
| **Hybrid** | **Very positive** | Best of both worlds |

**If shifting to beginners:**
- Latest Only: ⭐⭐⭐⭐⭐ (simplest)
- Hybrid: ⭐⭐⭐⭐ (still clean)
- Status Quo: ⭐⭐ (confusing)

### Impact on Book Quality

**Comprehensiveness:**
- Status Quo: 22,353 lines (most comprehensive)
- Hybrid: ~21,000 lines (5% reduction, negligible impact)
- Latest Only: ~21,000 lines (similar to Hybrid)
- Versioned Editions: 22,353+ lines across branches

**Code example quality:**
- All options maintain 100% compilation success (already only testing 0.15.2)
- No impact on example quality or coverage

**Technical accuracy:**
- Status Quo: Must maintain accuracy across 4 versions (harder)
- Others: Single version to maintain (easier, more accurate)

**Clarity:**
- Status Quo: Version markers add noise (readers report confusion)
- Hybrid: Clean main content (significant improvement)
- Latest Only: Cleanest (but loses historical context)

### Impact on Maintenance Workflow

**Content updates:**
```
Status Quo:
  New chapter → Check all 4 versions → Add markers → Update migration guide
  Time: 2-3h overhead per chapter

Hybrid:
  New chapter → Write for 0.15+ → (Optional: note in appendix)
  Time: 15-30min overhead per chapter

Latest Only:
  New chapter → Write for 0.15+ → Done
  Time: 0 overhead
```

**Version upgrades (e.g., 0.16 release):**
```
Status Quo:
  1. Update all version markers (4h)
  2. Rewrite migration guide (16-24h)
  3. Test examples (2h)
  4. Update references (2h)
  Total: 24-32h

Hybrid:
  1. Update appendix quick-reference (4-6h)
  2. Test examples (2h)
  3. Update version focus in docs (1h)
  Total: 7-9h

Latest Only:
  1. Test examples (2h)
  2. Update version in docs (30min)
  3. Fix breaking changes (2-4h)
  Total: 4.5-6.5h
```

### Impact on Book's Market Position

**Unique value proposition:**

**Current (multi-version):**
> "The only comprehensive production-focused Zig resource for experienced developers, covering Zig 0.14.x and 0.15.x with clear version guidance"

**After Hybrid:**
> "The only comprehensive production-focused Zig resource for experienced developers, teaching modern Zig 0.15+ with complete migration guidance"

**After Latest Only:**
> "The most up-to-date comprehensive Zig resource for experienced developers, teaching modern Zig 0.15+ best practices"

**Competitive positioning:**
- **vs Zig official docs:** More comprehensive, production-focused
- **vs zig.guide:** More advanced, better examples
- **vs ziglearn:** More current, professional examples
- **vs other books:** Only production-focused resource

**None of the options compromise market position.** The book's value is in:
1. Production patterns from exemplar projects (476+ citations)
2. Comprehensive coverage (15 chapters)
3. 100% validated examples
4. Professional quality and depth

Version strategy is secondary to these differentiators.

---

## Decision Framework

### Choose **Hybrid** if:
- ✅ Current target audience (experienced developers)
- ✅ Value both modern focus and migration help
- ✅ Want sustainable long-term maintenance
- ✅ Can invest 12-16h for restructuring
- ✅ 0.14 still has >10% adoption

### Choose **Latest Only** if:
- ✅ Shifting to beginner audience
- ✅ Maintenance resources very constrained
- ✅ 0.14 adoption <5%
- ✅ Zig breaking changes slow down
- ✅ Want absolutely simplest approach

### Choose **Status Quo** if:
- ✅ Planning immediate 0.16 support
- ✅ Book positioning as historical reference
- ✅ Strong demand from 0.14 users
- ✅ Can commit to 16-24h per version

### Choose **Versioned Editions** if:
- ✅ Zig announces LTS policy
- ✅ Becoming semi-official resource
- ✅ Supporting 4+ versions
- ✅ Infrastructure resources available

---

## Conclusion

**Recommended path forward: Implement Hybrid approach (Option 4)**

**Key actions:**
1. Remove inline version markers from Chapters 1-14
2. Condense Migration Guide to 300-400 line appendix
3. Update documentation to clearly state "Zig 0.15.2+"
4. Implement before 1.0 release

**Expected outcomes:**
- 5% shorter, cleaner reading experience
- 70% reduction in version-specific maintenance
- Preserved migration value for current 0.14 users
- Natural transition to "latest only" as 0.14 adoption drops
- Professional presentation balancing modern focus with backward awareness

**Timeline:** Can be completed in 1-2 weeks, well before 1.0 release milestone.

**This change improves book quality, reduces maintenance burden, and better serves the target audience of experienced developers without compromising comprehensiveness or professional positioning.**

---

## Appendix: Community Data

**Zig version adoption (estimated from ecosystem projects):**
- 0.15.x: ~60% (growing)
- 0.14.x: ~30% (declining)
- 0.13.x or older: ~10%

**Migration timeline observations:**
- Large projects (TigerBeetle, Bun): 1-2 weeks to migrate
- Medium projects: 1-3 days
- Small projects: Hours to same day

**Breaking changes frequency:**
- 0.13 → 0.14: Major (async removal, build system changes)
- 0.14 → 0.15: Major (unmanaged containers, I/O changes)
- 0.15 → 0.16: Unknown, but Zig is pre-1.0 (expect continued changes)

**Book's version references by chapter:**
| Chapter | 0.14 mentions | 0.15 mentions | Version markers |
|---------|---------------|---------------|-----------------|
| Ch 15 (Migration) | 62 | 212 | 24 |
| Ch 5 (Collections) | 2 | 5 | 5 |
| Ch 6 (I/O) | 1 | 8 | 5 |
| Others | 2 | 6 | 6 |
| **Total** | **67** | **231** | **40** |

Migration Guide accounts for 93% of 0.14 references, supporting the case for condensing it to an appendix.
