# Research Plan: Chapter 10 - Project Layout, Cross-Compilation & CI

## Document Information
- **Chapter**: 10 - Project Layout, Cross-Compilation & CI
- **Target Zig Versions**: 0.14.0, 0.14.1, 0.15.1, 0.15.2
- **Created**: 2025-11-04
- **Status**: Planning

## 1. Objectives

This research plan outlines the methodology for creating comprehensive documentation on idiomatic project organization, cross-compilation workflows, and continuous integration patterns in Zig. The chapter provides practical guidance for structuring projects and shipping production-ready software across multiple platforms.

**Primary Goals:**
1. Document idiomatic project folder structures and workspace patterns
2. Explain cross-compilation fundamentals and target specification
3. Demonstrate CI/CD integration for multi-platform builds
4. Show artifact generation and release workflows
5. Provide practical examples from production codebases
6. Cover version-specific differences in build and release patterns

**Strategic Approach:**
- Focus on practical, actionable patterns used in production projects
- Show real-world examples from TigerBeetle, Ghostty, Mach, ZLS, Bun
- Document cross-compilation workflows for common target platforms
- Demonstrate GitHub Actions and common CI systems
- Balance theory with runnable examples
- Maintain version compatibility through clear markers

## 2. Scope Definition

### In Scope

**Project Layout Topics:**
- Standard Zig project structure (src/, build.zig, build.zig.zon)
- Multi-module project organization
- Workspace patterns (monorepo, multi-package)
- File naming conventions and directory hierarchies
- Test organization (unit tests, integration tests)
- Documentation and example placement
- Asset and resource file organization

**Cross-Compilation Topics:**
- Target specification (triple notation: arch-os-abi)
- Standard target options (b.standardTargetOptions)
- CPU features and baseline specifications
- Cross-compiling from any OS to any OS
- Static vs dynamic linking considerations
- libc considerations for cross-compilation
- Common target combinations (linux-x86_64, windows-x86_64, macos-aarch64)

**CI/CD Topics:**
- GitHub Actions workflows for Zig
- Build matrices for multiple targets
- Caching strategies (zig-cache, global cache)
- Testing across platforms
- Release artifact generation
- Version tagging and release automation
- Docker integration for reproducible builds
- Common pitfalls in CI environments

### Out of Scope

- Deep dive into specific CI platform APIs (focus on patterns)
- Container orchestration beyond basic Docker usage
- Complex deployment strategies (focus on build and test)
- Package registry management (covered in Chapter 9)
- Advanced build system internals (covered in Chapter 8)
- Platform-specific deployment tooling (beyond build artifacts)

### Version-Specific Handling

**0.14.x and 0.15+ Differences:**
- Target specification API changes
- Build system module changes (covered in Chapter 8, referenced here)
- Release artifact naming conventions
- CI cache compatibility

**Common Patterns (all versions):**
- Project structure conventions are consistent
- Cross-compilation fundamentals remain the same
- CI/CD patterns apply to both versions

## 3. Core Topics

### Topic 1: Project Layout and Organization

**Concepts to Cover:**
- Standard directory structure (src/, build.zig, build.zig.zon, README.md, LICENSE)
- Source organization patterns (single file, multiple files, modules)
- Test file placement and naming conventions
- Example and documentation organization
- Resource and asset file management
- Build artifact directories (zig-out/, zig-cache/)
- Multi-package workspace patterns

**Research Sources:**
- Zig project init template (zig/lib/init/)
- TigerBeetle: Large monorepo structure
- Ghostty: Modular multi-component project
- ZLS: Tool project organization
- Mach: Multi-package engine structure
- Official Zig documentation on project structure

**Example Requirements:**
- Standard single-binary project layout
- Multi-module library project
- Workspace with multiple packages
- Test and example organization

### Topic 2: Cross-Compilation Fundamentals

**Concepts to Cover:**
- Target triple format (arch-os-abi)
- Common architectures (x86_64, aarch64, riscv64)
- Operating systems (linux, windows, macos, wasi)
- ABI variants (gnu, musl, msvc)
- CPU features and baseline configurations
- Standard target options in build.zig
- Querying available targets
- Static vs dynamic linking for cross-compilation
- libc considerations (glibc, musl, mingw)

**Research Sources:**
- Zig official documentation on cross-compilation
- zig targets command output
- TigerBeetle: Strict CPU feature requirements
- Bun: Multi-platform build configuration
- Zig compiler source: Target.zig
- Cross-compilation guides from community

**Example Requirements:**
- Basic cross-compilation build.zig
- Multi-target build matrix
- CPU feature specification
- Static binary for distribution

### Topic 3: CI/CD Integration

**Concepts to Cover:**
- GitHub Actions workflow structure
- Zig installation in CI (setup-zig action)
- Build matrix configuration (targets, optimize modes)
- Caching strategies (zig-cache, global cache, dependencies)
- Running tests across platforms
- Matrix parallelization
- Artifact upload and collection
- Release automation with GitHub Releases
- Docker for reproducible builds
- CI environment considerations

**Research Sources:**
- GitHub Actions workflows from reference repos:
  - zig/.github/workflows/
  - tigerbeetle/.github/workflows/
  - ghostty/.github/workflows/
  - zls/.github/workflows/
  - mach/.github/workflows/
- setup-zig GitHub Action documentation
- GitHub Actions caching documentation
- Community CI examples

**Example Requirements:**
- Basic CI workflow for single platform
- Multi-platform build matrix
- Release workflow with artifacts
- Docker-based reproducible build

### Topic 4: Release and Artifact Management

**Concepts to Cover:**
- Build artifact naming conventions
- Platform-specific packaging (tar.gz, zip, installers)
- Release binary optimization
- Strip and compression strategies
- Checksum generation for verification
- Version embedding in binaries
- Release note generation
- Tag-based release triggers
- Universal binaries (macOS fat binaries)
- Portable vs platform-specific builds

**Research Sources:**
- TigerBeetle: Multiversion binary packing
- Ghostty: macOS app and framework releases
- ZLS: Release pipeline with tarball generation
- Bun: Platform-specific release artifacts
- Zig compiler: Self-hosting release process
- GitHub Releases best practices

**Example Requirements:**
- Release binary build configuration
- Artifact naming and packaging
- Checksum generation script
- Multi-platform release workflow

## 4. Research Methodology

### Phase 1: Official Documentation (Priority 1, ~2 hours)

**Objective:** Establish authoritative understanding of targets, project structure, and build system.

**Tasks:**
1. Review Zig 0.15.2 documentation on targets and cross-compilation
2. Read `zig targets` output and understand target specification
3. Review official build system documentation for multi-target builds
4. Study std.Target API in standard library
5. Check release notes for cross-compilation improvements
6. Review official project init template structure

**Deliverables:**
- Notes on target specification format and options
- Understanding of standard project layout
- API references for target configuration
- Version-specific differences documented

**Validation:**
- Can explain target triple format completely
- Understand CPU feature specifications
- Know standard project structure conventions

### Phase 2: Project Structure Analysis (Priority 1, ~3 hours)

**Objective:** Extract project organization patterns from production codebases.

**Tasks:**
1. **Zig Compiler**: Analyze self-hosting project structure
   - Root structure: lib/, src/, test/, doc/
   - Build system organization
   - Documentation placement
2. **TigerBeetle**: Large monorepo patterns
   - Source organization: src/ subdirectories
   - Test structure
   - CI integration
   - TIGER_STYLE.md guidelines
3. **Ghostty**: Modular multi-component project
   - Component organization
   - Resource management
   - Platform-specific code layout
4. **ZLS**: Tool project structure
   - Binary + library pattern
   - Test organization
   - Release structure
5. **Mach**: Multi-package workspace
   - Package organization
   - Cross-package dependencies
   - Example placement

**Deliverables:**
- Directory tree diagrams for each project
- Common patterns and conventions
- Project-specific organizational strategies
- Best practices from style guides

**Validation:**
- Identified 3-5 common layout patterns
- Documented project-specific variations
- Can explain rationale for different structures

### Phase 3: Cross-Compilation Patterns (Priority 1, ~3 hours)

**Objective:** Document cross-compilation workflows and target configurations.

**Tasks:**
1. Run `zig targets` and document output structure
2. Study Target.zig in Zig standard library source
3. Analyze cross-compilation patterns in reference projects:
   - TigerBeetle: CPU feature enforcement
   - Bun: Custom target resolution
   - Mach: Platform-specific linking
   - Ghostty: Universal binary generation
4. Test cross-compilation from Linux to various targets:
   - linux-x86_64 (native)
   - linux-aarch64
   - windows-x86_64
   - macos-aarch64 (if possible)
   - wasi-wasm32
5. Document libc considerations (glibc, musl, mingw)
6. Explore static vs dynamic linking implications

**Deliverables:**
- Target specification reference table
- Cross-compilation examples (working code)
- Notes on platform-specific considerations
- Common pitfalls and solutions

**Validation:**
- Successfully cross-compiled to 3+ targets
- Understand libc linking implications
- Can explain CPU feature requirements

### Phase 4: CI/CD Workflow Analysis (Priority 1, ~4 hours)

**Objective:** Extract CI/CD patterns from production projects.

**Tasks:**
1. **Analyze GitHub Actions workflows:**
   - zig/.github/workflows/ci.yml
   - tigerbeetle/.github/workflows/ (all workflows)
   - ghostty/.github/workflows/
   - zls/.github/workflows/release.yml
   - mach/.github/workflows/
2. **Document common patterns:**
   - Zig installation methods (setup-zig, manual)
   - Matrix strategy configurations
   - Caching approaches
   - Test execution patterns
   - Artifact upload strategies
3. **Study release workflows:**
   - Tag-based triggers
   - Multi-platform artifact generation
   - Checksum generation
   - Release note automation
4. **Examine Docker usage:**
   - Reproducible build containers
   - CI image definitions
   - Cache volume strategies

**Deliverables:**
- 10+ GitHub workflow file links with analysis
- Common CI patterns documented
- Best practices for caching and parallelization
- Release automation patterns
- Docker integration examples

**Validation:**
- Found concrete examples of each pattern
- Can write basic CI workflow from scratch
- Understand caching strategies

### Phase 5: Release Engineering Patterns (Priority 2, ~2 hours)

**Objective:** Document release artifact generation and management.

**Tasks:**
1. Study release processes in reference projects:
   - Zig compiler: Self-hosting release
   - TigerBeetle: Multiversion binary packing
   - ZLS: Tarball generation with release.json
   - Ghostty: macOS app bundling
   - Bun: Platform-specific packaging
2. Document artifact naming conventions
3. Study binary optimization techniques:
   - Strip symbols
   - Compression methods
   - Checksum generation
4. Review version embedding patterns
5. Examine universal binary generation (macOS)

**Deliverables:**
- Release workflow patterns
- Artifact naming conventions
- Optimization and packaging strategies
- Version embedding techniques

**Validation:**
- Understand complete release pipeline
- Can generate production-ready artifacts
- Know platform-specific requirements

### Phase 6: Code Examples (Priority 1, ~4 hours)

**Objective:** Create 4-6 runnable, well-documented code examples.

**Examples to Create:**

1. **example_standard_layout/** (~project structure)
   - Demonstrate idiomatic project organization
   - src/, build.zig, build.zig.zon
   - Test organization
   - README and LICENSE
   - Basic build.zig

2. **example_cross_compile.zig** (~80-120 lines)
   - Multi-target build.zig
   - Target specification
   - CPU feature configuration
   - Install artifacts per target
   - Cross-compilation demonstration

3. **example_ci_basic.yml** (GitHub Actions workflow)
   - Single platform CI
   - Build and test
   - Caching configuration
   - ~40-60 lines

4. **example_ci_matrix.yml** (GitHub Actions workflow)
   - Multi-platform matrix
   - Multiple targets and optimize modes
   - Parallel execution
   - Artifact upload
   - ~80-120 lines

5. **example_release.yml** (GitHub Actions workflow)
   - Tag-triggered release
   - Multi-platform artifact generation
   - Checksum creation
   - GitHub Release upload
   - ~100-150 lines

6. **example_workspace/** (~project structure)
   - Multi-package workspace
   - Shared dependencies
   - Local path dependencies
   - Workspace build patterns

**Quality Requirements:**
- All build.zig examples compile without warnings on Zig 0.15.2
- Examples include clear comments explaining concepts
- Each example is self-contained or has clear dependencies
- Code follows project style_guide.md
- CI examples are based on real production patterns

**Testing Process:**
1. Write example code
2. Compile with Zig 0.15.2 (and 0.14.1 where applicable)
3. Verify expected behavior
4. Document any platform-specific considerations
5. Add explanatory comments

### Phase 7: Research Notes Synthesis (Priority 1, ~3 hours)

**Objective:** Consolidate all research findings into comprehensive research_notes.md.

**Structure:**
1. Introduction and scope
2. Project layout conventions
3. Cross-compilation fundamentals
4. Target specification reference
5. CI/CD patterns and workflows
6. Release and artifact management
7. Production patterns from exemplar projects
8. Common pitfalls
9. Version differences (0.14.x vs 0.15+)
10. Code examples summary
11. Sources and references (20+ citations)

**Quality Requirements:**
- 1500+ lines of detailed notes
- 20+ deep GitHub links to production code/workflows
- All claims cited with authoritative sources
- Clear version-specific guidance
- Organized for easy reference during writing

### Phase 8: Content Writing (Priority 1, ~4 hours)

**Objective:** Create publication-ready content.md chapter.

**Structure (from prompt.md):**
1. **Overview** - Purpose and importance of project organization and cross-compilation
2. **Core Concepts** - Example-driven teaching of key ideas
3. **Code Examples** - 4-6 runnable snippets with explanations
4. **Common Pitfalls** - 4-5 frequent mistakes and safer alternatives
5. **In Practice** - Real-world usage from reference repos
6. **Summary** - Mental model reinforcement
7. **References** - Numbered list of all citations (15+)

**Content Requirements:**
- 1000-1500 lines
- Follow style_guide.md (neutral, professional, no contractions)
- Version markers: 🕐 0.14.x, ✅ 0.15+ (where applicable)
- Inline code examples with syntax highlighting
- Deep GitHub links (20+)
- Authoritative citations (15+)
- Practical, actionable guidance

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

### 0.14.x Support

**Approach:**
- Most project layout patterns are version-agnostic
- Build system references should link to Chapter 8
- Note any build.zig API differences (module system)
- Cross-compilation fundamentals are consistent

**Testing:**
- Verify build.zig examples work on 0.14.1
- Note any API changes in target specification

### 0.15+ Support (Current)

**Approach:**
- Mark modern build system patterns with ✅ 0.15+
- Show module system integration where relevant
- All main examples target 0.15.2
- Reference Chapter 8 for build system details

**Testing:**
- Compile all examples with Zig 0.15.2
- Verify cross-compilation workflows
- Test CI examples (where possible)

### Breaking Changes to Address

**Build System Changes:**
- Module system integration (refer to Chapter 8)
- Target specification API (if changed)
- Artifact installation patterns

**Project Structure:**
- build.zig.zon fingerprint requirement (0.15+)
- Any directory convention changes

## 6. Code Example Specifications

### Example 1: example_standard_layout/

**Purpose:** Demonstrate idiomatic Zig project structure.

**Content:**
- Complete project with standard layout
- src/main.zig (executable)
- src/lib.zig (library)
- build.zig with library and executable
- build.zig.zon with metadata
- README.md and LICENSE
- .gitignore

**Concepts Illustrated:**
- Standard directory structure
- Separation of library and executable
- Basic build configuration
- Documentation and licensing

**Structure:**
```
example_standard_layout/
├── build.zig
├── build.zig.zon
├── README.md
├── LICENSE
├── .gitignore
└── src/
    ├── main.zig
    └── lib.zig
```

### Example 2: example_cross_compile.zig

**Purpose:** Multi-target cross-compilation build.zig.

**Content:**
- Target specification patterns
- Multiple target builds
- CPU feature configuration
- Per-target artifact installation
- Static linking configuration

**Concepts Illustrated:**
- Cross-compilation setup
- Target iteration patterns
- Build matrix in build.zig
- Artifact naming conventions

**Expected Output:**
Multiple binaries in zig-out/bin/:
```
myapp-x86_64-linux
myapp-aarch64-linux
myapp-x86_64-windows.exe
myapp-aarch64-macos
```

**Estimated Lines:** 80-120

### Example 3: example_ci_basic.yml

**Purpose:** Basic CI workflow for Zig projects.

**Content:**
- GitHub Actions workflow structure
- Zig installation with setup-zig
- Build and test steps
- Cache configuration
- Single platform (ubuntu-latest)

**Concepts Illustrated:**
- CI workflow basics
- Zig installation in CI
- Caching strategies
- Test execution

**Estimated Lines:** 40-60

### Example 4: example_ci_matrix.yml

**Purpose:** Multi-platform CI with build matrix.

**Content:**
- Matrix strategy configuration
- Multiple OS platforms (ubuntu, macos, windows)
- Multiple targets and optimize modes
- Parallel execution
- Artifact upload
- Cache sharing across jobs

**Concepts Illustrated:**
- Build matrix patterns
- Multi-platform testing
- Artifact collection
- CI parallelization

**Estimated Lines:** 80-120

### Example 5: example_release.yml

**Purpose:** Complete release workflow with artifacts.

**Content:**
- Tag-based trigger
- Multi-platform artifact generation
- Binary optimization (ReleaseFast, strip)
- Checksum generation
- Artifact packaging (tar.gz, zip)
- GitHub Release creation
- Version embedding

**Concepts Illustrated:**
- Release automation
- Multi-platform artifact generation
- Secure artifact distribution
- Version management

**Estimated Lines:** 100-150

### Example 6: example_workspace/

**Purpose:** Multi-package workspace organization.

**Content:**
- Monorepo structure with multiple packages
- Shared dependencies via build.zig.zon
- Local path dependencies
- Cross-package module imports
- Workspace-level build configuration

**Concepts Illustrated:**
- Workspace patterns
- Package organization
- Dependency management in monorepos
- Build coordination

**Structure:**
```
example_workspace/
├── build.zig
├── build.zig.zon
├── packages/
│   ├── core/
│   │   ├── build.zig
│   │   ├── build.zig.zon
│   │   └── src/
│   └── app/
│       ├── build.zig
│       ├── build.zig.zon
│       └── src/
└── README.md
```

## 7. Source Documentation

### Official Zig Sources (Priority 1)

1. **Zig 0.15.2 Documentation**
   - URL: https://ziglang.org/documentation/0.15.2/
   - Sections: Build System, Targets, Cross-Compilation
   - Focus: Target specification, build.zig patterns

2. **Zig Standard Library Source**
   - Path: zig-0.15.2/lib/std/
   - Files: Target.zig, Build.zig
   - Method: Direct source code reading

3. **Zig Project Init Template**
   - Path: zig/lib/init/
   - Files: build.zig, build.zig.zon
   - Focus: Standard project structure

4. **zig targets Command**
   - Run: `zig targets | jq`
   - Documentation: Available targets, architectures, OSes, ABIs

### Exemplar Projects (Priority 1)

1. **Zig Compiler**
   - Repository structure analysis
   - Self-hosting build patterns
   - CI workflows: .github/workflows/

2. **TigerBeetle**
   - Path: /home/jack/workspace/zig_guide/reference_repos/tigerbeetle/
   - Files: build.zig (multiversion builds), TIGER_STYLE.md
   - CI: .github/workflows/ci.yml
   - Focus: Strict CPU requirements, monorepo structure

3. **Ghostty**
   - Path: /home/jack/workspace/zig_guide/reference_repos/ghostty/
   - Files: build.zig (modular), project structure
   - CI: .github/workflows/
   - Focus: Multi-component organization, macOS universals

4. **ZLS**
   - Path: /home/jack/workspace/zig_guide/reference_repos/zls/
   - Files: build.zig, release pipeline
   - CI: .github/workflows/release.yml
   - Focus: Tool project structure, release automation

5. **Mach**
   - Repository: https://github.com/hexops/mach
   - Focus: Multi-package workspace, engine structure
   - CI: GitHub Actions workflows

6. **Bun**
   - Path: /home/jack/workspace/zig_guide/reference_repos/bun/
   - Files: build.zig (custom target resolution)
   - Focus: Multi-platform builds, large project organization

### CI/CD Resources (Priority 1)

1. **setup-zig GitHub Action**
   - Repository: https://github.com/goto-bus-stop/setup-zig
   - Documentation: Zig installation in CI
   - Usage patterns

2. **GitHub Actions Documentation**
   - Caching: https://docs.github.com/en/actions/using-workflows/caching-dependencies
   - Matrix builds: https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
   - Artifact upload: https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts

### Community Resources (Priority 2)

1. **Zig.guide**
   - URL: https://zig.guide/
   - Sections: Build system, project structure
   - Method: WebFetch for current content

2. **ziggit.dev**
   - Search: project organization, cross-compilation
   - Focus: Community patterns and discussions

## 8. Common Pitfalls to Document

### Project Layout Pitfalls

1. **Inconsistent Directory Structure**
   - Problem: Non-standard layouts confuse contributors
   - Solution: Follow zig init template conventions
   - Example: src/ for sources, not lib/ or code/

2. **Missing Essential Files**
   - Problem: No README, LICENSE, or .gitignore
   - Solution: Include standard project files
   - Example: Template .gitignore with zig-cache/, zig-out/

3. **Test Organization Confusion**
   - Problem: Tests scattered or inconsistently named
   - Solution: Co-locate tests with source or use test/ directory
   - Example: Standard test file naming

### Cross-Compilation Pitfalls

4. **Incorrect Target Specification**
   - Problem: Malformed target triples
   - Solution: Use zig targets to verify format
   - Example: x86_64-linux-gnu (correct) vs x86_64-linux (incomplete)

5. **libc Linking Issues**
   - Problem: Assuming glibc availability on all systems
   - Solution: Use musl for static Linux builds, consider bundling libc
   - Example: Static musl builds for portability

6. **CPU Feature Mismatches**
   - Problem: Binary requires features not available on target
   - Solution: Specify baseline CPU or test on actual hardware
   - Example: TigerBeetle x86_64_v3+aes requirement

7. **Dynamic Library Dependencies**
   - Problem: Missing shared libraries on target system
   - Solution: Static linking for distribution binaries
   - Example: Link mode configuration

### CI/CD Pitfalls

8. **Poor Cache Configuration**
   - Problem: Slow CI due to missing or incorrect caching
   - Solution: Cache zig-cache/ and global cache appropriately
   - Example: Proper cache key with Zig version and lockfile

9. **Matrix Explosion**
   - Problem: Too many combinations slow down CI
   - Solution: Focus on critical targets, use strategy.fail-fast
   - Example: Core targets only (linux, macos, windows)

10. **Missing Test on Actual Platforms**
    - Problem: Cross-compiled binaries not tested on target OS
    - Solution: Use platform-native runners for testing
    - Example: Test macos binaries on macos-latest runner

## 9. Validation Criteria

### Research Quality

- [ ] All claims cited with authoritative sources
- [ ] 20+ deep GitHub links to production code/workflows
- [ ] 15+ numbered references in bibliography
- [ ] Version-specific behavior documented
- [ ] Project structure patterns verified in multiple repos

### Code Quality

- [ ] All build.zig examples compile without warnings on Zig 0.15.2
- [ ] Cross-compilation examples produce working binaries
- [ ] Code follows project style_guide.md
- [ ] Comments explain concepts clearly
- [ ] CI examples based on real production patterns

### Content Quality

- [ ] Chapter structure matches prompt.md requirements
- [ ] Style guide compliance (neutral, professional tone)
- [ ] Version markers used consistently (where applicable)
- [ ] 4-6 complete examples documented
- [ ] Practical guidance for shipping software
- [ ] Clear explanation of cross-compilation workflows

### Completeness

- [ ] All core topics covered
- [ ] 4-6 runnable code examples or project templates
- [ ] Production patterns from exemplar projects
- [ ] CI/CD workflows documented
- [ ] Release engineering patterns explained
- [ ] Common pitfalls addressed

## 10. Timeline and Milestones

### Day 1: Research (8 hours)
- Phase 1: Official documentation (2 hours)
- Phase 2: Project structure analysis (3 hours)
- Phase 3: Cross-compilation patterns (3 hours)

**Milestone:** Understanding of project layouts, target specification, basic cross-compilation

### Day 2: Analysis and CI (8 hours)
- Phase 4: CI/CD workflow analysis (4 hours)
- Phase 5: Release engineering patterns (2 hours)
- Phase 6: Start code examples (2 hours)

**Milestone:** 10+ CI workflow links collected, release patterns documented

### Day 3: Examples and Writing (8 hours)
- Phase 6: Complete code examples (3 hours)
- Phase 7: Write research_notes.md (3 hours)
- Phase 8: Start content.md (2 hours)

**Milestone:** All examples working, comprehensive research notes

### Day 4: Content and Review (4 hours)
- Phase 8: Complete content.md (3 hours)
- Final review and validation (1 hour)

**Milestone:** Publication-ready chapter with all requirements met

**Total Estimated Time:** 28 hours (spread over 4 days)

## 11. Success Metrics

### Quantitative Metrics

- [ ] 4-6 runnable code examples or project templates created
- [ ] 1000-1500 lines in content.md
- [ ] 1500+ lines in research_notes.md
- [ ] 20+ deep GitHub links to production code/workflows
- [ ] 15+ authoritative citations
- [ ] 4-5 common pitfalls documented
- [ ] 0 compilation warnings on Zig 0.15.2

### Qualitative Metrics

- [ ] Clear explanation of cross-compilation fundamentals
- [ ] Practical CI/CD workflows ready to use
- [ ] Reader can structure projects idiomatically
- [ ] Code examples demonstrate real-world patterns
- [ ] Production examples show best practices
- [ ] Release workflows are actionable

### User Outcomes

After reading this chapter, users should be able to:
- [ ] Structure Zig projects idiomatically
- [ ] Cross-compile to multiple targets
- [ ] Set up CI/CD for Zig projects
- [ ] Configure build matrices for multi-platform testing
- [ ] Generate release artifacts properly
- [ ] Understand target specifications
- [ ] Choose appropriate linking modes
- [ ] Implement release automation
- [ ] Organize multi-package workspaces

## 12. Risk Mitigation

### Risk 1: CI Platform Specificity

**Risk:** Focus too heavily on GitHub Actions, limiting applicability.

**Mitigation:**
- Document general CI/CD patterns applicable to any platform
- Focus on concepts: caching, matrices, artifacts
- Mention other platforms (GitLab CI, Jenkins) in passing
- Patterns should be transferable

### Risk 2: Cross-Compilation Testing Limitations

**Risk:** Cannot test all target platforms on development machine.

**Mitigation:**
- Document expected behavior for untested platforms
- Reference production examples from reference repos
- Explain verification strategies (checksums, QEMU)
- Focus on build system configuration over runtime testing

### Risk 3: Rapidly Changing CI Best Practices

**Risk:** CI/CD patterns may evolve quickly.

**Mitigation:**
- Focus on fundamental patterns, not API details
- Use current production examples as reference
- Document principles over specific syntax
- Version-date the CI examples

### Risk 4: Complex Release Engineering

**Risk:** Release workflows may be too complex for tutorial.

**Mitigation:**
- Start with simple examples
- Build complexity gradually
- Reference production workflows for advanced patterns
- Provide links to complete examples in reference repos

## 13. Research Questions

These questions will guide the research and should be answered by the end:

1. **What is the standard Zig project structure?**
   - What directories are conventional?
   - Where do tests go?
   - How are examples organized?

2. **How do you specify cross-compilation targets?**
   - What is the target triple format?
   - How do you configure CPU features?
   - What are libc considerations?

3. **What CI/CD patterns are common in Zig projects?**
   - How is Zig installed in CI?
   - What caching strategies work best?
   - How are build matrices configured?

4. **How do production projects organize their code?**
   - Single-binary vs multi-package?
   - Monorepo vs multi-repo?
   - Module organization patterns?

5. **What are the best practices for release artifacts?**
   - Naming conventions?
   - Packaging formats?
   - Checksum generation?

6. **How do you handle multi-platform releases?**
   - Artifact generation per platform?
   - Universal binaries (macOS)?
   - Platform-specific considerations?

7. **What are common cross-compilation pitfalls?**
   - libc issues?
   - CPU feature problems?
   - Dynamic library dependencies?

## 14. Notes and Observations

*This section will be populated during research with insights, interesting findings, and important observations that don't fit elsewhere.*

### Initial Observations

- Cross-compilation is a first-class feature in Zig (unlike many languages)
- Most production projects follow similar directory structures
- CI/CD patterns are fairly consistent across projects
- GitHub Actions dominates as CI platform in Zig ecosystem
- Release engineering varies significantly by project type

### Key Differentiators

- TigerBeetle: Extremely strict about CPU features and determinism
- Ghostty: Complex macOS-specific release artifacts
- ZLS: Excellent example of release automation
- Zig compiler: Self-hosting adds unique constraints

---

**Document Status:** ✅ Complete - Ready for execution
**Next Step:** Begin Phase 1 - Official Documentation Research
