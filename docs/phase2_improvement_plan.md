# Zig Guide: Quality Density Improvement - Phase 2 Plan

**Date:** 2025-11-10
**Status:** Ready for Execution
**Branch:** `claude/improve-book-quality-density-011CUziCaGVJMFdyF984ZxUo`
**Parent:** COMPLETION_SUMMARY.md (Phase 1 complete)

---

## Executive Summary

Phase 1 improved scannability with TL;DR boxes and comparison tables (+36 lines, massive UX improvement). Phase 2 focuses on completing those improvements across ALL chapters while aggressively tightening prose to achieve a NET REDUCTION in line count without losing information.

**Goals:**
- Complete TL;DR boxes for remaining 9 chapters
- Add 5-7 strategic comparison tables
- Aggressive prose tightening in verbose sections
- Target: -200 to -400 net line reduction (1-2%)
- Improve: Information density, scannability, conciseness

---

## Current State Analysis

### Chapters by Status

| Chapter | Lines | Has TL;DR | Tables | Sections | Priority |
|---------|-------|-----------|--------|----------|----------|
| **Ch11 Testing** | 2,698 | ✅ | 11 | 35 | HIGH (longest) |
| **Ch10 Interop** | 2,530 | ✅ | 55 | 33 | HIGH (2nd longest) |
| **Ch14 Appendices** | 2,375 | ❌ | 0 | 127 | LOW (reference) |
| **Ch9 Project Layout** | 2,111 | ❌ | 0 | 44 | HIGH (missing TL;DR) |
| **Ch6 Async** | 1,845 | ✅ | 46 | 36 | MEDIUM (long, has TL;DR) |
| **Ch12 Logging** | 1,260 | ❌ | 0 | 27 | HIGH (missing TL;DR) |
| **Ch13 Migration** | 1,237 | ❌ | 0 | 32 | HIGH (missing TL;DR) |
| **Ch5 Errors** | 1,190 | ✅ | 0 | 28 | MEDIUM (add tables) |
| **Ch3 Collections** | 1,042 | ❌ | 1 | 28 | HIGH (missing TL;DR) |
| **Ch7 Build System** | 960 | ❌ | 0 | 31 | HIGH (missing TL;DR) |
| **Ch8 Packages** | 843 | ❌ | 0 | - | HIGH (missing TL;DR) |
| **Ch4 I/O** | 747 | ❌ | 1 | - | MEDIUM (missing TL;DR) |
| **Ch1 Idioms** | 621 | ❌ | 0 | - | MEDIUM (missing TL;DR) |
| **Ch2 Memory** | 442 | ✅ | 8 | - | ✅ COMPLETE |
| **Ch0 Intro** | 342 | ❌ | 0 | - | LOW (intro chapter) |

### Key Findings

**Missing TL;DR:** 9 chapters (60% of guide)
**Largest chapters:** Ch11 (2,698), Ch10 (2,530), Ch14 (2,375), Ch9 (2,111)
**Complex chapters:** Ch14 (127 sections!), Ch9 (44), Ch6 (36)
**Table opportunities:** 5-6 chapters with 0-1 tables

---

## Phase 2 Strategy: Three Waves

### Wave 1: Complete TL;DR Coverage (2-3 hours)
**Impact:** High | **Effort:** Low | **Line Cost:** +70-90

Add TL;DR boxes to remaining 9 chapters to complete navigation coverage.

### Wave 2: Strategic Comparison Tables (3-4 hours)
**Impact:** High | **Effort:** Medium | **Line Cost:** +40-60, Save: -100-150

Replace verbose prose with scannable tables in 5-7 chapters.

### Wave 3: Aggressive Prose Tightening (4-6 hours)
**Impact:** High | **Effort:** High | **Line Savings:** -300-500

Condense verbose sections, remove filler, tighten explanations without losing information.

**Net Target:** -200 to -400 lines while adding high-value content

---

## Wave 1: Complete TL;DR Coverage

### Chapters Needing TL;DR (Priority Order)

#### 1. Ch9 Project Layout, Cross-Compilation & CI (2,111 lines)
**Priority:** CRITICAL (longest without TL;DR)

```markdown
> **TL;DR for project setup:**
> - **Standard layout:** `src/` (source), `build.zig` (build script), `build.zig.zon` (deps)
> - **Cross-compile:** `zig build -Dtarget=aarch64-linux` (any target from any host)
> - **CI setup:** GitHub Actions with `zig build test` + cross-platform builds
> - **Common targets:** x86_64-linux, x86_64-windows, aarch64-macos, wasm32-freestanding
> - **Jump to:** [Layout §9.2](#project-structure) | [Cross-compile §9.4](#cross-compilation) | [CI examples §9.6](#ci-integration)
```

#### 2. Ch12 Logging, Diagnostics & Observability (1,260 lines)
**Priority:** HIGH

```markdown
> **TL;DR for production logging:**
> - **std.log:** Built-in logging with compile-time levels (err, warn, info, debug)
> - **Custom loggers:** Implement `log` function with custom formatting/output
> - **Structured logging:** Use `@src()` for file/line info, custom data fields
> - **Production:** std.log to stderr, custom logger for JSON/metrics export
> - **Jump to:** [Basic logging §12.2](#stdlog-usage) | [Custom loggers §12.4](#custom-log-implementations)
```

#### 3. Ch13 Migration Guide (0.14.1 → 0.15.2) (1,237 lines)
**Priority:** HIGH (critical for upgraders)

```markdown
> **TL;DR for 0.14 → 0.15 migration:**
> - **Breaking:** Async/await removed (use threads + libraries like libxev)
> - **Breaking:** `std.ArrayList(T)` now unmanaged (pass allocator to methods)
> - **Breaking:** `std.fs.File.stdout()` replaces `std.io.getStdOut()`
> - **Build:** `b.path()` replaces string paths, `b.addExecutable()` API changed
> - **See:** [Breaking changes summary §13.2](#breaking-changes-overview) | [Migration recipes §13.4](#migration-patterns)
```

#### 4. Ch3 Collections & Containers (1,042 lines)
**Priority:** HIGH

```markdown
> **TL;DR for Zig collections:**
> - **0.15 default:** `ArrayList(T)` is unmanaged (pass allocator to methods)
> - **Managed variant:** `ArrayListManaged(T)` stores allocator (simpler API, +8 bytes overhead)
> - **Common types:** ArrayList, HashMap, AutoHashMap, StringHashMap
> - **Always:** Call `.deinit(allocator)` to free memory
> - **See [comparison table](#managed-vs-unmanaged-containers) below**
```

#### 5. Ch7 Build System (build.zig) (960 lines)
**Priority:** MEDIUM

```markdown
> **TL;DR for build.zig:**
> - **Entry point:** `pub fn build(b: *std.Build) void`
> - **Executables:** `b.addExecutable(.{ .name = "app", .root_module = ... })`
> - **Libraries:** `b.addStaticLibrary()` or `b.addSharedLibrary()`
> - **Dependencies:** `b.dependency("name", .{})` from build.zig.zon
> - **Run:** `b.installArtifact(exe)` + `zig build` compiles, `zig build run` executes
> - **Jump to:** [Basic build §7.2](#basic-build-configuration) | [Dependencies §7.5](#dependency-management)
```

#### 6. Ch8 Packages & Dependencies (build.zig.zon) (843 lines)
**Priority:** MEDIUM

```markdown
> **TL;DR for package management:**
> - **build.zig.zon:** Package manifest with name, version, dependencies
> - **Add dependency:** Edit build.zig.zon + `b.dependency("name", .{})` in build.zig
> - **Sources:** URL (tarball/git), path (local), system (pkg-config/vcpkg)
> - **Version:** Use git commit hash or tarball hash for reproducibility
> - **Jump to:** [Creating packages §8.3](#creating-packages) | [Consuming deps §8.4](#dependency-consumption)
```

#### 7. Ch4 I/O, Streams & Formatting (747 lines)
**Priority:** MEDIUM

```markdown
> **TL;DR for Zig I/O:**
> - **0.15 change:** `std.fs.File.stdout()` replaces `std.io.getStdOut()`
> - **Writers:** `file.writer(&buf)` creates buffered writer, empty slice = unbuffered
> - **Readers:** `file.reader(&buf)` for buffered reading
> - **Formatting:** `writer.interface.print("fmt {d}", .{val})`
> - **Files:** `std.fs.cwd().openFile()`, always `defer file.close()`
> - **Jump to:** [Formatting §4.3](#formatting-and-print) | [File patterns §4.2](#file-io-patterns)
```

#### 8. Ch1 Language Idioms & Core Patterns (621 lines)
**Priority:** MEDIUM

```markdown
> **TL;DR for Zig idioms:**
> - **comptime:** Compile-time execution (generics, code generation, validation)
> - **defer/errdefer:** Deterministic cleanup (LIFO order, see Ch5)
> - **Error unions:** `!T` syntax, propagate with `try`, handle with `catch`
> - **Optionals:** `?T` syntax, unwrap with `orelse` or `if (val) |v| { ... }`
> - **No hidden control flow:** No exceptions, no operator overloading, explicit allocations
```

#### 9. Ch14 Appendices (2,375 lines)
**Priority:** LOW (reference material, TL;DR less useful)

**Decision:** Skip TL;DR for appendices - it's reference material meant for deep-diving.

**Wave 1 Total:** 8 TL;DR boxes, +70-80 lines

---

## Wave 2: Strategic Comparison Tables

### Table Opportunities (High Value)

#### 1. Ch7: Build Modes Comparison

**Location:** After "Build Configuration" section
**Replaces:** ~60 lines of prose explaining Debug, ReleaseSafe, ReleaseFast, ReleaseSmall

```markdown
| Build Mode | Optimization | Safety Checks | Binary Size | Use Case |
|------------|--------------|---------------|-------------|----------|
| `Debug` (default) | None | All | Largest | Development, debugging |
| `ReleaseSafe` | Yes | Runtime | Medium | Production (safety priority) |
| `ReleaseFast` | Aggressive | None | Medium | Production (performance priority) |
| `ReleaseSmall` | Size | None | Smallest | Embedded, WASM |

**Key trade-offs:**
- Debug: Slowest but safest, preserves stack traces, detects undefined behavior
- ReleaseSafe: ~10-20% slower than ReleaseFast, catches integer overflow/bounds
- ReleaseFast: Maximum performance, undefined behavior is actually undefined
- ReleaseSmall: Smallest binary, useful for resource-constrained environments
```

**Savings:** ~40 lines

#### 2. Ch9: CI Platform Comparison

**Location:** "CI Integration" section
**Replaces:** ~80 lines explaining GitHub Actions, GitLab CI, etc.

```markdown
| Platform | Zig Setup | Cross-Compile | Matrix Builds | Caching | Free Tier |
|----------|-----------|---------------|---------------|---------|-----------|
| **GitHub Actions** | `goto-bus-stop/setup-zig@v2` | ✅ Easy | ✅ Native | ✅ Good | 2,000 min/mo |
| **GitLab CI** | Docker image | ✅ Easy | ✅ Native | ✅ Good | 400 min/mo |
| **Circle CI** | Docker image | ✅ Easy | ✅ Native | ⚠️ Manual | 1,000 min/mo |
| **Travis CI** | Custom script | ⚠️ Manual | ✅ Native | ⚠️ Manual | 1,000 min/mo |

**Recommendation:** GitHub Actions (easiest setup, best docs, good caching)

**Example workflow:** See §9.6.2
```

**Savings:** ~60 lines

#### 3. Ch5: Error Handling Strategies

**Location:** After "Error Sets and Error Unions" section
**Replaces:** ~50 lines of narrative

```markdown
| Strategy | Syntax | When to Use | Example |
|----------|--------|-------------|---------|
| **Propagate** | `try operation()` | Can't handle error here | `const data = try file.read();` |
| **Provide default** | `catch default_value` | Acceptable fallback exists | `const count = parse(str) catch 0;` |
| **Handle & continue** | `catch \|err\| { ... }` | Can recover from error | `loadConfig() catch \|e\| { log(e); return default_config; }` |
| **Switch on error** | `catch \|err\| switch (err)` | Different actions per error | `query() catch \|e\| switch (e) { error.Timeout => retry(), ... }` |
| **Panic** | `catch unreachable` | Error is impossible | `std.fmt.parseInt(u8, "42", 10) catch unreachable` |
| **Ignore** | `catch {}` | Error doesn't matter | `file.close() catch {};` |

**Best practice:** Always propagate unless you can meaningfully handle the error.
```

**Savings:** ~30 lines

#### 4. Ch3: Collection Type Comparison

**Location:** After "Container Type Taxonomy" section
**Replaces:** ~100 lines of individual container descriptions

```markdown
| Type | Ordered | Key/Value | Lookup | Insert | Use Case |
|------|---------|-----------|--------|--------|----------|
| `ArrayList(T)` | ✅ | Value only | O(1) index | O(1) amortized append | Dynamic array, stack |
| `HashMap(K, V, ctx)` | ❌ | K→V | O(1) average | O(1) average | Custom hasher needed |
| `AutoHashMap(K, V)` | ❌ | K→V | O(1) average | O(1) average | Default hasher (integers, pointers) |
| `StringHashMap(V)` | ❌ | String→V | O(1) average | O(1) average | String keys optimized |
| `ArrayHashMap(K, V)` | ✅ Insert order | K→V | O(1) average | O(1) average | Preserves insertion order |
| `BoundedArray(T, N)` | ✅ | Value only | O(1) index | O(1) if space | Fixed max capacity, no alloc |
| `TailQueue(T)` | ✅ | Linked nodes | O(n) | O(1) push/pop | Doubly-linked list |

**Quick selection:**
- Need index access? → `ArrayList`
- Need key lookup? → `HashMap` variants
- Need ordering? → `ArrayList` or `ArrayHashMap`
- Known max size? → `BoundedArray` (no allocator needed)
```

**Savings:** ~70 lines

#### 5. Ch13: Breaking Changes Summary Table

**Location:** Beginning of migration guide
**Replaces:** ~80 lines scattered explanations

```markdown
| Area | 0.14.x | 0.15.0+ | Migration |
|------|--------|---------|-----------|
| **Async** | `async fn`, `await` | Removed | Use `std.Thread` + event loops |
| **ArrayList** | Managed (stores allocator) | Unmanaged (pass allocator) | Add allocator param to methods |
| **Stdout** | `std.io.getStdOut()` | `std.fs.File.stdout()` | Update all call sites |
| **Build paths** | String literals | `b.path("str")` | Wrap paths in `b.path()` |
| **Executable** | `.addExecutable("name", "src")` | `.addExecutable(.{ ... })` | Use struct syntax |
| **Hash functions** | `std.hash.Wyhash` | `std.hash.XxHash3` | Update imports |

**See detailed migration recipes:** §13.4
```

**Savings:** ~60 lines

#### 6. Ch8: Dependency Source Comparison

**Location:** "Dependency Sources" section

```markdown
| Source Type | Syntax | Integrity | Update Method | Use Case |
|-------------|--------|-----------|---------------|----------|
| **Git URL** | `.url = "https://..."` | Git hash | Change hash | Public repos |
| **Tarball URL** | `.url = "https://.../v1.tar.gz"` | SHA-256 hash | Change URL + hash | Releases |
| **Local path** | `.path = "libs/mylib"` | None (dev only) | Edit files directly | Monorepos, dev |
| **System** | `.system = "pkg-config"` | System manager | OS package manager | C libraries |

**Best practice:** Use git hashes or tarball hashes for reproducible builds.
```

**Savings:** ~40 lines

**Wave 2 Total:** 6 tables, +40-60 lines added, -300-360 lines removed, **net: -240-300 lines**

---

## Wave 3: Aggressive Prose Tightening

### Target: -300-500 Lines Without Information Loss

#### Strategy 1: Condense Verbose Explanations

**Pattern:** Multi-paragraph explanations → Single paragraph + example

**Example (from various chapters):**

```markdown
❌ BEFORE (6 lines):
The standard library's ArrayList provides dynamic array functionality with
automatic capacity management. When elements are added and the current capacity
is exceeded, the ArrayList automatically reallocates to a larger buffer,
typically doubling the capacity to minimize reallocation frequency. This
amortized constant-time append operation makes ArrayList suitable for scenarios
where the final size is unknown at initialization time.

✅ AFTER (3 lines):
`ArrayList` provides a dynamic array with automatic growth (doubles capacity when full).
Append is O(1) amortized. Use when final size is unknown.

```zig
var list = ArrayList(u8){};
try list.append(allocator, 'x');  // Auto-grows as needed
```
```

**Target chapters:** Ch3, Ch4, Ch6, Ch7, Ch9
**Expected savings:** ~100-150 lines

#### Strategy 2: Eliminate Conversational Filler

**Search and destroy patterns:**

```bash
# Find conversational filler
grep -n "As we have seen\|As mentioned\|It is important to note\|Let's\|Now that\|Before we" sections/*/content.md

# Find redundant transitions
grep -n "In this section\|This section\|The following\|As follows" sections/*/content.md

# Find obvious statements
grep -n "It's worth noting\|Note that\|Keep in mind\|Remember that" sections/*/content.md
```

**Examples to cut:**
- ❌ "It's important to note that..." → just state the fact
- ❌ "Let's examine how..." → just show the how
- ❌ "As we'll see in the following example..." → just show the example
- ❌ "Now that we understand X..." → just continue

**Target:** All chapters
**Expected savings:** ~50-80 lines

#### Strategy 3: Compress Code Example Explanations

**Pattern:** Before/after explanations → Inline comments only

```markdown
❌ BEFORE (10 lines):
The following example demonstrates proper resource cleanup using defer.
The defer statement is placed immediately after resource allocation,
ensuring cleanup occurs regardless of how the function exits.

```zig
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();
```

Note that defer executes in LIFO order, so multiple defer statements
will execute in reverse order of declaration.

✅ AFTER (4 lines):
```zig
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();  // LIFO cleanup - executes at scope exit
```
```

**Target chapters:** Ch3, Ch4, Ch6, Ch7, Ch11
**Expected savings:** ~80-120 lines

#### Strategy 4: Consolidate Repetitive Examples

**Pattern:** 3-4 similar examples → 1 comprehensive example

**Example:**
❌ Multiple examples showing ArrayList.append(), ArrayList.insert(), ArrayList.pop()
✅ Single example showing all common operations with comments

**Target chapters:** Ch3, Ch4, Ch11
**Expected savings:** ~60-100 lines

#### Strategy 5: Tighten Production Pattern Explanations

**Pattern:** Verbose backstory → Core pattern + production reference

```markdown
❌ BEFORE (8 lines):
TigerBeetle, a distributed database optimized for financial transactions,
implements sophisticated testing patterns to ensure correctness in the face
of network failures and concurrent operations. Their test suite includes
deterministic time simulation and network fault injection capabilities that
enable testing distributed consensus algorithms without the flakiness typically
associated with distributed systems testing. This approach has proven effective
in catching subtle bugs that only manifest under specific timing conditions.

✅ AFTER (3 lines):
**TigerBeetle pattern:** Deterministic time simulation + network fault injection for
testing distributed consensus without flakiness.[^ref]

[^ref]: https://github.com/tigerbeetle/tigerbeetle/tree/main/src/testing
```

**Target chapters:** Ch9, Ch11, Ch12
**Expected savings:** ~40-60 lines

**Wave 3 Total:** -330-510 lines

---

## Implementation Timeline

### Week 1: Wave 1 - TL;DR Boxes (2-3 hours)

**Day 1 (2 hours):**
- Add TL;DR to Ch9, Ch12, Ch13 (critical chapters)
- Add TL;DR to Ch3, Ch7, Ch8 (medium chapters)

**Day 2 (1 hour):**
- Add TL;DR to Ch4, Ch1 (smaller chapters)
- Commit with metrics

**Deliverable:** All chapters have navigation aids
**Line cost:** +70-80 lines

### Week 2: Wave 2 - Comparison Tables (3-4 hours)

**Day 3 (2 hours):**
- Ch7: Build modes table
- Ch9: CI platforms table
- Ch5: Error strategies table

**Day 4 (2 hours):**
- Ch3: Collection types table
- Ch13: Breaking changes table
- Ch8: Dependency sources table

**Deliverable:** 6 new comparison tables
**Line savings:** -240-300 lines (net, after adding tables)

### Week 3: Wave 3 - Aggressive Tightening (4-6 hours)

**Day 5 (2 hours):**
- Strategy 1: Condense verbose explanations (Ch3, Ch4, Ch6)

**Day 6 (2 hours):**
- Strategy 2: Eliminate filler (all chapters)
- Strategy 3: Compress code explanations (Ch3, Ch4, Ch6)

**Day 7 (2 hours):**
- Strategy 4: Consolidate examples (Ch3, Ch4, Ch11)
- Strategy 5: Tighten production patterns (Ch9, Ch11, Ch12)

**Deliverable:** Prose condensed across all chapters
**Line savings:** -330-510 lines

---

## Expected Final Results

### Quantitative Targets

| Metric | Current | Target | Change |
|--------|---------|--------|--------|
| Total lines | 20,243 | 19,800-19,900 | -300-450 (-1.5-2.2%) |
| Chapters with TL;DR | 5 (33%) | 13 (87%) | +8 |
| Comparison tables | 15 | 21 | +6 (+40%) |
| Average chapter size | 1,349 | ~1,320 | -30 |
| Dense overviews | 2 | 13 | +11 |

### Qualitative Goals

**✅ Every chapter scannable in <1 minute** (via TL;DR)
**✅ Tables enable quick decision-making** (build modes, CI platforms, etc.)
**✅ No prose bloat** (filler eliminated)
**✅ Code examples self-documenting** (inline comments replace prose)
**✅ Production patterns referenced concisely**

---

## Risk Mitigation

### Risk: Over-aggressive cutting loses clarity

**Mitigation:**
- Review each cut with "Does this remove information or just words?"
- Keep technical content, remove narrative fluff
- Test with target audience (experienced systems programmers)

### Risk: Tables become too dense

**Mitigation:**
- Limit to 5-6 columns maximum
- Use clear, scannable headers
- Include "Quick selection" guide below table
- Provide examples after table

### Risk: TL;DR becomes stale

**Mitigation:**
- Link TL;DR to specific sections (jump links)
- Include version-specific notes (0.14 vs 0.15)
- Review TL;DR after content changes

---

## Validation Checklist

After each wave:

**Code Quality:**
- [ ] All code examples still compile
- [ ] Cross-references still valid
- [ ] Jump links work correctly

**Content Quality:**
- [ ] No technical information lost
- [ ] Tables are accurate
- [ ] TL;DR matches chapter content
- [ ] Examples still comprehensive

**User Experience:**
- [ ] Skimmers find answers quickly
- [ ] Tables enable decisions
- [ ] Navigation improved
- [ ] No confusion from cuts

---

## Success Criteria

### Must Achieve:
- ✅ 8+ TL;DR boxes added (covering 87% of guide)
- ✅ 6+ comparison tables added
- ✅ Net line reduction of 200+ lines
- ✅ Improved scannability (validated via team review)
- ✅ No technical accuracy lost

### Stretch Goals:
- 🎯 All 13 content chapters have TL;DR (exclude appendices)
- 🎯 -400+ line reduction (2%)
- 🎯 Average chapter under 1,300 lines
- 🎯 Reader feedback: "Easy to scan" >90%

---

## Next Steps

**Choose execution approach:**

**Option A: Execute all waves sequentially** (recommended)
- Week 1: TL;DR boxes
- Week 2: Comparison tables
- Week 3: Prose tightening
- Timeline: ~10-13 hours total

**Option B: Execute waves in parallel** (faster but riskier)
- Simultaneous work on multiple chapters
- Timeline: ~6-8 hours total
- Risk: Merge conflicts, inconsistency

**Option C: Pilot on single chapter** (lowest risk)
- Choose Ch9 (longest without TL;DR)
- Execute all 3 waves on Ch9
- Validate approach before full rollout
- Timeline: ~2 hours pilot + 8-11 hours full

---

## Automation & Measurement

### Scripts to Create/Update

```bash
# 1. Find verbose explanations
scripts/find_verbose_prose.sh
# Identifies paragraphs >100 words for review

# 2. Detect conversational filler
scripts/detect_filler.sh
# Greps for filler patterns, outputs locations

# 3. Compare before/after
scripts/compare_density.sh
# Runs density_heatmap.sh and shows improvements
```

### Metrics to Track

**Before each wave:**
```bash
./scripts/measure_baseline.sh > metrics/before_wave_N.txt
```

**After each wave:**
```bash
./scripts/measure_baseline.sh > metrics/after_wave_N.txt
./scripts/compare_density.sh metrics/before_wave_N.txt metrics/after_wave_N.txt
```

---

## Commit Strategy

**Wave 1 Commit:**
```
feat: add TL;DR boxes to 8 remaining content chapters

Complete TL;DR coverage for quick navigation.

- Ch9: Project layout, cross-compilation, CI
- Ch12: Logging and diagnostics
- Ch13: Migration guide (0.14 → 0.15)
- Ch3: Collections and containers
- Ch7: Build system (build.zig)
- Ch8: Packages and dependencies
- Ch4: I/O, streams, formatting
- Ch1: Language idioms

Impact: +70-80 lines, 87% of guide now has TL;DR
```

**Wave 2 Commit:**
```
feat: add 6 comparison tables for quick decision-making

Replace verbose prose with scannable tables.

- Ch7: Build modes (Debug/ReleaseSafe/ReleaseFast/ReleaseSmall)
- Ch9: CI platforms (GitHub/GitLab/Circle/Travis)
- Ch5: Error handling strategies
- Ch3: Collection types comparison
- Ch13: Breaking changes (0.14 vs 0.15)
- Ch8: Dependency sources (git/tarball/local/system)

Impact: -240-300 lines net (added tables, removed prose)
```

**Wave 3 Commit:**
```
refactor: aggressive prose tightening across all chapters

Condense verbose explanations without information loss.

Strategies:
1. Multi-paragraph → single paragraph + example
2. Eliminate conversational filler
3. Compress code example explanations → inline comments
4. Consolidate repetitive examples
5. Tighten production pattern references

Impact: -330-510 lines, improved clarity and conciseness
```

---

## Ready to Execute

All planning complete. Choose an option above and we can begin Wave 1.

**Recommended:** Option A (sequential waves) for maximum confidence and measurability.

**Files created:**
- `docs/phase2_improvement_plan.md` (this document)

**Next command:** Start with Wave 1, Chapter 9 (highest priority)

---

**Last updated:** 2025-11-10
**Status:** ✅ READY FOR EXECUTION
