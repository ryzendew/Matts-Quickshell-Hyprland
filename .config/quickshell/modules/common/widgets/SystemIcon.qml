import QtQuick 2.15
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    property string iconName: ""
    property real iconSize: 24
    property color iconColor: "transparent"
    property string fallbackIcon: "application-x-executable"
    
    width: iconSize
    height: iconSize
    
    // Simple icon mapping for common cases
    property var iconMappings: {
        // Media and Entertainment
        "cider": "cider",
        "Cider": "cider",
        "spotify": "spotify",
        "obs": "com.obsproject.Studio",
        "vlc": "vlc",
        "mpv": "mpv",
        
        // Development
        "code": "visual-studio-code",
        "cursor": "cursor",
        "Cursor": "cursor",
        
        // Browsers
        "firefox": "firefox",
        "google-chrome": "google-chrome",
        "chromium": "chromium",
        
        // Communication
        "discord": "discord",
        "Discord": "discord",
        "vesktop": "discord",
        
        // System and Utilities
        "org.gnome.Nautilus": "folder",
        "nautilus": "folder",
        "org.gnome.Ptyxis": "terminal",
        "ptyxis": "terminal",
        "photo.exe": "affinity-photo"
    }
    
    // Get the best icon name to use
    function getBestIconName() {
        if (!iconName) return fallbackIcon
        
        var name = iconName.toString().trim()
        if (!name) return fallbackIcon
        
        // Try user mapping first
        if (iconMappings[name]) {
            return iconMappings[name]
        }
        
        // Clean the name (remove .desktop, .exe extensions)
        var cleanName = name.replace(/\.desktop$/, "").replace(/\.exe$/, "")
        
        // Try variations
        var variations = [
            cleanName,
            cleanName.toLowerCase(),
            cleanName.charAt(0).toUpperCase() + cleanName.slice(1).toLowerCase()
        ]
        
        // For org.* names, try just the last part
        if (name.startsWith("org.")) {
            var parts = name.split(".")
            if (parts.length > 2) {
                var lastPart = parts[parts.length - 1]
                variations.push(lastPart)
                variations.push(lastPart.toLowerCase())
            }
        }
        
        // Return the first variation that works, or fallback
        for (var i = 0; i < variations.length; i++) {
            try {
                var testPath = Quickshell.iconPath(variations[i], "")
                if (testPath !== "") {
                    return variations[i]
                }
            } catch (e) {
                // Continue to next variation
            }
        }
        
        return fallbackIcon
    }
    
    // Main icon display
    IconImage {
        id: mainIcon
        anchors.fill: parent
        source: {
            var iconName = getBestIconName()
            return Quickshell.iconPath(iconName, fallbackIcon)
        }
        smooth: true
        
        onStatusChanged: {
            if (status === Image.Error) {
                // Final fallback
                source = Quickshell.iconPath(fallbackIcon, "")
            }
        }
    }
    
    // Color overlay if specified
    ColorOverlay {
        visible: root.iconColor != "transparent" && root.iconColor != ""
        anchors.fill: parent
        source: mainIcon
        color: root.iconColor
    }
} 