# Research Plan: I/O, Streams & Formatting (Chapter 5)

**Research Date:** 2025-11-03
**Zig Versions Covered:** 0.14.0, 0.14.1, 0.15.1, 0.15.2
**Researcher:** Claude (Sonnet 4.5)
**Status:** Planning Phase

---

## 1. Chapter Overview & Objectives

### Primary Objective
Teach modern Zig I/O patterns and formatting APIs, focusing on the writer/reader model, stream lifetime management, and practical formatting patterns for day-to-day development.

### Key Questions to Answer
1. How does the writer/reader abstraction work in Zig?
2. What are the idiomatic patterns for obtaining and using writers and readers?
3. How do you handle stdout, stderr, and file I/O?
4. What are the best practices for formatting output?
5. How do you manage stream lifetime and cleanup?
6. What are the error handling patterns for I/O operations?
7. How do version differences (0.14.x vs 0.15+) affect I/O and formatting?
8. What are buffered vs unbuffered I/O patterns?

---

## 2. Core Topics to Research

### 2.1 Writer/Reader Abstraction

**Research Areas:**
- The `std.io.Writer` and `std.io.Reader` interface pattern
- Generic writer/reader types and implementations
- Obtaining writers from different sources:
  - stdout/stderr writers
  - File writers
  - Buffer writers
  - Network socket writers
  - Custom writer implementations
- Obtaining readers from different sources:
  - stdin readers
  - File readers
  - Buffer readers
  - Network socket readers
- Writer/reader composition patterns
- AnyWriter/AnyReader patterns (if applicable)

**Expected Sources:**
- Zig Standard Library documentation (`std.io`)
- Official language reference on I/O
- ziglang/zig source: `lib/std/io.zig`, `lib/std/io/reader.zig`, `lib/std/io/writer.zig`
- TigerBeetle, Ghostty, Bun for real-world I/O patterns

**Research Questions:**
- How does the generic writer/reader interface work?
- What are the type signatures and guarantees?
- How do you implement custom writers/readers?
- When should you use buffered vs unbuffered I/O?

---

### 2.2 Printing & Formatting Patterns

**Research Areas:**
- Standard printing functions:
  - `std.debug.print()`
  - `std.io.getStdOut().writer()`
  - `std.io.getStdErr().writer()`
- Formatting patterns:
  - `print()` method on writers
  - Format specifiers and their usage
  - Custom format implementations
  - `fmt` module patterns
- Formatting types:
  - Integers, floats, booleans
  - Strings and slices
  - Pointers and addresses
  - Custom types (implementing `format()`)
- Debugging vs production output patterns
- Performance considerations for formatting

**Expected Sources:**
- Zig Standard Library documentation (`std.fmt`)
- ziglang/zig source: `lib/std/fmt.zig`
- TigerBeetle TIGER_STYLE.md (logging conventions)
- Ghostty (terminal output formatting)
- Bun (JavaScript value formatting)
- ZLS (diagnostic output patterns)

**Research Questions:**
- What format specifiers are available?
- How do you implement custom formatting for your types?
- What are the performance implications of different formatting approaches?
- How do you handle formatting errors?

---

### 2.3 stdout/stderr Patterns

**Research Areas:**
- Obtaining stdout and stderr handles
- Buffered vs unbuffered output
- Line-buffered vs fully buffered patterns
- When to flush buffers
- Error handling for output operations
- stdout/stderr in different contexts (tests, CLI apps, servers)
- Thread-safety considerations for shared streams
- Redirecting or capturing output

**Expected Sources:**
- Zig Standard Library documentation
- ziglang/zig source: `lib/std/io.zig`
- TigerBeetle (structured logging to stderr)
- Bun (CLI output patterns)
- ZLS (language server output)
- Community CLI applications

**Research Questions:**
- When should you use buffered vs unbuffered output?
- How do you ensure output is flushed at appropriate times?
- What are the best practices for CLI applications?
- How do you handle output errors gracefully?

---

### 2.4 Stream Lifetime & Cleanup

**Research Areas:**
- Resource management for I/O streams
- When to close file handles
- Buffered stream flushing and closing
- Error-path cleanup for I/O resources (`errdefer`)
- defer patterns for stream cleanup
- File handle ownership semantics
- Reader/writer lifetime and borrowing
- Arena allocator patterns with I/O buffers

**Expected Sources:**
- Zig Standard Library documentation (`std.fs.File`)
- ziglang/zig source: `lib/std/fs/file.zig`
- TigerBeetle (file I/O patterns)
- Ghostty (file descriptor management)
- Bun (stream lifecycle)

**Research Questions:**
- When do you need to explicitly close streams?
- How do you ensure streams are properly closed on error paths?
- What are the ownership semantics for file handles?
- How do buffered streams interact with cleanup?

---

### 2.5 File I/O Patterns

**Research Areas:**
- Opening files for reading and writing
- File creation modes and permissions
- Reading files:
  - Reading entire files into memory
  - Streaming file reads
  - Line-by-line reading
  - Buffered reading patterns
- Writing files:
  - Writing entire buffers
  - Streaming writes
  - Buffered writing patterns
- File positioning and seeking
- Atomic file operations
- Temporary file patterns

**Expected Sources:**
- Zig Standard Library documentation (`std.fs`)
- ziglang/zig source: `lib/std/fs.zig`, `lib/std/fs/file.zig`
- TigerBeetle (data file I/O)
- Ghostty (config file reading)
- Bun (module resolution and file reading)

**Research Questions:**
- What are the idiomatic patterns for reading files?
- How do you handle large files efficiently?
- What are the error handling patterns for file operations?
- How do you ensure atomic file operations?

---

### 2.6 Buffering Patterns

**Research Areas:**
- BufferedReader and BufferedWriter
- Buffer size selection
- When to use buffering
- Flushing strategies
- Performance implications
- FixedBufferStream patterns
- Custom buffer management

**Expected Sources:**
- Zig Standard Library documentation (`std.io.bufferedReader`, `std.io.bufferedWriter`)
- ziglang/zig source: `lib/std/io/buffered_reader.zig`, `lib/std/io/buffered_writer.zig`
- TigerBeetle (buffered I/O patterns)
- Bun (high-performance buffering)

**Research Questions:**
- When should you use buffered I/O?
- What are appropriate buffer sizes?
- How do you manage buffer lifecycle?
- What are the performance trade-offs?

---

## 3. Research Methodology

### Phase 1: Official Documentation (Priority 1)
- [ ] Read Zig 0.15.2 standard library documentation for I/O and formatting
- [ ] Read Zig 0.14.1 standard library documentation for comparison
- [ ] Review release notes (0.14.0, 0.14.1, 0.15.1, 0.15.2) for I/O changes
- [ ] Examine standard library source code:
  - `std/io.zig`
  - `std/io/reader.zig`
  - `std/io/writer.zig`
  - `std/fmt.zig`
  - `std/fs/file.zig`
  - `std/io/buffered_reader.zig`
  - `std/io/buffered_writer.zig`
  - `std/io/fixed_buffer_stream.zig`

**Target Deliverables:**
- API surface documentation
- Version differences catalog
- Writer/reader interface specifications
- Format specifier reference
- Stream lifetime patterns

---

### Phase 2: Exemplar Project Analysis (Priority 1)

#### TigerBeetle (Correctness-First I/O)
**Files to Examine:**
- I/O patterns for data files
- Logging and diagnostic output
- TIGER_STYLE.md logging conventions
- Error handling for I/O operations
- Buffering strategies

**Research Questions:**
- How does TigerBeetle handle I/O errors?
- What are the logging patterns?
- How are file operations structured?

#### Ghostty (Terminal Emulator)
**Files to Examine:**
- PTY I/O patterns
- Config file reading
- Terminal output formatting
- Stream management for terminal I/O

**Research Questions:**
- How does Ghostty handle terminal I/O?
- What are the formatting patterns for terminal output?
- How is config file I/O handled?

#### Bun (JavaScript Runtime)
**Files to Examine:**
- High-performance I/O patterns
- Module file reading
- stdout/stderr handling
- JavaScript value formatting
- Network I/O patterns

**Research Questions:**
- How does Bun optimize I/O performance?
- What are the formatting patterns for JavaScript values?
- How is network I/O structured?

#### ZLS (Language Server)
**Files to Examine:**
- Source file reading
- LSP message formatting
- Diagnostic output
- Document stream management

**Research Questions:**
- How does ZLS handle source file I/O?
- What are the patterns for LSP message formatting?
- How are diagnostics formatted and output?

#### Mach Engine (Game/Multimedia)
**Files to Examine:**
- Asset file loading
- Debug output patterns
- Binary data I/O
- Logging systems

**Research Questions:**
- How does Mach handle asset I/O?
- What are the debugging and logging patterns?

**Target Deliverables:**
- 20+ deep GitHub links to real-world I/O usage
- Format implementation examples from production code
- Stream lifecycle patterns
- Common idioms across projects

---

### Phase 3: Community Resources (Priority 2)
- [ ] zig.guide - I/O and formatting section
- [ ] ziglearn.org - I/O patterns
- [ ] Zig by Example - I/O examples
- [ ] Introduction to Zig book (pedropark99) - I/O chapters
- [ ] Community discussions on Ziggit about I/O patterns
- [ ] Stack Overflow questions on Zig I/O and formatting

**Target Deliverables:**
- Common beginner mistakes
- Best practice patterns from community
- Migration guidance between versions
- Formatting gotchas and solutions

---

### Phase 4: Code Example Development (Priority 1)

**Required Examples (4-6 runnable):**

1. **Basic Writer/Reader Usage**
   - Obtaining stdout/stderr writers
   - Writing formatted output
   - Reading from stdin
   - Error handling patterns

2. **File I/O Patterns**
   - Reading entire file into memory
   - Writing to a file with proper cleanup
   - Streaming file reads and writes
   - Error-path cleanup with errdefer

3. **Custom Formatting**
   - Implementing custom format() for types
   - Format specifiers demonstration
   - Formatting complex nested structures
   - Performance-conscious formatting

4. **Buffered I/O**
   - BufferedReader and BufferedWriter usage
   - When and why to use buffering
   - Flushing patterns
   - Performance comparison

5. **Stream Lifetime Management**
   - defer/errdefer for cleanup
   - Nested stream resources
   - Ownership transfer patterns
   - Arena pattern with I/O buffers

6. **Real-World CLI Application Pattern**
   - Command-line argument processing
   - stdout/stderr usage conventions
   - Progress reporting
   - Error message formatting

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
- [ ] Document I/O APIs and patterns
- [ ] Identify any deprecated I/O functions
- [ ] Record standard formatting patterns
- [ ] Document stdout/stderr access patterns

### 0.15+ Changes
- [ ] Document any changes to I/O interfaces
- [ ] Identify breaking changes in fmt or I/O
- [ ] New I/O features or patterns
- [ ] Migration guidance for I/O code

### Cross-Version Patterns
- [ ] What works identically across all versions?
- [ ] What requires version markers?
- [ ] What are the recommended migration paths?

---

## 5. Common Pitfalls Research

**Target: Document 4-5 Common Mistakes**

1. **Forgetting to flush buffered output**
   - What happens?
   - When is flushing needed?
   - Prevention patterns

2. **Not closing file handles**
   - Resource leaks
   - Detection and prevention
   - defer/errdefer patterns

3. **Ignoring I/O errors**
   - Silent failures
   - Error handling best practices
   - Recovery strategies

4. **Using debug.print in production**
   - When to use debug.print vs proper logging
   - Performance implications
   - Better alternatives

5. **Incorrect buffer size choices**
   - Performance issues from poor sizing
   - Memory waste
   - Optimal sizing strategies

6. **Stream lifetime confusion**
   - Dangling references to writers/readers
   - Ownership mistakes
   - Cleanup order issues

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
- [ ] Resource cleanup is correct

### Content Quality Standards
- [ ] Clear explanation of writer/reader abstraction
- [ ] Formatting patterns are comprehensive
- [ ] Stream lifetime semantics are explicit
- [ ] Practical guidance for common scenarios
- [ ] Real-world examples from production code

---

## 7. Expected Deliverables

### Research Notes Document (`research_notes.md`)

**Structure:**
1. **Writer/Reader Abstraction**
   - Interface design and usage
   - Obtaining writers and readers
   - Custom implementations
   - Version differences

2. **Formatting Patterns**
   - Format specifiers reference
   - Custom formatting implementation
   - Performance considerations
   - Common patterns

3. **stdout/stderr Patterns**
   - Buffered vs unbuffered
   - Flushing strategies
   - Error handling
   - Thread-safety

4. **Stream Lifetime Management**
   - Resource cleanup patterns
   - defer/errdefer usage
   - Ownership semantics
   - Error-path cleanup

5. **File I/O Patterns**
   - Reading strategies
   - Writing strategies
   - Buffering patterns
   - Atomic operations

6. **Runnable Code Examples**
   - 4-6 comprehensive examples
   - Each with explanation and source attribution

7. **Exemplar Project Analysis**
   - 20+ deep GitHub links
   - Pattern analysis from each project
   - Common idioms identified

8. **Version Migration Guide**
   - 0.14.x patterns
   - 0.15+ patterns
   - Migration strategies

9. **Common Pitfalls**
   - 4-6 documented mistakes
   - Detection and prevention strategies

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
- [ ] **Pitfalls**: 4-6 common mistakes documented with solutions
- [ ] **Citations**: All factual claims have authoritative sources
- [ ] **Clarity**: Clear explanation of writer/reader model
- [ ] **Actionability**: Practical guidance for I/O operations
- [ ] **Version Awareness**: Clear version markers for version-specific content

---

## 10. Open Questions for User Clarification

**None at this stage.** The prompt.md and style_guide.md provide clear requirements. If ambiguities arise during research, will document them for clarification.

---

## 11. Research Sources Catalog

### Official Documentation
- Zig 0.15.2 Language Reference
- Zig 0.15.2 Standard Library Reference (std.io, std.fmt, std.fs)
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

This research plan follows the same successful methodology used in previous chapters:

1. **Start with official sources** to establish authoritative baseline
2. **Analyze exemplar projects** for real-world patterns and deep links
3. **Supplement with community resources** for common patterns and pitfalls
4. **Develop runnable examples** that demonstrate key concepts
5. **Document everything** with proper citations and version markers
6. **Validate** against quality standards before finalizing

The plan ensures comprehensive coverage of the writer/reader abstraction, formatting patterns, stream lifetime management, and practical I/O patterns for day-to-day Zig development.

---

**Status**: Research plan complete, ready to begin Phase 1 (Official Documentation Review)
**Next Step**: Execute research phases and document findings in `research_notes.md`
