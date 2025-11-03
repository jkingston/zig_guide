# Research Plan: Collections & Containers (Chapter 4)

**Research Date:** 2025-11-02
**Zig Versions Covered:** 0.14.0, 0.14.1, 0.15.1, 0.15.2
**Researcher:** Claude (Sonnet 4.5)
**Status:** Planning Phase

---

## 1. Chapter Overview & Objectives

### Primary Objective
Contrast managed and unmanaged container types and their ownership boundaries, building on the allocator foundations from Chapter 3.

### Key Questions to Answer
1. What is the difference between managed and unmanaged container types?
2. Who is responsible for freeing memory in each pattern?
3. When should developers choose one pattern over another?
4. What are common migration patterns between managed and unmanaged containers?
5. How do version differences (0.14.x vs 0.15+) affect container usage?
6. What are the ownership and lifetime semantics for each container type?

---

## 2. Core Topics to Research

### 2.1 Managed vs Unmanaged Containers

**Research Areas:**
- Definition and distinction between managed and unmanaged types
- Standard library container taxonomy:
  - `ArrayList` vs `ArrayListUnmanaged`
  - `HashMap` / `ArrayHashMap` vs unmanaged variants
  - `PriorityQueue` variants
  - `StringHashMap` patterns
  - Other common collections
- Memory layout and storage differences
- API differences (stored allocator vs passed allocator)
- Performance implications of each approach

**Expected Sources:**
- Zig Standard Library documentation (`std.ArrayList`, `std.HashMap`, etc.)
- Official language reference on container types
- TigerBeetle codebase (known for unmanaged patterns)
- Ghostty, Bun, ZLS for real-world usage patterns

**Research Questions:**
- When did Zig shift toward unmanaged containers? (Version history)
- What was the rationale behind this design decision?
- How do major projects (TigerBeetle, Ghostty) use these patterns?

---

### 2.2 Ownership Transfer and Borrowing

**Research Areas:**
- Container ownership semantics
- Transferring ownership of container contents
- Borrowing patterns with containers
- Slice vs owned collection trade-offs
- Iterator ownership semantics
- Return value ownership for container elements

**Expected Sources:**
- TigerBeetle TIGER_STYLE.md (ownership conventions)
- Ghostty codebase (ownership patterns in config handling)
- ZLS (language server container usage)
- Community guides on ownership idioms

**Research Questions:**
- How do you safely transfer ownership of a container?
- What are the patterns for borrowed vs owned container access?
- How do iterators interact with ownership semantics?
- What documentation conventions signal ownership transfer?

---

### 2.3 Deinit Responsibilities

**Research Areas:**
- When and how to call `deinit()` on containers
- Nested container cleanup patterns
- Containers of containers (ownership cascades)
- Error-path cleanup for containers (`errdefer`)
- Arena allocator patterns with containers (bulk cleanup)
- Manual vs automatic cleanup strategies

**Expected Sources:**
- Standard library container source code
- TigerBeetle manifest.zig, state_machine.zig (nested cleanup patterns)
- Bun allocators.zig (container management patterns)
- Community resources on defer/errdefer with containers

**Research Questions:**
- What happens if you forget to call `deinit()`?
- How do you clean up nested containers efficiently?
- When can you skip individual `deinit()` calls (arena pattern)?
- What are the error-path cleanup patterns for container initialization?

---

### 2.4 Container Selection Guidance

**Research Areas:**
- Performance characteristics of each container type
  - `ArrayList` vs fixed arrays vs slices
  - `HashMap` vs `ArrayHashMap` trade-offs
  - `StringHashMap` vs custom string handling
  - `PriorityQueue` use cases
- Memory layout and cache behavior
- Container initialization patterns
- Growth strategies and capacity management
- Common usage patterns in real codebases

**Expected Sources:**
- Zig Standard Library documentation
- TigerBeetle (performance-critical container usage)
- Bun (JavaScript runtime performance patterns)
- Mach (game engine container patterns)
- Community guides on container selection

**Research Questions:**
- When should you use `ArrayList` vs a fixed-size array?
- What are the trade-offs between `HashMap` variants?
- How do you choose appropriate initial capacities?
- What are the performance implications of different container types?

---

## 3. Research Methodology

### Phase 1: Official Documentation (Priority 1)
- [ ] Read Zig 0.15.2 standard library documentation for container types
- [ ] Read Zig 0.14.1 standard library documentation for comparison
- [ ] Review release notes (0.14.0, 0.14.1, 0.15.1, 0.15.2) for container changes
- [ ] Examine standard library source code:
  - `std/array_list.zig`
  - `std/hash_map.zig`
  - `std/priority_queue.zig`
  - `std/array_hash_map.zig`

**Target Deliverables:**
- API surface documentation
- Version differences catalog
- Memory layout understanding
- Initialization and cleanup patterns

---

### Phase 2: Exemplar Project Analysis (Priority 1)

#### TigerBeetle (Correctness-First Design)
**Files to Examine:**
- Container usage patterns throughout codebase
- Unmanaged container preferences
- Ownership and cleanup patterns
- TIGER_STYLE.md conventions

**Research Questions:**
- Why does TigerBeetle prefer unmanaged containers?
- What are the ownership patterns for nested containers?
- How do they handle container cleanup in error paths?

#### Ghostty (Terminal Emulator)
**Files to Examine:**
- Config.zig (configuration container patterns)
- Container usage in rendering pipelines
- Memory management for buffer collections

**Research Questions:**
- How does Ghostty manage collections of terminal buffers?
- What container types are used for configuration data?

#### Bun (JavaScript Runtime)
**Files to Examine:**
- allocators.zig (custom container patterns)
- Container usage in high-performance paths
- String handling and container patterns

**Research Questions:**
- How does Bun optimize container usage for performance?
- What custom container patterns exist?

#### ZLS (Language Server)
**Files to Examine:**
- Document management containers
- Symbol table container patterns
- Completion list management

**Research Questions:**
- How does ZLS manage collections of code symbols?
- What container patterns support incremental compilation?

#### Mach Engine (Game/Multimedia)
**Files to Examine:**
- Entity-component-system container patterns
- Rendering pipeline collection management

**Research Questions:**
- What container patterns support game entity management?
- How are collections optimized for frame-rate performance?

**Target Deliverables:**
- 20+ deep GitHub links to real-world container usage
- Ownership pattern examples from production code
- Performance-critical container usage patterns
- Common idioms across projects

---

### Phase 3: Community Resources (Priority 2)
- [ ] zig.guide - containers and collections section
- [ ] ziglearn.org - data structure patterns
- [ ] Zig by Example - container examples
- [ ] Introduction to Zig book (pedropark99) - container chapters
- [ ] Community discussions on Ziggit about container patterns
- [ ] Stack Overflow questions on Zig container usage

**Target Deliverables:**
- Common beginner mistakes
- Best practice patterns from community
- Migration guidance between versions

---

### Phase 4: Code Example Development (Priority 1)

**Required Examples (4-6 runnable):**

1. **Managed vs Unmanaged ArrayList Comparison**
   - Side-by-side comparison showing API differences
   - Ownership and cleanup patterns
   - When to use each variant

2. **HashMap Ownership Patterns**
   - Storing owned data in HashMap
   - Borrowing patterns for hash map access
   - Cleanup of hash map contents

3. **Nested Container Cleanup**
   - ArrayList of ArrayLists
   - HashMap containing containers
   - Error-path cleanup with errdefer

4. **Arena Pattern with Containers**
   - Using arena allocator for bulk container cleanup
   - Request-scoped container collections
   - Performance benefits demonstration

5. **Container Initialization Patterns**
   - Different ways to initialize containers
   - Capacity pre-allocation strategies
   - In-place initialization (TigerBeetle style)

6. **Migration Example (0.14.x to 0.15+)**
   - Converting managed containers to unmanaged
   - API migration patterns
   - Why the change improves code clarity

**Requirements for Each Example:**
- Must compile and run under specified Zig version(s)
- Include necessary imports and minimal setup
- Demonstrate output or behavior
- Include inline comments only when necessary
- Show proper error handling
- Demonstrate cleanup patterns

---

## 4. Version-Specific Research

### 0.14.x Baseline
- [ ] Document managed container APIs
- [ ] Identify deprecated patterns
- [ ] Record standard initialization patterns

### 0.15+ Changes
- [ ] Document shift toward unmanaged containers
- [ ] Identify breaking changes in container APIs
- [ ] Migration guidance for each container type
- [ ] New container features or patterns

### Cross-Version Patterns
- [ ] What works identically across all versions?
- [ ] What requires version markers?
- [ ] What are the recommended migration paths?

---

## 5. Common Pitfalls Research

**Target: Document 4-5 Common Mistakes**

1. **Forgetting to deinit() containers**
   - What happens?
   - How to detect?
   - Prevention patterns

2. **Freeing container contents incorrectly**
   - Nested container cleanup mistakes
   - Mixing allocators
   - Partial cleanup on errors

3. **Using wrong container variant**
   - Managed when unmanaged is better
   - Performance implications
   - API confusion

4. **Ownership confusion with container elements**
   - Who owns returned elements?
   - Slice vs owned data
   - Iterator invalidation

5. **Capacity and performance issues**
   - Not pre-allocating capacity
   - Inefficient growth patterns
   - Memory waste from oversizing

---

## 6. Validation Criteria

### Source Quality Standards
- [ ] All factual claims have authoritative citations
- [ ] Citations follow source hierarchy (official docs → GitHub → community)
- [ ] 20+ deep GitHub links to exemplar projects
- [ ] No speculative statements without attribution

### Code Quality Standards
- [ ] All examples compile under stated Zig versions
- [ ] All examples are runnable without modifications
- [ ] Examples demonstrate best practices
- [ ] Error handling is proper and idiomatic
- [ ] Cleanup patterns are correct

### Content Quality Standards
- [ ] Clear distinction between managed and unmanaged patterns
- [ ] Ownership semantics are explicit
- [ ] Deinit responsibilities are clearly documented
- [ ] Selection guidance is practical and actionable
- [ ] Real-world examples from production code

---

## 7. Expected Deliverables

### Research Notes Document (`research_notes.md`)

**Structure:**
1. **Container Type Taxonomy**
   - Managed container patterns
   - Unmanaged container patterns
   - Version differences

2. **Ownership Semantics**
   - Ownership transfer patterns
   - Borrowing patterns
   - Documentation conventions

3. **Deinit Patterns**
   - Simple container cleanup
   - Nested container cleanup
   - Error-path cleanup
   - Arena patterns

4. **Container Selection Guide**
   - Decision matrix
   - Performance characteristics
   - Usage patterns by container type

5. **Runnable Code Examples**
   - 4-6 comprehensive examples
   - Each with explanation and source attribution

6. **Exemplar Project Analysis**
   - 20+ deep GitHub links
   - Pattern analysis from each project
   - Common idioms identified

7. **Version Migration Guide**
   - 0.14.x patterns
   - 0.15+ patterns
   - Migration strategies

8. **Common Pitfalls**
   - 4-5 documented mistakes
   - Detection and prevention strategies

9. **Sources & References**
   - Numbered list of all citations
   - Organized by category

### Content Document (`content.md`)
Based on research notes, following the required chapter structure from `prompt.md`:
- Overview
- Core Concepts
- Code Examples
- Common Pitfalls
- In Practice
- Summary
- References

---

## 8. Research Timeline Estimate

| Phase | Estimated Effort | Priority |
|-------|-----------------|----------|
| Official Documentation Review | 2-3 hours | Critical |
| Exemplar Project Analysis | 3-4 hours | Critical |
| Community Resource Review | 1-2 hours | High |
| Code Example Development | 2-3 hours | Critical |
| Research Notes Documentation | 1-2 hours | Critical |
| Validation & Quality Check | 1 hour | Critical |
| **Total** | **10-15 hours** | - |

---

## 9. Success Metrics

- [ ] **Completeness**: All key topics from prompt.md are covered
- [ ] **Depth**: 20+ deep GitHub links to exemplar projects
- [ ] **Examples**: 4-6 runnable code examples with explanations
- [ ] **Pitfalls**: 4-5 common mistakes documented with solutions
- [ ] **Citations**: All factual claims have authoritative sources
- [ ] **Clarity**: Clear distinction between managed and unmanaged patterns
- [ ] **Actionability**: Practical guidance for container selection
- [ ] **Version Awareness**: Clear version markers for version-specific content

---

## 10. Open Questions for User Clarification

**None at this stage.** The prompt.md and style_guide.md provide clear requirements. If ambiguities arise during research, will document them for clarification.

---

## 11. Research Sources Catalog

### Official Documentation
- Zig 0.15.2 Language Reference
- Zig 0.15.2 Standard Library Reference
- Zig 0.14.1 Language Reference
- Zig 0.14.1 Standard Library Reference
- Release notes: 0.14.0, 0.14.1, 0.15.1, 0.15.2

### GitHub Repositories (Exemplars)
- ziglang/zig (standard library source)
- tigerbeetle/tigerbeetle
- ghostty-org/ghostty
- oven-sh/bun
- hexops/mach
- zigtools/zls

### Community Resources
- zig.guide
- ziglearn.org
- zig-by-example.com
- pedropark99.github.io/zig-book
- ziggit.dev discussions

---

## 12. Research Approach Summary

This research plan follows the same successful methodology used in Chapter 3 (Memory & Allocators):

1. **Start with official sources** to establish authoritative baseline
2. **Analyze exemplar projects** for real-world patterns and deep links
3. **Supplement with community resources** for common patterns and pitfalls
4. **Develop runnable examples** that demonstrate key concepts
5. **Document everything** with proper citations and version markers
6. **Validate** against quality standards before finalizing

The plan ensures comprehensive coverage of managed vs unmanaged container patterns, ownership semantics, cleanup responsibilities, and practical selection guidance—all building directly on the allocator foundations from Chapter 3.

---

**Status**: Research plan complete, ready to begin Phase 1 (Official Documentation Review)
**Next Step**: Execute research phases and document findings in `research_notes.md`
