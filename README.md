# Matt's Quickshell Hyprland Configuration Changelog

![image](https://github.com/user-attachments/assets/49bba28f-776e-454d-a351-a42bba898cd6)


---

A comprehensive documentation of all changes made in converting end-4's AGS-based Hyprland configuration (https://github.com/end-4/dots-hyprland) to Quickshell, with dock implementation based on Pharmaracist's work.

File Locations Overview
----------------------
Main configuration files changed from AGS to Quickshell:
- ~/.config/quickshell/shell.qml (Replaces ~/.config/ags/main.js)
- ~/.config/quickshell/modules/bar/ (Replaces ~/.config/ags/modules/bar/)
- ~/.config/quickshell/modules/dock/ (Replaces ~/.config/ags/modules/dock/)
- ~/.config/quickshell/style/ (Replaces ~/.config/ags/scss/)
- ~/.config/quickshell/services/ (Replaces ~/.config/ags/services/)
- ~/.config/hypr/hyprland.conf (Modified for Quickshell compatibility)

1. Core Shell Implementation
--------------------------
File: ~/.config/quickshell/shell.qml (Replaces ~/.config/ags/main.js)

Original (AGS):
```javascript
import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

export default {
    style: App.configDir + '/style.css',
    windows: [
        // window definitions
    ]
};
```

New (Quickshell):
```qml
import "./modules/bar/"
import "./modules/cheatsheet/"
import "modules/dock"
import "./modules/mediaControls/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/overview/"
import "./modules/screenCorners/"
import "./modules/session/"
import "./modules/sidebarLeft/"
import "./modules/sidebarRight/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "./services/"

ShellRoot {
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
        PersistentStateManager.loadStates()
    }

    Bar {}
    Cheatsheet {}
    Dock {}
    MediaControls {}
    NotificationPopup {}
    OnScreenDisplayBrightness {}
    OnScreenDisplayVolume {}
    Overview {}
    ReloadPopup {}
    ScreenCorners {}
    Session {}
    SidebarLeft {}
    SidebarRight {}
}
```

2. Bar Module Conversion
-----------------------
File: ~/.config/quickshell/modules/bar/Bar.qml (Replaces ~/.config/ags/modules/bar/bar.js)

Original (AGS):
```javascript
const Bar = () => Widget.Window({
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    child: Widget.CenterBox({
        startWidget: leftModules,
        centerWidget: centerModules,
        endWidget: rightModules,
    }),
});
```

New (Quickshell):
```qml
Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth
    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: ConfigOptions.bar.showBackground

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot
            screen: modelData
            WlrLayershell.namespace: "quickshell:bar:blur"
            implicitHeight: barHeight
            exclusiveZone: showBarBackground ? barHeight : (barHeight - 4)
            mask: Region {
                item: barContent
            }
            
            // Detailed bar implementation...
        }
    }
}
```

3. Dock Implementation (Based on Pharmaracist's Work)
--------------------------------------------------
File: ~/.config/quickshell/modules/dock/Dock.qml

Original Source: Adapted from [Pharmaracist's Quickshell implementation](https://github.com/Pharmaracist/dots-hyprland/tree/ii-qs/.config/quickshell)

Key Modifications:
```qml
// Added custom dock dimensions
readonly property int dockHeight: Appearance.sizes.barHeight * 1.5
readonly property int dockWidth: Appearance.sizes.barHeight * 1.5
readonly property int dockSpacing: Appearance.sizes.elevationMargin

// Modified background transparency
readonly property color backgroundColor: Qt.rgba(
    Appearance.colors.colLayer0.r,
    Appearance.colors.colLayer0.g,
    Appearance.colors.colLayer0.b,
    0.65  // Adjusted transparency
)

// Added custom pinned apps configuration
readonly property var defaultPinnedApps: [
    "microsoft-edge-dev",
    "org.gnome.Nautilus",
    "vesktop",
    "cider",
    "steam-native",
    "lutris",
    "heroic",
    "obs",
    "com.blackmagicdesign.resolve.desktop",
    "AffinityPhoto.desktop",
    "ptyxis"
]

// Added custom Arch menu button
Rectangle {
    id: archButton
    anchors.fill: parent
    anchors.margins: 4
    radius: Appearance.rounding.full
    color: archMouseArea.containsMouse ? Appearance.colors.colPrimary : "transparent"
    opacity: archMouseArea.containsMouse ? 0.8 : 0.5
    
    Image {
        anchors.centerIn: parent
        source: "/home/matt/.config/quickshell/logo/Arch-linux-logo.png"
        width: parent.width * 0.9
        height: parent.height * 0.9
        fillMode: Image.PreserveAspectFit
    }
}
```

A. Dock Item Modifications (DockItem.qml):
```qml
// Enhanced dock item styling
Rectangle {
    implicitWidth: dock.dockWidth - 10
    implicitHeight: dock.dockWidth - 10
    radius: Appearance.rounding.full
    
    // Modified hover effects
    color: mouseArea.pressed ? Appearance.colors.colLayer1Active : 
           mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
           "transparent"
    
    // Added custom icon sizing
    Image {
        width: parent.width * 0.65
        height: parent.height * 0.65
        anchors.bottomMargin: 10
    }
}
```

B. Context Menu Enhancements (DockItemMenu.qml):
```qml
// Added custom menu styling
background: Rectangle {
    implicitWidth: 200
    color: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        1.0
    )
    radius: Appearance.rounding.small
    border.width: 1
    border.color: Qt.rgba(
        Appearance.colors.colOnLayer0.r,
        Appearance.colors.colOnLayer0.g,
        Appearance.colors.colOnLayer0.b,
        0.1
    )
}

// Fixed right-click menu positioning
onRightClicked: (mouse) => {
    var component = Qt.createComponent("DockItemMenu.qml")
    if (component.status === Component.Ready) {
        var menu = component.createObject(parent, {
            "appInfo": modelData,
            "isPinned": false
        })
        
        // Position menu at mouse cursor location instead of default position
        menu.popup(Qt.point(mouse.x, mouse.y))
    }
}

// Added new menu items
MenuItem {
    id: floatMenuItem
    text: qsTr("Toggle floating")
    icon.name: "window-float"
    // ... custom styling
}
```

Key Fixes:
1. **Menu Positioning**: Fixed the context menu to appear directly under the mouse cursor instead of at a fixed position relative to the dock item
2. **Mouse Coordinates**: Properly passing mouse event coordinates to ensure accurate menu placement
3. **Dynamic Creation**: Improved menu object creation to ensure proper cleanup and prevent memory leaks

C. Configuration Changes (dock_config.json):
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

D. Hyprland Integration (hyprland-rules.conf):
```conf
# Added custom window rules for dock
windowrulev2 = blur,class:^(quickshell)$
windowrulev2 = rounding 30,class:^(quickshell)$
windowrulev2 = nofocus,class:^(quickshell)$

# Added layer rules for proper blur
layerrule = blur,quickshell:dock:blur
layerrule = ignorezero,quickshell:dock:blur
```

4. Theme System Migration
------------------------
Directory: ~/.config/quickshell/style/ (Replaces ~/.config/ags/scss/)

Original (AGS SCSS):
```scss
$bg: #1e1e2e;
$fg: #cdd6f4;

.bar {
    background-color: $bg;
    color: $fg;
}
```

New (Quickshell QML):
```qml
// style/Theme.qml
QtObject {
    readonly property color background: "#1e1e2e"
    readonly property color foreground: "#cdd6f4"
    
    readonly property QtObject bar: QtObject {
        readonly property color background: root.background
        readonly property color foreground: root.foreground
    }
}
```

5. Weather Module Integration (by lysec)
--------------------------------------
File: ~/.config/quickshell/modules/bar/Weather.qml

Implementation:
```qml
// Weather module by lysec
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Weather

WeatherWidget {
    id: weatherWidget
    
    // Weather implementation details...
    // Configuration and display logic
}
```

6. System Services
-----------------
Directory: ~/.config/quickshell/services/

Original (AGS):
```javascript
// services/brightness.js
const Brightness = {
    // AGS implementation
};
```

New (Quickshell):
```qml
// services/Brightness.qml
QtObject {
    id: brightnessService
    
    property var monitors: []
    property real globalBrightness: 1.0
    
    // Quickshell implementation
}
```

7. Hyprland Integration
----------------------
File: ~/.config/hypr/hyprland.conf

Added:
```conf
# Quickshell Integration
exec-once = qs

# Window Rules
windowrulev2 = float,class:^(quickshell)$
windowrulev2 = noanim,class:^(quickshell)$
windowrulev2 = noblur,class:^(quickshell)$

# Performance Optimizations
misc {
    force_default_wallpaper = 0
    disable_splash_rendering = true
    disable_hyprland_logo = true
}
```

8. Additional Components
----------------------
A. Notification System:
```qml
// modules/notificationPopup/NotificationPopup.qml
NotificationManager {
    popupTimeout: 5000
    popupLocation: Qt.TopRight
    
    // Notification handling logic
}
```

B. Media Controls:
```qml
// modules/mediaControls/MediaControls.qml
MediaController {
    players: MprisService.players
    
    // Media control implementation
}
```

File Locations Reference
----------------------
Key configuration files and their purposes:
- ~/.config/quickshell/shell.qml: Main shell configuration
- ~/.config/quickshell/modules/: UI components and widgets
- ~/.config/quickshell/services/: System services and utilities
- ~/.config/quickshell/style/: Theme and appearance
- ~/.config/hypr/: Hyprland configuration files

How to Apply Changes
------------------
1. Install required packages:
```bash
yay -S quickshell matugen-bin grimblast wtype qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations qt6-5compat qt6-base qt6-declarative qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland syntax-highlighting
```

2. Copy configuration files:
```bash
cp -r .config/* ~/.config/
```

3. Start Quickshell:
```bash
qs
```

Notes
-----
- Complete rewrite from AGS JavaScript to Quickshell QML
- Maintains functionality while improving performance
- Weather module implementation by lysec
- Based on end-4's Hyprland dotfiles
- Extensive use of Qt Quick and Material Design

Remember to backup your configuration files before applying changes.

## Credits

- Original dotfiles by [end-4](https://github.com/end-4/dots-hyprland)
- Dock implementation based on [Pharmaracist's work](https://github.com/Pharmaracist/dots-hyprland)
- Weather module by lysec
- Quickshell implementation and customizations by Matt

## License

GPL-3.0 License - See LICENSE file for details 
