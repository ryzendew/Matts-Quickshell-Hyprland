pragma Singleton
import QtQuick 2.15
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    // General blur enable/disable
    property bool blurEnabled: true

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

    // Weather widget settings
    property real weatherTransparency: 0.8
    property int weatherBlurAmount: 8
    property int weatherBlurPasses: 4
    property bool weatherXray: false

    // Save settings when they change
    onBarBlurAmountChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    onBarBlurPassesChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    onBarXrayChanged: Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    
    onDockTransparencyChanged: {
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurAmountChanged: {
        if (blurEnabled) {
            Hyprland.dispatch("setvar decoration:blur:enabled 1")
            Hyprland.dispatch("setvar decoration:blur:size " + dockBlurAmount)
            Hyprland.dispatch("layerrule blur,^(quickshell:dock:blur)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurPassesChanged: {
        if (blurEnabled) {
            Hyprland.dispatch("setvar decoration:blur:passes " + dockBlurPasses)
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockXrayChanged: {
        if (dockXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:dock:blur)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:dock:blur)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }

    onSidebarTransparencyChanged: {
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onSidebarXrayChanged: {
        if (sidebarXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("layerrule xray on,^(quickshell:sidebarRight)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("layerrule xray off,^(quickshell:sidebarRight)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }

    onWeatherTransparencyChanged: {
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurAmountChanged: {
        if (blurEnabled) {
            Hyprland.dispatch("setvar decoration:blur:enabled 1")
            Hyprland.dispatch("setvar decoration:blur:size " + weatherBlurAmount)
            Hyprland.dispatch("layerrule blur,^(quickshell:weather:blur)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurPassesChanged: {
        if (blurEnabled) {
            Hyprland.dispatch("setvar decoration:blur:passes " + weatherBlurPasses)
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherXrayChanged: {
        if (weatherXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:weather:blur)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:weather:blur)$")
        }
        Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
    }

    function updateDockBlurSettings() {
        if (!blurEnabled) {
            Hyprland.dispatch("layerrule unset,^(quickshell:dock:blur)$")
            return;
        }
        Hyprland.dispatch("setvar decoration:blur:enabled 1")
        Hyprland.dispatch("setvar decoration:blur:size " + dockBlurAmount)
        Hyprland.dispatch("setvar decoration:blur:passes " + dockBlurPasses)
        Hyprland.dispatch("layerrule blur,^(quickshell:dock:blur)$")
        if (dockXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:dock:blur)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:dock:blur)$")
        }
    }

    function updateWeatherBlurSettings() {
        if (!blurEnabled) {
            Hyprland.dispatch("layerrule unset,^(quickshell:weather:blur)$")
            return;
        }
        Hyprland.dispatch("setvar decoration:blur:enabled 1")
        Hyprland.dispatch("setvar decoration:blur:size " + weatherBlurAmount)
        Hyprland.dispatch("setvar decoration:blur:passes " + weatherBlurPasses)
        Hyprland.dispatch("layerrule blur,^(quickshell:weather:blur)$")
        if (weatherXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:weather:blur)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:weather:blur)$")
        }
    }
    
    function updateBarBlurSettings() {
        if (!blurEnabled) {
            Hyprland.dispatch("layerrule unset,^(quickshell:bar:blur)$")
            return;
        }
        Hyprland.dispatch("setvar decoration:blur:enabled 1")
        Hyprland.dispatch("layerrule blur,^(quickshell:bar:blur)$")
        if (barXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:bar:blur)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:bar:blur)$")
        }
    }

    // Apply initial settings
    Component.onCompleted: {
        updateDockBlurSettings()
        updateWeatherBlurSettings()
        updateBarBlurSettings()
        if (sidebarXray) {
            Hyprland.dispatch("layerrule xray on,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("layerrule xray on,^(quickshell:sidebarRight)$")
        } else {
            Hyprland.dispatch("layerrule xray off,^(quickshell:sidebarLeft)$")
            Hyprland.dispatch("layerrule xray off,^(quickshell:sidebarRight)$")
        }
    }
} 