{ config, ... }:

# Claims ~/.config/nvim — the path plain `nvim`/$EDITOR/$VISUAL
# (modules/misc-config.nix) resolve to — for whichever variant
# `home.modules.nvimVariant` (modules/flavors.nix) currently selects.
#
# Both modules/nvim.nix (LazyVim) and modules/nvim-minimax.nix (MiniMax)
# always build their own config and always deploy it to their own fixed
# path too (~/.config/nvim-lazyvim, ~/.config/nvim-minimax — each also
# reachable via a matching `nvim-lazyvim`/`nvim-minimax` shell alias/def),
# so switching this flag never breaks the non-selected variant's own
# tooling/lockfile — this module only decides which one additionally lands
# at the bare ~/.config/nvim path. Split into its own module (rather than
# folding into flavors.nix, which only declares options) so the two "real"
# nvim modules stay simple and symmetric.
{
  home.file.".config/nvim" = {
    source = config.home.modules.nvimPackages.${config.home.modules.nvimVariant};
    recursive = true;
  };
}
