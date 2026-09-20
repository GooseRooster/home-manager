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
        (ly + Umbriel + Noctalia v5). Gates session-specific integrations:
        tinty/gnomad are gnome-session-only (Noctalia's builtin templates own
        app theming in the noctalia session) and ghostty follows the theme
        rendered by whichever retint mechanism the session uses.
      '';
    };
    # Which shell "default shell" consumers hand off to: ghostty's `command`
    # (modules/ghostty.nix), the WSL bash hand-off (modules/wsl-shell-launcher.nix)
    # and nixos-config's termapp wrapper, which reads this flag back via
    # config.home-manager.users.<primary>.home.modules.defaultShell.
    defaultShell = lib.mkOption {
      type = lib.types.enum [ "nu" "zsh" ];
      default = "nu";
      description = ''
        Default interactive shell: "nu" (nushell) or "zsh". Set per host in
        hosts/*.nix; every consumer (ghostty command, WSL bash launcher,
        termapp) follows it together.
      '';
    };
    gaming = {
      enable = mkFlag "Gaming-specific dotfile content (yazi Steam/Emulation hops, tinty Vesktop theme hook).";
    };
    theming = {
      enable = mkFlag "Theming tooling config (tinty scheme sync, gnomad schemes).";
    };
    podmanAlias = {
      enable = mkFlag "DOCKER_HOST -> podman socket and docker -> podman alias in nushell.";
    };
    wsl = {
      enable = mkFlag "NixOS-WSL profile: skip GUI dotfiles.";
    };
  };
}
