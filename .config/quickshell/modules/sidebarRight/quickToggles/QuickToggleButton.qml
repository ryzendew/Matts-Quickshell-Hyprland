import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon
    property bool hasRightClickAction: false
    property real buttonSize: hasRightClickAction ? 48 : 40

    implicitWidth: buttonSize
    implicitHeight: buttonSize

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        radius: hasRightClickAction ? Appearance.rounding.medium : Appearance.rounding.full
        color: toggled ? 
            (button.down ? Appearance.colors.colLayer2Active : button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2) :
            (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
        
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: hasRightClickAction ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.larger
            fill: toggled ? 1 : 0
            text: buttonIcon
            color: "#FFFFFF"

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: if (hasRightClickAction && mouse.button === Qt.RightButton) button.rightClicked()
    }

    signal rightClicked()
}
