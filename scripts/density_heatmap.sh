#!/bin/bash
# Content Density Heatmap
# Visualizes density scores per chapter

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                        Zig Guide: Content Density Heatmap                             ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
echo
echo "Date: $(date +%Y-%m-%d)"
echo

printf "%-30s | %6s | %6s | %7s | %6s | %8s | %7s\n" \
    "Chapter" "Lines" "Code%" "Prose%" "Tables" "Diagrams" "Density"
printf "%.s─" {1..95}
echo

declare -a densities=()

for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))
    total_lines=$(wc -l < "$file")

    # Count code blocks (pairs of ```)
    code_markers=$(grep -c '^```' "$file" 2>/dev/null || echo "0")
    code_blocks=$((code_markers / 2))

    # Estimate code percentage (assume ~20 lines per block)
    code_pct=$(awk -v cb="$code_blocks" -v tl="$total_lines" \
        'BEGIN {pct = (cb * 20) / tl * 100; if (pct > 100) pct = 100; printf "%.1f", pct}')

    # Count tables (lines with |...|...|)
    tables=$(grep -c '|.*|.*|' "$file" 2>/dev/null || echo "0")

    # Count non-zig code blocks (diagrams, shell, etc)
    all_code_blocks=$code_blocks
    zig_blocks=$(grep -A1 '^```zig' "$file" 2>/dev/null | wc -l || echo "0")
    zig_blocks=$((zig_blocks / 2))
    diagrams=$((all_code_blocks - zig_blocks))
    if [ "$diagrams" -lt 0 ]; then diagrams=0; fi

    # Prose percentage
    prose_pct=$(awk -v cp="$code_pct" 'BEGIN {printf "%.1f", 100 - cp}')

    # Density score calculation:
    # Higher is better
    # Formula: (code% * 1.5) + (tables * 2) + (diagrams * 3) - (prose% * 0.5) - (lines / 100)
    density=$(awk -v cp="$code_pct" -v t="$tables" -v d="$diagrams" \
        -v pp="$prose_pct" -v tl="$total_lines" \
        'BEGIN {printf "%.1f", (cp * 1.5) + (t * 2) + (d * 3) - (pp * 0.5) - (tl / 100)}')

    # Store for sorting
    densities+=("$density|$chapter|$total_lines|$code_pct|$prose_pct|$tables|$diagrams")

    printf "%-30s | %6d | %5s%% | %6s%% | %6d | %8d | %7s\n" \
        "$chapter" "$total_lines" "$code_pct" "$prose_pct" "$tables" "$diagrams" "$density"
done | sort -t'|' -k1 -n

echo
printf "%.s─" {1..95}
echo

# Calculate average density
avg_density=$(printf '%s\n' "${densities[@]}" | awk -F'|' '{sum+=$1} END {printf "%.1f", sum/NR}')
echo "Average Density Score: $avg_density"

# Count negative density chapters
negative=$(printf '%s\n' "${densities[@]}" | awk -F'|' '$1 < 0 {count++} END {print count+0}')
echo "Chapters with negative density: $negative"

echo
echo "Density Score Interpretation:"
echo "  < 0    : Poor density (too much prose, few examples)"
echo "  0-15   : Moderate density"
echo "  15-30  : Good density (balanced)"
echo "  > 30   : Excellent density (code-first, tables, diagrams)"
echo
echo "═══════════════════════════════════════════════════════════════════════════════════════"
