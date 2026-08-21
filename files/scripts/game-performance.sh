#!/usr/bin/env bash
#
# game-performance.sh — switch to a "performance" power profile via
# tuned-ppd while a Steam game runs, then restore whatever was active
# before. Fedora 41+ default backend, driven through tuned-adm.
# Also disables GNOME Night Light for the duration and restores it.
#
# Steam: Properties -> General -> Launch Options:
#   /home/(your-username)/.local/bin/game-performance.sh %command%
#
# Can run under Steam's Flatpak sandbox, so host-side commands are routed
# out via flatpak-spawn --host. Requires:
#   flatpak --user override --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam
#   flatpak --user override --filesystem=~/.local/bin:ro com.valvesoftware.Steam

set -uo pipefail

# Detect whether we're inside a Flatpak sandbox; fall back to running
# commands directly if not (e.g. testing this script from a bare terminal).
if [[ -f /.flatpak-info ]] && command -v flatpak-spawn &>/dev/null; then
  host() { flatpak-spawn --host "$@"; }
else
  host() { "$@"; }
fi

notify() {
  host notify-send -a "game-performance" -i "$1" -t 4000 "$2" "$3" 2>/dev/null
}

if ! active_line="$(host tuned-adm active 2>/dev/null)"; then
  echo "game-performance.sh: tuned-adm unavailable, launching unmodified" >&2
  exec "$@"
fi

prev_profile="${active_line#Current active profile: }"

# PPD's "performance" name maps to a real tuned profile via
# /etc/tuned/ppd.conf; fall back to tuned's documented default mapping.
perf_profile="$(host awk -F= '/^[[:space:]]*performance[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2}' /etc/tuned/ppd.conf 2>/dev/null)"
perf_profile="${perf_profile:-throughput-performance}"

# --- Night Light state -------------------------------------------------
NIGHT_LIGHT_SCHEMA="org.gnome.settings-daemon.plugins.color"
NIGHT_LIGHT_KEY="night-light-enabled"

night_light_prev="$(host gsettings get "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" 2>/dev/null)"

restore_profile() {
  if host tuned-adm profile "$prev_profile" 2>/dev/null; then
    notify "power-profile-balanced-symbolic" "Power profile restored" "$prev_profile"
  fi
  if [[ -n "$night_light_prev" ]]; then
    host gsettings set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" "$night_light_prev" 2>/dev/null
  fi
}

trap restore_profile EXIT INT TERM

if [[ "$prev_profile" != "$perf_profile" ]]; then
  if host tuned-adm profile "$perf_profile" 2>/dev/null; then
    notify "power-profile-performance-symbolic" "Performance mode" "$perf_profile for this game"
  else
    echo "game-performance.sh: couldn't switch to '$perf_profile' profile" >&2
  fi
fi

if [[ "$night_light_prev" == "true" ]]; then
  host gsettings set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" false 2>/dev/null
fi

"$@"
exit_code=$?
exit "$exit_code"
