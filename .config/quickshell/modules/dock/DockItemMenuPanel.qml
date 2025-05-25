import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "root:/modules/common"
import "root:/modules/common/widgets"

PanelWindow {
    id: menuRoot
    
    property var appInfo: ({})
    property bool isPinned: false
    property point clickPos: Qt.point(0, 0)
    property int menuWidth: 200
    
    // Signals
    signal pinApp()
    signal unpinApp()
    signal closeApp()
    
    function show(pos) {
        clickPos = pos
        visible = true
        // Force layout update before positioning
        menuContent.implicitHeight = menuContent.childrenRect.height + menuContent.padding * 2
    }
    
    function hide() {
        visible = false
        destroy()
    }
    
    color: "transparent"
    visible: false
    implicitWidth: menuWidth
    implicitHeight: menuContent.implicitHeight
    
    // Set up as a popup window
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboard_mode: WlrKeyboardMode.None
    WlrLayershell.namespace: "quickshell:dockmenu"
    WlrLayershell.exclusive_zone: -1  // Don't reserve space
    
    // Click outside to close
    HyprlandFocusGrab {
        id: grab
        windows: [menuRoot]
        active: menuRoot.visible
        onCleared: () => {
            if (!active) menuRoot.hide()
        }
    }
    
    // Menu content
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: Qt.rgba(
            Appearance.colors.colLayer0.r,
            Appearance.colors.colLayer0.g,
            Appearance.colors.colLayer0.b,
            1.0
        )
        radius: Appearance.rounding.small
        
        // Add padding for content
        property int padding: 4
        
        // Add shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            source: menuContent
            anchors.fill: menuContent
            shadowEnabled: true
            shadowColor: Appearance.colors.colShadow
            shadowVerticalOffset: 1
            shadowBlur: 0.5
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: menuContent.padding
            spacing: 2
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
                onClicked: {
                    if (isPinned) {
                        menuRoot.unpinApp()
                    } else {
                        menuRoot.pinApp()
                    }
                    menuRoot.hide()
                }
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Launch new instance")
                onClicked: {
                    var command = appInfo.command || appInfo.class.toLowerCase()
                    Hyprland.dispatch(`exec ${command}`)
                    menuRoot.hide()
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
                buttonText: qsTr("Move to workspace")
                enabled: appInfo.address !== undefined
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`dispatch movetoworkspace +1 address:${appInfo.address}`)
                    }
                    menuRoot.hide()
                }
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Toggle floating")
                enabled: appInfo.address !== undefined
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`dispatch togglefloating address:${appInfo.address}`)
                    }
                    menuRoot.hide()
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
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`dispatch closewindow address:${appInfo.address}`)
                    } else if (appInfo.pid) {
                        Hyprland.dispatch(`dispatch closewindow pid:${appInfo.pid}`)
                    } else {
                        Hyprland.dispatch(`dispatch closewindow class:${appInfo.class}`)
                    }
                    menuRoot.closeApp()
                    menuRoot.hide()
                }
            }
        }
    }
    
    Component.onCompleted: {
        // Force layout update before positioning
        menuContent.implicitHeight = menuContent.childrenRect.height + menuContent.padding * 2
        
        // Position the menu above the click position
        var yPos = clickPos.y - height - 5
        if (yPos < 0) {
            // If it would go off the top, show below instead
            yPos = clickPos.y + 5
        }
        
        // Center horizontally on click position
        var xPos = clickPos.x - (width / 2)
        
        // Keep within screen bounds
        var screen = Qt.application.screens[0]
        if (xPos + width > screen.width) {
            xPos = screen.width - width - 5
        }
        if (xPos < 0) {
            xPos = 5
        }
        
        x = xPos
        y = yPos
    }
} 