import QtQuick
import qs
import qs.components
import qs.services

// Grid cell: app icon with its name below; "Neu" badge for new apps.
Item {
    id: root

    required property var app
    property bool selected: false

    signal activated
    // Right click, in tile coordinates.
    signal contextMenuRequested(real x, real y)

    implicitHeight: Theme.size.appTileHeight

    Rectangle {
        id: background

        anchors.fill: parent
        radius: Theme.radius.card
        color: root.selected ? Theme.colors.surfaceHighest : "transparent"

        Behavior on color {
            ColorAnim {
                duration: Theme.anim.fast
            }
        }

        Clickable {
            radius: background.radius
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton ? root.contextMenuRequested(mouse.x, mouse.y) : root.activated()
        }
    }

    AppIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.spacing.md
        icon: root.app.icon
        size: Theme.size.appTileIcon
    }

    Badge {
        visible: Apps.isNew(root.app.id)
        anchors.horizontalCenter: icon.right
        anchors.verticalCenter: icon.top
        text: "Neu"
    }

    StyledText {
        anchors.top: icon.bottom
        anchors.topMargin: Theme.spacing.xs
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacing.xs
        anchors.rightMargin: Theme.spacing.xs
        text: root.app.name
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        wrapMode: Text.Wrap
        maximumLineCount: 2
        font.pixelSize: Theme.font.small
    }
}
