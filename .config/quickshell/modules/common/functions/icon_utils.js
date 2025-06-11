function resolveIconPath(icon) {
    if (!icon) return "";
    
    // Define the Tela icon theme path
    const telaIconPath = "$HOME/.local/share/icons/Tela-circle-dark/scalable@2x/apps";
    
    // Icon name mappings
    const iconMappings = {
        'edge.svg': 'microsoft-edge.svg',
        'files.svg': 'org.gnome.Files.svg'
    };
    
    if (icon.includes("?path=")) {
        const [name, path] = icon.split("?path=");
        const fileName = name.substring(name.lastIndexOf("/") + 1);
        
        // First try the specified path
        const specifiedPath = `file://${path}/${fileName}`;
        
        // If the file is an icon request, also check the Tela theme directory
        if (path.includes("icons")) {
            // Use mapped icon name if available
            const mappedName = iconMappings[fileName] || fileName;
            const telaPath = `file://${telaIconPath}/${mappedName}`;
            return telaPath;
        }
        
        return specifiedPath;
    }
    
    // For direct icon names, check in Tela theme
    if (icon.startsWith("/")) {
        const fileName = icon.substring(icon.lastIndexOf("/") + 1);
        const mappedName = iconMappings[fileName] || fileName;
        return `file://${telaIconPath}/${mappedName}`;
    }
    
    // For bare icon names, use mapping if available
    const mappedName = iconMappings[icon] || icon;
    return `file://${telaIconPath}/${mappedName}`;
} 