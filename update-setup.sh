#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# HARD RESET dotfiles installer (sparse checkout: only ./dotfiles)
# + patches flake.nix let-bindings:
#   username, nvidiaAlternative, monitor, zoom, git-name, git-email, luna-path
# =========================================================

REPO_DEFAULT="https://github.com/Luna1506/dotfiles.git"
DEST_DEFAULT="$HOME/nixos"
BRANCH_DEFAULT="main"

MONITOR_DEFAULT="eDP-1"
ZOOM_DEFAULT="1"   # string

usage() {
  cat <<'EOF'
Hard reset dotfiles installer (sparse checkout: only ./dotfiles).

Usage:
  update-setup.sh --username <name> [options]

Required:
  --username <name>

Options:
  --fullname "<Full Name>"
  --git-name "<Name>"          Sets git-name in flake.nix (e.g. "Luna")
  --git-email "<Email>"        Sets git-email in flake.nix (e.g. "me@mail.com")
  --repo <url>                 (default: https://github.com/Luna1506/dotfiles.git)
  --dest <path>                (default: ~/nixos)
  --branch <name>              (default: main)
  --nvidia-alt <true|false>
  --monitor <name>             (default: eDP-1)
  --zoom <string>              (default: "1") e.g. "1.5"
  --luna-path                  Sets luna-path = true in flake.nix (or inserts it if missing)
  --no-first-run
  -h, --help
EOF
}

die(){ echo "Error: $*" >&2; exit 1; }

USERNAME=""
FULLNAME=""
GIT_NAME=""
GIT_EMAIL=""
REPO="$REPO_DEFAULT"
DEST="$DEST_DEFAULT"
BRANCH="$BRANCH_DEFAULT"
NVIDIA_ALT=""
MONITOR="$MONITOR_DEFAULT"
ZOOM="$ZOOM_DEFAULT"
RUN_FIRST="true"
LUNA_PATH="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) USERNAME="${2:-}"; shift 2;;
    --fullname) FULLNAME="${2:-}"; shift 2;;
    --git-name) GIT_NAME="${2:-}"; shift 2;;
    --git-email) GIT_EMAIL="${2:-}"; shift 2;;
    --repo) REPO="${2:-}"; shift 2;;
    --dest) DEST="${2:-}"; shift 2;;
    --branch) BRANCH="${2:-}"; shift 2;;
    --nvidia-alt) NVIDIA_ALT="${2:-}"; shift 2;;
    --monitor) MONITOR="${2:-}"; shift 2;;
    --zoom) ZOOM="${2:-}"; shift 2;;
    --luna-path) LUNA_PATH="true"; shift 1;;
    --no-first-run) RUN_FIRST="false"; shift 1;;
    -h|--help) usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

[[ -n "$USERNAME" ]] || die "--username is required"
[[ -z "$NVIDIA_ALT" || "$NVIDIA_ALT" == "true" || "$NVIDIA_ALT" == "false" ]] || die "--nvidia-alt must be true|false"
[[ "$ZOOM" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--zoom must look like 1 or 1.5"
if [[ -n "$GIT_EMAIL" ]] && ! [[ "$GIT_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
  die "--git-email does not look like an email address"
fi

command -v git >/dev/null || die "git not installed"

# Safety: don't delete DEST while running from inside it
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || true)"
DEST_ABS="$(readlink -f "$DEST" 2>/dev/null || true)"
if [[ -n "$DEST_ABS" && -n "$SCRIPT_PATH" && "$SCRIPT_PATH" == "$DEST_ABS"* ]]; then
  echo "⚠ Script is inside DEST. Copy it elsewhere first."
  exit 1
fi

echo "=== HARD RESET DOTFILES (sparse checkout) ==="
echo "Repo:      $REPO"
echo "Branch:    $BRANCH"
echo "Dest:      $DEST"
echo "User:      $USERNAME"
echo "Monitor:   $MONITOR"
echo "Zoom:      \"$ZOOM\""
[[ -n "$NVIDIA_ALT" ]] && echo "NVIDIA:    $NVIDIA_ALT"
[[ -n "$GIT_NAME" ]] && echo "Git name:  $GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && echo "Git mail:  $GIT_EMAIL"
echo "luna-path: $LUNA_PATH"
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
    first="$(find "$HOME_ROOT" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
    [[ -n "$first" ]] && mv "$first" "$HOME_ROOT/$USERNAME"
  fi
fi

# ---------------------------------------------------------
# Patch flake.nix (LET bindings)
# - username, monitor, nvidiaAlternative, zoom
# - git-name, git-email
# - luna-path (boolean)
# ---------------------------------------------------------
FLAKE="$DEST/flake.nix"
if [[ -f "$FLAKE" ]]; then
  # username
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$FLAKE"

  # monitor
  perl -0777 -i -pe "s/(\\bmonitor\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${MONITOR}\$3/g" "$FLAKE"

  # nvidiaAlternative (optional)
  [[ -n "$NVIDIA_ALT" ]] && \
    perl -0777 -i -pe "s/(\\bnvidiaAlternative\\s*=\\s*)(true|false)(\\s*;)/\$1${NVIDIA_ALT}\$3/g" "$FLAKE"

  # Remove broken dangling quote line if present
  perl -0777 -i -pe 's/^\s*";\s*$\n//mg' "$FLAKE"

  # zoom: replace or insert after monitor
  ZOOM="$ZOOM" perl -0777 -i -pe '
    my $z = $ENV{ZOOM};
    if (s/(\bzoom\s*=\s*")([^"]*)("\s*;)/$1$z$3/sg) {
      # replaced
    } else {
      s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          zoom = "$z";\n/s;
    }
  ' "$FLAKE"

  # luna-path (boolean): replace if present; otherwise insert after zoom (or monitor)
  LUNA_PATH="$LUNA_PATH" perl -0777 -i -pe '
    my $v = $ENV{LUNA_PATH};
    if (s/(\bluna-path\s*=\s*)(true|false)(\s*;)/$1$v$3/sg) {
      # replaced
    } else {
      if (s/(\bzoom\s*=\s*"[^"]*"\s*;\s*)/$1\n          luna-path = $v;\n/s) {
        # ok
      } else {
        s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          luna-path = $v;\n/s;
      }
    }
  ' "$FLAKE"

  # git-name: replace or insert after zoom/luna-path
  if [[ -n "$GIT_NAME" ]]; then
    GIT_NAME="$GIT_NAME" perl -0777 -i -pe '
      my $n = $ENV{GIT_NAME};
      if (s/(\bgit-name\s*=\s*")([^"]*)("\s*;)/$1$n$3/sg) {
        # replaced
      } else {
        if (s/(\bluna-path\s*=\s*(true|false)\s*;\s*)/$1\n          git-name = "$n";\n/s) {
          # ok
        } elsif (s/(\bzoom\s*=\s*"[^"]*"\s*;\s*)/$1\n          git-name = "$n";\n/s) {
          # ok
        } else {
          s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          git-name = "$n";\n/s;
        }
      }
    ' "$FLAKE"
  fi

  # git-email: replace or insert after git-name (or luna-path/zoom/monitor)
  if [[ -n "$GIT_EMAIL" ]]; then
    GIT_EMAIL="$GIT_EMAIL" perl -0777 -i -pe '
      my $e = $ENV{GIT_EMAIL};
      if (s/(\bgit-email\s*=\s*")([^"]*)("\s*;)/$1$e$3/sg) {
        # replaced
      } else {
        if (s/(\bgit-name\s*=\s*"[^"]*"\s*;\s*)/$1\n          git-email = "$e";\n/s) {
          # ok
        } elsif (s/(\bluna-path\s*=\s*(true|false)\s*;\s*)/$1\n          git-email = "$e";\n/s) {
          # ok
        } elsif (s/(\bzoom\s*=\s*"[^"]*"\s*;\s*)/$1\n          git-email = "$e";\n/s) {
          # ok
        } else {
          s/(\bmonitor\s*=\s*"[^"]*"\s*;\s*)/$1\n          git-email = "$e";\n/s;
        }
      }
    ' "$FLAKE"
  fi
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

