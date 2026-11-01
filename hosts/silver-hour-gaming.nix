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

  # Jackify (Wabbajack modlist manager), installed from its GitHub release
  # and launched through the sanitizing AppImage wrapper. The module owns
  # the install path, the .desktop entry and the nxm:// handler association
  # — see modules/jackify.nix for the why.
  home.modules.jackify.enable = true;

  # Apply the Adwaita-for-Steam skin (auto-detects native vs Flatpak Steam).
  # tinty feeds it ~/.config/AdwSteamGtk/custom.css; the module's path unit
  # re-installs whenever that file changes.
  home.modules.steamAdwaita.enable = true;

  home.bundles.flatpak.gaming.enable = true;
}
