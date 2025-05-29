import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"

RowLayout {
    id: barSection
    
    // --- Properties ---
    property string section: "left" // "left", "right", "center"
    property var moduleManager: null
    property var bar: null
    property bool enableDragAndDrop: ConfigOptions.bar.modules.enableDragAndDrop
    
    // Layout properties
    spacing: section === "center" ? 8 : 10
    layoutDirection: section === "right" ? Qt.RightToLeft : Qt.LeftToRight
    
    // --- Functions ---
    function refreshModules() {
        console.log("Refreshing modules for section:", section)
        
        // Clear existing modules
        for (var i = repeater.count - 1; i >= 0; i--) {
            var item = repeater.itemAt(i)
            if (item) {
                item.destroy()
            }
        }
        
        // Force repeater to rebuild
        repeater.model = 0
        repeater.model = moduleManager ? moduleManager.getModuleOrder(section) : []
    }
    
    function handleModuleReorder(moduleId, fromIndex, toIndex) {
        console.log("Handling reorder request:", moduleId, fromIndex, "->", toIndex)
        if (moduleManager) {
            moduleManager.moveModule(section, fromIndex, toIndex)
        }
    }
    
    // --- Module Repeater ---
    Repeater {
        id: repeater
        model: {
            console.log("Repeater model update for section:", section)
            console.log("moduleManager exists:", !!moduleManager)
            if (moduleManager) {
                var order = moduleManager.getModuleOrder(section)
                console.log("Module order:", JSON.stringify(order))
                return order
            } else {
                console.log("No moduleManager, using empty model")
                return []
            }
        }
        
        onCountChanged: {
            console.log("Repeater count changed to:", count, "for section:", section)
        }
        
        delegate: BarModule {
            moduleId: modelData
            moduleIndex: index
            section: barSection.section
            isDraggable: enableDragAndDrop
            
            moduleComponent: Component {
                Loader {
                    source: {
                        var componentPath = moduleManager ? moduleManager.getModuleComponent(modelData) : ""
                        console.log("Loading module", modelData, "from path:", componentPath)
                        return componentPath
                    }
                    
                    // Pass bar reference to modules that need it
                    onLoaded: {
                        console.log("Successfully loaded module:", modelData)
                        if (item && item.hasOwnProperty("bar")) {
                            item.bar = barSection.bar
                        }
                    }
                    
                    onStatusChanged: {
                        if (status === Loader.Error) {
                            console.log("Error loading module", modelData, ":", errorString)
                        }
                    }
                }
            }
            
            // Handle drag and drop
            onRequestReorder: (moduleId, fromIndex, toIndex) => {
                handleModuleReorder(moduleId, fromIndex, toIndex)
            }
            
            onDragStarted: (moduleId, index) => {
                console.log("Module drag started:", moduleId, "at", index)
            }
            
            onDragEnded: {
                console.log("Module drag ended")
            }
        }
    }
    
    // --- Connections ---
    Connections {
        target: moduleManager
        function onModuleOrderChanged(changedSection) {
            if (changedSection === section || changedSection === "all") {
                console.log("Module order changed for section:", section)
                refreshModules()
            }
        }
    }
    
    // --- Component Lifecycle ---
    Component.onCompleted: {
        console.log("DraggableBarSection created for:", section)
    }
} 