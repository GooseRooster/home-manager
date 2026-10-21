{ ... }:

# Headless WSL dev-host: no GUI dotfiles, but keeps the keychain-managed
# ssh-agent and the podman/docker alias. Targets both NixOS-WSL and foreign
# WSL distros (Ubuntu, Debian, ...).
#
# The uid-1000 user's name varies by distro (nixos / ubuntu / debian / whatever
# the user picked at install), so username/homeDirectory are read from the
# environment instead of hardcoded. Apply this target with `--impure`:
#   home-manager switch --flake .#wsl --impure
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # Base bundle is default-on; add the WSL extras (devcontainer, claude-code,
  # opencode, openfortivpn, ...).
  home.bundles.wsl.enable = true;

  home.modules.wsl.enable = true;
  home.modules.podmanAlias.enable = true;
}
