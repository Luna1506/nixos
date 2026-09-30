import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

// Application icon from the icon theme (or an absolute path), with a
// generic glyph in a circle when it can't be resolved.
Item {
    id: root

    // Icon name as in a desktop entry: theme name, path or file:// URL.
    property string icon
    property real size: Theme.size.appTileIcon
    // Material Symbols glyph shown when the icon can't be resolved.
    property string fallback: "apps"

    readonly property string source: {
        if (icon === "")
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("file://") || icon.startsWith("image://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: image

        // Explicit size instead of anchors: the image is requested before
        // anchors resolve, and a zero sourceSize renders SVGs at full size.
        width: root.size
        height: root.size
        visible: root.source !== "" && status === Image.Ready
        source: root.source
        implicitSize: root.size
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        visible: !image.visible
        radius: width / 2
        color: Theme.colors.surfaceHighest

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.fallback
            size: root.size * Theme.size.appIconGlyphScale
            fill: 1
            color: Theme.colors.textMuted
        }
    }
}
