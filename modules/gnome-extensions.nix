{
  config,
  lib,
  pkgs,
  ...
}:

# User-level GNOME Shell extensions: the ones that live in
# ~/.local/share/gnome-shell/extensions and are therefore part of the
# *person* (they follow across machines/OSes), not the image.
#
# The builds themselves are pinned in ../pkgs/gnome-extensions.nix (EGO
# downloads, hash-checked) and installed here as symlinks into
# ~/.local/share/gnome-shell/extensions/<uuid> — the only place GNOME
# looks for user extensions. The image's own extensions (in
# /usr/share/gnome-shell/extensions) stay the image's business.
#
# The enabled-extensions list is *not* owned here: the image ships its own
# list in /etc/dconf/db/local.d and the user may enable further extensions
# by hand (MosaicWM, for one). This module only appends the extensions it
# manages, so nothing else is disturbed.
{
  options.home.bundles.gnomeExtensions = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        User-level GNOME Shell extensions (pinned EGO builds) plus their
        settings. Off by default — only the GNOME desktop targets want it.
      '';
    };
  };

  config = lib.mkIf config.home.bundles.gnomeExtensions.enable (
    let
      extensions = import ../pkgs/gnome-extensions.nix { inherit pkgs; };

      # dconf path -> settings, for the extensions that carry a GSettings
      # schema. Only values that differ from the schema default are listed;
      # everything else stays whatever the extension's own default is.
      extensionSettings = {
        "org/gnome/shell/extensions/chromaleon" = {
          create-shortcut = true;
          morewaita = true;
          prefer-light = true;
          recolor-apps = true;
          recolor-folders = true;
          tint-apps = true;
          tint-shell = true;
          user-themes-warning = false;
        };
        "org/gnome/shell/extensions/nowplaying" = {
          panel-box = "left";
          panel-index = 1;
          show-spectrum = true;
          spectrum-all-sound = true;
          spectrum-shape = "waves";
        };
        "org/gnome/shell/extensions/quake-terminal" = {
          always-on-top = true;
          terminal-id = "com.mitchellh.ghostty.desktop";
          terminal-shortcut = [ "<Super>backslash" ];
          vertical-size = 85;
        };
        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = [
            "_processor_usage_"
            "__temperature_avg__"
            "_memory_usage_"
            "_storage_used_%_"
          ];
          icon-style = 1;
          storage-path = "/var";
        };
        "org/gnome/shell/extensions/weatherornot" = {
          position = "clock-left";
        };
      };
    in
    {
      # The extension itself: a symlink into the nix store, so the tree is
      # content-addressed and read-only. GNOME follows the symlink (it
      # enumerates the extensions dir without NOFOLLOW_SYMLINKS) and only
      # requires the directory name to equal the uuid.
      home.file = lib.listToAttrs (
        map (ext: {
          name = ".local/share/gnome-shell/extensions/${ext.id}";
          value = {
            source = "${ext.package}/share/gnome-shell/extensions/${ext.id}";
          };
        }) extensions
      );

      dconf.settings = extensionSettings;

      # Enable the managed extensions, additively: append the uuids that
      # are not in the list yet, leave everything else alone. The image
      # enables its own extensions through /etc/dconf/db/local.d, and the
      # user may have enabled others by hand — neither should be lost.
      home.activation.gnomeExtensionsEnable = lib.hm.dag.entryAfter [ "installPackages" ] ''
        gsettings_bin="${pkgs.glib}/bin/gsettings"
        current="$("$gsettings_bin" get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []")"

        case "$current" in
          "@as []") base="" ;;
          *) base="''${current%]}" ;;
        esac

        added=""
        for uuid in ${lib.concatStringsSep " " (map (ext: ext.id) extensions)}; do
          case "$current" in
            *"'$uuid'"*) continue ;;
          esac
          if [ -z "$added" ]; then
            added="'$uuid'"
          else
            added="$added, '$uuid'"
          fi
        done

        if [ -n "$added" ]; then
          if [ -z "$base" ]; then
            new="[$added]"
          else
            new="$base, $added]"
          fi
          "$gsettings_bin" set org.gnome.shell enabled-extensions "$new"
          echo "enabled extension(s): $added"
        fi
      '';
    }
  );
}
