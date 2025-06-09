import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isScanning: false
    property bool hasError: false
    property bool isActive: false
    property string errorMessage: ""
    property bool isConnecting: false
    property bool settingsExpanded: false
    property bool visibilityEnabled: false

    function toggleBluetooth() {
        const cmd = Bluetooth.bluetoothEnabled ? "bluetoothctl power off" : "bluetoothctl power on"
        Process.launch(cmd)
    }

    function toggleVisibility() {
        const cmd = visibilityEnabled ? "bluetoothctl discoverable off" : "bluetoothctl discoverable on"
        Process.launch(cmd)
    }

    // Initialize the ListModel for Bluetooth devices
    ListModel {
        id: devicesModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: true

        // Error Message Display
        PanelWindow {
            Layout.fillWidth: true
            visible: hasError
            height: visible ? errorText.implicitHeight + 20 : 0

            StyledText {
                id: errorText
                anchors.fill: parent
                anchors.margins: 10
                text: errorMessage
                color: Appearance.colors.colError
                wrapMode: Text.WordWrap
            }
        }

        // Bluetooth Toggle Section
        PanelWindow {
            Layout.fillWidth: true
            Layout.preferredHeight: btToggleLayout.implicitHeight + 20

            RowLayout {
                id: btToggleLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                MaterialSymbol {
                    text: "bluetooth"
                    iconSize: Appearance.font.pixelSize.huge
                    color: "#FFFFFF"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: qsTr("Bluetooth")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: bluetoothEnabled ? 
                            qsTr("Bluetooth is enabled") : 
                            qsTr("Bluetooth is disabled")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Switch {
                    checked: bluetoothEnabled
                    onClicked: toggleBluetooth()
                    
                    // Add proper styling
                    indicator: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 20
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 10
                        color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                        border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                        Rectangle {
                            x: parent.parent.checked ? parent.width - width - 4 : 4
                            y: 4
                            width: 12
                            height: 12
                            radius: 6
                            color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive

                            Behavior on x {
                                NumberAnimation {
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bluetooth Settings Section
        PanelWindow {
            Layout.fillWidth: true
            visible: bluetoothEnabled
            height: settingsColumn.implicitHeight + 20

            ColumnLayout {
                id: settingsColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: settingsExpanded ? "expand_more" : "chevron_right"
                        iconSize: Appearance.font.pixelSize.normal
                        color: "#FFFFFF"
                    }

                    StyledText {
                        text: qsTr("Bluetooth Settings")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: settingsExpanded = !settingsExpanded
                    }
                }

                // Settings content
                ColumnLayout {
                    visible: settingsExpanded
                    Layout.fillWidth: true
                    spacing: 8

                    // Device visibility
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: qsTr("Device visibility")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        Switch {
                            checked: visibilityEnabled
                            onClicked: toggleVisibility()
                            
                            indicator: Rectangle {
                                implicitWidth: 36
                                implicitHeight: 18
                                radius: 9
                                color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                                border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                                Rectangle {
                                    x: parent.parent.checked ? parent.width - width - 3 : 3
                                    y: 3
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive
                                }
                            }
                        }
                    }

                    // Device name
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: qsTr("Device name")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }

                        TextField {
                            id: deviceNameField
                            Layout.fillWidth: true
                            text: deviceName
                            placeholderText: qsTr("Enter device name")
                            color: Appearance.colors.colOnLayer1
                            
                            background: Rectangle {
                                color: Appearance.colors.colLayer2
                                radius: Appearance.rounding.small
                            }
                        }

                        Button {
                            text: qsTr("Save")
                            enabled: deviceNameField.text !== deviceName
                            
                            background: Rectangle {
                                implicitWidth: 60
                                implicitHeight: 30
                                color: !parent.enabled ? Appearance.colors.colLayer2Inactive :
                                       parent.down ? Appearance.colors.colAccentActive :
                                       parent.hovered ? Appearance.colors.colAccentHover :
                                       Appearance.colors.colAccent
                                radius: Appearance.rounding.small
                                opacity: parent.enabled ? 1.0 : 0.5
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: setDeviceName(deviceNameField.text)
                        }
                    }

                    // Auto-connect option
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: qsTr("Auto-connect to paired devices")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        Switch {
                            checked: autoConnectEnabled
                            onClicked: toggleAutoConnect()
                            
                            indicator: Rectangle {
                                implicitWidth: 36
                                implicitHeight: 18
                                radius: 9
                                color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                                border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                                Rectangle {
                                    x: parent.parent.checked ? parent.width - width - 3 : 3
                                    y: 3
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive
                                }
                            }
                        }
                    }

                    // Manage paired devices button
                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Manage Paired Devices")
                        
                        background: Rectangle {
                            implicitHeight: 36
                            color: parent.down ? Appearance.colors.colLayer2Active :
                                   parent.hovered ? Appearance.colors.colLayer2Hover :
                                   Appearance.colors.colLayer2
                            radius: Appearance.rounding.small
                            border.color: Appearance.colors.colOnLayer1Inactive
                            border.width: 1
                        }
                        
                        contentItem: RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "settings"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }
                            Text {
                                text: parent.parent.text
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                        }
                        
                        onClicked: showPairedDevicesDialog()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: settingsExpanded = !settingsExpanded
            }
        }

        // Available Devices Section
        PanelWindow {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: bluetoothEnabled

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    StyledText {
                        text: qsTr("Available Devices")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    BusyIndicator {
                        running: isScanning || isConnecting
                        visible: isScanning || isConnecting
                        width: Appearance.font.pixelSize.normal
                        height: width
                    }

                    MaterialSymbol {
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: "#FFFFFF"
                        visible: !isScanning && !isConnecting
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rescanDevices()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5
                    clip: true
                    model: devicesModel

                    // Add placeholder text when no devices
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("No devices found")
                        color: Appearance.colors.colSubtext
                        visible: devicesModel.count === 0
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: deviceItemLayout.implicitHeight + 20
                        hoverEnabled: true

                        Rectangle {
                            anchors.fill: parent
                            color: parent.hovered ? Appearance.colors.colLayer2 : "transparent"
                            radius: Appearance.rounding.small
                        }

                        RowLayout {
                            id: deviceItemLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            MaterialSymbol {
                                text: getDeviceIcon(model.type)
                                iconSize: Appearance.font.pixelSize.larger
                                color: model.connected ? "#FFFFFF" : "#FFFFFF"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: model.name
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: model.connected ? "#FFFFFF" : "#FFFFFF"
                                }

                                RowLayout {
                                    spacing: 5
                                    visible: model.connected || model.paired

                                    MaterialSymbol {
                                        text: "check_circle"
                                        visible: model.connected
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colAccent
                                    }

                                    StyledText {
                                        text: model.connected ? qsTr("Connected") : 
                                              model.paired ? qsTr("Paired") : ""
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: model.connected ? "#FFFFFF" : "#FFFFFF"
                                        visible: text !== ""
                                    }

                                    StyledText {
                                        text: qsTr("Signal: %1%").arg(model.rssi)
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                        visible: model.rssi !== undefined
                                    }
                                }
                            }

                            MaterialSymbol {
                                text: model.connected ? "more_vert" : "login"
                                iconSize: Appearance.font.pixelSize.normal
                                color: "#FFFFFF"
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.connected) {
                                            // Show device options menu
                                            deviceMenu.device = model
                                            deviceMenu.popup()
                                        } else if (model.paired) {
                                            connectDevice(model.mac)
                                        } else {
                                            pairDevice(model.mac)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property bool bluetoothEnabled: false
    property bool settingsExpanded: false
    property bool visibilityEnabled: false
    property bool autoConnectEnabled: false
    property string deviceName: ""

    function getDeviceIcon(type) {
        switch(type) {
            case "audio-headset": return "headphones"
            case "audio-speaker": return "speaker"
            case "input-keyboard": return "keyboard"
            case "input-mouse": return "mouse"
            case "input-gaming": return "sports_esports"
            case "phone": return "smartphone"
            default: return "bluetooth"
        }
    }

    function toggleBluetooth() {
        const cmd = "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                checkBluetoothState()
                if (bluetoothEnabled) {
                    rescanDevices()
                }
            } else {
                showError("Failed to toggle Bluetooth")
            }
        })
    }

    function checkBluetoothState() {
        const cmd = "bluetoothctl show | grep 'Powered: yes'"
        Io.shellCommand(cmd, (exitCode) => {
            bluetoothEnabled = (exitCode === 0)
        })
    }

    function rescanDevices() {
        if (!bluetoothEnabled) return

        isScanning = true
        const cmd = "bluetoothctl scan on"
        Io.shellCommand(cmd, () => {
            // Scan for 5 seconds then update device list
            Timer.setTimeout(() => {
                Io.shellCommand("bluetoothctl scan off", () => {
                    updateDeviceList()
                    isScanning = false
                })
            }, 5000)
        })
    }

    function updateDeviceList() {
        const cmd = "bluetoothctl devices"
        Io.shellCommand(cmd, (exitCode, stdout) => {
            if (exitCode === 0) {
                devicesModel.clear()
                const devices = stdout.split("\n")
                devices.forEach(line => {
                    if (line) {
                        const match = line.match(/Device\s+([0-9A-F:]+)\s+(.+)/)
                        if (match) {
                            const mac = match[1]
                            const name = match[2]
                            getDeviceInfo(mac, name)
                        }
                    }
                })
            } else {
                showError("Failed to get device list")
            }
        })
    }

    function getDeviceInfo(mac, name) {
        const cmd = `bluetoothctl info ${mac}`
        Io.shellCommand(cmd, (exitCode, stdout) => {
            if (exitCode === 0) {
                const connected = stdout.includes("Connected: yes")
                const paired = stdout.includes("Paired: yes")
                const type = getDeviceType(stdout)
                devicesModel.append({
                    mac: mac,
                    name: name,
                    connected: connected,
                    paired: paired,
                    type: type
                })
            }
        })
    }

    function getDeviceType(info) {
        if (info.includes("Icon: audio-headset")) return "audio-headset"
        if (info.includes("Icon: audio-speaker")) return "audio-speaker"
        if (info.includes("Icon: input-keyboard")) return "input-keyboard"
        if (info.includes("Icon: input-mouse")) return "input-mouse"
        if (info.includes("Icon: input-gaming")) return "input-gaming"
        if (info.includes("Icon: phone")) return "phone"
        return "unknown"
    }

    function connectDevice(mac) {
        isConnecting = true
        const cmd = `bluetoothctl connect ${mac}`
        Io.shellCommand(cmd, (exitCode) => {
            isConnecting = false
            if (exitCode === 0) {
                updateDeviceList()
            } else {
                showError("Failed to connect device")
            }
        })
    }

    function disconnectDevice(mac) {
        const cmd = `bluetoothctl disconnect ${mac}`
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                updateDeviceList()
            } else {
                showError("Failed to disconnect device")
            }
        })
    }

    function pairDevice(mac) {
        isConnecting = true
        const cmd = `bluetoothctl pair ${mac}`
        Io.shellCommand(cmd, (exitCode) => {
            isConnecting = false
            if (exitCode === 0) {
                connectDevice(mac)
            } else {
                showError("Failed to pair device")
            }
        })
    }

    function showError(message) {
        errorMessage = message
        hasError = true
        errorTimer.restart()
    }

    Timer {
        id: errorTimer
        interval: 3000
        onTriggered: {
            hasError = false
            errorMessage = ""
        }
    }

    Timer {
        interval: 10000
        running: isActive && bluetoothEnabled
        repeat: true
        onTriggered: updateDeviceList()
    }

    function toggleVisibility() {
        const cmd = visibilityEnabled ?
            "bluetoothctl discoverable off" :
            "bluetoothctl discoverable on"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                visibilityEnabled = !visibilityEnabled
            } else {
                showError("Failed to toggle visibility")
            }
        })
    }

    function toggleAutoConnect() {
        const cmd = autoConnectEnabled ?
            "bluetoothctl set auto-connect false" :
            "bluetoothctl set auto-connect true"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                autoConnectEnabled = !autoConnectEnabled
            } else {
                showError("Failed to toggle auto-connect")
            }
        })
    }

    function setDeviceName(name) {
        const cmd = `bluetoothctl set alias "${name}"`
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                deviceName = name
            } else {
                showError("Failed to set device name")
            }
        })
    }

    function showPairedDevicesDialog() {
        // Placeholder for future implementation
        // console.log("Paired devices dialog not implemented yet")
    }

    function loadBluetoothSettings() {
        // Get device name
        Io.shellCommand("bluetoothctl show | grep 'Alias:'", (exitCode, stdout) => {
            if (exitCode === 0) {
                const match = stdout.match(/Alias: (.+)/)
                if (match) {
                    deviceName = match[1]
                }
            }
        })

        // Check visibility
        Io.shellCommand("bluetoothctl show | grep 'Discoverable:'", (exitCode, stdout) => {
            visibilityEnabled = stdout.includes("yes")
        })

        // Check auto-connect
        Io.shellCommand("bluetoothctl show | grep 'AutoConnect:'", (exitCode, stdout) => {
            autoConnectEnabled = stdout.includes("yes")
        })
    }

    Component.onCompleted: {
        checkBluetoothState()
        loadBluetoothSettings()
        if (isActive && bluetoothEnabled) {
            updateDeviceList()
        }
    }

    onIsActiveChanged: {
        if (isActive) {
            checkBluetoothState()
            if (bluetoothEnabled) {
                updateDeviceList()
            }
        }
    }

    // Device options menu
    Menu {
        id: deviceMenu
        property var device

        background: Rectangle {
            implicitWidth: 200
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.small
            border.color: Appearance.colors.colOnLayer1Inactive
            border.width: 1
        }

        MenuItem {
            text: qsTr("Disconnect")
            icon.source: "disconnect"  // Using material symbol
            onTriggered: {
                if (deviceMenu.device) {
                    disconnectDevice(deviceMenu.device.mac)
                }
            }

            background: Rectangle {
                implicitHeight: 40
                color: parent.highlighted ? Appearance.colors.colLayer2Hover : "transparent"
                radius: Appearance.rounding.small
            }

            contentItem: RowLayout {
                spacing: 8
                MaterialSymbol {
                    text: "link_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                Text {
                    text: parent.parent.text
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }
        }

        MenuItem {
            text: qsTr("Forget")
            onTriggered: {
                if (deviceMenu.device) {
                    forgetDevice(deviceMenu.device.mac)
                }
            }

            background: Rectangle {
                implicitHeight: 40
                color: parent.highlighted ? Appearance.colors.colLayer2Hover : "transparent"
                radius: Appearance.rounding.small
            }

            contentItem: RowLayout {
                spacing: 8
                MaterialSymbol {
                    text: "delete"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colError
                }
                Text {
                    text: parent.parent.text
                    color: Appearance.colors.colError
                    Layout.fillWidth: true
                }
            }
        }
    }

    function forgetDevice(mac) {
        const cmd = `bluetoothctl remove ${mac}`
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                updateDeviceList()
            } else {
                showError("Failed to forget device")
            }
        })
    }
} 