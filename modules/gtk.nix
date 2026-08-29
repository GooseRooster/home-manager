{ config, lib, pkgs, ... }:

# GTK look & feel: fonts. Two mechanisms, both covered:
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
  };

  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "JetBrainsMono Nerd Font Mono 11";
    document-font-name = "JetBrainsMono Nerd Font Mono 11";
    monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
  };
}
