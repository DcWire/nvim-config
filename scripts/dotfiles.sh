#!/usr/bin/env bash

# Comprehensive Dotfiles Manager
# Manages nvim, tmux, zsh configs together

DOTFILES_REPO="git@github.com:YOUR_USERNAME/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Symlink all configs
setup_symlinks() {
    # Neovim
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

    # Tmux
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # Zsh
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

    # Git
    ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
}

# Initialize dotfiles repo
init_dotfiles() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    setup_symlinks
}

# Backup current configs to dotfiles
backup_to_dotfiles() {
    # Copy configs to dotfiles
    cp -r "$HOME/.config/nvim" "$DOTFILES_DIR/nvim"
    cp "$HOME/.tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf" 2>/dev/null || true
    cp "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc" 2>/dev/null || true
    cp "$HOME/.gitconfig" "$DOTFILES_DIR/git/.gitconfig" 2>/dev/null || true

    # Commit and push
    cd "$DOTFILES_DIR"
    git add .
    git commit -m "Update dotfiles $(date +%Y-%m-%d)"
    git push
}

case "$1" in
init)
    init_dotfiles
    ;;
backup)
    backup_to_dotfiles
    ;;
*)
    echo "Usage: $0 [init|backup]"
    ;;
esac
