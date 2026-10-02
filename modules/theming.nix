{ config, lib, ... }:

let
  cfg = config.home.modules;
  paletteDir = ../files/noctalia/palettes;
  palettes = lib.filterAttrs (_: type: type == "regular") (builtins.readDir paletteDir);
in
lib.mkIf cfg.theming.enable {
  # Noctalia owns app theming through its builtin templates; this module only
  # ships the custom palettes (custom is the only palette source stored as
  # files on disk) plus the shared wallpaper image.
  home.file = lib.mapAttrs' (name: _: {
    name = ".config/noctalia/palettes/${name}";
    value = {
      force = true;
      source = paletteDir + "/${name}";
    };
  }) palettes // {
    ".config/owl.jpg" = {
      source = ../files/owl.jpg;
      force = true;
    };
  };
}
