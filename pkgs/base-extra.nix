# Visual/misc CLI tools + GUI extras (home.bundles.baseExtra — on for the
# silver-hour image targets).
# Note: `claude-code` is unfree; allowed by the host config
# (nixpkgs.config.allowUnfree in home.nix / nixos-config's nix.nix).
#
# Fonts and VS Code are not listed here: the silver-hour image installs the
# Nerd Fonts and VS Code system-wide, so the user profile would only duplicate
# them.
{ pkgs }:

with pkgs;
[
  cava
  chafa
  zk
  lazydocker
  ramalama
  claude-code
  opencode
  devcontainer
  resterm
]
