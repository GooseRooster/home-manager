{
  config,
  lib,
  nix-flatpak,
  ...
}:

# Per-user Flatpaks: user-facing / opinionated GUI apps that belong to the
# person rather than the machine (the system side keeps the "normie" baseline
# in nixos-config/modules/flatpak/system.nix). Installed with `flatpak --user`
# via nix-flatpak's home-manager module, so they survive a host/OS migration
# and map cleanly onto a standalone-HM future.
#
# Selected per host via home.bundles.flatpak{Base,Multimedia,Gaming} — same
# list-function pattern as the CLI bundles in modules/bundles.nix. The lists
# live in ../pkgs/flatpak-*.nix.
{
  imports = [ nix-flatpak.homeManagerModules.nix-flatpak ];

  options.home.bundles.flatpak = {
    base = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Base user-facing Flatpaks (media, graphics, misc GUI apps).";
      };
    };
    multimedia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Multimedia Flatpaks (Stremio, ...).";
      };
    };
    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Gaming Flatpaks (Proton management, emulators, ...).";
      };
    };
  };

  # Enable the HM flatpak service only when a user set is actually selected;
  # otherwise leave the system-side flatpak daemon alone for lean targets
  # (containers, WSL).
  config = lib.mkIf (config.home.bundles.flatpak.base.enable
    || config.home.bundles.flatpak.multimedia.enable
    || config.home.bundles.flatpak.gaming.enable) {
    services.flatpak.enable = true;
    services.flatpak.packages =
      let
        cfg = config.home.bundles.flatpak;
      in
      lib.optionals cfg.base.enable (import ../pkgs/flatpak-base.nix)
      ++ lib.optionals cfg.multimedia.enable (import ../pkgs/flatpak-multimedia.nix)
      ++ lib.optionals cfg.gaming.enable (import ../pkgs/flatpak-gaming.nix);
  };
}
