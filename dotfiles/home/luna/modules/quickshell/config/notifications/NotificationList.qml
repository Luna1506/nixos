import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

ColumnLayout {
    spacing: Theme.spacing.sm

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.sm

        StyledText {
            text: "Notifications"
            font.pixelSize: Theme.font.title
            font.weight: Theme.font.weightMedium
        }

        Rectangle {
            visible: Notifications.count > 0
            implicitHeight: Theme.icon.normal
            implicitWidth: Math.max(implicitHeight, countText.implicitWidth + 2 * Theme.spacing.sm)
            radius: height / 2
            color: Theme.colors.primary

            StyledText {
                id: countText

                anchors.centerIn: parent
                text: Notifications.count
                color: Theme.colors.textOnPrimary
                font.pixelSize: Theme.font.small
                font.weight: Theme.font.weightSemiBold
            }
        }

        Item {
            Layout.fillWidth: true
        }

        PillButton {
            visible: Notifications.count > 0
            style: "text"
            icon: "clear_all"
            text: "Clear all"
            onClicked: Notifications.clearAll()
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: view

            anchors.fill: parent
            clip: true
            spacing: Theme.spacing.sm
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: Notifications.apps
            }

            delegate: NotificationGroup {
                required property string modelData

                width: view.width
                app: modelData
            }

            add: Transition {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }
            }

            remove: Transition {
                Anim {
                    property: "opacity"
                    to: 0
                }
            }

            // Also restores opacity/x: an add transition interrupted by a
            // displacement would otherwise leave the item half transparent.
            displaced: Transition {
                ParallelAnimation {
                    Anim {
                        property: "y"
                    }

                    Anim {
                        property: "opacity"
                        to: 1
                    }

                    Anim {
                        property: "x"
                        to: 0
                    }
                }
            }
        }

        EmptyState {
            anchors.centerIn: parent
            width: parent.width
            visible: Notifications.count === 0
            icon: Notifications.dnd ? "do_not_disturb_on" : "notifications_active"
            title: "All caught up"
            subtitle: Notifications.dnd ? "Do not disturb is on. New notifications will still show up here." : "No notifications"
        }
    }
}
