import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool borderless: ConfigOptions.bar.borderless
    implicitWidth: colLayout.implicitWidth + 8
    implicitHeight: 32
    color: "transparent"

    ColumnLayout {
        id: colLayout
        anchors.centerIn: parent
        spacing: 1

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer0
            text: DateTime.time
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer0
            text: DateTime.date
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }

}
