{ config, lib, ... }:

let
  cfg = config.home.modules;
in
{
  options.home.modules.sway = {
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra Sway configuration appended verbatim (host-specific output /
        input blocks). Only rendered in the noctalia session.
      '';
    };
  };

  # Sway config for the noctalia session. Replaces the Umbriel scrolling
  # layout with standard dynamic tiling; keybinds are ported from the old
  # Umbriel settings (see hosts/home in nixos-config) and adapted. Noctalia
  # owns theming: its builtin `sway` template renders ~/.config/sway/noctalia
  # (window colours + $variables) and its apply.sh appends an include to this
  # file — the include is pre-seeded below so that append becomes a no-op on
  # the read-only HM symlink.
  config = lib.mkIf (cfg.session == "noctalia") {
    xdg.configFile."sway/config".text = ''
      ### Variables
      set $mod Mod4
      set $term termapp
      set $ipc noctalia msg

      ### NixOS session integration (imports WAYLAND_DISPLAY/SWAYSOCK into
      ### D-Bus + systemd; see programs.sway in nixos-config).
      include /etc/sway/config.d/*

      ### Autostart
      # Noctalia v5 shell (owns bar/launcher/notifications/lockscreen/idle).
      exec noctalia
      # Dynamic tiling in a master-stack-ish shape (-l 2 caps autotiling's
      # split depth; upstream's recommended value for master-stack).
      exec_always autotiling -l 2
      # Removable-media automount (Sway has none built in; udisks2 is enabled
      # by the NixOS sway module). A tray icon lets you eject.
      exec udiskie --automount --notify
      # Scratch terminal: a centred 50%x50% floating ghostty, toggled with
      # Mod+;. Launched eagerly and parked in the scratchpad by the for_window
      # rule below. --class gives it a stable app_id; --gtk-single-instance
      # =false keeps it from merging into the regular ghostty instance.
      exec ghostty --class=scratch-term --gtk-single-instance=false

      ### Input
      focus_follows_mouse yes

      # Touchpad with GNOME-like defaults: tap to click (1 finger left,
      # 2 fingers right, 3 fingers middle via the lrm button map), natural
      # (reverse) scrolling, and disable-while-typing.
      input "type:touchpad" {
        tap enabled
        tap_button_map lrm
        natural_scroll enabled
        dwt enabled
      }

      ### Output (host-specific; laptop leaves this empty for auto-detect)
      ${cfg.sway.extraConfig}
      ### Appearance
      # 2px borders; the colours (bright $primary on the focused window,
      # dim $outline elsewhere) are rendered by Noctalia's builtin sway
      # template via the include at the bottom. Sway's default gaps are 0, so
      # set our own.
      default_border pixel 2
      default_floating_border pixel 2
      gaps inner 5
      gaps outer 5
      font pango:Iosevka Nerd Font Mono 11

      # Scratch terminal: float it, size to 50% of the output, centre it, and
      # park it in the scratchpad (toggled by Mod+; below).
      for_window [app_id="scratch-term"] floating enable, resize set 50 ppt 50 ppt, move position center, move scratchpad

      ### Keybindings
      # Basics
      bindsym $mod+Return exec $term
      bindsym $mod+q kill
      bindsym $mod+e exec $term yazi
      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit' swaymsg exit
      # Toggle the scratch terminal (show/hide the parked ghostty).
      bindsym $mod+semicolon scratchpad show

      # Noctalia IPC (docs.noctalia.dev)
      bindsym $mod+space exec $ipc panel-toggle launcher
      bindsym $mod+s exec $ipc panel-toggle control-center
      bindsym $mod+comma exec $ipc settings-toggle
      bindsym $mod+Shift+i exec $ipc settings-toggle
      bindsym Print exec $ipc screenshot-region
      bindsym $mod+Print exec $ipc screenshot-fullscreen
      bindsym $mod+v exec $ipc panel-toggle clipboard
      bindsym $mod+w exec $ipc panel-toggle wallpaper
      bindsym $mod+x exec $ipc bar-toggle
      bindsym $mod+Escape exec $ipc panel-toggle session
      bindsym Ctrl+Alt+l exec $ipc session lock
      bindsym $mod+Tab exec $ipc window-switcher

      # Focus (vim directions)
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right

      # Move the focused window
      bindsym $mod+Ctrl+h move left
      bindsym $mod+Ctrl+j move down
      bindsym $mod+Ctrl+k move up
      bindsym $mod+Ctrl+l move right

      # Column width  -> standard resize
      bindsym $mod+equal resize grow width 5%
      bindsym $mod+plus resize grow width 5%
      bindsym $mod+minus resize shrink width 5%

      # Layout / window state
      bindsym $mod+f fullscreen toggle
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+b splith
      bindsym $mod+Shift+b splitv
      bindsym $mod+a focus parent

      # Workspaces (standard tiling: numeric, 1-10)
      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9
      bindsym $mod+0 workspace number 10

      bindsym $mod+Shift+1 move container to workspace number 1
      bindsym $mod+Shift+2 move container to workspace number 2
      bindsym $mod+Shift+3 move container to workspace number 3
      bindsym $mod+Shift+4 move container to workspace number 4
      bindsym $mod+Shift+5 move container to workspace number 5
      bindsym $mod+Shift+6 move container to workspace number 6
      bindsym $mod+Shift+7 move container to workspace number 7
      bindsym $mod+Shift+8 move container to workspace number 8
      bindsym $mod+Shift+9 move container to workspace number 9
      bindsym $mod+Shift+0 move container to workspace number 10

      # Prev/next workspace (Umbriel Mod+Alt+K/J) and move across workspaces
      bindsym $mod+Alt+k workspace prev_on_output
      bindsym $mod+Alt+j workspace next_on_output
      bindsym $mod+Shift+h move container to workspace prev_on_output
      bindsym $mod+Shift+l move container to workspace next_on_output

      # 3-finger swipe up/down -> next/prev workspace (GNOME-ish).
      bindgesture swipe:3:down workspace next_on_output
      bindgesture swipe:3:up workspace prev_on_output

      # Resize mode
      mode "resize" {
        bindsym h resize shrink width 5%
        bindsym j resize grow height 5%
        bindsym k resize shrink height 5%
        bindsym l resize grow width 5%
        bindsym Return mode "default"
        bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"

      # Media keys (Noctalia IPC; work when locked where relevant)
      bindsym --locked XF86AudioRaiseVolume exec $ipc volume-up
      bindsym --locked XF86AudioLowerVolume exec $ipc volume-down
      bindsym --locked XF86AudioMute exec $ipc volume-mute
      bindsym --locked XF86MonBrightnessUp exec $ipc brightness-up
      bindsym --locked XF86MonBrightnessDown exec $ipc brightness-down
      bindsym $mod+Down exec playerctl play-pause
      bindsym $mod+XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      ### Noctalia palette (rendered by the builtin sway template). The
      ### include is pre-seeded so the template's apply.sh no-ops; the file
      ### itself is written (and stays writable) by Noctalia.
      include ~/.config/sway/noctalia
    '';
  };
}
