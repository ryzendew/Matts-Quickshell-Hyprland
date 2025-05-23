#!/usr/bin/env python3

import os
import sys
import json
import argparse
from pathlib import Path
from materialyoucolor.hct import Hct
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant
from materialyoucolor.scheme.scheme_expressive import SchemeExpressive
from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad
from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow
from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome
from materialyoucolor.scheme.scheme_neutral import SchemeNeutral
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity
from materialyoucolor.scheme.scheme_content import SchemeContent
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors

def rgba_to_hex(rgba):
    r, g, b, _ = rgba
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

def hex_to_argb(hex_color):
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    return (1.0, r, g, b)

def main():
    parser = argparse.ArgumentParser(description='Generate Material You colors for QuickShell')
    parser.add_argument('--color', help='Hex color code (e.g. #FF0000)')
    parser.add_argument('--path', help='Path to image file')
    parser.add_argument('--mode', choices=['light', 'dark'], default='dark', help='Color scheme mode')
    parser.add_argument('--scheme', choices=[
        'scheme-tonal-spot', 'scheme-vibrant', 'scheme-expressive',
        'scheme-fruit-salad', 'scheme-rainbow', 'scheme-monochrome',
        'scheme-neutral', 'scheme-fidelity', 'scheme-content'
    ], default='scheme-tonal-spot', help='Color scheme type')
    parser.add_argument('--output', help='Output file path')
    
    args = parser.parse_args()

    if not args.color and not args.path:
        print("Error: Either --color or --path must be specified")
        sys.exit(1)

    # Get source color
    if args.color:
        source_color = hex_to_argb(args.color)
        hct = Hct.from_argb(*source_color)
    else:
        # TODO: Implement image color extraction
        print("Error: Image color extraction not implemented yet")
        sys.exit(1)

    # Set dark mode
    darkmode = args.mode == 'dark'

    # Select scheme class
    scheme_map = {
        'scheme-tonal-spot': SchemeTonalSpot,
        'scheme-vibrant': SchemeVibrant,
        'scheme-expressive': SchemeExpressive,
        'scheme-fruit-salad': SchemeFruitSalad,
        'scheme-rainbow': SchemeRainbow,
        'scheme-monochrome': SchemeMonochrome,
        'scheme-neutral': SchemeNeutral,
        'scheme-fidelity': SchemeFidelity,
        'scheme-content': SchemeContent
    }
    SchemeClass = scheme_map.get(args.scheme, SchemeTonalSpot)

    # Generate scheme
    scheme = SchemeClass(hct, darkmode, 0.0)

    # Generate colors
    material_colors = {}
    for color in vars(MaterialDynamicColors).keys():
        color_name = getattr(MaterialDynamicColors, color)
        if hasattr(color_name, "get_hct"):
            rgba = color_name.get_hct(scheme).to_rgba()
            material_colors[color] = rgba_to_hex(rgba)

    # Add success colors
    if darkmode:
        material_colors.update({
            'success': '#B5CCBA',
            'onSuccess': '#213528',
            'successContainer': '#374B3E',
            'onSuccessContainer': '#D1E9D6'
        })
    else:
        material_colors.update({
            'success': '#4F6354',
            'onSuccess': '#FFFFFF',
            'successContainer': '#D1E8D5',
            'onSuccessContainer': '#0C1F13'
        })

    # Generate QML
    qml_template_path = os.path.join(os.path.dirname(__file__), 'templates/colors.qml')
    with open(qml_template_path, 'r') as f:
        template = f.read()

    # Replace color values in template
    for key, value in material_colors.items():
        template = template.replace(f'#{key}', value)

    # Write output
    output_path = args.output or os.path.join(os.getenv('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'quickshell/style/colors.qml')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(template)

if __name__ == '__main__':
    main() 