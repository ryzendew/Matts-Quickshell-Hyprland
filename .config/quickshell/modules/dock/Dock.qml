import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/icons.js" as Icons
import Qt.labs.platform
import "root:/modules/bar"

Scope {
    id: dock

    // Dock dimensions and appearance
    readonly property int dockHeight: Appearance.sizes.barHeight * 1.5
    readonly property int dockWidth: Appearance.sizes.barHeight * 1.5
    readonly property int dockSpacing: Appearance.sizes.elevationMargin
    
    // Color properties that update when Appearance changes
    readonly property color backgroundColor: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        AppearanceSettingsState.dockTransparency
    )
    
    // Auto-hide properties
    property bool autoHide: false
    property int hideDelay: 200 // Hide timer interval
    property int showDelay: 50 // Show timer interval
    property int animationDuration: Appearance.animation.elementMoveFast.duration // Animation speed for dock sliding
    property int approachRegionHeight: 18 // Height of the approach region in pixels
    
    // Property to track if mouse is over any dock item
    property bool mouseOverDockItem: false
    
    // Default pinned apps to use if no saved settings exist
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
    
    // Pinned apps list - will be loaded from file
    property var pinnedApps: []
    
    // Settings file path
    property string configFilePath: `${Quickshell.configDir}/dock_config.json`
    
    // Map desktop IDs to executable commands
    readonly property var desktopIdToCommand: ({
        "org.gnome.Nautilus": "nautilus",
        "org.gnome.nautilus": "nautilus",
        // Add more mappings as needed
    })
    
    // Watch for changes in blur settings
    Connections {
        target: AppearanceSettingsState
        function onDockBlurAmountChanged() {
            // Update Hyprland blur rules for dock
            Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
            Hyprland.dispatch(`keyword decoration:blur:size ${AppearanceSettingsState.dockBlurAmount}`)
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onDockBlurPassesChanged() {
            Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onDockTransparencyChanged() {
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
    }
    
    function saveConfig() {
        var config = {
            pinnedApps: pinnedApps,
            autoHide: autoHide
        }
        dockConfigView.setText(JSON.stringify(config, null, 2))
    }
    
    function savePinnedApps() {
        saveConfig()
    }
    
    // Toggle dock auto-hide (exclusive mode)
    function toggleDockExclusive() {
        // Toggle auto-hide state
        autoHide = !autoHide
        
        // If we're toggling to pinned mode (auto-hide off), ensure the dock is visible
        if (!autoHide) {
            // Force show the dock
            if (dockContainer) {
                dockContainer.y = dockRoot.height - dockHeight
                // Stop any hide timers
                hideTimer.stop()
            }
        }
        
        // Save the configuration
        saveConfig()
    }
    
    // Add a new app to pinned apps
    function addPinnedApp(appClass) {
        // Check if app is already pinned
        if (!pinnedApps.includes(appClass)) {
            // Create a new array to trigger QML reactivity
            var newPinnedApps = pinnedApps.slice()
            newPinnedApps.push(appClass)
            pinnedApps = newPinnedApps
            savePinnedApps()
        }
    }
    
    // Remove an app from pinned apps
    function removePinnedApp(appClass) {
        var index = pinnedApps.indexOf(appClass)
        if (index !== -1) {
            var newPinnedApps = pinnedApps.slice()
            newPinnedApps.splice(index, 1)
            pinnedApps = newPinnedApps
            savePinnedApps()
        }
    }
    
    // FileView for persistence
    FileView {
        id: dockConfigView
        path: configFilePath
        
        onLoaded: {
            try {
                const fileContents = dockConfigView.text()
                const config = JSON.parse(fileContents)
                if (config) {
                    // Load pinned apps
                    if (config.pinnedApps) {
                        dock.pinnedApps = config.pinnedApps
                    }
                    
                    // Load auto-hide setting if available
                    if (config.autoHide !== undefined) {
                        dock.autoHide = config.autoHide
                    }
                }
                console.log("[Dock] Config loaded")
            } catch (e) {
                console.log("[Dock] Error parsing config: " + e)
                // Initialize with defaults on parsing error
                dock.pinnedApps = defaultPinnedApps
                savePinnedApps()
            }
        }
        
        onLoadFailed: (error) => {
            console.log("[Dock] Config load failed: " + error)
            // Initialize with defaults if file doesn't exist
            dock.pinnedApps = defaultPinnedApps
            savePinnedApps()
        }
    }
    
    Component.onCompleted: {
        // Load config when component is ready
        dockConfigView.reload()
        
        // Apply initial blur settings
        Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
        Hyprland.dispatch(`keyword decoration:blur:size ${AppearanceSettingsState.dockBlurAmount}`)
    }
    
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            margins {
                top: 0
                bottom: 2
                left: 0
                right: 0
            }
            property ShellScreen modelData
            
            screen: modelData
            WlrLayershell.namespace: "quickshell:dock:blur"
            implicitHeight: dockHeight
            implicitWidth: dockContainer.implicitWidth
            color: "transparent"

            // Basic configuration
            WlrLayershell.layer: WlrLayer.Top
            exclusiveZone: dockHeight
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {
                item: Rectangle {
                    width: dockContent.width
                    height: dockContent.height
                    x: dockContent.x + (dockRoot.width - dockContent.width) / 2
                    y: dockContent.y
                }
            }

            // Track active windows
            property var activeWindows: []
            
            // Update when window list changes
            Connections {
                target: HyprlandData
                function onWindowListChanged() { updateActiveWindows() }
            }
            
            Component.onCompleted: {
                updateActiveWindows()
                refreshTimer.start()
            }
            
            Timer {
                id: refreshTimer
                interval: 2000
                repeat: true
                onTriggered: updateActiveWindows()
            }
            
            function updateActiveWindows() {
                try {
                    activeWindows = HyprlandData.windowList
                        .filter(w => w.mapped && !w.hidden)
                        .map(w => ({
                            class: w.class,
                            title: w.title,
                            command: w.class.toLowerCase(),
                            address: w.address,
                            pid: w.pid,
                            workspace: w.workspace
                        }))
                } catch (e) {
                    activeWindows = []
                }
            }
            
            function getIconForClass(windowClass) {
                return Icons.noKnowledgeIconGuess(windowClass) || windowClass.toLowerCase()
            }
            
            function isWindowActive(windowClass) {
                return activeWindows.some(w => 
                    w.class.toLowerCase() === windowClass.toLowerCase())
            }
            
            function focusOrLaunchApp(appInfo) {
                Hyprland.dispatch(isWindowActive(appInfo.class) ?
                    `dispatch focuswindow class:${appInfo.class}` :
                    `exec ${appInfo.command}`)
            }

            anchors.left: false
            anchors.right: false
            anchors.top: false
            anchors.bottom: true

            Item {
                id: fullContainer
                anchors.fill: parent

                Item {
                    id: dockContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    implicitWidth: dockContent.width
                    height: dockHeight

                    Rectangle {
                        id: dockContent
                        width: dockItemsLayout.width + (dockHeight * 0.5)
                        height: parent.height
                        anchors.centerIn: parent
                        radius: 30
                        color: Qt.rgba(
                            Appearance.colors.colLayer0.r,
                            Appearance.colors.colLayer0.g,
                            Appearance.colors.colLayer0.b,
                            1 - AppearanceSettingsState.dockTransparency
                        )

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                            }
                        }

                        // Border
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "black"
                            border.width: 3
                            radius: parent.radius
                        }

                        // Main dock layout
                        GridLayout {
                            id: dockItemsLayout
                            anchors.centerIn: dockContent
                            rowSpacing: 0
                            columnSpacing: 4
                            flow: GridLayout.LeftToRight
                            columns: -1
                            rows: 1

                            // Arch menu button (replacing the pin/unpin button)
                            Item {
                                Layout.preferredWidth: dockHeight * 0.65
                                Layout.preferredHeight: dockHeight * 0.65
                                Layout.leftMargin: 0 // Remove left margin completely
                                
                                Rectangle {
                                    id: archButton
                                    anchors.fill: parent
                                    anchors.margins: 4 // Reduce margins from 6 to 4
                                    radius: Appearance.rounding.full
                                    color: archMouseArea.containsMouse ? Appearance.colors.colPrimary : "transparent"
                                    opacity: archMouseArea.containsMouse ? 0.8 : 0.5
                                    
                                    // Arch Linux logo
                                    Image {
                                        anchors.centerIn: parent
                                        source: "/home/matt/.config/quickshell/logo/Arch-linux-logo.png"
                                        width: parent.width * 0.9
                                        height: parent.height * 0.9
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    
                                    // Hover effects
                                    Behavior on opacity {
                                        NumberAnimation { 
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                        }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation { 
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: archMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    // Track hover state to prevent auto-hide
                                    onEntered: dock.mouseOverDockItem = true
                                    onExited: dock.mouseOverDockItem = false
                                    
                                    // Launch hyprmenu when clicked
                                    onClicked: {
                                        Hyprland.dispatch("exec hyprmenu")
                                    }
                                 
                                }
                            }
                            
                            // Pinned apps
                            Repeater {
                                model: dock.pinnedApps
                                
                                DockItem {
                                    icon: Icons.noKnowledgeIconGuess(modelData) || modelData.toLowerCase()
                                    tooltip: ""
                                    isActive: dockRoot.isWindowActive(modelData)
                                    onClicked: {
                                        let cmd = dock.desktopIdToCommand[modelData] || modelData.toLowerCase();
                                        if (dockRoot.isWindowActive(modelData)) {
                                            Hyprland.dispatch(`dispatch focuswindow class:${modelData}`)
                                        } else {
                                            Hyprland.dispatch(`exec ${cmd}`)
                                        }
                                    }
                                    
                                    onRightClicked: (mouse) => {
                                        // Create a context menu for the app
                                        var component = Qt.createComponent("DockItemMenu.qml")
                                        if (component.status === Component.Ready) {
                                            var menu = component.createObject(parent, {
                                                "appInfo": {
                                                    class: modelData,
                                                    command: modelData.toLowerCase()
                                                },
                                                "isPinned": true
                                            })
                                            
                                            // Handle unpin app action
                                            menu.unpinApp.connect(function() {
                                                dock.removePinnedApp(modelData)
                                            })

                                            menu.popup()
                                        }
                                    }
                                }
                            }
                            
                            // Right separator (only visible if there are non-pinned apps)
                            Rectangle {
                                id: rightSeparator
                                visible: nonPinnedAppsRepeater.count > 0
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: dockHeight * 0.5
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.3
                            }
                            
                            // Right side - Active but not pinned apps
                            Repeater {
                                id: nonPinnedAppsRepeater
                                model: {
                                    var nonPinnedApps = []
                                    for (var i = 0; i < dockRoot.activeWindows.length; i++) {
                                        var activeWindow = dockRoot.activeWindows[i]
                                        var isPinned = false
                                        
                                        for (var j = 0; j < dock.pinnedApps.length; j++) {
                                            if (dock.pinnedApps[j].toLowerCase() === activeWindow.class.toLowerCase()) {
                                                isPinned = true
                                                break
                                            }
                                        }
                                        
                                        if (!isPinned) {
                                            nonPinnedApps.push(activeWindow)
                                        }
                                    }
                                    
                                    return nonPinnedApps
                                }
                                
                                DockItem {
                                    icon: Icons.noKnowledgeIconGuess(modelData.class) || modelData.class.toLowerCase()
                                    tooltip: modelData.title || modelData.class
                                    isActive: true
                                    onClicked: {
                                        // Use address for more precise window focusing when available
                                        if (modelData.address) {
                                            Hyprland.dispatch(`dispatch focuswindow address:${modelData.address}`)
                                        } else {
                                            Hyprland.dispatch(`dispatch focuswindow class:${modelData.class}`)
                                        }
                                    }
                                    
                                    onRightClicked: (mouse) => {
                                        // Create a context menu for the app
                                        var component = Qt.createComponent("DockItemMenu.qml")
                                        if (component.status === Component.Ready) {
                                            var menu = component.createObject(parent, {
                                                "appInfo": modelData,
                                                "isPinned": false
                                            })
                                            
                                            // Handle pin app action
                                            menu.pinApp.connect(function() {
                                                // Add to pinned apps
                                                dock.addPinnedApp(modelData.class)
                                            })
                                            
                                            // Position relative to mouse cursor
                                            menu.popup(Qt.point(mouse.x, mouse.y))
                                        }
                                    }
                                }
                            }

                            // Left separator for media
                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: dockHeight * 0.5
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.3
                            }

                            // Media controls at right edge
                            Item {
                                Layout.preferredWidth: mediaComponent.implicitWidth  // Use Media component's width
                                Layout.preferredHeight: dockHeight * 0.65
                                Layout.rightMargin: dockHeight * 0.25  // Add right margin to match left side spacing

                                Media {
                                    id: mediaComponent
                                    anchors.fill: parent
                                    anchors.margins: 4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
