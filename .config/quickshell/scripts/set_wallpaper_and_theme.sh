#!/bin/bash

# Usage: ./set_wallpaper_and_theme.sh /path/to/wallpaper.jpg

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: $0 /path/to/wallpaper.jpg"
    exit 1
fi

# 1. Set the wallpaper (using swww)
swww img "$WALLPAPER"

# 2. Generate new colors from the wallpaper
python "$HOME/.config/quickshell/scripts/generate_colors_material.py" --path "$WALLPAPER"

# 3. Apply the new GTK theme/colors
"$HOME/.config/quickshell/scripts/apply_gtk_colors.sh"

echo "Wallpaper, color generation, and GTK theming applied!" 