#!/usr/bin/env bash

# Quick Setup Script - Run this on a new machine
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nvim-config/main/scripts/setup.sh | bash

set -e

echo "🚀 Setting up Neovim configuration..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="ubuntu"
else
    echo "Unsupported OS"
    exit 1
fi

# Install git if not present
if ! command -v git &>/dev/null; then
    echo "Installing git..."
    if [ "$OS" = "macos" ]; then
        brew install git
    else
        sudo apt update && sudo apt install -y git
    fi
fi

# Clone the config
echo "Cloning Neovim config..."
if [ -d "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi

git clone https://github.com/YOUR_USERNAME/nvim-config.git "$HOME/.config/nvim"

# Make scripts executable
chmod +x "$HOME/.config/nvim/scripts/"*.sh

# Run install
"$HOME/.config/nvim/scripts/sync.sh" install

echo "✅ Setup complete! Open nvim and run :Lazy sync"
