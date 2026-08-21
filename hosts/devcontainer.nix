{ ... }:

# Dev container: lean shell + editor + yazi. Skips GUI/desktop dotfiles and
# devcontainer-init (nothing to scaffold *to* from inside a container).
#
# The uid-1000 user's name varies by base image (vscode / ubuntu / ...), so the
# username/homeDirectory are read from the environment instead of hardcoded.
# Apply this target with `--impure`:
#   home-manager switch --flake .#devcontainer --impure
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.modules.devcontainer.enable = true;
  home.modules.podmanAlias.enable = true;
}
