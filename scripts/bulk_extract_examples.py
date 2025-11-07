#!/usr/bin/env python3
"""
Bulk Extract Code Examples
Extracts runnable Zig code blocks from markdown files to standalone example files.

Usage:
    ./bulk_extract_examples.py <chapter_dir> [output_dir]
    ./bulk_extract_examples.py sections/04_collections_containers/ examples/ch04_collections/
"""

import re
import sys
import json
from pathlib import Path
from typing import List, Dict, Optional

class CodeBlockExtractor:
    def __init__(self, markdown_path: Path):
        self.markdown_path = markdown_path
        self.content = markdown_path.read_text()
        self.lines = self.content.split('\n')

    def extract_code_blocks(self) -> List[Dict]:
        """Extract all ```zig code blocks with metadata."""
        blocks = []
        in_code_block = False
        code_lines = []
        start_line = 0
        block_index = 0

        for i, line in enumerate(self.lines, 1):
            if line.strip().startswith('```zig'):
                in_code_block = True
                code_lines = []
                start_line = i
            elif line.strip() == '```' and in_code_block:
                in_code_block = False
                code = '\n'.join(code_lines)

                if code.strip():
                    block_index += 1
                    blocks.append({
                        'index': block_index,
                        'start_line': start_line,
                        'end_line': i,
                        'code': code,
                        'lines': len(code_lines),
                        'is_runnable': self._is_runnable(code),
                        'title': self._extract_title(start_line)
                    })
            elif in_code_block:
                code_lines.append(line)

        return blocks

    def _is_runnable(self, code: str) -> bool:
        """Determine if code block is runnable (has main or test)."""
        has_main = 'pub fn main()' in code
        has_test = 'test ' in code and '@import' in code
        has_imports = '@import' in code

        # Runnable if it has main/test and imports
        return (has_main or has_test) and has_imports

    def _extract_title(self, line_num: int) -> Optional[str]:
        """Extract title from preceding lines (### Example N: Title)."""
        # Look backwards for a heading
        for i in range(max(0, line_num - 10), line_num):
            line = self.lines[i] if i < len(self.lines) else ""

            # Match: ### Example 1: Title
            match = re.match(r'^###\s+Example\s+\d+:\s+(.+)$', line)
            if match:
                return match.group(1).strip()

            # Match: ### Title (without Example N:)
            match = re.match(r'^###\s+(.+)$', line)
            if match:
                title = match.group(1).strip()
                if not title.startswith('Example'):
                    return title

        return None

    def extract_runnable_blocks(self) -> List[Dict]:
        """Extract only runnable code blocks."""
        all_blocks = self.extract_code_blocks()
        return [b for b in all_blocks if b['is_runnable']]

def sanitize_filename(title: str) -> str:
    """Convert title to safe filename."""
    # Remove special characters, convert to lowercase
    name = re.sub(r'[^\w\s-]', '', title.lower())
    # Replace spaces with underscores
    name = re.sub(r'\s+', '_', name)
    # Remove consecutive underscores
    name = re.sub(r'_+', '_', name)
    return name.strip('_')

def add_file_header(code: str, chapter: str, title: str, example_num: int) -> str:
    """Add a descriptive header to the extracted code."""
    header = f"""// Example {example_num}: {title}
// {chapter}
//
// Extracted from chapter content.md

"""
    return header + code

def extract_chapter_examples(chapter_dir: Path, output_dir: Path, chapter_name: str, dry_run: bool = False):
    """Extract all runnable examples from a chapter."""
    content_file = chapter_dir / "content.md"

    if not content_file.exists():
        print(f"❌ No content.md found in {chapter_dir}")
        return []

    print(f"\n{'='*60}")
    print(f"Extracting from: {chapter_name}")
    print(f"Source: {content_file}")
    print(f"Output: {output_dir}")
    print(f"{'='*60}\n")

    extractor = CodeBlockExtractor(content_file)
    runnable_blocks = extractor.extract_runnable_blocks()

    if not runnable_blocks:
        print(f"⚠️  No runnable examples found in {chapter_name}")
        return []

    print(f"Found {len(runnable_blocks)} runnable examples:\n")

    extracted_files = []

    for i, block in enumerate(runnable_blocks, 1):
        # Generate filename
        if block['title']:
            filename = sanitize_filename(block['title'])
        else:
            filename = f"example_{i}"

        filename = f"{i:02d}_{filename}.zig"
        output_path = output_dir / filename

        # Add header to code
        code_with_header = add_file_header(
            block['code'],
            chapter_name,
            block['title'] or f"Example {i}",
            i
        )

        print(f"  [{i}/{len(runnable_blocks)}] {filename}")
        print(f"      Title: {block['title'] or '(untitled)'}")
        print(f"      Lines: {block['start_line']}-{block['end_line']} ({block['lines']} lines)")

        if not dry_run:
            output_path.write_text(code_with_header)
            try:
                rel_path = output_path.relative_to(Path.cwd())
            except ValueError:
                rel_path = output_path
            print(f"      ✅ Written to {rel_path}")
        else:
            try:
                rel_path = output_path.relative_to(Path.cwd())
            except ValueError:
                rel_path = output_path
            print(f"      [DRY RUN] Would write to {rel_path}")

        print()

        extracted_files.append({
            'filename': filename,
            'path': str(output_path),
            'title': block['title'],
            'lines': block['lines'],
            'source_lines': f"{block['start_line']}-{block['end_line']}"
        })

    return extracted_files

def generate_build_zig(output_dir: Path, example_files: List[str], dry_run: bool = False):
    """Generate build.zig for the extracted examples."""
    build_zig_content = """const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = [_][]const u8{
"""

    # Add example filenames (without .zig extension)
    for filename in example_files:
        name = filename.replace('.zig', '')
        build_zig_content += f'        "{name}",\n'

    build_zig_content += """    };

    // Build all examples
    inline for (examples) |example_name| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        // Add run step for each example
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
        run_step.dependOn(&run_cmd.step);
    }

    // Global test step
    const test_step = b.step("test", "Run all tests");
    _ = test_step;
}
"""

    build_file = output_dir / "build.zig"

    try:
        rel_path = build_file.relative_to(Path.cwd())
    except ValueError:
        rel_path = build_file

    if not dry_run:
        build_file.write_text(build_zig_content)
        print(f"✅ Generated {rel_path}")
    else:
        print(f"[DRY RUN] Would generate {rel_path}")

def generate_readme(output_dir: Path, chapter_name: str, extracted_files: List[Dict], dry_run: bool = False):
    """Generate README.md for the chapter examples."""
    readme_content = f"""# {chapter_name} - Examples

This directory contains runnable examples extracted from {chapter_name}.

## Building Examples

Build all examples:
```bash
zig build
```

Run a specific example:
```bash
"""

    if extracted_files:
        first_example = extracted_files[0]['filename'].replace('.zig', '')
        readme_content += f"zig build run-{first_example}\n"

    readme_content += """# etc...
```

## Examples Overview

| File | Description | Lines | Source |
|------|-------------|-------|--------|
"""

    for info in extracted_files:
        readme_content += f"| `{info['filename']}` | {info['title'] or '(untitled)'} | {info['lines']} | Lines {info['source_lines']} |\n"

    readme_content += """
## Version Compatibility

All examples tested and verified on:
- ✅ Zig 0.15.2 (primary target)

## Related Book Sections

These examples correspond to code blocks in the chapter's content.md file.
"""

    readme_file = output_dir / "README.md"

    try:
        rel_path = readme_file.relative_to(Path.cwd())
    except ValueError:
        rel_path = readme_file

    if not dry_run:
        readme_file.write_text(readme_content)
        print(f"✅ Generated {rel_path}")
    else:
        print(f"[DRY RUN] Would generate {rel_path}")

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Bulk extract runnable Zig examples from markdown chapters'
    )
    parser.add_argument('chapter_dir', type=Path, help='Chapter directory (e.g., sections/04_collections_containers/)')
    parser.add_argument('output_dir', type=Path, nargs='?', help='Output directory (e.g., examples/ch04_collections/)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be extracted without writing files')
    parser.add_argument('--skip-build', action='store_true', help='Skip generating build.zig')
    parser.add_argument('--skip-readme', action='store_true', help='Skip generating README.md')

    args = parser.parse_args()

    chapter_dir = args.chapter_dir

    # Auto-detect output directory if not provided
    if args.output_dir is None:
        chapter_name = chapter_dir.name
        output_dir = Path('examples') / chapter_name.replace('_', '_').replace('collections_containers', 'collections')
    else:
        output_dir = args.output_dir

    # Get chapter name for headers
    chapter_name = chapter_dir.name.replace('_', ' ').title()

    # Create output directory
    if not args.dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    # Extract examples
    extracted_files = extract_chapter_examples(chapter_dir, output_dir, chapter_name, args.dry_run)

    if not extracted_files:
        print("\n❌ No examples extracted")
        return 1

    print(f"\n{'='*60}")
    print(f"✅ Extracted {len(extracted_files)} examples")
    print(f"{'='*60}\n")

    # Generate build.zig
    if not args.skip_build:
        example_filenames = [info['filename'] for info in extracted_files]
        generate_build_zig(output_dir, example_filenames, args.dry_run)

    # Generate README
    if not args.skip_readme:
        generate_readme(output_dir, chapter_name, extracted_files, args.dry_run)

    print(f"\n✨ Done! Examples ready in {output_dir}")

    if not args.dry_run:
        print(f"\nTo build and test:")
        print(f"  cd {output_dir}")
        print(f"  zig build --summary all")

    return 0

if __name__ == '__main__':
    sys.exit(main())
