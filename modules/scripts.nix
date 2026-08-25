{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  home.file = {
    # Devcontainer template scaffolder — host/WSL only, not inside containers.
    ".local/bin/devcontainer-init" = lib.mkIf (!cfg.devcontainer.enable) {
      source = ../files/scripts/devcontainer-init;
      executable = true;
      force = true;
    };
  };
}
