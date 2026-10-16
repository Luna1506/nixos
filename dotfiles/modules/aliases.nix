{ pkgs, username, luna-path, ... }:

let
  homeDir = "/home/${username}";
  dotfilesAbs = "${homeDir}/nixos/dotfiles";
  dotfilesPath =
    if luna-path
    then dotfilesAbs
    else "./dotfiles";
in
{
  environment.shellAliases = {
    # rebuild alias bewusst entfernt, damit das rebuild-Script greift
    update = "cd ${dotfilesPath} && nix flake update && cd -";

    garbage = "sudo nix-collect-garbage";
    clear_efi = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5";
    clean = ''
      sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 &&
      sudo nix-collect-garbage
    '';
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      set -euo pipefail

      DOTFILES_PATH="${dotfilesPath}"
      NIXOS_DIR="$HOME/nixos"

      cd "$NIXOS_DIR"

      git add .

      # Nur committen wenn staged changes existieren
      if ! git diff --cached --quiet; then
        # Wenn Argument(e) da sind und nicht leer -> nutze sie, sonst lässt
        # Claude (Haiku) aus dem Diff eine kurze Message schreiben
        if [ $# -gt 0 ] && [ -n "$*" ]; then
          MESSAGE="$*"
        else
          echo "Commit-Message wird generiert..."
          MESSAGE="$(
            { git diff --cached --stat; echo; git diff --cached | head -c 30000; } |
              timeout 60 claude -p --model haiku "Schreibe für den folgenden Git-Diff einer NixOS-Konfiguration eine Commit-Message auf Deutsch: eine Zeile, höchstens 72 Zeichen, grob was geändert wurde (z. B. \"Spotify-Shortcuts und Zen-Autostart hinzugefügt\"). Keine Anführungszeichen, kein Präfix, keine Erklärung – gib nur die Message aus." 2>/dev/null |
              head -n 1 || true
          )"
          # Fallback ohne claude/Netz: geänderte Dateien
          if [ -z "$MESSAGE" ]; then
            MESSAGE="Geändert: $(git diff --cached --name-only | xargs -n1 basename | sort -u | head -n 5 | paste -sd ',' | sed 's/,/, /g')"
          fi
        fi

        git commit -m "$MESSAGE"
      else
        echo "Keine Änderungen zum Committen."
      fi

      sudo nixos-rebuild switch --flake "$DOTFILES_PATH#nixos"
    '')

    # Aktualisiert den vela-Input und baut das System im Hintergrund (User-Unit
    # vela-update). Ohne WLAN wird der laufende Schritt abgebrochen und nach dem
    # Reconnect neu gestartet; fertige Store-Pfade bleiben, es geht also dort weiter.
    # Umschalten danach wie immer mit rebuild (braucht sudo).
    (pkgs.writeShellScriptBin "vela-update" ''
      set -euo pipefail

      if [ "''${1:-}" != "--worker" ]; then
        systemctl --user reset-failed vela-update 2>/dev/null || true
        if ! systemd-run --user --unit=vela-update --collect --quiet \
          --setenv=PATH="$PATH" "$(readlink -f "$0")" --worker; then
          echo "vela-update läuft schon? Status: systemctl --user status vela-update"
          exit 1
        fi
        echo "vela-update läuft im Hintergrund. Log: journalctl --user -fu vela-update"
        exit 0
      fi

      DOTFILES_PATH="${dotfilesAbs}"
      JQ=${pkgs.jq}/bin/jq

      notify() { ${pkgs.libnotify}/bin/notify-send -a vela-update "vela-update" "$1" || true; }
      online() { [ "$(nmcli -t networking connectivity 2>/dev/null)" = full ]; }
      trap 'notify "Fehlgeschlagen – journalctl --user -u vela-update"' ERR

      # Führt den Befehl aus, solange WLAN da ist; bricht ohne WLAN ab und
      # startet ihn nach dem Reconnect neu.
      run_online() {
        local pid
        while true; do
          if ! online; then
            echo "Kein WLAN – pausiert"
            notify "Kein WLAN – pausiert, geht bei Verbindung weiter"
            until online; do sleep 10; done
            echo "WLAN wieder da – weiter"
            notify "WLAN wieder da – geht weiter"
          fi

          setsid "$@" &
          pid=$!
          while kill -0 "$pid" 2>/dev/null; do
            if ! online; then
              kill -TERM -- "-$pid" 2>/dev/null || true
              break
            fi
            sleep 5
          done
          if wait "$pid"; then return 0; fi
          online || continue
          return 1
        done
      }

      cd "$DOTFILES_PATH"
      old=$($JQ -r .nodes.vela.locked.rev flake.lock)
      run_online nix flake update vela
      new=$($JQ -r .nodes.vela.locked.rev flake.lock)

      if [ "$old" = "$new" ]; then
        echo "Kein vela-Update (''${old:0:7})"
        notify "Kein Update – vela ist aktuell"
        exit 0
      fi

      src=$(nix flake prefetch --json "github:raindancer118/vela/$new" | $JQ -r .storePath)
      version=$(grep -m1 '^version' "$src/Cargo.toml" | cut -d'"' -f2)
      echo "vela ''${old:0:7} → ''${new:0:7} ($version)"

      # home/luna/modules/vela ersetzt den setup()-Aufruf per mkForce: neue
      # Argumente des Moduls müssen dort nachgezogen werden.
      known="binary settings_file components_file panel_peek keycodes"
      missing=""
      for arg in $(awk '/setupArgs = \{/{f=1; next} f{print} f&&/\};[[:space:]]*$/{exit}' "$src/nix/hm-module.nix" \
        | grep -oE '[a-z_]+ =' | cut -d' ' -f1 | sort -u); do
        case " $known " in *" $arg "*) ;; *) missing="$missing $arg" ;; esac
      done
      if [ -n "$missing" ]; then
        echo "WARNUNG: neue setup()-Argumente:$missing – in home/luna/modules/vela/default.nix nachziehen"
        notify "Neue setup()-Argumente:$missing – vela/default.nix anpassen"
      fi

      run_online nix build --no-link ".#nixosConfigurations.nixos.config.system.build.toplevel"

      echo "Fertig gebaut. Umschalten mit: rebuild"
      notify "vela $version gebaut – zum Umschalten: rebuild"
    '')

    (pkgs.writeShellScriptBin "install" ''
      set -euo pipefail

      if [ $# -lt 1 ]; then
        echo "Usage: install <paketname> [weitere...]"
        exit 1
      fi

      DOTFILES_PATH="${dotfilesPath}"
      PACKAGES_FILE="$DOTFILES_PATH/modules/packages.nix"

      if [ ! -f "$PACKAGES_FILE" ]; then
        echo "Fehler: $PACKAGES_FILE nicht gefunden"
        exit 1
      fi

      for pkg in "$@"; do
        if awk '
          $0 ~ /# BEGIN AUTO PACKAGES/ {inblock=1; next}
          $0 ~ /# END AUTO PACKAGES/   {inblock=0}
          inblock {print}
        ' "$PACKAGES_FILE" | sed -E 's/^[[:space:]]+//' | grep -qx "$pkg"; then
          echo "Schon vorhanden: $pkg"
          continue
        fi

        tmp="$(mktemp)"
        awk -v pkg="$pkg" '
          /# END AUTO PACKAGES/ {
            print "    " pkg
            print
            next
          }
          { print }
        ' "$PACKAGES_FILE" > "$tmp"
        mv "$tmp" "$PACKAGES_FILE"

        echo "Hinzugefügt: $pkg"
      done

      sudo nixos-rebuild switch --flake "$DOTFILES_PATH#nixos"
    '')

    (pkgs.writeShellScriptBin "remove" ''
      set -euo pipefail

      if [ $# -lt 1 ]; then
        echo "Usage: remove <paketname> [weitere...]"
        exit 1
      fi

      DOTFILES_PATH="${dotfilesPath}"
      PACKAGES_FILE="$DOTFILES_PATH/modules/packages.nix"

      if [ ! -f "$PACKAGES_FILE" ]; then
        echo "Fehler: $PACKAGES_FILE nicht gefunden"
        exit 1
      fi

      for pkg in "$@"; do
        tmp="$(mktemp)"
        awk -v pkg="$pkg" '
          $0 ~ /# BEGIN AUTO PACKAGES/ {inblock=1; print; next}
          $0 ~ /# END AUTO PACKAGES/   {inblock=0; print; next}

          inblock {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            if (line == pkg) next
          }

          { print }
        ' "$PACKAGES_FILE" > "$tmp"
        mv "$tmp" "$PACKAGES_FILE"

        echo "Entfernt (falls vorhanden): $pkg"
      done

      sudo nixos-rebuild switch --flake "$DOTFILES_PATH#nixos"
    '')
  ];
}
