{
  config,
  lib,
  pkgs,
  ...
}:

# herdr: Rust terminal multiplexer with AI-agent detection (herdr.dev), wired
# through home-manager's native `programs.herdr` module (in the pinned HM rev).
# As before, the store symlink is read-only: herdr's runtime-persisted toggles
# (e.g. agent_panel_scope) won't survive a rebuild — set them here instead.
#
# herdr-nvim (github:ChmaraX/herdr-nvim): herdr has no native declarative
# plugin option — `programs.herdr.settings` only writes config.toml, and
# plugin install/link is a separate imperative subsystem with its own state
# (~/.config/herdr/.plugins.lock). We approximate declarative management the
# same way modules/yazi.nix pins plugins: fetch a pinned rev + the matching
# prebuilt release binary (mirrors what herdr-nvim's own
# herdr/install.sh would fetch, but reproducibly and offline), assemble the
# plugin directory in the store, and `herdr plugin link` it from a
# home.activation hook on every switch. The link is best-effort (`|| true`):
# re-link idempotency isn't documented upstream, and a switch shouldn't fail
# because of it.
let
  cfg = config.home.modules;
  bundles = config.home.bundles;

  herdrEnable = bundles.baseExtra.enable || bundles.wsl.enable;

  herdrNvimSrc = pkgs.fetchFromGitHub {
    owner = "ChmaraX";
    repo = "herdr-nvim";
    rev = "e652ebf7b3d6713992e68a30aec588822e69fae5"; # v1.0.0
    hash = "sha256-NAwzjZ4Ms7gDcFooCPLMZW0vrlq/Fq+XvVxUUamA4RI=";
  };

  herdrNvimBin = pkgs.fetchurl {
    url = "https://github.com/ChmaraX/herdr-nvim/releases/download/v1.0.0/herdr-nvim-x86_64-unknown-linux-gnu";
    hash = "sha256-RU5/+NBQCFgM4X8UInkIUX04ZKaiJTrdBl3LBLyDWZA=";
  };

  herdrNvimPlugin = pkgs.runCommand "herdr-nvim-plugin" { } ''
    cp -r ${herdrNvimSrc} $out
    chmod -R u+w $out
    mkdir -p $out/bin
    cp ${herdrNvimBin} $out/bin/herdr-nvim
    chmod +x $out/bin/herdr-nvim
  '';

  herdrNvimPluginDir = "${config.home.homeDirectory}/.local/share/herdr/plugins/herdr-nvim";
in
{
  programs.herdr = {
    enable = herdrEnable;

    settings = {
      onboarding = false;

      theme.name = "terminal";

      terminal.default_shell = cfg.defaultShell;

      keys = {
        # Optional workspace/agent bindings (unset upstream by default).
        previous_workspace = "prefix+shift+k";
        next_workspace = "prefix+shift+j";
        previous_agent = "prefix+alt+k";
        next_agent = "prefix+alt+j";
        switch_workspace = "prefix+shift+1..9";

        # Blanked: arrow keys always focus panes directionally.
        navigate_pane_left = "";
        navigate_pane_down = "";
        navigate_pane_up = "";
        navigate_pane_right = "";

        # Blanked: reassigned to herdr-nvim plugin actions below.
        edit_scrollback = "";
        open_notification_target = "";

        command = [
          {
            key = "prefix+e";
            type = "plugin_action";
            command = "chmarax.herdr-nvim.toggle";
            description = "nvim sidebar: toggle";
          }
          {
            key = "prefix+o";
            type = "plugin_action";
            command = "chmarax.herdr-nvim.pick-file";
            description = "nvim sidebar: open file from agent output";
          }
        ];
      };


      experimental = {
        kitty_graphics = true;
        pane_history = false;
      };
    };
  };

  home.file.".local/share/herdr/plugins/herdr-nvim" = lib.mkIf herdrEnable {
    source = herdrNvimPlugin;
    recursive = true;
  };

  home.activation.linkHerdrNvimPlugin = lib.mkIf herdrEnable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run "${config.programs.herdr.package}/bin/herdr" plugin link "${herdrNvimPluginDir}" || true
    ''
  );
}
