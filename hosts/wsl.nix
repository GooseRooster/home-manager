{ ... }:

# Headless WSL dev-host: no GUI dotfiles, but keeps the ssh-agent user service
# and the podman/docker alias. Targets both NixOS-WSL and foreign WSL distros
# (Ubuntu, Debian, ...).
#
# The uid-1000 user's name varies by distro (nixos / ubuntu / debian / whatever
# the user picked at install), so username/homeDirectory are read from the
# environment instead of hardcoded. Apply this target with `--impure`:
#   home-manager switch --flake .#wsl --impure
#
# For NixOS-WSL specifically, prefer wiring this repo through nixos-config's
# `home-manager.users.<name>.imports = [ inputs.dotfiles.hmModules.default ]`
# (see README) — that path lets NixOS infer the username natively and doesn't
# use this file at all.
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # Base bundle is default-on; add the WSL extras (devcontainer, claude-code,
  # opencode, openfortivpn, ...).
  home.bundles.wsl.enable = true;

  home.modules.wsl.enable = true;
  home.modules.podmanAlias.enable = true;

  # zsh as the default shell: drives the bash hand-off above (and, on
  # NixOS-integrated hosts, ghostty's command + termapp). Flip to "nu" to
  # revert the experiment everywhere at once.
  home.modules.defaultShell = "zsh";
}
