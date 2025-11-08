#!/usr/bin/env bash

# Neovim Config Sync Script with GLIBC Fix
# Usage: ./sync.sh [push|pull|install]

set -e

CONFIG_DIR="$HOME/.config/nvim"
SCRIPT_DIR="$CONFIG_DIR/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Detect OS and version
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

# Get Ubuntu version
get_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo ${VERSION_ID}
    else
        echo "unknown"
    fi
}

# Check GLIBC version
check_glibc_version() {
    local glibc_version=$(ldd --version | head -1 | awk '{print $NF}')
    echo "$glibc_version"
}

OS=$(detect_os)
UBUNTU_VERSION=$(get_ubuntu_version)
GLIBC_VERSION=$(check_glibc_version)

# Install Neovim based on system compatibility
install_neovim() {
    local os=$1
    local ubuntu_version=$2
    local glibc_version=$3

    log_info "Installing Neovim for $os (Ubuntu $ubuntu_version, GLIBC $glibc_version)..."

    # Remove any existing broken installations
    sudo apt remove --purge neovim neovim-runtime -y 2>/dev/null || true
    sudo rm -f /usr/local/bin/nvim 2>/dev/null || true
    sudo rm -f /usr/bin/nvim 2>/dev/null || true
    hash -r # Clear bash cache

    if [[ "$os" == "ubuntu" ]] || [[ "$os" == "debian" ]]; then
        # For Ubuntu 20.04 or GLIBC < 2.32, use AppImage
        if [[ "$ubuntu_version" == "20.04" ]] || [[ $(echo "$glibc_version < 2.32" | bc -l) == 1 ]]; then
            log_warn "Detected older GLIBC version. Using AppImage installation..."
            install_neovim_appimage
        else
            # For newer systems, try PPA first, fallback to AppImage
            log_info "Installing from PPA..."
            if ! install_neovim_ppa; then
                log_warn "PPA installation failed, falling back to AppImage..."
                install_neovim_appimage
            fi
        fi
    elif [[ "$os" == "macos" ]]; then
        install_neovim_macos
    fi

    # Verify installation
    if command -v nvim &>/dev/null; then
        log_info "✅ Neovim installed successfully!"
        nvim --version | head -1
    else
        log_error "❌ Neovim installation failed!"
        exit 1
    fi
}

# Install Neovim via AppImage (most compatible)
install_neovim_appimage() {
    log_info "Installing Neovim via AppImage..."

    cd /tmp

    # Try latest version first
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"

    # For Ubuntu 20.04, use a compatible version
    if [[ "$UBUNTU_VERSION" == "20.04" ]]; then
        nvim_url="https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage"
    fi

    curl -LO "$nvim_url"
    chmod u+x nvim.appimage

    # Test if it works
    if ./nvim.appimage --version &>/dev/null; then
        sudo mv nvim.appimage /usr/local/bin/nvim
        return 0
    else
        log_error "AppImage doesn't work on this system"
        return 1
    fi
}

# Install Neovim via PPA
install_neovim_ppa() {
    log_info "Installing Neovim from PPA..."

    sudo add-apt-repository ppa:neovim-ppa/stable -y
    sudo apt update
    sudo apt install neovim -y

    # Test if it works
    if nvim --version &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Install Neovim on macOS
install_neovim_macos() {
    if command -v brew &>/dev/null; then
        brew install neovim || brew upgrade neovim
    else
        log_error "Homebrew not installed. Please install it first."
        exit 1
    fi
}

# Fix APT repository issues
fix_apt_repos() {
    log_info "Checking APT repositories..."

    # Backup sources.list
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%s)

    # Remove malformed entries
    sudo sed -i '/\$(lsb_release/d' /etc/apt/sources.list
    sudo find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i '/\$(lsb_release/d' {} \; 2>/dev/null || true

    # Remove duplicates
    sudo awk '!seen[$0]++' /etc/apt/sources.list >/tmp/sources.list.tmp && sudo mv /tmp/sources.list.tmp /etc/apt/sources.list

    # Update
    sudo apt clean
    sudo apt update || {
        log_warn "APT update failed. Attempting to fix..."
        # Create clean sources.list for Ubuntu
        local codename=$(lsb_release -cs)
        cat <<EOF | sudo tee /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu $codename main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $codename-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $codename-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $codename-security main restricted universe multiverse
EOF
        sudo apt update
    }
}

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

    # Fix APT issues first (for Ubuntu/Debian)
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        fix_apt_repos
    fi

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

    # Install Neovim
    install_neovim "macos" "" ""

    # Install other packages
    brew install tmux node python@3.11 ripgrep fd lazygit
    brew install --cask kitty # For image support

    # Python packages
    pip3 install --upgrade pip
    pip3 install pynvim jupyter_client cairosvg pnglatex plotly kaleido pyperclip nbformat
    pip3 install pyright ruff black isort debugpy ipython jupytext jupyter
    pip3 install pytest pytest-cov
}

# Ubuntu-specific installation
install_ubuntu() {
    log_info "Installing Ubuntu dependencies..."
    log_info "Ubuntu version: $UBUNTU_VERSION, GLIBC: $GLIBC_VERSION"

    # Update package list
    sudo apt update

    # Install Neovim with GLIBC detection
    install_neovim "$OS" "$UBUNTU_VERSION" "$GLIBC_VERSION"

    # Install other dependencies
    sudo apt install -y tmux git curl wget build-essential

    # Install Node.js
    if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    # Install Python and pip
    sudo apt install -y python3-pip python3-venv

    # Install modern CLI tools
    sudo apt install -y ripgrep fd-find

    # Create fd symlink
    if [ -f /usr/bin/fdfind ]; then
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
    fi

    # Install lazygit
    if ! command -v lazygit &>/dev/null; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        cd /tmp && tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm -f /tmp/lazygit.tar.gz /tmp/lazygit
    fi

    # Python packages
    pip3 install --user --upgrade pip
    pip3 install --user pynvim jupyter_client cairosvg pnglatex plotly kaleido pyperclip nbformat
    pip3 install --user pyright ruff black isort debugpy ipython jupytext jupyter
    pip3 install --user pytest pytest-cov
}

# Common installation steps
install_common() {
    log_info "Setting up common configurations..."

    # Ensure .local/bin is in PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.zshrc 2>/dev/null || true
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Backup existing config if it exists and isn't a git repo
    if [ -d "$CONFIG_DIR" ] && [ ! -d "$CONFIG_DIR/.git" ]; then
        log_warn "Backing up existing config to $CONFIG_DIR.backup"
        mv "$CONFIG_DIR" "$CONFIG_DIR.backup.$(date +%s)"
    fi

    # Clone config if it doesn't exist
    if [ ! -d "$CONFIG_DIR/.git" ]; then
        log_info "Cloning Neovim config..."
        # Replace with your actual repo
        git clone https://github.com/YOUR_USERNAME/nvim-config.git "$CONFIG_DIR" || {
            log_error "Failed to clone. Make sure to update the repository URL!"
            exit 1
        }
    fi

    # Make scripts executable
    chmod +x "$CONFIG_DIR/scripts/"*.sh 2>/dev/null || true

    # Update Neovim remote plugins
    if command -v nvim &>/dev/null; then
        nvim --headless "+UpdateRemotePlugins" +qa || true
    fi

    # Create necessary directories
    mkdir -p "$HOME/.local/share/nvim/backup"
    mkdir -p "$HOME/.local/share/nvim/undo"
    mkdir -p "$HOME/.local/share/nvim/swap"
}

# Health check function
health_check() {
    log_info "Running health check..."

    echo -e "\n${BLUE}System Information:${NC}"
    echo "OS: $OS"
    [[ "$OS" == "ubuntu" ]] && echo "Ubuntu Version: $UBUNTU_VERSION"
    echo "GLIBC Version: $GLIBC_VERSION"

    echo -e "\n${BLUE}Dependencies:${NC}"

    # Check Neovim
    if command -v nvim &>/dev/null; then
        echo "✅ Neovim: $(nvim --version | head -1)"
    else
        echo "❌ Neovim: Not installed"
    fi

    # Check Python
    if command -v python3 &>/dev/null; then
        echo "✅ Python: $(python3 --version)"
    else
        echo "❌ Python: Not installed"
    fi

    # Check Node
    if command -v node &>/dev/null; then
        echo "✅ Node: $(node --version)"
    else
        echo "❌ Node: Not installed"
    fi

    # Check Git
    if command -v git &>/dev/null; then
        echo "✅ Git: $(git --version | cut -d' ' -f3)"
    else
        echo "❌ Git: Not installed"
    fi

    # Check ripgrep
    if command -v rg &>/dev/null; then
        echo "✅ Ripgrep: $(rg --version | head -1)"
    else
        echo "❌ Ripgrep: Not installed"
    fi

    # Check pynvim
    if python3 -c "import pynvim" 2>/dev/null; then
        echo "✅ Pynvim: Installed"
    else
        echo "❌ Pynvim: Not installed"
    fi

    echo -e "\n${BLUE}Neovim Config:${NC}"
    if [ -d "$CONFIG_DIR/.git" ]; then
        echo "✅ Config directory: $CONFIG_DIR"
        cd "$CONFIG_DIR"
        echo "   Git remote: $(git remote get-url origin 2>/dev/null || echo 'Not set')"
        echo "   Branch: $(git branch --show-current)"
    else
        echo "❌ Config not found at $CONFIG_DIR"
    fi
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
health | check)
    health_check
    ;;
fix-nvim)
    install_neovim "$OS" "$UBUNTU_VERSION" "$GLIBC_VERSION"
    ;;
*)
    echo "Neovim Config Sync Tool"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install   Install full Neovim setup on this machine"
    echo "  push      Push local config to git"
    echo "  pull      Pull latest config from git"
    echo "  health    Run health check"
    echo "  fix-nvim  Fix Neovim installation issues"
    echo ""
    echo "System Info:"
    echo "  OS: $OS"
    [[ "$OS" == "ubuntu" ]] && echo "  Ubuntu: $UBUNTU_VERSION (GLIBC $GLIBC_VERSION)"
    ;;
esac
