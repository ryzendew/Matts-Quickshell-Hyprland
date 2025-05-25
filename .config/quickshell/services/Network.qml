pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import Quickshell.Services.Pipewire;
import QtQuick;

Singleton {
    id: root

    property int updateInterval: 500  // Reduced to 500ms for more responsive updates
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
        // Improved command to get signal strength only for the active connection
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi list | awk '/^\\*/{print $2}' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                // More robust parsing with bounds checking
                const strength = parseInt(data) || 0;
                root.networkStrength = Math.max(0, Math.min(100, strength));
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
                // If WiFi is disabled, ensure strength is 0
                if (!root.wifiEnabled) {
                    root.networkStrength = 0;
                }
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
                    // If we're on ethernet, ensure WiFi strength is 0
                    root.networkStrength = 0;
                } else {
                    root.networkType = "none"
                    root.networkStrength = 0;
                }
            }
        }
    }
}

