{ ... }:

# NixOS desktop (nixos-config host "home"): full shell + editor + theming + gaming.
{
  home.username = "gooze";
  home.homeDirectory = "/home/gooze";

  home.modules.gaming.enable = true;
  home.modules.theming.enable = true;
  # podmanAlias stays off: the desktop gets its SSH agent from gnome-keyring and
  # uses podman natively (docker-compat socket handled by nixos-config's podman module).
}
