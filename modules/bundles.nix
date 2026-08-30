{ config, lib, pkgs, ... }:

# CLI "batteries" — package bundles selected per host via home.bundles.*.
# The lists live in ../pkgs/ as plain `{ pkgs }: [ ... ]` functions; bundles
# install into the user profile (home.packages), so NixOS hosts, WSL and
# containers all get the same mechanism.
#
#   container   base (default-on — zero config needed)
#   wsl         base + wsl
#   desktop     base + baseExtra (set in nixos-config's home-manager.users)
{
  options.home.bundles = {
    base = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Base CLI tooling (devcontainer-safe): shells, editors, git helpers,
          search/pagers and the lightweight toolchains. On by default for every
          target.
        '';
      };
    };
    baseExtra = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Visual/misc CLI tools + GUI extras (fonts, VS Code, fastfetch, …).
          Desktop hosts only — not for dev containers or WSL.
        '';
      };
    };
    wsl = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          WSL dev-host extras (dev container CLI, Claude Code, opencode,
          fastfetch, openfortivpn). No language toolchains, no GUI apps.
        '';
      };
    };
  };

  config.home.packages =
    let
      cfg = config.home.bundles;
    in
    lib.mkMerge [
      (lib.mkIf cfg.base.enable (import ../pkgs/base.nix { inherit pkgs; }))
      (lib.mkIf cfg.baseExtra.enable (import ../pkgs/base-extra.nix { inherit pkgs; }))
      (lib.mkIf cfg.wsl.enable (import ../pkgs/wsl.nix { inherit pkgs; }))
    ];
}
