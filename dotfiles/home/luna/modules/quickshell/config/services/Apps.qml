pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Installed applications for the launcher: search index and ranking, pins,
// launch history, "new" detection and launching.
//
// DesktopEntries watches the XDG application directories itself and emits
// applicationsChanged after a rescan, so newly installed apps show up live.
//
// State lives in ~/.local/state/quickshell/launcher.json:
//   pins:    ordered app ids
//   history: { id: { count, last } }   (last = ms since epoch)
//   known:   { id: firstSeen }         (0 = present when the launcher first ran)
Singleton {
    id: root

    // Visible, de-duplicated apps sorted by name. Each item:
    // { id, entry, name, subtitle, icon, fields: [{ text, weight, fuzzy }] }
    property var apps: []
    property var appsById: ({})

    property var pins: []
    property var history: ({})
    property var known: ({})
    property bool stateLoaded: false

    // Refreshed when the launcher opens; drives "new" expiry and frecency.
    property real now: Date.now()

    readonly property var pinnedApps: pins.map(id => appsById[id]).filter(Boolean)
    readonly property var recentApps: Object.keys(history).filter(id => appsById[id]).sort((a, b) => history[b].last - history[a].last).slice(0, Config.launcherRecentCount).map(id => appsById[id])
    readonly property var newApps: apps.filter(app => isNew(app.id)).sort((a, b) => known[b.id] - known[a.id])

    readonly property DesktopEntry claudeEntry: appsById[Config.claudeDesktopId]?.entry ?? null
    property bool claudeCodeAvailable: false

    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/launcher.json"
    readonly property string home: Quickshell.env("HOME") ?? "/"

    // Environment of the systemd user manager (the session environment,
    // without the variables of Quickshell's own Nix wrapper).
    property var sessionEnv: null

    // Called when the launcher opens.
    function prepare(): void {
        now = Date.now();
        if (!envProc.running)
            envProc.running = true;
    }

    function isPinned(id: string): bool {
        return pins.includes(id);
    }

    function isNew(id: string): bool {
        const seen = known[id] ?? 0;
        if (seen <= 0 || now - seen > Config.launcherNewDays * 86400000)
            return false;
        return !((history[id]?.last ?? 0) >= seen);
    }

    // ── Search ──────────────────────────────────────────────────────────

    // Lowercase, without diacritics (ä -> a, é -> e), ß -> ss.
    function normalize(text: string): string {
        return (text ?? "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\u00df/g, "ss");
    }

    function isSeparator(c: string): bool {
        return c === " " || c === "-" || c === "_" || c === "." || c === "/" || c === ":" || c === "(" || c === ",";
    }

    // Subsequence match; `wordStarts` prefers characters at word starts.
    // To keep noise out, the first character has to hit a word start and
    // only every third character may be "loose" (neither at a word start
    // nor right after the previous match).
    function subsequence(text: string, query: string, wordStarts: bool): int {
        let pos = 0;
        let score = 0;
        let streak = 0;
        let loose = 0;
        for (let i = 0; i < query.length; i++) {
            const c = query[i];
            let found = -1;
            if (wordStarts) {
                for (let j = text.indexOf(c, pos); j >= 0; j = text.indexOf(c, j + 1)) {
                    if (j === 0 || isSeparator(text[j - 1]) || (i > 0 && j === pos)) {
                        found = j;
                        break;
                    }
                }
            }
            if (found < 0)
                found = text.indexOf(c, pos);
            if (found < 0)
                return 0;
            const wordStart = found === 0 || isSeparator(text[found - 1]);
            const consecutive = i > 0 && found === pos;
            if (!wordStart && !consecutive) {
                if (i === 0 || ++loose > Math.floor((query.length - 1) / 3))
                    return 0;
            }
            streak = consecutive ? streak + 1 : 0;
            score += 1 + (wordStart ? 3 : 0) + 2 * streak;
            pos = found + 1;
        }
        return score;
    }

    // exact > prefix > word start > substring > fuzzy
    function matchText(text: string, query: string, fuzzy: bool): real {
        if (text === "" || query.length > text.length)
            return 0;
        if (text === query)
            return 1000;
        if (text.startsWith(query))
            return 800 - Math.min(100, text.length - query.length);
        let substring = false;
        for (let i = text.indexOf(query, 1); i > 0; i = text.indexOf(query, i + 1)) {
            if (isSeparator(text[i - 1]))
                return 600;
            substring = true;
        }
        if (substring)
            return 400;
        if (!fuzzy || query.length < 2)
            return 0;
        const best = Math.max(subsequence(text, query, false), subsequence(text, query, true));
        if (best === 0)
            return 0;
        // Best case per character: word start (3) + streak (2) + 1.
        return 100 + 200 * Math.min(1, best / (6 * query.length));
    }

    function matchApp(app: var, query: string): real {
        let best = 0;
        for (const field of app.fields)
            best = Math.max(best, matchText(field.text, query, field.fuzzy) * field.weight);
        return best;
    }

    function frecency(id: string): real {
        const h = history[id];
        if (!h)
            return 0;
        const ageDays = Math.max(0, now - h.last) / 86400000;
        const recency = Math.pow(0.5, ageDays / Config.launcherFrecencyHalfLife);
        const usage = Math.min(1, Math.log2(1 + h.count) / 5);
        return Config.launcherFrecencyBonus * (usage + recency) / 2;
    }

    // Apps matching `text`, best first. Every word of the query has to
    // match; the whole query as one string is tried as well.
    function search(text: string): var {
        const query = normalize(text).trim().replace(/\s+/g, " ");
        if (query === "")
            return [];
        const words = query.split(" ");
        const results = [];
        for (const app of apps) {
            let score = matchApp(app, query);
            if (words.length > 1) {
                let sum = 0;
                for (const word of words) {
                    const s = matchApp(app, word);
                    if (s === 0) {
                        sum = 0;
                        break;
                    }
                    sum += s;
                }
                score = Math.max(score, 0.9 * sum / words.length);
            }
            if (score <= 0)
                continue;
            if (isPinned(app.id))
                score += Config.launcherPinBonus;
            results.push({
                app: app,
                score: score + frecency(app.id)
            });
        }
        results.sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name));
        return results.slice(0, Config.launcherMaxResults).map(r => r.app);
    }

    // ── Entries ─────────────────────────────────────────────────────────

    function basename(path: string): string {
        return (path ?? "").split("/").pop();
    }

    // Everything the launcher shows or searches; a rescan that changes none
    // of it (the watcher also fires for unrelated changes) is ignored.
    property string signature: ""

    function entrySignature(entry: DesktopEntry): string {
        return [entry.id, entry.name, entry.genericName, entry.comment, entry.icon, entry.execString, entry.keywords.join(";"), entry.runInTerminal, entry.actions.map(a => a.name).join(";")].join("\u001f");
    }

    function rebuild(): void {
        // The order of DesktopEntries.applications is not stable between
        // runs; sort by id so duplicates resolve the same way every time.
        const entries = [...DesktopEntries.applications.values].filter(e => e && e.command.length > 0).sort((a, b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0);

        const next = entries.map(entrySignature).join("\u001e");
        if (next === signature)
            return;
        signature = next;

        // Same app installed through several profiles: keep one, preferring
        // an id that is pinned or has history.
        const chosen = {};
        for (const entry of entries) {
            const key = entry.name + "\n" + entry.execString;
            const current = chosen[key];
            if (!current || (!isPinned(current.id) && !(current.id in history) && (isPinned(entry.id) || entry.id in history)))
                chosen[key] = entry;
        }

        const list = [];
        const byId = {};
        for (const entry of entries) {
            if (chosen[entry.name + "\n" + entry.execString] !== entry)
                continue;

            const fields = [
                {
                    text: normalize(entry.name),
                    weight: 1,
                    fuzzy: true
                },
                {
                    text: normalize(entry.genericName),
                    weight: 0.8,
                    fuzzy: true
                },
                {
                    text: normalize(entry.keywords.join(" ")),
                    weight: 0.7,
                    fuzzy: true
                },
                {
                    text: normalize(basename(entry.command[0])),
                    weight: 0.6,
                    fuzzy: true
                },
                {
                    text: normalize(entry.comment),
                    weight: 0.4,
                    fuzzy: false
                }
            ].filter(f => f.text !== "");
            const app = {
                id: entry.id,
                entry: entry,
                name: entry.name,
                subtitle: entry.genericName || entry.comment,
                icon: entry.icon,
                fields: fields
            };
            list.push(app);
            byId[entry.id] = app;
        }
        list.sort((a, b) => a.name.localeCompare(b.name));
        apps = list;
        appsById = byId;
        updateKnown();
    }

    // Remember app ids. On the very first run everything counts as already
    // known; afterwards unknown ids get their first-seen time ("new").
    // Ids are never forgotten, so an app that briefly disappears during a
    // rebuild does not come back as new.
    function updateKnown(): void {
        if (!stateLoaded || apps.length === 0)
            return;
        const firstRun = Object.keys(known).length === 0;
        const stamp = firstRun ? 0 : Date.now();
        const next = Object.assign({}, known);
        let changed = false;
        for (const app of apps) {
            if (!(app.id in next)) {
                next[app.id] = stamp;
                changed = true;
            }
        }
        if (changed) {
            known = next;
            save();
        }
    }

    // ── Pins and history ────────────────────────────────────────────────

    function togglePin(id: string): void {
        pins = isPinned(id) ? pins.filter(p => p !== id) : pins.concat([id]);
        save();
    }

    // Moves a pin by `delta` places among the pins that are installed.
    function movePin(id: string, delta: int): void {
        const visible = pinnedApps.map(app => app.id);
        const from = visible.indexOf(id);
        const to = from + delta;
        if (from < 0 || to < 0 || to >= visible.length)
            return;
        visible.splice(to, 0, visible.splice(from, 1)[0]);
        // Uninstalled pins keep their place at the end.
        pins = visible.concat(pins.filter(p => !visible.includes(p)));
        save();
    }

    function canMovePin(id: string, delta: int): bool {
        const index = pinnedApps.findIndex(app => app.id === id);
        return index >= 0 && index + delta >= 0 && index + delta < pinnedApps.length;
    }

    function removeFromHistory(id: string): void {
        if (!(id in history))
            return;
        const next = Object.assign({}, history);
        delete next[id];
        history = next;
        save();
    }

    function recordLaunch(id: string): void {
        const next = Object.assign({}, history);
        next[id] = {
            count: (history[id]?.count ?? 0) + 1,
            last: Date.now()
        };
        history = next;
        save();
    }

    // ── Launching ───────────────────────────────────────────────────────

    // Launches an app, or one of its desktop actions.
    function launch(app: var, action: var): void {
        const entry = app?.entry;
        if (!entry)
            return;
        const command = action ? action.command : entry.command;
        if (!command || command.length === 0)
            return;
        run(entry.runInTerminal ? Config.terminalCommand.concat(command) : command, entry.workingDirectory, app.id);
        recordLaunch(app.id);
        ShellState.closeLauncher();
    }

    function launchClaude(): void {
        const app = appsById[Config.claudeDesktopId];
        if (app)
            launch(app, null);
        else {
            run(Config.claudeWebCommand, "", "claude-web");
            ShellState.closeLauncher();
        }
    }

    // New Claude chat with `text` as the prompt and the image files pasted
    // in (desktop app; claude.ai as fallback, without images).
    function askClaude(text: string, images: var): void {
        const prompt = text.trim().slice(0, Config.claudeAskMaxChars);
        const app = appsById[Config.claudeDesktopId];
        if (app) {
            run(Config.claudeAskCommand.concat([prompt], images), home, app.id);
            recordLaunch(app.id);
        } else {
            run(["xdg-open", Config.claudeAskWebUrl + "?q=" + encodeURIComponent(prompt)], "", "claude-web");
        }
        ShellState.closeLauncher();
    }

    function launchClaudeCode(): void {
        run(Config.terminalCommand.concat(Config.claudeCodeCommand), home, "claude-code");
        ShellState.closeLauncher();
    }

    // Like `systemd-escape`: keeps [A-Za-z0-9:_.] and writes every other
    // byte (UTF-8) as \xNN.
    function systemdEscape(text: string): string {
        const encoded = encodeURIComponent(text);
        let out = "";
        for (let i = 0; i < encoded.length; i++) {
            let byte;
            if (encoded[i] === "%") {
                byte = parseInt(encoded.substr(i + 1, 2), 16);
                i += 2;
            } else {
                byte = encoded.charCodeAt(i);
            }
            const c = String.fromCharCode(byte);
            const keep = /[A-Za-z0-9:_]/.test(c) || (c === "." && out !== "");
            out += keep ? c : "\\x" + (byte < 16 ? "0" : "") + byte.toString(16);
        }
        return out;
    }

    // Starts `argv` in its own systemd scope, so the app is neither a child
    // of Quickshell nor part of its service (it survives a shell restart).
    // The command is passed as an argument list; no shell is involved.
    function run(argv: var, workingDirectory: string, name: string): void {
        // app-<launcher>-<escaped app id>-<random>.scope, as systemd's XDG
        // application convention expects.
        const unit = "app-quickshell-" + systemdEscape(String(name)).slice(0, 128) + "-" + Math.floor(Math.random() * 0xffffffff).toString(16) + ".scope";
        const env = sessionEnv;
        Quickshell.execDetached({
            command: ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--slice=app-graphical.slice", "--unit=" + unit, "--"].concat(argv),
            // Without the session environment, at least drop the variables
            // of Quickshell's wrapper that would leak into Qt apps.
            environment: env ?? {
                "NIXPKGS_QT6_QML_IMPORT_PATH": null,
                "QT_PLUGIN_PATH": null
            },
            clearEnvironment: env !== null,
            workingDirectory: workingDirectory || home
        });
    }

    // ── Persistence ─────────────────────────────────────────────────────

    // Written right away (atomically, off the UI thread): changes are rare
    // single actions, and a delayed write would be lost if the shell is
    // stopped in between.
    function save(): void {
        if (stateLoaded)
            writeState();
    }

    function isPlainObject(value: var): bool {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    // Accepts only well-formed parts of the file; anything else is dropped.
    function applyState(data: var): void {
        const nextPins = [];
        if (Array.isArray(data.pins))
            for (const id of data.pins)
                if (typeof id === "string" && !nextPins.includes(id))
                    nextPins.push(id);

        const nextHistory = {};
        if (isPlainObject(data.history))
            for (const id in data.history) {
                const h = data.history[id];
                if (isPlainObject(h) && Number.isFinite(h.count) && Number.isFinite(h.last))
                    nextHistory[id] = {
                        count: Math.max(0, Math.floor(h.count)),
                        last: h.last
                    };
            }

        const nextKnown = {};
        if (isPlainObject(data.known))
            for (const id in data.known)
                if (Number.isFinite(data.known[id]))
                    nextKnown[id] = data.known[id];

        pins = nextPins;
        history = nextHistory;
        known = nextKnown;
    }

    function finishLoading(): void {
        stateLoaded = true;
        // Duplicates prefer pinned ids, which are only known now.
        signature = "";
        rebuild();
        updateKnown();
    }

    Component.onCompleted: {
        rebuild();
        envProc.running = true;
        claudeCodeProc.running = true;
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged(): void {
            root.rebuild();
        }
    }

    FileView {
        id: stateFile

        path: root.statePath
        printErrors: false
        onLoaded: {
            let data = null;
            try {
                data = JSON.parse(text());
            } catch (e) {}
            if (root.isPlainObject(data)) {
                root.applyState(data);
            } else {
                // Keep the broken file for inspection and start empty.
                console.warn("Apps: launcher state is not valid JSON, starting fresh; old file kept as launcher.json.bak");
                backupFile.setText(text());
            }
            root.finishLoading();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.finishLoading();
                return;
            }
            // Don't overwrite a file that exists but couldn't be read: the
            // launcher works, but nothing is saved this session.
            console.warn("Apps: failed to read launcher state, not saving changes:", FileViewError.toString(error));
        }
    }

    FileView {
        id: backupFile

        path: root.statePath + ".bak"
        printErrors: false
        preload: false
    }

    // Coalesces bursts of changes into one write.
    function writeState(): void {
        stateFile.setText(JSON.stringify({
            pins: pins,
            history: history,
            known: known
        }, null, 2));
    }

    Process {
        id: envProc

        command: ["systemctl", "--user", "show-environment", "--output=json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const env = JSON.parse(text);
                    if (root.isPlainObject(env) && env.PATH)
                        root.sessionEnv = env;
                } catch (e) {}
            }
        }
    }

    Process {
        id: claudeCodeProc

        command: ["sh", "-c", "command -v claude"]
        onExited: exitCode => root.claudeCodeAvailable = exitCode === 0
    }
}
