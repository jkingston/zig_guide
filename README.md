# Zig: Zero to Hero — Workspace Scaffold

This repository hosts the in-progress **Zig: Zero to Hero** guide focused on idioms and best practices for Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2.

This is a comprehensive guide to Zig development. Most patterns work across all supported versions; when they differ, we clearly mark version-specific code. See [versioning.md](versioning.md) for version support policy and update workflow.

The guide includes **15 chapters** covering Quick Start through Appendices (including Migration Guide). The `/sections` directory contains structured folders for select chapters.

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

### Current State (November 11, 2025)

**✅ Beta Release Ready!** 🎉

All critical priority items complete:
- ✅ 15 chapters (Quick Start through Appendices) - ~22,000+ lines
- ✅ Introduction with Quick Start guide
- ✅ 100 Zig example files (4,430+ lines of code)
- ✅ 97+ examples, 100% compilation success on Zig 0.15.2
- ✅ Complete CI/CD pipeline (validation + GitHub Pages)
- ✅ Comprehensive proofreading (433 footnotes, 74 cross-refs validated)
- ✅ mdBook integration with automated deployment

### Next: 1.0 Release

See [todo.md](todo.md) for the full roadmap. High priority items:
- Additional hands-on projects
- Technical review from Zig community
- Visual diagrams for key concepts
- Exercise sections with solutions
- Final copyediting pass

---

## 🎯 What Makes This Guide Unique

This is the **only comprehensive production-focused Zig resource** for experienced developers:

- **Zero to Hero Coverage:** From Quick Start guide through advanced topics
- **Real-World Focus:** Examples from major Zig projects (Bun, TigerBeetle, Ghostty, Mach, ZLS)
- **Production Ready:** 100% validated code examples, comprehensive CI/CD
- **Version Clarity:** Clear guidance for Zig 0.14.x and 0.15.x with version markers
- **Complete:** 15 chapters, 22,353+ lines of content, 100 Zig example files
- **Professional:** Testing, benchmarking, CI/CD, project layout, interoperability

---

## Documentation

- **[todo.md](todo.md)** - Project roadmap and task tracking
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute (for humans)
- **[AGENTS.md](AGENTS.md)** - AI agent instructions (for AI)
- **[versioning.md](versioning.md)** - Version support policy
- **[style_guide.md](style_guide.md)** - Writing standards
- **[references.md](references.md)** - Authoritative sources
