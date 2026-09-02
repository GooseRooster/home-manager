# Visual/misc CLI tools + GUI extras — desktop hosts only (home.bundles.baseExtra).
# Note: `vscode` and `claude-code` are unfree; allowed by the host config
# (nixpkgs.config.allowUnfree in home.nix / nixos-config's nix.nix).
{ pkgs }:

with pkgs; [
  cava
  chafa
  fastfetch
  zk
  lazydocker
  ramalama
  claude-code
  opencode
  devcontainer
  vscode

  nerd-fonts."fira-code"
  nerd-fonts."jetbrains-mono"
  nerd-fonts."sauce-code-pro"
  nerd-fonts."symbols-only"
  nerd-fonts."ubuntu"
]
