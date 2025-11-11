#!/bin/bash
# Redundancy Detection Script
# Identifies concept re-introductions and philosophical intros

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Zig Guide: Redundancy Detection Report                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo
echo "Date: $(date +%Y-%m-%d)"
echo

# Function to detect concept re-introductions
detect_reintros() {
    local concept=$1
    local pattern=$2
    local primary_chapter=$3

    echo "## $concept Re-introductions (Primary: $primary_chapter)"
    echo

    local total_redundant=0

    for file in sections/*/content.md; do
        chapter=$(basename $(dirname "$file"))

        # Skip primary chapter
        if [ "$chapter" = "$primary_chapter" ]; then
            continue
        fi

        # Count matches
        matches=$(grep -c -E "$pattern" "$file" 2>/dev/null || true)

        if [ "$matches" -gt 5 ]; then
            echo "⚠️  $chapter: $matches mentions"
            total_redundant=$((total_redundant + matches))

            # Show first 3 contexts with line numbers
            grep -n -E "$pattern" "$file" 2>/dev/null | head -3 | sed 's/^/    /'
            echo
        fi
    done

    echo "   Subtotal: $total_redundant redundant mentions"
    echo
}

# Detect allocator re-introductions (primary: Ch2)
detect_reintros "Allocator" \
    "allocator.*is |Allocator.*provides|explicit allocator|allocator model|allocator.*interface" \
    "02_memory_allocators"

# Detect defer re-explanations (primary: Ch5)
detect_reintros "Defer/Errdefer" \
    "defer.*execut|defer.*scope|errdefer.*when|LIFO.*order|defer.*cleanup" \
    "05_error_handling"

# Detect error union re-explanations (primary: Ch5)
detect_reintros "Error Unions" \
    "error union|!\[a-z].*syntax|try.*keyword|catch.*error|error.*handling.*pattern" \
    "05_error_handling"

# Find philosophical introductions (lines before first code block)
echo "## Philosophical Introductions (Lines Before First Code)"
echo

total_philosophical=0

for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))

    # Count lines before first ```zig block
    lines_before_code=$(awk '/```zig/{print NR; exit}' "$file" 2>/dev/null || echo "0")

    # Skip if no code found
    if [ "$lines_before_code" = "0" ]; then
        continue
    fi

    if [ "$lines_before_code" -gt 150 ]; then
        echo "⚠️  $chapter: $lines_before_code lines before first code example (target: <75)"
        total_philosophical=$((total_philosophical + lines_before_code - 75))
    elif [ "$lines_before_code" -gt 75 ]; then
        echo "⚡  $chapter: $lines_before_code lines before first code example (target: <75)"
    fi
done

echo
echo "   Estimated excess intro lines: $total_philosophical"
echo

# Detect verbose comparisons (could be tables)
echo "## Verbose Comparisons (Table Candidates)"
echo

for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))

    # Count paragraphs with comparison keywords
    comparisons=$(grep -c -E "whereas|in contrast|unlike|compared to|on the other hand" "$file" 2>/dev/null || true)

    # Count existing tables
    tables=$(grep -c '|.*|.*|' "$file" 2>/dev/null || true)

    if [ "$comparisons" -gt 5 ] && [ "$tables" -lt 3 ]; then
        echo "⚠️  $chapter: $comparisons comparison phrases, only $tables tables"
        echo "    Candidates for table conversion"
    fi
done

echo
echo "═══════════════════════════════════════════════════════════════"
echo "End of Redundancy Report"
echo "═══════════════════════════════════════════════════════════════"
