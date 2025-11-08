#!/usr/bin/env bash

# Neovim Config Sync Script
# Usage: ./sync.sh [push|pull|install]

set -e

CONFIG_DIR="$HOME/.config/nvim"
SCRIPT_DIR="$CONFIG_DIR/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo ${ID}
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Push config to git
push_config() {
    log_info "Pushing config to git..."
    cd "$CONFIG_DIR"

    # Add all changes
    git add .

    # Commit with timestamp
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    HOSTNAME=$(hostname)
    git commit -m "Update from $HOSTNAME at $TIMESTAMP" || {
        log_warn "No changes to commit"
        return 0
    }

    # Push to remote
    git push origin main || git push origin master
    log_info "Config pushed successfully!"
}

# Pull config from git
pull_config() {
    log_info "Pulling latest config from git..."
    cd "$CONFIG_DIR"

    # Stash any local changes
    git stash

    # Pull latest
    git pull origin main || git pull origin master

    # Apply stashed changes if any
    git stash pop || true

    log_info "Config pulled successfully!"
    log_info "Run :Lazy sync in Neovim to update plugins"
}

# Install everything from scratch
install_full() {
    log_info "Installing full Neovim setup for $OS..."

    case "$OS" in
    macos)
        install_macos
        ;;
    ubuntu | debian)
        install_ubuntu
        ;;
    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
    esac

    # Common installation steps
    install_common

    log_info "Installation complete! 🎉"
    log_info "Open Neovim and run :Lazy sync to install plugins"
}

# macOS-specific installation
install_macos() {
    log_info "Installing macOS dependencies..."

    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install packages
    brew install neovim || brew upgrade neovim
    brew install tmux
    brew install node
    brew install python@3.11
    brew install ripgrep
    brew install fd
    brew install lazygit
    brew install --cask kitty # For image support in Molten

    # Python packages
    pip3 install --upgrade pip
    pip3 install pynvim jupyter_client cairosvg pnglatex plotly kaleido pyperclip nbformat
    pip3 install pyright ruff black isort debugpy ipython jupytext jupyter
    pip3 install pytest pytest-cov
}

# Ubuntu-specific installation
install_ubuntu() {
    log_info "Installing Ubuntu dependencies..."

    # Update package list
    sudo apt update

    # Add Neovim PPA for latest version
    sudo add-apt-repository ppa:neovim-ppa/stable -y
    sudo apt update

    # Install packages
    sudo apt install -y neovim
    sudo apt install -y tmux
    sudo apt install -y nodejs npm
    sudo apt install -y python3-pip python3-venv
    sudo apt install -y ripgrep fd-find
    sudo apt install -y git curl wget
    sudo apt install -y build-essential

    # Install lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit

    # Python packages
    pip3 install --user --upgrade pip
    pip3 install --user pynvim jupyter_client cairosvg pnglatex plotly kaleido pyperclip nbformat
    pip3 install --user pyright ruff black isort debugpy ipython jupytext jupyter
    pip3 install --user pytest pytest-cov
}

# Common installation steps
install_common() {
    log_info "Setting up common configurations..."

    # Backup existing config if it exists and isn't a git repo
    if [ -d "$CONFIG_DIR" ] && [ ! -d "$CONFIG_DIR/.git" ]; then
        log_warn "Backing up existing config to $CONFIG_DIR.backup"
        mv "$CONFIG_DIR" "$CONFIG_DIR.backup.$(date +%s)"
    fi

    # Clone config if it doesn't exist
    if [ ! -d "$CONFIG_DIR/.git" ]; then
        log_info "Cloning Neovim config..."
        git clone git@github.com:YOUR_USERNAME/nvim-config.git "$CONFIG_DIR" || {
            log_error "Failed to clone. Make sure you have SSH keys set up for GitHub"
            log_info "Alternatively, use HTTPS:"
            log_info "git clone https://github.com/YOUR_USERNAME/nvim-config.git $CONFIG_DIR"
            exit 1
        }
    fi

    # Update Neovim remote plugins
    nvim --headless "+UpdateRemotePlugins" +qa || true

    # Create necessary directories
    mkdir -p "$HOME/.local/share/nvim/backup"
    mkdir -p "$HOME/.local/share/nvim/undo"
    mkdir -p "$HOME/.local/share/nvim/swap"
}

# Main script logic
case "${1:-}" in
push)
    push_config
    ;;
pull)
    pull_config
    ;;
install)
    install_full
    ;;
*)
    echo "Neovim Config Sync Tool"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  push      Push local config to git"
    echo "  pull      Pull latest config from git"
    echo "  install   Install full Neovim setup on this machine"
    echo ""
    echo "Current OS detected: $OS"
    ;;
esac
