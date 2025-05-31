import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    property bool enabled: false
    buttonIcon: "gamepad"
    toggled: enabled

    onToggledChanged: {
        if (toggled) {
            // Apply game mode settings
            // Original: Hyprland.dispatch(`exec hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`)
            
            // Store previous values if not already stored
            if (!previousSettings.animationsEnabled) previousSettings.animationsEnabled = Hyprland.getOption("animations:enabled");
            if (!previousSettings.shadowsEnabled) previousSettings.shadowsEnabled = Hyprland.getOption("decoration:shadow:enabled");
            if (!previousSettings.blurEnabled) previousSettings.blurEnabled = Hyprland.getOption("decoration:blur:enabled");
            if (!previousSettings.gapsIn) previousSettings.gapsIn = Hyprland.getOption("general:gaps_in");
            if (!previousSettings.gapsOut) previousSettings.gapsOut = Hyprland.getOption("general:gaps_out");
            if (!previousSettings.borderSize) previousSettings.borderSize = Hyprland.getOption("general:border_size");
            if (!previousSettings.rounding) previousSettings.rounding = Hyprland.getOption("decoration:rounding");
            if (!previousSettings.allowTearing) previousSettings.allowTearing = Hyprland.getOption("general:allow_tearing");

            // Construct the batch command with setvar for variables
            let batchCommand = `setvar animations:enabled 0; `;
            batchCommand += `setvar decoration:shadow:enabled 0; `;
            batchCommand += `setvar decoration:blur:enabled 0; `;
            batchCommand += `setvar general:gaps_in 0; `;
            batchCommand += `setvar general:gaps_out 0; `;
            batchCommand += `setvar general:border_size 1; `;
            batchCommand += `setvar decoration:rounding 0; `;
            batchCommand += `setvar misc:vfr false;`; // Recommended for gaming
            batchCommand += `keyword general:allow_tearing 1`; // keyword is correct for this one if it's a direct config keyword not a variable
                                                        // However, general:allow_tearing is a variable, so it should be setvar
            batchCommand = `setvar animations:enabled 0; `;
            batchCommand += `setvar decoration:shadow:enabled 0; `;
            batchCommand += `setvar decoration:blur:enabled 0; `;
            batchCommand += `setvar general:gaps_in 0; `;
            batchCommand += `setvar general:gaps_out 0; `;
            batchCommand += `setvar general:border_size 1; `;
            batchCommand += `setvar decoration:rounding 0; `;
            batchCommand += `setvar misc:vfr false; `; // Recommended for gaming
            batchCommand += `setvar general:allow_tearing 1;`;

            Hyprland.dispatch(`exec hyprctl --batch "${batchCommand}"`);
            
            label = "Game Mode: ON";
        } else {
            // Restore previous settings if they were stored
            let restoreCommand = "";
            if (previousSettings.animationsEnabled !== null) restoreCommand += `setvar animations:enabled ${previousSettings.animationsEnabled}; `;
            if (previousSettings.shadowsEnabled !== null) restoreCommand += `setvar decoration:shadow:enabled ${previousSettings.shadowsEnabled}; `;
            if (previousSettings.blurEnabled !== null) restoreCommand += `setvar decoration:blur:enabled ${previousSettings.blurEnabled}; `;
            if (previousSettings.gapsIn !== null) restoreCommand += `setvar general:gaps_in ${previousSettings.gapsIn}; `;
            if (previousSettings.gapsOut !== null) restoreCommand += `setvar general:gaps_out ${previousSettings.gapsOut}; `;
            if (previousSettings.borderSize !== null) restoreCommand += `setvar general:border_size ${previousSettings.borderSize}; `;
            if (previousSettings.rounding !== null) restoreCommand += `setvar decoration:rounding ${previousSettings.rounding}; `;
            if (previousSettings.allowTearing !== null) restoreCommand += `setvar general:allow_tearing ${previousSettings.allowTearing}; `;
            restoreCommand += `setvar misc:vfr true;`; // Restore VFR

            if (restoreCommand) {
                Hyprland.dispatch(`exec hyprctl --batch "${restoreCommand}"`);
            }
            label = "Game Mode: OFF";
        }
    }
    
    StyledToolTip {
        content: qsTr("Game mode")
    }
}