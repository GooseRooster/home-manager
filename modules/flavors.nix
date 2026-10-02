{ lib, ... }:

# Feature flags. Hosts (hosts/*.nix) set these; modules use
# `lib.mkIf`/`lib.optionalString` to include or omit files.
let
  mkFlag = desc: lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = desc;
  };
in
{
  options.home.modules = {
    # Full desktop session configs (Sway/Noctalia, GTK theming, terminal
    # emulator). Desktop hosts set this; dev containers and WSL leave it off.
    desktop = {
      enable = mkFlag "Full desktop session configs (Sway/Noctalia, GTK theming, terminal).";
    };
    gaming = {
      enable = mkFlag "Gaming-specific dotfile content (yazi Steam/Emulation hops).";
    };
    theming = {
      enable = mkFlag "Theming tooling config (Noctalia palettes).";
    };
    podmanAlias = {
      enable = mkFlag "DOCKER_HOST -> podman socket and docker -> podman alias in the shell.";
    };
    wsl = {
      enable = mkFlag "NixOS-WSL profile: skip GUI dotfiles.";
    };
  };
}
