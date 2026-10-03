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
  };

  # Standalone targets: foreign systems (WSL distros, dev containers) with a
  # standalone Nix install, applied with (--impure reads $USER/$HOME at eval
  # time — the user name varies by image/distro):
  #   home-manager switch --flake .#container --impure
  #   home-manager switch --flake .#wsl --impure
  outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # nix-flatpak's home-manager module, exposed to every HM evaluation via
      # extraSpecialArgs. modules/flatpak.nix reads it as a plain function
      # argument (not _module.args, which would recurse when referenced from
      # `imports`). Works for standalone targets and the NixOS `hmModules`
      # integration alike.
      extraSpecialArgs = { inherit nix-flatpak; };
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
      };

      # Reusable module bundles for NixOS integration
      # (home-manager.users.<name>.imports = [ dotfiles.hmModules.default ];).
      # nixos-config passes nix-flatpak via extraSpecialArgs on its side.
      hmModules = {
        default.imports = [ ./home.nix ];
        wsl.imports = [ ./home.nix ./hosts/wsl.nix ];
      };
    };
}
