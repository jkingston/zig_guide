#!/bin/bash
# Massif heap profiling script
# Massif tracks heap memory usage over time

set -e

echo "=== Massif Heap Profiling ==="
echo ""

# Check if valgrind is installed
if ! command -v valgrind &> /dev/null; then
    echo "Error: valgrind is not installed"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install valgrind"
    echo "  Fedora: sudo dnf install valgrind"
    echo "  Arch: sudo pacman -S valgrind"
    echo "  macOS: brew install valgrind (may have compatibility issues)"
    exit 1
fi

# Build for profiling
echo "Building with profiling configuration..."
zig build -Doptimize=ReleaseSafe

# Run with massif
echo ""
echo "Running massif..."
echo "This tracks heap allocations over time"
echo ""

valgrind --tool=massif \
    --massif-out-file=massif.out \
    --time-unit=ms \
    --detailed-freq=10 \
    --max-snapshots=200 \
    --stacks=yes \
    ./zig-out/bin/profiling_demo

echo ""
echo "========================================="
echo "Profiling complete!"
echo "========================================="
echo ""
echo "Output file: massif.out"
echo ""
echo "View results with:"
echo "  ms_print massif.out              # Text output with graph (recommended)"
echo "  massif-visualizer massif.out     # GUI viewer (if installed)"
echo ""
echo "What to look for:"
echo "  - Peak heap usage (highest point in graph)"
echo "  - Allocation hotspots (functions allocating most memory)"
echo "  - Memory growth over time"
echo "  - Heap snapshots at key points"
echo ""
echo "Generating quick summary..."
echo ""

if command -v ms_print &> /dev/null; then
    ms_print massif.out | head -n 50
    echo ""
    echo "(showing first 50 lines, run 'ms_print massif.out' for full output)"
else
    echo "Install valgrind tools to view with ms_print"
fi

echo ""
echo "Understanding the output:"
echo "  - Graph shows heap usage over time"
echo "  - Snapshots marked with @ show detailed allocation info"
echo "  - Peak snapshot shows maximum heap usage"
echo "  - Stack traces show where memory was allocated"
echo ""
echo "Tips:"
echo "  - Look for unexpected memory growth"
echo "  - Check peak usage location"
echo "  - Identify allocation-heavy functions"
echo "  - Use --stacks=yes to see allocation contexts"
echo ""
echo "Common patterns:"
echo "  - Sawtooth: allocate/free cycles"
echo "  - Ramp: growing data structure"
echo "  - Plateau: constant working set"
echo "  - Leak: continuous growth without freeing"
echo ""
