{
  description = "Home Manager dotfiles — declarative home, brew & bootstrap-free";

  inputs = {
    # CLI "batteries" (packages) live in nix-cli; follow its nixpkgs so HM
    # packages and the CLI bundles are built from the identical revision.
    nix-cli.url = "github:GooseRooster/nix-cli";

    nixpkgs.follows = "nix-cli/nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # The only standalone target is the foreign-WSL one (Ubuntu, Debian,
  # ... non-NixOS distros), applied with:
  #   home-manager switch --flake .#wsl --impure
  outputs = { self, nixpkgs, home-manager, nix-cli, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations.wsl =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nix-cli; };
          modules = [
            ./home.nix
            ./hosts/wsl.nix
          ];
        };

      # Reusable module bundles for NixOS integration
      # (home-manager.users.<name>.imports = [ dotfiles.hmModules.default ];).
      hmModules = {
        default = ./home.nix;
        wsl.imports = [ ./home.nix ./hosts/wsl.nix ];
      };
    };
}
