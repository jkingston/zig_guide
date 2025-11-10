#!/bin/bash
# Linux perf profiling script
# Perf is a sampling-based profiler with low overhead

set -e

echo "=== Linux Perf Profiling ==="
echo ""

# Check if perf is installed
if ! command -v perf &> /dev/null; then
    echo "Error: perf is not installed"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install linux-tools-common linux-tools-generic"
    echo "  Fedora: sudo dnf install perf"
    echo "  Arch: sudo pacman -S perf"
    echo ""
    echo "Note: perf is Linux-only. On macOS use Instruments, on Windows use Visual Studio Profiler"
    exit 1
fi

# Check for required permissions
if ! perf list &> /dev/null; then
    echo "Warning: perf may require additional permissions"
    echo "If you encounter permission errors, try:"
    echo "  sudo sysctl kernel.perf_event_paranoid=1"
    echo "  or run this script with sudo"
    echo ""
fi

# Build for profiling
echo "Building with profiling configuration..."
zig build -Doptimize=ReleaseSafe

# Run with perf
echo ""
echo "Running perf record..."
echo "This has low overhead (1-5%) and uses sampling"
echo ""

# Try to run perf, fallback to sudo if needed
if perf record -g --call-graph=dwarf -F 999 \
    ./zig-out/bin/profiling_demo 2>/dev/null; then
    :
else
    echo "Permission denied, trying with sudo..."
    sudo perf record -g --call-graph=dwarf -F 999 \
        ./zig-out/bin/profiling_demo
fi

echo ""
echo "Generating perf report..."

# Generate text report
if [ -w perf.data ]; then
    perf report -g 'graph,0.5,caller' --stdio > perf_report.txt 2>/dev/null || \
        sudo perf report -g 'graph,0.5,caller' --stdio > perf_report.txt
else
    sudo perf report -g 'graph,0.5,caller' --stdio > perf_report.txt
fi

echo ""
echo "========================================="
echo "Profiling complete!"
echo "========================================="
echo ""
echo "Output files:"
echo "  perf.data          # Raw profiling data"
echo "  perf_report.txt    # Text report"
echo ""
echo "View results with:"
echo "  perf report                    # Interactive TUI viewer (recommended)"
echo "  perf report --stdio            # Text output"
echo "  cat perf_report.txt            # Pre-generated report"
echo "  perf report --no-children      # Show self time only"
echo ""
echo "What to look for:"
echo "  - Functions with highest overhead % - CPU hotspots"
echo "  - Call chains showing where time is spent"
echo "  - Self vs Children overhead"
echo "  - Hot paths through your code"
echo ""
echo "Navigation in 'perf report' interactive mode:"
echo "  Enter  = Zoom into function"
echo "  Esc    = Zoom out"
echo "  a      = Annotate (show assembly)"
echo "  h      = Help"
echo "  q      = Quit"
echo ""
echo "Tips:"
echo "  - Overhead % is percentage of total samples"
echo "  - Focus on functions with high self overhead"
echo "  - Use call chains to understand context"
echo "  - Compare multiple runs for consistency"
echo ""
echo "Advanced usage:"
echo "  perf annotate <function>       # Show annotated assembly"
echo "  perf diff perf.data.old        # Compare two profiles"
echo "  perf script                    # Export for flamegraphs"
echo ""
