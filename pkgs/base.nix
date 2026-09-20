# Base CLI tooling — devcontainer-safe. Selected via home.bundles.base
# (default-on for every target).
{ pkgs }:

# The LSP binaries here back the nvim config's base profile
# (files/nvim/lua/config/profile.lua: base_lsp + minimal_langs, gated
# on PATH presence at enable time — a host without them just silently skips
# attach instead of erroring). All are node/static-based, so they're
# NixOS-safe unlike Mason's prebuilt native binaries.
with pkgs; [
  bash-language-server
  bat
  btop
  carapace
  docker-compose-language-service
  dockerfile-language-server
  dust
  dysk
  eza
  fd
  gcc
  go
  mediainfo
  python3
  pyright
  rustup
  ffmpeg-full
  fish
  fzf
  gh
  delta
  deja
  imagemagick
  jq
  lazygit
  lua-language-server
  neovim
  nushell
  p7zip
  pipx
  poppler-utils
  resvg
  ripgrep
  ruff
  starship
  tealdeer
  topgrade
  trash-cli
  tree-sitter
  uutils-coreutils
  uv
  vscode-langservers-extracted
  yaml-language-server
  yazi
  zip
  zoxide
  unzip
  nodejs
  ouch
  file
  shellcheck
  shfmt
  stylua
]
