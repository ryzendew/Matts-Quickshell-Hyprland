import "../"
import QtQuick
import Quickshell
import Quickshell.Io
import "root:/modules/common"
import "root:/modules/common/widgets"

QuickToggleButton {
    id: idleInhibitorButton
    property bool isInhibiting: false
    
    toggled: isInhibiting
    buttonIcon: isInhibiting ? "bedtime" : "coffee"
    
    onClicked: {
        if (isInhibiting) {
            // Re-enable sleep by starting hypridle
            startHypridle.startDetached()
            isInhibiting = false
            // console.log("Sleep/idle enabled")
        } else {
            // Disable sleep by killing hypridle
            killHypridle.startDetached()
            isInhibiting = true
            // console.log("Sleep/idle disabled")
        }
    }
    
    // Process to kill hypridle (disable sleep)
    Process {
        id: killHypridle
        command: ["pkill", "hypridle"]
    }
    
    // Process to start hypridle (enable sleep)
    Process {
        id: startHypridle
        command: ["hypridle"]
    }
    
    // Check hypridle status on startup
    Process {
        id: checkHypridleStatus
        running: true
        command: ["pgrep", "hypridle"]
        
        stdout: SplitParser {
            onRead: (data) => {
                // If hypridle is running, we're not inhibiting sleep
                // If no output, hypridle is not running, so we are inhibiting
                idleInhibitorButton.isInhibiting = data.trim() === ""
            }
        }
        
        onRunningChanged: {
            if (!running) {
                // Re-check status every 5 seconds
                statusTimer.start()
            }
        }
    }
    
    // Timer to periodically check hypridle status
    Timer {
        id: statusTimer
        interval: 5000 // 5 seconds
        repeat: false
        onTriggered: {
            checkHypridleStatus.running = true
        }
    }

    StyledToolTip {
        content: isInhibiting ? qsTr("Sleep disabled - Click to enable") : qsTr("Sleep enabled - Click to disable")
    }
}