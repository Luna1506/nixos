#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# HARD RESET dotfiles installer (sparse checkout: only ./dotfiles)
# + patches flake.nix let-bindings:
#   username, fullname (optional), nvidiaAlternative, monitor, zoom, git-name, git-email, luna-path
# + OPTIONAL: add arbitrary flake inputs + optional nixos module includes
#
# Extra flakes via:
#   --add-flake name=<inputName>,url=<flakeUrlOrPath>[,module=<attrPath>]
# =========================================================

REPO_DEFAULT="https://github.com/Luna1506/dotfiles.git"
DEST_DEFAULT="$HOME/nixos"
BRANCH_DEFAULT="main"

MONITOR_DEFAULT="eDP-1"
ZOOM_DEFAULT="1"

usage() {
  cat <<'EOF'
Hard reset dotfiles installer.

Usage:
  update-setup.sh --username <name> [options]

Required:
  --username <name>

Options:
  --fullname "<Full Name>"     Sets/updates fullname in flake.nix (if provided)
  --git-name "<Name>"
  --git-email "<Email>"
  --repo <url>                 (default: https://github.com/Luna1506/dotfiles.git)
  --dest <path>                (default: ~/nixos)
  --branch <name>              (default: main)
  --nvidia-alt <true|false>
  --monitor <name>             (default: eDP-1)
  --zoom <string>              (default: "1")
  --luna-path                  Sets luna-path = true
  --add-flake "name=<n>,url=<u>[,module=<m>]"
                               Adds an input and optionally a NixOS module entry.
                               - name:   input name (identifier, e.g. aliases)
                               - url:    flake URL or path
                                        examples: github:user/repo  OR  /abs/path  OR  path:/abs/path  OR  ../rel/path
                               - module: attr path under the input to add to nixosSystem.modules
                                        examples: nixosModules.default
                                                  nixosModules.catppuccin
                               Can be specified multiple times.
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

# Arrays of "name|url|module"
ADD_FLAKES=()

normalize_flake_url() {
  local raw="$1"
  if [[ -z "$raw" ]]; then
    echo ""
    return 0
  fi
  case "$raw" in
    path:*|github:*|gitlab:*|git+*|flake:*)
      echo "$raw"
      ;;
    /*)
      echo "path:$raw"
      ;;
    *)
      if [[ "$raw" == ./* || "$raw" == ../* ]]; then
        echo "path:$raw"
      else
        echo "path:$raw"
      fi
      ;;
  esac
}

parse_add_flake() {
  local spec="$1"
  local name="" url="" module=""

  IFS=',' read -r -a parts <<< "$spec"
  for p in "${parts[@]}"; do
    case "$p" in
      name=*) name="${p#name=}";;
      url=*) url="${p#url=}";;
      module=*) module="${p#module=}";;
      *) die "--add-flake: unknown field '$p' (allowed: name=,url=,module=)";;
    esac
  done

  [[ -n "$name" ]] || die "--add-flake requires name=..."
  [[ -n "$url"  ]] || die "--add-flake requires url=..."

  if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
    die "--add-flake name must be an identifier (got: '$name')"
  fi

  url="$(normalize_flake_url "$url")"

  if [[ -n "$module" ]] && ! [[ "$module" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*(\.[a-zA-Z_][a-zA-Z0-9_-]*)+$ ]]; then
    die "--add-flake module must look like 'nixosModules.default' (got: '$module')"
  fi

  ADD_FLAKES+=("${name}|${url}|${module}")
}

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
    --add-flake) parse_add_flake "${2:-}"; shift 2;;
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
  die "Script must not run from inside DEST"
fi

echo "=== HARD RESET DOTFILES ==="
echo "Repo:      $REPO"
echo "Branch:    $BRANCH"
echo "Dest:      $DEST"
echo "User:      $USERNAME"
[[ -n "$FULLNAME" ]] && echo "Fullname:  $FULLNAME"
echo "Monitor:   $MONITOR"
echo "Zoom:      $ZOOM"
[[ -n "$NVIDIA_ALT" ]] && echo "NVIDIA:    $NVIDIA_ALT"
[[ -n "$GIT_NAME" ]] && echo "Git name:  $GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && echo "Git mail:  $GIT_EMAIL"
echo "luna-path: $LUNA_PATH"

if [[ ${#ADD_FLAKES[@]} -gt 0 ]]; then
  echo "Extra flakes:"
  for entry in "${ADD_FLAKES[@]}"; do
    IFS='|' read -r n u m <<< "$entry"
    if [[ -n "$m" ]]; then
      echo "  - $n -> $u (module: $m)"
    else
      echo "  - $n -> $u"
    fi
  done
fi
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
# Install (hard reset)
# ---------------------------------------------------------
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP/repo/dotfiles" "$DEST"

# Ensure no git metadata survives
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
# Patch flake.nix (LET bindings + optional extra flakes)
# ---------------------------------------------------------
FLAKE="$DEST/flake.nix"
if [[ -f "$FLAKE" ]]; then
  # username
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$FLAKE"

  # fullname (only if provided): replace or insert after username
  if [[ -n "$FULLNAME" ]]; then
    FULLNAME="$FULLNAME" perl -0777 -i -pe '
      my $fn = $ENV{FULLNAME};
      if (s/(\bfullname\s*=\s*")([^"]*)("\s*;)/$1$fn$3/sg) {
        # replaced
      } else {
        s/(\busername\s*=\s*"[^"]*"\s*;\s*)/$1\n          fullname = "$fn";\n/s;
      }
    ' "$FLAKE"
  fi

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

  # ---------------------------------------------------------
  # OPTIONAL: add arbitrary extra flakes (ONLY if provided)
  # - Adds inputs.<name>.url
  # - Adds <name> into outputs args
  # - Optionally adds <name>.<moduleAttrPath> into modules list
  # ---------------------------------------------------------
  if [[ ${#ADD_FLAKES[@]} -gt 0 ]]; then
    EXTRA_LIST="$(printf "%s\n" "${ADD_FLAKES[@]}")"
    EXTRA_LIST="$EXTRA_LIST" perl -0777 -i -pe '
      my $list = $ENV{EXTRA_LIST} // "";
      my @entries = grep { length($_) } split(/\n/, $list);
      my $t = $_;

      for my $e (@entries) {
        my ($name,$url,$module) = split(/\|/, $e, 3);
        next unless $name && $url;

        # inputs.<name>.url
        if ($t !~ /^\s*\Q$name\E\.url\s*=/m) {
          my $ins = "    $name.url = \"$url\";\n";
          $t =~ s/(\n\s*\};\s*\n\s*\n\s*outputs\s*=)/\n$ins$1/s;
        }

        # outputs args include <name>
        if ($t !~ /outputs\s*=\s*\{[^}]*\b\Q$name\E\b/s) {
          $t =~ s/(outputs\s*=\s*\{[^}]*?)(,\s*\.\.\.\s*\}\@inputs:)/$1, $name$2/s;
        }

        # optional module include
        if (defined($module) && length($module)) {
          my $line = "$name.$module";
          if ($t !~ /^\s*\Q$line\E\s*$/m) {
            $t =~ s/(\n\s*\]\s*;)/\n\n            $line$1/s;
          }
        }
      }

      $_ = $t;
    ' "$FLAKE"
  fi
fi

# ---------------------------------------------------------
# Patch modules/users.nix (best effort)
# ---------------------------------------------------------
USERS_NIX="$DEST/modules/users.nix"
if [[ -f "$USERS_NIX" ]]; then
  perl -0777 -i -pe "s/(\\busername\\s*=\\s*\")([^\"]*)(\"\\s*;)/\$1${USERNAME}\$3/g" "$USERS_NIX"

  # also patch fullname there if you use it (only if provided)
  if [[ -n "$FULLNAME" ]]; then
    FULLNAME="$FULLNAME" perl -0777 -i -pe '
      my $fn = $ENV{FULLNAME};
      if (s/(\bfullname\s*=\s*")([^"]*)("\s*;)/$1$fn$3/sg) {
        # replaced
      } else {
        # do nothing if not present (safer)
      }
    ' "$USERS_NIX"
  fi
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

