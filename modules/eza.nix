{ ... }:

# eza — a modern `ls` replacement. Only wired into zsh (see modules/zsh.nix);
# nushell has no ls/ll/la aliases today and this doesn't add any, so its
# behavior there is unchanged.
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    colors = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  # `ls` renders a filebrowser-style tree of the current dir (two levels).
  # The alias expands through the module's `eza` options alias, so the
  # icons/colors/git/group-directories-first/--header wiring above rides
  # along. Kept OFF ll/la/lla on purpose: --tree renders poorly combined
  # with -l (tree glyphs inline in the long columns); lt already trees via
  # the module's own alias. Plain value beats the module's mkDefault
  # alias, so this overrides `ls = "eza"` cleanly.
  programs.zsh.shellAliases.ls = "eza --tree --level=1 --all";
}
