{
  lib,
  config,
  ...
}:

# direnv + nix-direnv — auto-loads per-project .envrc files. Part of the base
# bundle so every target (devcontainer, WSL, desktop) gets it. nix-direnv
# caches flake/devshell evals, so re-entering a project is instant instead of
# re-evaluating the flake each time.
{
  config = lib.mkIf config.home.bundles.base.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
