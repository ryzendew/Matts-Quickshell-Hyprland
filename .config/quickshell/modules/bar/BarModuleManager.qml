import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "root:/modules/common"

QtObject {
    id: moduleManager
    
    // --- Properties ---
    property var leftModuleOrder: ConfigOptions.bar.modules.defaultLeftOrder.slice()
    property var rightModuleOrder: ConfigOptions.bar.modules.defaultRightOrder.slice()
    property var centerModuleOrder: ConfigOptions.bar.modules.defaultCenterOrder.slice()
    
    // Module component definitions
    property var moduleComponents: ({
        "arch_logo": "modules/ArchLogoModule.qml",
        "indicators": "modules/IndicatorsModule.qml", 
        "workspaces": "modules/WorkspacesModule.qml",
        "clock": "modules/ClockModule.qml",
        "weather": "modules/WeatherModule.qml",
        "systray": "modules/SysTrayModule.qml"
    })
    
    // Optional persistence settings
    property bool enablePersistence: true
    property string configPath: "file://$HOME/.config/quickshell/bar-modules-order.json"
    
    // File for persistence (optional)
    property FileView configFile: enablePersistence ? persistenceFile : null
    
    property Component persistenceFile: Component {
        FileView {
            path: configPath
        }
    }
    
    // --- Signals ---
    signal moduleOrderChanged(string section)
    
    // --- Functions ---
    function getModuleComponent(moduleId) {
        return moduleComponents[moduleId] || null
    }
    
    function getModuleOrder(section) {
        switch (section) {
            case "left": return leftModuleOrder
            case "right": return rightModuleOrder
            case "center": return centerModuleOrder
            default: return []
        }
    }
    
    function setModuleOrder(section, newOrder) {
        console.log("Setting module order for", section, ":", JSON.stringify(newOrder))
        
        switch (section) {
            case "left":
                leftModuleOrder = newOrder.slice()
                break
            case "right":
                rightModuleOrder = newOrder.slice()
                break
            case "center":
                centerModuleOrder = newOrder.slice()
                break
        }
        
        // Save to file only if persistence is enabled
        if (enablePersistence) {
            saveModuleOrder()
        }
        moduleOrderChanged(section)
    }
    
    function moveModule(section, fromIndex, toIndex) {
        console.log("Moving module in", section, "from", fromIndex, "to", toIndex)
        
        var order = getModuleOrder(section)
        if (fromIndex < 0 || toIndex < 0 || fromIndex >= order.length || toIndex >= order.length) {
            console.log("Invalid indices for move operation")
            return false
        }
        
        var newOrder = order.slice()
        var item = newOrder.splice(fromIndex, 1)[0]
        newOrder.splice(toIndex, 0, item)
        
        setModuleOrder(section, newOrder)
        return true
    }
    
    function saveModuleOrder() {
        if (!enablePersistence || !configFile) {
            console.log("Persistence disabled, skipping save")
            return
        }
        
        var config = {
            left: leftModuleOrder,
            right: rightModuleOrder,
            center: centerModuleOrder,
            version: 1,
            timestamp: Date.now()
        }
        
        console.log("Saving module order:", JSON.stringify(config))
        
        try {
            configFile.text = JSON.stringify(config, null, 2)
            console.log("Successfully saved module order to file")
        } catch (error) {
            console.log("Failed to save module order (this is okay):", error)
        }
    }
    
    function loadModuleOrder() {
        if (!enablePersistence) {
            console.log("Persistence disabled, using default order")
            return
        }
        
        console.log("Attempting to load module order from:", configPath)
        
        try {
            // Create file view if it doesn't exist
            if (!configFile) {
                configFile = persistenceFile.createObject(moduleManager)
            }
            
            if (configFile && configFile.text && configFile.text.length > 0) {
                var config = JSON.parse(configFile.text)
                console.log("Loaded config:", JSON.stringify(config))
                
                if (config.left && Array.isArray(config.left)) {
                    leftModuleOrder = config.left.slice()
                }
                if (config.right && Array.isArray(config.right)) {
                    rightModuleOrder = config.right.slice()
                }
                if (config.center && Array.isArray(config.center)) {
                    centerModuleOrder = config.center.slice()
                }
                
                console.log("Applied saved module order")
                console.log("- Left:", JSON.stringify(leftModuleOrder))
                console.log("- Right:", JSON.stringify(rightModuleOrder))
                console.log("- Center:", JSON.stringify(centerModuleOrder))
                
                moduleOrderChanged("all")
            } else {
                console.log("No existing config file or empty file, using defaults")
            }
        } catch (error) {
            console.log("Failed to load module order (this is okay), using defaults:", error)
        }
    }
    
    function resetToDefaults() {
        console.log("Resetting module order to defaults")
        leftModuleOrder = ConfigOptions.bar.modules.defaultLeftOrder.slice()
        rightModuleOrder = ConfigOptions.bar.modules.defaultRightOrder.slice()
        centerModuleOrder = ConfigOptions.bar.modules.defaultCenterOrder.slice()
        
        if (enablePersistence) {
            saveModuleOrder()
        }
        moduleOrderChanged("all")
    }
    
    // Load on component completion (gracefully handle missing files)
    Component.onCompleted: {
        console.log("BarModuleManager initialized")
        console.log("- Persistence enabled:", enablePersistence)
        console.log("- Default order - Left:", JSON.stringify(leftModuleOrder))
        console.log("- Default order - Right:", JSON.stringify(rightModuleOrder))
        console.log("- Default order - Center:", JSON.stringify(centerModuleOrder))
        
        // Try to load saved order, but don't fail if file doesn't exist
        loadModuleOrder()
    }
} 