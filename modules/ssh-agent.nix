{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  # The desktop gets its agent from gnome-keyring; NixOS-WSL (and other
  # headless targets) run a user ssh-agent instead — mirroring chezmoi's
  # wsl-gated ssh-agent.service.
  services.ssh-agent.enable = cfg.wsl.enable;
}
