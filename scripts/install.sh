#!/bin/bash
set -e

# Configuration
REPO="MohammedElMO/lsrs"  # Replace with your actual repo
BINARY_NAME="lsrs"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case $arch in
        x86_64) arch="x86_64" ;;
        arm64|aarch64) arch="aarch64" ;;
        *) log_error "Unsupported architecture: $arch" && exit 1 ;;
    esac

    case $os in
        linux)
            echo "x86_64-unknown-linux-gnu"
            ;;
        darwin)
            if [[ $arch == "aarch64" ]]; then
                echo "aarch64-apple-darwin"
            else
                echo "x86_64-apple-darwin"
            fi
            ;;
        mingw*|msys*|cygwin*)
            log_error "Windows detected. Please use PowerShell install script or download manually."
            exit 1
            ;;
        *)
            log_error "Unsupported OS: $os"
            exit 1
            ;;
    esac
}

# Get latest release version
get_latest_version() {
    log_info "Fetching latest release..."
    curl -s "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name"' \
        | cut -d'"' -f4 \
        | sed 's/^v//'
}

# Download and install
install_binary() {
    local platform=$1
    local version=$2
    local archive_name="${BINARY_NAME}-${platform}.tar.gz"
    local download_url="https://github.com/$REPO/releases/download/v$version/$archive_name"

    log_info "Downloading $BINARY_NAME v$version for $platform..."

    # Create temp directory
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    # Download and extract
    if ! curl -L "$download_url" | tar xz; then
        log_error "Failed to download or extract $archive_name"
        log_error "Please check if the release exists: https://github.com/$REPO/releases"
        exit 1
    fi

    # Check if binary exists
    if [[ ! -f "$BINARY_NAME" ]]; then
        log_error "Binary $BINARY_NAME not found in archive"
        exit 1
    fi

    # Make executable
    chmod +x "$BINARY_NAME"

    # Install binary
    log_info "Installing to $INSTALL_DIR..."

    # Check if we need sudo
    if [[ ! -w "$INSTALL_DIR" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
        else
            log_error "No write permission to $INSTALL_DIR and sudo not available"
            log_error "Try running with: INSTALL_DIR=~/.local/bin $0"
            exit 1
        fi
    else
        mv "$BINARY_NAME" "$INSTALL_DIR/"
    fi

    # Cleanup
    cd - >/dev/null
    rm -rf "$tmp_dir"

    log_info "✅ $BINARY_NAME installed successfully!"
}

# Verify installation
verify_installation() {
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local installed_version=$($BINARY_NAME --version 2>/dev/null | head -n1)
        log_info "🎉 Installation verified: $installed_version"
        log_info "Run '$BINARY_NAME --help' to get started"
    else
        log_warn "Binary installed but not found in PATH"
        log_warn "You may need to add $INSTALL_DIR to your PATH"
        log_warn "Or try running: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
}

# Main execution
main() {
    log_info "Installing $BINARY_NAME..."

    # Check dependencies
    for cmd in curl tar; do
        if ! command -v $cmd >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done

    local platform=$(detect_platform)
    local version=$(get_latest_version)

    if [[ -z "$version" ]]; then
        log_error "Could not fetch latest version"
        exit 1
    fi

    log_info "Latest version: v$version"
    log_info "Platform: $platform"
    log_info "Install directory: $INSTALL_DIR"

    install_binary "$platform" "$version"
    verify_installation
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  INSTALL_DIR    Installation directory (default: /usr/local/bin)"
        echo ""
        echo "Examples:"
        echo "  $0                           # Install to /usr/local/bin"
        echo "  INSTALL_DIR=~/.local/bin $0  # Install to ~/.local/bin"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac