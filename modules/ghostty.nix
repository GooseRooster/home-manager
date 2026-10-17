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

    settings = {
      # No `command`: ghostty falls back to $SHELL (zsh on silver-hour).
      confirm-close-surface = false;
      adjust-cell-height = "15%";
      font-size = 14;
      # No `font-family`: the image installs Nerd Fonts system-wide and the
      # desktop's font choice owns this; ghostty's own default would be
      # JetBrains Mono.
      #
      # Theme: the tinted-theming theme file is written by the tinty
      # tinted-terminal hook (modules/theming-tools-silver-hour.nix) to
      # ~/.config/ghostty/themes/tinted-theming.
      theme = "tinted-theming";
    };
  };
}
