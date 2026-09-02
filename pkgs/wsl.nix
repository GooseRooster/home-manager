# Extra CLI tooling for a WSL dev host (home.bundles.wsl).
# No language toolchains, no GUI apps.
# Note: `claude-code` is unfree; allowed by the host config
# (nixpkgs.config.allowUnfree in home.nix).
{ pkgs }:

with pkgs; [
  devcontainer
  claude-code
  opencode
  fastfetch
  zk
  lazydocker
  openfortivpn
]
