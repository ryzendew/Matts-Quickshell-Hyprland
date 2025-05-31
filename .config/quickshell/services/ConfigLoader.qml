pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

Singleton {
    id: root
    property string fileDir: `${XdgDirectories.config}/illogical-impulse`
    property string fileName: "config.json"
    property string filePath: FileUtils.trimFileProtocol(`${root.fileDir}/${root.fileName}`)
    property bool firstLoad: true
    property bool isLoading: false
    property string lastError: ""

    // Helper function for controlled logging
    function log(level, message) {
        if (level === "debug" && !ConfigOptions.logging.debug) return
        if (level === "info" && !ConfigOptions.logging.info) return
        if (level === "warning" && !ConfigOptions.logging.warning) return
        if (level === "error" && !ConfigOptions.logging.error) return
        // console.log(`[ConfigLoader][${level.toUpperCase()}] ${message}`)
    }

    function loadConfig() {
        if (isLoading) {
            log("warning", "Config load already in progress")
            return
        }

        isLoading = true
        lastError = ""
        
        try {
            log("info", "Loading configuration from: " + filePath)
        configFileView.reload()
        } catch (e) {
            lastError = e.toString()
            log("error", "Failed to load config: " + lastError)
            isLoading = false
        }
    }

    function applyConfig(fileContent) {
        try {
            log("debug", "Parsing configuration JSON")
            const json = JSON.parse(fileContent)

            log("debug", "Applying configuration to Qt objects")
            ObjectUtils.applyToQtObject(ConfigOptions, json)
            
            if (root.firstLoad) {
                root.firstLoad = false
                log("info", "Initial configuration loaded successfully")
            } else {
                log("info", "Configuration reloaded successfully")
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration reloaded")}" "${root.filePath}"`)
            }
        } catch (e) {
            lastError = e.toString()
            log("error", "Error applying configuration: " + lastError)
            Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration failed to load")}" "${root.filePath}"`)
        } finally {
            isLoading = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
        repeat: false
        running: false
        onTriggered: {
            root.applyConfig(configFileView.text())
        }
    }

	FileView { 
        id: configFileView
        path: root.filePath
        onTextChanged: {
            if (text !== "") {
            delayedFileRead.start()
            }
        }
    }
}
