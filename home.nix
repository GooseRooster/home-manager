{ config, pkgs, ... }:

# Shared base: imports every module, exposes the flavor options (see
# modules/flavors.nix), and sets the common XDG / stateVersion plumbing.
# Per-target username, homeDirectory and feature flags live in hosts/*.nix.
{
  imports = [
    ./modules/flavors.nix
    ./modules/nushell.nix
    ./modules/bootstrap.nix
    ./modules/yazi.nix
    ./modules/starship.nix
    ./modules/topgrade.nix
    ./modules/misc-config.nix
    ./modules/gtk.nix
    ./modules/ssh-agent.nix
    ./modules/scripts.nix
    ./modules/caches.nix
    ./modules/podman.nix
  ];

  programs.home-manager.enable = true;
  xdg.enable = true;

  # When switching between the two HM tracks (standalone `home-manager switch`
  # vs the NixOS-integrated generation), pass `-b hm-backup` to standalone
  # switches so pre-existing files from the other track are backed up instead
  # of erroring. The integrated side sets home-manager.backupFileExtension in
  # the nixos-config host, which does the same for system rebuilds.

  # Some HM-referenced packages (or #base-extra bundles) are unfree (e.g. vscode).
  # This scopes allowUnfree to the HM-built nixpkgs instance only; system-wide
  # nix commands still need `NIXPKGS_ALLOW_UNFREE=1 --impure` (or a user
  # ~/.config/nix/nix.conf entry).
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.05";
}
