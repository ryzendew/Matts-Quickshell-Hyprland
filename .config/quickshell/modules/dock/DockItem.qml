import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

Rectangle {
    id: dockItem
    
    // --- Properties ---
    // The icon to display for this dock item
    property string icon: ""
    // Tooltip text for this item (shows app class or title)
    property string tooltip: isPinned ? appInfo.class || "" : (appInfo.title || appInfo.class || "")
    // Whether this item is currently active (focused window)
    property bool isActive: false
    // Whether the right-click menu is shown for this item
    property bool showMenu: false
    // Information about the app this item represents
    property var appInfo: ({})
    // Whether this app is pinned to the dock
    property bool isPinned: false
    // The index of this item in the layout (for ordering)
    property int layoutIndex: parent ? parent.children.indexOf(dockItem) : 0
    // The index in the model (if using a model)
    property int modelIndex: typeof index !== "undefined" ? index : 0  // Use the index from Repeater
    // The class of the app that was last clicked
    property string clickedAppClass: ""
    // The index of this item in the parent (for ordering)
    property int itemIndex: parent ? parent.children.indexOf(this) : 0
    // Whether this menu is the currently active menu
    property bool isActiveMenu: false
    // The last position where the item was hovered (for tooltips, etc)
    property point lastHoverPos: Qt.point(0, 0)  // Add this property to track hover position
    // The last click position for menu positioning
    property point lastClickPos: Qt.point(0, 0)
    
    // Drag and drop properties
    property bool isDragging: false
    property bool isDropTarget: false
    property real dragStartX: 0
    property real dragStartY: 0
    property int dragThreshold: 10
    
    // --- Signals ---
    // Emitted when the item is clicked (left click)
    signal clicked()
    // Emitted when the user wants to pin the app
    signal pinApp()
    // Emitted when the user wants to unpin the app
    signal unpinApp()
    // Emitted when the user wants to close the app
    signal closeApp()
    // Emitted when drag starts
    signal dragStarted()
    // Emitted when drag ends
    signal dragEnded()
    // Emitted when item is dropped on another item
    signal itemDropped(int fromIndex, int toIndex)
    
    // --- Appearance ---
    // Set the size and shape of the dock item
    implicitWidth: dock.dockWidth - 10
    implicitHeight: dock.dockWidth - 10
    radius: Appearance.rounding.full
    // Set the color based on state (active, hovered, pressed)
    color: mouseArea.pressed ? Appearance.colors.colLayer1Active : 
           mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
           "transparent"
    
    // Visual feedback for drag and drop
    opacity: isDragging ? 0.7 : 1.0
    scale: isDragging ? 1.1 : (isDropTarget ? 1.05 : 1.0)
    z: isDragging ? 100 : 1
    
    // Animate color changes for smooth transitions
    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }
    
    // Animate drag feedback
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
    
    // --- Icon ---
    // The app icon, centered in the item
    SystemIcon {
        id: iconItem
        anchors.centerIn: parent
        iconSize: parent.width * 0.65
        iconName: dockItem.icon
        iconColor: "transparent" // Let the icon use its natural colors
    }
    
    // --- Tooltip (disabled) ---
    // Loader for tooltips (currently disabled by setting active: false)
    Loader {
        id: tooltipLoader
        active: false  // Disable tooltips
        sourceComponent: PanelWindow {
            id: tooltipPanel
            visible: tooltipLoader.active
            color: Qt.rgba(0, 0, 0, 0)
            implicitWidth: tooltipContent.implicitWidth
            implicitHeight: tooltipContent.implicitHeight

            // Set up as a popup window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:docktooltip"

            // Let the window float freely
            anchors.left: true
            anchors.right: false
            anchors.top: false
            anchors.bottom: true
            
            margins {
                left: 655  // Hard-coded position that works well
                bottom: 65
                top: 0
                right: 0
            }

            Item {
                width: tooltipContent.implicitWidth
                height: tooltipContent.implicitHeight

                MultiEffect {
                    anchors.fill: tooltipContent
                    source: tooltipContent
                    shadowEnabled: true
                    shadowColor: Appearance.colors.colShadow
                    shadowVerticalOffset: 1
                    shadowBlur: 0.5
            }

            Rectangle {
                id: tooltipContent
                anchors.fill: parent
                color: Qt.rgba(
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    1.0
                )
                radius: Appearance.rounding.small
                implicitWidth: tooltipText.implicitWidth + 30
                implicitHeight: tooltipText.implicitHeight + 16

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: dockItem.tooltip
                    color: Appearance.colors.colOnLayer0
                    font: dockItem.font
                    }
                }
            }
        }
    }
    
    // --- Mouse Interaction ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        property bool dragActive: false
        property bool dragStarted: false
        
        // Track hover position for possible tooltip use
        onPositionChanged: (mouse) => {
            lastHoverPos = dockItem.mapToItem(null, mouse.x, mouse.y)
            
            // Handle dragging for pinned items only
            if (dragActive && dockItem.isPinned && (mouse.buttons & Qt.LeftButton)) {
                var distance = Math.sqrt(Math.pow(mouse.x - dragStartX, 2) + Math.pow(mouse.y - dragStartY, 2))
                
                if (!dragStarted && distance > dragThreshold) {
                    // Start dragging
                    dragStarted = true
                    dockItem.isDragging = true
                    dockItem.dragStarted()
                    console.log("Started dragging item at model index:", dockItem.modelIndex)
                }
                
                if (dockItem.isDragging) {
                    // Update drop targets - use the direct repeater reference
                    var repeater = dockItem.parentRepeater
                    
                    if (repeater && repeater.count !== undefined) {
                        for (var i = 0; i < repeater.count; i++) {
                            var item = repeater.itemAt(i)
                            if (item && item !== dockItem && item.isPinned) {
                                // Get the global mouse position
                                var globalMousePos = dockItem.mapToItem(null, mouse.x, mouse.y)
                                // Map to the target item's coordinate system
                                var itemMousePos = item.mapFromItem(null, globalMousePos.x, globalMousePos.y)
                                
                                // Check if mouse is over this item
                                var isOver = (itemMousePos.x >= 0 && itemMousePos.x <= item.width && 
                                            itemMousePos.y >= 0 && itemMousePos.y <= item.height)
                                
                                if (isOver && !item.isDropTarget) {
                                    console.log("Setting drop target for item at index:", i)
                                    item.isDropTarget = true
                                } else if (!isOver && item.isDropTarget) {
                                    console.log("Clearing drop target for item at index:", i)
                                    item.isDropTarget = false
                                }
                            }
                        }
                    }
                }
            }
        }
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton && dockItem.isPinned) {
                dragActive = true
                dragStarted = false
                dragStartX = mouse.x
                dragStartY = mouse.y
                console.log("Press detected on pinned item at model index:", dockItem.modelIndex)
            }
        }
        
        onReleased: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (dockItem.isDragging) {
                    console.log("Drop detected")
                    // Handle drop - use the direct repeater reference
                    var repeater = dockItem.parentRepeater
                    var dropTargetIndex = -1
                    var currentIndex = dockItem.modelIndex
                    
                    console.log("Current item index:", currentIndex)
                    console.log("Repeater count:", repeater ? repeater.count : "no repeater")
                    
                    if (repeater && repeater.count !== undefined) {
                        for (var i = 0; i < repeater.count; i++) {
                            var item = repeater.itemAt(i)
                            console.log("Checking item", i, "isPinned:", item ? item.isPinned : "no item", "isDropTarget:", item ? item.isDropTarget : "no item")
                            if (item && item !== dockItem && item.isPinned && item.isDropTarget) {
                                dropTargetIndex = i
                                item.isDropTarget = false
                                console.log("Found drop target at index:", dropTargetIndex)
                                break
                            } else if (item && item.isDropTarget !== undefined) {
                                item.isDropTarget = false
                            }
                        }
                    }
                    
                    console.log("Final drop target index:", dropTargetIndex)
                    console.log("Current index:", currentIndex)
                    
                    // Perform reorder if valid drop target found
                    if (dropTargetIndex >= 0 && currentIndex >= 0 && dropTargetIndex !== currentIndex) {
                        console.log("Calling reorderPinnedApp from", currentIndex, "to", dropTargetIndex)
                        dock.reorderPinnedApp(currentIndex, dropTargetIndex)
                    } else {
                        console.log("No reorder: dropTargetIndex =", dropTargetIndex, "currentIndex =", currentIndex)
                    }
                    
                    // End dragging
                    dockItem.isDragging = false
                    dragStarted = false
                    dockItem.dragEnded()
                }
                
                dragActive = false
            }
        }
        
        // Handle left and right clicks
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton && !dockItem.isDragging) {
                // Left click: activate/click the app (only if not dragging)
                dockItem.clicked()
            } else if (mouse.button === Qt.RightButton) {
                // Right click: open the context menu
                // First, close ALL other menus by finding all dock items
                var dockContainer = dockItem.parent
                if (dockContainer && dockContainer.children) {
                    for (var i = 0; i < dockContainer.children.length; i++) {
                        var item = dockContainer.children[i]
                        if (item && item !== dockItem && item.closeMenu && typeof item.closeMenu === "function") {
                            item.closeMenu()
                        }
                    }
                }
                
                if (dockItem.showMenu) {
                    dockItem.closeMenu()
                } else {
                    // Store the click position for menu positioning
                    lastClickPos = Qt.point(mouse.x, mouse.y)
                    dockItem.showMenu = true
                    dockItem.isActiveMenu = true
                }
            }
        }
        
        // Track mouse over state for dock hover logic
        onEntered: dock.mouseOverDockItem = true
        onExited: dock.mouseOverDockItem = false
    }
    
    // --- Active Indicator ---
    // A small dot below the icon to show if the app is active
    Rectangle {
        id: activeIndicator
        visible: isActive
        width: parent.width * 0.5
        height: 3
        radius: 5
        color: Appearance.colors.colOnLayer1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.bottomMargin: 1.5
    }
    
    // --- Drop Indicator ---
    // Visual indicator when this item is a drop target
    Rectangle {
        id: dropIndicator
        visible: isDropTarget
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Appearance.m3colors.m3primary
        border.width: 2
        
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.8
            radius: parent.radius
            color: Qt.rgba(Appearance.m3colors.m3primary.r, 
                          Appearance.m3colors.m3primary.g, 
                          Appearance.m3colors.m3primary.b, 0.2)
        }
    }
    
    // --- Right-Click Menu ---
    // Menu loader
    Loader {
        id: menuLoader
        active: dockItem.showMenu
        sourceComponent: PanelWindow {
            id: menuPanel
            visible: dockItem.showMenu
            color: Qt.rgba(0, 0, 0, 0)
            implicitWidth: 200
            implicitHeight: menuContent.implicitHeight

            // Set up as a popup window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:dockmenu"

            // Let the window float freely
            anchors.left: true
            anchors.right: false
            anchors.top: false
            anchors.bottom: true

            margins {
                left: {
                    var clickGlobal = dockItem.mapToItem(null, lastClickPos.x, lastClickPos.y)
                    return clickGlobal.x + 655
                }
                bottom: 2
            }

            // Click outside to close
            HyprlandFocusGrab {
                windows: [menuPanel]
                active: menuPanel.visible
                onCleared: () => {
                    if (!active) {
                        dockItem.closeMenu()
                    }
                }
            }

            Rectangle {
                id: menuContent
                anchors.fill: parent
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer0
                implicitHeight: menuLayout.implicitHeight + radius * 2

                DropShadow {
                    anchors.fill: parent
                    horizontalOffset: 0
                    verticalOffset: 1
                    radius: 8.0
                    samples: 17
                    color: Appearance.colors.colShadow
                    source: parent
                }

                ColumnLayout {
                    id: menuLayout
                    anchors.centerIn: parent
                    spacing: 2
                    anchors.margins: menuContent.radius

                    MenuButton {
                        Layout.fillWidth: true
                        buttonText: dockItem.isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
                        onClicked: {
                            if (dockItem.isPinned) {
                                dockItem.unpinApp()
                            } else {
                                dockItem.pinApp()
                            }
                            dockItem.closeMenu()
                        }
                    }

                    MenuButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Launch new instance")
                        onClicked: {
                            // Use the mapped command from desktopIdToCommand if available
                            var command = ""
                            if (dockItem.appInfo.class) {
                                // Try different variations of the class name
                                var classLower = dockItem.appInfo.class.toLowerCase()
                                var classWithDesktop = dockItem.appInfo.class + ".desktop"
                                if (dock.desktopIdToCommand[dockItem.appInfo.class]) {
                                    command = dock.desktopIdToCommand[dockItem.appInfo.class]
                                } else if (dock.desktopIdToCommand[classLower]) {
                                    command = dock.desktopIdToCommand[classLower]
                                } else if (dock.desktopIdToCommand[classWithDesktop]) {
                                    command = dock.desktopIdToCommand[classWithDesktop]
                                } else {
                                    command = dockItem.appInfo.command || dockItem.appInfo.class.toLowerCase()
                                }
                            }
                            console.log("Launching new instance with command:", command)
                            Hyprland.dispatch(`exec ${command}`)
                            dockItem.closeMenu()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(
                            Appearance.colors.colOnLayer0.r,
                            Appearance.colors.colOnLayer0.g,
                            Appearance.colors.colOnLayer0.b,
                            0.1
                        )
                    }

                    MenuButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Move to workspace") + " >"
                        enabled: {
                            // Check if we have an active window
                            var hasActiveWindow = false
                            if (dockItem.appInfo.address) {
                                hasActiveWindow = HyprlandData.windowByAddress[dockItem.appInfo.address] !== undefined
                            } else if (dockItem.appInfo.class) {
                                hasActiveWindow = HyprlandData.windowList.some(w => 
                                    w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                    w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                )
                            }
                            return hasActiveWindow
                        }
                        onClicked: {
                            // Show workspace submenu
                            workspaceSubmenu.visible = true
                        }
                    }

                    // Workspace submenu
                    Rectangle {
                        id: workspaceSubmenu
                        visible: false
                        Layout.fillWidth: true
                        implicitHeight: Math.min(workspaceLayout.implicitHeight, 300)
                        color: Appearance.colors.colLayer0
                        radius: Appearance.rounding.small
                        clip: true

                        // Get current workspace
                        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(dock.screen)
                        readonly property int currentWorkspace: monitor.activeWorkspace?.id ?? 1

                        ScrollView {
                            id: workspaceScroll
                            anchors.fill: parent
                            contentWidth: availableWidth
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                            ColumnLayout {
                                id: workspaceLayout
                                width: workspaceScroll.width - (workspaceScroll.ScrollBar.vertical.visible ? workspaceScroll.ScrollBar.vertical.width + 5 : 0)
                                spacing: 2

                                Repeater {
                                    model: 100
                                    MenuButton {
                                        Layout.fillWidth: true
                                        property int wsNumber: modelData + 1
                                        buttonText: qsTr("Workspace ") + wsNumber + (wsNumber === workspaceSubmenu.currentWorkspace ? " (current)" : "")
                                        onClicked: {
                                            console.log("\n=== Workspace button clicked ===")
                                            console.log("Target workspace:", wsNumber)
                                            console.log("Current workspace:", workspaceSubmenu.currentWorkspace)
                                            console.log("Initial appInfo:", JSON.stringify(dockItem.appInfo, null, 2))
                                            
                                            // Try to find the actual window in HyprlandData
                                            var actualWindow = null
                                            if (dockItem.appInfo.address) {
                                                actualWindow = HyprlandData.windowByAddress[dockItem.appInfo.address]
                                                console.log("Looking up by address:", dockItem.appInfo.address)
                                                console.log("Found window by address:", JSON.stringify(actualWindow, null, 2))
                                            } else {
                                                console.log("Looking up by class:", dockItem.appInfo.class)
                                                actualWindow = HyprlandData.windowList.find(w => {
                                                    const matches = w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                                        w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                                    console.log("Checking window:", w.class, "matches:", matches)
                                                    return matches
                                                })
                                                console.log("Found window by class:", JSON.stringify(actualWindow, null, 2))
                                            }
                                            
                                            console.log("\nWindow list:", JSON.stringify(HyprlandData.windowList, null, 2))
                                            console.log("\nWindow by address map:", JSON.stringify(HyprlandData.windowByAddress, null, 2))
                                            
                                            var cmd = ""
                                            if (actualWindow?.address) {
                                                cmd = `movetoworkspacesilent ${wsNumber},address:${actualWindow.address}`
                                                console.log("Using address command:", cmd)
                                            } else if (actualWindow?.class) {
                                                cmd = `movetoworkspacesilent ${wsNumber},class:${actualWindow.class}`
                                                console.log("Using class command:", cmd)
                                            } else if (dockItem.appInfo.pid) {
                                                cmd = `movetoworkspacesilent ${wsNumber},pid:${dockItem.appInfo.pid}`
                                                console.log("Using PID command:", cmd)
                                            } else if (dockItem.appInfo.class) {
                                                cmd = `movetoworkspacesilent ${wsNumber},class:${dockItem.appInfo.class}`
                                                console.log("Using fallback class command:", cmd)
                                            }

                                            if (cmd) {
                                                console.log("Dispatching command:", cmd)
                                                Hyprland.dispatch(cmd)
                                            } else {
                                                console.log("ERROR: No valid command could be constructed!")
                                            }
                                            
                                            dockItem.closeMenu()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(
                            Appearance.colors.colOnLayer0.r,
                            Appearance.colors.colOnLayer0.g,
                            Appearance.colors.colOnLayer0.b,
                            0.1
                        )
                    }

                    MenuButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Toggle floating")
                        enabled: {
                            // Check if we have an active window
                            var hasActiveWindow = false
                            if (dockItem.appInfo.address) {
                                hasActiveWindow = HyprlandData.windowByAddress[dockItem.appInfo.address] !== undefined
                            } else if (dockItem.appInfo.class) {
                                hasActiveWindow = HyprlandData.windowList.some(w => 
                                    w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                    w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                )
                            }
                            return hasActiveWindow
                        }
                        onClicked: {
                            console.log("Toggle floating clicked")
                            console.log("App info:", JSON.stringify(dockItem.appInfo, null, 2))
                            
                            // Try to find the actual window in HyprlandData
                            var actualWindow = null
                            if (dockItem.appInfo.address) {
                                actualWindow = HyprlandData.windowByAddress[dockItem.appInfo.address]
                            } else {
                                actualWindow = HyprlandData.windowList.find(w => 
                                    w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                    w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                )
                            }
                            
                            console.log("Found window:", JSON.stringify(actualWindow, null, 2))
                            
                            if (actualWindow?.address) {
                                console.log("Using address:", actualWindow.address)
                                Hyprland.dispatch(`togglefloating address:${actualWindow.address}`)
                            } else if (actualWindow?.class) {
                                console.log("Using class:", actualWindow.class)
                                Hyprland.dispatch(`togglefloating class:${actualWindow.class}`)
                            } else if (dockItem.appInfo.pid) {
                                console.log("Using PID:", dockItem.appInfo.pid)
                                Hyprland.dispatch(`togglefloating pid:${dockItem.appInfo.pid}`)
                            } else if (dockItem.appInfo.class) {
                                console.log("Using fallback class:", dockItem.appInfo.class)
                                Hyprland.dispatch(`togglefloating class:${dockItem.appInfo.class}`)
                            }
                            dockItem.closeMenu()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(
                            Appearance.colors.colOnLayer0.r,
                            Appearance.colors.colOnLayer0.g,
                            Appearance.colors.colOnLayer0.b,
                            0.1
                        )
                    }

                    MenuButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Close")
                        enabled: {
                            // Check if we have an active window
                            var hasActiveWindow = false
                            if (dockItem.appInfo.address) {
                                hasActiveWindow = HyprlandData.windowByAddress[dockItem.appInfo.address] !== undefined
                            } else if (dockItem.appInfo.class) {
                                hasActiveWindow = HyprlandData.windowList.some(w => 
                                    w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                    w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                )
                            }
                            return hasActiveWindow
                        }
                        onClicked: {
                            console.log("Close clicked")
                            console.log("App info:", JSON.stringify(dockItem.appInfo, null, 2))
                            
                            // Try to find the actual window in HyprlandData
                            var actualWindow = null
                            if (dockItem.appInfo.address) {
                                actualWindow = HyprlandData.windowByAddress[dockItem.appInfo.address]
                            } else {
                                actualWindow = HyprlandData.windowList.find(w => 
                                    w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                                    w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
                                )
                            }
                            
                            console.log("Found window:", JSON.stringify(actualWindow, null, 2))
                            
                            if (actualWindow?.address) {
                                console.log("Using address:", actualWindow.address)
                                Hyprland.dispatch(`closewindow address:${actualWindow.address}`)
                            } else if (actualWindow?.class) {
                                console.log("Using class:", actualWindow.class)
                                Hyprland.dispatch(`closewindow class:${actualWindow.class}`)
                            } else if (dockItem.appInfo.pid) {
                                console.log("Using PID:", dockItem.appInfo.pid)
                                Hyprland.dispatch(`closewindow pid:${dockItem.appInfo.pid}`)
                            } else if (dockItem.appInfo.class) {
                                console.log("Using fallback class:", dockItem.appInfo.class)
                                Hyprland.dispatch(`closewindow class:${dockItem.appInfo.class}`)
                            }
                            dockItem.closeApp()
                            dockItem.closeMenu()
                        }
                    }
                }
            }
        }
    }

    // --- Menu Close Function ---
    // Closes the right-click menu for this item
    function closeMenu() {
        showMenu = false
        isActiveMenu = false
    }
}

// --- Footnotes ---
// [1] Right-click triggers the context menu for this dock item.
// [2] Ensures only one menu is open at a time by closing others.
// [3] Toggles the menu: closes if already open, opens if closed.
// [4] Stores the mouse position so the menu can be placed near the click.
// [5] Setting showMenu to true triggers the Loader below to create the menu.
// [6] The Loader creates the menu window (PanelWindow) when showMenu is true.
// [7] The menu's UI and actions (Pin/Unpin, Launch, Move, Toggle, Close) are defined in DockItemMenuPanel.qml.