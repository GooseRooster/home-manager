{
  config,
  lib,
  pkgs,
  ...
}:

# Windows Terminal theming from WSL (wsl + tinty only). tinted-terminal ships a
# Windows Terminal template; its tinty hook (files/scripts/wt-tinty-apply)
# upserts the scheme into the Windows-side settings.json as "tinted-theming"
# and switches this distro's profile to it. Windows Terminal reloads the file
# on change, so `tinty apply <scheme>` retints open tabs live.
#
# Everything that reads the ANSI palette (yazi, lazygit, btop, starship, zsh
# highlighting) follows along, since Windows Terminal owns that palette here.
let
  cfg = config.home.modules;
  wtCfg = cfg.windowsTerminal;

  wtTintyApply = pkgs.writeShellApplication {
    name = "wt-tinty-apply";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];
    text = builtins.readFile ../files/scripts/wt-tinty-apply;
  };

  # Optional overrides; unset ones fall through to the script's autodetection.
  hookEnv = lib.concatStringsSep " " (
    lib.optional (wtCfg.settingsPath != null) "WT_SETTINGS=${lib.escapeShellArg wtCfg.settingsPath}"
    ++ lib.optional (wtCfg.profileName != null) "WT_PROFILE=${lib.escapeShellArg wtCfg.profileName}"
  );
in
{
  options.home.modules.windowsTerminal = {
    settingsPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/mnt/c/Users/me/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json";
      description = ''
        Windows Terminal settings.json, as a WSL path. null autodetects the
        Store (stable, then Preview) and unpackaged installs under /mnt/c/Users.
      '';
    };
    profileName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the WSL profile whose colorScheme tinty switches. null uses
        $WSL_DISTRO_NAME at apply time.
      '';
    };
  };

  config = lib.mkIf (cfg.wsl.enable && cfg.tinty.enable) {
    # On PATH too, so the current scheme can be re-pushed by hand
    # (`wt-tinty-apply`), e.g. after resetting Windows Terminal's settings.
    home.packages = [ wtTintyApply ];

    home.modules.tinty.items = [
      {
        name = "tinted-terminal-wt";
        path = "https://github.com/tinted-theming/tinted-terminal";
        themes-dir = "themes/windows-terminal";
        supported-systems = [ "base16" "base24" "tinted8" ];
        hook = lib.concatStringsSep " " (
          lib.optional (hookEnv != "") hookEnv ++ [ "${wtTintyApply}/bin/wt-tinty-apply" ]
        );
      }
    ];
  };
}
