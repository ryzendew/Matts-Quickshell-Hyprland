# Matt's Quickshell Hyprland Configuration

<div align="center">
    <img src="assets/preview.png" alt="Matt's Quickshell Hyprland Desktop">
    <br>
    <em>A modern, feature-rich Quickshell-powered Hyprland desktop environment</em>
</div>

---

A comprehensive Quickshell-based Hyprland configuration converted from end-4's original AGS implementation, featuring an enhanced dock system adapted from Pharmaracist's work, lysec's weather module, and extensive custom improvements.

## ✨ Features

- **🖱️ Advanced Dock System** - Drag & drop reordering, right-click menus, workspace management
- **🌤️ Dynamic Weather Widget** - Real-time weather with location customization (by lysec)
- **📊 System Monitoring** - CPU, memory, disk usage with modern visualizations
- **🔊 Audio Controls** - PipeWire integration with volume controls and media management
- **🪟 Window Management** - Intelligent Hyprland window controls and workspace switching
- **🎨 Material Design Theming** - Beautiful animations and modern UI components
- **🎮 Gaming Ready** - Optimized for gaming performance (especially on PikaOS)
- **📱 Mobile-Inspired Design** - Touch-friendly interface with smooth animations

## 🚀 Quick Installation

> **⚠️ ALPHA WARNING**: The automated installer script is currently in alpha stage and may be untested on some systems. Please review the script before running and report any issues you encounter.

### One-Line Install
```bash
# Normal installation
curl -fsSL https://raw.githubusercontent.com/ryzendew/Matts-Quickshell-Hyprland/main/install.sh | bash

# Force reinstall all packages
curl -fsSL https://raw.githubusercontent.com/ryzendew/Matts-Quickshell-Hyprland/main/install.sh | bash -- --force
```

### Manual Installation
```bash
git clone https://github.com/ryzendew/Matts-Quickshell-Hyprland.git
cd Matts-Quickshell-Hyprland
chmod +x install.sh

# Normal installation
./install.sh

# Force reinstall all packages
./install.sh --force
```

## 🛠️ System Requirements

### Arch Linux
- Fresh Arch Linux installation
- Internet connection
- At least 2GB free disk space
- Base system with sudo configured

### PikaOS 4
- PikaOS 4 Hyprland Edition (recommended)
- Internet connection
- At least 1GB free disk space
- Quickshell pre-installed (automatic on Hyprland edition)

## 📋 Essential Dependencies

### Required Packages
```bash
# Core Hyprland and Wayland
sudo pacman -S hyprland wayland wayland-protocols

# Qt framework (required for Quickshell)
sudo pacman -S qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations

# System utilities used by the config
sudo pacman -S grim slurp wl-clipboard wtype brightnessctl pamixer mako syntax-highlighting

# Fonts (prevents missing font errors)
sudo pacman -S ttf-dejavu noto-fonts

# AUR packages
yay -S quickshell matugen-bin grimblast hyprswitch nwg-displays nwg-look
```

## 🖥️ Supported Distributions

### Arch Linux
- Full support with automatic yay installation
- AUR packages for extended functionality
- SDDM display manager setup

### PikaOS 4
The installer will:
- Utilize pre-installed Quickshell and Hyprland
- Install minimal additional dependencies
- Use pikman for AUR-like packages when available
- Work with existing gaming optimizations

## ⚙️ Interactive Configuration

The installer provides interactive menus for:

1. **Config Backup** - Backup existing ~/.config
2. **Weather Location** - Set your location for weather widget
3. **Terminal Selection** - Choose from 8 terminal emulators
4. **Browser Selection** - Choose from 8 web browsers
5. **Additional Packages** - File manager and extras

## 🎨 Key Components

### Dock System
- **Drag & Drop**: Reorder pinned applications by dragging
- **Right-Click Menus**: Comprehensive context menus with workspace management
- **Smart Window Switching**: Click dock icons to switch to app workspaces
- **Auto-Hide Support**: Configurable dock visibility

### Weather Widget
- **Real-time Data**: Current weather conditions and forecasts
- **Location Aware**: GPS or manual location configuration
- **Beautiful UI**: Material Design weather display

### System Bar
- **Brightness Control**: Mouse wheel brightness adjustment
- **System Information**: CPU, memory, and disk usage
- **Network Status**: Connection status and speed monitoring
- **Audio Controls**: Volume control and media player integration

## 🔧 Configuration Structure

```
~/.config/quickshell/
├── modules/           # Core UI modules
│   ├── bar/          # Top bar components
│   ├── dock/         # Dock implementation
│   ├── notifications/ # Notification system
│   └── weather/      # Weather widget
├── services/         # System services
├── style/           # Theme and styling
├── assets/          # Images and resources
└── shell.qml        # Main shell entry point
```

## 🔧 Post-Installation

### Starting the Environment
1. Reboot your system
2. Select Hyprland from display manager
3. Start Quickshell: `qs`

### Key Bindings (Default Hyprland)
- `SUPER + Enter` - Terminal
- `SUPER + D` - Application launcher  
- `SUPER + Q` - Close window
- `SUPER + Shift + Q` - Exit Hyprland

## 🚨 Troubleshooting

### Common Issues

**Quickshell not starting:**
```bash
# Check if quickshell is installed
command -v qs || command -v quickshell

# Check configuration
ls ~/.config/quickshell/
```

**Icons not displaying:**
```bash
# Install additional icon themes
sudo pacman -S papirus-icon-theme hicolor-icon-theme

# Clear icon cache
rm -rf ~/.cache/icon-theme.cache
```

**Weather module not working:**
```bash
# Check network connectivity
ping api.openweathermap.org

# Verify weather API dependencies
pacman -Qs curl jq
```

**Distribution Detection Issues:**
The script automatically detects your distribution. If detection fails:
- Ensure `/etc/os-release` exists and is readable
- For PikaOS: Verify you're using PikaOS 4
- For Arch: Verify pacman is available

## 📖 Documentation

- **[Changelog](CHANGELOG.md)** - Detailed version history and feature changes
- **[Installation Guide](docs/installation.md)** - Step-by-step installation instructions
- **[Configuration Guide](docs/configuration.md)** - Customization and theming options

## 🙏 Credits

- **Original Design**: Based on [end-4's dots-hyprland](https://github.com/end-4/dots-hyprland) AGS configuration
- **Dock Implementation**: Thanks to [Pharmaracist's dock design](https://github.com/Pharmaracist/dots-hyprland)
- **Weather Module**: Created by lysec
- **Quickshell Framework**: [Quickshell project](https://github.com/quickshell-org/quickshell)
- **Quickshell Implementation and Enhancements**: Matt

Special thanks to Pharmaracist (@Pharmaracist) for the foundational dock work that made this project possible.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit:
- Bug reports
- Feature requests  
- Pull requests
- Distribution-specific improvements

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/ryzendew/Matts-Quickshell-Hyprland/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ryzendew/Matts-Quickshell-Hyprland/discussions)


---

**Enjoy your beautiful new Hyprland setup! 🎉**