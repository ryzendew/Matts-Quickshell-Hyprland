# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Latest Updates] - Applied from end-4/dots-hyprland PR #1276

### 🏠 Shell Improvements
- **Enhanced `shell.qml`** with helpful comments and memory-efficient Loader pattern
- Added enable/disable flags for all modules to save memory when not needed
- Components now only load when enabled

### 🎵 Media Controls Enhancements  
- **Improved media player filtering** - removes duplicate players and handles track titles better
- **Better positioning control** - media controls now positioned to the right with adjustable spacing
- **Single active player display** - shows only the currently active player instead of all players
- **Enhanced `PlayerControl`** with RippleButton components and better theming
- **Added `Directories` service** for centralized directory management

### 🔍 Search & Icon Improvements
- **Enhanced `AppSearch.qml`** with comprehensive improvements:
  - Better icon guessing for window classes and applications
  - Extended app name substitutions for better icon detection
  - Regex-based substitutions for special cases (Steam games, etc.)
  - Desktop entry search fallback for icon guessing
  - Optional fuzzy search with Levenshtein distance support

### 🎛️ Dock Improvements  
- **Updated `DockApps.qml`** with better window grouping and focus cycling
- Improved app detection and window management

### 📁 New Components Added
- **`Directories.qml`** - Centralized directory management singleton
- **`RippleButton.qml`** - Modern button component with ripple effects
- **`levendist.js`** - Levenshtein distance function for fuzzy search algorithms

### 🎯 Performance & UX
- **Memory optimization** through conditional module loading
- **Better responsiveness** with improved component architecture  
- **Enhanced user experience** with smarter icon detection and media controls

---

## [2.0] - Complete Dock Overhaul (Latest)

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

## [1.5] - Menu and Icon Improvements

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

## [1.0] - Initial Quickshell Conversion

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