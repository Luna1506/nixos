# Opens a new chat in Claude Desktop with a prompt and optional images:
#   qs-claude-ask <prompt> [image...]
#
# The chat deep link only carries text, so the images go through the
# clipboard: each one is copied and pasted into the Claude window with
# Ctrl+V. The image files are deleted afterwards.
#
# A deep link that arrives while the app is still starting gets lost, so a
# cold start launches the app plainly and waits until its composer is ready.

prompt=$1
shift

log="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/logs/main.log"
window_class=com.anthropic.Claude
# Startup timeout and the time the chat page needs before pasting (seconds).
ready_timeout=60
page_delay=1.5

link="claude://claude.ai/new?surface=chat&source=os_open"
if [ -n "$prompt" ]; then
  link+="&q=$(jq -rn --arg s "$prompt" '$s | @uri')"
fi

log_size() {
  stat -c %s "$log" 2>/dev/null || echo 0
}

# True once the log has a "composer ready" line written after offset $start.
composer_ready() {
  [ -f "$log" ] || return 1
  # The log was rotated: search the new file from the beginning.
  [ "$(log_size)" -ge "$start" ] || start=0
  tail -c +"$((start + 1))" "$log" | grep -q '\[startup-perf\] input ready'
}

if ! pgrep -u "$(id -u)" -x claude-desktop >/dev/null; then
  start=$(log_size)
  claude-desktop >/dev/null 2>&1 &
  waited=0
  until composer_ready || [ "$waited" -ge $((ready_timeout * 2)) ]; do
    sleep 0.5
    waited=$((waited + 1))
  done
fi

claude-desktop "$link" >/dev/null 2>&1

[ $# -gt 0 ] || exit 0

# Hyprland's Lua dispatchers; a failed one only prints a warning.
dispatch() {
  hyprctl dispatch "$1" >/dev/null || true
}

sleep "$page_delay"
# Addressed directly: the Lua API ignores "class:<regex>" selectors.
address=$(hyprctl clients -j | jq -r --arg c "$window_class" 'first(.[] | select(.class == $c) | .address) // empty')
[ -n "$address" ] || exit 1
window="address:$address"
dispatch "hl.dsp.focus({ window = \"$window\" })"
for image in "$@"; do
  case $image in
    *.jpeg | *.jpg) type=image/jpeg ;;
    *.webp) type=image/webp ;;
    *.gif) type=image/gif ;;
    *) type=image/png ;;
  esac
  wl-copy --type "$type" <"$image"
  sleep 0.3
  dispatch "hl.dsp.send_shortcut({ mods = \"CTRL\", key = \"V\", window = \"$window\" })"
  sleep 0.7
done
rm -f -- "$@"
