{ ... }:

# silver-hour image target (standalone Home Manager on the atomic Fedora
# GNOME image). The user's name is created by the installer, so
# username/homeDirectory are read from the environment. Apply with --impure
# (or use the `hms` zsh helper):
#   home-manager switch --flake .#silver-hour --impure
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # silver-hour profile: system fonts/VS Code, gnomad + tinty theming, no GTK
  # alterations (see modules/flavors.nix and modules/theming-tools-silver-hour.nix).
  home.modules.silverHour.enable = true;

  # base is default-on; add the visual/misc extras (fonts/VS Code stripped).
  home.bundles.baseExtra.enable = true;

  # docker -> podman alias + user socket.
  home.modules.podmanAlias.enable = true;

  # Base user-facing Flatpaks (devtoolbox stripped — the image covers it).
  home.bundles.flatpak.base.enable = true;
}
