import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import "root:/services"
import "root:/modules/common"

Item {
    id: root
    
    property real iconSize: 16
    property color iconColor: "#ffffff"
    
    width: iconSize
    height: iconSize
    
    // Base ethernet icon (always visible)
    Image {
        id: baseIcon
        anchors.fill: parent
        source: "root:/logo/ethernet.svg"
        fillMode: Image.PreserveAspectFit
        visible: true
    }
    
    ColorOverlay {
        id: baseOverlay
        anchors.fill: baseIcon
        source: baseIcon
        color: root.iconColor
    }
    
    // Download indicator (green arrow pointing down)
    Rectangle {
        id: downloadIndicator
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -2
        width: 6
        height: 6
        radius: 3
        color: "#00ff88"
        opacity: 0
        
        // Pulsing animation for download activity
        SequentialAnimation {
            id: downloadAnimation
            running: Network.isDownloading
            loops: Animation.Infinite
            
            NumberAnimation {
                target: downloadIndicator
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: downloadIndicator
                property: "opacity"
                from: 1
                to: 0
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
        
        // Fade out when not downloading
        Behavior on opacity {
            enabled: !Network.isDownloading
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
    
    // Upload indicator (orange arrow pointing up)
    Rectangle {
        id: uploadIndicator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: -2
        anchors.leftMargin: -2
        width: 6
        height: 6
        radius: 3
        color: "#ff6600"
        opacity: 0
        
        // Pulsing animation for upload activity
        SequentialAnimation {
            id: uploadAnimation
            running: Network.isUploading
            loops: Animation.Infinite
            
            NumberAnimation {
                target: uploadIndicator
                property: "opacity"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: uploadIndicator
                property: "opacity"
                from: 1
                to: 0
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
        
        // Fade out when not uploading
        Behavior on opacity {
            enabled: !Network.isUploading
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
    
    // Activity glow effect when there's any network activity
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: width / 2
        color: "transparent"
        border.color: Network.hasActivity ? "#4488ff" : "transparent"
        border.width: 1
        opacity: Network.hasActivity ? 0.6 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
        
        // Subtle breathing animation when active
        SequentialAnimation {
            running: Network.hasActivity
            loops: Animation.Infinite
            
            NumberAnimation {
                target: parent
                property: "scale"
                from: 1.0
                to: 1.1
                duration: 1000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: parent
                property: "scale"
                from: 1.1
                to: 1.0
                duration: 1000
                easing.type: Easing.InOutSine
            }
        }
    }
} 