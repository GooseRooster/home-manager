# Base CLI tooling — devcontainer-safe. Selected via home.bundles.base
# (default-on for every target).
{ pkgs }:

with pkgs; [
  bat
  btop
  carapace
  dust
  dysk
  eza
  fd
  gcc
  go
  mediainfo
  python3
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
  neovim
  nushell
  p7zip
  pipx
  poppler-utils
  resvg
  ripgrep
  starship
  tealdeer
  topgrade
  trash-cli
  tree-sitter
  uutils-coreutils
  uv
  yazi
  zip
  zoxide
  unzip
  nodejs
  file
  shellcheck
  stylua
]
