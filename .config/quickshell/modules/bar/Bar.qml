import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth
    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: ConfigOptions.bar.showBackground

    // Watch for changes in blur settings
    Connections {
        target: AppearanceSettingsState
        function onBarBlurAmountChanged() {
            // Update Hyprland blur rules for bar
            Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.barBlurPasses}`)
            Hyprland.dispatch(`keyword decoration:blur:size ${AppearanceSettingsState.barBlurAmount}`)
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onBarBlurPassesChanged() {
            Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.barBlurPasses}`)
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onBarTransparencyChanged() {
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
    }

    Component.onCompleted: {
        // Apply initial blur settings
        Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.barBlurPasses}`)
        Hyprland.dispatch(`keyword decoration:blur:size ${AppearanceSettingsState.barBlurAmount}`)
    }

    Variants { // For each monitor
        model: Quickshell.screens

        PanelWindow { // Bar window
            id: barRoot

            property ShellScreen modelData
            property var brightnessMonitor: Brightness.getMonitorForScreen(modelData)
            property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen.width) ? 2 :
                (Appearance.sizes.barShortenScreenWidthThreshold >= screen.width) ? 1 : 0
            readonly property int centerSideModuleWidth: 
                (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened :
                (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : 
                    Appearance.sizes.barCenterSideModuleWidth

            NetworkTooltip {
                id: networkTooltip
                screen: modelData
            }

            screen: modelData
            implicitHeight: barHeight
            exclusiveZone: showBarBackground ? barHeight : (barHeight - 4)
            mask: Region {
                item: barContent
            }
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            Rectangle { // Bar background
                id: barContent
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                height: barHeight

                // Blur background layer
                Rectangle {
                    id: blurLayer
                    anchors.fill: parent
                    color: "transparent"
                    
                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: AppearanceSettingsState.barBlurAmount
                        cached: true
                    }
                }

                // Content layer
                Rectangle {
                    anchors.fill: parent
                    color: showBarBackground ? Qt.rgba(
                        Appearance.colors.colLayer0.r,
                        Appearance.colors.colLayer0.g,
                        Appearance.colors.colLayer0.b,
                        1 - AppearanceSettingsState.barTransparency
                    ) : "transparent"
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                        }
                    }
                }

                // Bottom border
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3
                    color: "black"
                }
                
                MouseArea { // Left side | scroll to change brightness
                    id: barLeftSideMouseArea
                    anchors.left: parent.left
                    implicitHeight: barHeight
                    width: (barRoot.width - middleSection.width) / 2
                    property bool hovered: false
                    property real lastScrollX: 0
                    property real lastScrollY: 1
                    property bool trackingScroll: false
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: (event) => {
                        barLeftSideMouseArea.hovered = true
                    }
                    onExited: (event) => {
                        barLeftSideMouseArea.hovered = false
                        barLeftSideMouseArea.trackingScroll = false
                    }
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            Hyprland.dispatch('global quickshell:sidebarLeftOpen')
                        }
                    }
                    // Scroll to change brightness
                    WheelHandler {
                        onWheel: (event) => {
                            if (event.angleDelta.y < 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness - 0.05);
                            else if (event.angleDelta.y > 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness + 0.05);
                            // Store the mouse position and start tracking
                            barLeftSideMouseArea.lastScrollX = event.x;
                            barLeftSideMouseArea.lastScrollY = event.y;
                            barLeftSideMouseArea.trackingScroll = true;
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                    onPositionChanged: (mouse) => {
                        if (barLeftSideMouseArea.trackingScroll) {
                            const dx = mouse.x - barLeftSideMouseArea.lastScrollX;
                            const dy = mouse.y - barLeftSideMouseArea.lastScrollY;
                            if (Math.sqrt(dx*dx + dy*dy) > osdHideMouseMoveThreshold) {
                                Hyprland.dispatch('global quickshell:osdBrightnessHide')
                                barLeftSideMouseArea.trackingScroll = false;
                            }
                        }
                    }
                    Item {  // Left section
                        anchors.fill: parent
                        implicitHeight: leftSectionRowLayout.implicitHeight
                        implicitWidth: leftSectionRowLayout.implicitWidth

                        ScrollHint {
                            reveal: barLeftSideMouseArea.hovered
                            icon: "light_mode"
                            tooltipText: qsTr("Scroll to change brightness")
                            side: "left"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            
                        }
                        
                        RowLayout { // Content
                            id: leftSectionRowLayout
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.leftMargin: 2
                                Layout.fillWidth: false
                                
                                radius: Appearance.rounding.full
                                color: archMouseArea.containsMouse ? 
                                    Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
                                    "transparent"
                                implicitWidth: archLogo.width + 10
                                implicitHeight: archLogo.height + 10

                                Image {
                                    id: archLogo
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: "file:///home/matt/.config/quickshell/logo/Arch-linux-logo.png"
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                MouseArea {
                                    id: archMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    onClicked: {
                                        Hyprland.dispatch("exec hyprmenu")
                                    }
                                }
                            }

                            // Spacer
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                RowLayout { // Middle section
                    id: middleSection
                    anchors.centerIn: parent
                    spacing: 8

                    RowLayout {
                        id: leftCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // (empty, reserved for future symmetry)
                    }

                    RowLayout {
                        id: middleCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Workspaces {
                            bar: barRoot
                            Layout.alignment: Qt.AlignCenter
                            MouseArea { // Right-click to toggle overview
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onPressed: (event) => {
                                    if (event.button === Qt.RightButton) {
                                        Hyprland.dispatch('global quickshell:overviewToggle')
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: rightCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // (empty, reserved for future symmetry)
                    }
                }

                MouseArea { // Right side | scroll to change volume
                    id: barRightSideMouseArea

                    anchors.right: parent.right
                    implicitHeight: barHeight
                    width: (barRoot.width - middleSection.width) / 2

                    property bool hovered: false
                    property real lastScrollX: 0
                    property real lastScrollY: 0
                    property bool trackingScroll: false
                    
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: (event) => {
                        barRightSideMouseArea.hovered = true
                    }
                    onExited: (event) => {
                        barRightSideMouseArea.hovered = false
                        barRightSideMouseArea.trackingScroll = false
                    }
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            Hyprland.dispatch('global quickshell:sidebarRightOpen')
                        }
                        else if (event.button === Qt.RightButton) {
                            MprisController.activePlayer.next()
                        }
                    }
                    // Scroll to change volume
                    WheelHandler {
                        onWheel: (event) => {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            if (event.angleDelta.y < 0)
                                Audio.sink.audio.volume -= step;
                            else if (event.angleDelta.y > 0)
                                Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
                            // Store the mouse position and start tracking
                            barRightSideMouseArea.lastScrollX = event.x;
                            barRightSideMouseArea.lastScrollY = event.y;
                            barRightSideMouseArea.trackingScroll = true;
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                    onPositionChanged: (mouse) => {
                        if (barRightSideMouseArea.trackingScroll) {
                            const dx = mouse.x - barRightSideMouseArea.lastScrollX;
                            const dy = mouse.y - barRightSideMouseArea.lastScrollY;
                            if (Math.sqrt(dx*dx + dy*dy) > osdHideMouseMoveThreshold) {
                                Hyprland.dispatch('global quickshell:osdVolumeHide')
                                barRightSideMouseArea.trackingScroll = false;
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        implicitHeight: rightSectionRowLayout.implicitHeight
                        implicitWidth: rightSectionRowLayout.implicitWidth
                        
                        ScrollHint {
                            reveal: barRightSideMouseArea.hovered
                            icon: "volume_up"
                            tooltipText: qsTr("Scroll to change volume")
                            side: "right"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RowLayout {
                            id: rightSectionRowLayout
                            anchors.fill: parent
                            spacing: 5
                            layoutDirection: Qt.RightToLeft
                    
                            Rectangle {
                                Layout.margins: 4
                                Layout.rightMargin: 2
                                Layout.fillHeight: true
                                implicitWidth: indicatorsRowLayout.implicitWidth + 10*2
                                radius: Appearance.rounding.full
                                color: (barRightSideMouseArea.pressed || GlobalStates.sidebarRightOpen) ? 
                                    Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
                                    barRightSideMouseArea.hovered ? 
                                    Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.8) : 
                                    "transparent"
                                RowLayout {
                                    id: indicatorsRowLayout
                                    anchors.centerIn: parent
                                    property real realSpacing: 15
                                    spacing: 0
                                    
                                    Revealer {
                                        reveal: Audio.sink?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "volume_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                    Revealer {
                                        reveal: Audio.source?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "mic_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                    // Network icons
                                    Item {
                                        width: Appearance.font.pixelSize.larger
                                        height: Appearance.font.pixelSize.larger
                                        Layout.rightMargin: indicatorsRowLayout.realSpacing - 1.5
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 4

                                            // Ethernet icon
                                            Rectangle {
                                                Layout.preferredWidth: Appearance.font.pixelSize.larger * 0.85
                                                Layout.preferredHeight: Appearance.font.pixelSize.larger * 0.85
                                                color: "transparent"
                                                visible: Network.networkType === "ethernet"

                                                Image {
                                                    id: ethernetIcon
                                                    anchors.fill: parent
                                                    source: "root:/logo/ethernet.svg"
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: true
                                                }

                                                ColorOverlay {
                                                    anchors.fill: parent
                                                    source: ethernetIcon
                                                    color: Appearance.colors.colOnLayer0
                                                }
                                            }

                                            // WiFi icon
                                            Rectangle {
                                                id: wifiIconRect
                                                Layout.preferredWidth: Appearance.font.pixelSize.larger * 0.85
                                                Layout.preferredHeight: Appearance.font.pixelSize.larger * 0.85
                                                color: "transparent"
                                                visible: Network.networkType === "wifi"

                                                Image {
                                                    id: wifiIcon
                                                    anchors.fill: parent
                                                    source: Network.wifiEnabled ? (
                                                        Network.networkStrength > 80 ? "root:/logo/wifi-4.svg" :
                                                        Network.networkStrength > 60 ? "root:/logo/wifi-3.svg" :
                                                        Network.networkStrength > 40 ? "root:/logo/wifi-2.svg" :
                                                        Network.networkStrength > 20 ? "root:/logo/wifi-1.svg" :
                                                        "root:/logo/wifi-0.svg"
                                                    ) : "root:/logo/wifi-0.svg"
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: true
                                                    opacity: Network.wifiEnabled ? 1.0 : 0.5
                                                
                                                    Behavior on source {
                                                        PropertyAnimation {
                                                        duration: Appearance.animation.elementMoveFast.duration
                                                        easing.type: Appearance.animation.elementMoveFast.type
                                                    }
                                                }
                                                }

                                                ColorOverlay {
                                                    anchors.fill: parent
                                                    source: wifiIcon
                                                    color: Appearance.colors.colOnLayer0
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onEntered: networkTooltip.show()
                                                    onExited: networkTooltip.hide()
                                                    onPositionChanged: (mouse) => {
                                                        var point = wifiIconRect.mapToItem(null, mouse.x, mouse.y)
                                                        networkTooltip.updatePosition(point.x, point.y)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    MaterialSymbol {
                                        text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer0
                                    }
                                }
                            }

                            ClockWidget {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: 2
                            }

                            Weather {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: 2
                                Layout.leftMargin: 2
                                Layout.minimumWidth: 100
                                weatherLocation: "Halifax, Nova Scotia, Canada"
                            }

                            SysTray {
                                bar: barRoot
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }

            // Round decorators
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: barContent.bottom
                height: 0

                RoundCorner {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    size: 0
                    corner: cornerEnum.topLeft
                    color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                }
                RoundCorner {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    size: 0
                    corner: cornerEnum.topRight
                    color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                }
            }

        }

    }

}
