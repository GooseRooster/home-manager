{ lib, ... }:

# Tool configs via native HM modules. HM installs the binaries too (same
# nixpkgs instance as the home.bundles lists, so overlapping entries dedupe
# to identical store paths).
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      theme_background = true;
      truecolor = true;
      force_tty = false;
      disable_presets = "Off";
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      vim_keys = true;
      disable_mouse = false;
      rounded_corners = true;
      terminal_sync = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_gpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;
      proc_follow_detailed = true;
      proc_aggregate = false;
      keep_dead_proc_usage = false;
      cpu_graph_upper = "Auto";
      cpu_graph_lower = "Auto";
      show_gpu_info = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      cpu_core_map = "";
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      freq_mode = "first";
      clock_format = "%X";
      background_update = true;
      custom_cpu_name = "";
      disks_filter = "";
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      io_graph_speeds = "";
      swap_upload_download = false;
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      net_iface = "";
      base_10_bitrate = "Auto";
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;
      log_level = "WARNING";
      save_config_on_exit = true;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
      shown_gpus = "nvidia amd intel apple";
      custom_gpu_name0 = "";
      custom_gpu_name1 = "";
      custom_gpu_name2 = "";
      custom_gpu_name3 = "";
      custom_gpu_name4 = "";
      custom_gpu_name5 = "";
    };
  };

  programs.lazygit = {
    enable = true;
    # TTY-friendly theme. All values are SGR names; the host terminal's
    # palette drives the actual color, so this works across containers,
    # SSH, tmux, any $TERM.
    # Only one key differs from lazygit's upstream default: selectedLineBgColor
    # is [default] instead of [blue]. gocui's setCharacter force-boldens and
    # bumps the cell color to the bright variant on selection regardless of
    # theme (pkg/gocui/view.go), so a colored diff hunk on a blue band is hard
    # to read on most terminal schemes. Dropping the band lets the bright cell
    # fg sit on the terminal's natural bg, which is universally readable.
    # SGR 2 (dim/faint) is not exposed by the theme parser; true dimming would
    # require a source patch.
    settings = {
      gui.theme = {
        activeBorderColor = [ "green" "bold" ]; # SGR 1;32
        inactiveBorderColor = [ "default" ]; # SGR 39
        searchingActiveBorderColor = [ "cyan" "bold" ]; # SGR 1;36
        optionsTextColor = [ "blue" ]; # SGR 34
        selectedLineBgColor = [ "default" ]; # SGR 49 (was [blue])
        inactiveViewSelectedLineBgColor = [ "bold" ]; # SGR 1
        cherryPickedCommitFgColor = [ "blue" ]; # SGR 34
        cherryPickedCommitBgColor = [ "cyan" ]; # SGR 46
        markedBaseCommitFgColor = [ "blue" ]; # SGR 34
        markedBaseCommitBgColor = [ "yellow" ]; # SGR 43
        unstagedChangesColor = [ "red" ]; # SGR 31
        defaultFgColor = [ "default" ]; # SGR 39
      };

      git.diffRenderers = [
        {
          colorArg = "always";
          command = "delta --dark --paging=never";
        }
      ];

      os = {
        editPreset = "nvim-remote";
        edit = "[ -z \"\$NVIM\" ] && (nvim -- {{filename}}) || (nvim --server \"\$NVIM\" --remote-send \"q\" && nvim --server \"\$NVIM\" --remote-tab {{filename}})";
        editAtLine = "[ -z \"\$NVIM\" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server \"\$NVIM\" --remote-send \"q\" && nvim --server \"\$NVIM\" --remote-tab {{filename}} && nvim --server \"\$NVIM\" --remote-send \":{{line}}<CR>\")";
      };
    };
  };

  programs.lazydocker = {
    enable = true;
    # TTY-friendly theme: colors are SGR names (see the lazygit note above).
    # selectedLineBgColor [default] — no background band; the cell's own color
    # (force-bold+bright by gocui) sits on the terminal's natural bg. The
    # `reverse` attribute was rejected: gocui applies the swap per-cell, so
    # multi-colored rows shimmer.
    # activeBorderColor [green, bold] is kept at default: lazydocker wires it
    # to SelFgColor (pkg/gui/theme.go SetColorScheme), so it also drives the
    # selected-row fg and cannot be decoupled through the theme YAML.
    settings.gui.theme = {
      activeBorderColor = [ "green" "bold" ]; # SGR 1;32 (also SelFgColor)
      inactiveBorderColor = [ "default" ]; # SGR 39
      selectedLineBgColor = [ "default" ]; # SGR 49 (was [blue])
      optionsTextColor = [ "blue" ]; # SGR 34
    };
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      display.separator = "  ";
      modules =
[
      {
        type = "title";
        key = "ホスト";
        keyColor = "blue";
      }
      "break"
      {
        type = "os";
        key = "__OS_KEY__";
        keyColor = "green";
      }
      {
        type = "kernel";
        key = "├─";
        format = "{1} {2}";
        keyColor = "green";
      }
      {
        type = "wm";
        key = "╰─󱂬";
        keyColor = "green";
      }
      "break"
      {
        type = "terminal";
        key = "╭─";
        keyColor = "green";
      }
      {
        type = "shell";
        key = "╰─";
        keyColor = "green";
      }
      "break"
      {
        type = "cpu";
        key = "╭─󰍛";
        keyColor = "green";
      }
      {
        type = "gpu";
        key = "├─󰘚";
        keyColor = "green";
      }
      {
        type = "display";
        key = "├─󰍹";
        keyColor = "green";
        format = "{width}x{height} @ {refresh-rate}Hz";
      }
      {
        type = "memory";
        key = "├─󰑭";
        keyColor = "green";
      }
      {
        type = "uptime";
        key = "╰─󰅐";
        keyColor = "green";
      }
    ];
    };
  };
}
