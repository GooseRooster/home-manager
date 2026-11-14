{
  config,
  lib,
  pkgs,
  ...
}:

# tinty — the tinted-theming scheme manager, shared by every target that sets
# home.modules.tinty.enable (wsl, silver-hour). This module owns the generic
# half: the package, config.toml, the first `tinty sync`, the custom schemes
# and the terminal-side items every tinty host wants. Host-specific items are
# appended through `home.modules.tinty.items` by their own modules:
#   modules/theming-tools-silver-hour.nix  Ghostty, tinted-shell, Zen, Discord, Steam
#   modules/windows-terminal.nix           Windows Terminal (WSL)
#
# yazi and lazygit deliberately stay on their ANSI themes in chromaleon mode:
# their templates are base16-only, while the silver-hour ChromaLeon bridge
# applies tinted8 schemes. In gnomad mode the scheme is a base16 one and the
# templates apply themselves (see files/scripts/theming).
let
  cfg = config.home.modules;

  # The custom base16 schemes (shared with gnomad, which reads the same files
  # from ~/.config/gnomad/schemes on silver-hour).
  schemesDir = ../files/gnomad/schemes;
  schemes = lib.filterAttrs (_: type: type == "regular") (builtins.readDir schemesDir);

  # Items every tinty host gets.
  sharedItems = [
    {
      # Claude Code
      name = "tinted-claude-code";
      path = "https://github.com/tinted-theming/tinted-claude-code";
      themes-dir = "scripts";
      theme-file-extension = ".js";
      supported-systems = [ "base16" "base24" "tinted8" ];
      hook = "mkdir -p \"$HOME/.claude/themes\" && node \"$TINTY_THEME_FILE_PATH\" > \"$HOME/.claude/themes/tinty.json\"";
    }
    {
      # Neovim: no hook. The item exists so tinty clones the plugin and builds
      # custom schemes (ChromaLeon, the files/gnomad ones) into the clone;
      # files/nvim/plugin/50-custom/theme.lua loads tinted-nvim from there and
      # follows current_scheme itself.
      name = "tinted-nvim";
      path = "https://github.com/tinted-theming/tinted-nvim";
      themes-dir = "colors";
      supported-systems = [ "base16" "base24" "tinted8" ];
    }
    {
      # fzf: no hook. zsh sources the artifact tinty copies into its data dir
      # (see the initContent block below).
      name = "tinted-fzf";
      path = "https://github.com/tinted-theming/tinted-fzf";
      themes-dir = "sh";
      supported-systems = [ "base16" "base24" "tinted8" ];
    }
    {
      # yazi — the template generates a *flavor*, so it lands in
      # ~/.config/yazi/flavors/<name>.yazi/flavor.toml. Which flavor
      # theme.toml selects follows the scheme system (see the hook below).
      path = "https://github.com/tinted-theming/tinted-yazi";
      name = "tinted-yazi";
      themes-dir = "flavors";
      supported-systems = [ "base16" ];
      hook = ''
        mkdir -p "$HOME/.config/yazi/flavors/tinted.yazi"
        cp -f "$TINTY_THEME_FILE_PATH" "$HOME/.config/yazi/flavors/tinted.yazi/flavor.toml"
      '';
    }
    {
      # lazygit — the template is a config fragment (gui: theme: …) rather
      # than a theme file, so it is merged into lazygit's own config through
      # LG_CONFIG_FILE (see files/zsh/functions.zsh).
      path = "https://github.com/tinted-theming/tinted-lazygit";
      name = "tinted-lazygit";
      themes-dir = "themes";
      supported-systems = [ "base16" ];
    }
  ];

  # yazi's theme.toml follows the *scheme system*, not the theming mode: the
  # base16 template when the scheme is a base16 one, the terminal's ANSI
  # palette otherwise — the ChromaLeon bridge applies a tinted8 scheme, which
  # the base16-only templates cannot express. tinty's global hooks run on
  # every apply and get the scheme in the environment, which is exactly the
  # signal needed.
  yaziThemeHook = pkgs.writeShellApplication {
    name = "yazi-theme";
    runtimeInputs = [ pkgs.coreutils ];
    runtimeEnv = {
      YAZI_THEME_ANSI = "${../files/yazi/theme.toml}";
      YAZI_THEME_TINTED = "${../files/yazi/theme-tinted.toml}";
    };
    text = ''
      theme_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
      src="$YAZI_THEME_ANSI"
      if [ "''${TINTY_SCHEME_SYSTEM:-}" = "base16" ] &&
        [ -f "$theme_dir/flavors/tinted.yazi/flavor.toml" ]; then
        src="$YAZI_THEME_TINTED"
      fi
      mkdir -p "$theme_dir"
      # A store symlink (an older configuration) would send the copy into a
      # read-only store path — replace it with a real file.
      if [ -L "$theme_dir/theme.toml" ]; then
        rm -f "$theme_dir/theme.toml"
      fi
      cp -f "$src" "$theme_dir/theme.toml"
      chmod u+w "$theme_dir/theme.toml"
    '';
  };
in
{
  options.home.modules.tinty.items = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [ ];
    description = ''
      tinty `[[items]]` entries, written to config.toml. Modules append their
      own; definitions are concatenated.
    '';
  };

  config = lib.mkIf cfg.tinty.enable {
    home.modules.tinty.items = lib.mkBefore sharedItems;

    home.packages = [ pkgs.tinty ];

    home.file = {
      ".config/tinted-theming/tinty/config.toml" = {
        force = true;
        source = (pkgs.formats.toml { }).generate "tinty-config" {
          items = cfg.tinty.items;
          # Global hooks run after the item hooks on every apply.
          hooks = [ "${yaziThemeHook}/bin/yazi-theme" ];
        };
      };
    };

    # The custom schemes (files/gnomad/schemes) are *copied* into tinty's
    # custom-schemes directory, not symlinked into it: gnomad rewrites that
    # file when it applies a custom scheme — it syncs the scheme into tinty
    # right before the apply — and writing through a symlink into the
    # read-only nix store fails with EACCES. A copy keeps `tinty apply
    # base16-<slug>` working by hand *and* lets gnomad apply the custom
    # schemes (from its TUI or through the theming toggle).
    home.activation.tintyCustomSchemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      custom_dir="$HOME/.local/share/tinted-theming/tinty/custom-schemes/base16"
      mkdir -p "$custom_dir"
      for src in ${lib.escapeShellArgs (map (name: "${schemesDir}/${name}") (lib.attrNames schemes))}; do
        name="$(basename "$src")"
        cp -f "$src" "$custom_dir/$name"
        chmod u+w "$custom_dir/$name"
      done
    '';

    # Run `tinty sync` so `tinty apply` works immediately. Idempotent: sync
    # only runs while an item's clone is missing (first switch, or an item
    # added since), so a switch stays offline-safe otherwise. Runs after
    # writeBoundary so the config above exists. Each item's hook creates its
    # own output directory.
    home.activation.tintySetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # yazi's theme.toml belongs to the hook above (it follows the scheme
      # system). Materialize the default once, so yazi is not unthemed
      # before the first tinty apply.
      if [ ! -e "$HOME/.config/yazi/theme.toml" ]; then
        cp "${../files/yazi/theme.toml}" "$HOME/.config/yazi/theme.toml"
        chmod u+w "$HOME/.config/yazi/theme.toml"
      fi

      # Not "run": every activation step shares one script, and a function
      # named run would replace Home Manager's run helper for every later step.
      tintySetupStep() {
        local repos="$HOME/.local/share/tinted-theming/tinty/repos" item
        for item in ${lib.escapeShellArgs (map (i: i.name) cfg.tinty.items)}; do
          if [ ! -d "$repos/$item" ]; then
            PATH="${pkgs.git}/bin:$PATH" ${pkgs.tinty}/bin/tinty sync \
              || echo "WARN: 'tinty sync' failed (offline?), skipping." >&2
            return
          fi
        done
      }
      tintySetupStep
    '';

    # tinted-fzf appends `--color` options to FZF_DEFAULT_OPTS. Start from the
    # pre-theme value each time, so nested shells don't stack them. tinty
    # copies the current item files to artifacts/<name>-<themes-dir>-file.*.
    programs.zsh.initContent = lib.mkOrder 1215 ''
      if [[ -r "$HOME/.local/share/tinted-theming/tinty/artifacts/tinted-fzf-sh-file.sh" ]]; then
        export _TINTED_FZF_BASE_OPTS="''${_TINTED_FZF_BASE_OPTS-$FZF_DEFAULT_OPTS}"
        FZF_DEFAULT_OPTS="$_TINTED_FZF_BASE_OPTS"
        source "$HOME/.local/share/tinted-theming/tinty/artifacts/tinted-fzf-sh-file.sh"
      fi
    '';
  };
}
