# Zig Developer Guide — Workspace Scaffold

This repository hosts the in-progress **Zig Developer Guide** focused on idioms and best practices for Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2.

This is a comprehensive guide to Zig development. Most patterns work across all supported versions; when they differ, we clearly mark version-specific code. See [VERSIONING.md](VERSIONING.md) for version support policy and update workflow.

The guide includes **16 chapters** from "Zero to Hero" (Chapter 0) through core concepts, advanced topics, and comprehensive appendices. The `/sections` directory contains structured folders per chapter (ch00-ch15).

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

**📖 See [TODO.md](TODO.md) for detailed task tracking and progress.**

### Current State (November 9, 2025)

**✅ Beta Release Ready!** 🎉

All critical priority items complete:
- ✅ 16 chapters (ch00-ch15) - 22,353+ lines
- ✅ Chapter 0: Zero to Hero professional setup guide
- ✅ 100 Zig example files (4,430+ lines of code)
- ✅ 97+ examples, 100% compilation success on Zig 0.15.2
- ✅ Complete CI/CD pipeline (validation + GitHub Pages)
- ✅ Comprehensive proofreading (433 footnotes, 74 cross-refs validated)
- ✅ mdBook integration with automated deployment

### Next: 1.0 Release

See [TODO.md](TODO.md) for the full roadmap. High priority items:
- Additional hands-on projects
- Technical review from Zig community
- Visual diagrams for key concepts
- Exercise sections with solutions
- Final copyediting pass

---

## 🎯 What Makes This Guide Unique

This is the **only comprehensive production-focused Zig resource** for experienced developers:

- **Zero to Hero Coverage:** From first project setup (Chapter 0) through advanced topics
- **Real-World Focus:** Examples from major Zig projects (Bun, TigerBeetle, Ghostty, Mach, ZLS)
- **Production Ready:** 100% validated code examples, comprehensive CI/CD
- **Version Clarity:** Clear guidance for Zig 0.14.x and 0.15.x with version markers
- **Complete:** 16 chapters, 22,353+ lines of content, 100 Zig example files
- **Professional:** Testing, benchmarking, CI/CD, project layout, interoperability

---

## Documentation

- **[TODO.md](TODO.md)** - Project roadmap and task tracking
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute (for humans)
- **[AGENTS.md](AGENTS.md)** - AI agent instructions (for AI)
- **[VERSIONING.md](VERSIONING.md)** - Version support policy
- **[style_guide.md](style_guide.md)** - Writing standards
- **[references.md](references.md)** - Authoritative sources
