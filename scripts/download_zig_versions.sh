#!/usr/bin/env bash
# Script to download multiple Zig versions for testing code examples
# Usage: ./scripts/download_zig_versions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ZIG_VERSIONS_DIR="$PROJECT_ROOT/zig_versions"

# Target versions from VERSIONING.md
VERSIONS=(
    "0.14.0"
    "0.14.1"
    "0.15.1"
    "0.15.2"
)

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        OS_NAME="linux"
        ;;
    Darwin)
        OS_NAME="macos"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64)
        ARCH_NAME="x86_64"
        ;;
    aarch64|arm64)
        ARCH_NAME="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected platform: $OS_NAME-$ARCH_NAME"
echo "Installing Zig versions to: $ZIG_VERSIONS_DIR"
echo ""

# Create versions directory
mkdir -p "$ZIG_VERSIONS_DIR"

# Download and extract each version
for VERSION in "${VERSIONS[@]}"; do
    VERSION_DIR="$ZIG_VERSIONS_DIR/zig-$VERSION"

    if [ -d "$VERSION_DIR" ] && [ -f "$VERSION_DIR/zig" ]; then
        echo "✓ Zig $VERSION already installed"
        continue
    fi

    echo "Downloading Zig $VERSION..."

    # Construct download URL - format changed after 0.14.0
    if [[ "$VERSION" == "0.14.0" ]]; then
        TARBALL="zig-$OS_NAME-$ARCH_NAME-$VERSION.tar.xz"
        EXTRACTED_NAME="zig-$OS_NAME-$ARCH_NAME-$VERSION"
    else
        TARBALL="zig-$ARCH_NAME-$OS_NAME-$VERSION.tar.xz"
        EXTRACTED_NAME="zig-$ARCH_NAME-$OS_NAME-$VERSION"
    fi
    URL="https://ziglang.org/download/$VERSION/$TARBALL"

    # Download to temp location with retry logic
    TEMP_FILE="$ZIG_VERSIONS_DIR/$TARBALL"

    # Try up to 3 times with delays
    DOWNLOAD_SUCCESS=false
    for attempt in 1 2 3; do
        if curl --retry 2 --retry-delay 2 -L -o "$TEMP_FILE" "$URL"; then
            DOWNLOAD_SUCCESS=true
            break
        fi
        echo "  Download attempt $attempt failed, retrying..."
        sleep 2
    done

    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "Failed to download Zig $VERSION after 3 attempts"
        echo "URL: $URL"
        rm -f "$TEMP_FILE"
        continue
    fi

    echo "Extracting Zig $VERSION..."

    # Extract
    tar -xf "$TEMP_FILE" -C "$ZIG_VERSIONS_DIR"

    # Rename to consistent directory name
    EXTRACTED_DIR="$ZIG_VERSIONS_DIR/$EXTRACTED_NAME"
    if [ -d "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "$VERSION_DIR"
    fi

    # Clean up tarball
    rm -f "$TEMP_FILE"

    # Verify installation
    if [ -f "$VERSION_DIR/zig" ]; then
        INSTALLED_VERSION=$("$VERSION_DIR/zig" version)
        echo "✓ Zig $VERSION installed successfully (reports: $INSTALLED_VERSION)"
    else
        echo "✗ Failed to install Zig $VERSION"
    fi

    echo ""
done

echo "Installation complete!"
echo ""
echo "Installed versions:"
for VERSION in "${VERSIONS[@]}"; do
    VERSION_DIR="$ZIG_VERSIONS_DIR/zig-$VERSION"
    if [ -f "$VERSION_DIR/zig" ]; then
        echo "  $VERSION: $VERSION_DIR/zig"
    fi
done

echo ""
echo "To use a specific version:"
echo "  $ZIG_VERSIONS_DIR/zig-0.15.2/zig build-exe example.zig"
