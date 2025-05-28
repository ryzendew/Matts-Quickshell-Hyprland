import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
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
    
    // Menu properties
    property bool showDockMenu: false
    property var menuAppInfo: ({})
    property rect menuTargetRect: Qt.rect(0, 0, 0, 0)  // Store position and size of target item
    property var activeMenuItem: null  // Track which item triggered the menu
    
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
        // Nautilus variations
        "org.gnome.Nautilus": "nautilus --new-window",
        "org.gnome.nautilus": "nautilus --new-window",
        "nautilus": "nautilus --new-window",
        "Nautilus": "nautilus --new-window",
        
        // Other apps
        "vesktop": "vesktop --new-window",
        "microsoft-edge-dev": "microsoft-edge-dev --new-window",
        "steam-native": "steam-native -newbigpicture",
        "lutris": "lutris",
        "heroic": "heroic",
        "obs": "obs",
        "com.blackmagicdesign.resolve": "resolve",
        "AffinityPhoto": "AffinityPhoto",
        "ptyxis": "ptyxis"
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
    
    // Reorder pinned apps (for drag and drop)
    function reorderPinnedApp(fromIndex, toIndex) {
        console.log("reorderPinnedApp called with fromIndex:", fromIndex, "toIndex:", toIndex)
        console.log("Current pinnedApps:", JSON.stringify(pinnedApps))
        
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || 
            fromIndex >= pinnedApps.length || toIndex >= pinnedApps.length) {
            console.log("Invalid indices, aborting reorder")
            return
        }
        
        var newPinnedApps = pinnedApps.slice()
        var item = newPinnedApps.splice(fromIndex, 1)[0]
        newPinnedApps.splice(toIndex, 0, item)
        pinnedApps = newPinnedApps
        
        console.log("New pinnedApps:", JSON.stringify(pinnedApps))
        savePinnedApps()
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
    
    function showMenuForApp(appInfo) {
        menuAppInfo = appInfo
        showDockMenu = true
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
                            border.width: 2.5
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
                                Layout.preferredWidth: dock.dockWidth - 10
                                Layout.preferredHeight: dock.dockWidth - 10
                                Layout.leftMargin: 0 // Remove left margin completely
                                
                                Rectangle {
                                    id: archButton
                                    anchors.fill: parent
                                    radius: Appearance.rounding.full
                                    color: archMouseArea.pressed ? Appearance.colors.colLayer1Active : 
                                           archMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
                                           "transparent"
                                    
                                    Behavior on color {
                                        ColorAnimation { 
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                        }
                                    }
                                    
                                    // Arch Linux logo
                                    Image {
                                        anchors.centerIn: parent
                                        source: "/home/matt/.config/quickshell/logo/Arch-linux-logo.png"
                                        width: parent.width * 0.65
                                        height: parent.height * 0.65
                                        fillMode: Image.PreserveAspectFit
                                }
                                
                                MouseArea {
                                    id: archMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    onClicked: {
                                        GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
                                        }
                                    }
                                }
                            }
                            
                            // Pinned apps
                            Repeater {
                                id: pinnedAppsRepeater
                                model: dock.pinnedApps
                                
                                DockItem {
                                    property var parentRepeater: pinnedAppsRepeater  // Add reference to the repeater
                                    icon: modelData  // Pass raw class name to SystemIcon
                                    tooltip: modelData  // Use the app class name for pinned apps
                                    isActive: dockRoot.isWindowActive(modelData)
                                    isPinned: true
                                    appInfo: ({
                                        class: modelData,
                                        command: modelData.toLowerCase()
                                    })
                                    onClicked: {
                                        // Find the window for this pinned app
                                        var targetWindow = HyprlandData.windowList.find(w => 
                                            w.class.toLowerCase() === modelData.toLowerCase() ||
                                            w.initialClass.toLowerCase() === modelData.toLowerCase()
                                        )
                                        
                                        if (targetWindow) {
                                            // If window exists, focus it and switch to its workspace
                                            if (targetWindow.address) {
                                                Hyprland.dispatch(`focuswindow address:${targetWindow.address}`)
                                                
                                                // Also switch to the workspace on the current monitor
                                                if (targetWindow.workspace && targetWindow.workspace.id) {
                                                    Hyprland.dispatch(`workspace ${targetWindow.workspace.id}`)
                                                }
                                            } else {
                                                Hyprland.dispatch(`focuswindow class:${modelData}`)
                                            }
                                        } else {
                                            // If no window exists, launch the app
                                            let cmd = dock.desktopIdToCommand[modelData] || modelData.toLowerCase();
                                            Hyprland.dispatch(`exec ${cmd}`)
                                        }
                                    }
                                    onUnpinApp: {
                                                dock.removePinnedApp(modelData)
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
                                    icon: modelData.class  // Pass raw class name to SystemIcon
                                    tooltip: modelData.title || modelData.class
                                    isActive: true
                                    isPinned: false
                                    appInfo: modelData
                                    
                                    onClicked: {
                                        // For unpinned apps, we already have the specific window
                                        if (modelData.address) {
                                            Hyprland.dispatch(`focuswindow address:${modelData.address}`)
                                            
                                            // Also switch to the workspace on the current monitor
                                            if (modelData.workspace && modelData.workspace.id) {
                                                Hyprland.dispatch(`workspace ${modelData.workspace.id}`)
                                            }
                                        } else {
                                            Hyprland.dispatch(`focuswindow class:${modelData.class}`)
                                        }
                                    }
                                    onPinApp: {
                                                dock.addPinnedApp(modelData.class)
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
                                Layout.preferredWidth: mediaComponent.implicitWidth
                                Layout.preferredHeight: dockHeight * 0.65
                                Layout.rightMargin: dockHeight * 0.25

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
