#!/usr/bin/env bash

# Test different color schemes with a sample color
SCHEMES=(
    "scheme-tonal-spot"
    "scheme-vibrant"
    "scheme-expressive"
    "scheme-fruit-salad"
    "scheme-rainbow"
    "scheme-monochrome"
    "scheme-neutral"
    "scheme-fidelity"
    "scheme-content"
)

# Default test color
COLOR="#91689E"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--color)
            COLOR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Test each scheme
for scheme in "${SCHEMES[@]}"; do
    echo "Testing scheme: $scheme"
    ./applycolor.sh "$COLOR" "dark" "$scheme"
    echo "Press Enter to try next scheme or Ctrl+C to exit"
    read
done 