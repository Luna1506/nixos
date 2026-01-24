#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# HARD RESET dotfiles installer (sparse checkout: only ./dotfiles)
# =========================================================

REPO_DEFAULT="https://github.com/Luna1506/dotfiles.git"
DEST_DEFAULT="$HOME/dotfiles"
BRANCH_DEFAULT="main"

MONITOR_DEFAULT="eDP-1"
ZOOM_DEFAULT="1"   # string

usage() {
  cat <<'EOF'
Hard reset dotfiles installer (sparse checkout: only ./dotfiles).

Usage:
  bootstrap-dotfiles.sh --username <name> [options]

Required:
  --username <name>

Options:
  --fullname "<Full Name>"
  --repo <url>                 (default: https://github.com/Luna1506/dotfiles.git)
  --dest <path>                (default: ~/dotfiles)
  --branch <name>              (default: main)
  --nvidia-alt <true|false>
  --monitor <name>             (default: eDP-1)
  --zoom <string>              (default: "1") e.g. "1.5"
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

[[ -n "$USERNAME" ]] || die "--username is required"
[[ -z "$NVIDIA_ALT" || "$NVIDIA_ALT" == "true" || "$NVIDIA_ALT" == "false" ]] || die "--nvidia-alt must be true|false"
[[ "$ZOOM" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--zoom must look like 1 or 1.5"

command -v git >/dev/null || die "git not installed"

# Safety: don't delete DEST while running from inside it
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || true)"
DEST_ABS="$(readlink -f "$DEST" 2>/dev/null || true)"
if [[ -n "$DEST_ABS" && -n "$SCRIPT_PATH" && "$SCRIPT_PATH" == "$DEST_ABS"* ]]; then
  echo "⚠ Script is inside DEST. Copy it elsewhere first."
  exit 1
fi

echo "=== HARD RESET DOTFILES (sparse checkout) ==="
echo "Repo:    $REPO"
echo "Branch:  $BRANCH"
echo "Dest:    $DEST"
echo "User:    $USERNAME"
echo "Monitor: $MONITOR"
echo "Zoom:    \"$ZOOM\""
echo

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------
# Sparse checkout: only ./dotfiles
# ---------------------------------------------------------
git clone --filter=blob:none --no-checkout "$REPO" "$TMP/repo" >/dev/null
pushd "$TMP/repo" >/dev/null
git sparse-checkout init --cone >/dev/null
git sparse-checkout set dotfiles >/dev/null
git checkout "$BRANCH" >/dev/null
popd >/dev/null

[[ -d "$TMP/repo/dotfiles" ]] || die "Repo has no dotfiles/ directory"

# ---------------------------------------------------------
# Install
# ---------------------------------------------------------
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP/repo/dotfiles" "$DEST"
rm -rf "$DEST/.git"

# ---------------------------------------------------------
# Rename home folder
# ---------------------------------------------------------
HOME_ROOT="$DEST/home"
if [[ -d "$HOME_ROOT" && ! -d "$HOME_ROOT/$USERNAME" ]]; then
  if [[ -d "$HOME_ROOT/luna" ]]; then
    mv "$HOME_ROOT/luna" "$HOME_ROOT/$USERNAME"
  else
    first="$(find "$HOME_ROOT" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    [[ -n "$first" ]] && mv "$first" "$HOME_ROOT/$USERNAME"
  fi
fi

# ---------------------------------------------------------
# Patch flake.nix (LET bindings)
# ---------------------------------------------------------
FLAKE="$DEST/flake.nix"
if [[ -f "$FLAKE" ]]; then
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$FLAKE"
  perl -0777 -i -pe "s/(\\bmonitor\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${MONITOR}\$3/g" "$FLAKE"

  [[ -n "$NVIDIA_ALT" ]] && \
    perl -0777 -i -pe "s/(\\bnvidiaAlternative\\s*=\\s*)(true|false)(\\s*;)/\$1${NVIDIA_ALT}\$3/g" "$FLAKE"

  # Remove broken dangling quote line if present
  perl -0777 -i -pe 's/^\s*";\s*$\n//mg' "$FLAKE"

  # ZOOM: replace or insert cleanly
  ZOOM="$ZOOM" perl -0777 -i -pe '
    my $z = $ENV{ZOOM};
    if (s/(\bzoom\s*=\s*")([^"]*)("\s*;)/$1$z$3/sg) {
      # replaced
    } else {
      s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          zoom = "$z";\n/s;
    }
  ' "$FLAKE"
fi

# ---------------------------------------------------------
# Patch modules/users.nix (best effort)
# ---------------------------------------------------------
USERS_NIX="$DEST/modules/users.nix"
if [[ -f "$USERS_NIX" ]]; then
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$USERS_NIX"
fi

# ---------------------------------------------------------
# first-run.sh
# ---------------------------------------------------------
if [[ "$RUN_FIRST" == "true" && -f "$DEST/first-run.sh" ]]; then
  chmod +x "$DEST/first-run.sh"
  (cd "$DEST" && ./first-run.sh)
fi

echo
echo "✅ DONE"
echo "Next:"
echo "  cd \"$DEST\""
echo "  sudo nixos-rebuild switch --flake .#nixos"

