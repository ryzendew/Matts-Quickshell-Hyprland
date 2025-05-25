pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import Quickshell.Services.Pipewire;
import QtQuick;

Singleton {
    id: root

    property int updateInterval: 1000
    property string networkName: ""
    property int networkStrength: 0
    property bool wifiEnabled: false
    property string networkType: "none"  // "ethernet", "wifi", or "none"

    function update() {
        updateNetworkName.running = true
        updateNetworkStrength.running = true
        updateWifiState.running = true
        updateNetworkType.running = true
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            update()
            interval = root.updateInterval
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data || ""
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data) || 0;
            }
        }
    }

    Process {
        id: updateWifiState
        running: true
        command: ["sh", "-c", "nmcli radio wifi | grep -q enabled && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (parseInt(data) === 1);
            }
        }
    }

    Process {
        id: updateNetworkType
        running: true
        command: ["sh", "-c", "nmcli device | awk '$3==\"connected\" {print $2}' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                const type = data.trim().toLowerCase()
                if (type === "wifi") {
                    root.networkType = "wifi"
                } else if (type === "ethernet") {
                    root.networkType = "ethernet"
                } else {
                    root.networkType = "none"
                }
            }
        }
    }
}

