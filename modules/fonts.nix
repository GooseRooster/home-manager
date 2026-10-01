{ config, lib, ... }:

let
  cfg = config.home.modules;
in
{
  # Clear the flatpak font cache just incase, if the font choice changed.
  home.activation.refreshFlatpakFontCache = lib.mkIf (!cfg.wsl.enable) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "$HOME/.var/app" ]; then
        run rm -rf "$HOME"/.var/app/*/cache/fontconfig
      fi
    ''
  );
}
