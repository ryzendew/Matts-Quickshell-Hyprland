import "root:/"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: notificationPopup

    LazyLoader {
        loading: true
        PanelWindow {
            id: root
            visible: (columnLayout.children.length > 0 || notificationGroups.length > 0)
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

            property Component notifComponent: NotificationWidget {}
            property var notificationGroups: ({})  // Group notifications by app name
            property list<NotificationWidget> notificationWidgetList: []

            WlrLayershell.namespace: "quickshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                top: true
                right: true
                bottom: true
            }

            mask: Region {
                item: columnLayout
            }

            color: "transparent"
            implicitWidth: Appearance.sizes.notificationPopupWidth

            // Signal handlers to add/remove notifications
            Connections {
                target: Notifications
                function onNotify(notification) {
                    if (GlobalStates.sidebarRightOpen) {
                        return
                    }

                    const appName = notification.appName || "unknown"
                    if (!root.notificationGroups[appName]) {
                        root.notificationGroups[appName] = []
                    }

                    // Create new notification widget
                    const notif = root.notifComponent.createObject(columnLayout, { 
                        notificationObject: notification,
                        popup: true,
                        groupName: appName,
                        groupCount: root.notificationGroups[appName].length + 1
                    });

                    // Add to group and widget list
                    root.notificationGroups[appName].unshift(notif)
                    notificationWidgetList.unshift(notif)

                    // Update layout without shuffling
                    updateLayout()
                }

                function onDiscard(id) {
                    removeNotification(id, true)
                }

                function onTimeout(id) {
                    removeNotification(id, true)
                }

                function onDiscardAll() {
                    for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                        const widget = notificationWidgetList[i];
                        if (widget && widget.notificationObject) {
                            widget.destroyWithAnimation();
                        }
                    }
                    notificationWidgetList = []
                    root.notificationGroups = {}
                }
            }

            function removeNotification(id, animate) {
                for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                    const widget = notificationWidgetList[i];
                    if (widget && widget.notificationObject && widget.notificationObject.id === id) {
                        // Remove from group
                        const group = root.notificationGroups[widget.groupName]
                        if (group) {
                            const index = group.indexOf(widget)
                            if (index !== -1) {
                                group.splice(index, 1)
                                if (group.length === 0) {
                                    delete root.notificationGroups[widget.groupName]
                                } else {
                                    // Update group counts
                                    for (let j = 0; j < group.length; j++) {
                                        group[j].groupCount = group.length
                                    }
                                }
                            }
                        }

                        // Remove widget
                        if (animate) {
                            widget.destroyWithAnimation()
                        } else {
                            widget.destroy()
                        }
                        notificationWidgetList.splice(i, 1)
                        break
                    }
                }
                updateLayout()
            }

            function updateLayout() {
                // Remove all from column
                for (let i = 0; i < notificationWidgetList.length; i++) {
                    if (notificationWidgetList[i].parent === columnLayout) {
                        notificationWidgetList[i].parent = null
                    }
                }

                // Add back in correct order
                for (let i = 0; i < notificationWidgetList.length; i++) {
                    if (notificationWidgetList[i].parent === null) {
                        notificationWidgetList[i].parent = columnLayout
                    }
                }
            }

            ColumnLayout {
                id: columnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Appearance.sizes.elevationMargin * 2
                spacing: 0

                // Notifications are added by the signal handlers
            }
        }
    }
}
