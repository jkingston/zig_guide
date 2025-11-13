# Zig: Zero to Hero — Reference & Exemplars

> Comprehensive reference list of official documentation, guides, idioms, and exemplar projects
> covering **Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2**, the validated production versions for this guide.
>
> Use this document as a "source appendix" when writing best-practice or idiom sections.

---

## 1. Authoritative Documentation

| Resource                                                                                 | Description                                                                               |
| ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **[Zig Language Reference (0.15.2)](https://ziglang.org/documentation/0.15.2/)**         | Canonical specification for syntax, semantics, and the standard library as of 0.15.2.     |
| **[Zig Language Reference (0.14.1)](https://ziglang.org/documentation/0.14.1/)**         | Previous stable release documentation, still used in many OSS projects.                   |
| **[Style Guide](https://ziglang.org/documentation/0.15.2/#Style-Guide)**                 | Official coding conventions — naming, indentation, file layout, and idiomatic constructs. |
| **[Standard Library Reference](https://ziglang.org/documentation/0.15.2/std)**           | Documentation for the Zig standard library (stdlib) APIs and idioms.                      |
| **[Build System Guide](https://zig.guide/build-system/)**                                | How to structure, compile, and package projects using `build.zig`.                        |
| **[Generating Documentation](https://zig.guide/build-system/generating-documentation/)** | How to use `zig doc` and inline comments for documentation generation.                    |
| **[Zig Downloads Page](https://ziglang.org/download/)**                                  | Official hub listing all versions and binaries, with links to each set of release notes.  |

---

## 2. Community Guides & Example-Driven Learning

| Resource                                                                               | Description                                                                                 |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **[Zig by Example](https://zig-by-example.com)**                                       | Concise, practical snippets demonstrating idiomatic Zig features.                           |
| **[Zig.guide](https://zig.guide)**                                                     | Beginner-friendly walkthroughs for core concepts and project organization.                  |
| **[Ziglings](https://github.com/ratfactor/ziglings)**                                  | Interactive exercise series inspired by *Rustlings*, teaching idioms by fixing broken code. |
| **[ZigLearn](https://ziglearn.org)**                                                   | Text-based tutorial explaining Zig’s semantics, memory model, and tooling.                  |
| **[Introduction to Zig (Pedro Duarte Faria)](https://pedropark99.github.io/zig-book)** | Project-based open book covering fundamentals and modern idioms.                            |

---

## 3. Community Discussions & Best-Practice Threads

| Topic                                                                                                                        | Summary                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **[Parameter documentation patterns](https://ziggit.dev/t/what-are-the-best-param-documentation-patterns-for-zig/4422)**     | Community discussion on inline API doc conventions.                                          |
| **[Organizing large projects](https://stackoverflow.com/questions/78766103/how-to-organize-large-projects-in-zig-language)** | Guidance for multi-module layout, namespacing, and dependency handling.                      |
| **[Idioms and error handling](https://ziggit.dev)**                                                                          | Ongoing community exploration of defer/errdefer usage, error unions, and RAII-like patterns. |

---

## 4. Exemplar Projects (Architectural References)

> **These 6 production codebases are deeply integrated throughout the guide** with 476+ cited examples demonstrating architectural patterns, best practices, and production idioms. Each reference includes GitHub links with line numbers and contextual explanations.

| Project                                                          | Integration Level | Description                                                                                                                                              |
| ---------------------------------------------------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[TigerBeetle](https://github.com/tigerbeetle/tigerbeetle)**    | 164 citations     | Distributed financial transaction database. Exemplifies correctness-first design, testing strategy, data-integrity patterns, and deterministic simulation. |
| **[Ghostty](https://github.com/ghostty-org/ghostty)**            | 101 citations     | GPU-accelerated terminal emulator by Mitchell Hashimoto. Cross-platform abstractions, C/Swift interop, modular architecture, and platform-aware logging.  |
| **[Bun](https://github.com/oven-sh/bun)**                        | 97 citations      | JavaScript runtime, bundler, and package manager. Demonstrates async I/O, work-stealing thread pools, atomic operations, and high-performance patterns.    |
| **[ZLS – Zig Language Server](https://github.com/zigtools/zls)** | 87 citations      | Language server tooling showing modular design, build integration, incremental compilation, and probabilistic failure testing.                           |
| **[Mach](https://github.com/hexops/mach)**                       | 27+ citations     | Game and multimedia framework ecosystem. Modular API design, `zig build` idioms, optional feature patterns, and graphics engine architecture.            |
| **[Zig Stdlib](https://github.com/ziglang/zig)**                 | 40+ citations     | Zig compiler and standard library source. Canonical reference for idiomatic patterns, memory management, and API design.                                 |

---

## 5. Additional Reference Projects

> Production Zig codebases demonstrating specialized patterns. While not as extensively cited as exemplar projects, these provide valuable domain-specific examples.

| Project                                                        | Description                                                                                                                                  |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **[zig-gamedev](https://github.com/michal-z/zig-gamedev)**     | Graphics and game development libraries. Complex C/C++ interop, sophisticated multi-library build patterns, and cross-platform abstractions. |
| **[zap](https://github.com/zigzap/zap)**                       | High-performance HTTP server framework. Production event loop patterns, middleware architecture, and efficient request/response handling.    |
| **[zigimg](https://github.com/zigimg/zigimg)**                 | Image encoding/decoding library. Structured binary I/O, format parsing, streaming decoders, and allocator usage patterns.                    |
| **[NCDU 2](https://dev.yorhel.nl/ncdu)**                       | Disk usage analyzer rewritten in Zig. Compact, idiomatic CLI structure.                                                                      |
| **[zigup](https://github.com/marler8997/zigup)**               | Zig version manager. Cross-platform CLI patterns, filesystem operations, HTTP downloads, and version lifecycle management.                   |
| **[zig-ci-template](https://github.com/ziglang/zig-bootstrap)** | Official CI configuration examples. Matrix builds, cross-compilation workflows, and artifact caching strategies.                             |

---

## 6. Learning Resources & Ecosystem Discovery

> Resources for learning Zig progressively and discovering community projects. These are not architectural exemplars but valuable for skill development and ecosystem navigation.

| Resource                                                       | Purpose                                                                                     |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **[Ziglings](https://github.com/ratfactor/ziglings)**          | Interactive exercise series inspired by *Rustlings*, teaching idioms by fixing broken code. |
| **[Awesome Zig](https://github.com/zigcc/awesome-zig)**        | Curated index of Zig libraries, tools, games, and applications for ecosystem discovery.     |
| **[Awesome Mach](https://github.com/hexops/awesome-mach)**     | Supplementary list focused on the Mach ecosystem (graphics & game dev).                     |
| **[ZigMod](https://github.com/nektro/zigmod)** *(Historical)* | Pre-0.11 package manager. Now superseded by official package management in Zig 0.11+.       |

---

## 7. Version-Specific Release Notes

> For cross-version best-practice commentary, refer to these release notes when identifying behavioral or standard-library changes between 0.14 and 0.15.

| Version                                                              | Date       | Notes                                                                                      |
| -------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------ |
| **[0.15.2](https://ziggit.dev/t/zig-0-15-2-released/12466/6)**       | 2025-10-11 | Most recent stable at time of writing — minor fixes and stability improvements.            |
| **[0.15.1](https://ziglang.org/download/0.15.1/release-notes.html)** | 2025-08-19 | Introduced incremental build enhancements and diagnostic improvements.                     |
| **[0.15.0](https://ziglang.org/download/0.15.0/release-notes.html)** | (retracted) | **Retracted** — never officially released. Use 0.15.1 instead.                            |
| **[0.14.1](https://ziglang.org/download/0.14.1/release-notes.html)** | 2025-05-21 | Bug-fix release for 0.14; widely used baseline for many production projects.               |
| **[0.14.0](https://ziglang.org/download/0.14.0/release-notes.html)** | 2025-03-05 | Major feature update: improved build system, incremental compilation, x86 backend rewrite. |

---

## 8. Suggested Use in the Guide

When building *Zig: Zero to Hero* itself:

1. **Cite official docs** for any syntax or standard-library feature.
2. **Pull idioms** and code examples primarily from **Exemplar Projects** (Section 4):
   - TigerBeetle for testing, correctness, and data integrity patterns
   - Ghostty for cross-platform abstractions and C/Swift interop
   - Bun for concurrency, async I/O, and high-performance patterns
   - ZLS for tooling, build integration, and testing utilities
   - Mach for game engine architecture and modular design
   - Zig stdlib for canonical idiomatic patterns
3. **Use Additional Reference Projects** (Section 5) for domain-specific examples:
   - zig-gamedev for complex build patterns and C/C++ interop
   - zap for HTTP server architecture
   - zigimg for binary I/O and format parsing
   - zig-ci-template for CI/CD patterns
4. **Annotate differences** between 0.14.1 and 0.15.2 with direct links to the relevant release notes.
5. **Reference community discussions** for "why" behind patterns (error handling, ownership, build idioms).
6. **Include GitHub links with line numbers** for all exemplar project citations.

---

### Summary

This reference list ensures the developer guide remains authoritative, current, and idiomatically grounded.

**The 6 Exemplar Projects** (TigerBeetle, Ghostty, Bun, ZLS, Mach, Zig stdlib) are deeply integrated throughout all 15 chapters with 476+ cited examples demonstrating production patterns. These are the primary architectural references for the guide.

**Additional Reference Projects** and **Learning Resources** provide supplementary domain-specific examples and educational materials while maintaining clear separation from the core exemplar set.

---
