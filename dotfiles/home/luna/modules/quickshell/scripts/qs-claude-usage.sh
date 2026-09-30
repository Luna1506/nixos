# Prints the Claude plan usage as one line of JSON:
#   {"status":"ok","fetchedAt":<ms>,"session":{"utilization":0..1,"resetsAt":<ms>},"week":{...}}
# or {"status":"unavailable","reason":"<code>"}.
#
# Unofficial: uses the endpoint behind Claude Code's /usage, which may change
# at any time. Read-only. The OAuth token is read from Claude Code's
# credentials file at runtime, passed to curl on stdin (never in argv or the
# environment) and never printed. An expired token is not refreshed; that is
# left to Claude Code.

credentials="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json"

unavailable() {
  printf '{"status":"unavailable","reason":"%s"}\n' "$1"
  exit 0
}

[ -r "$credentials" ] || unavailable no-credentials

expires=$(jq -r '.claudeAiOauth.expiresAt // 0 | floor' "$credentials" 2>/dev/null) || unavailable bad-credentials
now=$(($(date +%s) * 1000))
[ "$expires" -gt "$now" ] || unavailable expired

# curl config line with the Authorization header. The token charset is
# checked so it can't break out of the quoted config value.
header=$(jq -r '
  .claudeAiOauth.accessToken // ""
  | if test("^[A-Za-z0-9._~+/=-]+$") then "header = \"Authorization: Bearer \(.)\"" else empty end
' "$credentials" 2>/dev/null) || unavailable bad-credentials
[ -n "$header" ] || unavailable bad-credentials

body=$(mktemp)
trap 'rm -f "$body"' EXIT

status=$(printf '%s\n' "$header" | curl -q --silent --config - \
  --max-time 10 \
  --output "$body" \
  --write-out '%{http_code}' \
  --header 'anthropic-beta: oauth-2025-04-20' \
  --header 'Accept: application/json' \
  --user-agent 'quickshell-claude-usage' \
  https://api.anthropic.com/api/oauth/usage 2>/dev/null) || unavailable offline
[ "$status" = 200 ] || unavailable "http-$status"

jq -c --argjson now "$now" '
  def ms: try (sub("\\.[0-9]+"; "") | sub("(\\+00:00|Z)$"; "Z") | fromdateiso8601 * 1000) catch 0;
  def window: if type == "object" and (.utilization | type) == "number"
    then { utilization: (.utilization / 100), resetsAt: ((.resets_at // "") | ms) }
    else null end;
  { status: "ok", fetchedAt: $now, session: (.five_hour | window), week: (.seven_day | window) }
  | if .session == null and .week == null then { status: "unavailable", reason: "no-data" } else . end
' "$body" 2>/dev/null || unavailable bad-response
