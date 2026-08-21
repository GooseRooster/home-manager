{ config, pkgs, ... }:

# Shared base: imports every module, exposes the flavor options (see
# modules/flavors.nix), and sets the common XDG / stateVersion plumbing.
# Per-target username, homeDirectory and feature flags live in hosts/*.nix.
{
  imports = [
    ./modules/flavors.nix
    ./modules/nushell.nix
    ./modules/nvim.nix
    ./modules/yazi.nix
    ./modules/starship.nix
    ./modules/topgrade.nix
    ./modules/misc-config.nix
    ./modules/ssh-agent.nix
    ./modules/scripts.nix
    ./modules/caches.nix
    ./modules/podman.nix
  ];

  programs.home-manager.enable = true;
  xdg.enable = true;

  home.stateVersion = "26.05";
}
