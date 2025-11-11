# Research Plan: Chapter 14 - Migration Guide (0.14.1 → 0.15.2)

**Chapter ID**: 14_migration_guide
**Status**: Research Phase
**Estimated Effort**: 20-28 hours
**Target Completion**: 4-5 days
**Last Updated**: 2025-11-05

---

## Executive Summary

This research plan outlines a systematic approach to documenting the migration path from Zig 0.14.1 to Zig 0.15.2. The chapter will serve as a practical playbook for upgrading existing codebases, focusing on the most impactful breaking changes with before/after examples and actionable migration strategies.

### Critical Breaking Changes Identified

1. **Build System**: `.root_module` is now required (not optional) - affects every build.zig
2. **I/O API**: Explicit writer buffering required, new `.interface` accessor - affects all I/O code
3. **ArrayList**: Default changed from managed to unmanaged - requires careful allocator management

---

## Research Goals

### Primary Objectives

1. **Comprehensive Coverage**: Document all breaking changes that affect typical Zig projects
2. **Practical Guidance**: Provide actionable migration patterns with working examples
3. **Real-World Context**: Extract patterns from production codebases (TigerBeetle, Ghostty, ZLS)
4. **Clear Migration Paths**: Offer multiple strategies (all-at-once, gradual, library maintainer)
5. **Error Prevention**: Catalog common pitfalls with solutions

### Success Criteria

- ✅ All 6 code examples compile on both Zig 0.14.1 and 0.15.2
- ✅ Content covers all breaking changes from metadata/sections.yaml
- ✅ 25+ authoritative citations from local sources
- ✅ Clear before/after for each migration pattern
- ✅ Actionable step-by-step migration checklist
- ✅ Real-world patterns from 3+ reference projects
- ✅ 10+ common pitfalls documented with ❌/✅ examples
- ✅ 1200-1500 lines of publication-ready content
- ✅ Seamless integration with chapters 4, 5, 8, 9, 10, 12

---

## Research Questions

### Critical Questions (Must Answer)

1. **Build System**
   - What exactly changed in the `.root_module` API?
   - How do you migrate simple vs complex build.zig files?
   - What are the new module creation patterns?
   - How does this affect library builds?

2. **I/O and Writers**
   - Why was explicit buffering introduced?
   - What's the performance impact of buffered vs unbuffered?
   - How do you migrate stdout/stderr code?
   - What is the new `Io.zig` module for?

3. **ArrayList Changes**
   - Why did ArrayList default to unmanaged?
   - When should you use managed vs unmanaged?
   - How do you migrate existing ArrayList code?
   - What are the allocator passing patterns?

4. **Migration Strategy**
   - Can you support both versions simultaneously?
   - What's the minimal migration path?
   - What's the recommended migration order?
   - How long does a typical migration take?

### Secondary Questions (Should Answer)

5. What formatting API changes occurred?
6. Which stdlib modules were reorganized?
7. What APIs were deprecated?
8. How did testing APIs change?
9. What import paths changed?
10. Are there performance implications in any changes?

---

## Research Phases

### Phase 1: Build System Migration Patterns (2-3 hours)

**Priority**: HIGHEST (affects every project)

#### Objectives
- Document all breaking changes in std.Build API
- Extract migration patterns from existing chapters
- Create comprehensive build.zig migration guide
- Identify common build configuration scenarios

#### Tasks

1. **Compare std.Build APIs**
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/Build.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/Build.zig`
   - Focus on:
     - `addExecutable()` signature changes
     - `addLibrary()` signature changes
     - `addTest()` signature changes
     - Module system changes
     - `b.createModule()` API

2. **Extract Patterns from Existing Chapters**
   - Review build.zig files in sections 8-13
   - Count `.root_module` usage patterns
   - Identify common build configurations:
     - Simple executable
     - Library + executable
     - Multi-module project
     - With build options
     - Test configuration
   - Document the transition pattern for each

3. **Create Migration Guide**
   - Before/after for each pattern
   - Step-by-step migration instructions
   - Common errors and fixes
   - Validation steps

4. **Analyze Reference Projects**
   - `/home/jack/workspace/zig_guide/reference_repos/tigerbeetle/build.zig`
   - `/home/jack/workspace/zig_guide/reference_repos/zls/build.zig`
   - `/home/jack/workspace/zig_guide/reference_repos/ghostty/build.zig`
   - Extract advanced patterns

#### Deliverables
- Build system migration patterns (5-6 examples)
- Common error messages and solutions
- Migration time estimates
- Validation checklist

#### Key Citations Needed
- `std.Build` API documentation (0.14.1 and 0.15.2)
- Build system changes from release notes
- Reference project build files

---

### Phase 2: I/O and Writer Migration (2-3 hours)

**Priority**: HIGH (affects all I/O code)

#### Objectives
- Document stdout/stderr relocation to std.fs.File
- Explain new explicit buffering model
- Show migration for common I/O patterns
- Explain performance implications

#### Tasks

1. **Compare I/O APIs**
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/io.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/fs/File.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/Io.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/fs/File.zig`
   - Document:
     - `std.io.getStdOut()` → `std.fs.File.stdout()` change
     - `file.writer()` → `file.writer(buffer)` change
     - New `.interface` accessor for writers
     - Buffered vs unbuffered patterns
     - `flush()` requirements

2. **Extract I/O Patterns from Chapter 5**
   - Read `/home/jack/workspace/zig_guide/sections/05_io_streams/content.md`
   - Identify all I/O code examples
   - Document migration for each pattern:
     - Simple stdout printing
     - File writing
     - Formatted output
     - Error output
     - Buffered vs unbuffered

3. **Document New Io.zig Module**
   - Purpose and use cases
   - New abstractions provided
   - When to use vs old patterns
   - Migration path from old I/O code

4. **Performance Analysis**
   - Buffered vs unbuffered performance
   - Buffer size considerations
   - When to flush

#### Deliverables
- I/O migration guide (4-5 examples)
- Buffering best practices
- Performance implications documentation
- stdout/stderr quick reference

#### Key Citations Needed
- `std.io` module documentation (0.14.1)
- `std.fs.File` documentation (both versions)
- `Io.zig` module documentation (0.15.2)
- Chapter 5 examples

---

### Phase 3: ArrayList and Container Migration (2-3 hours)

**Priority**: HIGH (common in most codebases)

#### Objectives
- Document ArrayList's managed→unmanaged default change
- Show allocator passing patterns
- Provide migration strategies
- Explain when to use managed vs unmanaged

#### Tasks

1. **Compare ArrayList APIs**
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/array_list.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/array_list.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/std.zig` (for exports)
   - Document:
     - Default behavior change (managed → unmanaged)
     - Method signature changes (allocator parameters added)
     - `init()` vs `initCapacity()` changes
     - `deinit()` parameter changes
     - Managed wrapper availability (`AlignedManaged`)

2. **Extract Container Patterns from Chapter 4**
   - Read `/home/jack/workspace/zig_guide/sections/04_collections_containers/content.md`
   - Identify all ArrayList usage examples
   - Document allocator passing patterns
   - Show `deinit()` migration
   - Explain ownership implications

3. **Develop Migration Strategies**
   - **Minimal change**: Use `AlignedManaged` wrapper
   - **Full migration**: Embrace unmanaged, pass allocators
   - **Mixed approach**: Case-by-case decisions
   - Pros/cons of each strategy
   - Migration decision tree

4. **Test Migration Patterns**
   - Create test examples for each strategy
   - Verify allocator management is correct
   - Check for memory leaks
   - Performance comparison

#### Deliverables
- ArrayList migration patterns (3-4 examples)
- Allocator passing best practices
- Migration decision tree
- Managed vs unmanaged comparison

#### Key Citations Needed
- `array_list.zig` source (both versions)
- Chapter 4 container examples
- Memory management patterns

---

### Phase 4: Formatting and Other stdlib Changes (1-2 hours)

**Priority**: MEDIUM (less common impact)

#### Objectives
- Document formatting API changes
- List module reorganizations
- Identify deprecated APIs
- Note import path changes

#### Tasks

1. **Format API Changes**
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/fmt.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/fmt.zig`
   - Document:
     - `FormatOptions` → `Options` rename
     - New `Case` enum
     - New `Number` structure
     - Behavior changes

2. **Module Reorganization**
   - Compare `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/std.zig`
   - Compare `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/std.zig`
   - List moved types:
     - `DoublyLinkedList` location
     - `SinglyLinkedList` location
     - `RingBuffer` removal
     - Other moved/removed types
   - Document new import paths

3. **Testing API Changes**
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/lib/std/testing.zig`
   - Read `/home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/testing.zig`
   - Note any breaking changes
   - Document new features

4. **Deprecation Survey**
   - Search for `@deprecated` in 0.15.2 stdlib
   - List all deprecated APIs
   - Provide replacement guidance

#### Deliverables
- Formatting migration notes
- Deprecated API list with replacements
- Import path change reference
- Minor breaking changes catalog

#### Key Citations Needed
- `fmt.zig` source (both versions)
- `std.zig` exports (both versions)
- Deprecation comments

---

### Phase 5: Reference Project Migration Patterns (2-3 hours)

**Priority**: MEDIUM-HIGH (provides real-world context)

#### Objectives
- Study how production codebases migrated
- Extract practical patterns
- Identify common pitfalls from real code
- Document best practices

#### Tasks

1. **Analyze TigerBeetle Migration**
   - Location: `/home/jack/workspace/zig_guide/reference_repos/tigerbeetle/`
   - Focus areas:
     - `build.zig` structure
     - I/O patterns in database code
     - Container usage patterns
     - Custom log handler migration
   - Search for:
     - `.root_module` usage
     - File I/O patterns
     - ArrayList usage
     - Scoped logging patterns
   - Extract 3-5 notable patterns

2. **Analyze ZLS Migration**
   - Location: `/home/jack/workspace/zig_guide/reference_repos/zls/`
   - Focus areas:
     - LSP server I/O patterns
     - Build runner integration
     - JSON parsing/formatting
     - Large codebase organization
   - Extract LSP-specific patterns

3. **Analyze Ghostty Migration**
   - Location: `/home/jack/workspace/zig_guide/reference_repos/ghostty/`
   - Focus areas:
     - Terminal I/O (heavy I/O usage)
     - macOS integration patterns
     - Application-level build
     - Platform-aware logging
   - Extract GUI/terminal patterns

4. **Analyze Bun Patterns** (if applicable)
   - Location: `/home/jack/workspace/zig_guide/reference_repos/bun/`
   - Focus on JavaScript runtime patterns
   - Extract high-performance I/O patterns

5. **Synthesize Findings**
   - Common patterns across projects
   - Project-specific approaches
   - Best practices
   - Pitfalls to avoid

#### Deliverables
- Real-world migration patterns (5-8 examples)
- Project-specific strategies
- Common pitfalls from production code
- Best practices synthesis

#### Key Citations Needed
- TigerBeetle source files (3-5 citations)
- ZLS source files (2-3 citations)
- Ghostty source files (2-3 citations)
- Other reference projects as applicable

---

### Phase 6: Create Migration Examples (3-4 hours)

**Priority**: HIGHEST (core deliverable)

#### Objectives
- Build 6 working before/after migration examples
- Each example compiles on both Zig versions
- Clear READMEs explain migration steps
- Cover most common migration scenarios

---

#### Example 1: Simple Executable Migration

**Purpose**: Show basic build.zig migration
**Directory**: `examples/01_build_simple/`
**Complexity**: Beginner
**Migration Time**: 5 minutes

**Files**:
```
01_build_simple/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig
└── README.md
```

**Key Changes**:
- `.root_source_file = b.path(...)` → `.root_module = b.createModule(.{ .root_source_file = b.path(...) })`
- Target and optimize passing moved into module

**Expected Lines**: ~30 total (15 per version)

**README Sections**:
- What changed and why
- Migration steps
- Build commands for both versions
- Expected output

---

#### Example 2: I/O Migration - stdout/stderr

**Purpose**: Show I/O API changes
**Directory**: `examples/02_io_stdout/`
**Complexity**: Beginner-Intermediate
**Migration Time**: 10-15 minutes

**Files**:
```
02_io_stdout/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig
└── README.md
```

**Key Changes**:
- `std.io.getStdOut()` → `std.fs.File.stdout()`
- `writer()` → `writer(&buffer)` or `writer(&.{})` for unbuffered
- `writer.print()` → `writer.interface.print()` for buffered
- Add `try writer.interface.flush()` for buffered

**Demonstrates**:
- Both buffered and unbuffered approaches
- When to use each
- stderr usage

**Expected Lines**: ~60 total (30 per version)

---

#### Example 3: ArrayList Migration

**Purpose**: Show container default change
**Directory**: `examples/03_arraylist/`
**Complexity**: Intermediate
**Migration Time**: 15-20 minutes

**Files**:
```
03_arraylist/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig (two variants)
└── README.md
```

**Key Changes**:
- `ArrayList(T).init(allocator)` stores allocator internally
- New `ArrayList(T)` needs allocator passed to each method
- `append(item)` → `append(allocator, item)`
- `deinit()` → `deinit(allocator)`

**Demonstrates**:
- Managed (old behavior) with `AlignedManaged`
- Unmanaged (new default) with explicit allocators
- Pros/cons of each approach

**Expected Lines**: ~80 total (40 per version)

---

#### Example 4: File I/O with Buffering

**Purpose**: Show buffered file writing
**Directory**: `examples/04_file_io/`
**Complexity**: Intermediate
**Migration Time**: 15-20 minutes

**Files**:
```
04_file_io/
├── 0.14.1/
│   ├── build.zig
│   └── src/main.zig
├── 0.15.2/
│   ├── build.zig
│   └── src/main.zig
└── README.md
```

**Key Changes**:
- File writer buffering
- Buffer size selection
- Flush requirements
- Error handling

**Demonstrates**:
- Reading and writing files
- Performance implications
- Buffer management
- Proper cleanup

**Expected Lines**: ~90 total (45 per version)

---

#### Example 5: Complete CLI Tool Migration

**Purpose**: End-to-end migration
**Directory**: `examples/05_cli_tool/`
**Complexity**: Intermediate-Advanced
**Migration Time**: 30-45 minutes

**Files**:
```
05_cli_tool/
├── 0.14.1/
│   ├── build.zig
│   └── src/
│       ├── main.zig
│       ├── config.zig
│       └── processor.zig
├── 0.15.2/
│   ├── build.zig
│   └── src/
│       ├── main.zig
│       ├── config.zig
│       └── processor.zig
└── README.md
```

**Key Changes**:
- Build system migration
- I/O migration (file + stdout)
- ArrayList migration
- Combined effect demonstration

**Demonstrates**:
- Real-world CLI tool structure
- Multiple migration points
- Coordinated changes
- Testing strategy

**Expected Lines**: ~150 total (75 per version)

---

#### Example 6: Library with Module System

**Purpose**: Library and module migration
**Directory**: `examples/06_library/`
**Complexity**: Advanced
**Migration Time**: 20-30 minutes

**Files**:
```
06_library/
├── 0.14.1/
│   ├── build.zig
│   ├── src/
│   │   └── lib.zig
│   └── examples/
│       └── usage.zig
├── 0.15.2/
│   ├── build.zig
│   ├── src/
│   │   └── lib.zig
│   └── examples/
│       └── usage.zig
└── README.md
```

**Key Changes**:
- Library build with modules
- Module exports
- Example executable using library
- Import patterns

**Demonstrates**:
- Creating a library
- Exposing modules
- Using library in executable
- Testing library

**Expected Lines**: ~100 total (50 per version)

---

#### Example Creation Workflow

For each example:

1. **Create Directory Structure**
   ```bash
   mkdir -p examples/XX_name/{0.14.1,0.15.2}/src
   ```

2. **Write 0.14.1 Version**
   - Write build.zig using old syntax
   - Write source code using old APIs
   - Test compilation with Zig 0.14.1
   - Verify functionality

3. **Write 0.15.2 Version**
   - Migrate build.zig to new syntax
   - Update source code to new APIs
   - Test compilation with Zig 0.15.2
   - Verify functionality

4. **Create README**
   - Explain what the example demonstrates
   - List all changes made
   - Provide migration steps
   - Include build/run commands
   - Show expected output

5. **Validate**
   - Both versions compile without warnings
   - Both versions produce same output
   - README is clear and complete
   - Code is well-commented

#### Deliverables
- 6 complete working examples
- Each with before/after versions
- Comprehensive READMEs
- Tested on both Zig versions

#### Key Citations Needed
- Chapters 4, 5, 8 for patterns
- stdlib documentation for both versions

---

### Phase 7: Document Common Pitfalls (1-2 hours)

**Priority**: HIGH (prevents migration errors)

#### Objectives
- Catalog common migration mistakes
- Provide clear solutions
- Use ❌/✅ format for clarity
- Cover errors from all breaking changes

#### Pitfall Categories

**1. Build System Errors**

- Missing `.root_module`
- Wrong `createModule()` usage
- Target/optimize in wrong place
- Module import errors
- Option configuration mistakes

**2. I/O Errors**

- Missing buffer parameter
- Forgetting `.interface` accessor
- Forgetting `flush()` call
- Wrong stdout/stderr import
- Buffering misconceptions

**3. ArrayList Errors**

- Missing allocator parameters
- Wrong `init()` call
- `deinit()` without allocator
- Mixing managed/unmanaged
- Allocator lifetime issues

**4. General Migration Errors**

- Partial migration (inconsistent state)
- Version-specific code not marked
- Missing version checks
- Broken cross-compilation
- Test failures

#### Format for Each Pitfall

```markdown
### ❌ Pitfall: [Name]

**Symptom**: [Error message or behavior]

**Cause**: [Why this happens]

```zig
// ❌ Incorrect
[broken code]
```

**Solution**: [How to fix]

```zig
// ✅ Correct
[fixed code]
```

**Prevention**: [How to avoid in future]
```

#### Tasks

1. **Collect Error Messages**
   - Compile examples with common mistakes
   - Record error messages
   - Note cryptic or confusing errors

2. **Create Pitfall Examples**
   - Write minimal reproduction
   - Show error output
   - Provide fix
   - Explain why

3. **Organize by Category**
   - Group related pitfalls
   - Order by severity/frequency
   - Cross-reference with examples

4. **Test All Pitfalls**
   - Verify broken code produces error
   - Verify fix resolves issue
   - Ensure explanations are clear

#### Deliverables
- 10-15 documented pitfalls
- Each with ❌ wrong and ✅ correct code
- Clear explanations
- Prevention strategies

#### Key Citations Needed
- Compiler error messages
- Reference project issues (if available)

---

### Phase 8: Create Migration Checklist (1 hour)

**Priority**: HIGH (makes chapter actionable)

#### Objectives
- Step-by-step migration procedure
- Validation at each step
- Rollback strategies
- Time estimates

#### Checklist Structure

```markdown
## Migration Checklist

### Pre-Migration (15-30 minutes)

- [ ] Backup your codebase (git commit or branch)
- [ ] Update Zig to target version (0.15.2)
- [ ] Review this migration guide completely
- [ ] Identify which breaking changes affect your code
- [ ] Estimate migration time for your project
- [ ] Plan migration order (suggest: build → I/O → containers)

### Phase 1: Build System (per project: 5-30 minutes)

- [ ] Update build.zig for each executable
  - [ ] Change `.root_source_file` to `.root_module = b.createModule(...)`
  - [ ] Move `target` and `optimize` into `createModule()`
  - [ ] Update test configuration
- [ ] Update library build.zig (if applicable)
- [ ] Test: `zig build` compiles without errors
- [ ] Test: `zig build test` passes
- [ ] Commit: "chore: migrate build.zig to 0.15.2"

### Phase 2: I/O Migration (per module: 10-45 minutes)

- [ ] Update stdout/stderr usage
  - [ ] Replace `std.io.getStdOut()` with `std.fs.File.stdout()`
  - [ ] Replace `std.io.getStdErr()` with `std.fs.File.stderr()`
- [ ] Update writer usage
  - [ ] Add buffer parameter: `writer(&buffer)` or `writer(&.{})`
  - [ ] Add `.interface` for buffered writers
  - [ ] Add `flush()` calls where needed
- [ ] Test: Output is correct
- [ ] Test: No buffering issues
- [ ] Commit: "chore: migrate I/O to 0.15.2 API"

### Phase 3: Container Migration (per module: 15-60 minutes)

- [ ] Review all ArrayList usage
- [ ] Choose strategy: keep managed or go unmanaged
- [ ] If keeping managed:
  - [ ] Use `AlignedManaged` wrapper
  - [ ] Minimal code changes
- [ ] If going unmanaged:
  - [ ] Add allocator parameter to all methods
  - [ ] Update `deinit()` calls
  - [ ] Verify allocator lifetime
- [ ] Test: All functionality works
- [ ] Test: No memory leaks (use allocator testing)
- [ ] Commit: "chore: migrate ArrayList to 0.15.2"

### Phase 4: Format and Minor Changes (per file: 5-15 minutes)

- [ ] Update format options if using custom formatting
- [ ] Fix any import path changes
- [ ] Replace deprecated APIs
- [ ] Test: Everything compiles
- [ ] Commit: "chore: migrate remaining 0.15.2 changes"

### Phase 5: Final Validation (30-60 minutes)

- [ ] Run full test suite
- [ ] Check for deprecation warnings
- [ ] Run in release mode: `zig build -Doptimize=ReleaseFast`
- [ ] Test cross-compilation targets (if applicable)
- [ ] Update CI configuration (if needed)
- [ ] Update documentation with version markers
- [ ] Final commit: "chore: complete migration to Zig 0.15.2"

### Rollback Plan

If migration fails or is incomplete:

- [ ] Revert to backup: `git reset --hard <commit>`
- [ ] Or: Keep work in branch, switch back to main
- [ ] Document blockers for future attempt
- [ ] Consider hybrid approach (support both versions)
```

#### Deliverables
- Complete actionable checklist
- Time estimates for each phase
- Rollback procedures
- Validation steps

---

### Phase 9: Write Content (4-5 hours)

**Priority**: HIGHEST (final deliverable)

#### Objectives
- Produce publication-ready content.md
- 1200-1500 lines target
- Follow required 7-section structure
- Integrate all research and examples
- 25+ citations

#### Content Structure

**Section 1: Overview (100-150 lines)**

- Purpose of migration guide
- Why these changes were made (philosophy)
- When to migrate (timing considerations)
- Migration effort estimation
- How to use this guide

**Section 2: Core Concepts (200-250 lines)**

- Build System Changes
  - `.root_module` requirement explained
  - Module creation patterns
  - Why this change improves things

- I/O and Writer Changes
  - New buffering model explained
  - stdout/stderr relocation rationale
  - `Io.zig` module purpose
  - Performance implications

- ArrayList Default Change
  - Managed → unmanaged philosophy
  - Allocator passing patterns
  - When to use each approach

- Other Notable Changes
  - Formatting API improvements
  - Module reorganization
  - Deprecations with replacements

**Section 3: Migration Strategies (150-200 lines)**

- All-at-Once Migration
  - When appropriate
  - Step-by-step guide
  - Expected timeframe
  - Pros and cons

- Gradual Migration
  - Compatibility patterns
  - Version-specific code
  - Migration phases
  - Pros and cons

- Library Maintainer Strategy
  - Supporting both versions
  - Feature flags approach
  - Version detection
  - Deprecation timeline

**Section 4: Code Examples (400-500 lines)**

- Example 1: Build.zig Migration
  - Before code
  - After code
  - Explanation
  - Common errors

- Example 2: I/O Migration
  - Before code
  - After code
  - Buffering explained
  - Performance notes

- Example 3: ArrayList Migration
  - Before code
  - After code (both strategies)
  - Allocator management
  - Decision criteria

- Example 4: File I/O
  - Before code
  - After code
  - Buffer management
  - Best practices

- Example 5: CLI Tool
  - Before code
  - After code
  - End-to-end migration
  - Testing approach

- Example 6: Library
  - Before code
  - After code
  - Module exports
  - Usage patterns

**Section 5: Common Pitfalls (200-250 lines)**

- 10-15 pitfalls with ❌/✅ examples
- Organized by category
- Error messages included
- Prevention strategies

**Section 6: Migration Checklist (100-150 lines)**

- Full checklist from Phase 8
- Time estimates
- Validation steps
- Rollback procedures

**Section 7: In Practice (100-150 lines)**

- TigerBeetle migration patterns
  - Build system approach
  - I/O patterns
  - Custom logger migration

- ZLS migration approach
  - LSP-specific challenges
  - Build runner integration

- Ghostty migration experience
  - Terminal I/O migration
  - Platform-aware code

- Community feedback
  - Common questions
  - Migration timelines
  - Success stories

**Section 8: Summary (50-75 lines)**

- Key takeaways
- Migration decision tree
- Resources for help
- Future version compatibility

**Section 9: References (30-50 lines)**

- 25+ numbered citations
- Stdlib sources
- Chapter cross-references
- Reference project links

#### Writing Guidelines

- Use neutral, professional tone (style_guide.md)
- Active voice preferred
- No contractions
- Clear version markers (🕐 0.14.x / ✅ 0.15+)
- Code blocks properly formatted
- Cross-references to other chapters
- Footnoted citations throughout

#### Deliverables
- content.md (1200-1500 lines)
- All sections complete
- All examples integrated
- All citations included
- Proofread and validated

---

### Phase 10: Testing and Validation (2-3 hours)

**Priority**: HIGH (ensures quality)

#### Objectives
- Verify all code compiles
- Validate all examples work
- Check all citations
- Proofread content
- Run validation checklist

#### Tasks

1. **Code Validation**
   ```bash
   # Test all 0.14.1 examples
   cd examples/01_build_simple/0.14.1
   /home/jack/workspace/zig_guide/zig_versions/zig-0.14.1/zig build

   # Test all 0.15.2 examples
   cd examples/01_build_simple/0.15.2
   /home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/zig build

   # Repeat for all 6 examples
   ```

2. **Functional Testing**
   - Run each example
   - Verify output is correct
   - Check both versions produce same result
   - Test error cases

3. **Citation Validation**
   - Check all footnotes have targets
   - Verify file paths exist
   - Test cross-references
   - Number citations correctly

4. **Content Review**
   - Proofread all sections
   - Check code formatting
   - Verify version markers
   - Validate line counts
   - Run spell check

5. **Style Guide Compliance**
   - Review against style_guide.md
   - Check tone and voice
   - Verify technical accuracy
   - Validate formatting

6. **Cross-Chapter Integration**
   - Verify references to Chapters 4, 5, 8, 9, 10, 12
   - Check consistency with earlier chapters
   - Validate version marker usage

7. **Final Checklist**
   - [ ] All 6 examples compile on both versions
   - [ ] All examples produce correct output
   - [ ] 25+ citations properly formatted
   - [ ] Content is 1200-1500 lines
   - [ ] All required sections present
   - [ ] No typos or grammar errors
   - [ ] Version markers correct
   - [ ] Code blocks properly formatted
   - [ ] No speculative statements
   - [ ] All cross-references work

#### Deliverables
- Validated examples (all passing)
- Proofread content
- Citation index
- Validation report

---

## Timeline and Milestones

### Week 1: Research and Planning (8-12 hours)

**Day 1-2: Core Research**
- ✅ Phase 1: Build System (2-3h)
- ✅ Phase 2: I/O Migration (2-3h)
- ✅ Phase 3: ArrayList Migration (2-3h)
- ✅ Phase 4: Other Changes (1-2h)

**Day 3: Reference Analysis**
- ✅ Phase 5: Reference Projects (2-3h)

### Week 2: Example Creation (6-8 hours)

**Day 4-5: Examples**
- ✅ Phase 6: Create 6 Examples (3-4h)
- ✅ Phase 7: Document Pitfalls (1-2h)
- ✅ Phase 8: Create Checklist (1h)

### Week 3: Writing (4-5 hours)

**Day 6-7: Content**
- ✅ Phase 9: Write Content (4-5h)

### Week 4: Validation (2-3 hours)

**Day 8: Testing**
- ✅ Phase 10: Testing & Validation (2-3h)

**Total Estimated Time**: 20-28 hours over 8 working days

---

## Deliverables Checklist

### Planning Documents

- [x] research_plan.md (this document)
- [ ] research_notes.md (800-1000 lines with 25+ citations)
- [ ] examples_summary.md (specifications for 6 examples)
- [ ] content_outline.md (detailed structure with line estimates)

### Examples

- [ ] Example 1: Simple Build Migration (~30 lines)
- [ ] Example 2: I/O stdout/stderr (~60 lines)
- [ ] Example 3: ArrayList Migration (~80 lines)
- [ ] Example 4: File I/O with Buffering (~90 lines)
- [ ] Example 5: Complete CLI Tool (~150 lines)
- [ ] Example 6: Library with Modules (~100 lines)

### Final Content

- [ ] content.md (1200-1500 lines, publication-ready)
- [ ] All sections complete
- [ ] 25+ citations
- [ ] 10+ pitfalls documented
- [ ] Migration checklist included
- [ ] Proofread and validated

---

## Risk Mitigation

### Identified Risks

1. **Version Testing Complexity**
   - **Risk**: Difficult to test both versions simultaneously
   - **Impact**: Medium
   - **Mitigation**: Clear directory structure, separate builds, automated scripts

2. **Incomplete Reference History**
   - **Risk**: Reference projects may not have clear migration commits
   - **Impact**: Low-Medium
   - **Mitigation**: Focus on current state, infer patterns, note best practices

3. **Subtle API Differences**
   - **Risk**: Easy to miss minor breaking changes
   - **Impact**: Medium
   - **Mitigation**: Thorough stdlib comparison, test everything, multiple validation passes

4. **Example Complexity Balance**
   - **Risk**: Examples too simple (not useful) or too complex (overwhelming)
   - **Impact**: Medium
   - **Mitigation**: Progressive complexity, real-world relevance, clear explanations

5. **Migration Strategy Disagreement**
   - **Risk**: Multiple valid approaches, hard to recommend one
   - **Impact**: Low
   - **Mitigation**: Present all strategies with pros/cons, clear decision tree

6. **Keeping Content Current**
   - **Risk**: Zig continues evolving, content may date quickly
   - **Impact**: Low (guide covers 0.14-0.15 specifically)
   - **Mitigation**: Clear version scope, prepare for future updates

---

## Quality Assurance

### Code Quality Standards

- All examples must compile without warnings
- All examples must produce correct output
- Code should be idiomatic for each version
- No hardcoded paths or system dependencies
- READMEs must be complete and accurate

### Content Quality Standards

- No speculative statements
- All claims cited from authoritative sources
- Clear, neutral technical prose
- Active voice preferred
- Consistent terminology
- Proper version markers throughout

### Citation Standards

- 25+ total citations minimum
- Mix of stdlib sources, chapters, and reference projects
- Deep links to specific files/lines where possible
- Footnote format per style_guide.md
- References section complete

### Review Criteria

- Technical accuracy verified
- Style guide compliance confirmed
- All examples tested
- Proofread for typos/grammar
- Cross-references validated
- Line count targets met
- Integration with other chapters checked

---

## Integration Points

### Chapter Cross-References

**Chapter 4 (Collections & Containers)**
- ArrayList patterns
- Managed vs unmanaged context
- Memory ownership

**Chapter 5 (I/O, Streams & Formatting)**
- Writer/Reader migration
- Buffering patterns
- stdout/stderr usage

**Chapter 8 (Build System)**
- build.zig structure
- Module system
- Build options

**Chapter 9 (Packages & Dependencies)**
- Module imports
- Package integration
- Dependency management

**Chapter 10 (Project Layout & CI)**
- Project organization
- CI configuration
- Cross-compilation

**Chapter 12 (Testing, Benchmarking & Profiling)**
- Test migration
- Testing strategy
- Validation approaches

### Version Marker Strategy

Throughout all chapters:
- **🕐 0.14.x**: Legacy pattern (still valid in 0.14.x)
- **✅ 0.15+**: Current best practice (0.15.x)
- Side-by-side comparisons for major changes
- Migration guidance in Chapter 14

---

## Appendix: File Locations

### Zig Versions

```
/home/jack/workspace/zig_guide/zig_versions/
├── zig-0.14.0/
├── zig-0.14.1/
├── zig-0.15.1/
└── zig-0.15.2/
```

### Reference Projects

```
/home/jack/workspace/zig_guide/reference_repos/
├── tigerbeetle/
├── ghostty/
├── bun/
├── zls/
├── mach/
├── ziglings/
└── awesome-zig/
```

### Existing Chapters

```
/home/jack/workspace/zig_guide/sections/
├── 04_collections_containers/content.md
├── 05_io_streams/content.md
├── 08_build_system/content.md
├── 09_packages_dependencies/content.md
├── 10_project_layout_ci/content.md
├── 12_testing_benchmarking/content.md
└── 13_logging_diagnostics/content.md
```

### Key stdlib Files

**0.14.1**:
- `lib/std/Build.zig`
- `lib/std/io.zig`
- `lib/std/fs/File.zig`
- `lib/std/array_list.zig`
- `lib/std/fmt.zig`
- `lib/std/testing.zig`
- `lib/std/std.zig`

**0.15.2**:
- `lib/std/Build.zig`
- `lib/std/Io.zig` (new)
- `lib/std/fs/File.zig`
- `lib/std/array_list.zig`
- `lib/std/fmt.zig`
- `lib/std/testing.zig`
- `lib/std/std.zig`

---

## Notes and Observations

### Breaking Change Philosophy

The 0.15.x releases focused on:
1. **Explicitness**: Making implicit behavior explicit (buffering, allocators)
2. **Safety**: Reducing accidental misuse through API design
3. **Performance**: Enabling better optimization through clearer contracts
4. **Consistency**: Aligning APIs across the stdlib

### Common Migration Patterns Observed

1. Most projects can migrate incrementally
2. Build system is always first step
3. I/O migration most visible to users
4. ArrayList migration most time-consuming
5. Testing catches most issues

### Recommended Migration Order

1. Build system (required first)
2. I/O and writers (high visibility)
3. Containers (widespread but isolated)
4. Minor changes (low risk)
5. Full validation (comprehensive)

---

**Document Status**: Complete and ready for execution
**Next Phase**: Begin Phase 1 - Build System Migration Patterns
**Estimated Completion**: 4-5 working days from start
