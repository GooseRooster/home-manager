{ ... }:

{
  programs.lazydocker = {
    enable = true;
    # TTY-friendly theme: colors are SGR names (see the lazygit note in
    # modules/lazygit.nix).
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
}
