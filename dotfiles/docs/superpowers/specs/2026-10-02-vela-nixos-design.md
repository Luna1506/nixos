# vela auf NixOS – Design

## Ziel

vela (github.com/raindancer118/vela) ersetzt den eigenen Quickshell-Launcher und
das Panel. Läuft vela auf einem per Home Manager konfigurierten NixOS, landen
alle Einstellungen, die vela schreibt, im NixOS-Repo statt in `~/.config` bzw.
`~/.local/state`. Ein Button in den vela-Settings löst den Rebuild aus.

Entschieden:

- **Ansatz A:** vela schreibt in ein festes `state/`-Verzeichnis im Repo. Es
  sucht nicht selbst, welches Modul eine Option setzt (das ist bei
  `wayland.windowManager.hyprland.settings` mit berechneten Werten nicht
  zuverlässig möglich).
- **Umfang:** Hyprland-Overrides (`hyprland.toml` + generiertes `hyprland.lua`)
  **und** vela's eigene `config.toml`.
- **Rebuild:** öffnet das konfigurierte Terminal mit dem konfigurierten Befehl
  (Default `rebuild`: git commit + `sudo nixos-rebuild switch`).
- waybar bleibt.

## 1. Erkennung (vela, `src/nixos.rs`)

NixOS-Modus ist aktiv genau dann, wenn

1. `/etc/os-release` eine Zeile `ID=nixos` (auch `ID="nixos"`) enthält, **und**
2. `$XDG_CONFIG_HOME/vela/nixos.toml` existiert und parst:

   ```toml
   state_dir = "/home/luna/nixos/dotfiles/home/luna/modules/vela/state"
   rebuild   = "rebuild"
   ```

   `state_dir` muss absolut sein. `rebuild` ist optional (Default `"rebuild"`).

Die Erkennung läuft einmal pro Prozess (`OnceLock`). Für Tests nimmt sie
os-release-Inhalt und Zeiger-Pfad als Parameter (`detect(os_release: &str,
pointer: &Path)`).

Fälle:

| System | Zeiger-Datei | Verhalten |
| --- | --- | --- |
| nicht NixOS | egal | wie heute |
| NixOS | fehlt / ungültig | wie heute + Hinweis-Banner in den Settings („NixOS erkannt: Änderungen landen nicht in deiner NixOS-Config“); ungültig zusätzlich `log::warn!` |
| NixOS | gültig | NixOS-Modus |

## 2. Pfadumleitung (`src/paths.rs`)

Im NixOS-Modus liefern

- `config_file()` → `state_dir/config.toml`
- `hypr_overrides_file()` → `state_dir/hyprland.toml`
- `hypr_lua_file()` → `state_dir/hyprland.lua`

Alles andere (`state_dir()` für history.json, hypridle.conf, Cache, Socket)
bleibt unverändert. `config_dir()` bleibt `~/.config/vela`, dort liegt nur der
Zeiger. Existiert `state_dir` nicht, legt vela es an (wie heute `~/.config/vela`).

## 3. Rebuild-Button (`src/ui/settings/mod.rs`)

- `adw::Banner` analog zum bestehenden „Reload file“-Banner, nur im NixOS-Modus.
- Sichtbar, wenn `git -C <state_dir> status --porcelain -- .` nicht leer ist.
  Geprüft beim Öffnen der Settings und nach jedem Speichern von HyprStore/
  ConfigStore (beide melden Saves bereits über Listener/FileMonitor). Kein git
  oder kein Repo → Banner nie sichtbar, `log::warn!` einmal.
- Text (die GTK-Oberfläche ist englisch, wie „Reload file“): „Changes not yet
  applied to NixOS“, Button „Apply & rebuild“.
- Klick: startet `[terminal].executable` aus vela's Config mit dem
  Rebuild-Befehl über den vorhandenen Launch-Code in `src/launch.rs`
  (SpawnSpec, kein `sh -c` mit Nutzertext). Der Befehl wird mit `shlex`
  gesplittet. Danach den Status neu prüfen, sobald das Terminal beendet ist
  (Child-Watch); bis dahin bleibt der Banner sichtbar.

## 4. `contrib/hyprland/vela.lua`

Neue Option `settings_file` (Default `nil` → bisheriger Pfad
`$XDG_STATE_HOME/vela/hyprland.lua`). Das HM-Modul setzt sie auf
`state_dir .. "/hyprland.lua"`. Sonst nichts geändert.

## 5. Nix-Paket + Home-Manager-Modul (vela-Repo)

`flake.nix` (inputs: nixpkgs) mit

- `packages.<system>.default`: `rustPlatform.buildRustPackage` aus
  `Cargo.lock`; nativeBuildInputs `pkg-config wrapGAppsHook4`; buildInputs
  `gtk4 libadwaita gtk4-layer-shell`. postInstall: Icons nach
  `share/icons/hicolor/scalable/apps`, `data/vela.desktop` (Exec auf
  `$out/bin/vela`), `shell/` ohne `test-*` nach `share/vela/shell`,
  `contrib/hyprland/vela.lua` nach `share/vela/vela.lua`. Wrapper ergänzt PATH um
  `quickshell` und `hypridle`. Tests im Build: `doCheck = false` (brauchen
  Wayland/Hyprland); CI testet weiter auf Arch.
- `homeManagerModules.default` (`nix/hm-module.nix`), Optionen unter
  `programs.vela`:
  - `enable`, `package` (Default: Paket aus dem Flake)
  - `panelPeek` (nullOr str, z. B. `"SUPER + B"`)
  - `nixos.stateDir` (nullOr str, absolut) – null → kein Zeiger, normaler Modus
  - `nixos.rebuildCommand` (str, Default `"rebuild"`)
  - Erzeugt: `home.packages`, `systemd.user.services.vela` (Inhalt wie
    `contrib/systemd/vela.service.in`: ExecStart `${pkg}/bin/vela-daemon`,
    PartOf/After `graphical-session.target`, kein WantedBy – vela.lua startet
    ihn per `systemctl --user restart vela.service`; `start_daemon()` findet ihn
    unter `~/.config/systemd/user`), `xdg.configFile."vela/nixos.toml"`
    (wenn stateDir gesetzt), `wayland.windowManager.hyprland.extraConfig` mit
    `dofile("${pkg}/share/vela/vela.lua").setup({ binary = …, settings_file = …,
    panel_peek = … })`.
- README: Abschnitt „NixOS“.

Nicht enthalten (YAGNI): MCP-Registrierung bei Claude Code (README nennt den
`claude mcp add`-Befehl), Arch-Paket-Änderungen.

## 6. Eigene Config (Luna1506/nixos, nach dem vela-Branch)

- Input `vela.url = "github:raindancer118/vela/nixos-support"`
  (`inputs.nixpkgs.follows = "nixpkgs"`).
- `home/luna/modules/vela/default.nix`: Modul importieren, `programs.vela`
  aktivieren, `nixos.stateDir = "/home/${username}/nixos/dotfiles/home/${username}/modules/vela/state"`.
- `home/luna/modules/vela/state/.gitkeep`.
- Entfernen: Import `./modules/quickshell` (Launcher SUPER+R, Panel SUPER+B,
  Benachrichtigungen, OSD), Input `quickpanel`, `wofi.nix`.
- Kein `exec`-Start von `qs`/hypridle mehr (vela startet beide).

## Tests

- Unit-Tests: `detect()` für alle drei Fälle aus der Tabelle (auch
  `ID="nixos"`, relativer state_dir → ungültig), Pfadumleitung, Parsen des
  git-Status.
- `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`,
  `cargo test` im vela-Repo.
- `nix build .#default` im vela-Repo; `nix flake check`.
- Eigene Config: `nixos-rebuild build --flake ./dotfiles#nixos` (kein switch).
