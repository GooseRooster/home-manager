# Custom zsh functions. Kept in its own file so it can be edited without
# touching modules/zsh.nix. Sourced from programs.zsh.initContent.


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
