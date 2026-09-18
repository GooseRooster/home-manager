{ lib, ... }:

# Feature flags. Hosts (hosts/*.nix) set these; modules use
# `lib.mkIf`/`lib.optionalString` to include or omit files.
let
  mkFlag = desc: lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = desc;
  };
in
{
  options.home.modules = {
    # Which shell "default shell" consumers hand off to: ghostty's `command`
    # (modules/ghostty.nix), the WSL bash hand-off (modules/wsl-shell-launcher.nix)
    # and nixos-config's termapp wrapper, which reads this flag back via
    # config.home-manager.users.<primary>.home.modules.defaultShell.
    defaultShell = lib.mkOption {
      type = lib.types.enum [ "nu" "zsh" ];
      default = "nu";
      description = ''
        Default interactive shell: "nu" (nushell) or "zsh". Set per host in
        hosts/*.nix; every consumer (ghostty command, WSL bash launcher,
        termapp) follows it together.
      '';
    };
    # Which Neovim config becomes "main" — the one plain `nvim`/$EDITOR/
    # $VISUAL resolve to. modules/nvim.nix (LazyVim) and
    # modules/nvim-minimax.nix (MiniMax) each always deploy themselves to
    # their own fixed path/alias (~/.config/nvim-lazyvim, ~/.config/nvim-minimax)
    # regardless of this setting, so the non-selected variant stays reachable
    # for comparison without touching this flag back — see modules/nvim-main.nix,
    # which reads `nvimPackages.${nvimVariant}` to build ~/.config/nvim.
    nvimVariant = lib.mkOption {
      type = lib.types.enum [ "lazyvim" "minimax" ];
      default = "lazyvim";
      description = ''
        Which Neovim config is "main": "lazyvim" (modules/nvim.nix) or
        "minimax" (modules/nvim-minimax.nix). Both are always built and
        always reachable via their own `nvim-lazyvim`/`nvim-minimax` shell
        alias regardless of this setting — it only decides which one plain
        `nvim` opens.
      '';
    };
    # Internal: set by modules/nvim.nix ("lazyvim") and
    # modules/nvim-minimax.nix ("minimax"), consumed by modules/nvim-main.nix.
    # Not meant to be set by hosts.
    nvimPackages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      internal = true;
      default = { };
      description = "Built nvim config derivations, keyed by variant name.";
    };
    gaming = {
      enable = mkFlag "Gaming-specific dotfile content (yazi Steam/Emulation hops, tinty Vesktop theme hook).";
    };
    theming = {
      enable = mkFlag "Theming tooling config (tinty scheme sync, gnomad schemes).";
    };
    podmanAlias = {
      enable = mkFlag "DOCKER_HOST -> podman socket and docker -> podman alias in nushell.";
    };
    wsl = {
      enable = mkFlag "NixOS-WSL profile: skip GUI dotfiles.";
    };
  };
}
