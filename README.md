# Zig: Zero to Hero — Workspace Scaffold

This repository hosts the in-progress **Zig: Zero to Hero** guide focused on modern Zig idioms and best practices for **Zig 0.15.2**.

This is a comprehensive guide to Zig development teaching current best practices. All code examples and runnable programs target Zig 0.15.2. For users on Zig 0.14.1, migration guidance is provided in Appendix A & B. See [versioning.md](versioning.md) for version support policy.

The guide includes **14 chapters** covering Quick Start through Logging/Diagnostics, plus **3 appendices** (0.14.1 Quick Reference, Migration 0.14→0.15, Reference Material). A draft [Appendix C](appendix_c_migration_015_016.md) covering the 0.15→0.16 migration is available on the `update/zig-0.16` branch.

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

### Current State (March 2026)

**✅ Beta Release Ready!** 🎉

All critical priority items complete:
- ✅ 15 chapters (Quick Start through Appendices) - ~22,000+ lines
- ✅ Introduction with Quick Start guide
- ✅ 101 Zig example files (4,430+ lines of code)
- ✅ 87 complete programs validated via `zig ast-check` on Zig 0.15.2
- ✅ Complete CI/CD pipeline (example validation + inline code block validation + GitHub Pages)
- ✅ Comprehensive proofreading (433 footnotes, 74 cross-refs validated)
- ✅ mdBook integration with automated deployment
- ✅ Codeberg link migration (Zig repo moved from GitHub, Nov 2025)
- ✅ 7 exemplar projects: TigerBeetle, Ghostty, Bun, ZLS, Mach, Lightpanda, zap

### Next: 1.0 Release

See [todo.md](todo.md) for the full roadmap. High priority items:
- Zig 0.16.0 update (draft migration guide on `update/zig-0.16` branch)
- Additional hands-on projects
- Technical review from Zig community
- Visual diagrams for key concepts
- Exercise sections with solutions

---

## 🎯 What Makes This Guide Unique

This is the **only comprehensive production-focused Zig resource** for experienced developers:

- **Zero to Hero Coverage:** From Quick Start guide through advanced topics
- **Real-World Focus:** Examples from major Zig projects (Bun, TigerBeetle, Ghostty, Mach, ZLS, Lightpanda)
- **Production Ready:** 100% validated code examples on Zig 0.15.2, comprehensive CI/CD
- **Modern & Focused:** Teaches current best practices (Zig 0.15.2) with migration support
- **Complete:** 14 chapters + 3 appendices, 22,000+ lines of content, 100 Zig example files
- **Professional:** Testing, benchmarking, CI/CD, project layout, interoperability

---

## Documentation

- **[todo.md](todo.md)** - Project roadmap and task tracking
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute (for humans)
- **[AGENTS.md](AGENTS.md)** - AI agent instructions (for AI)
- **[versioning.md](versioning.md)** - Version support policy
- **[style_guide.md](style_guide.md)** - Writing standards
- **[references.md](references.md)** - Authoritative sources
