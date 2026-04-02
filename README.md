# Zig: Zero to Hero — Workspace Scaffold

This repository hosts the in-progress **Zig: Zero to Hero** guide focused on modern Zig idioms and best practices for **Zig 0.16.0-dev**.

This is a comprehensive guide to Zig development teaching current best practices. All code examples and runnable programs target Zig 0.16.0-dev (tracking `master`). APIs may shift before the 0.16.0 stable release. For users on older versions, migration guidance is provided in the appendices (Appendix A & B for 0.14.x, Appendix C for 0.15.x). See [versioning.md](versioning.md) for version support policy.

The guide includes **14 chapters** covering Quick Start through Logging/Diagnostics, plus **4 appendices** (0.14.1 Quick Reference, Migration 0.14→0.15, Migration 0.15→0.16, Reference Material).

## Quick Start

```bash
# Build all examples
zig build

# Build the book
bash scripts/prepare-mdbook.sh
mdbook build

# Serve locally
mdbook serve
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development instructions.

## Project Status

**📖 See [todo.md](todo.md) for detailed task tracking and progress.**

### Current State (April 2026)

**✅ Beta Release Ready!**

All critical priority items complete:
- ✅ 15 chapters (Quick Start through Appendices) - ~22,000+ lines
- ✅ Introduction with Quick Start guide
- ✅ 101 Zig example files (4,430+ lines of code)
- ✅ 92 complete programs semantically validated via `zig build-obj` on Zig 0.16.0-dev
- ✅ Complete CI/CD pipeline (example validation + inline code block validation + GitHub Pages)
- ✅ Comprehensive proofreading (433 footnotes, 74 cross-refs validated)
- ✅ mdBook integration with automated deployment
- ✅ Codeberg link migration (Zig repo moved from GitHub, Nov 2025)
- ✅ 7 exemplar projects: TigerBeetle, Ghostty, Bun, ZLS, Mach, Lightpanda, zap
- ✅ 0.16.0-dev update: process.Init, std.Io, DebugAllocator, Appendix C migration guide

### Next: 1.0 Release

See [todo.md](todo.md) for the full roadmap. High priority items:
- Re-validate on Zig 0.16.0 stable when released
- Additional hands-on projects
- Technical review from Zig community
- Visual diagrams for key concepts
- Exercise sections with solutions

---

## 🎯 What Makes This Guide Unique

This is the **only comprehensive production-focused Zig resource** for experienced developers:

- **Zero to Hero Coverage:** From Quick Start guide through advanced topics
- **Real-World Focus:** Examples from major Zig projects (Bun, TigerBeetle, Ghostty, Mach, ZLS, Lightpanda)
- **Production Ready:** 92 programs semantically compiled on Zig 0.16.0-dev, comprehensive CI/CD
- **Modern & Focused:** Teaches current best practices (Zig 0.16.0-dev) with migration support
- **Complete:** 14 chapters + 4 appendices, 22,000+ lines of content, 100 Zig example files
- **Professional:** Testing, benchmarking, CI/CD, project layout, interoperability

---

## Documentation

- **[todo.md](todo.md)** - Project roadmap and task tracking
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute (for humans)
- **[AGENTS.md](AGENTS.md)** - AI agent instructions (for AI)
- **[versioning.md](versioning.md)** - Version support policy
- **[style_guide.md](style_guide.md)** - Writing standards
- **[references.md](references.md)** - Authoritative sources
