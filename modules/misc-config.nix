{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only configs are skipped on WSL, mirroring chezmoi's old
  # .chezmoiignore.tmpl wsl block.
  desktopOnly = !cfg.wsl.enable;

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

  # tinty -> Noctalia palette hook — only when the noctalia session is active.
  # Copies the generated base16 palette into Noctalia's user-writable palettes
  # dir (~/.config/noctalia/palettes/) and applies it as a custom scheme.
  noctaliaBlock = ''
    [[items]]
    path = "https://github.com/LePetitPrince-4/base16-noctalia"
    name = "noctalia"
    themes-dir = "palettes"
    hook = "cp -f $TINTY_THEME_FILE_PATH ~/.config/noctalia/palettes/tinty.json && noctalia msg color-scheme-set custom tinty"
  '';

  # Ghostty config: `theme` only when tinty theming is enabled (else ghostty tries
  # to load a tinty theme that was never written), and the shell is the Nix nu.
  ghosttyConfig = lib.concatStringsSep "\n" (
    (lib.optional cfg.theming.enable "theme = \"tinted-theming\"")
    ++ [
      "command = ${pkgs.nushell}/bin/nu"
      "confirm-close-surface = false"
      "adjust-cell-height = 15%"
      "font-size = 14"
    ]
  ) + "\n";
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
          [ "{{ VESKTOP }}" "{{ NOCTALIA }}" ]
          [
            (lib.optionalString cfg.gaming.enable vesktopBlock)
            (lib.optionalString (cfg.session == "noctalia") noctaliaBlock)
          ]
          (builtins.readFile ../files/tinty/config.toml);
      };
    })
  ];
}
