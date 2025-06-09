#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pre_process() {
    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
    if [ ! -d "$STATE_DIR"/user/generated ]; then
        mkdir -p "$STATE_DIR"/user/generated
    fi
}

get_current_wallpaper() {
    # Get the first monitor's wallpaper path
    swww query | grep -m1 "image: " | sed 's/.*image: //'
}

check_and_prompt_upscale() {
    local img="$1"
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)" # max monitor width
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)" # max monitor height

    if command -v identify &>/dev/null && [ -f "$img" ]; then
        local img_width img_height
        img_width=$(identify -format "%w" "$img" 2>/dev/null)
        img_height=$(identify -format "%h" "$img" 2>/dev/null)
        if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
            action=$(notify-send "Wallpaper Upscale" \
                "Image resolution (${img_width}x${img_height}) is lower than screen resolution (${min_width_desired}x${min_height_desired})" \
                -A "open_upscayl=Open Upscayl")
            if [[ "$action" == "open_upscayl" ]]; then
                if command -v upscayl &>/dev/null; then
                    nohup upscayl > /dev/null 2>&1 &
                else
                    action2=$(notify-send \
                        -a "Wallpaper" \
                        -c "im.error" \
                        -A "install_upscayl=Install Upscayl (Arch)" \
                        "Install Upscayl?" \
                        "yay -S upscayl-bin")
                    if [[ "$action2" == "install_upscayl" ]]; then
                        foot yay -S upscayl-bin
                        if command -v upscayl &>/dev/null; then
                            nohup upscayl > /dev/null 2>&1 &
                        fi
                    fi
                fi
            fi
        fi
    fi
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    saturation="${3:-0}"  # Default saturation
    brightness="${4:-0}"  # Default brightness

    if [[ -z "$imgpath" ]]; then
        echo 'No image path provided'
        exit 1
    fi

    if [[ "$noswitch_flag" != "1" ]]; then
        # Set wallpaper with swww
        swww img "$imgpath" --transition-step 100 --transition-fps 120 \
            --transition-type grow --transition-angle 30 --transition-duration 1
    fi

    # Determine mode if not set
    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    pre_process

    # Use walrs to set wallpaper and generate colors
    # -i: input image
    # -R: reload with new wallpaper
    # -s: saturation adjustment
    # -b: brightness adjustment
    walrs -i "$imgpath" -R -s "$saturation" -b "$brightness"
}

main() {
    imgpath=""
    mode_flag=""
    noswitch_flag=""
    saturation="0"
    brightness="0"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                shift
                ;;
            --saturation)
                saturation="$2"
                shift 2
                ;;
            --brightness)
                brightness="$2"
                shift 2
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                else
                    echo "Unexpected argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    switch "$imgpath" "$mode_flag" "$saturation" "$brightness"
}

main "$@"