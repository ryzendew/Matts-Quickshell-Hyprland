import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool borderless: ConfigOptions.bar.borderless
    implicitWidth: colLayout.implicitWidth + 2
    implicitHeight: 28
    color: "transparent"

    ColumnLayout {
        id: colLayout
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            text: DateTime.time
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.tiny
            color: Appearance.colors.colOnLayer0
            text: DateTime.date
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
