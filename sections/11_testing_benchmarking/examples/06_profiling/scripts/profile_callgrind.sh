#!/bin/bash
# Callgrind profiling script for CPU profiling
# Callgrind is a deterministic profiler that tracks instruction execution

set -e

echo "=== Callgrind CPU Profiling ==="
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

# Run with callgrind
echo ""
echo "Running callgrind..."
echo "This will be slower than normal execution (10-50x overhead)"
echo ""

valgrind --tool=callgrind \
    --callgrind-out-file=callgrind.out \
    --collect-jumps=yes \
    --collect-systime=yes \
    --separate-threads=yes \
    ./zig-out/bin/profiling_demo

echo ""
echo "========================================="
echo "Profiling complete!"
echo "========================================="
echo ""
echo "Output file: callgrind.out"
echo ""
echo "View results with:"
echo "  kcachegrind callgrind.out              # GUI viewer (recommended)"
echo "  callgrind_annotate callgrind.out       # Text output"
echo "  callgrind_annotate --auto=yes callgrind.out # Auto-annotated source"
echo ""
echo "What to look for:"
echo "  - Functions with highest 'Ir' (instruction reads) - CPU hotspots"
echo "  - Call graph showing function relationships"
echo "  - 'Self' vs 'Incl' costs to find true bottlenecks"
echo "  - Hot paths in your code (highlighted in kcachegrind)"
echo ""
echo "Key metrics:"
echo "  Ir  = Instruction reads (total instructions)"
echo "  Dr  = Data reads (memory reads)"
echo "  Dw  = Data writes (memory writes)"
echo "  I1mr = L1 instruction cache misses"
echo "  D1mr = L1 data cache read misses"
echo "  D1mw = L1 data cache write misses"
echo ""
echo "Tips:"
echo "  - Focus on functions with high 'Self' cost"
echo "  - Use call graph to understand where time is spent"
echo "  - Compare before/after when making optimizations"
echo ""
