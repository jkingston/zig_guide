# Research Plan: Chapter 7 - Async, Concurrency & Performance

## Document Information
- **Chapter**: 7 - Async, Concurrency & Performance
- **Target Zig Versions**: 0.14.0, 0.14.1, 0.15.1, 0.15.2
- **Created**: 2025-11-03
- **Status**: In Progress

## 1. Objectives

This research plan outlines the methodology for creating comprehensive documentation on Zig's concurrency model, async patterns, and performance optimization techniques. The chapter addresses a critical transition: the removal of async/await keywords in Zig 0.15+, requiring coverage of both legacy patterns and modern approaches.

**Primary Goals:**
1. Document modern (0.15+) concurrency approaches using std.Thread and synchronization primitives
2. Explain event loop patterns with practical library examples (xev)
3. Provide brief but accurate legacy documentation of 0.14.x async/await
4. Demonstrate profiling and benchmarking techniques
5. Offer clear guidance on when to use threads vs event loops
6. Show real-world patterns from production codebases

**Strategic Approach:**
- Focus primarily on 0.15+ patterns as the current and future direction
- Include brief legacy section on async/await for 0.14.x users with clear deprecation warnings
- Use xev library to demonstrate realistic async I/O patterns
- Balance theory with practical, runnable examples
- Maintain version compatibility through clear markers

## 2. Scope Definition

### In Scope

**Core Concurrency Topics:**
- std.Thread: Creation, joining, thread lifecycle management
- Synchronization primitives: Mutex, RwLock, Semaphore, Condition
- Atomic operations: std.atomic usage patterns and memory ordering
- Thread-local storage and thread safety patterns

**Event Loop Patterns:**
- Event loop architecture and concepts
- xev library: Installation, basic usage, common patterns
- Async I/O without language-level async/await
- Comparing threads vs event loops for different use cases

**Legacy Async (0.14.x):**
- Brief overview of async/await keywords
- Why they were removed (architectural rationale)
- Migration guidance for 0.14.x users

**Performance Topics:**
- std.testing.benchmark usage
- std.time for measurements
- Integration with external profilers (perf, tracy, valgrind)
- Performance-oriented coding patterns
- Benchmarking methodology

### Out of Scope

- Deep dive into async/await implementation details (deprecated)
- Comprehensive event loop library comparison (focus on xev)
- Low-level synchronization primitives beyond stdlib
- Advanced SIMD or cache optimization (future chapter material)
- Distributed systems or networked concurrency
- Lock-free data structures (beyond basic atomic usage)

### Version-Specific Handling

**0.14.x (Legacy):**
- Mark with 🕐 0.14.x version indicator
- Keep brief, focused on migration path
- Explain deprecation rationale
- Provide code example for reference only

**0.15+ (Current):**
- Mark with ✅ 0.15+ version indicator
- Primary focus of chapter
- Show modern patterns and idioms
- All main examples target 0.15.2

## 3. Core Topics

### Topic 1: Thread Fundamentals (std.Thread)

**Concepts to Cover:**
- Thread creation with std.Thread.spawn
- Thread joining and detaching
- Passing data to threads safely
- Thread lifecycle and resource management
- Error handling in threaded contexts

**Research Sources:**
- Zig 0.15.2 standard library: std/Thread.zig
- Official documentation: threading section
- TigerBeetle: thread pool patterns
- Bun: thread usage for JavaScript workers

**Example Requirements:**
- Basic thread creation and joining
- Passing structured data to threads
- Error handling across thread boundaries

### Topic 2: Synchronization Primitives

**Concepts to Cover:**
- Mutex: Exclusive access patterns
- RwLock: Reader-writer synchronization
- Atomic operations: Load, store, compare-and-swap
- Memory ordering: Acquire, Release, SeqCst, Monotonic
- Condition variables (if available in stdlib)
- Thread-safe data structures

**Research Sources:**
- Zig 0.15.2 standard library: std/Thread/Mutex.zig, std/Thread/RwLock.zig
- std.atomic documentation
- TigerBeetle: deterministic concurrency patterns
- Bun: high-performance synchronization

**Example Requirements:**
- Mutex protecting shared state
- Atomic counter with proper memory ordering
- RwLock for read-heavy workloads

### Topic 3: Event Loop Patterns

**Concepts to Cover:**
- Event loop architecture (single-threaded async)
- Event types: I/O readiness, timers, signals
- Non-blocking I/O concepts
- xev library: Setup, running the loop, registering callbacks
- Async I/O without async/await keywords
- When to choose event loops vs threads

**Research Sources:**
- xev library repository and documentation
- Ghostty: xev integration patterns
- libuv, libev comparisons (architectural concepts)
- Async I/O models (epoll, kqueue, IOCP)

**Example Requirements:**
- Basic xev event loop setup
- Timer events
- File descriptor I/O (if xev supports)
- Combining xev with std.Thread

### Topic 4: Legacy Async/Await (0.14.x)

**Concepts to Cover:**
- async function declaration
- await expressions
- suspend and resume semantics
- Why async/await was removed
- Migration path to 0.15+

**Research Sources:**
- Zig 0.14.1 documentation
- Zig GitHub issues/proposals on async removal
- Andrew Kelley's statements on async direction
- Community discussions on ziggit.dev

**Example Requirements:**
- One reference example showing 0.14.x async/await syntax
- Clear deprecation warning
- Equivalent 0.15+ implementation

### Topic 5: Profiling and Benchmarking

**Concepts to Cover:**
- std.testing.benchmark API
- std.time for manual measurements
- Benchmark methodology and pitfalls
- External profiler integration (perf, tracy)
- Release builds vs debug builds
- CPU cache effects on benchmarks

**Research Sources:**
- std.testing source code
- std.time documentation
- Mach: performance measurement patterns
- Bun: benchmarking strategies

**Example Requirements:**
- std.testing.benchmark usage
- Manual timing with std.time
- Comparing algorithm performance

## 4. Research Methodology

### Phase 1: Official Documentation (Priority 1, ~3 hours)

**Objective:** Establish authoritative understanding of language features and stdlib APIs.

**Tasks:**
1. Read Zig 0.15.2 documentation on std.Thread, std.atomic, synchronization primitives
2. Read Zig 0.14.1 documentation on async/await (for legacy section)
3. Review std.testing.benchmark and std.time APIs
4. Search release notes for async/await removal rationale
5. Check GitHub proposals/issues related to async removal

**Deliverables:**
- Notes on current (0.15+) threading APIs with version compatibility
- Understanding of legacy (0.14.x) async/await
- Rationale for async/await removal
- API references for benchmarking tools

**Validation:**
- Can explain why async/await was removed
- Can describe std.Thread API accurately
- Understand memory ordering guarantees

### Phase 2: Event Loop Libraries (Priority 1, ~3 hours)

**Objective:** Understand modern async I/O patterns using library-based approaches.

**Tasks:**
1. Clone/explore xev library repository
2. Read xev documentation and examples
3. Understand xev's event loop model
4. Check xev's Zig version compatibility
5. Identify alternative event loop libraries (if any)
6. Study Ghostty's xev integration

**Deliverables:**
- Notes on xev installation and setup
- Understanding of xev API and patterns
- Comparison with traditional async/await
- Real-world usage examples from Ghostty

**Validation:**
- Can install and run basic xev example
- Can explain event loop architecture
- Can map async concepts to xev patterns

### Phase 3: Exemplar Projects (Priority 1, ~4 hours)

**Objective:** Extract real-world concurrency patterns from production codebases.

**Tasks:**
1. **Ghostty**: Search for xev usage, thread patterns, async I/O
   - Grep for: `xev`, `std.Thread.spawn`, `Mutex`, `atomic`
   - Read: Main event loop, terminal I/O handling
2. **Bun**: Search for concurrency patterns, thread pools
   - Grep for: thread usage, synchronization primitives
   - Focus on: JavaScript worker threads, async runtime
3. **TigerBeetle**: Search for deterministic concurrency
   - Grep for: `Mutex`, `atomic`, thread safety comments
   - Read: TIGER_STYLE.md section on concurrency
4. **Mach**: Search for game loop patterns, frame timing
   - Grep for: event loops, performance measurement
   - Focus on: Frame rate limiting, async patterns

**Deliverables:**
- 20+ deep GitHub links to production code
- Notes on common patterns and idioms
- Anti-patterns and pitfalls
- Style guidelines from TigerBeetle

**Validation:**
- Found concrete examples of each pattern
- Can cite specific files and line numbers
- Understand production-grade error handling

### Phase 4: Performance Tooling (Priority 2, ~2 hours)

**Objective:** Document profiling and benchmarking approaches.

**Tasks:**
1. Study std.testing.benchmark implementation
2. Read documentation on benchmark methodology
3. Research external profiler integration:
   - Linux perf with Zig binaries
   - Tracy profiler integration
   - Valgrind for memory analysis
4. Check Mach and Bun for benchmarking examples
5. Understand compiler optimizations affecting benchmarks

**Deliverables:**
- Notes on benchmark best practices
- Examples of profiler integration
- Common pitfalls in performance measurement
- Links to external profiler documentation

**Validation:**
- Can write accurate benchmarks
- Understand benchmark pitfalls
- Can integrate external profilers

### Phase 5: Code Examples (Priority 1, ~5 hours)

**Objective:** Create 5-6 runnable, well-documented code examples.

**Examples to Create:**

1. **example_basic_threads.zig** (~50-80 lines)
   - Thread creation with std.Thread.spawn
   - Passing data to threads
   - Joining threads
   - Error handling
   - Expected output demonstration

2. **example_synchronization.zig** (~80-120 lines)
   - Mutex protecting shared counter
   - Atomic operations with memory ordering
   - RwLock for reader-writer pattern
   - Comparison of approaches

3. **example_event_loop_xev.zig** (~80-120 lines)
   - xev setup and initialization
   - Basic event loop
   - Timer events
   - Clean shutdown
   - Requires xev dependency

4. **example_async_io_xev.zig** (~100-150 lines)
   - Async file I/O with xev
   - Multiple concurrent operations
   - Error handling in async context
   - Requires xev dependency

5. **example_benchmarking.zig** (~60-100 lines)
   - std.testing.benchmark usage
   - Comparing algorithm implementations
   - Manual timing with std.time
   - Benchmark pitfalls demonstration

6. **example_legacy_async.zig** (~40-60 lines) [Optional]
   - 0.14.x async/await syntax reference
   - Clear deprecation comments
   - Equivalent 0.15+ approach shown
   - Only for comparison purposes

**Quality Requirements:**
- All examples compile without warnings on Zig 0.15.2
- Examples include clear comments explaining concepts
- Each example has expected output description
- Code follows project style_guide.md
- Examples are self-contained (except xev dependencies)

**Testing Process:**
1. Write example code
2. Compile with Zig 0.15.2
3. Run and verify output
4. Document any dependencies (xev)
5. Add explanatory comments
6. Test with --release-fast to check optimizations

### Phase 6: Research Notes Synthesis (Priority 1, ~3 hours)

**Objective:** Consolidate all research findings into comprehensive research_notes.md.

**Structure:**
1. Introduction and scope
2. Thread fundamentals (std.Thread)
3. Synchronization primitives
4. Event loop patterns (xev)
5. Legacy async/await and removal rationale
6. Profiling and benchmarking
7. Production patterns from exemplar projects
8. Common pitfalls
9. Version differences (0.14.x vs 0.15+)
10. Code examples summary
11. Sources and references (30+ citations)

**Quality Requirements:**
- 1500+ lines of detailed notes
- 20+ deep GitHub links to production code
- All claims cited with authoritative sources
- Clear version-specific guidance
- Organized for easy reference during writing

### Phase 7: Content Writing (Priority 1, ~4 hours)

**Objective:** Create publication-ready content.md chapter.

**Structure (from prompt.md):**
1. **Overview** - Purpose and importance of concurrency and performance
2. **Core Concepts** - Example-driven teaching of key ideas
3. **Code Examples** - 5-6 runnable snippets with explanations
4. **Common Pitfalls** - 4-5 frequent mistakes and safer alternatives
5. **In Practice** - Real-world usage from reference repos
6. **Summary** - Mental model reinforcement
7. **References** - Numbered list of all citations (15+)

**Content Requirements:**
- 1000-1500 lines
- Follow style_guide.md (neutral, professional, no contractions)
- Version markers: 🕐 0.14.x, ✅ 0.15+
- Inline code examples with syntax highlighting
- Deep GitHub links (20+)
- Authoritative citations (15+)
- Clear explanation of async/await removal

**Writing Process:**
1. Review research_notes.md for key points
2. Organize content into chapter structure
3. Write overview and core concepts sections
4. Integrate code examples with explanations
5. Document common pitfalls with solutions
6. Add production examples from research
7. Write summary section
8. Compile references list
9. Review for style guide compliance
10. Verify all version markers are correct

## 5. Version Compatibility Strategy

### 0.14.x Support (Legacy)

**Approach:**
- Include brief section on async/await at end of chapter
- Mark clearly with 🕐 0.14.x version indicator
- Explain deprecation and rationale
- Provide migration guidance to 0.15+
- Keep one reference example

**Rationale:**
Users on 0.14.x need to understand what changed and why, but the primary focus should be on current and future patterns.

### 0.15+ Support (Current)

**Approach:**
- Mark all current features with ✅ 0.15+
- Focus on std.Thread and library-based async
- Show modern patterns and idioms
- All main examples target 0.15.2

**Testing:**
- Compile all examples with Zig 0.15.2
- Verify APIs against stdlib source
- Check for deprecation warnings

### Breaking Changes to Address

**async/await Removal:**
- Explain architectural reasons (simplification, library-based approach)
- Show equivalent patterns with std.Thread and xev
- Provide migration table: async/await -> modern equivalent
- Link to official proposals/discussions

**API Changes:**
- Document any std.Thread API changes between 0.14 and 0.15
- Note atomic operations API stability
- Check for synchronization primitive changes

## 6. Code Example Specifications

### Example 1: example_basic_threads.zig

**Purpose:** Demonstrate std.Thread fundamentals.

**Content:**
- Thread creation with spawn()
- Passing data via struct
- Joining threads
- Error handling
- Resource cleanup

**Concepts Illustrated:**
- Thread lifecycle
- Data sharing between threads
- Thread-safe resource management

**Expected Output:**
```
Starting main thread
Worker thread received: 42
Worker thread received: 100
Main thread completed
```

**Estimated Lines:** 50-80

### Example 2: example_synchronization.zig

**Purpose:** Show synchronization primitives in action.

**Content:**
- Mutex protecting shared counter
- Multiple threads incrementing safely
- Atomic counter comparison
- RwLock for read-heavy pattern
- Performance comparison notes

**Concepts Illustrated:**
- Exclusive access with Mutex
- Atomic operations
- Reader-writer synchronization
- When to use each approach

**Expected Output:**
```
Mutex-protected counter: 1000 (10 threads x 100 iterations)
Atomic counter: 1000
RwLock: 100 writes, 1000 reads completed
```

**Estimated Lines:** 80-120

### Example 3: example_event_loop_xev.zig

**Purpose:** Basic xev event loop usage.

**Content:**
- xev initialization
- Event loop creation
- Timer events
- Clean shutdown
- Error handling

**Concepts Illustrated:**
- Event loop architecture
- Single-threaded async
- Non-blocking operations
- Resource management

**Dependencies:** xev library

**Expected Output:**
```
Event loop started
Timer fired: 100ms
Timer fired: 200ms
Timer fired: 300ms
Event loop shutdown
```

**Estimated Lines:** 80-120

### Example 4: example_async_io_xev.zig

**Purpose:** Async I/O patterns with xev.

**Content:**
- File I/O with xev
- Multiple concurrent operations
- Completion callbacks
- Error handling in async context

**Concepts Illustrated:**
- Async file operations
- Callback patterns
- Concurrent I/O without blocking
- Error propagation in async code

**Dependencies:** xev library

**Expected Output:**
```
Started reading file1.txt
Started reading file2.txt
Completed file1.txt: 256 bytes
Completed file2.txt: 512 bytes
All operations completed
```

**Estimated Lines:** 100-150

### Example 5: example_benchmarking.zig

**Purpose:** Performance measurement techniques.

**Content:**
- std.testing.benchmark usage
- Comparing sort algorithms
- Manual timing with std.time
- Warm-up and iteration count
- Statistical considerations

**Concepts Illustrated:**
- Benchmark methodology
- Timing measurement
- Performance comparison
- Common pitfalls (cache effects, optimizer)

**Expected Output:**
```
Algorithm A: 1.23ms average (1000 iterations)
Algorithm B: 0.89ms average (1000 iterations)
Winner: Algorithm B (27% faster)
```

**Estimated Lines:** 60-100

### Example 6: example_legacy_async.zig (Optional)

**Purpose:** Reference for 0.14.x async/await syntax.

**Content:**
- async function declaration
- await expression
- Clear deprecation notice
- Equivalent 0.15+ approach shown

**Concepts Illustrated:**
- Legacy async/await syntax
- Why it was removed
- How to express same pattern in 0.15+

**Version:** Targets 0.14.1, marked as deprecated

**Estimated Lines:** 40-60

## 7. Source Documentation

### Official Zig Sources (Priority 1)

1. **Zig 0.15.2 Documentation**
   - URL: https://ziglang.org/documentation/0.15.2/
   - Sections: Language Reference (threading), Standard Library
   - Focus: std.Thread, std.atomic, std.testing

2. **Zig 0.14.1 Documentation**
   - URL: https://ziglang.org/documentation/0.14.1/
   - Sections: async/await keywords
   - Focus: Legacy async documentation

3. **Zig Standard Library Source**
   - Path: /home/jack/workspace/zig_guide/zig_versions/zig-0.15.2/lib/std/
   - Files: Thread.zig, Thread/Mutex.zig, Thread/RwLock.zig, atomic.zig, testing.zig
   - Method: Direct source code reading

4. **Zig GitHub Repository**
   - Proposals on async removal
   - Release notes for 0.15.0
   - Issues discussing concurrency

### Event Loop Libraries

1. **xev**
   - Repository: https://github.com/mitchellh/libxev
   - Documentation: README and examples/
   - Focus: Event loop API, Zig bindings

2. **Ghostty xev Integration**
   - Path: /home/jack/workspace/zig_guide/reference_repos/ghostty/
   - Search: xev usage patterns
   - Focus: Real-world async I/O

### Exemplar Projects (Priority 1)

1. **TigerBeetle**
   - Path: /home/jack/workspace/zig_guide/reference_repos/tigerbeetle/
   - Files: src/*, TIGER_STYLE.md
   - Search patterns: `Mutex`, `atomic`, concurrency comments
   - Focus: Deterministic concurrency, testing

2. **Ghostty**
   - Path: /home/jack/workspace/zig_guide/reference_repos/ghostty/
   - Search patterns: `xev`, `std.Thread`, event loop
   - Focus: Modern async I/O, terminal handling

3. **Bun**
   - Path: /home/jack/workspace/zig_guide/reference_repos/bun/
   - Search patterns: thread pool, worker threads
   - Focus: High-performance JavaScript runtime

4. **Mach**
   - Repository: https://github.com/hexops/mach
   - Focus: Game loop, frame timing, performance

### Community Resources (Priority 2)

1. **Zig Guide (zig.guide)**
   - URL: https://zig.guide/
   - Sections: Concurrency, async
   - Method: WebFetch for current content

2. **ziggit.dev**
   - Search: async removal discussions, concurrency patterns
   - Focus: Community perspective on async transition

3. **Zig NEWS**
   - Recent announcements on async direction
   - Performance improvements in stdlib

## 8. Common Pitfalls to Document

### Concurrency Pitfalls

1. **Data Races Without Synchronization**
   - Problem: Multiple threads accessing shared state without protection
   - Solution: Mutex or atomic operations
   - Example: Counter incremented by multiple threads

2. **Deadlocks with Multiple Mutexes**
   - Problem: Lock ordering inconsistency
   - Solution: Always acquire locks in consistent order
   - Example: Two mutexes locked in different order

3. **Memory Ordering Confusion**
   - Problem: Incorrect atomic operation ordering
   - Solution: Understand Acquire, Release, SeqCst semantics
   - Example: When Monotonic is insufficient

4. **Forgetting to Join Threads**
   - Problem: Main thread exits before workers complete
   - Solution: Always join or detach threads
   - Example: Resource leaks from unjoined threads

### Performance Pitfalls

5. **Inaccurate Benchmarks**
   - Problem: Optimizer removes code, cold cache effects
   - Solution: Use std.testing.benchmark, warm-up runs
   - Example: Benchmark that measures nothing

6. **Thread Oversubscription**
   - Problem: Creating too many threads
   - Solution: Thread pool matching CPU cores
   - Example: Performance degradation with excessive threads

7. **Event Loop Blocking Operations**
   - Problem: Blocking calls in event loop thread
   - Solution: Offload to worker threads or use async I/O
   - Example: File I/O blocking event loop

## 9. Validation Criteria

### Research Quality

- [ ] All claims cited with authoritative sources
- [ ] 20+ deep GitHub links to production code
- [ ] 15+ numbered references in bibliography
- [ ] Version-specific behavior documented
- [ ] Breaking changes clearly explained

### Code Quality

- [ ] All examples compile without warnings on Zig 0.15.2
- [ ] Examples run and produce expected output
- [ ] Code follows project style_guide.md
- [ ] Comments explain concepts clearly
- [ ] Examples are self-contained (except documented dependencies)

### Content Quality

- [ ] Chapter structure matches prompt.md requirements
- [ ] Style guide compliance (neutral, professional tone)
- [ ] Version markers used consistently
- [ ] 4-5 common pitfalls documented
- [ ] Clear explanation of async/await removal
- [ ] Practical guidance on threads vs event loops

### Completeness

- [ ] All core topics covered
- [ ] 5-6 runnable code examples
- [ ] Production patterns from exemplar projects
- [ ] Legacy async/await section included
- [ ] Profiling and benchmarking demonstrated
- [ ] Migration guidance provided

## 10. Timeline and Milestones

### Day 1: Research (8 hours)
- Phase 1: Official documentation (3 hours)
- Phase 2: Event loop libraries (3 hours)
- Phase 3: Start exemplar projects (2 hours)

**Milestone:** Understanding of async removal, std.Thread API, xev basics

### Day 2: Analysis and Examples (8 hours)
- Phase 3: Complete exemplar projects (2 hours)
- Phase 4: Performance tooling (2 hours)
- Phase 5: Start code examples (4 hours)

**Milestone:** 20+ GitHub links collected, 3+ examples complete

### Day 3: Examples and Writing (8 hours)
- Phase 5: Complete code examples (2 hours)
- Phase 6: Write research_notes.md (3 hours)
- Phase 7: Start content.md (3 hours)

**Milestone:** All examples working, comprehensive research notes

### Day 4: Content and Review (4 hours)
- Phase 7: Complete content.md (3 hours)
- Final review and validation (1 hour)

**Milestone:** Publication-ready chapter with all requirements met

**Total Estimated Time:** 28 hours (spread over 4 days)

## 11. Success Metrics

### Quantitative Metrics

- [ ] 5-6 runnable code examples created
- [ ] 1000-1500 lines in content.md
- [ ] 1500+ lines in research_notes.md
- [ ] 20+ deep GitHub links to production code
- [ ] 15+ authoritative citations
- [ ] 4-5 common pitfalls documented
- [ ] 0 compilation warnings on Zig 0.15.2

### Qualitative Metrics

- [ ] Clear explanation of why async/await was removed
- [ ] Practical guidance on choosing concurrency patterns
- [ ] Reader can understand threads vs event loops tradeoffs
- [ ] Code examples demonstrate real-world patterns
- [ ] Production examples show best practices
- [ ] Migration path clear for 0.14.x users

### User Outcomes

After reading this chapter, users should be able to:
- [ ] Create and manage threads with std.Thread
- [ ] Use Mutex and atomic operations correctly
- [ ] Understand event loop architecture
- [ ] Set up basic xev event loop
- [ ] Choose appropriate concurrency pattern for their use case
- [ ] Write accurate benchmarks
- [ ] Understand why async/await was removed
- [ ] Migrate from 0.14.x async/await to 0.15+ patterns

## 12. Risk Mitigation

### Risk 1: xev Version Compatibility

**Risk:** xev library may not be compatible with all target Zig versions.

**Mitigation:**
- Check xev compatibility with Zig 0.15.2
- Document required xev version
- Provide installation instructions
- Include fallback explanation if examples can't run

### Risk 2: Incomplete async Removal Documentation

**Risk:** Official rationale for async removal may be sparse or scattered.

**Mitigation:**
- Search GitHub proposals, issues, and release notes
- Check Andrew Kelley's talks and ziggit posts
- Synthesize information from multiple sources
- Focus on architectural benefits even if rationale is brief

### Risk 3: Limited Production Async Examples

**Risk:** Reference projects may not have extensive async patterns yet.

**Mitigation:**
- Focus on Ghostty's xev usage as primary example
- Document thread-based patterns from other projects
- Explain transition period for ecosystem
- Show conceptual patterns even if examples are limited

### Risk 4: Complex Event Loop Examples

**Risk:** Async I/O examples may be too complex for tutorial.

**Mitigation:**
- Start with simple timer-based xev example
- Build complexity gradually
- Focus on concepts over completeness
- Provide links to full examples in Ghostty

## 13. Research Questions

These questions will guide the research and should be answered by the end:

1. **Why was async/await removed from Zig?**
   - What were the architectural issues?
   - What is the future direction?
   - When was the decision made?

2. **How do modern Zig projects handle async I/O?**
   - What libraries are used?
   - What patterns are common?
   - How does it compare to async/await?

3. **When should you use threads vs event loops?**
   - Performance characteristics?
   - Use case recommendations?
   - Hybrid approaches?

4. **What are the memory ordering guarantees in std.atomic?**
   - Acquire, Release, SeqCst, Monotonic?
   - When to use each?
   - Common mistakes?

5. **How do you profile Zig programs?**
   - Built-in tools?
   - External profilers?
   - Best practices?

6. **What concurrency patterns are used in production?**
   - TigerBeetle's approach?
   - Ghostty's event loop?
   - Bun's thread model?

7. **How do you test concurrent code reliably?**
   - Deterministic testing?
   - Race detection?
   - Error injection?

## 14. Notes and Observations

*This section will be populated during research with insights, interesting findings, and important observations that don't fit elsewhere.*

---

**Document Status:** ✅ Complete - Ready for execution
**Next Step:** Begin Phase 1 - Official Documentation Research
