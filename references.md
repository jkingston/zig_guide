# Zig Developer Guide — Reference & Exemplars

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

## 4. Major Projects Written in Zig (Exemplars)

> Each of these serves as a large-scale example of idiomatic Zig use — for FFI, async design, build tooling, and code organization.

| Project                                                          | Description                                                                                                                                              |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[Bun](https://github.com/oven-sh/bun)**                        | JavaScript runtime, bundler, and package manager implemented largely in Zig. Demonstrates async I/O, concurrency, and FFI idioms.                        |
| **[TigerBeetle](https://github.com/tigerbeetle/tigerbeetle)**    | Distributed financial transaction database. Exemplifies correctness-first design, testing strategy, and data-integrity patterns.                         |
| **[Ghostty](https://github.com/ghostty-org/ghostty)**            | GPU-accelerated terminal emulator by Mitchell Hashimoto. Excellent reference for cross-platform abstractions, C/Swift interop, and modular architecture. |
| **[Mach](https://github.com/hexops/mach)**                       | Game and multimedia framework ecosystem. Demonstrates modular API design and `zig build` idioms.                                                         |
| **[ZLS – Zig Language Server](https://github.com/zigtools/zls)** | Tooling example showing modular design, build integration, and incremental compilation.                                                                  |
| **[NCDU 2](https://dev.yorhel.nl/ncdu)**                         | Disk usage analyzer rewritten in Zig. Compact, idiomatic CLI structure.                                                                                  |
| **[ZigMod](https://github.com/nektro/zigmod)**                   | Package/dependency manager for Zig projects; showcases extensible build scripts and dependency resolution.                                               |
| **[Ziglings](https://github.com/ratfactor/ziglings)**            | (Also above) – reference for idiomatic syntax and progressive code patterns.                                                                             |
| **[zig-gamedev](https://github.com/michal-z/zig-gamedev)**       | Graphics and game development libraries. Complex C/C++ interop, sophisticated multi-library build patterns, and cross-platform abstractions.             |
| **[zig-ci-template](https://github.com/ziglang/zig-bootstrap)**  | Official CI configuration examples. Matrix builds, cross-compilation workflows, and artifact caching strategies.                                          |
| **[zap](https://github.com/zigzap/zap)**                         | High-performance HTTP server framework. Production event loop patterns, middleware architecture, and efficient request/response handling.                |
| **[zigimg](https://github.com/zigimg/zigimg)**                   | Image encoding/decoding library. Structured binary I/O, format parsing, streaming decoders, and allocator usage patterns.                                |
| **[zigup](https://github.com/marler8997/zigup)**                 | Zig version manager. Cross-platform CLI patterns, filesystem operations, HTTP downloads, and version lifecycle management.                               |

---

## 5. Curated Project Lists

| Resource                                                   | Description                                                             |
| ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| **[Awesome Zig](https://github.com/zigcc/awesome-zig)**    | Curated index of Zig libraries, tools, games, and applications.         |
| **[Awesome Mach](https://github.com/hexops/awesome-mach)** | Supplementary list focused on the Mach ecosystem (graphics & game dev). |

---

## 6. Version-Specific Release Notes

> For cross-version best-practice commentary, refer to these release notes when identifying behavioral or standard-library changes between 0.14 and 0.15.

| Version                                                              | Date       | Notes                                                                                      |
| -------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------ |
| **[0.15.2](https://ziggit.dev/t/zig-0-15-2-released/12466/6)**       | 2025-10-11 | Most recent stable at time of writing — minor fixes and stability improvements.            |
| **[0.15.1](https://ziglang.org/download/0.15.1/release-notes.html)** | 2025-08-19 | Introduced incremental build enhancements and diagnostic improvements.                     |
| **[0.15.0](https://ziglang.org/download/0.15.0/release-notes.html)** | (retracted) | **Retracted** — never officially released. Use 0.15.1 instead.                            |
| **[0.14.1](https://ziglang.org/download/0.14.1/release-notes.html)** | 2025-05-21 | Bug-fix release for 0.14; widely used baseline for many production projects.               |
| **[0.14.0](https://ziglang.org/download/0.14.0/release-notes.html)** | 2025-03-05 | Major feature update: improved build system, incremental compilation, x86 backend rewrite. |

---

## 7. Suggested Use in the Developer Guide

When building the *Zig Developer Guide* itself:

1. **Cite official docs** for any syntax or standard-library feature.
2. **Pull idioms** and code examples primarily from
   - Zig by Example
   - Ziglings
   - TigerBeetle, Ghostty, and zap codebases
   - zig-gamedev for complex build patterns
   - zigimg for binary I/O and format parsing
3. **Annotate differences** between 0.14.1 and 0.15.2 with direct links to the relevant release notes.
4. **Reference community discussions** for "why" behind patterns (error handling, ownership, build idioms).
5. **Cross-link** to real projects in the "Exemplars" section whenever illustrating a best practice.
6. **Use zig-ci-template** as canonical reference for CI/CD patterns and cross-compilation workflows.

---

### Summary

This reference list ensures the developer guide remains authoritative, current, and idiomatically grounded.
By combining official documentation with living examples (TigerBeetle, Ghostty, Bun, Mach, ZLS, zap, zig-gamedev, zigimg),
the guide will align with community consensus while documenting version-specific differences across Zig 0.14.1 → 0.15.2.

---
