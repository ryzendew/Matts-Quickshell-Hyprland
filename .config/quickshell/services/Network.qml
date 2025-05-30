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

    // Network activity properties
    property real downloadSpeed: 0  // KB/s
    property real uploadSpeed: 0    // KB/s
    property bool hasActivity: false
    property bool isDownloading: false
    property bool isUploading: false
    
    // Internal properties for speed calculation
    property var previousStats: ({})
    property real lastUpdateTime: 0

    function update() {
        updateNetworkName.running = true
        updateNetworkStrength.running = true
        updateWifiState.running = true
        updateNetworkType.running = true
        updateNetworkActivity.running = true
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

    Process {
        id: updateNetworkActivity
        running: true
        command: ["sh", "-c", "cat /proc/net/dev | grep -E '(eth|enp|wlan|wlp)' | head -1 | awk '{print $2,$10}'"]
        stdout: SplitParser {
            onRead: data => {
                const currentTime = Date.now()
                const parts = data.trim().split(' ')
                
                if (parts.length >= 2) {
                    const rxBytes = parseInt(parts[0]) || 0
                    const txBytes = parseInt(parts[1]) || 0
                    
                    if (root.previousStats.rxBytes !== undefined && root.lastUpdateTime > 0) {
                        const timeDiff = (currentTime - root.lastUpdateTime) / 1000 // seconds
                        const rxDiff = rxBytes - root.previousStats.rxBytes
                        const txDiff = txBytes - root.previousStats.txBytes
                        
                        if (timeDiff > 0) {
                            root.downloadSpeed = Math.max(0, rxDiff / timeDiff / 1024) // KB/s
                            root.uploadSpeed = Math.max(0, txDiff / timeDiff / 1024)   // KB/s
                            
                            // Consider activity if speed > 1 KB/s
                            root.isDownloading = root.downloadSpeed > 1
                            root.isUploading = root.uploadSpeed > 1
                            root.hasActivity = root.isDownloading || root.isUploading
                        }
                    }
                    
                    root.previousStats = { rxBytes: rxBytes, txBytes: txBytes }
                    root.lastUpdateTime = currentTime
                }
            }
        }
    }
}

