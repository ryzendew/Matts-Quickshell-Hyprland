pragma Singleton

import "root:/modules/common"
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/levendist.js" as Levendist
import Quickshell
import Quickshell.Io

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: ConfigOptions?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
    })
    property var regexSubstitutions: [
        {
            "regex": "/^steam_app_(\\d+)$/",
            "replace": "steam_icon_$1"
        },
        {
            "regex": "/Minecraft.*$/",
            "replace": "minecraft"
        }
    ]

    // Cache properties
    property var searchCache: ({})
    property int cacheSize: 100
    property var cacheKeys: []

    // Force refresh trigger
    property int refreshTrigger: 0

    // Helper function for controlled logging
    function log(level, message) {
        if (!ConfigOptions.logging.enabled) return
        if (level === "debug" && !ConfigOptions.logging.debug) return
        if (level === "info" && !ConfigOptions.logging.info) return
        if (level === "warning" && !ConfigOptions.logging.warning) return
        if (level === "error" && !ConfigOptions.logging.error) return
        console.log(`[AppSearch][${level.toUpperCase()}] ${message}`)
    }

    // Cache management functions
    function addToCache(key, value) {
        if (cacheKeys.length >= cacheSize) {
            const oldestKey = cacheKeys.shift()
            delete searchCache[oldestKey]
        }
        searchCache[key] = value
        cacheKeys.push(key)
    }

    function getFromCache(key) {
        return searchCache[key]
    }

    readonly property list<DesktopEntry> list: {
        refreshTrigger;
        return Array.from(DesktopEntries.applications.values)
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property var preppedNames: {
        refreshTrigger;
        return list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
                }));
    }

    // Add a signal for when the app list is refreshed
    signal appListRefreshed()

    // Function to refresh the desktop entries and notify components
    function refresh() {
        log("info", "Refreshing application list...")
        
        // Clear search cache on refresh
        searchCache = {}
        cacheKeys = []
        
        // Execute xdg-desktop-menu forceupdate to refresh the desktop database
        const process = Qt.createQmlObject('
            import Quickshell.Io
            Process {
                command: ["xdg-desktop-menu", "forceupdate"]
                running: true
                onFinished: {
                    root.refreshTrigger++
                    root.appListRefreshed()
                    destroy()
                }
            }
        ', root)
    }

    // Optimized search function with caching
    function search(query) {
        if (!query) return []
        
        // Check cache first
        const cachedResult = getFromCache(query)
        if (cachedResult) {
            log("debug", "Cache hit for query: " + query)
            return cachedResult
        }

        log("debug", "Cache miss for query: " + query)
        const results = Fuzzy.go(query, preppedNames, {
            keys: ["name"],
            threshold: scoreThreshold,
            limit: 50
        }).map(result => result.obj.entry)

        // Cache the results
        addToCache(query, results)
        return results
    }

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Normal substitutions
        if (substitutions[str])
            return substitutions[str];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // If it gets detected normally, no need to guess
        if (iconExists(str)) return str;

        let guessStr = str;
        // Guess: Take only app name of reverse domain name notation
        guessStr = str.split('.').slice(-1)[0].toLowerCase();
        if (iconExists(guessStr)) return guessStr;
        // Guess: normalize to kebab case
        guessStr = str.toLowerCase().replace(/\s+/g, "-");
        if (iconExists(guessStr)) return guessStr;
        // Guess: First fuzze desktop entry match
        const searchResults = root.fuzzyQuery(str);
        if (searchResults.length > 0) {
            const firstEntry = searchResults[0];
            guessStr = firstEntry.icon
            if (iconExists(guessStr)) return guessStr;
        }

        // Give up
        return str;
    }
}
