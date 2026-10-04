{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home.modules;

  # Image formats GNOME Loupe declares in its .desktop MimeType.
  imageTypes = [
    "image/apng"
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heic"
    "image/jp2"
    "image/jpeg"
    "image/jxl"
    "image/png"
    "image/qoi"
    "image/svg+xml"
    "image/svg+xml-compressed"
    "image/tiff"
    "image/vnd.microsoft.icon"
    "image/webp"
    "image/x-dds"
    "image/x-exr"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-qoi"
    "image/x-tga"
    "image/x-win-bitmap"
    "image/x-xbitmap"
    "image/x-xpixmap"
  ];

  # Browser handler MIME types and the previous runtime defaults; declared so
  # taking ownership of ~/.config/mimeapps.list doesn't drop them.
  browserDefaults = {
    "x-scheme-handler/http" = "zen-twilight.desktop";
    "x-scheme-handler/https" = "zen-twilight.desktop";
    "x-scheme-handler/chrome" = "firefox.desktop";
    "text/html" = "zen-twilight.desktop";
    "application/x-extension-htm" = "firefox.desktop";
    "application/x-extension-html" = "firefox.desktop";
    "application/x-extension-shtml" = "firefox.desktop";
    "application/xhtml+xml" = "zen-twilight.desktop";
    "application/x-extension-xhtml" = "firefox.desktop";
    "application/x-extension-xht" = "firefox.desktop";
  };
in

# GTK look & feel: fonts + theme name. Two mechanisms, both covered:
#   - ~/.config/gtk-{3,4}.0/settings.ini (gtk-font-name) — read by plain GTK
#     apps on Wayland (no xsettings provider in a bare Sway session).
#   - org.gnome.desktop.interface GSettings keys — read by GNOME-runtime
#     flatpaks, xdg-desktop-portal-gtk and gsettings-aware apps.
# GTK theme is deliberately NOT set here: the noctalia session's template
# flow (adw-gtk3 + gtk.css overlay, see nixos-config modules/desktop/noctalia.nix)
# owns gtk-theme via its apply hook, and HM shouldn't fight it.
{
  gtk = {
    enable = true;
    # Note: name and size are separate — the module composes "name size" for
    # both settings.ini and the dconf font-name key.
    font = {
      name = "Iosevka Nerd Font Mono";
      size = 11;
    };

    # Hatter icon theme (installed by nixos-config). `package` stays null so HM
    # only writes gtk-icon-theme-name into settings.ini; the theme files are
    # provided system-wide. Noctalia's icon resolver reads this (and the
    # gsettings key below) for shell/app icons.
    iconTheme = {
      name = "Hatter-Slate";
      package = null;
    };

    # gtk-theme-name in settings.ini: read unconditionally by every GTK app at
    # startup (no GSettings bridge required on Wayland). This is what makes
    # GTK3 apps (Firefox widgets, GNOME Boxes, ...) follow the Noctalia
    # palette via adw-gtk3 + the template's gtk.css overlay. Harmless for
    # GTK4/libadwaita apps, which ignore gtk-theme and get colors from the
    # gtk.css overlay instead.
    gtk3.extraConfig = lib.optionalAttrs cfg.desktop.enable {
      gtk-theme-name = "adw-gtk3-dark";
    };
    gtk4.extraConfig = lib.optionalAttrs cfg.desktop.enable {
      gtk-theme-name = "adw-gtk3-dark";
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "Iosevka Nerd Font Mono 11";
    document-font-name = "Iosevka Nerd Font Mono 11";
    monospace-font-name = "Iosevka Nerd Font Mono 11";
    icon-theme = "Hatter-Slate";
  };

  # Default applications (the XDG standard is ~/.config/mimeapps.list,
  # [Default Applications]). Images open in GNOME Loupe (system Flatpak)
  # instead of Gradia, which otherwise wins via the Flatpak mimeinfo.cache.
  xdg.mimeApps = lib.mkIf cfg.desktop.enable {
    enable = true;

    defaultApplications = browserDefaults // lib.genAttrs imageTypes (_: "org.gnome.Loupe.desktop");

    associations.added = lib.genAttrs (builtins.attrNames browserDefaults) (_: [
      "firefox.desktop"
      "zen-twilight.desktop"
    ]);
  };
}
