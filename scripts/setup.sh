#!/usr/bin/env bash

# Quick Setup Script with GLIBC Detection
# Run: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nvim-config/main/scripts/setup.sh | bash

set -e

echo "🚀 Setting up Neovim configuration..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="ubuntu"
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_VERSION=${VERSION_ID}
        log_info "Detected Ubuntu $UBUNTU_VERSION"
    fi
else
    log_error "Unsupported OS"
    exit 1
fi

# Install git if not present
if ! command -v git &>/dev/null; then
    log_info "Installing git..."
    if [ "$OS" = "macos" ]; then
        brew install git
    else
        sudo apt update && sudo apt install -y git
    fi
fi

# Clone the config
log_info "Setting up Neovim config..."
if [ -d "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
    log_warn "Existing config backed up"
fi

# Replace with your repo URL
git clone https://github.com/YOUR_USERNAME/nvim-config.git "$HOME/.config/nvim"

# Make scripts executable
chmod +x "$HOME/.config/nvim/scripts/"*.sh

# Run full installation
log_info "Running full installation..."
"$HOME/.config/nvim/scripts/sync.sh" install

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open Neovim: nvim"
echo "2. Wait for plugins to install automatically"
echo "3. Or run :Lazy sync manually"
echo ""
echo "Run health check: ~/.config/nvim/scripts/sync.sh health"cho "✅ Setup complete! Open nvim and run :Lazy sync"
