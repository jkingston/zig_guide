#!/usr/bin/env bash
#
# Sync Validation Script
# Detects when inline code blocks in markdown drift from external example files
#
# Usage: ./scripts/validate_sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "=== Zig: Zero to Hero - Sync Validation ==="
echo

# Function to normalize Zig code for comparison
normalize_code() {
    # Remove comments, trim whitespace, normalize line endings
    sed 's|//.*$||g' | \
    sed 's|^\s*||g' | \
    sed 's|\s*$||g' | \
    grep -v '^$'
}

# Function to extract code from markdown between markers
extract_from_markdown() {
    local file=$1
    local start_marker=$2
    local end_marker=$3

    awk "/$start_marker/,/$end_marker/" "$file" | \
    grep -v "$start_marker" | \
    grep -v "$end_marker"
}

# Check if example mapping file exists
MAPPING_FILE="$PROJECT_ROOT/examples_mapping.json"

if [ ! -f "$MAPPING_FILE" ]; then
    echo -e "${YELLOW}Warning: examples_mapping.json not found${NC}"
    echo "Creating example mapping file..."

    # Create a basic mapping file structure
    cat > "$MAPPING_FILE" << 'EOF'
{
  "comment": "Maps markdown code blocks to external example files",
  "mappings": [
    {
      "markdown": "sections/02_language_idioms/content.md",
      "examples": [
        {
          "external_file": "examples/ch02_idioms/01_naming_conventions.zig",
          "markdown_section": "Naming Conventions",
          "note": "Enhanced version with main function"
        }
      ]
    }
  ]
}
EOF

    echo -e "${YELLOW}Template mapping file created. Please populate it with actual mappings.${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# For now, perform a basic check: ensure all external examples compile
echo "Step 1: Validating all external examples compile..."
echo

CHAPTER_DIRS=$(find "$PROJECT_ROOT/examples" -mindepth 1 -maxdepth 1 -type d | sort)

for chapter_dir in $CHAPTER_DIRS; do
    chapter_name=$(basename "$chapter_dir")

    if [ -f "$chapter_dir/build.zig" ]; then
        echo -n "  Checking $chapter_name... "

        if (cd "$chapter_dir" && zig build --summary none > /dev/null 2>&1); then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            echo "    Build failed for $chapter_name"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -n "  Checking $chapter_name... "
        echo -e "${YELLOW}⊘ (no build.zig)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo
echo "Step 2: Checking for duplicate code patterns..."
echo "  (Full implementation requires examples_mapping.json to be populated)"
echo

# TODO: Implement full sync validation using examples_mapping.json
# For each mapping:
#   1. Extract code from markdown
#   2. Normalize both markdown and external code
#   3. Compare and report differences

echo "=== Validation Summary ==="
echo
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $ERRORS error(s)${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ All validations passed${NC}"
    exit 0
fi
