#!/usr/bin/env bash
set -euo pipefail

# Script to test all code examples in the Zig Developer Guide
# Tests standalone .zig files and build projects across multiple Zig versions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Find Zig binary
find_zig() {
    if command -v zig &> /dev/null; then
        ZIG_BIN=$(command -v zig)
        ZIG_VERSION=$($ZIG_BIN version)
        log_info "Using Zig: $ZIG_BIN (version $ZIG_VERSION)"
        return 0
    else
        log_error "Zig not found in PATH. Please install Zig."
        return 1
    fi
}

# Test a standalone .zig file
test_standalone_file() {
    local file=$1
    local test_name=$(basename "$file")
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Testing: $test_name"
    
    if $ZIG_BIN test "$file" > /tmp/zig_test_output.log 2>&1; then
        log_pass "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_fail "$test_name"
        log_error "Output:"
        cat /tmp/zig_test_output.log
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Test a build project
test_build_project() {
    local project_dir=$1
    local test_name=$(basename "$project_dir")
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Building: $test_name"
    
    pushd "$project_dir" > /dev/null
    
    if $ZIG_BIN build > /tmp/zig_build_output.log 2>&1; then
        log_pass "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        popd > /dev/null
        return 0
    else
        log_fail "$test_name"
        log_error "Output:"
        cat /tmp/zig_build_output.log
        FAILED_TESTS=$((FAILED_TESTS + 1))
        popd > /dev/null
        return 1
    fi
}

# Main testing logic
main() {
    log_info "====================================="
    log_info "Zig Developer Guide - Code Examples Test"
    log_info "====================================="
    echo ""
    
    # Find Zig
    if ! find_zig; then
        exit 1
    fi
    echo ""
    
    # Test standalone example files
    log_info "Testing standalone .zig examples..."
    echo ""
    
    for example_file in "$REPO_ROOT"/sections/*/example_*.zig; do
        if [ -f "$example_file" ]; then
            test_standalone_file "$example_file"
            echo ""
        fi
    done
    
    # Test build projects
    log_info "Testing build projects..."
    echo ""
    
    for examples_dir in "$REPO_ROOT"/sections/*/examples/*/; do
        if [ -d "$examples_dir" ] && [ -f "$examples_dir/build.zig" ]; then
            test_build_project "$examples_dir"
            echo ""
        fi
    done
    
    # Summary
    echo ""
    log_info "====================================="
    log_info "Test Summary"
    log_info "====================================="
    echo "Total tests:   $TOTAL_TESTS"
    echo -e "${GREEN}Passed:        $PASSED_TESTS${NC}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "${RED}Failed:        $FAILED_TESTS${NC}"
    else
        echo "Failed:        $FAILED_TESTS"
    fi
    
    if [ $SKIPPED_TESTS -gt 0 ]; then
        echo -e "${YELLOW}Skipped:       $SKIPPED_TESTS${NC}"
    else
        echo "Skipped:       $SKIPPED_TESTS"
    fi
    
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_info "All tests passed! ✅"
        exit 0
    else
        log_error "Some tests failed. ❌"
        exit 1
    fi
}

# Run main
main "$@"
