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
    rebuild = "sudo nixos-rebuild switch --flake ${dotfilesPath}#nixos";
    update = "cd ${dotfilesPath} && nix flake update && cd -";

    garbage = "sudo nix-collect-garbage";
    clear_efi = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5";
    clean = ''
      sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 &&
      sudo nix-collect-garbage
    '';
  };

  environment.systemPackages = [
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
        # Prüfen ob bereits im AUTO Block
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
