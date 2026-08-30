{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only: skipped on WSL
  desktopOnly = !cfg.wsl.enable;
in
{
  programs.ghostty = lib.mkIf desktopOnly {
    enable = true;
    # The binary is installed system-wide by nixos-config
    # (modules/desktop/terminal.nix); HM only writes the config file.
    # package = null also disables the module's onChange +validate-config
    # hook, which needs a real ghostty binary to exec — with a stub package
    # it fails activation (getExe on empty-directory).
    # dbus.packages, the other null blocker, is only set under
    # systemd.enable, which stays off: the system-wide ghostty package
    # ships its own user units, and the pre-native setup had no
    # HM-provided unit either.
    package = null;
    systemd.enable = false;

    # The shell is the Nix nu.
    settings = {
      command = "${pkgs.nushell}/bin/nu";
      confirm-close-surface = false;
      adjust-cell-height = "15%";
      font-size = 14;
    } // lib.optionalAttrs cfg.theming.enable {
      # The `theme` line points at whichever retint mechanism the session
      # uses: tinty writes ~/.config/ghostty/themes/tinted-theming, while
      # Noctalia's builtin ghostty template writes
      # ~/.config/ghostty/themes/noctalia (and its apply.sh no-ops on configs
      # already set to `theme = noctalia`, which matters because HM's config
      # is a read-only symlink).
      theme = if cfg.session == "noctalia" then "noctalia" else "tinted-theming";
    };
  };
}
