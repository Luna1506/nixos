import QtQuick
import QtQuick.Layouts
import qs

// Row for detail lists: icon (or custom `leading` items), title/subtitle
// and trailing items (children are placed at the end of the row).
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool highlighted: false
    property bool clickable: true
    property real iconFill: highlighted ? 1 : 0
    default property alias trailing: trailingRow.data
    property alias leading: leadingItem.data

    signal clicked
    // Right click, in row coordinates.
    signal contextMenuRequested(real x, real y)

    implicitHeight: Theme.size.listRow
    radius: Theme.radius.small
    color: highlighted ? Theme.colors.surfaceHighest : "transparent"

    Behavior on color {
        ColorAnim {}
    }

    Clickable {
        enabled: root.clickable
        radius: root.radius
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.contextMenuRequested(mouse.x, mouse.y) : root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: Theme.spacing.sm
        spacing: Theme.spacing.md

        Item {
            id: leadingItem

            visible: children.length > 0
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

        MaterialIcon {
            visible: root.icon !== ""
            icon: root.icon
            fill: root.iconFill
            color: root.highlighted ? Theme.colors.primary : Theme.colors.text
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.weight: root.highlighted ? Theme.font.weightMedium : Theme.font.weightNormal
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: Theme.colors.textMuted
                font.pixelSize: Theme.font.small
            }
        }

        Row {
            id: trailingRow

            spacing: Theme.spacing.xs
        }
    }
}
