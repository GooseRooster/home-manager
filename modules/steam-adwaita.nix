{
  config,
  lib,
  pkgs,
  adwaitaForSteam ? null,
  ...
}:

# Adwaita-for-Steam integration for standalone Home Manager (silver-hour
# gaming image). The package is the same runtime installer wrapper used by
# nixos-config; only the service/activation plumbing is adapted to HM:
#
#   - the skin is installed at login and whenever tinty rewrites custom.css;
#   - the target is auto-detected (native ~/.steam/steam or Flatpak), because
#     the image may ship either flavour;
#   - the watched directory is created by activation instead of tmpfiles.
let
  cfg = config.home.modules.steamAdwaita;

  customCssDir = "${config.home.homeDirectory}/.config/AdwSteamGtk";
  customCss = "${customCssDir}/custom.css";

  adwaita-skin = pkgs.callPackage ../pkgs/adwaita-for-steam {
    src = adwaitaForSteam;
  };

  adwaita-refresh = pkgs.writeShellScriptBin "steam-adwaita-refresh" ''
    targetArg=()
    case "${cfg.target}" in
      auto)
        if [ -f "$HOME/.steam/steam/steamui/css/library.css" ]; then
          targetArg=(-t "$HOME/.steam/steam")
        elif [ -f "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/steamui/css/library.css" ]; then
          targetArg=(-t flatpak)
        else
          echo "steam-adwaita: no Steam installation found; skipping" >&2
          exit 0
        fi
        ;;
      native)
        targetArg=(-t "$HOME/.steam/steam")
        ;;
      flatpak)
        targetArg=(-t flatpak)
        ;;
      *)
        targetArg=(-t "${cfg.target}")
        ;;
    esac

    exec ${adwaita-skin}/bin/steam-adwaita-install \
      "''${targetArg[@]}" \
      --custom-css ${customCss} \
      "$@"
  '';

  # Theme tools can write custom.css several times in quick succession, and
  # path-unit events landing while the oneshot service is running are dropped
  # — so settle on a stable hash first, then install.
  adwaita-watched-refresh = pkgs.writeShellScript "steam-adwaita-watched-refresh" ''
    prev=""
    for i in 1 2 3 4 5 6 7 8 9 10; do
      cur="$(${pkgs.coreutils}/bin/sha256sum ${customCss} 2>/dev/null | ${pkgs.coreutils}/bin/cut -d' ' -f1 || true)"
      if [ -n "$cur" ] && [ "$cur" = "$prev" ]; then
        break
      fi
      prev="$cur"
      ${pkgs.coreutils}/bin/sleep 1
    done
    exec ${adwaita-refresh}/bin/steam-adwaita-refresh
  '';
in
{
  options.home.modules.steamAdwaita = {
    target = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = ''
        Steam install to skin: "auto" (prefer native, then Flatpak),
        "native" (~/.steam/steam), "flatpak", or an explicit Steam path.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = adwaitaForSteam != null;
        message = "home.modules.steamAdwaita requires the adwaita-for-steam flake input (see flake.nix extraSpecialArgs).";
      }
    ];

    home.packages = [
      adwaita-skin
      adwaita-refresh
    ];

    # The path unit needs the watched directory to exist at login, even before
    # the theming tool has written custom.css for the first time.
    home.activation.steamAdwaitaDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/AdwSteamGtk"
    '';

    # Runs install.py at login (and via `systemctl --user start
    # steam-adwaita`): Steam client updates can reset the patched steamui
    # CSS, so the skin also survives Steam's own reinstalls/verifies.
    # No RemainAfterExit — the path unit below must be able to re-trigger it.
    systemd.user.services.steam-adwaita = {
      Unit = {
        Description = "Re-apply the Adwaita-for-Steam skin to the Steam install";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${adwaita-watched-refresh}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Re-run the installer whenever tinty rewrites custom.css. Watch the
    # parent directory (not the file) so atomic write-temp-rename edits and
    # delete-and-recreate cycles don't lose the inotify watch; extra triggers
    # are harmless thanks to the debounce.
    systemd.user.paths.steam-adwaita = {
      Unit.Description = "Watch ~/.config/AdwSteamGtk/custom.css for theming-tool edits";
      Path = {
        PathChanged = customCssDir;
        Unit = "steam-adwaita.service";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
