#!/usr/bin/env bash
set -euo pipefail

FLAG="$HOME/.cache/waybar"

# Wenn irgendeine Waybar läuft -> killen und Flag löschen
if pgrep -u "$USER" -f '(^|/)(waybar)(\s|$)' >/dev/null; then
  rm -f "$FLAG"
  pkill -u "$USER" -f '(^|/)(waybar)(\s|$)' || true
  exit 0
fi

# Sonst starten
touch "$FLAG"
waybar >/dev/null 2>&1 &

