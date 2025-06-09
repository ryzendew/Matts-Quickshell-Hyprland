import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: borderless ? "transparent" : Qt.rgba(
        Appearance.colors.colLayer1.r,
        Appearance.colors.colLayer1.g,
        Appearance.colors.colLayer1.b,
        0.8 // 80% opacity to match bar
    )
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Hyprland.dispatch("exec grimblast copy area")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "screenshot_region"
                iconSize: Appearance.font.pixelSize.normal
                color: "#FFFFFF"
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Hyprland.dispatch("exec hyprpicker -a")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "colorize"
                iconSize: Appearance.font.pixelSize.normal
                color: "#FFFFFF"
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Hyprland.dispatch("exec wvkbd-mobintl")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "keyboard"
                iconSize: Appearance.font.pixelSize.normal
                color: "#FFFFFF"
            }
        }

    }

}
