# Content Outline: Chapter 14 - Migration Guide (0.14.1 → 0.15.2)

**Target Length**: 1200-1500 lines
**Structure**: 7 required sections
**Examples**: 6 complete migration examples
**Citations**: 29+ authoritative sources

---

## Section Breakdown with Line Estimates

| Section | Lines | Percentage | Purpose |
|---------|-------|------------|---------|
| 1. Overview | 100-150 | 8-10% | Context and scope |
| 2. Core Concepts | 300-350 | 22-25% | Breaking changes explained |
| 3. Code Examples | 400-500 | 30-35% | Working migration code |
| 4. Common Pitfalls | 200-250 | 15-17% | Errors and solutions |
| 5. In Practice | 100-150 | 8-10% | Real-world patterns |
| 6. Summary | 50-75 | 4-5% | Key takeaways |
| 7. References | 30-50 | 2-3% | Citations |
| **TOTAL** | **1180-1525** | **100%** | **~1350 target** |

---

## 1. Overview (100-150 lines)

### Purpose
Set context for migration, explain why changes were made, and provide roadmap.

### Subsections

#### 1.1 Introduction (20-30 lines)
- What this chapter covers
- Target audience (developers upgrading from 0.14.1)
- Why migration is necessary
- Expected migration timeframe

#### 1.2 Breaking Changes Summary (30-40 lines)
- **Critical**: Build system, I/O, ArrayList (table format)
- Impact assessment per change
- Quick reference for what affects your code
- Migration effort estimates

#### 1.3 Migration Philosophy (20-30 lines)
- Why Zig makes breaking changes
- Design goals: explicitness, performance, safety
- Long-term benefits of migration
- Community feedback and consensus

#### 1.4 How to Use This Guide (20-30 lines)
- Reading the examples
- Testing migration incrementally
- When to seek help
- Link to online resources

### Key Points to Cover
- Migration is mandatory for 0.15.2
- Most changes caught by compiler
- Examples provide before/after patterns
- Expected timeframe: 1-4 hours for typical projects

---

## 2. Core Concepts (300-350 lines)

### Purpose
Explain each breaking change in detail with rationale and migration patterns.

### 2.1 Build System Changes (90-110 lines)

#### What Changed (20-25 lines)
- `root_module` became required (not optional)
- Deprecated convenience fields removed
- Unified library API (`addLibrary` vs `addStaticLibrary`/`addSharedLibrary`)

#### Why the Change (15-20 lines)
- Explicit module configuration
- Better build graph analysis
- Clearer dependency management
- Forward compatibility

#### Migration Pattern (35-45 lines)
- Simple executable example
- Library example
- Multi-module example
- Code snippets with inline comments

#### Common Errors (20-25 lines)
- Missing `root_module` field
- Wrong parameter location
- Library linkage confusion

### 2.2 I/O and Writer Changes (90-110 lines)

#### What Changed (25-30 lines)
- stdout/stderr relocated to `std.fs.File`
- `writer()` requires buffer parameter
- Methods accessed via `.interface` field
- Manual `flush()` required

#### Why the Change (20-25 lines)
- Explicit buffering control
- Performance predictability
- Clear resource ownership
- Better error handling

#### Migration Pattern (30-40 lines)
- Buffered stdout example
- Unbuffered stderr example
- File writing example
- When to use which approach

#### Common Errors (15-20 lines)
- Missing buffer parameter
- Forgetting `.interface` accessor
- Forgetting `flush()` (silent data loss)
- Buffer lifetime issues

### 2.3 ArrayList Default Change (90-110 lines)

#### What Changed (25-30 lines)
- `ArrayList(T)` now unmanaged by default
- `ArrayListUnmanaged` deprecated (just use `ArrayList`)
- All mutation methods require allocator parameter
- Managed wrapper available but deprecated

#### Why the Change (20-25 lines)
- Memory overhead reduction (8 bytes per container)
- Allocation visibility
- Better composition in structs
- Community consensus ("Embracing Unmanaged")

#### Migration Pattern (30-40 lines)
- Simple ArrayList example
- ArrayList in struct fields
- Multiple strategies (unmanaged vs managed wrapper)
- Decision tree for migration approach

#### Common Errors (15-20 lines)
- Missing allocator parameters
- Using `.init()` with unmanaged
- Wrong allocator lifetime
- Mixing managed/unmanaged

### 2.4 Other Notable Changes (30-40 lines)

#### Formatting API (15-20 lines)
- `FormatOptions` → `Options` (deprecated alias)
- New `Case` enum
- New `Number` struct
- Minimal migration impact

#### Module Organization (15-20 lines)
- stdout/stderr relocation summary
- New `Io.zig` module
- Backward compatibility notes

---

## 3. Code Examples (400-500 lines)

### Purpose
Provide complete, working migration examples for common scenarios.

### Example Structure
Each example follows this pattern:
1. Brief description (what it demonstrates)
2. 0.14.1 code block
3. 0.15.2 code block
4. Key differences explained
5. Migration steps

### 3.1 Example 1: Simple Build Migration (60-70 lines)
- **What**: Basic executable build.zig
- **0.14.1 Code**: 20-25 lines
- **0.15.2 Code**: 20-25 lines
- **Explanation**: 15-20 lines
- **Changes**: Wrap in `createModule()`, move target/optimize

### 3.2 Example 2: I/O stdout/stderr (70-80 lines)
- **What**: Console output migration
- **0.14.1 Code**: 15-20 lines
- **0.15.2 Code**: 20-25 lines
- **Explanation**: 25-30 lines
- **Changes**: Relocation, buffering, flush()

### 3.3 Example 3: ArrayList Migration (80-90 lines)
- **What**: Container default change
- **0.14.1 Code**: 20-25 lines
- **0.15.2 Code (unmanaged)**: 20-25 lines
- **0.15.2 Code (managed wrapper)**: 15-20 lines
- **Explanation**: 25-30 lines
- **Changes**: Allocator passing, memory savings

### 3.4 Example 4: File I/O with Buffering (70-80 lines)
- **What**: File writing with explicit buffering
- **0.14.1 Code**: 15-20 lines
- **0.15.2 Code**: 20-25 lines
- **Explanation**: 30-35 lines
- **Changes**: Buffer management, flush requirement, performance

### 3.5 Example 5: CLI Tool (70-80 lines)
- **What**: End-to-end application migration
- **Overview**: 10-15 lines (describe structure)
- **Key Migration Points**: 30-40 lines (across modules)
- **Explanation**: 25-30 lines
- **Changes**: Coordinated migration, testing strategy

### 3.6 Example 6: Library with Modules (70-80 lines)
- **What**: Library build and export
- **0.14.1 Code**: 20-25 lines
- **0.15.2 Code**: 20-25 lines
- **Explanation**: 25-30 lines
- **Changes**: Module export, API design

---

## 4. Common Pitfalls (200-250 lines)

### Purpose
Catalog frequent mistakes with clear solutions (❌ wrong, ✅ correct format).

### Structure
Each pitfall follows this pattern:
1. Pitfall name/description (5-10 lines)
2. ❌ Incorrect code example (10-15 lines)
3. Error message or symptom (3-5 lines)
4. ✅ Correct code example (10-15 lines)
5. Explanation and prevention (5-10 lines)

Total per pitfall: ~35-55 lines

### 4.1 Build System Pitfalls (60-80 lines)

**Pitfall 1**: Missing `root_module` field (35-40 lines)
- Symptom: "missing struct field: root_module"
- Solution: Add `createModule()` wrapper

**Pitfall 2**: Target/optimize in wrong location (35-40 lines)
- Symptom: "no field named 'target' in ExecutableOptions"
- Solution: Move inside `createModule()`

### 4.2 I/O Pitfalls (70-90 lines)

**Pitfall 3**: Forgetting flush() (40-45 lines)
- Symptom: Silent data loss, incomplete output
- Solution: Always flush before close
- Prevention: Add to cleanup checklist

**Pitfall 4**: Buffer lifetime issues (35-45 lines)
- Symptom: Use-after-free, undefined behavior
- Solution: Ensure buffer outlives writer
- Prevention: Keep buffer in same struct

### 4.3 ArrayList Pitfalls (70-80 lines)

**Pitfall 5**: Missing allocator parameter (35-40 lines)
- Symptom: "expected 3 arguments, found 2"
- Solution: Pass allocator to mutation methods

**Pitfall 6**: Wrong allocator (35-40 lines)
- Symptom: Runtime error, memory corruption
- Solution: Use same allocator consistently
- Prevention: Document allocator source

---

## 5. In Practice (100-150 lines)

### Purpose
Show how real-world projects handle migration.

### 5.1 TigerBeetle Patterns (30-40 lines)
- Build system approach (post-creation imports)
- Performance-critical I/O patterns
- Large-scale ArrayList migration
- Code examples from actual source[^8][^10][^27]

### 5.2 ZLS Patterns (30-40 lines)
- Options module organization (labeled blocks)
- Generated code integration
- LSP-specific I/O patterns
- Code examples from actual source[^9][^28]

### 5.3 Ghostty Patterns (20-30 lines)
- Terminal I/O migration
- Platform-aware code
- Container usage patterns
- References to actual implementation

### 5.4 Migration Timelines (20-30 lines)
- Typical project sizes and migration times
- Community migration experiences
- Lessons learned
- Best practices synthesis

---

## 6. Summary (50-75 lines)

### Purpose
Reinforce key concepts and provide action items.

### 6.1 Key Takeaways (20-25 lines)
- Three critical breaking changes (build, I/O, ArrayList)
- Migration is straightforward but pervasive
- Compiler catches most issues
- Real-world projects: 1-4 hours typically

### 6.2 Migration Decision Tree (15-20 lines)
- When to migrate: Before starting new features
- Approach: All-at-once for small projects, gradual for large
- Testing strategy: Incremental with frequent validation
- Rollback plan: Git branches and commits

### 6.3 Resources (15-20 lines)
- Link to example code in repository
- Reference to completed chapters (4, 5, 8)
- Community resources (Ziggit, Discord)
- Official release notes

---

## 7. References (30-50 lines)

### Purpose
Provide authoritative citations for all claims.

### Citation Format
```markdown
1. [Source Description](file_path_or_URL) - Specific detail cited
2. [Another Source](path) - What this supports
...
```

### Citation Categories

**Zig Standard Library** (10-15 citations):
- Build.zig (0.14.1 and 0.15.2)
- io.zig / Io.zig
- fs/File.zig
- array_list.zig
- fmt.zig

**Completed Chapters** (8-10 citations):
- Chapter 4 (Collections)
- Chapter 5 (I/O)
- Chapter 8 (Build System)
- Chapter 13 (Logging)

**Reference Projects** (6-8 citations):
- TigerBeetle build patterns
- ZLS options patterns
- Ghostty I/O patterns

**Planning Documents** (2-3 citations):
- research_plan.md
- research_notes.md

---

## Integration Points with Other Chapters

### Cross-References Required

**Chapter 4 (Collections & Containers)**:
- ArrayList patterns → Migration Example 3
- Managed vs unmanaged → Core Concepts 2.3
- Memory overhead → Core Concepts 2.3

**Chapter 5 (I/O, Streams & Formatting)**:
- Writer patterns → Core Concepts 2.2
- Buffering → Example 2 and 4
- stdout/stderr → Example 2

**Chapter 8 (Build System)**:
- build.zig structure → Core Concepts 2.1
- Module system → Example 1, 5, 6
- Build options → Example 5

**Chapter 9 (Packages & Dependencies)**:
- Module imports → Example 6
- Library creation → Example 6

**Chapter 10 (Project Layout & CI)**:
- Migration in practice → Section 5
- Testing strategy → Common Pitfalls

---

## Writing Guidelines

### Tone and Voice
- Neutral, professional technical English
- Active voice preferred
- No contractions ("do not" not "don't")
- Clear, direct explanations

### Code Formatting
- All code blocks must specify language: ` ```zig `
- Use inline comments sparingly
- Prefer self-documenting code
- Show complete, runnable examples

### Version Markers
- **🕐 0.14.x**: Legacy pattern (deprecated)
- **✅ 0.15+**: Current best practice
- Use side-by-side comparisons for major changes

### Error Examples
- **❌**: Incorrect code or approach
- **✅**: Correct code or solution
- Always include error message if compilation fails
- Explain why the error occurs

### Citations
- Footnote style: `[^1]`
- Deep links to specific files and line numbers
- References section at end with all citations

---

## Quality Checklist

Before finalizing content.md:

- [ ] All 7 required sections present
- [ ] Line count: 1200-1500 lines
- [ ] 6 complete code examples integrated
- [ ] All examples compile on both versions
- [ ] 29+ citations properly formatted
- [ ] Cross-references to chapters 4, 5, 8, 9, 10
- [ ] Version markers (🕐/✅) used correctly
- [ ] Common pitfalls with ❌/✅ format
- [ ] No contractions used
- [ ] All code blocks specify `zig` language
- [ ] No speculative statements
- [ ] Active voice throughout
- [ ] Proofread for typos/grammar

---

## Implementation Timeline

### Phase 1: Core Content (2 hours)
- Write Overview section
- Write Core Concepts section
- Integrate research from research_notes.md

### Phase 2: Examples (2 hours)
- Create all 6 examples
- Test on both versions
- Write example explanations

### Phase 3: Pitfalls & Practice (1 hour)
- Document 10-12 common pitfalls
- Write In Practice section with real-world patterns
- Add cross-references

### Phase 4: Polish (1 hour)
- Write Summary section
- Compile References section
- Proofread entire chapter
- Validate all citations
- Check line count

**Total Estimated Time**: 6-8 hours for content.md

---

**Document Status**: Complete outline ready for content generation
**Next Step**: Create 6 migration examples, then write content.md
**Target Completion**: content.md ready for review in 8-10 hours
