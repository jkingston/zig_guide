#!/usr/bin/env python3
"""
Extract and analyze code blocks from Zig Developer Guide markdown files.
Used by CI to track code block statistics and potential issues.
"""

import re
import sys
import json
from pathlib import Path
from collections import defaultdict

def extract_code_blocks(md_content):
    """Extract all code blocks from markdown content."""
    # Match code blocks: ```lang\n...\n```
    pattern = r'```(\w+)?\n(.*?)```'
    matches = re.findall(pattern, md_content, re.DOTALL)

    blocks = []
    for lang, code in matches:
        blocks.append({
            'language': lang if lang else 'none',
            'code': code,
            'lines': len(code.split('\n'))
        })

    return blocks

def analyze_chapter(chapter_path):
    """Analyze code blocks in a chapter."""
    content_file = chapter_path / 'content.md'

    if not content_file.exists():
        return None

    with open(content_file, 'r', encoding='utf-8') as f:
        content = f.read()

    blocks = extract_code_blocks(content)

    # Count by language
    lang_counts = defaultdict(int)
    total_lines = 0

    for block in blocks:
        lang_counts[block['language']] += 1
        total_lines += block['lines']

    return {
        'chapter': chapter_path.name,
        'total_blocks': len(blocks),
        'total_lines': total_lines,
        'by_language': dict(lang_counts),
        'blocks': blocks
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_code_blocks.py <sections_dir>")
        sys.exit(1)

    sections_dir = Path(sys.argv[1])

    if not sections_dir.exists():
        print(f"Error: Directory {sections_dir} does not exist")
        sys.exit(1)

    print("# Code Block Analysis - Zig Developer Guide\n")

    all_chapters = []
    total_blocks = 0
    total_lines = 0
    global_lang_counts = defaultdict(int)

    # Process each chapter
    chapters = sorted([d for d in sections_dir.iterdir() if d.is_dir()])

    for chapter_path in chapters:
        result = analyze_chapter(chapter_path)

        if result:
            all_chapters.append(result)
            total_blocks += result['total_blocks']
            total_lines += result['total_lines']

            for lang, count in result['by_language'].items():
                global_lang_counts[lang] += count

    # Print summary
    print(f"## Summary\n")
    print(f"- **Total Chapters**: {len(all_chapters)}")
    print(f"- **Total Code Blocks**: {total_blocks}")
    print(f"- **Total Code Lines**: {total_lines}")
    print(f"")

    print(f"## Code Blocks by Language\n")
    for lang, count in sorted(global_lang_counts.items(), key=lambda x: -x[1]):
        percentage = (count / total_blocks * 100) if total_blocks > 0 else 0
        print(f"- **{lang}**: {count} blocks ({percentage:.1f}%)")
    print("")

    print(f"## Per-Chapter Breakdown\n")
    for chapter in all_chapters:
        print(f"### {chapter['chapter']}")
        print(f"- Code blocks: {chapter['total_blocks']}")
        print(f"- Code lines: {chapter['total_lines']}")

        if chapter['by_language']:
            langs = ', '.join([f"{lang}({count})" for lang, count in chapter['by_language'].items()])
            print(f"- Languages: {langs}")
        print("")

    # Export JSON for further processing
    analysis_data = {
        'summary': {
            'total_chapters': len(all_chapters),
            'total_blocks': total_blocks,
            'total_lines': total_lines,
            'by_language': dict(global_lang_counts)
        },
        'chapters': all_chapters
    }

    output_file = Path('code_blocks_analysis.json')
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(analysis_data, f, indent=2)

    print(f"✅ Analysis complete. JSON data written to {output_file}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
