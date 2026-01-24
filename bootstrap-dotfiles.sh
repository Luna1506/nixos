#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Defaults
# =========================================================
REPO_DEFAULT="https://github.com/Luna1506/dotfiles.git"
DEST_DEFAULT="$HOME/dotfiles"
BRANCH_DEFAULT="main"
RUN_FIRST_DEFAULT="true"

# =========================================================
# Usage
# =========================================================
usage() {
  cat <<'EOF'
Usage:
  bootstrap-dotfiles.sh --username <name> [options]

Required:
  --username <name>            New username to set in config

Options:
  --fullname "<Full Name>"     Full name for modules/users.nix
  --repo <url>                Git repo URL
  --dest <path>               Destination directory (default: ~/dotfiles)
  --branch <name>             Git branch (default: main)
  --nvidia-alt <true|false>   Set nvidiaAlternative if found
  --no-first-run              Do not run first-run.sh
  -h, --help                  Show this help
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

# =========================================================
# Args
# =========================================================
USERNAME=""
FULLNAME=""
REPO="$REPO_DEFAULT"
DEST="$DEST_DEFAULT"
BRANCH="$BRANCH_DEFAULT"
NVIDIA_ALT=""
RUN_FIRST="$RUN_FIRST_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) USERNAME="${2:-}"; shift 2;;
    --fullname) FULLNAME="${2:-}"; shift 2;;
    --repo) REPO="${2:-}"; shift 2;;
    --dest) DEST="${2:-}"; shift 2;;
    --branch) BRANCH="${2:-}"; shift 2;;
    --nvidia-alt) NVIDIA_ALT="${2:-}"; shift 2;;
    --no-first-run) RUN_FIRST="false"; shift 1;;
    -h|--help) usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

[[ -n "$USERNAME" ]] || { usage; die "--username is required"; }
[[ -z "$NVIDIA_ALT" || "$NVIDIA_ALT" == "true" || "$NVIDIA_ALT" == "false" ]] \
  || die "--nvidia-alt must be true or false"

# =========================================================
# Helpers
# =========================================================
set_kv_bool() {
  local file="$1" key="$2" value="$3"
  [[ -f "$file" ]] || return 0
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    perl -0777 -i -pe "s/^([[:space:]]*${key}[[:space:]]*=[[:space:]]*)(true|false)([[:space:]]*;)/\$1${value}\$3/m" "$file"
    echo "✔ ${file}: set ${key} = ${value}"
  fi
}

set_kv_string() {
  local file="$1" key="$2" value="$3"
  [[ -f "$file" ]] || return 0
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    perl -0777 -i -pe "s/^([[:space:]]*${key}[[:space:]]*=[[:space:]]*\")([^\"]*)(\"[[:space:]]*;)/\$1${value}\$3/m" "$file"
    echo "✔ ${file}: set ${key} = \"${value}\""
  fi
}

patch_flake() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  set_kv_string "$f" "username" "$USERNAME"
  if [[ -n "$NVIDIA_ALT" ]]; then
    set_kv_bool "$f" "nvidiaAlternative" "$NVIDIA_ALT"
    set_kv_bool "$f" "my.nvidiaAlternative" "$NVIDIA_ALT"
  fi
}

patch_users() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  set_kv_string "$f" "username" "$USERNAME"
  set_kv_string "$f" "name" "$USERNAME"
  if [[ -n "$FULLNAME" ]]; then
    set_kv_string "$f" "fullName" "$FULLNAME"
    set_kv_string "$f" "realName" "$FULLNAME"
    set_kv_string "$f" "description" "$FULLNAME"
  fi
}

# =========================================================
# Main
# =========================================================
echo "→ Repo:   $REPO"
echo "→ Dest:   $DEST"
echo "→ User:   $USERNAME"
[[ -n "$FULLNAME" ]] && echo "→ Name:   $FULLNAME"
[[ -n "$NVIDIA_ALT" ]] && echo "→ NVIDIA alt: $NVIDIA_ALT"
echo

command -v git >/dev/null || die "git not installed"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Cloning repository"
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMP/repo" >/dev/null

if [[ -e "$DEST" ]]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  BACKUP="${DEST}.bak-${TS}"
  echo "→ Backing up existing $DEST → $BACKUP"
  mv "$DEST" "$BACKUP"
fi

echo "→ Installing dotfiles"
mkdir -p "$(dirname "$DEST")"
mv "$TMP/repo" "$DEST"

# ---------------------------------------------------------
# Remove .git
# ---------------------------------------------------------
if [[ -d "$DEST/.git" ]]; then
  echo "→ Removing .git directory"
  rm -rf "$DEST/.git"
fi

# ---------------------------------------------------------
# Patch configs
# ---------------------------------------------------------
echo "→ Patching configuration files"
patch_flake "$DEST/flake.nix"
patch_users "$DEST/modules/users.nix"

# ---------------------------------------------------------
# Run first-run.sh
# ---------------------------------------------------------
if [[ "$RUN_FIRST" == "true" ]]; then
  if [[ -f "$DEST/first-run.sh" ]]; then
    echo "→ Running first-run.sh"
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
echo "  cd $DEST"
echo "  sudo nixos-rebuild switch --flake .#nixos"

