{
  description = "Home Manager dotfiles — declarative home + CLI batteries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Source of truth for television's community cable channels (linked into
    # ~/.config/television/cable by modules/television.nix). Pinned in the
    # lockfile, so channel updates ride along with `nix flake update`.
    television.url = "github:alexpasmantier/television";
  };

  # Standalone targets: foreign systems (WSL distros, dev containers) with a
  # standalone Nix install, applied with (--impure reads $USER/$HOME at eval
  # time — the user name varies by image/distro):
  #   home-manager switch --flake .#container --impure
  #   home-manager switch --flake .#wsl --impure
  outputs = { self, nixpkgs, home-manager, television, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Upstream cable channels: a plain source path into the pinned television
      # checkout. Channels are organized per-OS upstream (cable/unix,
      # cable/windows); this flake is linux-only, so unix it is. Threaded to
      # modules via _module.args so both the standalone homeConfigurations and
      # the NixOS-consumed hmModules see it.
      tvCable = "${television}/cable/unix";
    in
    {
      homeConfigurations = {
        # Lean dev-container target: base batteries + dotfiles, nothing else.
        container =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              { _module.args.tvCable = tvCable; }
              ./home.nix
              ./hosts/container.nix
            ];
          };

        wsl =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              { _module.args.tvCable = tvCable; }
              ./home.nix
              ./hosts/wsl.nix
            ];
          };
      };

      # Reusable module bundles for NixOS integration
      # (home-manager.users.<name>.imports = [ dotfiles.hmModules.default ];).
      hmModules = {
        default.imports = [ { _module.args.tvCable = tvCable; } ./home.nix ];
        wsl.imports = [ { _module.args.tvCable = tvCable; } ./home.nix ./hosts/wsl.nix ];
      };
    };
}
