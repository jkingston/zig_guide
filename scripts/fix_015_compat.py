#!/usr/bin/env python3
"""
Fix Zig 0.15.2 API Compatibility Issues

Automatically updates code to work with Zig 0.15.2 API changes.

Usage:
    ./fix_015_compat.py <file_or_directory>
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple

class Zig015Fixer:
    def __init__(self, content: str):
        self.content = content
        self.changes_made = []

    def fix_all(self) -> str:
        """Apply all fixes."""
        self.fix_arraylist_init()
        self.fix_arraylist_append()
        self.fix_arraylist_deinit()
        self.fix_arraylist_appendslice()
        self.fix_hashmap_init()
        self.fix_hashmap_deinit()
        self.fix_hashmap_put()
        self.fix_toownedslice()
        self.fix_fromownedslice()
        return self.content

    def fix_arraylist_init(self):
        """Fix ArrayList.init() -> ArrayList{}"""
        # Pattern: std.ArrayList(T).init(allocator)
        pattern = r'std\.ArrayList\(([^)]+)\)\.init\((\w+)\)'
        replacement = r'std.ArrayList(\1){}'

        old_content = self.content
        self.content = re.sub(pattern, replacement, self.content)

        if self.content != old_content:
            self.changes_made.append("ArrayList initialization: .init(allocator) -> {}")

    def fix_arraylist_append(self):
        """Fix list.append(item) -> list.append(allocator, item)"""
        # This is trickier - need to find variable name and add allocator parameter

        # Pattern: variable.append(single_arg)
        # We need to be careful not to match already-fixed code

        # Simple pattern for obvious cases
        lines = self.content.split('\n')
        new_lines = []
        modified = False

        for line in lines:
            # Match: something.append(arg) where arg is NOT already "allocator, ..."
            match = re.search(r'(\w+)\.append\((?!allocator,)([^)]+)\)', line)

            if match and 'ArrayList' in self.content:  # Only if we have ArrayList in file
                var_name = match.group(1)
                arg = match.group(2).strip()

                # Don't fix if already has allocator
                if not arg.startswith('allocator,'):
                    new_line = line.replace(
                        f'{var_name}.append({arg})',
                        f'{var_name}.append(allocator, {arg})'
                    )
                    new_lines.append(new_line)
                    if new_line != line:
                        modified = True
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

        if modified:
            self.content = '\n'.join(new_lines)
            self.changes_made.append("ArrayList.append: Added allocator parameter")

    def fix_arraylist_appendslice(self):
        """Fix list.appendSlice(slice) -> list.appendSlice(allocator, slice)"""
        lines = self.content.split('\n')
        new_lines = []
        modified = False

        for line in lines:
            match = re.search(r'(\w+)\.appendSlice\((?!allocator,)([^)]+)\)', line)

            if match:
                var_name = match.group(1)
                arg = match.group(2).strip()

                if not arg.startswith('allocator,'):
                    new_line = line.replace(
                        f'{var_name}.appendSlice({arg})',
                        f'{var_name}.appendSlice(allocator, {arg})'
                    )
                    new_lines.append(new_line)
                    if new_line != line:
                        modified = True
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

        if modified:
            self.content = '\n'.join(new_lines)
            self.changes_made.append("ArrayList.appendSlice: Added allocator parameter")

    def fix_arraylist_deinit(self):
        """Fix list.deinit() -> list.deinit(allocator)"""
        lines = self.content.split('\n')
        new_lines = []
        modified = False

        for line in lines:
            # Match: something.deinit() with no arguments
            match = re.search(r'(\w+)\.deinit\(\)', line)

            if match and ('ArrayList' in self.content or 'Hash' in self.content):
                var_name = match.group(1)
                new_line = line.replace(f'{var_name}.deinit()', f'{var_name}.deinit(allocator)')
                new_lines.append(new_line)
                if new_line != line:
                    modified = True
            else:
                new_lines.append(line)

        if modified:
            self.content = '\n'.join(new_lines)
            self.changes_made.append("Container.deinit: Added allocator parameter")

    def fix_hashmap_init(self):
        """Fix HashMap.init() -> HashMap{}"""
        # AutoHashMapUnmanaged and similar
        pattern = r'(std\.\w*HashMap\w*)\(([^)]+)\)\.init\(\)'
        replacement = r'\1(\2){}'

        old_content = self.content
        self.content = re.sub(pattern, replacement, self.content)

        if self.content != old_content:
            self.changes_made.append("HashMap initialization: .init() -> {}")

    def fix_hashmap_deinit(self):
        """Already handled by fix_arraylist_deinit"""
        pass

    def fix_hashmap_put(self):
        """Fix map.put(key, value) -> map.put(allocator, key, value)"""
        lines = self.content.split('\n')
        new_lines = []
        modified = False

        for line in lines:
            # Match: something.put(arg1, arg2) where NOT already "allocator, ..."
            match = re.search(r'(\w+)\.put\((?!allocator,)([^)]+)\)', line)

            if match and 'Hash' in self.content:
                var_name = match.group(1)
                args = match.group(2).strip()

                if not args.startswith('allocator,'):
                    new_line = line.replace(
                        f'{var_name}.put({args})',
                        f'{var_name}.put(allocator, {args})'
                    )
                    new_lines.append(new_line)
                    if new_line != line:
                        modified = True
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

        if modified:
            self.content = '\n'.join(new_lines)
            self.changes_made.append("HashMap.put: Added allocator parameter")

    def fix_toownedslice(self):
        """Fix toOwnedSlice() -> toOwnedSlice(allocator)"""
        old_content = self.content
        self.content = re.sub(r'\.toOwnedSlice\(\)', '.toOwnedSlice(allocator)', self.content)

        if self.content != old_content:
            self.changes_made.append("toOwnedSlice: Added allocator parameter")

    def fix_fromownedslice(self):
        """Fix fromOwnedSlice(allocator, slice) - usually correct already"""
        # This one is typically already correct in 0.15, but let's check
        pass

def fix_file(file_path: Path, dry_run: bool = False) -> Tuple[bool, List[str]]:
    """Fix a single .zig file."""
    if not file_path.suffix == '.zig':
        return False, []

    content = file_path.read_text()
    fixer = Zig015Fixer(content)
    new_content = fixer.fix_all()

    if new_content != content:
        if not dry_run:
            file_path.write_text(new_content)
        return True, fixer.changes_made
    return False, []

def fix_directory(dir_path: Path, dry_run: bool = False):
    """Fix all .zig files in a directory."""
    zig_files = list(dir_path.rglob('*.zig'))

    print(f"Found {len(zig_files)} .zig files in {dir_path}\n")

    total_fixed = 0
    for zig_file in sorted(zig_files):
        modified, changes = fix_file(zig_file, dry_run)

        if modified:
            total_fixed += 1
            rel_path = zig_file.relative_to(dir_path) if zig_file.is_relative_to(dir_path) else zig_file
            print(f"{'[DRY RUN] ' if dry_run else ''}✅ Fixed: {rel_path}")
            for change in changes:
                print(f"    - {change}")
            print()

    print(f"\n{'='*60}")
    if dry_run:
        print(f"[DRY RUN] Would fix {total_fixed}/{len(zig_files)} files")
    else:
        print(f"✅ Fixed {total_fixed}/{len(zig_files)} files")
    print(f"{'='*60}")

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Fix Zig 0.15.2 API compatibility issues'
    )
    parser.add_argument('path', type=Path, help='File or directory to fix')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be changed without modifying files')

    args = parser.parse_args()

    path = args.path

    if not path.exists():
        print(f"❌ Path does not exist: {path}")
        return 1

    if path.is_file():
        modified, changes = fix_file(path, args.dry_run)
        if modified:
            print(f"{'[DRY RUN] ' if args.dry_run else ''}✅ Fixed: {path}")
            for change in changes:
                print(f"  - {change}")
        else:
            print(f"ℹ️  No changes needed: {path}")
    elif path.is_dir():
        fix_directory(path, args.dry_run)
    else:
        print(f"❌ Invalid path: {path}")
        return 1

    return 0

if __name__ == '__main__':
    sys.exit(main())
