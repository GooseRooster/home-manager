# Visual/misc CLI tools + GUI extras — desktop hosts only (home.bundles.baseExtra).
# Note: `vscode` and `claude-code` are unfree; allowed by the host config
# (nixpkgs.config.allowUnfree in home.nix / nixos-config's nix.nix).
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
  vscode
  resterm

  nerd-fonts."fira-code"
  nerd-fonts."jetbrains-mono"
  nerd-fonts."sauce-code-pro"
  nerd-fonts."symbols-only"
  nerd-fonts."ubuntu"

  # gsr-ui (GPU Screen Recorder's new overlay) reads its font from
  # org.gnome.desktop.interface font-name; inside the Flatpak sandbox that
  # resolves to the schema default "Adwaita Sans", which the Freedesktop
  # runtime doesn't ship. Installing it here makes it visible via /run/host/fonts.
  adwaita-fonts
]
