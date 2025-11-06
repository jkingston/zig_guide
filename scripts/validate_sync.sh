#!/bin/bash
# Validate that examples compile and are in sync with documentation
# Used by CI to ensure examples remain valid

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "========================================="
echo "Validating Zig Developer Guide Examples"
echo "========================================="
echo ""

# Check if zig is available
if ! command -v zig &> /dev/null; then
    echo "❌ Error: zig command not found"
    exit 1
fi

ZIG_VERSION=$(zig version)
echo "✓ Zig version: $ZIG_VERSION"
echo ""

# Count total chapters with examples
CHAPTER_COUNT=$(find examples -maxdepth 1 -type d -name "ch*" | wc -l)
echo "Found $CHAPTER_COUNT chapter directories with examples"
echo ""

# Validate each chapter's examples compile
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

for chapter_dir in examples/ch*/; do
    if [ ! -d "$chapter_dir" ]; then
        continue
    fi

    chapter_name=$(basename "$chapter_dir")

    # Check if build.zig exists
    if [ ! -f "${chapter_dir}build.zig" ]; then
        echo "⚠️  Skipping $chapter_name (no build.zig)"
        continue
    fi

    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    echo "Validating $chapter_name..."

    # Try to build - capture output and check exit code
    BUILD_OUTPUT=$(cd "$chapter_dir" && zig build 2>&1)
    BUILD_EXIT_CODE=$?

    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo "  ✓ Build successful"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ❌ Build failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        # Show the error (last 20 lines)
        echo "$BUILD_OUTPUT" | tail -20
    fi
done

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Total chapters validated: $TOTAL_COUNT"
echo "Successful builds: $SUCCESS_COUNT"
echo "Failed builds: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "❌ Validation FAILED - $FAIL_COUNT chapter(s) have build errors"
    exit 1
else
    echo "✅ Validation PASSED - All examples compile successfully!"
    exit 0
fi
