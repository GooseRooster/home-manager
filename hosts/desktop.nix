{ ... }:

# NixOS desktop (nixos-config host "home"): full shell + editor + theming + gaming.
{
  home.username = "goose";
  home.homeDirectory = "/home/goose";

  home.modules.gaming.enable = true;
  home.modules.theming.enable = true;
  # Rootless podman socket + docker->podman alias (lazydocker/lazypodman). SSH
  # agent still comes from gnome-keyring; podman socket is user-scoped.
  home.modules.podmanAlias.enable = true;
}
