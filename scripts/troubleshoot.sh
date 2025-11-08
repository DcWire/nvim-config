#!/usr/bin/env bash

# Troubleshooting script for common issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Fix GLIBC issues
fix_glibc() {
    log_section "Fixing GLIBC Issues"

    # Check current GLIBC version
    local glibc_version=$(ldd --version | head -1 | awk '{print $NF}')
    log_info "Current GLIBC version: $glibc_version"

    # Remove broken nvim
    log_info "Removing potentially broken Neovim installations..."
    sudo apt remove --purge neovim neovim-runtime -y 2>/dev/null || true
    sudo rm -f /usr/local/bin/nvim /usr/bin/nvim 2>/dev/null || true

    # Install via AppImage
    log_info "Installing Neovim via AppImage (most compatible)..."
    cd /tmp
    curl -LO https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim

    # Test
    if nvim --version &>/dev/null; then
        log_info "✅ Neovim fixed and working!"
    else
        log_error "Still having issues. Try building from source."
    fi
}

# Fix APT repositories
fix_apt() {
    log_section "Fixing APT Repositories"

    # Backup
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%s)

    # Remove bad entries
    log_info "Removing malformed entries..."
    sudo sed -i '/\$(lsb_release/d' /etc/apt/sources.list
    sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/\$(lsb_release/d' {} \; 2>/dev/null || true

    # Remove duplicates
    sudo awk '!seen[$0]++' /etc/apt/sources.list >/tmp/sources.list.tmp
    sudo mv /tmp/sources.list.tmp /etc/apt/sources.list

    # Update
    sudo apt clean
    sudo apt update

    log_info "✅ APT repositories fixed!"
}

# Fix Python/pynvim issues
fix_python() {
    log_section "Fixing Python/Pynvim"

    # Install pip if missing
    if ! command -v pip3 &>/dev/null; then
        log_info "Installing pip3..."
        sudo apt install -y python3-pip
    fi

    # Install pynvim
    log_info "Installing pynvim..."
    pip3 install --user --upgrade pynvim

    # Update remote plugins
    if command -v nvim &>/dev/null; then
        nvim --headless "+UpdateRemotePlugins" +qa
        log_info "✅ Python support fixed!"
    fi
}

# Fix all common issues
fix_all() {
    log_section "Running Complete Fix"

    # Fix APT first
    fix_apt

    # Fix GLIBC/Neovim
    fix_glibc

    # Fix Python
    fix_python

    # Run health check
    "$HOME/.config/nvim/scripts/sync.sh" health
}

# Main menu
case "${1:-}" in
glibc)
    fix_glibc
    ;;
apt)
    fix_apt
    ;;
python)
    fix_python
    ;;
all)
    fix_all
    ;;
*)
    echo "Neovim Troubleshooting Tool"
    echo ""
    echo "Usage: $0 [issue]"
    echo ""
    echo "Issues:"
    echo "  glibc   Fix GLIBC version errors"
    echo "  apt     Fix APT repository issues"
    echo "  python  Fix Python/pynvim issues"
    echo "  all     Fix all common issues"
    echo ""
    echo "Example: $0 glibc"
    ;;
esac
