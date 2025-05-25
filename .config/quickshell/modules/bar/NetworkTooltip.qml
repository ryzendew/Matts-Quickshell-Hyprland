import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "root:/services"

PanelWindow {
    id: tooltipWindow
    visible: false
    color: "transparent"
    exclusiveZone: -1

    Rectangle {
        id: networkTooltip
        anchors.fill: parent
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.small
        opacity: tooltipWindow.visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }

        // Add a subtle shadow
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8.0
            samples: 17
            color: "#80000000"
        }

        ColumnLayout {
            id: tooltipLayout
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: Network.networkName || "Not Connected"
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: Network.networkType === "wifi" ? Network.networkStrength + "% Signal Strength" : "No WiFi Connection"
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                opacity: 0.8
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    function updatePosition(mouseX, mouseY) {
        width = tooltipLayout.implicitWidth + 20
        height = tooltipLayout.implicitHeight + 16
        
        // Position relative to the screen
        var pos = screen.mapFromGlobal(mouseX, mouseY)
        x = pos.x
        y = pos.y + 20
    }

    function show() {
        visible = true
    }

    function hide() {
        visible = false
    }
} 