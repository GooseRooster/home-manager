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

  # nix-flatpak's flatpak-managed-install.service installs the whole Flatpak set
  # on activation; on a cold cache that runs past sd-switch's 120000 ms default
  # (TimeoutStartSec=infinity on the unit, so sd-switch is the only bound). When
  # sd-switch times out the activation aborts before installPackages, leaving
  # ~/.nix-profile (and thus `home-manager`) uninstalled. 0 means "no --timeout"
  # i.e. the 2-min default, so a nonzero ceiling is required. 15 min is ~6x the
  # observed cold-install time; only affects switches, not running units.
  systemd.user.servicesStartTimeoutMs = 900000;

  # docker -> podman alias + user socket.
  home.modules.podmanAlias.enable = true;

  # Base user-facing Flatpaks (devtoolbox stripped — the image covers it).
  home.bundles.flatpak.base.enable = true;
}
