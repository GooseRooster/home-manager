{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in

# GTK look & feel: fonts + theme name. Two mechanisms, both covered:
#   - ~/.config/gtk-{3,4}.0/settings.ini (gtk-font-name) — read by plain GTK
#     apps on Wayland (no xsettings provider outside GNOME).
#   - org.gnome.desktop.interface GSettings keys — read by GNOME-runtime
#     flatpaks, xdg-desktop-portal-gtk and gsettings-aware apps.
# GTK theme is deliberately NOT set here: the noctalia session's template
# flow (adw-gtk3 + gtk.css overlay, see nixos-config modules/desktop/noctalia.nix)
# owns gtk-theme via its apply hook, and HM shouldn't fight it. Under the
# gnome session gnomad/GNOME manage the theme as before.
{
  gtk = {
    enable = true;
    # Note: name and size are separate — the module composes "name size" for
    # both settings.ini and the dconf font-name key.
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };

    # gtk-theme-name in settings.ini: read unconditionally by every GTK app at
    # startup (no GSettings bridge required on Wayland). This is what makes
    # GTK3 apps (Firefox widgets, GNOME Boxes, ...) follow the Noctalia
    # palette via adw-gtk3 + the template's gtk.css overlay. In the gnome
    # session this stays unset so gnomad/GNOME (XSettings, which outranks
    # settings.ini) keeps control. Harmless for GTK4/libadwaita apps, which
    # ignore gtk-theme and get colors from the gtk.css overlay instead.
    gtk3.extraConfig = lib.optionalAttrs (cfg.session == "noctalia") {
      gtk-theme-name = "adw-gtk3-dark";
    };
    gtk4.extraConfig = lib.optionalAttrs (cfg.session == "noctalia") {
      gtk-theme-name = "adw-gtk3-dark";
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "JetBrainsMono Nerd Font Mono 11";
    document-font-name = "JetBrainsMono Nerd Font Mono 11";
    monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
  };
}
