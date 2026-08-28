{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only configs are skipped on WSL, mirroring chezmoi's old
  # .chezmoiignore.tmpl wsl block.
  desktopOnly = !cfg.wsl.enable;

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

  # Ghostty config. The `theme` line points at whichever retint mechanism the
  # session uses: tinty writes ~/.config/ghostty/themes/tinted-theming, while
  # Noctalia's builtin ghostty template writes ~/.config/ghostty/themes/noctalia
  # (and its apply.sh no-ops on configs already set to `theme = noctalia`,
  # which matters because HM's config is a read-only symlink).
  # The shell is the Nix nu.
  ghosttyConfig = lib.concatStringsSep "\n" (
    (lib.optional cfg.theming.enable (
      if cfg.session == "noctalia" then "theme = noctalia" else "theme = \"tinted-theming\""
    ))
    ++ [
      "command = ${pkgs.nushell}/bin/nu"
      "confirm-close-surface = false"
      "adjust-cell-height = 15%"
      "font-size = 14"
    ]
  ) + "\n";
in
{
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
        force = true;
        text = ghosttyConfig;
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

    # Theming (tinty scheme sync + gnomad schemes) — desktop only. tinty is
    # dropped in the noctalia session: Noctalia templates own app theming there.
    (lib.mkIf (cfg.theming.enable && cfg.session != "noctalia") {
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
