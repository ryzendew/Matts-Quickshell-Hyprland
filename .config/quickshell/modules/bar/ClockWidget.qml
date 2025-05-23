import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool borderless: ConfigOptions.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 6
    implicitHeight: 32
    color: "transparent"

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer0
            text: DateTime.time
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            text: "•"
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            text: DateTime.date
        }

    }

}
