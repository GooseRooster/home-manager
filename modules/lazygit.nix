{ config, lib, pkgs, ... }:

# lazygit — the terminal git UI.
#
# The package is a *wrapper*: the base16 template (tinted-lazygit) generates a
# config fragment rather than a theme file, so it has to be merged into
# lazygit's own config through LG_CONFIG_FILE. The fragment only exists when
# the base16 template was applied — tinty rebuilds the artifacts on every
# apply, and a tinted8 scheme (the silver-hour ChromaLeon bridge) skips the
# base16-only items — so its presence is the signal that the template is in
# play. No theming mode involved: the WSL host, whose schemes are base16,
# gets the template as well.
#
# The wrapper is a binary rather than a shell function on purpose: Home
# Manager's own shell integration defines `lg` (a function that calls
# `command lazygit`), and a shell function could not intercept that. At the
# binary level every path is covered — `lg`, `lazygit` typed by hand, the
# bash/fish/nushell integrations, and lazygit started from a script.
let
  # The fragment tinted-lazygit produces, and the config it is merged into.
  fragmentPath = "\${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/artifacts/tinted-lazygit-themes-file.yml";
  configPath = "\${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml";

  lazygitWrapper = pkgs.writeShellApplication {
    name = "lazygit";
    runtimeInputs = [ pkgs.lazygit ];
    text = ''
      fragment="${fragmentPath}"
      config="${configPath}"
      if [ -f "$fragment" ] && [ -f "$config" ]; then
        export LG_CONFIG_FILE="$config,$fragment"
      fi
      exec lazygit "$@"
    '';
  };
in
{
  programs.lazygit = {
    enable = true;

    # The wrapper above is the package (it has to be, or the profile would
    # ship two `lazygit` binaries).
    package = null;

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

    };
  };

  home.packages = [ lazygitWrapper ];
}
