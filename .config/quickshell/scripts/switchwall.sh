#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
terminalscheme="$XDG_CONFIG_HOME/quickshell/scripts/terminal/scheme-base.json"

pre_process() {
    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
    if [ ! -d "$STATE_DIR"/user/generated ]; then
        mkdir -p "$STATE_DIR"/user/generated
    fi
}

post_process() {
    local mode_flag="$1"
    # Set GNOME color-scheme if mode_flag is dark or light
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
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

THUMBNAIL_DIR="/tmp/mpvpaper_thumbnails"
CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "mkv" || "$extension" == "webm" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" &
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"

    if [[ "$color_flag" == "1" ]]; then
        matugen_args=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo 'No image path provided'
            exit 1
        fi

        if [[ "$noswitch_flag" != "1" ]]; then
            # Set wallpaper with swww
            swww img "$imgpath" --transition-step 100 --transition-fps 120 \
                --transition-type grow --transition-angle 30 --transition-duration 1
        fi

        matugen_args=(image "$imgpath")
        generate_colors_material_args=(--path "$imgpath")
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

    [[ -n "$mode_flag" ]] && matugen_args+=(--mode "$mode_flag") && generate_colors_material_args+=(--mode "$mode_flag")
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/color.txt")

    pre_process

    matugen "${matugen_args[@]}"
    source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
    python "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    "$SCRIPT_DIR"/applycolor.sh
    deactivate

    post_process "$mode_flag"
}

main() {
    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                color_flag="1"
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    color="$2"
                    shift 2
                else
                    color=$(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --noswitch)
                noswitch_flag="1"
                imgpath=$(get_current_wallpaper)
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        imgpath="$(yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper')"
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color"
}

main "$@"