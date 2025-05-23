# Matt's Quickshell Hyprland Configuration Changelog

![image](https://github.com/user-attachments/assets/c7808580-5a63-4ac9-b690-7c71bca06a34)


---

A comprehensive documentation of all changes made in converting end-4's AGS-based Hyprland configuration (https://github.com/end-4/dots-hyprland) to Quickshell.

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

3. Dock Implementation
---------------------
File: ~/.config/quickshell/modules/dock/Dock.qml (New implementation)

Original: No dock in AGS version

New (Quickshell):
```qml
Scope {
    id: dock

    readonly property int dockWidth: 60
    readonly property int dockSpacing: 8
    
    PanelWindow {
        id: dockRoot
        screen: modelData
        WlrLayershell.namespace: "quickshell:dock"
        
        DockContent {
            id: dockContent
            anchors.fill: parent
            
            // Pinned apps configuration from dock_config.json
            pinnedApps: [
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
            ]
        }
    }
}
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
- Weather module by lysec
- Quickshell changes by Matt

## License

GPL-3.0 License - See LICENSE file for details 
