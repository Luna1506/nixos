import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

// The launcher card: search field above a single list. Without a query the
// list shows the Claude card and the sections (pinned, recent, new, all
// apps) as icon grids; with a query, one list of results by relevance.
// Without matches the query can be sent to Claude as a new chat; Shift+Enter
// does that with any query.
//
// The list is a ListView of rows (headers, grid rows, result rows), so it
// stays virtualized with hundreds of apps. Rows carry a stable `key` for the
// ScriptModel, so pinning or a rescan updates rows in place instead of
// resetting the view. Keyboard navigation works on a flat list of the
// selectable items; the selection follows an item's key, not its index.
Rectangle {
    id: root

    readonly property string query: search.text.trim()
    readonly property int columns: Config.launcherColumns
    readonly property real cellWidth: list.width / columns

    // { key, kind, ... } with kind: "claude" | "header" | "hint" |
    // "apps" (one grid row) | "result" | "ask"
    readonly property var rows: query !== "" ? searchRows(Apps.search(query)) : homeRows()
    // { key, row, col, app } in navigation order; app is null for the Claude
    // card and the "Claude fragen" row.
    readonly property var items: navigationItems(rows)
    // Key of the selected item; if it disappears (e.g. unpinned), the
    // selection stays at about the same place.
    property string selectedKey: ""
    property int selectedHint: 0
    readonly property int selected: {
        const index = items.findIndex(item => item.key === selectedKey);
        return index >= 0 ? index : Math.max(0, Math.min(selectedHint, items.length - 1));
    }
    readonly property var current: items[selected] ?? null

    function reset(): void {
        search.text = "";
        menu.close();
        selectedKey = "";
        selectedHint = 0;
        list.positionViewAtBeginning();
        search.input.forceActiveFocus();
    }

    function gridRows(apps: var, section: string): var {
        const out = [];
        for (let i = 0; i < apps.length; i += columns)
            out.push({
                key: section + ":" + i,
                kind: "apps",
                section: section,
                apps: apps.slice(i, i + columns)
            });
        return out;
    }

    function header(title: string): var {
        return {
            key: "header:" + title,
            kind: "header",
            title: title
        };
    }

    function homeRows(): var {
        let out = [
            {
                key: "claude",
                kind: "claude"
            },
            header("Angepinnt")];
        if (Apps.pinnedApps.length > 0)
            out = out.concat(gridRows(Apps.pinnedApps, "pinned"));
        else
            out.push({
                key: "hint",
                kind: "hint",
                text: "Rechtsklick oder Strg+P auf eine App, um sie anzupinnen"
            });
        if (Apps.recentApps.length > 0)
            out = out.concat([header("Zuletzt geöffnet")], gridRows(Apps.recentApps, "recent"));
        if (Apps.newApps.length > 0)
            out = out.concat([header("Neu installiert")], gridRows(Apps.newApps, "new"));
        return out.concat([header("Alle Apps")], gridRows(Apps.apps, "all"));
    }

    function searchRows(results: var): var {
        if (results.length === 0)
            return [header("Claude"),
                {
                    key: "ask",
                    kind: "ask"
                }
            ];
        return results.map(app => ({
                    key: "result:" + app.id,
                    kind: "result",
                    app: app
                }));
    }

    function navigationItems(rows: var): var {
        const out = [];
        rows.forEach((row, i) => {
            if (row.kind === "claude" || row.kind === "ask")
                out.push({
                    key: row.key,
                    row: i,
                    col: 0,
                    app: null
                });
            else if (row.kind === "result")
                out.push({
                    key: row.key,
                    row: i,
                    col: 0,
                    app: row.app
                });
            else if (row.kind === "apps")
                row.apps.forEach((app, col) => out.push({
                        key: row.section + ":" + app.id,
                        row: i,
                        col: col,
                        app: app
                    }));
        });
        return out;
    }

    function isSelected(row: int, col: int): bool {
        return current !== null && current.row === row && current.col === col;
    }

    function select(index: int): void {
        if (items.length === 0)
            return;
        const target = Math.max(0, Math.min(index, items.length - 1));
        selectedKey = items[target].key;
        selectedHint = target;
        // Show the section header too when moving into its first row.
        const row = items[target].row;
        if (row > 0 && rows[row - 1].kind === "header")
            list.positionViewAtIndex(row - 1, ListView.Contain);
        list.positionViewAtIndex(row, ListView.Contain);
    }

    // Tab / arrow keys in the grid: wraps around.
    function move(delta: int): void {
        if (items.length > 0)
            select((selected + delta + items.length) % items.length);
    }

    // Up / down: same column in the previous / next row with items.
    function moveVertical(direction: int): void {
        const cur = current;
        if (!cur)
            return;
        let i = selected;
        while (i >= 0 && i < items.length && items[i].row === cur.row)
            i += direction;
        if (i < 0 || i >= items.length)
            return;
        const row = items[i].row;
        let first = i;
        while (first > 0 && items[first - 1].row === row)
            first--;
        let last = first;
        while (last + 1 < items.length && items[last + 1].row === row)
            last++;
        select(Math.min(first + cur.col, last));
    }

    function activate(item: var): void {
        if (!item)
            return;
        if (item.app)
            Apps.launch(item.app, null);
        else if (item.key === "ask")
            Apps.askClaude(query);
        else
            Apps.launchClaude();
    }

    function menuEntries(app: var): var {
        const id = app.id;
        const out = [];
        const pinned = Apps.isPinned(id);
        out.push({
            icon: pinned ? "keep_off" : "keep",
            label: pinned ? "Lösen" : "Anpinnen",
            run: () => Apps.togglePin(id)
        });
        if (Apps.canMovePin(id, -1))
            out.push({
                icon: "arrow_back",
                label: "Nach links verschieben",
                run: () => Apps.movePin(id, -1)
            });
        if (Apps.canMovePin(id, 1))
            out.push({
                icon: "arrow_forward",
                label: "Nach rechts verschieben",
                run: () => Apps.movePin(id, 1)
            });
        if (id in Apps.history)
            out.push({
                icon: "history",
                label: "Aus „Zuletzt geöffnet“ entfernen",
                run: () => Apps.removeFromHistory(id)
            });
        for (const action of app.entry.actions)
            out.push({
                icon: "open_in_new",
                label: action.name,
                run: () => Apps.launch(app, action)
            });
        return out;
    }

    // Opens the context menu at a point of `source`, or below the selected
    // item when opened from the keyboard.
    function openMenu(app: var, source: Item, x: real, y: real): void {
        if (!app)
            return;
        const point = source.mapToItem(menu, x, y);
        menu.open(menuEntries(app), point.x, point.y);
    }

    function openMenuForCurrent(): void {
        const cur = current;
        const item = cur ? list.itemAtIndex(cur.row) : null;
        if (!cur?.app || !item)
            return;
        const x = cur.col * cellWidth + (rows[cur.row].kind === "apps" ? cellWidth / 2 : Theme.spacing.xl);
        openMenu(cur.app, item, x, item.height);
    }

    function handleKey(event: var): void {
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (menu.opened) {
            switch (event.key) {
            case Qt.Key_Escape:
                menu.close();
                break;
            case Qt.Key_Down:
            case Qt.Key_Tab:
                menu.move(1);
                break;
            case Qt.Key_Up:
            case Qt.Key_Backtab:
                menu.move(-1);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                menu.trigger(menu.current);
                break;
            default:
                // Typing closes the menu and goes on into the search field.
                menu.close();
                return;
            }
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            ShellState.closeLauncher();
            break;
        case Qt.Key_Down:
            moveVertical(1);
            break;
        case Qt.Key_Up:
            moveVertical(-1);
            break;
        case Qt.Key_Tab:
            move(1);
            break;
        case Qt.Key_Backtab:
            move(-1);
            break;
        case Qt.Key_Left:
        case Qt.Key_Right:
            // With a query the arrows move the text cursor.
            if (query !== "")
                return;
            move(event.key === Qt.Key_Right ? 1 : -1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if ((event.modifiers & Qt.ShiftModifier) && query !== "")
                Apps.askClaude(query);
            else
                activate(current);
            break;
        case Qt.Key_Menu:
            openMenuForCurrent();
            break;
        case Qt.Key_P:
            if (!ctrl)
                return;
            openMenuForCurrent();
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // The first result is preselected.
    onQueryChanged: {
        menu.close();
        selectedKey = "";
        selectedHint = 0;
        list.positionViewAtBeginning();
    }

    color: Theme.colors.panel
    radius: Theme.radius.panel
    border.width: Theme.size.border
    border.color: Theme.colors.outline

    // Swallow clicks so they don't reach the "click outside" area.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
    }

    // Receives the search field's key presses before the text input.
    Item {
        id: keyHandler

        Keys.onPressed: event => root.handleKey(event)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.size.launcherPadding
        spacing: Theme.spacing.lg

        TextField {
            id: search

            Layout.fillWidth: true
            implicitHeight: Theme.size.searchFieldHeight
            icon: "search"
            placeholder: "Apps durchsuchen…"
            input.font.pixelSize: Theme.font.title
            input.focus: true
            forwardKeysTo: [keyHandler]
            trailing: Badge {
                visible: root.query !== ""
                text: "Claude ⇧↵"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list

                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // Keeps a few rows around so fast scrolling doesn't pop in icons.
                cacheBuffer: Theme.size.appTileHeight * 4
                model: ScriptModel {
                    values: root.rows
                    objectProp: "key"
                }

                delegate: Loader {
                    id: row

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    sourceComponent: {
                        switch (modelData.kind) {
                        case "claude":
                            return claudeRow;
                        case "header":
                            return headerRow;
                        case "hint":
                            return hintRow;
                        case "apps":
                            return appsRow;
                        case "result":
                            return resultRow;
                        default:
                            return askRow;
                        }
                    }

                    Component {
                        id: claudeRow

                        Item {
                            implicitHeight: card.implicitHeight + Theme.spacing.sm

                            ClaudeCard {
                                id: card

                                width: parent.width
                                selected: root.isSelected(row.index, 0)
                            }
                        }
                    }

                    Component {
                        id: headerRow

                        SectionHeader {
                            height: implicitHeight + Theme.spacing.md
                            leftPadding: Theme.spacing.sm
                            verticalAlignment: Text.AlignBottom
                            bottomPadding: Theme.spacing.xs
                            text: row.modelData.title
                        }
                    }

                    Component {
                        id: hintRow

                        StyledText {
                            height: Theme.size.pillButton
                            leftPadding: Theme.spacing.sm
                            text: row.modelData.text
                            color: Theme.colors.textDisabled
                            font.pixelSize: Theme.font.small
                        }
                    }

                    Component {
                        id: appsRow

                        Row {
                            id: gridRow

                            readonly property int rowIndex: row.index

                            Repeater {
                                model: row.modelData.apps

                                AppTile {
                                    id: tile

                                    required property var modelData
                                    required property int index

                                    width: root.cellWidth
                                    app: modelData
                                    selected: root.isSelected(gridRow.rowIndex, index)
                                    onActivated: Apps.launch(app, null)
                                    onContextMenuRequested: (x, y) => root.openMenu(app, tile, x, y)
                                }
                            }
                        }
                    }

                    Component {
                        id: resultRow

                        ListRow {
                            id: result

                            readonly property var app: row.modelData.app

                            height: Theme.size.listRow
                            title: app.name
                            subtitle: app.subtitle
                            highlighted: root.isSelected(row.index, 0)
                            onClicked: Apps.launch(app, null)
                            onContextMenuRequested: (x, y) => root.openMenu(app, result, x, y)
                            leading: AppIcon {
                                icon: result.app.icon
                                size: Theme.size.appRowIcon
                            }

                            Badge {
                                anchors.verticalCenter: parent?.verticalCenter
                                visible: Apps.isNew(result.app.id)
                                text: "Neu"
                            }

                            MaterialIcon {
                                visible: Apps.isPinned(result.app.id)
                                icon: "keep"
                                size: Theme.icon.small
                                color: Theme.colors.textMuted
                            }
                        }
                    }

                    Component {
                        id: askRow

                        ListRow {
                            height: Theme.size.listRow
                            title: "Claude fragen"
                            subtitle: "„" + root.query + "“"
                            highlighted: root.isSelected(row.index, 0)
                            onClicked: Apps.askClaude(root.query)
                            leading: AppIcon {
                                icon: Apps.claudeEntry?.icon ?? ""
                                fallback: "auto_awesome"
                                size: Theme.size.appRowIcon
                            }

                            Badge {
                                anchors.verticalCenter: parent?.verticalCenter
                                text: "⇧↵"
                            }
                        }
                    }
                }
            }

            // Thin scroll indicator, like ScrollArea.
            Rectangle {
                visible: list.contentHeight > list.height
                anchors.right: list.right
                y: list.visibleArea.yPosition * list.height
                width: Theme.size.scrollbarWidth
                height: list.visibleArea.heightRatio * list.height
                radius: width / 2
                color: Theme.colors.textDisabled
                opacity: list.moving ? 1 : Theme.opacity.scrollbarIdle
            }
        }
    }

    ContextMenu {
        id: menu

        anchors.fill: parent
    }
}
