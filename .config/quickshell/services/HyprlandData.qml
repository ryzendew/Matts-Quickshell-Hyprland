pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    function updateWindowList() {
        getClients.running = true
        getMonitors.running = true
    }

    Component.onCompleted: {
        updateWindowList()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            console.log("[HYPRLAND DEBUG] Received event:", event.name)
            // Only filter out specific events that don't affect window list
            if(event.name in [
                "focusedmon", "monitoradded", 
                "createworkspace", "destroyworkspace", "moveworkspace", 
                "activespecial"
            ]) {
                console.log("[HYPRLAND DEBUG] Filtered out event:", event.name)
                return;
            }
            console.log("[HYPRLAND DEBUG] Updating window list due to event:", event.name)
            updateWindowList()
        }
    }

    Process {
        id: getClients
        command: ["bash", "-c", "hyprctl clients -j | jq -c"]
        stdout: SplitParser {
            onRead: (data) => {
                console.log("[HYPRLAND DEBUG] Received window list update")
                root.windowList = JSON.parse(data)
                console.log("[HYPRLAND DEBUG] Window list updated:", JSON.stringify(root.windowList.map(w => w.class)))
                let tempWinByAddress = {}
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i]
                    tempWinByAddress[win.address] = win
                }
                root.windowByAddress = tempWinByAddress
                root.addresses = root.windowList.map((win) => win.address)
            }
        }
    }
    Process {
        id: getMonitors
        command: ["bash", "-c", "hyprctl monitors -j | jq -c"]
        stdout: SplitParser {
            onRead: (data) => {
                root.monitors = JSON.parse(data)
            }
        }
    }
}

