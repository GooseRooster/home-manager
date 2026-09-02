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
let
  cfg = config.home.modules;
  bundles = config.home.bundles;
in
{
  programs.herdr = {
    enable = bundles.baseExtra.enable || bundles.wsl.enable;

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
      };


      experimental = {
        kitty_graphics = true;
        pane_history = false;
      };
    };
  };
}
