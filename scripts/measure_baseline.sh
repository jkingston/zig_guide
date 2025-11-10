#!/bin/bash
# Comprehensive Baseline Measurement
# Captures all quality metrics before improvements

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Zig Guide: Comprehensive Baseline Metrics              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo
echo "Date: $(date +%Y-%m-%d)"
echo

# Total line count
echo "## Total Line Count"
echo
total=$(wc -l sections/*/content.md | tail -1 | awk '{print $1}')
echo "Total lines: $total"
chapter_count=$(ls sections/*/content.md | wc -l)
echo "Number of chapters: $chapter_count"
avg_lines=$((total / chapter_count))
echo "Average lines per chapter: $avg_lines"
echo

# Chapter breakdown
echo "## Chapter Breakdown (by size)"
echo
printf "%-30s | %6s\n" "Chapter" "Lines"
printf "%.s─" {1..40}
echo
wc -l sections/*/content.md | sort -n | tail -n +1 | head -n -1 | while read lines file; do
    chapter=$(basename $(dirname "$file"))
    printf "%-30s | %6d\n" "$chapter" "$lines"
done
echo

# Allocator mentions
echo "## Allocator Mentions (by chapter)"
echo
allocator_total=0
for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))
    count=$(grep -ic "allocator" "$file" 2>/dev/null || echo "0")
    if [ "$count" -gt 20 ]; then
        printf "%-30s | %6d\n" "$chapter" "$count"
    fi
    allocator_total=$((allocator_total + count))
done
echo "Total allocator mentions: $allocator_total"
echo

# Defer mentions
echo "## Defer/Errdefer Mentions (by chapter)"
echo
defer_total=0
for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))
    count=$(grep -icE "defer|errdefer" "$file" 2>/dev/null || echo "0")
    if [ "$count" -gt 15 ]; then
        printf "%-30s | %6d\n" "$chapter" "$count"
    fi
    defer_total=$((defer_total + count))
done
echo "Total defer/errdefer mentions: $defer_total"
echo

# Error handling mentions
echo "## Error Union Mentions (by chapter)"
echo
error_total=0
for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))
    count=$(grep -icE "error union|try |catch " "$file" 2>/dev/null || echo "0")
    if [ "$count" -gt 20 ]; then
        printf "%-30s | %6d\n" "$chapter" "$count"
    fi
    error_total=$((error_total + count))
done
echo "Total error handling mentions: $error_total"
echo

# Code vs prose ratio
echo "## Code vs Prose Analysis"
echo
code_total=0
for file in sections/*/content.md; do
    code_blocks=$(grep -c '^```zig' "$file" 2>/dev/null || echo "0")
    code_total=$((code_total + code_blocks))
done
echo "Total code blocks: $code_total"
blocks_per_chapter=$((code_total / chapter_count))
echo "Average code blocks per chapter: $blocks_per_chapter"
echo

# Tables
echo "## Tables Analysis"
echo
table_total=0
for file in sections/*/content.md; do
    tables=$(grep -c '|.*|.*|' "$file" 2>/dev/null || echo "0")
    table_total=$((table_total + tables))
done
echo "Total table rows: $table_total"
echo "Average tables per chapter: $((table_total / chapter_count))"
echo

# Philosophical intros
echo "## Philosophical Introductions"
echo
long_intro_count=0
for file in sections/*/content.md; do
    chapter=$(basename $(dirname "$file"))
    lines=$(awk '/```zig/{print NR; exit}' "$file" 2>/dev/null || echo "0")

    if [ "$lines" -gt 150 ]; then
        printf "%-30s | %6d lines before first code\n" "$chapter" "$lines"
        long_intro_count=$((long_intro_count + 1))
    fi
done
echo "Chapters with >150 line intros: $long_intro_count"
echo

# Summary metrics
echo "═══════════════════════════════════════════════════════════════"
echo "## Summary Metrics"
echo "═══════════════════════════════════════════════════════════════"
echo
printf "%-40s | %10s\n" "Metric" "Value"
printf "%.s─" {1..55}
echo
printf "%-40s | %10d\n" "Total lines" "$total"
printf "%-40s | %10d\n" "Total chapters" "$chapter_count"
printf "%-40s | %10d\n" "Average lines per chapter" "$avg_lines"
printf "%-40s | %10d\n" "Total code blocks" "$code_total"
printf "%-40s | %10d\n" "Total allocator mentions" "$allocator_total"
printf "%-40s | %10d\n" "Total defer mentions" "$defer_total"
printf "%-40s | %10d\n" "Chapters with long intros" "$long_intro_count"
printf "%-40s | %10d\n" "Total tables" "$table_total"
echo

# Density estimate
redundancy_pct=$(awk -v at="$allocator_total" -v dt="$defer_total" -v total="$total" \
    'BEGIN {printf "%.1f", ((at + dt) / total) * 100}')
echo "Estimated redundancy percentage: $redundancy_pct%"

echo
echo "═══════════════════════════════════════════════════════════════"
echo "Baseline measurement complete."
echo "═══════════════════════════════════════════════════════════════"
