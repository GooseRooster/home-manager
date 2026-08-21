{ ... }:

# Dev container: lean shell + editor + yazi. Skips GUI/desktop dotfiles and
# devcontainer-init (nothing to scaffold *to* from inside a container).
# NOTE: adjust username/homeDirectory to match the container's uid-1000 user
# (e.g. vscode -> /home/vscode) if the template differs.
{
  home.username = "gooze";
  home.homeDirectory = "/home/gooze";

  home.modules.devcontainer.enable = true;
  home.modules.podmanAlias.enable = true;
}
