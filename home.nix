{ config, pkgs, ... }:

# Shared base: imports every module, exposes the flavor options (see
# modules/flavors.nix), and sets the common XDG / stateVersion plumbing.
# Per-target username, homeDirectory and feature flags live in hosts/*.nix.
{
  imports = [
    ./modules/flavors.nix
    ./modules/bundles.nix
    ./modules/nushell.nix
    ./modules/zsh.nix
    ./modules/wsl-shell-launcher.nix
    ./modules/eza.nix
    ./modules/yazi.nix
    ./modules/nvim.nix
    ./modules/television.nix
    ./modules/starship.nix
    ./modules/topgrade.nix
    ./modules/misc-config.nix
    ./modules/ghostty.nix
    ./modules/tools.nix
    ./modules/gtk.nix
    ./modules/ssh-agent.nix
    ./modules/scripts.nix
    ./modules/caches.nix
    ./modules/podman.nix
  ];

  programs.home-manager.enable = true;
  xdg.enable = true;

  # The NixOS hosts consume this repo through nixos-config's
  # `home-manager.users.<name>.imports = [ dotfiles.hmModules.default ]`, which
  # sets home-manager.backupFileExtension (hm-backup) on its side.

  # Some bundle packages are unfree (vscode in base-extra, claude-code in
  # base-extra/wsl). This scopes allowUnfree to the HM-built nixpkgs instance
  # only; system-wide nix commands still need `NIXPKGS_ALLOW_UNFREE=1 --impure`
  # (or a user ~/.config/nix/nix.conf entry).
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.05";
}
