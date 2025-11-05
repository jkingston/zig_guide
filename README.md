# Zig Developer Guide — Workspace Scaffold

This repository hosts the in-progress **Zig Developer Guide** focused on idioms and best practices for Zig 0.14.0, 0.14.1, 0.15.1, and 0.15.2.

This is a comprehensive guide to Zig development. Most patterns work across all supported versions; when they differ, we clearly mark version-specific code. See [VERSIONING.md](VERSIONING.md) for version support policy and update workflow.

Each section is isolated for deep-research agent work. Agents must:
- Cite *only authoritative or clearly identified community sources.*
- Include all URLs directly in Markdown footnotes.
- Produce neutral, concise, example-driven prose.
- Use `✅ 0.15` and `🕐 0.14` to indicate version-specific content.

The `/sections` directory contains structured folders per chapter.

## Reference Repositories

This guide references several major Zig projects as exemplars of idiomatic code. Use the included script to clone/update them locally:

```bash
./scripts/update_reference_repos.sh
```

This will clone the following repositories to `./reference_repos/`:
- **zig** - Zig compiler with documentation source for all versions
- **bun**, **tigerbeetle**, **ghostty**, **mach**, **zls** - Major production projects
- **ziglings**, **zigmod**, **awesome-zig** - Learning resources and curated lists

The reference repositories are git-ignored and used for research purposes only.

## Building the Book

This guide uses [mdBook](https://rust-lang.github.io/mdBook/) for publishing.

### Prerequisites
- Install Rust and Cargo: https://rustup.rs/
- Install mdBook: `cargo install mdbook`

### Build Steps

1. **Prepare sources** (copies content from `/sections` to `/src`):
   ```bash
   ./scripts/prepare-mdbook.sh
   ```

2. **Build the book**:
   ```bash
   mdbook build
   ```
   Output will be in `book/index.html`

3. **Serve locally** (with live reload):
   ```bash
   mdbook serve --open
   ```
   Opens browser to http://localhost:3000

### Development Workflow

When editing content:
1. Edit files in `sections/XX_name/content.md`
2. Run `./scripts/prepare-mdbook.sh` to sync to `src/`
3. mdBook will auto-reload if `mdbook serve` is running

**Note:** Chapter files in `src/ch*.md` are generated and should not be edited directly.

## Project Status

This is an in-progress technical book. See [EDITORIAL_REVIEW.md](EDITORIAL_REVIEW.md) for a comprehensive assessment of content quality and publication readiness.

**Current Status:**
- ✅ 15 chapters completed (~19,674 lines)
- ✅ Comprehensive research and citations
- ✅ Production code examples from TigerBeetle, Ghostty, Bun, ZLS
- ⚠️ Code examples need systematic testing
- ⚠️ Some citation formatting needs standardization
- 🔧 Ready for community review and feedback

For implementation priorities, see [ACTION_CHECKLIST.md](ACTION_CHECKLIST.md).
