{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only configs are skipped in dev containers and WSL, mirroring
  # chezmoi's .chezmoiignore.tmpl devcontainer/wsl blocks.
  desktopOnly = !cfg.devcontainer.enable && !cfg.wsl.enable;

  # tinty Vesktop hook — only when gaming is enabled (see files/tinty/config.toml).
  vesktopBlock = ''
    #Vesktop (Discord)
    [[items]]
    path = "https://github.com/deathbeam/base16-discord.git"
    name = "base16-discord"
    themes-dir = "themes"
    theme-file-extension = ".theme.css"
    supported-systems = ["base16"]
    hook = "cp \"$TINTY_THEME_FILE_PATH\" \"$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css\""
  '';
in
{
  # Platform-agnostic configs — binaries come from nix-cli / nixos-config, these
  # only place the config files. force = true: HM owns them (lazygit/lazydocker/
  # btop generate a default on first run; old chezmoi copies may also exist).
  xdg.configFile = {
    "btop/btop.conf" = {
      source = ../files/btop/btop.conf;
      force = true;
    };
    "lazygit/config.yml" = {
      source = ../files/lazygit/config.yml;
      force = true;
    };
    "lazydocker/config.yml" = {
      source = ../files/lazydocker/config.yml;
      force = true;
    };
    "herdr/config.toml" = {
      source = ../files/herdr/config.toml;
      force = true;
    };
    "fastfetch/config.jsonc" = {
      source = ../files/fastfetch/config.jsonc;
      force = true;
    };
  };

  home.file = lib.mkMerge [
    # GUI/desktop-only (skipped in containers/WSL).
    (lib.mkIf desktopOnly {
      ".config/ghostty/config" = {
        source = ../files/ghostty/config;
        force = true;
      };
      ".config/mpv/mpv.conf" = {
        source = ../files/mpv/mpv.conf;
        force = true;
      };
      ".config/owl.jpg" = {
        source = ../files/owl.jpg;
        force = true;
      };
    })

    # Theming (tinty scheme sync + gnomad schemes) — desktop only.
    (lib.mkIf cfg.theming.enable {
      ".config/gnomad/schemes/dragon-ember.yaml" = {
        source = ../files/gnomad/schemes/dragon-ember.yaml;
        force = true;
      };
      ".config/gnomad/schemes/gloaming.yaml" = {
        source = ../files/gnomad/schemes/gloaming.yaml;
        force = true;
      };
      ".config/gnomad/schemes/kiln.yaml" = {
        source = ../files/gnomad/schemes/kiln.yaml;
        force = true;
      };
      ".config/gnomad/schemes/marshlight.yaml" = {
        source = ../files/gnomad/schemes/marshlight.yaml;
        force = true;
      };
      ".config/gnomad/schemes/peat.yaml" = {
        source = ../files/gnomad/schemes/peat.yaml;
        force = true;
      };
      ".config/tinted-theming/tinty/config.toml" = {
        force = true;
        text = builtins.replaceStrings
          [ "{{ VESKTOP }}" ]
          [ (lib.optionalString cfg.gaming.enable vesktopBlock) ]
          (builtins.readFile ../files/tinty/config.toml);
      };
    })
  ];
}
