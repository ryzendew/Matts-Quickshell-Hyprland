import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    color: "transparent"
    radius: Appearance.rounding.normal

    property bool internal: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // WiFi Toggle Section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: wifiToggleLayout.implicitHeight + 20
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            RowLayout {
                id: wifiToggleLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                MaterialSymbol {
                    text: Network.wifiEnabled ? (
                        Network.networkStrength >= 90 ? "signal_wifi_6_bar" :
                        Network.networkStrength >= 80 ? "signal_wifi_5_bar" :
                        Network.networkStrength >= 65 ? "signal_wifi_4_bar" :
                        Network.networkStrength >= 45 ? "signal_wifi_3_bar" :
                        Network.networkStrength >= 25 ? "signal_wifi_2_bar" :
                        Network.networkStrength >= 10 ? "signal_wifi_1_bar" :
                        "signal_wifi_0_bar"
                    ) : "signal_wifi_off"
                    iconSize: Appearance.font.pixelSize.huge
                    color: "#FFFFFF"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: qsTr("WiFi")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Network.wifiEnabled ? 
                            (Network.networkName || qsTr("Not connected")) : 
                            qsTr("WiFi is turned off")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Switch {
                    checked: Network.wifiEnabled
                    onClicked: {
                        toggleNetwork.running = true
                    }
                }
            }
        }

        // Available Networks Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal
            visible: Network.wifiEnabled

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                StyledText {
                    text: qsTr("Available Networks")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5
                    clip: true

                    model: ListModel {
                        id: networksModel
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: networkItemLayout.implicitHeight + 20

                        RowLayout {
                            id: networkItemLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            MaterialSymbol {
                                text: model.strength > 80 ? "signal_wifi_4_bar" :
                                      model.strength > 60 ? "network_wifi_3_bar" :
                                      model.strength > 40 ? "network_wifi_2_bar" :
                                      model.strength > 20 ? "network_wifi_1_bar" :
                                      "signal_wifi_0_bar"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: model.ssid
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                }

                                StyledText {
                                    text: model.connected ? qsTr("Connected") : 
                                          model.saved ? qsTr("Saved") : ""
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    visible: text !== ""
                                }
                            }

                            MaterialSymbol {
                                text: "lock"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                visible: model.secured
                            }
                        }

                        onClicked: {
                            if (!model.connected) {
                                if (model.saved) {
                                    connectSavedNetwork.command = ["nmcli", "connection", "up", "id", model.ssid]
                                    connectSavedNetwork.running = true
                                } else {
                                    // Launch network settings for new connection
                                    Hyprland.dispatch(`exec ${ConfigOptions.apps.network}`)
                                }
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Open Network Settings")
                    onClicked: {
                        Hyprland.dispatch(`exec ${ConfigOptions.apps.network}`)
                    }
                }
            }
        }
    }

    // Network toggle process
    Process {
        id: toggleNetwork
        command: ["bash", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]
        onRunningChanged: {
            if(!running) {
                Network.update()
                updateNetworks.running = true
            }
        }
    }

    // Connect to saved network process
    Process {
        id: connectSavedNetwork
        onRunningChanged: {
            if(!running) {
                Network.update()
                updateNetworks.running = true
            }
        }
    }

    // Update available networks
    Process {
        id: updateNetworks
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        running: true
        interval: 10000
        stdout: SplitParser {
            onRead: (data) => {
                networksModel.clear()
                data.split("\\n").forEach(line => {
                    if (line) {
                        const [ssid, signal, security, inUse] = line.split(":")
                        if (ssid) {
                            networksModel.append({
                                ssid: ssid,
                                strength: parseInt(signal),
                                secured: security !== "",
                                connected: inUse === "*",
                                saved: false  // Will be updated by saved networks check
                            })
                        }
                    }
                })
                updateSavedNetworks.running = true
            }
        }
    }

    // Check saved networks
    Process {
        id: updateSavedNetworks
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: SplitParser {
            onRead: (data) => {
                const savedNetworks = data.split("\\n")
                for (let i = 0; i < networksModel.count; i++) {
                    const network = networksModel.get(i)
                    network.saved = savedNetworks.includes(network.ssid)
                    networksModel.set(i, network)
                }
            }
        }
    }

    Component.onCompleted: {
        updateNetworks.running = true
    }
} 