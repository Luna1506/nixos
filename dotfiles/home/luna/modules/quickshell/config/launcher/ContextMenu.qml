import QtQuick
import qs
import qs.components

// Small popup menu inside the launcher card. `entries` are
// { icon, label, run }. While open, a click anywhere else closes it.
Item {
    id: root

    property var entries: []
    property int current: 0
    readonly property bool opened: entries.length > 0

    function open(items: var, x: real, y: real): void {
        entries = items;
        current = 0;
        // Keep the menu inside the card.
        menu.x = Math.max(Theme.spacing.sm, Math.min(x, width - menu.width - Theme.spacing.sm));
        menu.y = Math.max(Theme.spacing.sm, Math.min(y, height - menu.height - Theme.spacing.sm));
    }

    function close(): void {
        entries = [];
    }

    function move(delta: int): void {
        if (entries.length > 0)
            current = (current + delta + entries.length) % entries.length;
    }

    function trigger(index: int): void {
        const entry = entries[index];
        close();
        entry?.run();
    }

    visible: opened

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: root.close()
    }

    Rectangle {
        id: menu

        width: Theme.size.menuWidth
        // Computed from the entries, so open() can place it right away.
        height: root.entries.length * Theme.size.menuRow + 2 * Theme.spacing.xs
        radius: Theme.radius.small + Theme.spacing.xs
        color: Theme.colors.surfaceHigh
        border.width: Theme.size.border
        border.color: Theme.colors.outline
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : Theme.anim.popInScale
        transformOrigin: Item.TopLeft

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }

        Behavior on scale {
            Anim {
                duration: Theme.anim.fast
            }
        }

        // Swallow clicks between the rows.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            x: Theme.spacing.xs
            y: Theme.spacing.xs
            width: parent.width - 2 * Theme.spacing.xs

            Repeater {
                model: root.entries

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: column.width
                    height: Theme.size.menuRow
                    radius: Theme.radius.small
                    color: index === root.current ? Theme.colors.surfaceHighest : "transparent"

                    Clickable {
                        radius: row.radius
                        onClicked: root.trigger(row.index)
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.current = row.index;
                        }
                    }

                    MaterialIcon {
                        id: rowIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        icon: row.modelData.icon
                        size: Theme.icon.small
                    }

                    StyledText {
                        anchors.left: rowIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacing.md
                        anchors.rightMargin: Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                    }
                }
            }
        }
    }
}
