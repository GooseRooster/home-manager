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

  outputs = { self, nixpkgs, home-manager, nix-cli, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = host: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nix-cli; };
        modules = [
          ./home.nix
          ./hosts/${host}.nix
        ];
      };

      # Reusable module bundles for NixOS integration
      # (home-manager.users.<name>.imports = [ dotfiles.hmModules.desktop ];).
      mkHostModule = host: { imports = [ ./home.nix ./hosts/${host}.nix ]; };
    in
    {
      homeConfigurations = {
        desktop = mkHome "desktop";
        wsl = mkHome "wsl";
        devcontainer = mkHome "devcontainer";
      };

      hmModules = {
        default = ./home.nix;
        desktop = mkHostModule "desktop";
        wsl = mkHostModule "wsl";
        devcontainer = mkHostModule "devcontainer";
      };
    };
}
