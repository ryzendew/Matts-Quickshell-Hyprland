import QtQuick
pragma Singleton

QtObject {
    // HyprMenu position configuration
    // Available options:
    // - "top-left": Top left corner
    // - "top-center": Top center (below bar)
    // - "top-right": Top right corner
    // - "center": Center of screen
    // - "bottom-left": Bottom left corner
    // - "bottom-center": Bottom center (above dock) - DEFAULT
    // - "bottom-right": Bottom right corner
    
    readonly property string position: "bottom-center"
} 