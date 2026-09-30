import QtQuick
import qs

// Small pill label, e.g. "Neu".
Rectangle {
    id: root

    property alias text: label.text

    implicitHeight: Theme.size.badgeHeight
    implicitWidth: label.implicitWidth + 2 * Theme.size.badgePadding
    radius: height / 2
    color: Theme.colors.primary

    StyledText {
        id: label

        anchors.centerIn: parent
        color: Theme.colors.textOnPrimary
        font.pixelSize: Theme.font.badge
        font.weight: Theme.font.weightSemiBold
        font.letterSpacing: Theme.font.labelLetterSpacing
    }
}
