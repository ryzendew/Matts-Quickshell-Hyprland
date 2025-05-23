import "root:/modules/common"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Button {
    id: button

    required default property Item content
    property bool extraActiveCondition: false

    PointingHandInteraction{}

    implicitHeight: Math.max(content.implicitHeight, 26, content.implicitHeight)
    implicitWidth: Math.max(content.implicitHeight, 26, content.implicitWidth)
    contentItem: content

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: (button.down || extraActiveCondition) ? 
            Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
            button.hovered ? 
            Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.8) : 
            ColorUtils.transparentize(Appearance.colors.colLayer1, 1)
    }

}
