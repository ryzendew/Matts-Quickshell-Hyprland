import "root:/modules/common/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item
    property bool targetMenuOpen: false
    property int trayItemWidth: 16

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    Layout.fillHeight: true
    implicitWidth: trayItemWidth
    onClicked: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu) menu.open();
            break;
        }
        event.accepted = true;
    }

    QsMenuAnchor {
        id: menu

        menu: root.item.menu
        anchor.window: bar
        anchor.rect.x: root.x + bar.width - 500
        anchor.rect.y: root.y
        anchor.rect.height: root.height
        anchor.edges: Edges.Bottom
    }

    IconImage {
        id: trayIcon
        //source: root.item.icon <- old

        // Possible tray icon fix
        source: {
            let icon = modelData?.icon || "";
            if (icon.includes("?path=")) {
                    const [name, path] = icon.split("?path=");
                    const fileName = name.substring(name.lastIndexOf("/") + 1);
                    return `file://${path}/${fileName}`;
            }
            return icon;
        }
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
    }

    Desaturate {
        id: desaturatedIcon
        anchors.fill: trayIcon
        source: trayIcon
        desaturation: 0 // 1.0 means fully grayscale
    }
    ColorOverlay {
        anchors.fill: desaturatedIcon
        source: desaturatedIcon
        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 1.0)
    }

}
