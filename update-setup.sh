#!/usr/bin/env bash
set -euo pipefail

REPO_DEFAULT="https://github.com/Luna1506/dotfiles/dotfiles.git"
DEST_DEFAULT="$HOME/dotfiles"
BRANCH_DEFAULT="main"

MONITOR_DEFAULT="eDP-1"
ZOOM_DEFAULT="1"   # string

usage() {
  cat <<'EOF'
Hard reset dotfiles installer.

Usage:
  bootstrap-dotfiles_hardreset.sh --username <name> [options]

Required:
  --username <name>

Options:
  --fullname "<Full Name>"
  --repo <url>                 (default: https://github.com/Luna1506/dotfiles.git)
  --dest <path>                (default: ~/dotfiles)
  --branch <name>              (default: main)
  --nvidia-alt <true|false>
  --monitor <name>             (default: eDP-1)
  --zoom <string>              (default: "1") e.g. "1.5" or "2.5"
  --no-first-run
  -h, --help
EOF
}

die(){ echo "Error: $*" >&2; exit 1; }

USERNAME=""
FULLNAME=""
REPO="$REPO_DEFAULT"
DEST="$DEST_DEFAULT"
BRANCH="$BRANCH_DEFAULT"
NVIDIA_ALT=""
MONITOR="$MONITOR_DEFAULT"
ZOOM="$ZOOM_DEFAULT"
RUN_FIRST="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) USERNAME="${2:-}"; shift 2;;
    --fullname) FULLNAME="${2:-}"; shift 2;;
    --repo) REPO="${2:-}"; shift 2;;
    --dest) DEST="${2:-}"; shift 2;;
    --branch) BRANCH="${2:-}"; shift 2;;
    --nvidia-alt) NVIDIA_ALT="${2:-}"; shift 2;;
    --monitor) MONITOR="${2:-}"; shift 2;;
    --zoom) ZOOM="${2:-}"; shift 2;;
    --no-first-run) RUN_FIRST="false"; shift 1;;
    -h|--help) usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

[[ -n "$USERNAME" ]] || { usage; die "--username is required"; }
[[ -z "$NVIDIA_ALT" || "$NVIDIA_ALT" == "true" || "$NVIDIA_ALT" == "false" ]] || die "--nvidia-alt must be true|false"
[[ "$ZOOM" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--zoom must look like 1 or 1.5 (dot only)"

command -v git >/dev/null || die "git not installed"

# If script is inside DEST, we cannot rm -rf DEST while running from it.
SCRIPT_PATH="$(readlink -f "$0" || true)"
DEST_ABS="$(readlink -f "$DEST" 2>/dev/null || true)"
if [[ -n "${DEST_ABS:-}" && -n "${SCRIPT_PATH:-}" && "$SCRIPT_PATH" == "$DEST_ABS"* ]]; then
  echo "⚠ You are running this script from inside DEST ($DEST_ABS)."
  echo "  Move/copy it outside first, e.g.:"
  echo "    cp \"$SCRIPT_PATH\" /tmp/bootstrap.sh && bash /tmp/bootstrap.sh --username \"$USERNAME\" ..."
  exit 1
fi

echo "=== HARD RESET DOTFILES ==="
echo "Repo:      $REPO"
echo "Branch:    $BRANCH"
echo "Dest:      $DEST"
echo "User:      $USERNAME"
[[ -n "$FULLNAME" ]] && echo "Name:      $FULLNAME"
[[ -n "$NVIDIA_ALT" ]] && echo "NVIDIA:    $NVIDIA_ALT"
echo "Monitor:   $MONITOR"
echo "Zoom:      \"$ZOOM\""
echo "First-run: $RUN_FIRST"
echo

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Cloning fresh to temp…"
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMP/repo" >/dev/null

echo "→ Removing destination completely…"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP/repo" "$DEST"

echo "→ Removing .git…"
rm -rf "$DEST/.git"

# --- Rename home folder deterministically
HOME_ROOT="$DEST/home"
if [[ -d "$HOME_ROOT" ]]; then
  if [[ -d "$HOME_ROOT/$USERNAME" ]]; then
    echo "✔ home/$USERNAME already exists"
  elif [[ -d "$HOME_ROOT/luna" ]]; then
    echo "→ Renaming home/luna → home/$USERNAME"
    mv "$HOME_ROOT/luna" "$HOME_ROOT/$USERNAME"
  else
    first_dir="$(find "$HOME_ROOT" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | head -n1 || true)"
    if [[ -n "$first_dir" ]]; then
      echo "→ Renaming home/$first_dir → home/$USERNAME"
      mv "$HOME_ROOT/$first_dir" "$HOME_ROOT/$USERNAME"
    else
      echo "⚠ No directories under $HOME_ROOT; skipping home rename"
    fi
  fi
else
  echo "ℹ No $HOME_ROOT directory; skipping home rename"
fi

# --- Patch flake.nix (let-bindings) - safe replace-or-insert for zoom
FLAKE="$DEST/flake.nix"
if [[ -f "$FLAKE" ]]; then
  echo "→ Patching flake.nix…"

  # Basic replacements (safe anywhere)
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$FLAKE"
  perl -0777 -i -pe "s/(\\bmonitor\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${MONITOR}\$3/g" "$FLAKE"

  if [[ -n "$NVIDIA_ALT" ]]; then
    perl -0777 -i -pe "s/(\\bnvidiaAlternative\\s*=\\s*)(true|false)(\\s*;)/\$1${NVIDIA_ALT}\$3/g" "$FLAKE"
  fi

  # Remove the common broken line that can appear if an earlier patch went wrong:
  perl -0777 -i -pe 's/^\s*";\s*$\n//mg' "$FLAKE"

  # Zoom: replace if present; otherwise insert after monitor = "...";
  ZOOM="$ZOOM" perl -0777 -i -pe '
    my $z = $ENV{ZOOM};

    # 1) Replace existing zoom assignment if present
    if (s/(\bzoom\s*=\s*")([^"]*)("\s*;)/$1.$z.$3/sg) {
      # ok
    } else {
      # 2) Insert after monitor assignment (usually in let block)
      s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          zoom = "$z";\n/s;
    }
  ' "$FLAKE"

  echo "✔ Patched $FLAKE"
else
  echo "⚠ No flake.nix found at $FLAKE (skipping flake patch)"
fi

# --- Patch modules/users.nix (best-effort)
USERS_NIX="$DEST/modules/users.nix"
if [[ -f "$USERS_NIX" ]]; then
  echo "→ Patching modules/users.nix…"

  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$USERS_NIX"
  perl -0777 -i -pe "s/(\\bname\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$USERS_NIX"

  if [[ -n "$FULLNAME" ]]; then
    FULLNAME="$FULLNAME" perl -0777 -i -pe '
      my $n = $ENV{FULLNAME};
      s/(\b(fullName|realName|description)\s*=\s*")([^"]*)("\s*;)/$1.$n.$4/g;
    ' "$USERS_NIX"
  fi

  echo "✔ Patched $USERS_NIX"
else
  echo "⚠ No modules/users.nix found (skipping)"
fi

# --- Run first-run.sh
if [[ "$RUN_FIRST" == "true" ]]; then
  if [[ -f "$DEST/first-run.sh" ]]; then
    echo "→ Running first-run.sh…"
    chmod +x "$DEST/first-run.sh"
    (cd "$DEST" && ./first-run.sh)
  else
    echo "⚠ first-run.sh not found, skipping"
  fi
else
  echo "→ Skipping first-run.sh"
fi

echo
echo "✅ Done."
echo "Next:"
echo "  cd \"$DEST\""
echo "  sudo nixos-rebuild switch --flake .#nixos"

