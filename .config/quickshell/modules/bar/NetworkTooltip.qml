import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell
import "root:/modules/common"
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
        Item {
            anchors.fill: parent
            z: -1
            MultiEffect {
                anchors.fill: parent
                source: networkTooltip
                shadowEnabled: true
                shadowColor: Appearance.colors.colShadow
                shadowVerticalOffset: 1
                shadowBlur: 0.5
            }
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
        
        // Position directly using the provided coordinates
        x = mouseX - width / 2
        y = mouseY + 20
        
        // Keep tooltip on screen
        if (x < 0) x = 0
        if (x + width > screen.width) x = screen.width - width
        if (y + height > screen.height) y = mouseY - height - 5
    }

    function show() {
        visible = true
    }

    function hide() {
        visible = false
    }
} 