{ ... }:

# Lean dev-container target: base CLI batteries + the dotfiles, nothing else
# (no GUI dotfiles, no WSL extras, no podman alias).
#
# The user's name varies by image, so username/homeDirectory are read from the
# environment instead of hardcoded. Apply with `--impure`:
#   home-manager switch --flake .#container --impure
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # home.bundles.base is default-on — nothing to enable here. Add per-image
  # feature flags (home.modules.*) below if a container needs them.

  # zsh as the default interactive shell (same flag as hosts/wsl.nix; on
  # NixOS-integrated hosts it also drives ghostty's command + termapp).
  home.modules.defaultShell = "zsh";
}
