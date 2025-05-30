import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    
    property string source: ""
    property string iconFolder: "root:/assets/icons"  // The folder to check first
    width: 30
    height: 30
    
    SystemIcon {
        id: iconImage
        anchors.fill: parent
        iconName: {
            var potentialPath = "";
            if (root.source && root.source.startsWith("/")) {
                potentialPath = root.source;
            } else if (iconFolder && root.source) {
                potentialPath = root.source;
            } else {
                potentialPath = root.source;
            }
            return potentialPath;
        }
        iconSize: Math.min(root.width, root.height)
    }
}
