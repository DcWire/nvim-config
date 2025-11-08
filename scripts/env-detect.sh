#!/usr/bin/env bash

# Environment Detection and Setup
# This script detects and configures environment-specific settings

CONFIG_DIR="$HOME/.config/nvim"
LOCAL_CONFIG="$CONFIG_DIR/lua/config/local.lua"

detect_terminal() {
    if [ -n "$KITTY_WINDOW_ID" ]; then
        echo "kitty"
    elif [ -n "$ITERM_SESSION_ID" ]; then
        echo "iterm2"
    elif [ -n "$TMUX" ]; then
        echo "tmux"
    else
        echo "unknown"
    fi
}

detect_python() {
    # Detect Python path
    if command -v python3 &>/dev/null; then
        which python3
    elif command -v python &>/dev/null; then
        which python
    else
        echo ""
    fi
}

# Generate local config
generate_local_config() {
    TERMINAL=$(detect_terminal)
    PYTHON_PATH=$(detect_python)

    cat >"$LOCAL_CONFIG" <<EOF
-- Auto-generated local configuration
-- Generated on $(date)

local M = {}

-- Terminal
M.terminal = "$TERMINAL"

-- Python path
M.python_path = "$PYTHON_PATH"

-- Image backend for Molten
if M.terminal == "kitty" then
    vim.g.molten_image_provider = "image.nvim"
    require("image").setup({
        backend = "kitty",
    })
elseif M.terminal == "iterm2" then
    vim.g.molten_image_provider = "image.nvim"
    require("image").setup({
        backend = "ueberzug",
    })
else
    vim.g.molten_image_provider = "none"
end

-- Python host
if M.python_path ~= "" then
    vim.g.python3_host_prog = M.python_path
end

return M
EOF

    echo "Local config generated at $LOCAL_CONFIG"
}

generate_local_config
