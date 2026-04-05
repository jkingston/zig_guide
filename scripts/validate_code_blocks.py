#!/usr/bin/env python3
"""
Validate Zig code blocks from markdown chapters.

Two validation levels:
  1. Complete programs (pub fn main / test blocks) — semantic compilation via
     `zig build-obj` (catches type errors, wrong signatures, etc.)
  2. All other zig blocks — skipped (snippets shown in context)

`zig build-obj` compiles to object code without linking, avoiding platform-
specific linker issues while still performing full semantic analysis.

Falls back to `zig ast-check` (syntax only) with --syntax-only flag.

Exit code: 0 if all tested blocks pass, 1 if any fail.
"""

import re
import os
import sys
import json
import shutil
import subprocess
import tempfile
from pathlib import Path


def extract_code_blocks(markdown_content: str, file_path: str):
    """Extract ```zig code blocks with line numbers."""
    blocks = []
    lines = markdown_content.split('\n')
    in_code_block = False
    code_lines = []
    start_line = 0
    block_index = 0
    prev_lines = []

    for i, line in enumerate(lines, 1):
        if line.strip().startswith('```zig'):
            in_code_block = True
            code_lines = []
            start_line = i
            prev_lines = [lines[j] for j in range(max(0, i - 4), i - 1)]
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
                    'file': file_path,
                    'context_before': prev_lines,
                })
        elif in_code_block:
            code_lines.append(line)

    return blocks


def is_old_version_block(block: dict) -> bool:
    """Check if block is marked as an old version example."""
    context = '\n'.join(block['context_before']).lower()
    return any(m in context for m in ['0.15', '0.14', '0.13', '0.12', '0.11', '🕐'])


def is_complete_program(code: str) -> bool:
    """Check if a code block is a complete, standalone Zig program.

    Complete programs have:
      - pub fn main() OR test "..." blocks
      - Usually @import("std")
    """
    stripped = code.strip()
    has_main = 'pub fn main(' in stripped
    has_test = bool(re.search(r'^test\s+"', stripped, re.MULTILINE))
    return has_main or has_test


def is_complete_file(code: str) -> bool:
    """Check if a code block is a complete file (all top-level declarations).

    These are blocks that start with const/fn/pub declarations and contain
    no bare statements. They can be ast-checked as-is.
    """
    stripped = code.strip()

    # Must start with a declaration
    first_meaningful = None
    for line in stripped.split('\n'):
        s = line.strip()
        if s and not s.startswith('//'):
            first_meaningful = s
            break

    if not first_meaningful:
        return False

    decl_starts = ['const ', 'var ', 'pub ', 'fn ', 'comptime ', 'extern ']
    if not any(first_meaningful.startswith(k) for k in decl_starts):
        return False

    # Must not contain bare statements (try, if, for, while, assignments outside fn)
    # Simple heuristic: if all non-blank, non-comment lines at indent level 0
    # are declarations, it's a complete file
    bare_statement_markers = [
        'try ', 'if (', 'for (', 'while (', 'switch (', 'return ',
        'defer ', 'errdefer ',
    ]
    for line in stripped.split('\n'):
        s = line.strip()
        if not s or s.startswith('//'):
            continue
        # Check only top-level lines (no leading whitespace)
        if line and not line[0].isspace():
            if any(s.startswith(m) for m in bare_statement_markers):
                return False
            # Assignment at top level
            if re.match(r'^[a-zA-Z_][\w.]*(\.\*|\[.*\])?\s*=[^=]', s):
                return False

    return True


def is_build_zig(code: str) -> bool:
    """Check if this is a build.zig fragment."""
    return any(m in code for m in [
        'pub fn build(b:', 'b.addExecutable', 'b.createModule',
        'b.standardTargetOptions', 'b.addTest(', 'b.installArtifact',
        'b.addModule', 'b.addRunArtifact', 'b.step(',
        'b.path(', '.dependOn(', 'b.addOptions',
    ])


def prepare_for_check(code: str) -> str:
    """Prepare a complete program/file for ast-check."""
    preamble = []
    if 'std.' in code and '@import("std")' not in code:
        preamble.append('const std = @import("std");')
    if 'testing.' in code and 'std.testing' not in code and '@import' not in code:
        if 'const std' not in '\n'.join(preamble) and '@import("std")' not in code:
            preamble.append('const std = @import("std");')
        preamble.append('const testing = std.testing;')
    if 'builtin.' in code and '@import("builtin")' not in code:
        preamble.append('const builtin = @import("builtin");')
    if preamble:
        return '\n'.join(preamble) + '\n' + code
    return code


def is_incomplete_test(code: str) -> bool:
    """Check if a test block references too many undeclared externals to validate."""
    stripped = code.strip()
    # If it references external libraries/modules we can't provide
    external_markers = [
        'xev.', 'c.', 'fontconfig.', 'zgui.', 'sdl.',
        '{ ... }', '{ /* ... */ }',  # Ellipsis placeholders
    ]
    if any(m in stripped for m in external_markers):
        return True
    # Test name listings without bodies
    meaningful = [l for l in stripped.split('\n') if l.strip() and not l.strip().startswith('//')]
    if meaningful and all(l.strip().startswith('test "') for l in meaningful):
        return True
    return False


IGNORABLE_ERRORS = [
    'use of undeclared identifier',
    'unused local constant',
    'unused local variable',
    'local variable is never mutated',
    'unused function parameter',
    'unused capture',
    'documentation comments cannot be attached to tests',
    # build-obj errors expected in isolated code blocks:
    'no module named',
    'import of file outside module path',
    'unable to load',
]


def _all_errors_ignorable(stderr: str) -> bool:
    """Check if all error lines in stderr are in our ignorable list."""
    error_lines = [l for l in stderr.split('\n') if ': error:' in l]
    return bool(error_lines) and all(
        any(ign in line for ign in IGNORABLE_ERRORS)
        for line in error_lines
    )


def _write_zig_file(code: str, tmp_dir: str, block_id: str) -> str:
    zig_file = os.path.join(tmp_dir, f"block_{block_id}.zig")
    with open(zig_file, 'w') as f:
        f.write(code)
    return zig_file


def build_obj_check(code: str, tmp_dir: str, block_id: str) -> tuple:
    """Semantically compile a code block via `zig build-obj`.

    Returns (success, error_message). This catches type errors, wrong
    function signatures, and other semantic issues that ast-check misses.
    Falls back gracefully for blocks that reference external dependencies.
    """
    zig_file = _write_zig_file(code, tmp_dir, block_id)

    try:
        result = subprocess.run(
            ['zig', 'build-obj', zig_file],
            capture_output=True, text=True, timeout=60
        )
        if result.returncode == 0:
            return True, None

        stderr = result.stderr.strip()
        if _all_errors_ignorable(stderr):
            return True, None
        return False, stderr

    except subprocess.TimeoutExpired:
        return False, "Timed out"
    except FileNotFoundError:
        return False, "zig not found in PATH"


def ast_check(code: str, tmp_dir: str, block_id: str) -> tuple:
    """Run zig ast-check on a code block (syntax only).

    Returns (success, error_message). Filters out semantic errors that
    ast-check reports but which are expected in isolated code blocks.
    """
    zig_file = _write_zig_file(code, tmp_dir, block_id)

    try:
        result = subprocess.run(
            ['zig', 'ast-check', zig_file],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            stderr = result.stderr.strip()
            if _all_errors_ignorable(stderr):
                return True, None
            return False, stderr
        return True, None
    except subprocess.TimeoutExpired:
        return False, "Timed out"
    except FileNotFoundError:
        return False, "zig not found in PATH"


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_code_blocks.py <directory|file> [--json] [--verbose] [--syntax-only]")
        sys.exit(1)

    path = Path(sys.argv[1])
    json_output = '--json' in sys.argv
    verbose = '--verbose' in sys.argv
    syntax_only = '--syntax-only' in sys.argv
    validate = ast_check if syntax_only else build_obj_check

    if path.is_file():
        md_files = [(path, path.stem)]
    elif path.is_dir():
        # Match numbered chapters (01-*.md) and lettered appendices (a-*.md)
        md_files = [(f, f.stem) for f in sorted(path.glob('[0-9]*.md'))]
        md_files += [(f, f.stem) for f in sorted(path.glob('[a-d]-*.md'))]
        # Legacy names (ch*.md, appendix*.md) for backwards compatibility
        if not md_files:
            md_files = [(f, f.stem) for f in sorted(path.glob('ch*.md'))]
            md_files += [(f, f.stem) for f in sorted(path.glob('appendix*.md'))]
    else:
        print(f"Error: {path} not found")
        sys.exit(1)

    tmp_dir = tempfile.mkdtemp(prefix='zig_validate_')
    stats = {'tested': 0, 'passed': 0, 'skipped': 0, 'failed': 0}
    failures = []

    try:
        for md_file, chapter_name in md_files:
            content = md_file.read_text()
            blocks = extract_code_blocks(content, str(md_file))

            ch_tested = 0
            ch_passed = 0
            ch_skipped = 0

            for block in blocks:
                code = block['code'].strip()

                # Skip old version examples
                if is_old_version_block(block):
                    ch_skipped += 1
                    stats['skipped'] += 1
                    continue

                # Skip build.zig fragments
                if is_build_zig(code):
                    ch_skipped += 1
                    stats['skipped'] += 1
                    continue

                # Only validate complete programs (main/test blocks)
                if not is_complete_program(code):
                    ch_skipped += 1
                    stats['skipped'] += 1
                    continue

                # Skip test blocks that reference external libs
                if is_incomplete_test(code):
                    ch_skipped += 1
                    stats['skipped'] += 1
                    continue

                prepared = prepare_for_check(code)
                block_id = f"{chapter_name}_{block['index']}"
                success, error_msg = validate(prepared, tmp_dir, block_id)

                ch_tested += 1
                stats['tested'] += 1

                if success:
                    ch_passed += 1
                    stats['passed'] += 1
                else:
                    stats['failed'] += 1
                    failure = {
                        'file': str(md_file),
                        'chapter': chapter_name,
                        'block': block['index'],
                        'line': block['start_line'],
                        'error': error_msg,
                        'code_preview': code[:200],
                    }
                    failures.append(failure)
                    if verbose:
                        print(f"    FAIL: {md_file.name}:{block['start_line']} block #{block['index']}")

            if not json_output:
                total = ch_tested + ch_skipped
                if ch_tested == 0:
                    status = "·"
                elif ch_tested == ch_passed:
                    status = "✓"
                else:
                    status = "✗"
                print(f"  {status} {chapter_name}: {ch_passed}/{ch_tested} validated, {ch_skipped} snippets ({total} total)")

        mode = "syntax-only (ast-check)" if syntax_only else "semantic (build-obj)"
        if json_output:
            output = {**stats, 'mode': mode, 'failures': failures}
            print(json.dumps(output, indent=2))
        else:
            print(f"\n{'='*60}")
            print(f"Mode: {mode}")
            print(f"Validated: {stats['passed']}/{stats['tested']} passed, "
                  f"{stats['skipped']} snippets skipped, {stats['failed']} failed")

            if failures:
                print(f"\n{'='*60}")
                print("FAILURES:\n")
                for f in failures:
                    print(f"  {f['file']}:{f['line']} (block #{f['block']})")
                    for line in f['error'].split('\n')[:3]:
                        print(f"    {line}")
                    print()

        sys.exit(1 if failures else 0)

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == '__main__':
    main()
