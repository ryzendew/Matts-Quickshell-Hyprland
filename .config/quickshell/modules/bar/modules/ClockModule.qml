import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "../"

Item {
    Layout.alignment: Qt.AlignVCenter
    Layout.rightMargin: 4
    Layout.leftMargin: 4
    implicitWidth: clockWidget.implicitWidth
    implicitHeight: clockWidget.implicitHeight
    
    ClockWidget {
        id: clockWidget
        anchors.fill: parent
    }
} 