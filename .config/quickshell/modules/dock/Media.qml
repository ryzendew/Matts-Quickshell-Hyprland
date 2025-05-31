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
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    readonly property string formattedText: cleanedTitle + (activePlayer?.trackArtist ? (" - " + String(activePlayer.trackArtist)) : "")
    
    // Properties for album art, similar to PlayerControl.qml
    property var artUrl: activePlayer?.trackArtUrl
    property string artDownloadLocation: Quickshell.Io.Directories.coverArt // Assuming Directories is accessible via Quickshell.Io
    property string artFileName: Qt.md5(artUrl) + ".jpg"
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    property color artDominantColor: colorQuantizer?.colors[0] || Appearance.m3colors.m3secondaryContainer

    // Track position and length separately for better accuracy
    property real currentPosition: activePlayer ? activePlayer.position : 0
    property real totalLength: activePlayer ? activePlayer.length : 0
    readonly property real progress: totalLength > 0 ? Math.min(1, Math.max(0, currentPosition / totalLength)) : 0

    Layout.fillHeight: true
    implicitWidth: contentRow.implicitWidth + 35
    implicitHeight: parent.height

    // Album art image (fills the background)
    Image {
        id: albumArtBackground
        anchors.fill: parent
        source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.15 // Low opacity for subtle background
        visible: root.activePlayer && root.artUrl.length > 0
        cache: false
        asynchronous: true
    }

    // Art URL change handler and downloader process, similar to PlayerControl.qml
    onArtUrlChanged: {
        if (root.artUrl.length == 0) {
            root.downloaded = false; // Reset downloaded state
            return;
        }
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        command: [ "bash", "-c", `mkdir -p '${root.artDownloadLocation}' && [ -f '${root.artFilePath}' ] || curl -sSL '${targetFile}' -o '${root.artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.downloaded = true
            } else {
                console.warn("Media.qml: Failed to download album art from", targetFile, "Exit code:", exitCode)
                root.downloaded = false
            }
        }
    }

    ColorQuantizer { // Added for artDominantColor, if needed later, or for consistency
        id: colorQuantizer
        source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

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
            text: String(formattedText)
            font.pixelSize: Appearance.font.pixelSize.normal
            font.family: Appearance.font.family.main
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
            elide: Text.ElideNone
            clip: false
        }
    }

    // Use TextMetrics to calculate the exact width needed
    TextMetrics {
        id: textMetrics
        text: String(formattedText)
        font.pixelSize: Appearance.font.pixelSize.normal
        font.family: Appearance.font.family.main
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
