import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ListView {
    id: root
    property var notifications: []
    property bool isExpanded: false
    property bool isHovered: false
    property bool isPressed: false
    property bool isDragging: false
    property bool isDismissed: false

    width: parent.width
    height: contentHeight
    spacing: 10
    clip: true

    model: notifications

    delegate: NotificationGroup {
        groupObject: modelData
    }

    function destroyWithAnimation() {
        opacity = 0
        scale = 0.8
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        },
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
        destroy()
    }
}