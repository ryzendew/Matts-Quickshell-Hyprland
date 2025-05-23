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
    property string networkType: ""  // "ethernet", "wifi", or "none"

    function update() {
        updateNetworkName.running = true
        updateNetworkStrength.running = true
        updateWifiState.running = true
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
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    let parts = data.split(":");
                    root.networkName = parts[0] || "";
                    root.networkType = parts[1] || "";
                } else {
                    root.networkName = "";
                    root.networkType = "none";
                }
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
}

