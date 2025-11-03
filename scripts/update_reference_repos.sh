#!/usr/bin/env bash
set -euo pipefail

# Script to checkout/update Zig reference repositories for the Zig Developer Guide
# These repos serve as exemplars of idiomatic Zig code and best practices

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_DIR="${REPOS_DIR:-$WORKSPACE_DIR/reference_repos}"

# Reference repositories from references.md
declare -A REPOS=(
    # Core Zig compiler & docs (contains documentation source for all versions)
    ["zig"]="https://github.com/ziglang/zig.git"

    # Major production projects (exemplars of idiomatic Zig)
    ["bun"]="https://github.com/oven-sh/bun.git"
    ["tigerbeetle"]="https://github.com/tigerbeetle/tigerbeetle.git"
    ["ghostty"]="https://github.com/ghostty-org/ghostty.git"
    ["mach"]="https://github.com/hexops/mach.git"
    ["zls"]="https://github.com/zigtools/zls.git"

    # Learning resources & tools
    ["ziglings"]="https://github.com/ratfactor/ziglings.git"
    ["zigmod"]="https://github.com/nektro/zigmod.git"

    # Curated lists & resources
    ["awesome-zig"]="https://github.com/zigcc/awesome-zig.git"
)

print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Zig Reference Repos Update Script${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

clone_or_update_repo() {
    local repo_name=$1
    local repo_url=$2
    local repo_path="$REPOS_DIR/$repo_name"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Processing: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ -d "$repo_path" ]; then
        print_info "Repository exists at: $repo_path"

        # Check if it's a git repository
        if [ -d "$repo_path/.git" ]; then
            print_info "Updating repository..."
            cd "$repo_path"

            # Fetch latest changes
            if git fetch --quiet 2>/dev/null; then
                # Check if we're on a branch
                current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

                if [ -n "$current_branch" ]; then
                    # Get status
                    local_commit=$(git rev-parse HEAD)
                    remote_commit=$(git rev-parse "@{u}" 2>/dev/null || echo "")

                    if [ "$local_commit" = "$remote_commit" ]; then
                        print_status "Already up to date on branch '$current_branch'"
                    else
                        # Check for local changes
                        if [ -n "$(git status --porcelain)" ]; then
                            print_warning "Local changes detected, skipping pull"
                            print_info "Run 'git pull' manually in $repo_path"
                        else
                            print_info "Pulling latest changes..."
                            if git pull --quiet; then
                                print_status "Updated successfully"
                            else
                                print_error "Failed to pull changes"
                            fi
                        fi
                    fi
                else
                    print_warning "Detached HEAD state, skipping update"
                    print_info "Current commit: $(git rev-parse --short HEAD)"
                fi
            else
                print_error "Failed to fetch from remote"
            fi

            cd - > /dev/null
        else
            print_error "Directory exists but is not a git repository: $repo_path"
        fi
    else
        print_info "Cloning repository to: $repo_path"

        # Create parent directory if needed
        mkdir -p "$REPOS_DIR"

        if git clone "$repo_url" "$repo_path"; then
            print_status "Cloned successfully"
        else
            print_error "Failed to clone repository"
            return 1
        fi
    fi
}

show_summary() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Summary${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""

    for repo_name in "${!REPOS[@]}"; do
        local repo_path="$REPOS_DIR/$repo_name"
        if [ -d "$repo_path/.git" ]; then
            cd "$repo_path"
            local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
            local commit=$(git rev-parse --short HEAD)
            echo -e "  ${GREEN}✓${NC} $repo_name: $branch @ $commit"
            cd - > /dev/null
        else
            echo -e "  ${RED}✗${NC} $repo_name: not available"
        fi
    done

    echo ""
    echo -e "${GREEN}Done!${NC} Reference repositories are in: $REPOS_DIR"
}

main() {
    print_header
    print_info "Target directory: $REPOS_DIR"
    print_info "Processing ${#REPOS[@]} repositories..."

    # Sort repo names for consistent output
    for repo_name in $(echo "${!REPOS[@]}" | tr ' ' '\n' | sort); do
        clone_or_update_repo "$repo_name" "${REPOS[$repo_name]}"
    done

    show_summary
}

# Check for git
if ! command -v git &> /dev/null; then
    print_error "git is not installed or not in PATH"
    exit 1
fi

# Parse command line options
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat << EOF
Usage: $0 [OPTIONS]

Checkout and update Zig reference repositories for the Zig Developer Guide.

Options:
  -h, --help     Show this help message

Environment Variables:
  REPOS_DIR      Directory where repos will be cloned (default: ./reference_repos)

Repositories:
EOF
    for repo_name in $(echo "${!REPOS[@]}" | tr ' ' '\n' | sort); do
        echo "  - $repo_name: ${REPOS[$repo_name]}"
    done
    exit 0
fi

main
