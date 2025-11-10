#!/usr/bin/env bash
set -euo pipefail

# Script to prepare mdBook sources from sections/ directory
# This copies all chapter content files to src/ for mdBook to build

echo "Preparing mdBook sources..."

# Create src directory if it doesn't exist
mkdir -p src

# Clean old generated files (but keep SUMMARY.md and README.md which are tracked)
rm -f src/ch*.md src/references.md src/style_guide.md

# Copy chapter content files
echo "Copying chapter files..."
cp sections/01_introduction/content.md src/ch01_introduction.md
cp sections/01_language_idioms/content.md src/ch01_language_idioms.md
cp sections/02_memory_allocators/content.md src/ch02_memory_allocators.md
cp sections/03_collections_containers/content.md src/ch03_collections_containers.md
cp sections/04_io_streams/content.md src/ch04_io_streams.md
cp sections/05_error_handling/content.md src/ch05_error_handling.md
cp sections/06_async_concurrency/content.md src/ch06_async_concurrency.md
cp sections/07_build_system/content.md src/ch07_build_system.md
cp sections/08_packages_dependencies/content.md src/ch08_packages_dependencies.md
cp sections/09_project_layout_ci/content.md src/ch09_project_layout_ci.md
cp sections/10_interoperability/content.md src/ch10_interoperability.md
cp sections/11_testing_benchmarking/content.md src/ch11_testing_benchmarking.md
cp sections/12_logging_diagnostics/content.md src/ch12_logging_diagnostics.md
cp sections/13_migration_guide/content.md src/ch13_migration_guide.md
cp sections/14_appendices/content.md src/ch14_appendices.md

# Copy reference materials
echo "Copying reference materials..."
cp references.md src/references.md
cp style_guide.md src/style_guide.md

echo "✓ mdBook sources prepared in src/"
echo "  - 15 chapter files (including Introduction)"
echo "  - 2 reference files"
echo ""
echo "Ready to build with: mdbook build"
