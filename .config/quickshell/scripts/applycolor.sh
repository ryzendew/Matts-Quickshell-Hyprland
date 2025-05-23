#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create necessary directories
mkdir -p "$STATE_DIR/user/generated"
mkdir -p "$CONFIG_DIR/style"

apply_colors() {
    local color="$1"
    local mode="${2:-dark}"
    local scheme="${3:-scheme-tonal-spot}"

    # Generate colors using our Python script
    python "$SCRIPT_DIR/generate_colors.py" \
        --color "$color" \
        --mode "$mode" \
        --scheme "$scheme" \
        --output "$CONFIG_DIR/style/colors.qml"

    # Try to reload QuickShell components gracefully first
    if pkill -USR1 -f "quickshell"; then
        # Wait a bit to let the reload take effect
        sleep 1
        return 0
    fi

    # If QuickShell is not running or reload failed, start it
    if ! pgrep -f "quickshell" > /dev/null; then
        quickshell &>/dev/null &
    fi
}

# If no arguments provided, use default color
if [ $# -eq 0 ]; then
    apply_colors "#91689E"
else
    apply_colors "$@"
fi
