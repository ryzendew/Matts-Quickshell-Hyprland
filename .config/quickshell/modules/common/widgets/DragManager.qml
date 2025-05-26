import QtQuick
import QtQuick.Controls
import "root:/modules/common"

MouseArea {
    id: dragManager
    property bool interactive: false
    property real startX: 0
    property real startY: 0
    property real dragStartThreshold: 10
    property real dragConfirmThreshold: 70
    property bool dragStarted: false
    property bool preventStealing: true
    property bool horizontalOnly: false
    property bool verticalOnly: false

    signal dragBegin(real startX, real startY)
    signal dragUpdate(real deltaX, real deltaY)
    signal dragEnd(real deltaX, real deltaY)
    signal dragCancelled()

    hoverEnabled: interactive
    preventStealing: interactive && preventStealing

    onPressed: (mouse) => {
        if (!interactive) {
            mouse.accepted = false
            return
        }
        startX = mouse.x
        startY = mouse.y
    }

    onPositionChanged: (mouse) => {
        if (!interactive) {
            mouse.accepted = false
            return
        }

        let dx = mouse.x - startX
        let dy = mouse.y - startY
        
        if (horizontalOnly) dy = 0
        if (verticalOnly) dx = 0

        if (dragStarted || Math.abs(dx) > dragStartThreshold || Math.abs(dy) > dragStartThreshold) {
            if (!dragStarted) {
                dragStarted = true
                dragBegin(startX, startY)
            }
            dragUpdate(dx, dy)
        }
    }

    onReleased: (mouse) => {
        if (!interactive) {
            mouse.accepted = false
            return
        }

        let dx = mouse.x - startX
        let dy = mouse.y - startY
        
        if (horizontalOnly) dy = 0
        if (verticalOnly) dx = 0

        if (dragStarted) {
            if (Math.abs(dx) > dragConfirmThreshold || Math.abs(dy) > dragConfirmThreshold) {
                dragEnd(dx, dy)
            } else {
                dragCancelled()
            }
        }
        dragStarted = false
    }

    onInteractiveChanged: {
        if (!interactive) {
            dragStarted = false
            dragCancelled()
        }
    }
} 