{ ... }:

# NixOS-WSL (nixos-config "wsl" flavor): headless dev-host. No GUI dotfiles,
# but keeps the ssh-agent service and the podman/docker alias for devcontainers.
{
  home.username = "gooze";
  home.homeDirectory = "/home/gooze";

  home.modules.wsl.enable = true;
  home.modules.podmanAlias.enable = true;
}
