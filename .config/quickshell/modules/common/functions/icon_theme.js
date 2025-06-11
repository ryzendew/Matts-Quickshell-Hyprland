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
    
    // console.log("[ICON DEBUG] Getting icon for:", iconName, "with homeDir:", homeDir);
    
    if (!iconName || iconName.trim() === "") {
        return "";
    }

    // Strip "file://" prefix if present
    if (homeDir && homeDir.startsWith("file://")) {
        homeDir = homeDir.substring(7);
    }

    if (!homeDir) {
        // console.error("[ICON DEBUG] homeDir not provided to getIconPath!");
        return ""; // Cannot proceed without homeDir
    }
    
    // console.log("[ICON DEBUG] Getting icon for:", iconName, "with homeDir:", homeDir);
    
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
    
    var themes = [
        "Tela-circle", "Tela-circle-blue", "Tela-circle-grey", "Tela-circle-manjaro",
        "Tela-circle-nord", "Tela-circle-black", "breeze-plus", "breeze-plus-dark", "breeze", "breeze-dark", "hicolor", "Adwaita"
    ];
    var iconBasePaths = [
        "/usr/share/icons",
        "/.local/share/icons",
        "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    var sizeDirs = ["scalable/apps", "48x48/apps", "64x64/apps", "apps/48", "128x128/apps"];
    var extensions = [".svg", ".png"];

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
                        // Let QML handle file existence check via Image.status
                        // console.log("[ICON DEBUG] Returning candidate path:", fullPath);
                        return fullPath; // Return raw path
                    }
                }
            }
        }
    }
    
    // console.log("[ICON DEBUG] No specific icon found for:", iconName, ", trying generic fallback.");
    return "/usr/share/icons/breeze/apps/48/applications-other.svg"; // Generic fallback raw path
}

function refreshThemes() {
    // console.log("[ICON DEBUG] Theme refresh requested (currently no-op)");
} 
