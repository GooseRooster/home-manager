# Custom zsh functions. Kept in its own file so it can be edited without
# touching modules/zsh.nix. Sourced from programs.zsh.initContent.


# ── Functions: navigation ─────────────────────────────────────────────────────
# Dotfile listing (zsh's dotglob-matching pattern never matches "." or "..").
# Fedora's /etc/profile.d/colorls.sh ships `alias l.='ls -d .* --color=auto'`,
# sourced into login shells before this file; without the unalias, defining the
# function below aborts parse with "defining function based on alias `ls'".
unalias l. 2>/dev/null
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

pfetch() {
  PF_INFO="ascii title os host kernel uptime pkgs cpu memory shell" \
    USER="ホスト  ${USER}" \
    command pfetch "$@"
}

# Home, clear, greeting
home() {
  cd ~ && clear
  pfetch
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

# ── Functions: home-manager ───────────────────────────────────────────────────
# Standalone Home Manager against the *remote* dotfiles flake. The host is a
# flake output (homeConfigurations.<host>), defaulting to the target this
# machine actually runs; extra args are passed through (e.g. `hms silver-hour -n`).
# --impure is always used: hosts/*.nix read $USER/$HOME at eval time.
_HM_FLAKE="github:GooseRooster/home-manager"

# Which target this machine runs. Written by the target's own home.file entry
# (~/.config/home-manager-host), so it always matches the configuration that
# was last applied here. Before the first switch on a machine there is no
# marker, and the helper then refuses to guess — applying the wrong target
# would drop or add whole feature sets (gaming content, GNOME dotfiles).
_hm_default_host() {
  local marker="${HOME}/.config/home-manager-host"
  if [[ -r "$marker" ]]; then
    read -r host <"$marker"
    if [[ -n "$host" ]]; then
      print -r -- "$host"
      return
    fi
  fi
  print -r -- ""
}

# Resolve the target to apply: an explicit argument wins, otherwise the
# marker file. Prints nothing (and fails) when neither is available.
_hm_host() {
  local host="$1"
  if [[ -z "$host" ]]; then
    host="$(_hm_default_host)"
  fi
  if [[ -z "$host" ]]; then
    print -u2 "hms: no target known — pass one explicitly, e.g. 'hms silver-hour-gaming'."
    print -u2 "hms: known targets: container, wsl, silver-hour, silver-hour-gaming"
    return 1
  fi
  print -r -- "$host"
}

# Switch (build + activate) the remote flake. --refresh forces Nix to re-resolve
# the GitHub branch ref instead of reusing the cached tarball, so a freshly
# pushed commit is picked up.
hms() {
  local host
  host="$(_hm_host "${1:-}")" || return 1
  home-manager switch --flake "${_HM_FLAKE}#${host}" --impure --refresh "${@[2,-1]}"
}

# Build only (no activation) — preview a change.
hmb() {
  local host
  host="$(_hm_host "${1:-}")" || return 1
  home-manager build --flake "${_HM_FLAKE}#${host}" --impure --refresh "${@[2,-1]}"
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
