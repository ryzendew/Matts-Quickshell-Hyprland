import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "root:/modules/common/widgets"
import "./quickToggles"
import "../common/AppearanceSettingsState.qml" as AppearanceSettingsState

Flickable {
    id: flick
    contentWidth: parent ? parent.width : 320
    contentHeight: appearanceColumn.implicitHeight
    clip: true
    interactive: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: appearanceColumn
        width: flick.width
        spacing: 20
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 15

        StyledText {
            text: qsTr("Bar Appearance")
            font.pixelSize: Appearance.font.pixelSize.larger
            color: "#ffffff"
            Layout.topMargin: 6
            Layout.bottomMargin: 4
        }
        Rectangle { height: 1; color: Appearance.colors.colLayer0; Layout.fillWidth: true; opacity: 0.5 }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Transparency"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: barTransparencySlider
                from: 0; to: 1; stepSize: 0.01
                value: AppearanceSettingsState.barTransparency
                onValueChanged: AppearanceSettingsState.barTransparency = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for transparency
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(barTransparencySlider.value * 100) + "%"
                color: "#ffffff" 
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Amount"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: barBlurSlider
                from: 0; to: 100; stepSize: 1
                value: AppearanceSettingsState.barBlurAmount
                onValueChanged: AppearanceSettingsState.barBlurAmount = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(barBlurSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Passes"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: barBlurPassesSlider
                from: 1; to: 8; stepSize: 1
                value: AppearanceSettingsState.barBlurPasses
                onValueChanged: AppearanceSettingsState.barBlurPasses = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur passes
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(barBlurPassesSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Xray"); Layout.preferredWidth: 120; color: "#ffffff" }
            RowLayout {
                spacing: 5
                QuickToggleButton {
                    toggled: AppearanceSettingsState.barXray
                    buttonIcon: "visibility"
                    onClicked: AppearanceSettingsState.barXray = !AppearanceSettingsState.barXray
                }
                StyledText {
                    text: AppearanceSettingsState.barXray ? "On" : "Off"
                    color: AppearanceSettingsState.barXray ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        StyledText {
            text: qsTr("Dock Appearance")
            font.pixelSize: Appearance.font.pixelSize.larger
            color: "#ffffff"
            Layout.topMargin: 12
            Layout.bottomMargin: 4
        }
        Rectangle { height: 1; color: Appearance.colors.colLayer0; Layout.fillWidth: true; opacity: 0.5 }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Transparency"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: dockTransparencySlider
                from: 0; to: 1; stepSize: 0.01
                value: AppearanceSettingsState.dockTransparency
                onValueChanged: AppearanceSettingsState.dockTransparency = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for transparency
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(dockTransparencySlider.value * 100) + "%"
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Amount"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: dockBlurSlider
                from: 0; to: 100; stepSize: 1
                value: AppearanceSettingsState.dockBlurAmount
                onValueChanged: AppearanceSettingsState.dockBlurAmount = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(dockBlurSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Passes"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: dockBlurPassesSlider
                from: 1; to: 8; stepSize: 1
                value: AppearanceSettingsState.dockBlurPasses
                onValueChanged: AppearanceSettingsState.dockBlurPasses = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur passes
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(dockBlurPassesSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Xray"); Layout.preferredWidth: 120; color: "#ffffff" }
            RowLayout {
                spacing: 5
                QuickToggleButton {
                    toggled: AppearanceSettingsState.dockXray
                    buttonIcon: "visibility"
                    onClicked: AppearanceSettingsState.dockXray = !AppearanceSettingsState.dockXray
                }
                StyledText {
                    text: AppearanceSettingsState.dockXray ? "On" : "Off"
                    color: AppearanceSettingsState.dockXray ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        StyledText {
            text: qsTr("Sidebar Appearance")
            font.pixelSize: Appearance.font.pixelSize.larger
            color: "#ffffff"
            Layout.topMargin: 12
            Layout.bottomMargin: 4
        }
        Rectangle { height: 1; color: Appearance.colors.colLayer0; Layout.fillWidth: true; opacity: 0.5 }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Transparency"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: sidebarTransparencySlider
                from: 0; to: 1; stepSize: 0.01
                value: AppearanceSettingsState.sidebarTransparency
                onValueChanged: AppearanceSettingsState.sidebarTransparency = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for transparency
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(sidebarTransparencySlider.value * 100) + "%"
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Amount"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: sidebarBlurSlider
                from: 0; to: 100; stepSize: 1
                value: AppearanceSettingsState.sidebarBlurAmount
                onValueChanged: AppearanceSettingsState.sidebarBlurAmount = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(sidebarBlurSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Blur Passes"); Layout.preferredWidth: 120; color: "#ffffff" }
            StyledSlider {
                id: sidebarBlurPassesSlider
                from: 1; to: 8; stepSize: 1
                value: AppearanceSettingsState.sidebarBlurPasses
                onValueChanged: AppearanceSettingsState.sidebarBlurPasses = value
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                highlightColor: Qt.rgba(1, 1, 1, 0.8)  // White for blur passes
                trackColor: Qt.rgba(1, 1, 1, 0.2)      // Dimmed white for track
            }
            StyledText { 
                text: Math.round(sidebarBlurPassesSlider.value)
                color: "#ffffff"
                Layout.minimumWidth: 45
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            StyledText { text: qsTr("Xray"); Layout.preferredWidth: 120; color: "#ffffff" }
            RowLayout {
                spacing: 5
                QuickToggleButton {
                    toggled: AppearanceSettingsState.sidebarXray
                    buttonIcon: "visibility"
                    onClicked: AppearanceSettingsState.sidebarXray = !AppearanceSettingsState.sidebarXray
                }
                StyledText {
                    text: AppearanceSettingsState.sidebarXray ? "On" : "Off"
                    color: AppearanceSettingsState.sidebarXray ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        Item { Layout.fillHeight: true; height: 10 }
    }
} 