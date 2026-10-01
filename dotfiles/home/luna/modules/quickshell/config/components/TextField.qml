import QtQuick
import qs

// Pill-shaped single line input with an optional leading icon. With
// `password` the text is masked and an eye button reveals it.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder
    property string icon
    property bool password: false
    property bool reveal: false
    // Items that get key presses before the text input (Keys.forwardTo).
    property list<Item> forwardKeysTo
    // Items at the end of the field, e.g. a shortcut hint.
    property alias trailing: trailingRow.data

    signal accepted

    implicitHeight: Theme.size.iconButton + Theme.spacing.xs
    implicitWidth: Theme.size.controlWidth
    radius: height / 2
    color: Theme.colors.surfaceHighest
    border.width: Theme.size.border
    border.color: input.activeFocus ? Theme.colors.primary : "transparent"

    Behavior on border.color {
        ColorAnim {}
    }

    MaterialIcon {
        id: leadingIcon

        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.lg
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        color: Theme.colors.textMuted
    }

    TextInput {
        id: input

        anchors.left: leadingIcon.visible ? leadingIcon.right : parent.left
        anchors.right: trailingRow.left
        anchors.leftMargin: leadingIcon.visible ? Theme.spacing.md : Theme.spacing.lg
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Theme.colors.text
        selectionColor: Theme.colors.primaryMuted
        selectedTextColor: Theme.colors.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.body
        Keys.forwardTo: root.forwardKeysTo
        echoMode: root.password && !root.reveal ? TextInput.Password : TextInput.Normal
        onAccepted: root.accepted()

        StyledText {
            anchors.fill: parent
            visible: input.text === ""
            text: root.placeholder
            color: Theme.colors.textMuted
            font.pixelSize: input.font.pixelSize
        }
    }

    Row {
        id: trailingRow

        anchors.right: eye.visible ? eye.left : parent.right
        anchors.rightMargin: width > 0 ? Theme.spacing.md : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.xs
    }

    IconButton {
        id: eye

        visible: root.password
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.xs
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Theme.size.pillButton
        implicitHeight: Theme.size.pillButton
        tonal: false
        icon: root.reveal ? "visibility_off" : "visibility"
        iconSize: Theme.icon.small
        onClicked: root.reveal = !root.reveal
    }
}
