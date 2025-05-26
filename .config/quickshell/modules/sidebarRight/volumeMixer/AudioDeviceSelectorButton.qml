import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Button {
    id: button
    required property bool input

    transform: Scale {
        id: buttonScale
        origin.x: button.width / 2
        origin.y: button.height / 2
        xScale: button.down ? 0.95 : button.hovered ? 1.02 : 1.0
        yScale: xScale

        Behavior on xScale {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.OutBack
                easing.overshoot: 2.0
            }
        }
    }

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: (button.down) ? Appearance.colors.colLayer2Active : (button.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.OutCubic
            }
        }
    }

    PointingHandInteraction {}

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.leftMargin: 5
            color: Appearance.colors.colOnLayer2
            iconSize: Appearance.font.pixelSize.hugeass
            text: input ? "mic_external_on" : "media_output"

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.OutCubic
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 5
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                text: input ? qsTr("Input") : qsTr("Output")
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: (input ? Pipewire.defaultAudioSource?.description : Pipewire.defaultAudioSink?.description) ?? qsTr("Unknown")
                color: Appearance.m3colors.m3outline
            }
        }
    }
}