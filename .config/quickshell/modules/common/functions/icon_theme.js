var currentDetectedTheme = "Tela-circle";

function getCurrentIconTheme() {
    return currentDetectedTheme;
}

function setCurrentTheme(theme) {
    currentDetectedTheme = theme;
    // console.log("[ICON DEBUG] Theme set to:", theme);
}

function getCurrentTheme() {
    return currentDetectedTheme;
}

function getIconPath(iconName, homeDir) {
    if (!homeDir) {
        // console.error("[ICON DEBUG] homeDir not provided to getIconPath!");
        return "";
    }
    
    if (!iconName || iconName.trim() === "") {
        return "";
    }

    // Strip "file://" prefix if present
    if (homeDir && homeDir.startsWith("file://")) {
        homeDir = homeDir.substring(7);
    }

    if (!homeDir) {
        return ""; // Cannot proceed without homeDir
    }
    
    // Icon variations to try (most specific first)
    var iconVariations = [iconName];
    var appMappings = {
        "Cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "qt6ct": ["preferences-system", "system-preferences", "preferences-desktop"],
        "steam": ["steam-native", "steam-launcher", "steam-icon"],
        "steam-native": ["steam", "steam-launcher", "steam-icon"],
        "microsoft-edge-dev": ["microsoft-edge", "msedge", "edge", "web-browser"],
        "vesktop": ["discord", "com.discordapp.Discord"],
        "discord": ["vesktop", "com.discordapp.Discord"],
        "cider": ["apple-music", "music"],
        "org.gnome.Nautilus": ["nautilus", "file-manager", "system-file-manager"],
        "org.gnome.nautilus": ["nautilus", "file-manager", "system-file-manager"],
        "nautilus": ["org.gnome.Nautilus", "file-manager", "system-file-manager"],
        "obs": ["com.obsproject.Studio", "obs-studio"],
        "ptyxis": ["terminal", "org.gnome.Terminal"],
        "org.gnome.ptyxis": ["terminal", "org.gnome.Terminal"],
        "org.gnome.Ptyxis": ["terminal", "org.gnome.Terminal"]
    };
    
    if (appMappings[iconName]) {
        iconVariations = iconVariations.concat(appMappings[iconName]);
    }
    var lowerName = iconName.toLowerCase();
    if (lowerName !== iconName) {
        iconVariations.push(lowerName);
        if (appMappings[lowerName]) {
            iconVariations = iconVariations.concat(appMappings[lowerName]);
        }
    }
    
    var themes = ["Tela-circle", "Adwaita"];
    var iconBasePaths = [
        homeDir + "/.local/share/icons",
        homeDir + "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    var sizeDirs = ["scalable/apps", "48x48/apps", "64x64/apps", "apps/48", "128x128/apps"];
    var extensions = [".svg", ".png"];

    // Try Tela-circle first, then fall back to Adwaita
    for (var t = 0; t < themes.length; t++) {
        var theme = themes[t];
        for (var b = 0; b < iconBasePaths.length; b++) {
            var basePath = iconBasePaths[b];
            for (var v = 0; v < iconVariations.length; v++) {
                var iconVar = iconVariations[v];
                for (var s = 0; s < sizeDirs.length; s++) {
                    var sizeDir = sizeDirs[s];
                    for (var e = 0; e < extensions.length; e++) {
                        var ext = extensions[e];
                        var fullPath = basePath + "/" + theme + "/" + sizeDir + "/" + iconVar + ext;
                        if (Qt.fileExists(fullPath)) {
                            return fullPath;
                        }
                    }
                }
            }
        }
    }
    
    // If no icon found in either theme, return Adwaita's generic icon
    return "/usr/share/icons/Adwaita/48x48/apps/applications-other.png";
}

function refreshThemes() {
    // console.log("[ICON DEBUG] Theme refresh requested (currently no-op)");
} 