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
# yazi and lazygit deliberately stay on their ANSI themes: their templates are
# base16-only, while the silver-hour ChromaLeon bridge applies tinted8 schemes.
# Both already follow the terminal palette, which tinty retints anyway.
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
  ];
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

    home.file =
      lib.mapAttrs' (name: _: {
        name = ".local/share/tinted-theming/tinty/custom-schemes/base16/${name}";
        value = {
          force = true;
          source = schemesDir + "/${name}";
        };
      }) schemes
      // {
        ".config/tinted-theming/tinty/config.toml" = {
          force = true;
          source = (pkgs.formats.toml { }).generate "tinty-config" { items = cfg.tinty.items; };
        };
      };

    # Run `tinty sync` so `tinty apply` works immediately. Idempotent: sync
    # only runs while an item's clone is missing (first switch, or an item
    # added since), so a switch stays offline-safe otherwise. Runs after
    # writeBoundary so the config above exists. Each item's hook creates its
    # own output directory.
    home.activation.tintySetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
