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
