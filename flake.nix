{
  description = "Home Manager dotfiles — declarative home + CLI batteries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative per-user Flatpak installs (nixpkgs removed
    # services.flatpak.packages). Same source as nixos-config's system-side
    # input; here we use its home-manager module (flatpak --user).
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # gnomad — the GNOME base16/base24 colour-scheme TUI used by the silver-hour
    # profile. It ships no home-manager module (only `packages.*` and a NixOS
    # module), so the silver-hour theming module installs its package directly.
    gnomad.url = "github:GooseRooster/gnomad";
    gnomad.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Standalone targets: every host this flake builds for is applied with
  # Home Manager directly (foreign WSL distros, dev containers, the atomic
  # Fedora image). hosts/*.nix read $USER/$HOME at eval time, so the switch
  # needs --impure (the user name varies by image/distro):
  #   home-manager switch --flake .#container --impure
  #   home-manager switch --flake .#wsl --impure
  #   home-manager switch --flake .#silver-hour --impure
  outputs = { self, nixpkgs, home-manager, nix-flatpak, gnomad, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # nix-flatpak's home-manager module (modules/flatpak.nix) and the gnomad
      # flake (modules/theming-tools-silver-hour.nix) are exposed to every HM
      # evaluation via extraSpecialArgs. Both are read as plain function
      # arguments (not _module.args, which would recurse when referenced from
      # `imports`).
      extraSpecialArgs = { inherit nix-flatpak gnomad; };
    in
    {
      homeConfigurations = {
        # Lean dev-container target: base batteries + dotfiles, nothing else.
        container =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            inherit extraSpecialArgs;
            modules = [
              ./home.nix
              ./hosts/container.nix
            ];
          };

        wsl =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            inherit extraSpecialArgs;
            modules = [
              ./home.nix
              ./hosts/wsl.nix
            ];
          };

        # silver-hour image targets (standalone HM on the atomic Fedora image).
        # hosts/*.nix read $USER/$HOME at eval time, so apply with --impure:
        #   home-manager switch --flake .#silver-hour --impure
        silver-hour =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            inherit extraSpecialArgs;
            modules = [
              ./home.nix
              ./hosts/silver-hour.nix
            ];
          };

        # Gaming flavour of the image (adds home.modules.gaming + gaming
        # Flatpaks to the silver-hour target).
        silver-hour-gaming =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            inherit extraSpecialArgs;
            modules = [
              ./home.nix
              ./hosts/silver-hour-gaming.nix
            ];
          };
      };
    };
}
