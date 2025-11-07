#!/usr/bin/env python3
"""
Extract Zig code blocks from markdown files for the Zig Developer Guide.

This script parses markdown files and extracts code blocks marked with ```zig,
creating a mapping that can be used for validation or extraction.
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict
import json

def extract_code_blocks(markdown_content: str, file_path: str) -> List[Dict]:
    """Extract all ```zig code blocks from markdown content."""
    code_blocks = []
    lines = markdown_content.split('\n')

    in_code_block = False
    code_lines = []
    start_line = 0
    block_index = 0

    for i, line in enumerate(lines, 1):
        if line.strip().startswith('```zig'):
            in_code_block = True
            code_lines = []
            start_line = i
        elif line.strip() == '```' and in_code_block:
            in_code_block = False
            code = '\n'.join(code_lines)

            # Skip empty blocks
            if code.strip():
                block_index += 1
                code_blocks.append({
                    'index': block_index,
                    'start_line': start_line,
                    'end_line': i,
                    'code': code,
                    'file': file_path,
                    'lines': len(code_lines),
                    'chars': len(code)
                })
        elif in_code_block:
            code_lines.append(line)

    return code_blocks

def is_runnable_example(code: str) -> bool:
    """Determine if a code block is a complete, runnable example."""
    # Check for main function or test
    has_main = 'pub fn main()' in code
    has_test = 'test ' in code

    # Check for complete program elements
    has_imports = '@import' in code

    # Likely a snippet if it's just a few lines without structure
    is_snippet = len(code.split('\n')) < 10 and not (has_main or has_test)

    return (has_main or has_test) and has_imports and not is_snippet

def categorize_blocks(blocks: List[Dict]) -> Tuple[List[Dict], List[Dict]]:
    """Categorize blocks as runnable examples or inline snippets."""
    runnable = []
    snippets = []

    for block in blocks:
        if is_runnable_example(block['code']):
            runnable.append(block)
        else:
            snippets.append(block)

    return runnable, snippets

def analyze_chapter(chapter_path: Path) -> Dict:
    """Analyze a chapter's markdown file and extract code block info."""
    content_file = chapter_path / 'content.md'

    if not content_file.exists():
        return None

    content = content_file.read_text()
    blocks = extract_code_blocks(content, str(content_file))
    runnable, snippets = categorize_blocks(blocks)

    return {
        'chapter': chapter_path.name,
        'content_file': str(content_file),
        'total_blocks': len(blocks),
        'runnable_blocks': len(runnable),
        'snippet_blocks': len(snippets),
        'runnable': runnable,
        'snippets': snippets
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_code_blocks.py <sections_directory>")
        print("   or: extract_code_blocks.py <markdown_file>")
        sys.exit(1)

    path = Path(sys.argv[1])

    if path.is_file():
        # Analyze single file
        content = path.read_text()
        blocks = extract_code_blocks(content, str(path))
        runnable, snippets = categorize_blocks(blocks)

        print(f"\n=== {path.name} ===")
        print(f"Total blocks: {len(blocks)}")
        print(f"Runnable examples: {len(runnable)}")
        print(f"Inline snippets: {len(snippets)}")

        if runnable:
            print(f"\n--- Runnable Examples ({len(runnable)}) ---")
            for block in runnable:
                print(f"  Block #{block['index']} (lines {block['start_line']}-{block['end_line']}, {block['lines']} lines)")
                # Show first line of code
                first_line = block['code'].split('\n')[0][:60]
                print(f"    {first_line}...")

    elif path.is_dir():
        # Analyze all chapters in sections directory
        chapters = sorted([d for d in path.iterdir() if d.is_dir()])

        total_stats = {
            'total_blocks': 0,
            'runnable': 0,
            'snippets': 0
        }

        results = []

        for chapter in chapters:
            result = analyze_chapter(chapter)
            if result:
                results.append(result)
                total_stats['total_blocks'] += result['total_blocks']
                total_stats['runnable'] += result['runnable_blocks']
                total_stats['snippets'] += result['snippet_blocks']

        # Print summary
        print("\n=== Code Block Analysis ===\n")
        print(f"{'Chapter':<30} {'Total':<8} {'Runnable':<10} {'Snippets':<10}")
        print("-" * 60)

        for result in results:
            print(f"{result['chapter']:<30} {result['total_blocks']:<8} {result['runnable_blocks']:<10} {result['snippet_blocks']:<10}")

        print("-" * 60)
        print(f"{'TOTAL':<30} {total_stats['total_blocks']:<8} {total_stats['runnable']:<10} {total_stats['snippets']:<10}")

        # Save detailed results to JSON
        output_file = Path('code_blocks_analysis.json')
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\nDetailed results saved to: {output_file}")

    else:
        print(f"Error: {path} is neither a file nor a directory")
        sys.exit(1)

if __name__ == '__main__':
    main()
