import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

// All notifications of one app in a card. Shows the newest few; the rest
// behind "Show more".
Card {
    id: root

    required property string app

    readonly property var items: Notifications.list.filter(n => Notifications.appKey(n) === app)
    readonly property int collapsedCount: Config.groupCollapsedCount
    property bool expanded: false
    readonly property var shown: expanded ? items : items.slice(0, collapsedCount)

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.lg
            Layout.rightMargin: Theme.spacing.sm
            Layout.topMargin: Theme.spacing.sm
            spacing: Theme.spacing.sm

            StyledText {
                Layout.fillWidth: true
                text: root.items.length > 1 ? root.app + "  ·  " + root.items.length : root.app
                color: Theme.colors.textMuted
                font.pixelSize: Theme.font.small
                font.weight: Theme.font.weightMedium
            }

            PillButton {
                visible: root.items.length > root.collapsedCount
                implicitHeight: Theme.icon.large
                style: "text"
                text: root.expanded ? I18n.tr("Show less") : I18n.tr("Show %1 more", root.items.length - root.collapsedCount)
                onClicked: root.expanded = !root.expanded
            }

            IconButton {
                visible: root.items.length > 1
                implicitWidth: Theme.icon.large
                implicitHeight: Theme.icon.large
                tonal: false
                icon: "clear_all"
                iconSize: Theme.icon.small
                iconColor: Theme.colors.textMuted
                onClicked: Notifications.dismissApp(root.app)
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.shown
            }

            NotificationContent {
                id: item

                required property var modelData

                Layout.fillWidth: true
                notification: modelData
                showAppName: false
                onClicked: item.expanded = !item.expanded
            }
        }
    }
}
