{ lib, ... }:

# Feature flags. Hosts (hosts/*.nix) set these; modules use
# `lib.mkIf`/`lib.optionalString` to include or omit files.
let
  mkFlag =
    desc:
    lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = desc;
    };
in
{
  options.home.modules = {
    gaming = {
      enable = mkFlag "Gaming-specific dotfile content (yazi Steam/Emulation hops).";
    };
    steamAdwaita = {
      enable = mkFlag "Adwaita-for-Steam skinning (native or Flatpak Steam).";
    };
    podmanAlias = {
      enable = mkFlag "DOCKER_HOST -> podman socket and docker -> podman alias in the shell.";
    };
    wsl = {
      enable = mkFlag "WSL profile: skip GUI dotfiles.";
    };
    silverHour = {
      enable = mkFlag "silver-hour image profile (GNOME, system fonts, gnomad/tinty theming).";
    };
  };
}
