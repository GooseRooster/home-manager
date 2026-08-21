{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  home.file = {
    # Game performance helper (tuned-adm + night light) — gaming hosts only.
    ".local/bin/game-performance.sh" = lib.mkIf cfg.gaming.enable {
      source = ../files/scripts/game-performance.sh;
      executable = true;
    };

    # Devcontainer template scaffolder — host/WSL only, not inside containers.
    ".local/bin/devcontainer-init" = lib.mkIf (!cfg.devcontainer.enable) {
      source = ../files/scripts/devcontainer-init;
      executable = true;
    };
  };
}
