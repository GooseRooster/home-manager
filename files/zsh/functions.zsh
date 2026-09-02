# Functional port of files/nushell/config.nu's custom functions, for zsh.
# Kept in its own file (mirrors nu's config.nu split) so it can be edited
# without touching modules/zsh.nix. Sourced from programs.zsh.initContent.

# ── Functions: misc ───────────────────────────────────────────────────────────
get-os-release-field() {
  local field="$1"
  local line
  line=$(command grep -m1 "^${field}=" /etc/os-release 2>/dev/null)
  line="${line#${field}=}"
  line="${line%\"}"
  line="${line#\"}"
  print -r -- "$line"
}

# Nerd-font glyph for the running distro, used to build the __OS_KEY__ prefix
# ("╭─" + glyph) substituted into the fastfetch config. Each pattern is matched
# as a regex against ID/ID_LIKE/VARIANT_ID/IMAGE_ID from /etc/os-release,
# top-down — so the first (most-specific) row wins. Universal Blue images and
# distro derivatives are listed before their base distro on purpose. Fill in
# the nerd-font glyph for each distro you want branded; an unmatched distro
# falls back to the plain "╭─".
distro-glyph() {
  local ident
  ident="$(get-os-release-field ID) $(get-os-release-field ID_LIKE) $(get-os-release-field VARIANT_ID) $(get-os-release-field IMAGE_ID)"
  ident="${(L)ident}"

  # pattern:glyph pairs, in match-priority order.
  local -a table=(
    'bluefin:󱍢'
    'manjaro:'
    'endeavouros:'
    'mint:󰣭'
    'pop:'
    'kali:'
    'rocky:'
    'alma:'
    'centos:'
    'fedora:'
    'ubuntu:'
    'debian:'
    'arch:'
    'opensuse:'
    'nixos:'
    'gentoo:'
    'alpine:'
    'void:'
    'rhel:󱄛'
  )

  local row pattern glyph
  for row in "${table[@]}"; do
    pattern="${row%%:*}"
    glyph="${row#*:}"
    if [[ "$ident" =~ $pattern ]]; then
      print -r -- "$glyph"
      return
    fi
  done
  print -r -- ""
}

fastfetch() {
  # Only want the greeting to fire if we are not within a container
  # (distrobox sets CONTAINER_ID).
  [[ -n "${CONTAINER_ID:-}" ]] && return 0

  local ff_dir="$HOME/.config/fastfetch"
  local config="$ff_dir/config.jsonc"
  local logo_file="$ff_dir/logo.txt" # per-machine, never committed to dotfiles

  if [[ ! -f "$config" ]]; then
    # custom config not deployed on this machine yet — fall back to plain fastfetch
    command fastfetch "$@"
    return
  fi

  local is_bluefin=0
  if [[ "$(get-os-release-field VARIANT_ID)" == "bluefin" || "$(get-os-release-field IMAGE_ID)" == "bluefin" ]]; then
    is_bluefin=1
  fi

  local os_key="╭─$(distro-glyph)"

  local ublue_ff_conf="/etc/ublue-os/fastfetch.json"
  local bluefin_logo_dir="/usr/share/ublue-os/fastfetch"
  if [[ -f "$ublue_ff_conf" ]] && (( ${+commands[jq]} )); then
    local dir
    dir="$(command jq -r '."logo-directory" // empty' "$ublue_ff_conf" 2>/dev/null)"
    [[ -n "$dir" ]] && bluefin_logo_dir="$dir"
  fi

  local -a logo_flags=()
  if [[ -f "$logo_file" ]]; then
    logo_flags=(--file "$logo_file")
  elif (( is_bluefin )) && [[ -d "$bluefin_logo_dir" ]]; then
    local pick
    pick="$(command ls -1 -- "$bluefin_logo_dir" 2>/dev/null | shuf -n1)"
    [[ -n "$pick" ]] && logo_flags=(--file-raw "$bluefin_logo_dir/$pick")
  fi
  # else: fastfetch falls back to its own builtin distro logo

  local tmp
  tmp="$(mktemp -t "fastfetch-config.XXXXXX.jsonc")"
  sed "s/__OS_KEY__/${os_key//\//\\/}/g" "$config" >| "$tmp"
  command fastfetch --config "$tmp" "${logo_flags[@]}" "$@"
  rm -f -- "$tmp"
}

# ── Functions: navigation ─────────────────────────────────────────────────────
# Dotfile listing (zsh's dotglob-matching pattern never matches "." or "..").
l.() {
  eza -la .*(N)
}

# Yazi cd-on-exit wrapper (`y`) isn't ported here: modules/yazi.nix already
# enables programs.yazi.enableZshIntegration (default-on), which provides an
# equivalent `y()` — defining our own here would just get silently shadowed
# by it (function definitions loaded later in .zshrc win).

# Make a dir and cd into it
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# Home, clear, greeting
home() {
  cd ~ && clear
  fastfetch
}

# Notebook, for use with zk
notebook() {
  cd ~ && mkdir -p notes && cd notes
}

# ── Functions: file ops ───────────────────────────────────────────────────────
# Backup a file
backup() {
  cp -- "$1" "$1.bak"
}

# Smart copy — auto-recurse if source is a directory
copy() {
  if [[ $# -eq 2 && -d "$1" ]]; then
    cp -r -- "${1%/}" "$2"
  else
    cp -- "$@"
  fi
}

# ── Custom completions ────────────────────────────────────────────────────────
# dotnet — delegate to dotnet's own completion library (carapace has no
# built-in dotnet completer; its bridges are cobra/argcomplete/clap only).
# Verbatim upstream snippet:
# https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
if (( ${+commands[dotnet]} )); then
  _dotnet_zsh_complete() {
    local completions=("$(dotnet complete "$words")")

    # If the completion list is empty, just continue with filename selection
    if [ -z "$completions" ]; then
      _arguments '*::arguments: _normal'
      return
    fi

    # This is not a variable assignment, don't remove spaces!
    _values = "${(ps:\n:)completions}"
  }
  compdef _dotnet_zsh_complete dotnet
fi
