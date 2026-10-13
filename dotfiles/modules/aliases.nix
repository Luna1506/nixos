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
