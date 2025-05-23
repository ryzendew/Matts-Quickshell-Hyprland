import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    readonly property string formattedText: cleanedTitle + (activePlayer?.trackArtist ? " - " + activePlayer.trackArtist : "")
    
    // Track position and length separately for better accuracy
    property real currentPosition: activePlayer ? activePlayer.position : 0
    property real totalLength: activePlayer ? activePlayer.length : 0
    readonly property real progress: totalLength > 0 ? Math.min(1, Math.max(0, currentPosition / totalLength)) : 0

    Layout.fillHeight: true
    implicitWidth: contentRow.implicitWidth + 32
    implicitHeight: parent.height

    // Update position when player changes
    Connections {
        target: activePlayer
        function onPositionChanged() {
            currentPosition = activePlayer.position
        }
        function onLengthChanged() {
            totalLength = activePlayer.length
        }
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 500
        repeat: true
        onTriggered: {
            if (activePlayer) {
                currentPosition = activePlayer.position
                totalLength = activePlayer.length
            }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        height: parent.height
        spacing: 16

        CircularProgress {
            id: progressCircle
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            lineWidth: 2
            value: root.progress
            Behavior on value {
                enabled: activePlayer?.playbackState == MprisPlaybackState.Playing
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
            secondaryColor: Appearance.m3colors.m3secondaryContainer
            primaryColor: Appearance.m3colors.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: activePlayer?.isPlaying ? "pause" : "play_arrow"
                iconSize: 20
                color: Appearance.m3colors.m3onSecondaryContainer
            }
        }

        Text {
            id: mediaText
            anchors.verticalCenter: parent.verticalCenter
            width: textMetrics.width
            color: Appearance.colors.colOnLayer1
            text: formattedText
            font.pixelSize: Appearance.font.pixelSize.normal
            font.family: Appearance.font.family
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
            elide: Text.ElideNone
            clip: false
        }
    }

    // Use TextMetrics to calculate the exact width needed
    TextMetrics {
        id: textMetrics
        text: formattedText
        font.pixelSize: Appearance.font.pixelSize.normal
        font.family: Appearance.font.family
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                Hyprland.dispatch("global quickshell:mediaControlsToggle")
            }
        }
    }
}
