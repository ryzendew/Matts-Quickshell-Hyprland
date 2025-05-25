pragma Singleton
import QtQuick 2.15
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    // Bar settings
    property int barBlurAmount: 8
    property int barBlurPasses: 4
    property bool barXray: false

    // Dock settings
    property real dockTransparency: 0.65
    property int dockBlurAmount: 20
    property int dockBlurPasses: 2
    property bool dockXray: false

    // Sidebar settings
    property real sidebarTransparency: 0.2
    property bool sidebarXray: false

    // Save settings when they change
    onBarBlurAmountChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    onBarBlurPassesChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    onBarXrayChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    
    onDockTransparencyChanged: {
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurAmountChanged: {
        Hyprland.dispatch("keyword decoration:blur:enabled 1")
        Hyprland.dispatch("keyword decoration:blur:size " + dockBlurAmount)
        Hyprland.dispatch("keyword layerrule blur,^(quickshell:dock:blur)$")
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurPassesChanged: {
        Hyprland.dispatch("keyword decoration:blur:passes " + dockBlurPasses)
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockXrayChanged: {
        if (dockXray) {
            Hyprland.dispatch("keyword layerrule xray on,^(quickshell:dock:blur)$")
        } else {
            Hyprland.dispatch("keyword layerrule xray off,^(quickshell:dock:blur)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }

    onSidebarTransparencyChanged: {
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onSidebarXrayChanged: {
        if (sidebarXray) {
            Hyprland.dispatch("keyword layerrule xray on,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("keyword layerrule xray on,^(quickshell:sidebarRight)$")
        } else {
            Hyprland.dispatch("keyword layerrule xray off,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("keyword layerrule xray off,^(quickshell:sidebarRight)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }

    Component.onCompleted: {
        // Apply initial settings
        Hyprland.dispatch("keyword decoration:blur:enabled 1")
        Hyprland.dispatch("keyword decoration:blur:size " + dockBlurAmount)
        Hyprland.dispatch("keyword decoration:blur:passes " + dockBlurPasses)
        Hyprland.dispatch("keyword layerrule blur,^(quickshell:dock:blur)$")
        // Apply sidebar xray settings if enabled
        if (sidebarXray) {
            Hyprland.dispatch("keyword layerrule xray on,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("keyword layerrule xray on,^(quickshell:sidebarRight)$")
        }
    }
} 