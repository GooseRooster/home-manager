{
  config,
  lib,
  ...
}:

# GNOME desktop settings that are opinions rather than image policy: the
# Multitasking panel, the alert sound, the default applications and the
# keyboard shortcuts.
#
# The image (silver-hour) ships GNOME defaults in /etc/dconf/db/local.d;
# everything here is the user's deviation from those defaults, declared so
# it survives a re-image and can be reviewed in the diff.
{
  options.home.modules.gnomeSettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Declarative GNOME desktop settings (multitasking, alert sound,
        default applications, keyboard shortcuts). Desktop hosts only.
      '';
    };
  };

  config = lib.mkIf config.home.modules.gnomeSettings.enable {
    dconf.settings = {
      # Multitasking: no edge tiling, workspaces span all displays, and the
      # window switcher only looks at the current workspace.
      "org/gnome/mutter" = {
        attach-modal-dialogs = false;
        edge-tiling = false;
        workspaces-only-on-primary = false;
      };
      "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
      };

      # Sound: the alert sound is a custom canberra theme (see the
      # activation step below), the "Swing" sample of the GNOME sound theme.
      "org/gnome/desktop/sound" = {
        event-sounds = true;
        theme-name = "__custom";
      };

      # Keyboard shortcuts: window management, workspace switching and the
      # overview shortcuts that are in the way of the tiling bindings.
      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        maximize = [ ];
        switch-to-workspace-left = [ "<Alt><Super>k" ];
        switch-to-workspace-right = [ "<Alt><Super>j" ];
        unmaximize = [ "<Alt>F5" ];
      };
      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ ];
        toggle-tiled-right = [ ];
      };
      "org/gnome/shell/keybindings" = {
        shift-overview-down = [ ];
        shift-overview-up = [ ];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        control-center = [ "<Super>i" ];
        # The built-in "Home Folder" action goes through GIO, which hands
        # the home folder to the *running* file manager — it reuses the
        # window that already shows it instead of opening a new one. It
        # is replaced by the custom binding below, which asks Nautilus
        # for a new window explicitly.
        home = [ ];
        www = [ "<Super>b" ];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        command = "ghostty";
        binding = "<Super>Return";
      };
      # Home folder, always in a new window.
      #
      # Nautilus is a single-instance GApplication: activating it with a
      # URI that is already open raises that window instead of opening
      # another one. The "home" media key cannot ask for a new window,
      # because it launches the folder through GIO
      # (g_app_info_launch_default_for_uri), and GIO hands the URI to the
      # running instance over D-Bus — the --new-window in the desktop
      # entry's Exec line never reaches it. Calling Nautilus directly
      # does pass the flag through, so every press opens another window.
      #
      # The path is absolute because gsd runs the command without a
      # shell: no ~, no $HOME.
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Home Folder (new window)";
        command = "nautilus --new-window ${config.home.homeDirectory}";
        binding = "<Super>e";
      };
      # GSR screenshot/recording helpers, shipped at /usr/bin by the image.
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "GSR Screenshot (Fullscreen)";
        command = "gsr-shot full";
        binding = "<Super>Print";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "GSR Record (screen)";
        command = "gsr-rec screen";
        binding = "<Alt><Super>1";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        name = "GSR Record Stop";
        command = "gsr-rec stop";
        binding = "<Alt><Super>q";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        name = "GSR Record (screen + mic)";
        command = "gsr-rec --mic screen";
        binding = "<Alt><Super>2";
      };
    };

    # The alert sound theme: index.theme plus the two event sounds.
    #
    # The sounds are absolute symlinks into the image's sound theme, so
    # canberra finds them and gnome-control-center can still name the
    # current alert ("Swing") — hence they are not plain home.file
    # entries (a store symlink would hide the sample's name). index.theme
    # is a real file for the same reason: the control center rewrites it
    # when the alert sound changes.
    home.activation.gnomeAlertSound = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      theme_dir="$HOME/.local/share/sounds/__custom"
      alert="/usr/share/sounds/gnome/default/alerts/swing.ogg"

      mkdir -p "$theme_dir"
      # A plain file, writable by the user: gnome-control-center rewrites
      # index.theme when the alert sound changes. The store dedupes identical
      # files, so the old copy is removed first — copying onto a leftover
      # symlink into the store would fail with "same file".
      rm -f "$theme_dir/index.theme"
      install -m 644 ${../files/sounds/__custom/index.theme} \
        "$theme_dir/index.theme"

      if [ -f "$alert" ]; then
        ln -sfn "$alert" "$theme_dir/bell-terminal.ogg"
        ln -sfn "$alert" "$theme_dir/bell-window-system.ogg"
      else
        echo "WARN: alert sound '$alert' not found; keeping the current one." >&2
      fi
    '';

    # Default applications: the web browser is Zen, everything else keeps
    # the image's defaults (Papers for PDFs, Loupe for images, ...).
    #
    # Not xdg.mimeApps: that links ~/.config/mimeapps.list into the
    # read-only store, and GNOME's Default Applications panel then cannot
    # write to it (see modules/mime-apps.nix). The file is seeded once
    # instead, and is GNOME's to change afterwards.
    home.modules.mimeApps = lib.mkMerge [
      {
        enable = true;

        defaultApplications = {
          "x-scheme-handler/http" = "zen-browser.desktop";
          "x-scheme-handler/https" = "zen-browser.desktop";
          "x-scheme-handler/chrome" = "zen-browser.desktop";
          "text/html" = "zen-browser.desktop";
          "application/x-extension-htm" = "zen-browser.desktop";
          "application/x-extension-html" = "zen-browser.desktop";
          "application/x-extension-shtml" = "zen-browser.desktop";
          "application/xhtml+xml" = "zen-browser.desktop";
          "application/x-extension-xhtml" = "zen-browser.desktop";
          "application/x-extension-xht" = "zen-browser.desktop";
        };

        addedAssociations = {
          "x-scheme-handler/http" = [ "zen-browser.desktop" ];
          "x-scheme-handler/https" = [ "zen-browser.desktop" ];
          "x-scheme-handler/chrome" = [ "zen-browser.desktop" ];
          "text/html" = [ "zen-browser.desktop" ];
          "application/x-extension-htm" = [ "zen-browser.desktop" ];
          "application/x-extension-html" = [ "zen-browser.desktop" ];
          "application/x-extension-shtml" = [ "zen-browser.desktop" ];
          "application/xhtml+xml" = [ "zen-browser.desktop" ];
          "application/x-extension-xhtml" = [ "zen-browser.desktop" ];
          "application/x-extension-xht" = [ "zen-browser.desktop" ];
        };
      }
    ];
  };
}
