{ config, lib, ... }:

let
  cfg = config.home.modules;
in
lib.mkIf cfg.theming.enable {
  # Noctalia owns app theming through its builtin templates; this module only
  # ships the custom palettes (custom is the only palette source stored as
  # files on disk) plus the shared wallpaper image.
  home.file = {
    ".config/noctalia/palettes/peat.json" = {
      force = true;
      source = ../files/noctalia/palettes/peat.json;
    };
    ".config/noctalia/palettes/peat_bog.json" = {
      force = true;
      source = ../files/noctalia/palettes/peat_bog.json;
    };
    ".config/noctalia/palettes/peat_mist.json" = {
      force = true;
      source = ../files/noctalia/palettes/peat_mist.json;
    };
    ".config/owl.jpg" = {
      source = ../files/owl.jpg;
      force = true;
    };
  };
}
