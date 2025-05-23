.pragma library

const substitutions = {
    "code-url-handler": "visual-studio-code",
    "Code": "visual-studio-code",
    "GitHub Desktop": "github-desktop",
    "Minecraft* 1.20.1": "minecraft",
    "gnome-tweaks": "org.gnome.tweaks",
    "pavucontrol-qt": "pavucontrol",
    "wps": "wps-office2019-kprometheus",
    "wpsoffice": "wps-office2019-kprometheus",
    "footclient": "foot",
    "zen": "zen-browser",
     "ptyxis": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/org.gnome.Ptyxis.svg",
      "AffinityPhoto.desktop": "/home/matt/.config/quickshell/assets/icons/AffinityPhoto.png",
      "steam-native": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/steam.svg",
      "lutris": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/lutris.svg",
      "com.blackmagicdesign.resolve.desktop": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/resolve.svg",
      "cider": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/cider.svg",
      "vesktop": "/home/matt/.local/share/icons/Tela-circle-dark/scalable/apps/vesktop.svg",
      "obs": "/home/matt/.config/quickshell/assets/icons/obs.svg",
      "heroic": "/home/matt/.config/quickshell/assets/icons/heroic.svg",
      "microsoft-edge-dev": "/home/matt/.config/quickshell/assets/icons/edge.svg",
      "org.gnome.Nautilus": "/home/matt/.config/quickshell/assets/icons/files.svg",
    "": "image-missing"
}
const regexSubstitutions = [
    {
        "regex": "/^steam_app_(\\d+)$/",
        "replace": "steam_icon_$1"
    }
]


function iconExists(iconName) {
    return false; // TODO: Make this work without Gtk
}

function substitute(str) {
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

    // Guess: convert to kebab case
    if (!iconExists(str)) str = str.toLowerCase().replace(/\s+/g, "-");

    // Original string
    return str;
}

function noKnowledgeIconGuess(str) {
    if (!str) return "image-missing";

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

    // Guess: convert to kebab case if it's not reverse domain name notation
    if (!str.includes('.')) {
        str = str.toLowerCase().replace(/\s+/g, "-");
    }

    // Original string
    return str;
}
