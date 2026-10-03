{
  config,
  lib,
  pkgs,
  ...
}:

# User-level theming tooling (moved out of nixos-config's modules/extras):
# recolors ~/Pictures/Wallpapers with the active Noctalia palette (gowall) and
# exposes a batch refresh hook (theme_regen) that Noctalia calls when the
# palette changes. Both are user concerns — they run in the session and talk
# to the Noctalia IPC, not to system services.
let
  cfg = config.home.modules;

  # Prefer the package the running session shell was built from
  # (programs.noctalia.package, set by the noctalia flake HM module), falling
  # back to nixpkgs.
  noctaliaPkg =
    if config.programs.noctalia.package != null
    then config.programs.noctalia.package
    else pkgs.noctalia;

  gowallConvertWallpapers = pkgs.writeShellApplication {
    name = "gowall_convert_wallpapers";
    runtimeInputs = with pkgs; [
      gowall
      jq
      noctaliaPkg
    ];
    text = builtins.readFile ../files/scripts/gowall_convert_wallpapers;
  };

  themeRegen = pkgs.writeShellApplication {
    name = "theme_regen";
    runtimeInputs = [
      pkgs.sway
      gowallConvertWallpapers
    ];
    text = builtins.readFile ../files/scripts/theme_regen;
  };
in
lib.mkIf cfg.theming.enable {
  home.packages = [
    gowallConvertWallpapers
    themeRegen
  ];
}
