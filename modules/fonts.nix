{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # Flatpak sandboxes don't get NixOS's system fonts: the host font dir is
  # exposed, but it carries a fontconfig cache the runtime considers valid, and
  # fonts added to `fonts.packages` (Iosevka, ...) are silently skipped — so
  # GTK gets the right *name* from the Settings portal but can't resolve it and
  # falls back to the default. Flatpak *does* bind ~/.local/share/fonts as
  # /run/host/user-fonts and scans it fresh, so symlink the session fonts there.
  # (Not gated on the session: any desktop here benefits.)
  fonts = {
    iosevka = pkgs.nerd-fonts.iosevka;
    jetbrains-mono = pkgs.nerd-fonts.jetbrains-mono;
    noto = pkgs.noto-fonts;
    noto-color-emoji = pkgs.noto-fonts-color-emoji;
  };
in
{
  home.file = lib.mkIf (!cfg.wsl.enable) (
    lib.mapAttrs' (
      name: pkg:
      lib.nameValuePair ".local/share/fonts/${name}" {
        source = "${pkg}/share/fonts";
      }
    ) fonts
  );
}
