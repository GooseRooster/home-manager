{
  description = "Home Manager dotfiles — declarative home + CLI batteries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Standalone targets: foreign systems (WSL distros, dev containers) with a
  # standalone Nix install, applied with (--impure reads $USER/$HOME at eval
  # time — the user name varies by image/distro):
  #   home-manager switch --flake .#container --impure
  #   home-manager switch --flake .#wsl --impure
  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        # Lean dev-container target: base batteries + dotfiles, nothing else.
        container =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home.nix
              ./hosts/container.nix
            ];
          };

        wsl =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home.nix
              ./hosts/wsl.nix
            ];
          };
      };

      # Reusable module bundles for NixOS integration
      # (home-manager.users.<name>.imports = [ dotfiles.hmModules.default ];).
      hmModules = {
        default.imports = [ ./home.nix ];
        wsl.imports = [ ./home.nix ./hosts/wsl.nix ];
      };
    };
}
