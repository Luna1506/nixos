# Saves the image in the Wayland clipboard for the launcher's "Ask Claude":
#   qs-claude-paste <dir>
# Prints the path of the saved file, or nothing when the clipboard holds no
# image (PNG, JPEG, WebP or GIF).

dir=$1
mkdir -p "$dir"
# Leftovers of launcher sessions that were closed without asking Claude.
find "$dir" -type f -mmin +1440 -delete

types=$(wl-paste --list-types 2>/dev/null) || exit 0
type=""
for candidate in image/png image/jpeg image/webp image/gif; do
  if grep -qx "$candidate" <<<"$types"; then
    type=$candidate
    break
  fi
done
[ -n "$type" ] || exit 0

file="$dir/$(date +%s%N).${type#image/}"
if ! wl-paste --type "$type" >"$file" || [ ! -s "$file" ]; then
  rm -f "$file"
  exit 0
fi
printf '%s\n' "$file"
