#!/usr/bin/env bash
set -euo pipefail

HOST="laptop"
TARGET_DIR="./hosts/${HOST}"
SOURCE="/etc/nixos/hardware-configuration.nix"
TARGET="${TARGET_DIR}/hardware-configuration.nix"

echo "→ Sync hardware-configuration for host: ${HOST}"

if [[ ! -f "$SOURCE" ]]; then
  echo "❌ Source file not found: $SOURCE"
  exit 1
fi

mkdir -p "$TARGET_DIR"

if [[ -f "$TARGET" ]]; then
  echo "⚠️ Removing existing $TARGET"
  rm -f "$TARGET"
fi

cp "$SOURCE" "$TARGET"

echo "✅ Copied to $TARGET"

