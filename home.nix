{ config, pkgs, ... }:

# Shared base: imports every module, exposes the flavor options (see
# modules/flavors.nix), and sets the common XDG / stateVersion plumbing.
# Per-target username, homeDirectory and feature flags live in hosts/*.nix.
{
  imports = [
    ./modules/flavors.nix
    ./modules/bundles.nix
    ./modules/flatpak.nix
    ./modules/theming-tools-silver-hour.nix
    ./modules/zsh.nix
    ./modules/wsl-shell-launcher.nix
    ./modules/eza.nix
    ./modules/direnv.nix
    ./modules/yazi.nix
    ./modules/nvim.nix
    ./modules/herdr.nix
    ./modules/starship.nix
    ./modules/ghostty.nix
    ./modules/mpv.nix
    ./modules/btop.nix
    ./modules/lazygit.nix
    ./modules/lazydocker.nix
    ./modules/fonts.nix
    ./modules/gnome-extensions.nix
    ./modules/gnome-settings.nix
    ./modules/ssh-agent.nix
    ./modules/scripts.nix
    ./modules/caches.nix
    ./modules/podman.nix
  ];

  programs.home-manager.enable = true;
  xdg.enable = true;

  # User-level GC: prunes this user's nix profile generations (older than the
  # window) and garbage-collects user-reachable store paths. Runs as a systemd
  # user timer; complements the system-level nix.gc in nixos-config, which
  # never touches per-user profiles.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Some bundle packages are unfree (claude-code in base-extra/wsl). This
  # scopes allowUnfree to the HM-built nixpkgs instance only; system-wide nix
  # commands still need `NIXPKGS_ALLOW_UNFREE=1 --impure` (or a user
  # ~/.config/nix/nix.conf entry).
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.05";
}
