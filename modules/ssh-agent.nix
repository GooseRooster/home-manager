{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  # The desktop gets its agent from gnome-keyring/gcr-ssh-agent; WSL uses
  # keychain to manage a persistent ssh-agent with a passphrase cached for
  # the life of the boot (re-prompts once per `wsl --shutdown`, not once
  # per terminal).
  home.packages = lib.mkIf cfg.wsl.enable [ pkgs.keychain ];
}
