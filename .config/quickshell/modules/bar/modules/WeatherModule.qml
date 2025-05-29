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
    Layout.minimumWidth: 100
    implicitWidth: weather.implicitWidth
    implicitHeight: weather.implicitHeight
    
    Weather {
        id: weather
        anchors.fill: parent
        weatherLocation: "Halifax, Nova Scotia, Canada"
    }
} 