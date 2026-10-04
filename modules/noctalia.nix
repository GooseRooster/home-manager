{
  config,
  lib,
  ...
}:

# Declarative Noctalia shell settings — the curated, opinionated bits of the
# shell that belong to the user (top bar, widgets, shell behaviour, idle,
# session actions, night light, templates). Written to
# ~/.config/noctalia/config.toml.
#
# Layering (see docs.noctalia.dev/noctalia/configuration/):
#   1. built-in defaults
#   2. ~/.config/noctalia/*.toml   <- this module (read-only HM symlink)
#   3. ~/.local/state/noctalia/settings.toml  <- app-managed, WINS
#
# Because layer 3 wins, we deliberately do NOT declare [theme] here: the
# palette choice (custom_palette/source/mode) is a live GUI preference that
# Noctalia persists to settings.toml. Nor do we declare [wallpaper] paths or
# the lockscreen widget layout — both are per-host / per-monitor runtime state
# the GUI owns. Anything the GUI has already written to settings.toml still
# shadows the values below until it is cleared (one-time cleanup).
#
# Host-specific display bits (e.g. the bar list) can be extended through
# home.modules.noctalia.extraSettings; GPU monitoring is intentionally NOT
# modelled — add a GPU sysmon widget in the Settings UI on hosts that want it
# (that override lands in settings.toml and wins, which is what we want).
let
  cfg = config.home.modules.noctalia;

  # Curated declarative config, mirroring the values captured from the live
  # settings.toml minus theme/wallpaper/lockscreen-layout.
  baseSettings = {
    accessibility.ui_scale = 1.1;

    # Top bar: one full-width bar with capsule widgets. The sysmon widgets
    # (cpu_usage/cpu_temp/ram_usage/disk_usage) are CPU/RAM/disk only — no GPU.
    bar.default = {
      background_opacity = 0.82;
      capsule = true;
      capsule_border = "outline";
      capsule_radius = 0;
      contact_shadow = true;
      margin_ends = 0;
      radius = 0;
      scale = 1.1;
      start = [
        "wallpaper"
        "workspaces"
        "cpu_usage"
        "cpu_temp"
        "ram_usage"
        "disk_usage"
      ];
      center = [
        "weather"
        "clock"
        "audio_visualizer"
      ];
      end = [
        "tray"
        "notifications"
        "clipboard"
        "group:g1"
        "volume"
        "brightness"
        "battery"
        "control-center"
        "session"
      ];
      capsule_group = [
        {
          id = "g1";
          members = [
            "network"
            "bluetooth"
          ];
          accordion = false;
          accordion_direction = "end";
          border = "outline";
          border_width = 1.0;
          enabled = true;
          fill = "surface_variant";
          opacity = 1.0;
          padding = 6.0;
          radius = 0.0;
        }
      ];
    };

    # Batch palette refresh hook (see modules/theming-tools.nix).
    hooks.colors_changed = "theme_regen";

    # Idle: lock at 10 min, screen off at 11, lock+suspend at 15.
    idle = {
      behavior_order = [
        "lock"
        "screen-off"
        "lock-and-suspend"
      ];
      behavior.lock = {
        action = "lock";
        enabled = true;
        timeout = 600.0;
      };
      behavior."screen-off" = {
        action = "screen_off";
        enabled = true;
        timeout = 660.0;
      };
      behavior."lock-and-suspend" = {
        action = "lock_and_suspend";
        enabled = true;
        timeout = 900.0;
      };
    };

    location.auto_locate = true;

    # Lock screen: no background blur/tint (wallpaper shows through cleanly).
    # Widget layout itself is left to the GUI (per-output placement).
    lockscreen = {
      blur_intensity = 0.0;
      tint_intensity = 0.0;
    };

    nightlight.enabled = true;

    shell = {
      app_icon_colorize = true;
      corner_radius_scale = 1.5;
      font_family = "Iosevka NFM";
      telemetry_enabled = true;

      animation.speed = 2.2;

      launcher = {
        app_grid = true;
        pinned = [
          "zen-twilight"
          "foot"
          "io.github.nokse22.high-tide"
          "io.github.kolunmi.Bazaar"
          "com.rafaelmardojai.Blanket"
          "steam"
          "io.github.Faugus.faugus-launcher"
          "io.mpv.Mpv"
          "nvim"
          "yazi"
          "dev.noctalia.Noctalia"
          "btop"
        ];
      };

      panel = {
        control_center_placement = "floating";
        wallpaper_placement = "floating";
        open_near_click_control_center = true;
        open_near_click_session = true;
        open_near_click_wallpaper = true;
      };

      session.actions = [
        {
          action = "lock";
          enabled = true;
          shortcut = "1";
          countdown_seconds = 0.0;
          variant = "default";
        }
        {
          action = "logout";
          command = "swaymsg exit";
          enabled = true;
          shortcut = "2";
          countdown_seconds = 60.0;
          variant = "default";
        }
        {
          action = "lock_and_suspend";
          enabled = true;
          shortcut = "3";
          countdown_seconds = 0.0;
          variant = "default";
        }
        {
          action = "reboot";
          enabled = true;
          shortcut = "4";
          countdown_seconds = 60.0;
          variant = "default";
        }
        {
          action = "shutdown";
          enabled = true;
          shortcut = "5";
          countdown_seconds = 60.0;
          variant = "destructive";
        }
      ];
    };

    # App theming templates (palette rendering into foot/gtk/sway/ghostty, plus
    # the community zen-browser template). The palette CHOICE is not set here.
    theme.templates = {
      enable_builtin_templates = true;
      builtin_ids = [
        "foot"
        "gtk3"
        "gtk4"
        "ghostty"
        "sway"
      ];
      community_ids = [ "zen-browser fuzzel discord" ];

      # Adwaita-for-Steam: rendered palette -> custom CSS consumed by
      # pkgs/adwaita-for-steam (output_path is deliberately NOT HM-managed —
      # Noctalia must rewrite custom.css at runtime).
      user.adwaita_steam = {
        input_path = "${../files/noctalia/noctalia-steam-adwaita.css}";
        output_path = "$XDG_CONFIG_HOME/AdwSteamGtk/custom.css";
      };
    };

    # Bar widget definitions.
    widget.cpu_usage = {
      type = "sysmon";
    };
    widget.cpu_temp = {
      type = "sysmon";
      stat = "cpu_temp";
    };
    widget.ram_usage = {
      type = "sysmon";
      stat = "ram_pct";
    };
    widget.disk_usage = {
      type = "sysmon";
      stat = "disk_used_pct";
    };
    widget.clock.format = "{:%A %d %B %H:%M}";
    widget.weather.show_condition = false;
    widget.workspaces.occupied_color = "tertiary";
    widget.audio_visualizer = {
      show_when_idle = true;
      actions = {
        left = "panel-open control-center media";
        right = "media toggle";
      };
    };
  };
in
{
  # `home.modules.noctalia.enable` is declared in modules/flavors.nix
  # alongside the other feature flags.
  options.home.modules.noctalia = {
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Extra Noctalia settings merged over the curated defaults (host-specific
        additions, e.g. bar tweaks). Applied with lib.recursiveUpdate, so arrays
        are replaced wholesale — pass the full list when overriding one.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      settings = lib.recursiveUpdate baseSettings cfg.extraSettings;
    };
  };
}
