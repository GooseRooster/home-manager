{ lib, ... }:

# Feature flags — the Home Manager equivalent of chezmoi's `chezmoi.toml`
# `[data]` flags and the `.chezmoiignore.tmpl` / `*.tmpl` conditionals they
# drove. Hosts (hosts/*.nix) set these; modules use `lib.mkIf`/`lib.optionalString`
# to include or omit files. The inverse of chezmoi's *ignore* list.
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
        (ly + Umbriel + Noctalia v5). In the noctalia session Noctalia's
        builtin templates own app theming, so tinty config/tooling is dropped
        and ghostty points at Noctalia's rendered theme.
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
