{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  iniFormat = pkgs.formats.ini { listsAsDuplicateKeys = true; };

  settings = {
    main = {
      # Terminal font/size: matches the previous Ghostty setup (Iosevka
      # Nerd Font Mono at size 14). The font is installed system-wide by
      # nixos-config (modules/desktop/apps.nix).
      font = "Iosevka Nerd Font Mono:size=14";
    }
    // lib.optionalAttrs cfg.theming.enable {
      # The `include` points at the theme rendered by the session's retint
      # mechanism: Noctalia's builtin `foot` template writes
      # ~/.config/foot/themes/noctalia. Its apply.sh no-ops when foot.ini
      # already contains an include=...noctalia line — which matters because
      # HM's config is a read-only symlink.
      include = "~/.config/foot/themes/noctalia";
    };
  };
in
{
  # The foot binary is installed system-wide by nixos-config
  # (modules/desktop/terminal.nix); HM only writes the config file. Unlike
  # programs.ghostty, programs.foot has no `package = null` escape hatch (it
  # puts cfg.package straight into home.packages), so foot.ini is written
  # directly with the ini generator — the same "HM owns the config, system
  # owns the binary" split, keeping non-desktop targets GUI-package-free.
  xdg.configFile."foot/foot.ini" = lib.mkIf cfg.desktop.enable {
    source = iniFormat.generate "foot.ini" settings;
  };
}
