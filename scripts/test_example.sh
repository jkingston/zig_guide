#!/usr/bin/env bash
# Script to test a Zig code example against multiple versions
# Usage: ./scripts/test_example.sh <path_to_example.zig> [versions...]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <example.zig> [version1 version2 ...]"
    echo ""
    echo "Examples:"
    echo "  $0 sections/05_io_streams/example_basic_writer.zig"
    echo "  $0 sections/05_io_streams/example_basic_writer.zig 0.15.1 0.15.2"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ZIG_VERSIONS_DIR="$PROJECT_ROOT/zig_versions"

EXAMPLE_FILE="$1"
shift

# If no versions specified, test all available versions
if [ $# -eq 0 ]; then
    VERSIONS=($(ls "$ZIG_VERSIONS_DIR" | grep '^zig-' | sed 's/^zig-//'))
else
    VERSIONS=("$@")
fi

if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "Error: File not found: $EXAMPLE_FILE"
    exit 1
fi

EXAMPLE_NAME=$(basename "$EXAMPLE_FILE" .zig)
echo "Testing: $EXAMPLE_FILE"
echo "Against versions: ${VERSIONS[*]}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for VERSION in "${VERSIONS[@]}"; do
    ZIG_BIN="$ZIG_VERSIONS_DIR/zig-$VERSION/zig"

    if [ ! -f "$ZIG_BIN" ]; then
        echo "⚠ Zig $VERSION not found at $ZIG_BIN"
        echo "   Run: ./scripts/download_zig_versions.sh"
        echo ""
        continue
    fi

    echo "Testing with Zig $VERSION..."

    OUTPUT_BIN="/tmp/${EXAMPLE_NAME}_${VERSION}"

    if "$ZIG_BIN" build-exe "$EXAMPLE_FILE" -femit-bin="$OUTPUT_BIN" 2>&1 | head -20; then
        echo "  ✓ Compilation successful"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

        # Optionally run the binary if requested
        if [ "${RUN_EXAMPLES:-}" = "1" ]; then
            echo "  Running..."
            if "$OUTPUT_BIN" 2>&1 | head -20; then
                echo "  ✓ Execution successful"
            else
                echo "  ✗ Execution failed"
            fi
        fi

        # Cleanup
        rm -f "$OUTPUT_BIN"
    else
        echo "  ✗ Compilation failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    echo ""
done

echo "Results: $SUCCESS_COUNT succeeded, $FAIL_COUNT failed"

if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
fi
