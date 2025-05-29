# Matt's Quickshell Hyprland Configuration - Changelog

<div align="center">
    <img src="assets/preview.png" alt="Matt's Quickshell Hyprland Desktop">
    <br>
    <em>My Enhanced Quickshell-powered Hyprland Desktop Environment</em>
</div>

---

A comprehensive changelog documenting all modifications made to convert end-4's AGS-based Hyprland configuration to Quickshell, with dock implementation based on Pharmaracist's work and extensive custom enhancements.

## Version 2.0 - Complete Dock Overhaul (Latest)

### Major Features Added

#### 1. Drag & Drop Functionality (`DockItem.qml`)
```qml
// NEW: Drag and drop properties for reordering pinned apps
property bool isDragging: false
property bool isDropTarget: false
property real dragStartX: 0
property real dragStartY: 0
property int dragThreshold: 10

// NEW: Enhanced mouse interaction with drag detection
onPositionChanged: (mouse) => {
    if (dragActive && dockItem.isPinned && (mouse.buttons & Qt.LeftButton)) {
        var distance = Math.sqrt(Math.pow(mouse.x - dragStartX, 2) + Math.pow(mouse.y - dragStartY, 2))
        if (!dragStarted && distance > dragThreshold) {
            dragStarted = true
            dockItem.isDragging = true
        }
    }
}
```

**What it does:**
- Drag pinned apps to reorder them in the dock
- Visual feedback during drag operations (opacity and scale changes)
- Drop indicators when hovering over valid drop targets
- Smooth animations for all drag/drop interactions

#### 2. Enhanced Icon System
```qml
// CHANGED: From Image to SystemIcon for better icon handling
SystemIcon {
    id: iconItem
    anchors.centerIn: parent
    iconSize: parent.width * 0.65
    iconName: dockItem.icon
    iconColor: "transparent" // Let icons use natural colors
}
```

**Improvements:**
- Better icon resolution and scaling
- Support for system theme icons
- Improved performance with icon caching
- Natural color preservation for application icons

#### 3. Advanced Menu System
```qml
// NEW: Comprehensive right-click menu with all functionality
MenuButton {
    buttonText: qsTr("Move to workspace") + " >"
    enabled: {
        var hasActiveWindow = false
        if (dockItem.appInfo.address) {
            hasActiveWindow = HyprlandData.windowByAddress[dockItem.appInfo.address] !== undefined
        }
        return hasActiveWindow
    }
}

// NEW: Workspace submenu with scrollable workspace list
ScrollView {
    Repeater {
        model: 100
        MenuButton {
            buttonText: qsTr("Workspace ") + (modelData + 1)
            onClicked: {
                Hyprland.dispatch(`movetoworkspacesilent ${modelData + 1},address:${actualWindow.address}`)
            }
        }
    }
}
```

**Menu Features:**
- Pin/Unpin apps to dock
- Launch new instances
- Move windows to specific workspaces (1-100)
- Toggle floating mode
- Close windows
- Smart window detection and command generation

#### 4. Advanced Window Management
```qml
// NEW: Workspace switching when clicking dock icons
onClicked: {
    let win = dockRoot.activeWindows.find(w => w.class.toLowerCase() === modelData.toLowerCase());
    if (win) {
        // Switch to workspace if window is on different workspace
        if (win.workspace && Hyprland.active.workspace.id !== win.workspace) {
            Hyprland.dispatch(`dispatch workspace ${win.workspace}`);
        }
        // Focus the window
        if (win.address) {
            Hyprland.dispatch(`dispatch focuswindow address:${win.address}`);
        }
    }
}
```

**What it does:**
- Clicking a dock icon for an app on another workspace switches to that workspace
- Focuses the window after workspace switch
- Works for both pinned and non-pinned applications

### Configuration Changes

#### Enhanced Dock Configuration (`dock_config.json`)
```json
{
  "pinnedApps": [
    "org.gnome.Nautilus",
    "vesktop", 
    "cider",
    "steam-native",
    "lutris",
    "heroic.desktop",
    "obs.desktop",
    "com.blackmagicdesign.resolve.desktop",
    "AffinityPhoto.desktop",
    "ptyxis"
  ],
  "autoHide": false
}
```

#### Advanced Command Mapping (`Dock.qml`)
```qml
readonly property var desktopIdToCommand: ({
    "org.gnome.Nautilus": "nautilus --new-window",
    "vesktop": "vesktop --new-window", 
    "microsoft-edge-dev": "microsoft-edge-dev --new-window",
    "steam-native": "steam-native -newbigpicture",
    "com.blackmagicdesign.resolve": "resolve",
    "AffinityPhoto": "AffinityPhoto",
    "ptyxis": "ptyxis"
})
```

### Visual Enhancements

#### 1. Improved Animations
```qml
// NEW: Drag feedback animations
Behavior on opacity {
    NumberAnimation {
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Appearance.animation.elementMoveFast.type
    }
}

Behavior on scale {
    NumberAnimation {
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Appearance.animation.elementMoveFast.type
    }
}
```

#### 2. Drop Target Indicators
```qml
// NEW: Visual drop indicator
Rectangle {
    id: dropIndicator
    visible: isDropTarget
    border.color: Appearance.m3colors.m3primary
    border.width: 2
    
    Rectangle {
        anchors.centerIn: parent
        color: Qt.rgba(Appearance.m3colors.m3primary.r, 
                      Appearance.m3colors.m3primary.g, 
                      Appearance.m3colors.m3primary.b, 0.2)
    }
}
```

## Version 1.5 - Menu and Icon Improvements

### Fixed Right-Click Menu Positioning
```qml
// FIXED: Menu positioning to appear above clicked icon
margins {
    left: {
        var clickGlobal = dockItem.mapToItem(null, lastClickPos.x, lastClickPos.y)
        return clickGlobal.x + 655
    }
    bottom: 2
}
```

### Enhanced Icon Handling
```javascript
// NEW: Icon utility function for better path resolution
function resolveIconPath(icon) {
    if (!icon) return "";
    if (icon.includes("?path=")) {
        const [name, path] = icon.split("?path=");
        const fileName = name.substring(name.lastIndexOf("/") + 1);
        return `file://${path}/${fileName}`;
    }
    return icon;
}
```

**Applied to components:**
- `DockItem.qml`
- `CustomIcon.qml`
- `SysTrayItem.qml`
- `SearchItem.qml`
- `OverviewWindow.qml`

### Tooltip Management
```qml
// DISABLED: Tooltips system-wide for cleaner experience
Loader {
    id: tooltipLoader
    active: false  // Disabled tooltips
}
```

## Version 1.0 - Initial Quickshell Conversion

### Core Shell Implementation
**File:** `shell.qml` (Replaced `main.js`)
```qml
// NEW: Qt-based shell implementation
ShellRoot {
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
        PersistentStateManager.loadStates()
    }

    Bar {}
    Dock {}
    MediaControls {}
    NotificationPopup {}
    // ... all other modules
}
```

### Dock Implementation (Based on Pharmaracist's Work)
**Source:** [Pharmaracist's Quickshell implementation](https://github.com/Pharmaracist/dots-hyprland)

#### Key Modifications:
```qml
// ADDED: Custom dock dimensions
readonly property int dockHeight: Appearance.sizes.barHeight * 1.5
readonly property int dockWidth: Appearance.sizes.barHeight * 1.5

// ADDED: Custom Arch menu button
Rectangle {
    id: archButton
    Image {
        source: "/home/matt/.config/quickshell/logo/Arch-linux-logo.png"
        width: parent.width * 0.65
        height: parent.height * 0.65
    }
}
```

### Bar Module Conversion
**File:** `modules/bar/Bar.qml` (Replaced `modules/bar/bar.js`)
```qml
// NEW: Qt Quick Controls based bar
PanelWindow {
    WlrLayershell.namespace: "quickshell:bar:blur"
    implicitHeight: barHeight
    exclusiveZone: showBarBackground ? barHeight : (barHeight - 4)
    // Custom brightness control on scroll
    WheelHandler {
        onWheel: {
            barRoot.brightnessMonitor.setBrightness(
                barRoot.brightnessMonitor.brightness + (event.angleDelta.y > 0 ? 0.05 : -0.05)
            )
        }
    }
}
```

### Weather Module Integration (by lysec)
```qml
// INTEGRATED: Weather widget by lysec
WeatherWidget {
    id: weatherWidget
    // Weather implementation and display logic
}
```

### Theme System Migration
**Directory:** `style/` (Replaced `scss/`)
```qml
// NEW: Qt Quick Controls theming
QtObject {
    readonly property color background: "#1e1e2e"
    readonly property color foreground: "#cdd6f4"
    
    readonly property QtObject bar: QtObject {
        readonly property color background: root.background
        readonly property color foreground: root.foreground
    }
}
```

### System Services Rewrite
**Directory:** `services/`
```qml
// NEW: Qt-based services
QtObject {
    id: brightnessService
    property var monitors: []
    property real globalBrightness: 1.0
    // Quickshell implementation
}
```

### Hyprland Integration
**File:** `hypr/hyprland.conf`
```conf
# ADDED: Quickshell Integration
exec-once = qs

# ADDED: Window rules for dock
windowrulev2 = float,class:^(quickshell)$
windowrulev2 = noanim,class:^(quickshell)$
windowrulev2 = noblur,class:^(quickshell)$

# ADDED: Layer rules for proper blur
layerrule = blur,quickshell:dock:blur
layerrule = ignorezero,quickshell:dock:blur

# ADDED: Performance optimizations
misc {
    force_default_wallpaper = 0
    disable_splash_rendering = true
    disable_hyprland_logo = true
}
```

## Installation Instructions

### Automated Installation (Recommended)

**One-command installer for fresh Arch systems:**

```bash
curl -fsSL https://raw.githubusercontent.com/ryzendew/Matts-Quickshell-Hyprland/main/install.sh | bash
```

Or download and run manually:
```bash
wget https://raw.githubusercontent.com/ryzendew/Matts-Quickshell-Hyprland/main/install.sh
chmod +x install.sh
./install.sh
```

### Manual Installation

### Prerequisites
```bash
yay -S quickshell matugen-bin grimblast wtype qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations qt6-5compat qt6-base qt6-declarative qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland syntax-highlighting
```

### Essential Dependencies for Arch Linux

#### Required Packages
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
yay -S quickshell-git matugen-bin grimblast hyprswitch nwg-displays nwg-look
```

#### One-Command Install
```bash
# Install everything at once
sudo pacman -S hyprland wayland wayland-protocols qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations grim slurp wl-clipboard wtype brightnessctl pamixer mako syntax-highlighting ttf-dejavu noto-fonts && yay -S quickshell-git matugen-bin grimblast hyprswitch nwg-displays nwg-look
```

### Setup
1. Clone this repository:
```bash
git clone https://github.com/ryzendew/Matts-Quickshell-Hyprland.git
```

2. Copy configuration files:
```bash
cp -r .config/* ~/.config/
```

3. Start Quickshell:
```bash
qs
```

## Features Summary

### Current Features
- ✅ Drag & drop reordering of pinned apps
- ✅ Workspace switching when clicking dock icons
- ✅ Advanced right-click menu system
- ✅ Enhanced icon handling and display
- ✅ Smooth animations and visual feedback
- ✅ Window management (move to workspace, toggle floating, close)
- ✅ Auto-reload disabled (stability improvement)
- ✅ Tooltips disabled (cleaner UI)
- ✅ Weather integration (by lysec)
- ✅ Material Design theming
- ✅ HiDPI support

### Customization Options
- **Dock Apps:** Edit `dock_config.json` to modify pinned applications
- **Commands:** Adjust `desktopIdToCommand` mapping in `Dock.qml`
- **Appearance:** Modify theme files in `style/` directory
- **Workspace Rules:** Edit `hypr/hyprland-rules.conf`

## Performance Optimizations

1. **Memory Usage**
   - Efficient QML component loading
   - Optimized image caching
   - Reduced redundant calculations

2. **CPU Usage**
   - Minimized property bindings
   - Optimized animation timings
   - Efficient event handling

3. **Graphics**
   - Hardware acceleration for animations
   - Efficient compositor integration
   - Optimized blur effects

## Troubleshooting

### Common Issues

#### Quickshell won't start
```bash
# Check if all Qt dependencies are installed
pacman -Qs qt6

# Verify Quickshell installation
yay -Qs quickshell

# Check logs
journalctl --user -u quickshell
```

#### Icons not displaying
```bash
# Install additional icon themes
sudo pacman -S papirus-icon-theme hicolor-icon-theme

# Clear icon cache
rm -rf ~/.cache/icon-theme.cache
```

#### Weather module not working
```bash
# Check network connectivity
ping api.openweathermap.org

# Verify weather API dependencies
pacman -Qs curl jq
```

## Credits

- **Original dotfiles:** [end-4](https://github.com/end-4/dots-hyprland)
- **Dock base implementation:** [Pharmaracist](https://github.com/Pharmaracist/dots-hyprland)
- **Weather module:** lysec
- **Quickshell implementation and enhancements:** Matt
- **Special thanks:** Pharmaracist (@Pharmaracist) for the foundational dock work

## License

GPL-3.0 License - See LICENSE file for details

## 🚀 Supported Distributions

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

## ✨ Features

- **Dynamic Weather Widget** - Real-time weather with location customization
- **System Monitoring** - CPU, memory, disk usage
- **Audio Controls** - PipeWire integration with volume controls
- **Window Management** - Intelligent Hyprland window controls
- **Customizable Themes** - Multiple color schemes and layouts
- **Gaming Ready** - Optimized for gaming performance (especially on PikaOS)

## 📦 Quick Installation

> **⚠️ ALPHA WARNING**: The automated installer script is currently in alpha stage and may be untested on some systems. Please review the script before running and report any issues you encounter.

### One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/ryzendew/Matts-Quickshell-Hyprland/main/install.sh | bash
```

### Manual Installation
```bash
git clone https://github.com/ryzendew/Matts-Quickshell-Hyprland.git
cd Matts-Quickshell-Hyprland
chmod +x install.sh
./install.sh
```

## 🖥️ Distribution-Specific Notes

### Arch Linux
The installer will:
- Install yay AUR helper automatically
- Install all dependencies from official and AUR repositories
- Set up SDDM display manager
- Enable essential system services

### PikaOS 4
The installer will:
- Utilize pre-installed Quickshell and Hyprland
- Install minimal additional dependencies
- Use pikman for AUR-like packages when available
- Work with existing gaming optimizations

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

## 📋 What Gets Installed

### Core Dependencies
- **Hyprland** - Wayland compositor
- **Quickshell** - Qt-based shell framework
- **PipeWire** - Audio system
- **NetworkManager** - Network management

### Additional Tools
- **Display Manager** - SDDM (Arch) or existing (PikaOS)
- **Screen Capture** - grim, slurp, grimblast
- **Clipboard** - wl-clipboard
- **Brightness Control** - brightnessctl
- **Notifications** - mako (Arch)

### Optional Applications
- **Terminal Emulators** - Alacritty, Ptyxis, Kitty, etc.
- **Web Browsers** - Firefox, Chrome, Edge, Brave, etc.
- **File Manager** - Nautilus (optional)

## ⚙️ Interactive Configuration

The installer provides interactive menus for:

1. **Config Backup** - Backup existing ~/.config
2. **Weather Location** - Set your location for weather widget
3. **Terminal Selection** - Choose from 8 terminal emulators
4. **Browser Selection** - Choose from 8 web browsers
5. **Additional Packages** - File manager and extras

## 🎨 Customization

### Weather Configuration
During installation, you'll be prompted to set your location:
```
Examples: 
- New York, NY, USA
- London, England  
- Tokyo, Japan
```

### Theme Customization
Configuration files are located in:
- `~/.config/quickshell/` - Main Quickshell configuration
- `~/.config/hypr/` - Hyprland window manager settings

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

**Distribution Detection Issues:**
The script automatically detects your distribution. If detection fails:
- Ensure `/etc/os-release` exists and is readable
- For PikaOS: Verify you're using PikaOS 4
- For Arch: Verify pacman is available

**PikaOS Specific:**
- Use PikaOS Hyprland Edition for best compatibility
- Some packages may need manual installation via `pikman`
- Gaming optimizations are pre-configured

### Error Recovery
The installer includes automatic cleanup on failure:
- Temporary files are removed
- Partial installations are cleaned up
- Error messages provide specific guidance

## 🤝 Contributing

Contributions are welcome! Please feel free to submit:
- Bug reports
- Feature requests  
- Pull requests
- Distribution-specific improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

- **Original Design**: Based on end-4's dots-hyprland AGS configuration
- **Weather Module**: Inspired by lysec's implementation  
- **Dock Implementation**: Thanks to Pharmaracist's dock design
- **PikaOS Support**: Added for the amazing gaming-focused distribution

## 📞 Support

- **Issues**: GitHub Issues page
- **Discussions**: GitHub Discussions
- **PikaOS Community**: Join the PikaOS Discord for distribution-specific help

---

**Enjoy your beautiful new Hyprland setup! 🎉**