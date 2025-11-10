#!/bin/bash
# Generate flame graph from perf data
# Flame graphs provide visual representation of profiling data

set -e

echo "=== Flame Graph Generation ==="
echo ""

# Check if perf.data exists
if [ ! -f perf.data ]; then
    echo "Error: perf.data not found"
    echo "Run ./scripts/profile_perf.sh first to generate profiling data"
    exit 1
fi

# Check if FlameGraph tools are available
if ! command -v stackcollapse-perf.pl &> /dev/null; then
    echo "FlameGraph tools not found in PATH"
    echo ""
    echo "Installation options:"
    echo ""
    echo "1. Clone FlameGraph repository:"
    echo "   git clone https://github.com/brendangregg/FlameGraph"
    echo "   export PATH=\$PATH:\$(pwd)/FlameGraph"
    echo ""
    echo "2. Install system-wide:"
    echo "   cd FlameGraph"
    echo "   sudo cp *.pl /usr/local/bin/"
    echo ""
    echo "3. Or run from current directory:"
    echo "   git clone https://github.com/brendangregg/FlameGraph"
    echo "   ./FlameGraph/stackcollapse-perf.pl"
    echo ""

    # Try to find FlameGraph in common locations
    for dir in ./FlameGraph ../FlameGraph ~/FlameGraph; do
        if [ -f "$dir/stackcollapse-perf.pl" ]; then
            echo "Found FlameGraph at: $dir"
            export PATH="$PATH:$(cd "$dir" && pwd)"
            break
        fi
    done

    if ! command -v stackcollapse-perf.pl &> /dev/null; then
        echo "Still not found. Please install FlameGraph first."
        exit 1
    fi
fi

# Generate flame graph
echo "Converting perf data to folded format..."

# Handle permissions for perf.data
if [ -r perf.data ]; then
    perf script | stackcollapse-perf.pl > out.folded
else
    sudo perf script | stackcollapse-perf.pl > out.folded
fi

echo "Generating flame graph SVG..."
flamegraph.pl out.folded > flamegraph.svg

echo ""
echo "========================================="
echo "Flame graph generated successfully!"
echo "========================================="
echo ""
echo "Output files:"
echo "  out.folded        # Intermediate folded format"
echo "  flamegraph.svg    # Interactive flame graph"
echo ""
echo "View the flame graph:"
echo "  xdg-open flamegraph.svg    # Linux"
echo "  open flamegraph.svg        # macOS"
echo "  start flamegraph.svg       # Windows"
echo ""
echo "Or open flamegraph.svg in your web browser"
echo ""
echo "How to read flame graphs:"
echo "  - X-axis: Alphabetical order (NOT time)"
echo "  - Y-axis: Stack depth (call hierarchy)"
echo "  - Width: Proportion of samples (time spent)"
echo "  - Color: Random (helps distinguish adjacent frames)"
echo ""
echo "What to look for:"
echo "  - WIDE bars = functions consuming most CPU time (HOT)"
echo "  - Tall stacks = deep call chains"
echo "  - Plateau shape = consistent execution path"
echo "  - Towers = expensive call chains"
echo ""
echo "Interactive features:"
echo "  - Click on a frame to zoom in"
echo "  - Click 'Reset Zoom' to zoom out"
echo "  - Hover to see function details"
echo "  - Search (Ctrl+F) to highlight functions"
echo ""
echo "Tips:"
echo "  - Focus on the widest flames at the top"
echo "  - Click to zoom into interesting areas"
echo "  - Use search to find specific functions"
echo "  - Compare multiple flame graphs side-by-side"
echo ""
echo "Advanced: Generate differential flame graph:"
echo "  perf script -i perf.data.old | stackcollapse-perf.pl > old.folded"
echo "  perf script -i perf.data.new | stackcollapse-perf.pl > new.folded"
echo "  difffolded.pl old.folded new.folded | flamegraph.pl > diff.svg"
echo ""
