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
    # Which desktop session stack this dotfiles config targets. Set directly
    # in hosts/*.nix (standalone) or mirrored from the NixOS
    # modules.desktop.session option by the host config (integrated).
    session = lib.mkOption {
      type = lib.types.enum [ "gnome" "noctalia" ];
      default = "gnome";
      description = ''
        Desktop session stack: "gnome" (GDM + GNOME Shell) or "noctalia"
        (ly + Sway + Noctalia v5). Gates session-specific integrations:
        tinty/gnomad are gnome-session-only (Noctalia's builtin templates own
        app theming in the noctalia session) and ghostty follows the theme
        rendered by whichever retint mechanism the session uses.
      '';
    };
    gaming = {
      enable = mkFlag "Gaming-specific dotfile content (yazi Steam/Emulation hops, tinty Vesktop theme hook).";
    };
    theming = {
      enable = mkFlag "Theming tooling config (tinty scheme sync, gnomad schemes).";
    };
    podmanAlias = {
      enable = mkFlag "DOCKER_HOST -> podman socket and docker -> podman alias in the shell.";
    };
    wsl = {
      enable = mkFlag "NixOS-WSL profile: skip GUI dotfiles.";
    };
  };
}
