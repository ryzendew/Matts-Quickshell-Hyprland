import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

Rectangle {
    id: dockItem
    
    property string icon: ""
    property string tooltip: ""
    property bool isActive: false
    property bool showMenu: false
    property var appInfo: ({})
    property bool isPinned: false
    property int layoutIndex: parent ? parent.children.indexOf(dockItem) : 0
    property int modelIndex: index  // Get index from Repeater
    property string clickedAppClass: ""
    property int itemIndex: parent ? parent.children.indexOf(this) : 0
    property point lastClickPos: Qt.point(0, 0)  // Store the last click position
    property bool isActiveMenu: false
    
    signal clicked()
    signal pinApp()
    signal unpinApp()
    signal closeApp()
    
    implicitWidth: dock.dockWidth - 10
    implicitHeight: dock.dockWidth - 10
    radius: Appearance.rounding.full
    color: mouseArea.pressed ? Appearance.colors.colLayer1Active : 
           mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
           "transparent"
    
    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }
    
    Image {
        id: iconItem
        anchors.centerIn: parent
        width: parent.width * 0.65
        height: parent.height * 0.65
        source: "image://icon/" + dockItem.icon
        sourceSize.width: width
        sourceSize.height: height
        cache: true
        asynchronous: false
        smooth: true
        antialiasing: true
        anchors.bottomMargin: 10
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                dockItem.clicked()
            } else if (mouse.button === Qt.RightButton) {
                // Close any other open menus first
                var items = parent.children
                for (var i = 0; i < items.length; i++) {
                    var item = items[i]
                    if (item !== dockItem && item.closeMenu) {
                        item.closeMenu()
                    }
                }
                
                // Toggle this menu
                if (dockItem.showMenu) {
                    dockItem.closeMenu()
                } else {
                    lastClickPos = Qt.point(mouse.x, mouse.y)
                    dockItem.showMenu = true
                    dockItem.isActiveMenu = true
                }
            }
        }
        
        onEntered: dock.mouseOverDockItem = true
        onExited: dock.mouseOverDockItem = false
    }
    
    // Active indicator dot
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
    
    ToolTip {
        id: itemTooltip
        visible: mouseArea.containsMouse && dockItem.tooltip !== ""
        text: dockItem.tooltip
        delay: 0
        timeout: 5000
        contentItem: StyledText {
            text: itemTooltip.text
            color: Appearance.colors.colOnTooltip
            horizontalAlignment: Text.AlignHCenter
        }
        
        background: Rectangle {
            color: Appearance.colors.colTooltip
            radius: Appearance.rounding.small
        }
    }

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
                left: dockItem.x + lastClickPos.x + 500
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
                            var command = dockItem.appInfo.command || dockItem.appInfo.class.toLowerCase()
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

    // Function to close menu
    function closeMenu() {
        showMenu = false
        isActiveMenu = false
    }
}