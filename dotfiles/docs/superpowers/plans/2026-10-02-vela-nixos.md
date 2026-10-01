# vela auf NixOS – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** vela erkennt NixOS, schreibt dann seine Einstellungen in ein `state/`-Verzeichnis im NixOS-Repo und bietet einen „Apply & rebuild“-Button; dazu ein Nix-Paket mit Home-Manager-Modul, und Lunas Config stellt auf vela um.

**Architecture:** Neues Modul `src/nixos.rs` erkennt den Modus (os-release + Zeiger-Datei `~/.config/vela/nixos.toml`) einmal pro Prozess. `src/paths.rs` leitet `config_file`, `hypr_overrides_file`, `hypr_lua_file` im NixOS-Modus nach `state_dir` um – der Rest von vela bleibt unverändert. Die Settings zeigen ein `adw::Banner`, wenn `git status` im state_dir Änderungen meldet; der Button startet den Rebuild-Befehl im Terminal. `flake.nix` + `nix/hm-module.nix` paketieren vela und schreiben Zeiger, Service und `setup()`-Aufruf.

**Tech Stack:** Rust 2024 (gtk4-rs 0.11, libadwaita 0.9, serde/toml, shlex), Nix flakes, Home Manager (Hyprland `configType = "lua"`).

**Spec:** `docs/superpowers/specs/2026-10-02-vela-nixos-design.md`

## Global Constraints

- vela-Branch: `nixos-support` von `main` in `git@github.com:raindancer118/vela.git` (Arbeitskopie: Scratchpad `vela/`).
- Commits: keine Claude-/Co-Authored-By-Zeilen.
- vela-Code-Stil: `cargo fmt` mit vorhandener `rustfmt.toml`, `cargo clippy --all-targets -- -D warnings` muss sauber sein.
- Keine Shell mit Nutzertext: Rebuild-Befehl wird mit `shlex` gesplittet und als argv übergeben.
- GTK-Texte englisch (wie „Reload file“).
- Nicht-NixOS-Verhalten bleibt bitgleich: ohne Zeiger-Datei auf NixOS nur zusätzlicher Hinweis-Banner.
- Hyprland ≥ 0.55 mit Lua-Config; HM hängt `extraConfig` ans Ende der `hyprland.lua` (geprüft in HM `lib.nix`, `renderSection "extraConfig"` zuletzt).
- Kein `nixos-rebuild switch` durch den Agenten, nur `build`.

## Review Focus

1. `nixos.toml` mit relativem oder `~/…`-Pfad → muss als ungültig gelten (normaler Modus + Warnung), nicht still relativ zum cwd schreiben. Test in Task 2.
2. `state_dir` existiert noch nicht (frisches Repo) → vela legt es beim ersten Speichern an (`write_atomic` macht `create_dir_all`); `git status` auf nicht existentem Verzeichnis darf nicht panicen → Banner aus. Test in Task 3.
3. state_dir nicht in einem git-Repo / git fehlt → `dirty()` liefert `None`, Banner bleibt aus. Test in Task 3.
4. Rebuild-Befehl leer oder mit unbalancierten Quotes → klarer Fehler-Toast statt Absturz. Test in Task 3.
5. `/etc/os-release` mit `ID="nixos"` (quoted) oder `ID=nixos` mit Leerzeichen/CRLF → erkannt; `ID_LIKE=nixos` allein → nicht. Test in Task 2.

---

### Task 1: Nix-Flake mit Paket und devShell

**Files:**
- Create: `flake.nix`, `nix/package.nix`
- Modify: `.gitignore` (`result`, `result-*`)

**Interfaces:**
- Produces: `packages.x86_64-linux.default` (Binärdateien `bin/vela`, `bin/vela-daemon`, `share/vela/shell/**`, `share/vela/vela.lua`, Icons, Desktop-Datei); `devShells.x86_64-linux.default` mit cargo/clippy/rustfmt + GTK-Libs. Task 6 erweitert `flake.nix` um `homeManagerModules.default`.

- [ ] **Step 1: Branch anlegen**

```bash
cd vela && git switch -c nixos-support
```

- [ ] **Step 2: `nix/package.nix` schreiben**

```nix
{
  lib,
  rustPlatform,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  gtk4-layer-shell,
  quickshell,
  hypridle,
  hyprsunset,
  brightnessctl,
  xdg-utils,
}:
let
  cargo = (builtins.fromTOML (builtins.readFile ../Cargo.toml)).package;
in
rustPlatform.buildRustPackage {
  pname = "vela";
  inherit (cargo) version;
  src = lib.cleanSource ../.;
  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs = [ pkg-config wrapGAppsHook4 ];
  buildInputs = [ gtk4 libadwaita gtk4-layer-shell ];

  # Tests need a Wayland compositor / Hyprland; CI runs them on Arch.
  doCheck = false;

  postInstall = ''
    for icon in data/icons/*.svg; do
      install -Dm644 "$icon" "$out/share/icons/hicolor/scalable/apps/$(basename "$icon")"
    done
    sed "s|^Exec=vela|Exec=$out/bin/vela|" data/vela.desktop \
      | install -Dm644 /dev/stdin "$out/share/applications/vela.desktop"
    install -Dm644 contrib/hyprland/vela.lua "$out/share/vela/vela.lua"
    (cd shell && find . -type f \( -name '*.qml' -o -name '*.svg' \) ! -name 'test-*' \
      -exec install -Dm644 {} "$out/share/vela/shell/{}" \;)
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ quickshell hypridle hyprsunset brightnessctl xdg-utils ]})
  '';

  meta = {
    description = "Launcher, control center and every Hyprland setting";
    homepage = "https://github.com/Raindancer118/vela";
    license = lib.licenses.mit;
    mainProgram = "vela";
    platforms = lib.platforms.linux;
  };
}
```

- [ ] **Step 3: `flake.nix` schreiben**

```nix
{
  description = "vela: launcher, control center and every Hyprland setting";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: {
        default = pkgs.callPackage ./nix/package.nix { };
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          packages = with pkgs; [ cargo rustc clippy rustfmt ];
        };
      });
    };
}
```

- [ ] **Step 4: Bauen**

Run: `git add -A && nix build .#default -L && ls result/bin result/share/vela && result/bin/vela --version`
Expected: `vela vela 0.28.2` (o. ä.), `result/share/vela/shell/shell.qml` und `result/share/vela/vela.lua` existieren.

- [ ] **Step 5: devShell-Baseline**

Run: `nix develop -c sh -c 'cargo fmt --check && cargo clippy --all-targets --locked -- -D warnings && cargo test --locked --lib'`
Expected: alles grün (Ausgangslage vor eigenen Änderungen; Tests, die Hyprland/Wayland brauchen, sind `live_*` und ignoriert bzw. skippen – falls einer ohne Hyprland fehlschlägt, notieren, nicht fixen).

- [ ] **Step 6: Commit**

```bash
printf 'result\nresult-*\n' >> .gitignore
git add flake.nix flake.lock nix/package.nix .gitignore
git commit -m "Nix flake: package and dev shell"
```

---

### Task 2: NixOS-Erkennung (`src/nixos.rs`)

**Files:**
- Create: `src/nixos.rs`
- Modify: `src/lib.rs` (`pub mod nixos;`)

**Interfaces:**
- Produces:
  - `pub struct NixosMode { pub state_dir: PathBuf, pub rebuild: String }`
  - `pub enum Status { NotNixos, Unconfigured, Active(NixosMode) }`
  - `pub fn detect(os_release: &str, pointer: Option<&str>) -> Status` (pointer = Inhalt von nixos.toml, falls vorhanden)
  - `pub fn status() -> &'static Status` (cached, liest `/etc/os-release` und `paths::config_dir().join("nixos.toml")`)
  - `pub fn active() -> Option<&'static NixosMode>`
  - `pub fn pointer_file() -> PathBuf`

- [ ] **Step 1: Tests schreiben** (unten in `src/nixos.rs`)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    const NIXOS: &str = "NAME=NixOS\nID=nixos\nVERSION_ID=\"26.11\"\n";
    const ARCH: &str = "NAME=\"Arch Linux\"\nID=arch\n";
    const PTR: &str = "state_dir = \"/home/u/nixos/vela/state\"\nrebuild = \"rebuild --fast\"\n";

    #[test]
    fn not_nixos_ignores_the_pointer() {
        assert_eq!(detect(ARCH, Some(PTR)), Status::NotNixos);
    }

    #[test]
    fn id_like_alone_is_not_nixos() {
        assert_eq!(detect("ID=foo\nID_LIKE=nixos\n", Some(PTR)), Status::NotNixos);
    }

    #[test]
    fn quoted_and_crlf_ids_are_recognised() {
        assert!(matches!(detect("ID=\"nixos\"\r\n", Some(PTR)), Status::Active(_)));
        assert!(matches!(detect("  ID = nixos \n", Some(PTR)), Status::Active(_)));
    }

    #[test]
    fn nixos_without_pointer_is_unconfigured() {
        assert_eq!(detect(NIXOS, None), Status::Unconfigured);
    }

    #[test]
    fn broken_or_relative_pointer_is_unconfigured() {
        assert_eq!(detect(NIXOS, Some("state_dir = [")), Status::Unconfigured);
        assert_eq!(detect(NIXOS, Some("state_dir = \"nixos/state\"")), Status::Unconfigured);
        assert_eq!(detect(NIXOS, Some("state_dir = \"~/nixos/state\"")), Status::Unconfigured);
        assert_eq!(detect(NIXOS, Some("rebuild = \"x\"")), Status::Unconfigured);
    }

    #[test]
    fn valid_pointer_activates_with_default_rebuild() {
        assert_eq!(
            detect(NIXOS, Some("state_dir = \"/s\"")),
            Status::Active(NixosMode { state_dir: "/s".into(), rebuild: "sudo nixos-rebuild switch --flake .".into() })
        );
        assert_eq!(
            detect(NIXOS, Some(PTR)),
            Status::Active(NixosMode { state_dir: "/home/u/nixos/vela/state".into(), rebuild: "rebuild --fast".into() })
        );
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `nix develop -c cargo test --lib nixos::`
Expected: Compile-Fehler (`detect` fehlt).

- [ ] **Step 3: Implementierung**

```rust
//! NixOS with Home Manager: the module writes `~/.config/vela/nixos.toml`
//! naming a directory inside the user's NixOS repository. While it exists
//! (and the system is NixOS), vela keeps config.toml and its Hyprland
//! overrides there instead of ~/.config and ~/.local/state, so they are part
//! of the declarative configuration; Settings offers to commit and rebuild.

use serde::Deserialize;
use std::path::PathBuf;
use std::sync::OnceLock;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NixosMode {
    /// Absolute directory in the NixOS repository vela writes to.
    pub state_dir: PathBuf,
    /// Command run in a terminal by "Apply & rebuild".
    pub rebuild: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Status {
    NotNixos,
    /// NixOS, but the Home Manager module did not name a state directory.
    Unconfigured,
    Active(NixosMode),
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Pointer {
    state_dir: PathBuf,
    #[serde(default = "default_rebuild")]
    rebuild: String,
}

fn default_rebuild() -> String {
    "sudo nixos-rebuild switch --flake .".into()
}

fn is_nixos(os_release: &str) -> bool {
    os_release.lines().any(|line| {
        line.split_once('=')
            .is_some_and(|(k, v)| k.trim() == "ID" && v.trim().trim_matches('"') == "nixos")
    })
}

pub fn detect(os_release: &str, pointer: Option<&str>) -> Status {
    if !is_nixos(os_release) {
        return Status::NotNixos;
    }
    let Some(text) = pointer else {
        return Status::Unconfigured;
    };
    match toml::from_str::<Pointer>(text) {
        Ok(p) if p.state_dir.is_absolute() => Status::Active(NixosMode {
            state_dir: p.state_dir,
            rebuild: p.rebuild,
        }),
        Ok(p) => {
            log::warn!("{}: state_dir must be absolute, got {}", pointer_file().display(), p.state_dir.display());
            Status::Unconfigured
        }
        Err(e) => {
            log::warn!("{}: {e}", pointer_file().display());
            Status::Unconfigured
        }
    }
}

pub fn pointer_file() -> PathBuf {
    crate::paths::config_dir().join("nixos.toml")
}

pub fn status() -> &'static Status {
    static STATUS: OnceLock<Status> = OnceLock::new();
    STATUS.get_or_init(|| {
        let os = std::fs::read_to_string("/etc/os-release").unwrap_or_default();
        let ptr = std::fs::read_to_string(pointer_file()).ok();
        detect(&os, ptr.as_deref())
    })
}

pub fn active() -> Option<&'static NixosMode> {
    match status() {
        Status::Active(m) => Some(m),
        _ => None,
    }
}
```

Plus `pub mod nixos;` in `src/lib.rs` (alphabetisch nach `mcp`).

- [ ] **Step 4: Tests grün**

Run: `nix develop -c cargo test --lib nixos::`
Expected: 6 passed.

- [ ] **Step 5: Commit**

```bash
git add src/nixos.rs src/lib.rs
git commit -m "Detect NixOS with a Home Manager state directory"
```

---

### Task 3: Pfadumleitung, git-Status, Rebuild-Spec

**Files:**
- Modify: `src/paths.rs` (die drei Pfadfunktionen)
- Modify: `src/nixos.rs` (`dirty`, `porcelain_dirty`, `rebuild_spec`)

**Interfaces:**
- Consumes: `nixos::active()`, `launch::{SpawnSpec, LaunchError, in_terminal}`, `config::Terminal`.
- Produces:
  - `paths::config_file()`, `paths::hypr_overrides_file()`, `paths::hypr_lua_file()` (Signatur unverändert, Ziel umgeleitet)
  - `fn in_state_dir(mode: Option<&NixosMode>, name: &str, default: PathBuf) -> PathBuf` (privat in paths.rs)
  - `pub fn porcelain_dirty(stdout: &str) -> bool`
  - `pub fn dirty(mode: &NixosMode) -> Option<bool>` – `None`: kein git / kein Repo / Verzeichnis fehlt
  - `pub fn rebuild_spec(mode: &NixosMode, term: &Terminal) -> Result<SpawnSpec, LaunchError>`

- [ ] **Step 1: Tests schreiben**

In `src/paths.rs` (vorhandenes `#[cfg(test)] mod tests` erweitern, sonst anlegen):

```rust
#[test]
fn state_dir_redirects_vela_files_only_in_nixos_mode() {
    let mode = crate::nixos::NixosMode { state_dir: "/repo/vela".into(), rebuild: "rebuild".into() };
    assert_eq!(in_state_dir(Some(&mode), "config.toml", "/home/u/.config/vela/config.toml".into()), PathBuf::from("/repo/vela/config.toml"));
    assert_eq!(in_state_dir(None, "config.toml", "/home/u/.config/vela/config.toml".into()), PathBuf::from("/home/u/.config/vela/config.toml"));
}
```

In `src/nixos.rs` tests:

```rust
use crate::config::Terminal;

fn mode(dir: &std::path::Path, rebuild: &str) -> NixosMode {
    NixosMode { state_dir: dir.to_path_buf(), rebuild: rebuild.into() }
}

fn term() -> Terminal {
    Terminal { executable: "/bin/sh".into(), exec_args: Some(vec!["-e".into()]) }
}

#[test]
fn porcelain_output_means_dirty() {
    assert!(!porcelain_dirty(""));
    assert!(!porcelain_dirty("\n"));
    assert!(porcelain_dirty(" M config.toml\n"));
    assert!(porcelain_dirty("?? hyprland.lua\n"));
}

#[test]
fn dirty_is_unknown_outside_a_repository_or_without_the_directory() {
    let dir = tempfile::tempdir().unwrap();
    assert_eq!(dirty(&mode(dir.path(), "rebuild")), None);
    assert_eq!(dirty(&mode(&dir.path().join("missing"), "rebuild")), None);
}

#[test]
fn dirty_follows_git_status_of_the_state_dir() {
    let repo = tempfile::tempdir().unwrap();
    let git = |args: &[&str]| {
        assert!(std::process::Command::new("git").arg("-C").arg(repo.path()).args(args).status().unwrap().success());
    };
    git(&["init", "-q"]);
    git(&["config", "user.email", "t@t"]);
    git(&["config", "user.name", "t"]);
    let state = repo.path().join("vela");
    std::fs::create_dir(&state).unwrap();
    std::fs::write(repo.path().join("other.nix"), "{}").unwrap();
    // Changes outside the state directory don't count.
    assert_eq!(dirty(&mode(&state, "rebuild")), Some(false));
    std::fs::write(state.join("config.toml"), "x").unwrap();
    assert_eq!(dirty(&mode(&state, "rebuild")), Some(true));
    git(&["add", "-A"]);
    git(&["commit", "-qm", "c"]);
    assert_eq!(dirty(&mode(&state, "rebuild")), Some(false));
}

#[test]
fn rebuild_runs_split_words_in_the_terminal_and_waits() {
    let dir = tempfile::tempdir().unwrap();
    let spec = rebuild_spec(&mode(dir.path(), "rebuild 'vela: apply'"), &term()).unwrap();
    assert_eq!(spec.argv[..2], ["/bin/sh".to_owned(), "-e".to_owned()]);
    assert_eq!(spec.argv[2], "sh");
    assert_eq!(spec.argv[3], "-c");
    assert_eq!(spec.argv[4], WAIT_SCRIPT);
    assert_eq!(spec.argv[5..], ["sh".to_owned(), "rebuild".to_owned(), "vela: apply".to_owned()]);
    assert_eq!(spec.cwd.as_deref(), Some(dir.path()));
}

#[test]
fn empty_or_unbalanced_rebuild_command_is_an_error() {
    let dir = tempfile::tempdir().unwrap();
    assert!(matches!(rebuild_spec(&mode(dir.path(), "  "), &term()), Err(LaunchError::InvalidExec(_))));
    assert!(matches!(rebuild_spec(&mode(dir.path(), "rebuild 'x"), &term()), Err(LaunchError::InvalidExec(_))));
}
```

- [ ] **Step 2: Fehlschlag prüfen**

Run: `nix develop -c cargo test --lib -- nixos:: paths::`
Expected: Compile-Fehler (`in_state_dir`, `dirty`, `rebuild_spec`, `WAIT_SCRIPT` fehlen).

- [ ] **Step 3: Implementierung `src/paths.rs`**

```rust
/// In NixOS mode (see `nixos`) vela's own files live in the state
/// directory of the user's NixOS repository.
fn in_state_dir(mode: Option<&crate::nixos::NixosMode>, name: &str, default: PathBuf) -> PathBuf {
    match mode {
        Some(m) => m.state_dir.join(name),
        None => default,
    }
}

pub fn config_file() -> PathBuf {
    in_state_dir(crate::nixos::active(), "config.toml", config_dir().join("config.toml"))
}

/// vela's Hyprland overrides (Settings → Hyprland, `vela mcp`).
pub fn hypr_overrides_file() -> PathBuf {
    in_state_dir(crate::nixos::active(), "hyprland.toml", config_dir().join("hyprland.toml"))
}

/// The Lua generated from them; contrib/hyprland/vela.lua loads this path
/// (in NixOS mode the Home Manager module passes it as `settings_file`).
pub fn hypr_lua_file() -> PathBuf {
    in_state_dir(crate::nixos::active(), "hyprland.lua", state_dir().join("hyprland.lua"))
}
```

- [ ] **Step 4: Implementierung `src/nixos.rs`**

```rust
use crate::config::Terminal;
use crate::launch::{self, LaunchError, SpawnSpec};
use std::process::{Command, Stdio};

/// Runs the command given as arguments and keeps the terminal open so its
/// result (and a sudo prompt) can be read.
pub const WAIT_SCRIPT: &str = r#""$@"; s=$?; echo; if [ "$s" -eq 0 ]; then echo "vela: rebuild finished"; else echo "vela: rebuild failed ($s)"; fi; printf 'Press Enter to close '; read -r _"#;

pub fn porcelain_dirty(stdout: &str) -> bool {
    stdout.lines().any(|l| !l.trim().is_empty())
}

/// Whether the state directory has changes git hasn't committed yet.
/// None if that can't be told (no git, no repository, no directory).
pub fn dirty(mode: &NixosMode) -> Option<bool> {
    if !mode.state_dir.is_dir() {
        return None;
    }
    let out = Command::new("git")
        .arg("-C")
        .arg(&mode.state_dir)
        .args(["status", "--porcelain", "--untracked-files=all", "--", "."])
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    out.status.success().then(|| porcelain_dirty(&String::from_utf8_lossy(&out.stdout)))
}

/// `terminal [exec args] sh -c WAIT_SCRIPT sh <rebuild words…>`
pub fn rebuild_spec(mode: &NixosMode, term: &Terminal) -> Result<SpawnSpec, LaunchError> {
    let words = shlex::split(&mode.rebuild)
        .filter(|w| !w.is_empty())
        .ok_or_else(|| LaunchError::InvalidExec(format!("rebuild command “{}”", mode.rebuild)))?;
    let mut command = vec!["sh".to_owned(), "-c".to_owned(), WAIT_SCRIPT.to_owned(), "sh".to_owned()];
    command.extend(words);
    Ok(SpawnSpec {
        argv: launch::in_terminal(term, command)?,
        cwd: Some(mode.state_dir.clone()),
        env: Vec::new(),
        name: "vela-rebuild".into(),
    })
}
```

(`shlex::split("  ")` liefert `Some([])` → `filter` macht daraus `None` → InvalidExec.)

- [ ] **Step 5: Tests grün + gesamte Suite**

Run: `nix develop -c sh -c 'cargo test --lib -- nixos:: paths:: && cargo test --locked --lib'`
Expected: alle neuen Tests grün, keine Regression gegenüber Task-1-Baseline.

- [ ] **Step 6: Commit**

```bash
git add src/paths.rs src/nixos.rs
git commit -m "NixOS mode: keep config and Hyprland overrides in the repository"
```

---

### Task 4: Banner in den Settings

**Files:**
- Modify: `src/ui/settings/mod.rs` (nach `hypr_banner`, ~Zeile 176)

**Interfaces:**
- Consumes: `nixos::{status, Status, dirty, rebuild_spec}`, `daemon.store.get().terminal`, `daemon.store.subscribe`, `daemon.hypr.subscribe`, `launch::spawn_detached`, `toasts: adw::ToastOverlay`.

- [ ] **Step 1: Prüfen, wie die Terminal-Config erreichbar ist**

Run: `grep -n "pub terminal" src/config.rs`
Expected: Feld `terminal: Terminal` in `Config`. (Falls anders benannt, den Namen unten anpassen.)

- [ ] **Step 2: Banner einbauen** (nach dem `hypr_banner`-Block; `toasts` wird davor erzeugt – die Zeile `let toasts = adw::ToastOverlay::new();` vor diesen Block ziehen)

```rust
        // NixOS: offer to commit and rebuild what vela changed in the repository.
        let nixos_banner = adw::Banner::new("");
        match crate::nixos::status() {
            crate::nixos::Status::Active(mode) => {
                nixos_banner.set_title("Changes not yet applied to NixOS");
                nixos_banner.set_button_label(Some("Apply & rebuild"));
                let refresh = {
                    let b = nixos_banner.clone();
                    move || b.set_revealed(crate::nixos::dirty(mode) == Some(true))
                };
                refresh();
                // Saves happen shortly after a change; look again once they're written.
                let pending: Rc<RefCell<Option<glib::SourceId>>> = Rc::default();
                let later = {
                    let refresh = refresh.clone();
                    move || {
                        if let Some(id) = pending.borrow_mut().take() {
                            id.remove();
                        }
                        let (refresh, slot) = (refresh.clone(), pending.clone());
                        *pending.borrow_mut() = Some(glib::timeout_add_local_once(Duration::from_millis(1500), move || {
                            slot.borrow_mut().take();
                            refresh();
                        }));
                    }
                };
                {
                    let later = later.clone();
                    daemon.store.subscribe(move |_, _| later());
                }
                daemon.hypr.subscribe(move |_| later());
                // Coming back from the rebuild terminal.
                window.connect_is_active_notify(move |w| {
                    if w.is_active() {
                        refresh();
                    }
                });
                let (store, toasts_c) = (daemon.store.clone(), toasts.clone());
                nixos_banner.connect_button_clicked(move |_| {
                    let result = crate::nixos::rebuild_spec(mode, &store.get().terminal)
                        .and_then(|spec| launch::spawn_detached(&spec, false));
                    if let Err(e) = result {
                        toasts_c.add_toast(adw::Toast::new(&format!("Rebuild: {e}")));
                    }
                });
            }
            crate::nixos::Status::Unconfigured => {
                nixos_banner.set_title("NixOS detected: changes are not saved to your NixOS configuration (see README → NixOS)");
                nixos_banner.set_revealed(true);
            }
            crate::nixos::Status::NotNixos => {}
        }
```

`content_view.add_top_bar(&nixos_banner);` nach `add_top_bar(&hypr_banner)`.
Imports oben ergänzen, soweit nicht vorhanden: `std::cell::RefCell`, `std::time::Duration`, `crate::launch`.

Hinweis zum Closure: `later` muss `Clone` sein und `pending` teilen – `pending` als `Rc` vor `later` klonen:
`let later = { let refresh = refresh.clone(); let pending = pending.clone(); move || { … } };` mit `pending` im Body. `refresh` braucht `Clone` (Banner-Klon ist `Clone`, also ist die Closure es).

- [ ] **Step 3: Kompilieren, fmt, clippy**

Run: `nix develop -c sh -c 'cargo fmt && cargo clippy --all-targets --locked -- -D warnings'`
Expected: sauber.

- [ ] **Step 4: Manueller Test (Nicht-NixOS-Pfad bleibt gleich, NixOS-Pfad)**

```bash
nix build .#default
mkdir -p /tmp/velatest/repo/state && git -C /tmp/velatest/repo init -q
XDG_CONFIG_HOME=/tmp/velatest/cfg; mkdir -p $XDG_CONFIG_HOME/vela
printf 'state_dir = "/tmp/velatest/repo/state"\nrebuild = "echo rebuild-ok"\n' > $XDG_CONFIG_HOME/vela/nixos.toml
VELA_SOCKET=/tmp/velatest/vela.sock XDG_CONFIG_HOME=$XDG_CONFIG_HOME result/bin/vela-daemon &
VELA_SOCKET=/tmp/velatest/vela.sock result/bin/vela settings
```
Expected: `/tmp/velatest/repo/state/config.toml` entsteht, Banner „Changes not yet applied to NixOS“ sichtbar; Klick öffnet Ghostty mit `rebuild-ok` + „Press Enter to close“. Nach `git -C /tmp/velatest/repo add -A && git commit -m x` und Fokus zurück → Banner weg. Ohne nixos.toml: Hinweis-Banner „NixOS detected…“. Daemon danach beenden.

- [ ] **Step 5: Commit**

```bash
git add src/ui/settings/mod.rs
git commit -m "Settings: Apply & rebuild banner in NixOS mode"
```

---

### Task 5: `vela.lua` – Option `settings_file`

**Files:**
- Modify: `contrib/hyprland/vela.lua` (defaults + `if o.settings`-Block)

- [ ] **Step 1: Default ergänzen** (nach `settings = true,`)

```lua
    -- Lua file with those settings; nil = $XDG_STATE_HOME/vela/hyprland.lua.
    -- The NixOS Home Manager module points it into your repository.
    settings_file = nil,
```

- [ ] **Step 2: Laden anpassen**

```lua
    if o.settings then
        local generated = o.settings_file
        if not generated then
            local state = os.getenv("XDG_STATE_HOME")
            if not state or state == "" then state = os.getenv("HOME") .. "/.local/state" end
            generated = state .. "/vela/hyprland.lua"
        end
        if exists(generated) then
            local ok, err = pcall(dofile, generated)
            if not ok then print("vela: " .. tostring(err)) end
        end
    end
```

- [ ] **Step 3: Syntax prüfen**

Run: `nix shell nixpkgs#lua -c luac -p contrib/hyprland/vela.lua`
Expected: keine Ausgabe.

- [ ] **Step 4: Commit**

```bash
git add contrib/hyprland/vela.lua
git commit -m "vela.lua: settings_file option"
```

---

### Task 6: Home-Manager-Modul + README

**Files:**
- Create: `nix/hm-module.nix`
- Modify: `flake.nix` (`homeManagerModules.default`), `README.md` (Abschnitt NixOS unter „Get it“)

**Interfaces:**
- Consumes: `self.packages.<system>.default` (Task 1), `settings_file` (Task 5), Zeiger-Format (Task 2).
- Produces: `programs.vela.{enable, package, panelPeek, nixos.stateDir, nixos.rebuildCommand}`.

- [ ] **Step 1: `nix/hm-module.nix`**

```nix
self:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.vela;
  inherit (lib) mkOption mkEnableOption mkIf types;
  setupArgs = {
    binary = lib.getExe cfg.package;
  }
  // lib.optionalAttrs (cfg.nixos.stateDir != null) { settings_file = "${cfg.nixos.stateDir}/hyprland.lua"; }
  // lib.optionalAttrs (cfg.panelPeek != null) { panel_peek = cfg.panelPeek; };
in
{
  options.programs.vela = {
    enable = mkEnableOption "vela, launcher and control center for Hyprland";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "vela.packages.\${system}.default";
    };
    panelPeek = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "SUPER + B";
      description = "Shortcut for the control center: a tap toggles it, holding peeks.";
    };
    nixos = {
      stateDir = mkOption {
        type = types.nullOr (types.strMatching "/.*");
        default = null;
        example = "/home/me/nixos/home/me/vela";
        description = ''
          Absolute path of a directory in your NixOS repository. vela then keeps
          config.toml and its Hyprland settings there, and Settings offers
          "Apply & rebuild". A string, not a Nix path: vela writes to it.
        '';
      };
      rebuildCommand = mkOption {
        type = types.str;
        default = "sudo nixos-rebuild switch --flake .";
        example = "rebuild";
        description = "Run in a terminal, in stateDir, by \"Apply & rebuild\".";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ (with pkgs; [ material-symbols rubik papirus-icon-theme ]);

    systemd.user.services.vela = {
      Unit = {
        Description = "vela application launcher";
        Documentation = "https://github.com/Raindancer118/vela";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/vela-daemon";
        Restart = "on-abnormal";
        RestartSec = 1;
        KillMode = "process";
        Environment = [ "RUST_LOG=vela=info" ];
      };
    };

    xdg.configFile."vela/nixos.toml" = mkIf (cfg.nixos.stateDir != null) {
      text = ''
        state_dir = ${builtins.toJSON cfg.nixos.stateDir}
        rebuild = ${builtins.toJSON cfg.nixos.rebuildCommand}
      '';
    };

    wayland.windowManager.hyprland.extraConfig = ''
      -- vela: Super tap, control center, idle and vela's Hyprland settings (last, so they win)
      dofile("${cfg.package}/share/vela/vela.lua").setup(${lib.generators.toLua { } setupArgs})
    '';
  };
}
```

(`builtins.toJSON` eines Strings ist ein gültiger TOML-Basic-String.)

- [ ] **Step 2: `flake.nix` ergänzen** (in `outputs`, neben `packages`)

```nix
      homeManagerModules.default = import ./nix/hm-module.nix self;
```

- [ ] **Step 3: README-Abschnitt** (nach den bestehenden Install-Varianten unter „Get it“)

````markdown
### NixOS (Home Manager)

```nix
# flake.nix
inputs.vela = {
  url = "github:Raindancer118/vela";
  inputs.nixpkgs.follows = "nixpkgs";
};

# home.nix
imports = [ inputs.vela.homeManagerModules.default ];
programs.vela = {
  enable = true;
  panelPeek = "SUPER + B";
  # Optional: keep vela's settings in your NixOS repository
  nixos.stateDir = "/home/me/nixos/home/me/vela";
  nixos.rebuildCommand = "sudo nixos-rebuild switch --flake /home/me/nixos#host";
};
```

Needs `wayland.windowManager.hyprland.configType = "lua"`. The module adds
the `setup()` call at the end of your hyprland.lua, the user service and
`~/.config/vela/nixos.toml`. On NixOS with `nixos.stateDir` set, vela keeps
`config.toml`, `hyprland.toml` and `hyprland.lua` in that directory instead
of `~/.config/vela` and `~/.local/state/vela`; changes still apply live, and
Settings shows **Apply & rebuild** while git reports uncommitted changes
there. Without it, vela works as everywhere else and says so in Settings.
The MCP server is registered with `claude mcp add --scope user vela -- vela mcp`.
````

- [ ] **Step 4: Prüfen**

Run: `nix flake check -L && nix eval .#homeManagerModules.default --apply builtins.isFunction`
Expected: `check` ohne Fehler, `true`.

- [ ] **Step 5: Commit**

```bash
git add nix/hm-module.nix flake.nix README.md
git commit -m "Home Manager module with NixOS mode; README: NixOS"
```

---

### Task 7: Branch pushen

- [ ] **Step 1:** `git push -u origin nixos-support`
Expected: Branch auf GitHub. (Kein PR ohne Rückfrage.)

---

### Task 8: Lunas Config auf vela umstellen

**Files (in `/home/luna/nixos/dotfiles`):**
- Modify: `flake.nix` (Input `vela`, Input `quickpanel` raus), `flake.lock`
- Create: `home/luna/modules/vela/default.nix`, `home/luna/modules/vela/state/.gitkeep`
- Modify: `home/luna/home.nix` (Import `./modules/quickshell` → `./modules/vela`)
- Modify: `home/luna/modules/default-hyprland/default.nix` (`./wofi.nix` raus)
- Delete: `home/luna/modules/quickshell/`, `home/luna/modules/default-hyprland/wofi.nix`, `flakes/Quickpanel/`

- [ ] **Step 1: Abhängigkeiten prüfen, bevor etwas gelöscht wird**

Run: `grep -rn "quickshell\|qs ipc\|qs-claude\|wofi\|quickpanel" --include=*.nix . | grep -v "^./flakes/Quickpanel\|^./home/luna/modules/quickshell/"`
Expected: Nur Treffer in `flake.nix` (Input), `home.nix` (Import), `default-hyprland/default.nix` (wofi-Import), ggf. `binds.nix`-Kommentar. Jeder andere Treffer (z. B. Bind auf `qs ipc` oder `wofi`) wird in diesem Task mit entfernt bzw. auf vela umgestellt (`vela toggle` / `vela panel toggle`).
Außerdem: Pakete aus `modules/quickshell/default.nix` `home.packages`, die außerhalb gebraucht werden (z. B. `brightnessctl` für XF86-Brightness-Binds in `binds.nix`), nach `home/luna/modules/vela/default.nix` übernehmen.

- [ ] **Step 2: `home/luna/modules/vela/default.nix`**

```nix
{ inputs, username, ... }:
{
  imports = [ inputs.vela.homeManagerModules.default ];

  programs.vela = {
    enable = true;
    # Wie vorher das Quickshell-Panel; Launcher: Super antippen.
    panelPeek = "SUPER + B";
    nixos = {
      # String, kein Nix-Pfad: vela schreibt hier hinein.
      stateDir = "/home/${username}/nixos/dotfiles/home/${username}/modules/vela/state";
      rebuildCommand = "rebuild vela";
    };
  };
}
```

(`rebuild vela` → Lunas Script committet mit Message „vela“ und rebuildet.)

- [ ] **Step 3: flake.nix** – `quickpanel`-Block entfernen, ergänzen:

```nix
    vela = {
      url = "github:raindancer118/vela/nixos-support";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 4: home.nix / default-hyprland/default.nix** – Importe tauschen bzw. entfernen; Verzeichnisse/Dateien aus „Delete“ mit `git rm -r` entfernen; `touch home/luna/modules/vela/state/.gitkeep`.

- [ ] **Step 5: Lock + Build**

Run: `cd /home/luna/nixos/dotfiles && nix flake lock && git add -A && nixos-rebuild build --flake .#nixos`
Expected: Build erfolgreich, `result` zeigt auf neues System. `grep -c "share/vela/vela.lua" result/…` ist nicht nötig; stattdessen:
`nix eval .#nixosConfigurations.nixos.config.home-manager.users.luna.xdg.configFile.\"vela/nixos.toml\".text`
Expected: `state_dir = "/home/luna/nixos/dotfiles/home/luna/modules/vela/state"` …

- [ ] **Step 6: Commit (lokal, kein Push ohne Rückfrage, kein switch)**

```bash
git -C /home/luna/nixos add -A
git -C /home/luna/nixos commit -m "Replace Quickshell launcher/panel and wofi with vela"
```

Danach Luna: `rebuild` ausführen, neu einloggen (Hyprland-Config + Services ändern sich).
