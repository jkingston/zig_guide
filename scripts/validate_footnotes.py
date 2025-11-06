#!/usr/bin/env python3
"""
Comprehensive proofreading validation for Zig Developer Guide
Checks footnote references, cross-chapter references, and common issues
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

SECTIONS_DIR = Path("/home/user/zig_guide/sections")

def check_footnotes(content_path):
    """Check that all footnote references have definitions and vice versa"""
    with open(content_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all references [^N]
    ref_pattern = r'\[\^(\d+)\](?!:)'  # [^N] not followed by :
    references = set(re.findall(ref_pattern, content))

    # Find all definitions [^N]:
    def_pattern = r'^\[\^(\d+)\]:'
    definitions = set(re.findall(def_pattern, content, re.MULTILINE))

    issues = []

    # Check for references without definitions
    missing_defs = references - definitions
    if missing_defs:
        for ref in sorted(missing_defs, key=int):
            issues.append(f"  ⚠️  Reference [^{ref}] has no definition")

    # Check for definitions without references
    unused_defs = definitions - references
    if unused_defs:
        for ref in sorted(unused_defs, key=int):
            issues.append(f"  ℹ️  Definition [^{ref}]: is never referenced")

    return {
        'references': len(references),
        'definitions': len(definitions),
        'issues': issues
    }

def check_cross_references(content_path):
    """Check for chapter cross-references"""
    with open(content_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all "Chapter N" references
    chapter_refs = re.findall(r'Chapter (\d+)', content)

    issues = []
    for ref in chapter_refs:
        chapter_num = int(ref)
        if chapter_num < 1 or chapter_num > 15:
            issues.append(f"  ⚠️  Invalid chapter reference: Chapter {ref}")

    return {
        'count': len(chapter_refs),
        'references': chapter_refs,
        'issues': issues
    }

def check_common_issues(content_path):
    """Check for common formatting and content issues"""
    with open(content_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    issues = []

    # Check for TODO/FIXME/XXX markers
    for i, line in enumerate(lines, 1):
        if re.search(r'TODO|FIXME|XXX', line, re.IGNORECASE):
            issues.append(f"  ⚠️  Line {i}: TODO/FIXME marker found")

    # Check for common typos
    typos = {
        'teh': 'the',
        'fo ': 'for ',
        'adn': 'and',
        'thsi': 'this',
        'taht': 'that',
    }

    content = ''.join(lines)
    for typo, correction in typos.items():
        if typo in content.lower():
            count = len(re.findall(typo, content, re.IGNORECASE))
            issues.append(f"  ⚠️  Possible typo '{typo}' found {count} time(s)")

    return {
        'issues': issues
    }

def check_terminology_consistency(content_path):
    """Check for consistent terminology usage"""
    with open(content_path, 'r', encoding='utf-8') as f:
        content = f.read()

    issues = []

    # Check for inconsistent version references
    version_patterns = [
        (r'0\.14\.x', '0.14.x'),
        (r'0\.15\+', '0.15+'),
        (r'Zig 0\.14', 'Zig 0.14'),
        (r'Zig 0\.15', 'Zig 0.15'),
    ]

    # Check for std.debug.print vs print inconsistency
    if 'print(' in content and 'std.debug.print' not in content and '@import("std")' in content:
        if content.count('print(') > content.count('std.debug.print'):
            issues.append("  ℹ️  Found unqualified 'print()' calls - verify context")

    return {
        'issues': issues
    }

def main():
    report = []
    report.append("# Comprehensive Proofreading Report")
    report.append(f"\nGenerated: {Path(__file__).name}\n")

    # Process each chapter
    chapters = sorted(SECTIONS_DIR.glob("*/content.md"))

    total_footnote_issues = 0
    total_cross_ref_issues = 0
    total_other_issues = 0

    for chapter_path in chapters:
        chapter_name = chapter_path.parent.name
        report.append(f"\n## {chapter_name}")
        report.append("")

        # Check footnotes
        footnote_result = check_footnotes(chapter_path)
        report.append(f"**Footnotes:** {footnote_result['references']} references, {footnote_result['definitions']} definitions")
        if footnote_result['issues']:
            report.extend(footnote_result['issues'])
            total_footnote_issues += len(footnote_result['issues'])
        else:
            report.append("  ✅ All footnotes valid")
        report.append("")

        # Check cross-references
        crossref_result = check_cross_references(chapter_path)
        if crossref_result['count'] > 0:
            report.append(f"**Cross-References:** {crossref_result['count']} chapter references found")
            if crossref_result['issues']:
                report.extend(crossref_result['issues'])
                total_cross_ref_issues += len(crossref_result['issues'])

        # Check common issues
        common_result = check_common_issues(chapter_path)
        if common_result['issues']:
            report.append("**Common Issues:**")
            report.extend(common_result['issues'])
            total_other_issues += len(common_result['issues'])

        # Check terminology
        term_result = check_terminology_consistency(chapter_path)
        if term_result['issues']:
            report.append("**Terminology:**")
            report.extend(term_result['issues'])

        report.append("")

    # Summary
    report.append("\n---")
    report.append("\n## Summary")
    report.append(f"\n- **Footnote issues:** {total_footnote_issues}")
    report.append(f"- **Cross-reference issues:** {total_cross_ref_issues}")
    report.append(f"- **Other issues:** {total_other_issues}")
    report.append(f"- **Total issues:** {total_footnote_issues + total_cross_ref_issues + total_other_issues}")

    # Write report
    report_path = Path("/home/user/zig_guide/PROOFREADING_REPORT.md")
    report_path.write_text('\n'.join(report))

    print('\n'.join(report))
    print(f"\n✅ Report written to {report_path}")

    return 0 if (total_footnote_issues + total_cross_ref_issues + total_other_issues) == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
