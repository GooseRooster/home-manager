{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  # The desktop gets its agent from gcr-ssh-agent (gnome-keyring dropped its
  # SSH component); nixos-config's sway module exports SSH_AUTH_SOCK for the
  # session. WSL uses keychain to manage a persistent ssh-agent with a
  # passphrase cached for the life of the boot (re-prompts once per
  # `wsl --shutdown`, not once per terminal).
  home.packages = lib.mkIf cfg.wsl.enable [ pkgs.keychain ];
}
