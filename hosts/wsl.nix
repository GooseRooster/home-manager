{ ... }:

# NixOS-WSL (nixos-config "wsl" flavor): headless dev-host. No GUI dotfiles,
# but keeps the ssh-agent service and the podman/docker alias for devcontainers.
{
  home.username = "goose";
  home.homeDirectory = "/home/goose";

  home.modules.wsl.enable = true;
  home.modules.podmanAlias.enable = true;
}
