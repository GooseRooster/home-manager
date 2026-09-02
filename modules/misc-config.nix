{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only configs are skipped on WSL.
  desktopOnly = !cfg.wsl.enable;

  # Tinty scheme-sync items. The Vesktop entry is appended only with the
  # gaming flag.
  tintyItems = [
    {
      path = "https://github.com/tinted-theming/tinted-shell";
      name = "tinted-shell";
      themes-dir = "scripts";
      hook = ". %f";
    }
    {
      # Claude Code
      name = "tinted-claude-code";
      path = "https://github.com/tinted-theming/tinted-claude-code";
      themes-dir = "scripts";
      theme-file-extension = ".js";
      supported-systems = [ "base16" "base24" "tinted8" ];
      hook = "mkdir -p \"$HOME/.claude/themes\" && node \"$TINTY_THEME_FILE_PATH\" > \"$HOME/.claude/themes/tinty.json\"";
    }
    {
      # Ghostty — with `theme` set to "tinted-theming" (see modules/ghostty.nix),
      # this is where Ghostty looks for the theme file.
      path = "https://github.com/tinted-theming/tinted-terminal";
      name = "tinted-terminal";
      themes-dir = "themes/ghostty";
      hook = ''
        mkdir -p ~/.config/ghostty/themes
        command cp -f "$TINTY_THEME_FILE_PATH" ~/.config/ghostty/themes/tinted-theming
        killall -SIGUSR2 ghostty 2>/dev/null || true
      '';
      supported-systems = [ "base16" "base24" ];
    }
  ] ++ lib.optional cfg.gaming.enable {
    # Vesktop (Discord)
    path = "https://github.com/deathbeam/base16-discord.git";
    name = "base16-discord";
    themes-dir = "themes";
    theme-file-extension = ".theme.css";
    supported-systems = [ "base16" ];
    hook = "cp \"$TINTY_THEME_FILE_PATH\" \"$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css\"";
  };
in
{
  # Shell-agnostic session env. home.sessionVariables feeds the systemd user
  # environment, so GUI apps and termapp-launched shells get these even
  # without an interactive shell bootstrap NVIM_PROFILE is read by nvim's
  # profile.lua (files/nvim/lua/config/profile.lua).
  home.sessionVariables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
    VISUAL = "${pkgs.neovim}/bin/nvim";
    NVIM_PROFILE = "minimal";
  };

  # herdr's config lives in modules/herdr.nix (programs.herdr).

  home.file = lib.mkMerge [
    # GUI/desktop-only (skipped in containers/WSL). mpv.conf is declarative
    # here, the file is picked up by external/flatpak mpv runs).
    (lib.mkIf desktopOnly {
      ".config/mpv/mpv.conf" = {
        force = true;
        text = lib.generators.toKeyValue { } {
          vo = "gpu-next";
          gpu-api = "vulkan";
          hwdec = "vaapi";
          hwdec-codecs = "all";
          deband = "yes";
          dither-depth = "auto";
          panscan = "0.8";
          pipewire-buffer = "50";
          target-peak = "1000";
        };
      };
      ".config/owl.jpg" = {
        source = ../files/owl.jpg;
        force = true;
      };
    })

    # Theming (tinty scheme sync + gnomad schemes) — desktop only. tinty is a
    # gnome-session-only tool: Noctalia's builtin templates own app theming in
    # the noctalia session, so the tinty/gnomad files are dropped there.
    (lib.mkIf (cfg.theming.enable && cfg.session == "gnome") {
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
        source = (pkgs.formats.toml { }).generate "tinty-config" { items = tintyItems; };
      };
    })

    # Theming - desktop only. Noctalia custom schemes.
    (lib.mkIf (cfg.theming.enable && cfg.session == "noctalia") {
      ".config/noctalia/palettes/peat.json" = {
          force = true;
          source = ../files/noctalia/palettes/peat.json;
      };
      ".config/noctalia/palettes/peat_bog.json" = {
          force = true;
          source = ../files/noctalia/palettes/peat_bog.json;
      };
      ".config/noctalia/palettes/peat_mist.json" = {
          force = true;
          source = ../files/noctalia/palettes/peat_mist.json;
      };
    })
  ];
}
