# Research Plan: Error Handling & Resource Cleanup (Chapter 6)

**Research Date:** 2025-11-03
**Zig Versions Covered:** 0.14.0, 0.14.1, 0.15.1, 0.15.2
**Researcher:** Claude (Sonnet 4.5)
**Status:** Planning Phase

---

## 1. Chapter Overview & Objectives

### Primary Objective
Describe Zig's error philosophy and its practical pairing with resource cleanup, demonstrating how error sets, error unions, and deterministic cleanup strategies (defer/errdefer) work together to create safe, maintainable error handling patterns.

### Key Questions to Answer
1. What is Zig's error philosophy and how does it differ from exceptions?
2. How do error sets and error unions provide type safety for error handling?
3. What are the patterns for error propagation using `try`, `catch`, and explicit returns?
4. How do `defer` and `errdefer` ensure deterministic resource cleanup?
5. What are the best practices for testing error paths and recovery scenarios?
6. How do allocators interact with error handling and cleanup?
7. What are common error handling anti-patterns and pitfalls?
8. How do version differences (0.14.x vs 0.15+) affect error handling patterns?

---

## 2. Core Topics to Research

### 2.1 Error Sets and Error Unions

**Research Areas:**
- Error set declaration and composition
- Error union types (`!T` syntax)
- Inferred error sets
- Error set inference vs explicit declaration
- Merging error sets (union of errors)
- Error payload vs error identity
- Error return trace mechanics
- Standard library error conventions

**Expected Sources:**
- Zig Language Reference (0.14.1 and 0.15.2)
- Standard Library documentation for error types
- TigerBeetle TIGER_STYLE.md (error conventions)
- Ghostty error handling patterns
- Bun error propagation in performance-critical paths
- ZLS error handling in language server operations

**Research Questions:**
- When should error sets be explicit vs inferred?
- How do you compose error sets from multiple functions?
- What are the trade-offs between specific and generic error sets?
- How does error return trace information work?
- What is the standard library convention for error naming?

---

### 2.2 Try, Catch, and Error Propagation

**Research Areas:**
- `try` keyword mechanics and sugar
- `catch` syntax and patterns
- Error propagation strategies
- Explicit error handling vs propagation
- Error payload capture in catch blocks
- Error switching and exhaustive handling
- Conditional error handling patterns
- Error recovery strategies

**Expected Sources:**
- Zig Language Reference
- TigerBeetle error propagation patterns
- Ghostty configuration error handling
- Bun parser error recovery
- ZLS incremental parsing error handling
- Community resources on idiomatic error handling

**Research Questions:**
- When should you use `try` vs explicit `catch`?
- How do you handle errors that need context or wrapping?
- What are the patterns for error recovery vs fail-fast?
- How do you maintain error context across function boundaries?
- What are idiomatic patterns for error logging?

---

### 2.3 Cleanup with defer and errdefer

**Research Areas:**
- `defer` semantics and execution order (LIFO)
- `errdefer` mechanics and error-path cleanup
- Interaction between defer and errdefer
- Scope-based resource management (RAII-like patterns)
- Cleanup ordering for dependent resources
- Partial initialization cleanup patterns
- Allocator cleanup patterns with defer/errdefer
- Common pitfalls with deferred cleanup

**Expected Sources:**
- Zig Language Reference on defer and errdefer
- Standard Library cleanup patterns
- TigerBeetle resource management patterns
- Ghostty resource lifecycle management
- Bun stream and buffer cleanup patterns
- Mach engine resource cleanup

**Research Questions:**
- How does defer execution order work in complex scopes?
- When should you use errdefer vs defer?
- How do you handle cleanup for partially constructed objects?
- What are the patterns for cleanup in complex control flow?
- How do defer/errdefer interact with early returns?
- What are common mistakes with deferred cleanup?

---

### 2.4 Testing Error Scenarios

**Research Areas:**
- Testing error paths and recovery
- Failing allocators for testing
- Error simulation patterns
- Exhaustive error testing strategies
- Test allocator patterns
- Mocking error conditions
- Fuzzing error paths
- Error handling test coverage

**Expected Sources:**
- Zig Standard Library testing utilities
- `std.testing.FailingAllocator` documentation
- TigerBeetle testing patterns
- ZLS error testing strategies
- Community testing best practices
- Zig test framework documentation

**Research Questions:**
- How do you systematically test all error paths?
- What tools exist for simulating error conditions?
- How do you test cleanup on error paths?
- What are patterns for testing partial failure scenarios?
- How do you verify error messages and context?

---

### 2.5 Error Handling and Allocators

**Research Areas:**
- Out-of-memory error handling
- Allocation failure recovery strategies
- Arena allocator error semantics
- Failing allocator testing patterns
- Error cleanup with allocated resources
- Allocator error propagation patterns
- Memory leak prevention on error paths

**Expected Sources:**
- Chapter 3 (Memory & Allocators) cross-reference
- Standard Library allocator interfaces
- TigerBeetle allocation error handling
- Ghostty memory failure patterns
- Bun allocator error strategies

**Research Questions:**
- How do you handle out-of-memory errors gracefully?
- What are patterns for recovering from allocation failures?
- How do arena allocators affect error handling?
- How do you ensure no leaks on error paths?
- What are the testing patterns for allocation failures?

---

## 3. Research Methodology

### Phase 1: Official Documentation (Priority 1)
- [ ] Read Zig 0.15.2 Language Reference - Error handling section
- [ ] Read Zig 0.14.1 Language Reference - Error handling section
- [ ] Review release notes (0.14.0, 0.14.1, 0.15.1, 0.15.2) for error handling changes
- [ ] Examine standard library source code:
  - Error set definitions across stdlib
  - Common error handling patterns
  - Testing utilities (`std.testing.FailingAllocator`)
  - Error return trace implementation
- [ ] Document error conventions in standard library

**Target Deliverables:**
- Error set and error union semantics
- Try/catch/defer/errdefer mechanics
- Version differences catalog
- Standard library error conventions
- Testing utilities documentation

---

### Phase 2: Exemplar Project Analysis (Priority 1)

#### TigerBeetle (Correctness-First Design)
**Files to Examine:**
- TIGER_STYLE.md (error handling conventions)
- Error propagation patterns in critical paths
- Resource cleanup patterns
- Testing strategies for error paths
- Allocation failure handling

**Research Questions:**
- What are TigerBeetle's error handling conventions?
- How do they ensure correctness in error paths?
- What patterns exist for testing error scenarios?
- How do they handle partial initialization failures?

#### Ghostty (Terminal Emulator)
**Files to Examine:**
- Configuration parsing error handling
- Terminal state error recovery
- Resource cleanup on errors
- Error reporting to users

**Research Questions:**
- How does Ghostty recover from configuration errors?
- What are the patterns for user-facing error messages?
- How are terminal resources cleaned up on errors?

#### Bun (JavaScript Runtime)
**Files to Examine:**
- Parser error recovery patterns
- Performance-critical error handling
- Stream error propagation
- Resource cleanup in async operations

**Research Questions:**
- How does Bun handle errors in performance-critical paths?
- What are the patterns for parser error recovery?
- How does Bun manage error context?

#### ZLS (Language Server)
**Files to Examine:**
- Incremental parsing error handling
- Error recovery strategies
- Error diagnostics generation
- Resource management on error paths

**Research Questions:**
- How does ZLS recover from parsing errors?
- What patterns exist for maintaining state during errors?
- How are diagnostic errors generated and managed?

#### Mach Engine (Game/Multimedia)
**Files to Examine:**
- Graphics resource error handling
- Initialization failure recovery
- Frame-critical error handling
- Resource cleanup patterns

**Research Questions:**
- How does Mach handle graphics initialization errors?
- What are the patterns for resource cleanup in game loops?
- How does Mach balance error handling with performance?

**Target Deliverables:**
- 20+ deep GitHub links to real-world error handling patterns
- Resource cleanup examples from production code
- Error testing patterns from exemplar projects
- Common idioms across projects

---

### Phase 3: Community Resources (Priority 2)
- [ ] zig.guide - error handling section
- [ ] ziglearn.org - error handling patterns
- [ ] Zig by Example - error examples
- [ ] Introduction to Zig book (pedropark99) - error handling chapters
- [ ] Community discussions on Ziggit about error patterns
- [ ] Stack Overflow questions on Zig error handling
- [ ] Error handling blog posts and tutorials

**Target Deliverables:**
- Common beginner mistakes with error handling
- Best practice patterns from community
- Migration guidance for error handling between versions
- Real-world error handling war stories

---

### Phase 4: Code Example Development (Priority 1)

**Required Examples (4-6 runnable):**

1. **Error Sets and Error Unions Basics**
   - Declaring error sets
   - Error union types
   - Basic error propagation with try
   - Error payload capture with catch
   - Demonstrates fundamental error syntax

2. **Error Propagation Patterns**
   - Explicit error handling with catch
   - Error context and wrapping patterns
   - Error switching for different handling
   - Try vs catch trade-offs
   - Multi-function error propagation

3. **Resource Cleanup with defer/errdefer**
   - Basic defer usage (LIFO order)
   - errdefer for error-path cleanup
   - Partial initialization cleanup
   - File handle cleanup example
   - Memory cleanup with allocators

4. **Testing Error Paths**
   - Using FailingAllocator
   - Simulating error conditions
   - Testing cleanup on error paths
   - Verifying error propagation
   - Error path test coverage

5. **Allocator Error Handling**
   - Out-of-memory error handling
   - Arena allocator cleanup patterns
   - Partial allocation cleanup
   - Error recovery strategies
   - Cross-reference with Chapter 3

6. **Complex Error Scenarios**
   - Nested try blocks
   - Error recovery and retry logic
   - Multi-resource cleanup ordering
   - Error context propagation
   - Production-ready error handling

**Requirements for Each Example:**
- Must compile and run under specified Zig version(s)
- Include necessary imports and minimal setup
- Demonstrate output or behavior clearly
- Include inline comments only when necessary
- Show proper error handling and cleanup
- Demonstrate best practices from exemplar projects

---

## 4. Version-Specific Research

### 0.14.x Baseline
- [ ] Document error handling syntax in 0.14.x
- [ ] Identify any deprecated error patterns
- [ ] Record error return trace behavior
- [ ] Document standard library error conventions

### 0.15+ Changes
- [ ] Document error handling changes in 0.15+
- [ ] Identify breaking changes in error syntax or semantics
- [ ] Document error return trace improvements
- [ ] New error handling features or patterns

### Cross-Version Patterns
- [ ] What error handling works identically across all versions?
- [ ] What requires version markers?
- [ ] What are the recommended migration paths for error handling?
- [ ] How has error handling philosophy evolved?

---

## 5. Common Pitfalls Research

**Target: Document 4-5 Common Mistakes**

1. **Forgetting errdefer for resource cleanup**
   - What happens when error paths don't clean up?
   - Memory leaks on error paths
   - Resource leaks on error paths
   - Prevention patterns

2. **Incorrect defer/errdefer ordering**
   - LIFO execution order confusion
   - Dependencies between cleanup actions
   - Partial initialization pitfalls
   - Testing cleanup order

3. **Ignoring specific error cases**
   - Using `try` when specific handling is needed
   - Loss of error context
   - Poor error messages
   - When to use catch vs try

4. **Not testing error paths**
   - Untested error branches
   - Cleanup bugs in error paths
   - Missing error scenarios
   - Using FailingAllocator for testing

5. **Overly broad or narrow error sets**
   - When to use specific error sets
   - When to use inferred errors
   - Error set composition pitfalls
   - Balance between specificity and maintainability

---

## 6. Validation Criteria

### Source Quality Standards
- [ ] All factual claims have authoritative citations
- [ ] Citations follow source hierarchy (official docs → GitHub → community)
- [ ] 20+ deep GitHub links to exemplar projects
- [ ] No speculative statements without attribution
- [ ] Error handling philosophy grounded in official docs

### Code Quality Standards
- [ ] All examples compile under stated Zig versions
- [ ] All examples are runnable without modifications
- [ ] Examples demonstrate best practices
- [ ] Error handling is proper and idiomatic
- [ ] Cleanup patterns are correct and complete
- [ ] Examples include proper testing patterns

### Content Quality Standards
- [ ] Clear explanation of error sets and error unions
- [ ] Comprehensive coverage of try/catch/defer/errdefer
- [ ] Resource cleanup patterns are explicit and correct
- [ ] Testing error paths is thoroughly covered
- [ ] Allocator error handling builds on Chapter 3
- [ ] Real-world examples from production code
- [ ] Common pitfalls are clearly documented

---

## 7. Expected Deliverables

### Research Notes Document (`research_notes.md`)

**Structure:**
1. **Error Sets and Error Unions**
   - Error set declaration syntax
   - Error union types and semantics
   - Inferred vs explicit error sets
   - Version differences

2. **Error Propagation Mechanics**
   - Try, catch, and return semantics
   - Error context and wrapping
   - Error switching patterns
   - Propagation best practices

3. **Resource Cleanup Patterns**
   - defer and errdefer mechanics
   - LIFO execution order
   - Partial initialization cleanup
   - Complex cleanup scenarios

4. **Testing Error Paths**
   - FailingAllocator usage
   - Error simulation techniques
   - Test coverage for error paths
   - Production testing patterns

5. **Allocator Error Handling**
   - Out-of-memory handling
   - Cleanup with allocators
   - Arena patterns
   - Cross-reference to Chapter 3

6. **Runnable Code Examples**
   - 4-6 comprehensive examples
   - Each with explanation and source attribution
   - Covering all key topics

7. **Exemplar Project Analysis**
   - 20+ deep GitHub links
   - Pattern analysis from each project
   - Common idioms identified
   - Error handling conventions

8. **Version Migration Guide**
   - 0.14.x patterns
   - 0.15+ patterns
   - Migration strategies

9. **Common Pitfalls**
   - 4-5 documented mistakes
   - Detection and prevention strategies
   - Testing approaches

10. **Sources & References**
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
- [ ] **Clarity**: Clear explanation of error philosophy and mechanics
- [ ] **Actionability**: Practical guidance for error handling and cleanup
- [ ] **Testing**: Comprehensive coverage of error path testing
- [ ] **Version Awareness**: Clear version markers for version-specific content
- [ ] **Integration**: Proper connection to Chapter 3 (Memory & Allocators)

---

## 10. Open Questions for User Clarification

**None at this stage.** The prompt.md and style_guide.md provide clear requirements. If ambiguities arise during research, will document them for clarification.

---

## 11. Research Sources Catalog

### Official Documentation
- Zig 0.15.2 Language Reference - Error Handling
- Zig 0.15.2 Standard Library Reference
- Zig 0.14.1 Language Reference - Error Handling
- Zig 0.14.1 Standard Library Reference
- Release notes: 0.14.0, 0.14.1, 0.15.1, 0.15.2

### GitHub Repositories (Exemplars)
- ziglang/zig (standard library source, error handling implementation)
- tigerbeetle/tigerbeetle (TIGER_STYLE.md, error handling conventions)
- ghostty-org/ghostty (terminal emulator error handling)
- oven-sh/bun (runtime error handling, parser recovery)
- hexops/mach (game engine resource management)
- zigtools/zls (language server error recovery)

### Community Resources
- zig.guide (error handling section)
- ziglearn.org (error patterns)
- zig-by-example.com (error examples)
- pedropark99.github.io/zig-book (error handling chapters)
- ziggit.dev discussions (error handling threads)
- Stack Overflow (Zig error handling questions)

---

## 12. Research Approach Summary

This research plan follows the proven methodology used in previous chapters:

1. **Start with official sources** to establish authoritative baseline
2. **Analyze exemplar projects** for real-world patterns and deep links
3. **Supplement with community resources** for common patterns and pitfalls
4. **Develop runnable examples** that demonstrate key concepts
5. **Document everything** with proper citations and version markers
6. **Validate** against quality standards before finalizing

The plan ensures comprehensive coverage of error sets, error unions, try/catch mechanics, defer/errdefer cleanup patterns, and error testing strategies—all grounded in Zig's error handling philosophy and practical production usage.

### Key Differentiators for This Chapter

- **Philosophy Focus**: Understanding Zig's explicit error handling philosophy vs exceptions
- **Cleanup Integration**: Deep dive into defer/errdefer mechanics and resource safety
- **Testing Emphasis**: Systematic coverage of error path testing with FailingAllocator
- **Allocator Connection**: Building on Chapter 3's allocator patterns for error handling
- **Production Patterns**: Real-world error handling from exemplar projects

---

## 13. Cross-Chapter Integration

### Connection to Previous Chapters
- **Chapter 3 (Memory & Allocators)**: Allocator error handling, cleanup patterns, arena allocators
- **Chapter 4 (Collections & Containers)**: Container cleanup on error paths, deinit responsibilities
- **Chapter 5 (I/O, Streams & Formatting)**: File error handling, stream errors, I/O cleanup

### Connection to Future Chapters
- **Chapter 7 (Async & Concurrency)**: Error handling in async contexts
- **Chapter 12 (Testing & Benchmarking)**: Advanced error testing patterns
- **Chapter 13 (Logging & Diagnostics)**: Error logging and diagnostics

---

**Status**: Research plan complete, ready to begin Phase 1 (Official Documentation Review)
**Next Step**: Execute research phases and document findings in `research_notes.md`
