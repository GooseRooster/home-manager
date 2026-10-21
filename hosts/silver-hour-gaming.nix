{ ... }:

# Gaming flavour of the silver-hour image. Everything from the workstation
# target plus the gaming dotfile content (yazi Steam/Emulation hops, tinty
# Vesktop hook) and the gaming Flatpaks (the image installs ProtonPlus +
# Protontricks as system Flatpaks).
#
#   home-manager switch --flake .#silver-hour-gaming --impure
{
  imports = [ ./silver-hour.nix ];

  home.modules.gaming.enable = true;

  home.bundles.flatpak.gaming.enable = true;
}
