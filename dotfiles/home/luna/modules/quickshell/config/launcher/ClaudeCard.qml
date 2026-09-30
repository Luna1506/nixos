import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

// Shortcut to Claude (desktop app, or claude.ai as fallback), an optional
// Claude Code button and the current plan usage.
Card {
    id: root

    property bool selected: false

    implicitHeight: layout.implicitHeight + 2 * Theme.spacing.lg
    color: selected ? Theme.colors.surfaceHigh : Theme.colors.surface

    Behavior on color {
        ColorAnim {
            duration: Theme.anim.fast
        }
    }

    Clickable {
        radius: root.radius
        onClicked: Apps.launchClaude()
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.lg
        spacing: Theme.spacing.md

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.md

            AppIcon {
                icon: Apps.claudeEntry?.icon ?? ""
                fallback: "auto_awesome"
                size: Theme.size.claudeIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: "Claude"
                    font.pixelSize: Theme.font.title
                    font.weight: Theme.font.weightMedium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Apps.claudeEntry ? "Desktop-App öffnen" : "claude.ai im Browser öffnen"
                    color: Theme.colors.textMuted
                    font.pixelSize: Theme.font.small
                }
            }

            PillButton {
                visible: Apps.claudeCodeAvailable
                text: "Claude Code"
                icon: "terminal"
                onClicked: Apps.launchClaudeCode()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: ClaudeUsage.available
            spacing: Theme.spacing.xl

            UsageBar {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: ClaudeUsage.session !== null
                label: "Session"
                value: ClaudeUsage.current(ClaudeUsage.session)
                resetsAt: ClaudeUsage.session?.resetsAt ?? 0
                now: ClaudeUsage.now
            }

            UsageBar {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: ClaudeUsage.week !== null
                label: "Woche"
                value: ClaudeUsage.current(ClaudeUsage.week)
                resetsAt: ClaudeUsage.week?.resetsAt ?? 0
                now: ClaudeUsage.now
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !ClaudeUsage.available
            text: ClaudeUsage.loading ? "Usage wird geladen…" : "Usage nicht verfügbar"
            color: Theme.colors.textDisabled
            font.pixelSize: Theme.font.small
        }
    }
}
