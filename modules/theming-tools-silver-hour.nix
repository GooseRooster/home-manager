{
  config,
  lib,
  pkgs,
  gnomad ? null,
  ...
}:

# silver-hour theming tooling (GNOME/tinty flow): gnomad picks the base16/base24
# scheme, tinty syncs the tinted-theming item set.
#
# gnomad comes from its own flake (flake.nix input) and the custom gnomad
# schemes live under files/gnomad/schemes. tinty itself (package, config.toml,
# sync, the shared terminal items) is modules/tinty.nix; this module appends
# the desktop items. `theme = "tinted-theming"` in modules/ghostty.nix makes
# the tinted-terminal ghostty hook effective.
let
  cfg = config.home.modules;

  schemesDir = ../files/gnomad/schemes;
  schemes = lib.filterAttrs (_: type: type == "regular") (builtins.readDir schemesDir);

  # Desktop tinty items, appended to home.modules.tinty.items. The Steam hook
  # writes the Adwaita-for-Steam custom.css consumed by
  # modules/steam-adwaita.nix; the Vesktop hook stays, gaming-gated.
  tintyItems = [
    {
      path = "https://github.com/tinted-theming/tinted-shell";
      name = "tinted-shell";
      themes-dir = "scripts";
      hook = ". %f";
      supported-systems = [ "base16" "tinted8" ];
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
      supported-systems = [ "base16" "base24" "tinted8" ];
    }
    {
      path = "https://github.com/tinted-theming/tinted-zen";
      name = "tinted-zen";
      themes-dir = "output";
      hook = ''
        profile_dir="$HOME/.zen/$(awk -F= "/^\[Install/{i=1} i && /^Default=/{print \$2; exit}" "$HOME/.zen/profiles.ini")"
        mkdir -p "''${profile_dir}/chrome"
        cp -f "$TINTY_THEME_FILE_PATH" "''${profile_dir}/chrome/userChrome.css"
      '';
      supported-systems = [ "base16" "base24" "tinted8" ];
    }
  ] ++ lib.optionals cfg.gaming.enable [
    {
      # Vesktop (Discord)
      path = "https://github.com/deathbeam/base16-discord.git";
      name = "base16-discord";
      themes-dir = "themes";
      theme-file-extension = ".theme.css";
      supported-systems = [ "base16" ];
      hook = ''
        mkdir -p "$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings"
        cp -f "$TINTY_THEME_FILE_PATH" "$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css"
      '';
    }
  ] ++ lib.optionals cfg.steamAdwaita.enable [
    {
      # Adwaita-for-Steam: modules/steam-adwaita.nix watches this file and
      # re-runs the skin installer after each tinty apply.
      path = "https://github.com/GooseRooster/tinted-adwaita-for-steam";
      name = "tinted-adwaita-for-steam";
      themes-dir = "output";
      supported-systems = [ "base16" "base24" "tinted8" ];
      hook = ''
        mkdir -p "$HOME/.config/AdwSteamGtk"
        cp -f "$TINTY_THEME_FILE_PATH" "$HOME/.config/AdwSteamGtk/custom.css"
      '';
    }
  ];

  # ChromaLeon -> tinty bridge. ChromaLeon only persists a single accent colour
  # (plus a per-wallpaper cache), so we re-derive the palette from the current
  # wallpaper and map it onto a tinted8 scheme. The bridge itself ships in
  # gnomad's own repository (assets/chromaleon-bridge) and is packaged as
  # `chromaleon-bridge`; this module only wires up the units around it.
  gnomadBridge = gnomad.packages.${pkgs.stdenv.hostPlatform.system}.chromaleon-bridge;

  # The bridge, with the depth dial baked in.
  #
  # `depth` is a property of the installation, not of the invocation: the
  # systemd units and gnomad's on_wallpaper_apply hook both end up calling the
  # same script, and they must agree — otherwise each one regenerates the
  # scheme with a different palette and they overwrite each other. Baking it
  # into the wrapper makes the nix option the single source of truth for
  # every path (units, the hook, a manual run).
  chromaleonBridge = pkgs.runCommand "gnomad-chromaleon-bridge"
    { nativeBuildInputs = [ pkgs.makeWrapper ]; }
    ''
      mkdir -p $out/bin
      cp ${gnomadBridge}/bin/chromaleon_tinty \
         ${gnomadBridge}/bin/chromaleon_tinty_watch \
         ${gnomadBridge}/bin/chromaleon_palette.py \
         ${gnomadBridge}/bin/chromaleon_pixels.js \
         $out/bin/
      chmod +x $out/bin/*
      wrapProgram $out/bin/chromaleon_tinty \
        --set CHROMALEON_DEPTH ${toString cfg.chromaleon.depth} \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.coreutils pkgs.dconf pkgs.gjs pkgs.imagemagick
          pkgs.python3 pkgs.tinty pkgs.util-linux
        ]}
      wrapProgram $out/bin/chromaleon_tinty_watch \
        --set CHROMALEON_DEPTH ${toString cfg.chromaleon.depth} \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.coreutils pkgs.dconf pkgs.gjs pkgs.imagemagick
          pkgs.python3 pkgs.tinty pkgs.util-linux
        ]}
    '';
in
{
  options.home.modules.chromaleon = {
    depth = lib.mkOption {
      type = lib.types.ints.between 0 3;
      default = 1;
      description = ''
        How far the generated terminal palette moves away from the ChromaLeon
        shell surface in OKLCH. 0 matches the shell surface exactly; 3 adds a
        pronounced luminance/chroma separation for depth.
      '';
    };
  };

  config = lib.mkIf cfg.silverHour.enable {
  assertions = [
    {
      assertion = gnomad != null;
      message = "home.modules.silverHour requires the gnomad flake input (see flake.nix extraSpecialArgs).";
    }
    {
      assertion = cfg.tinty.enable;
      message = "home.modules.silverHour requires home.modules.tinty (the ChromaLeon bridge runs `tinty apply`).";
    }
  ];

  home.modules.tinty.items = tintyItems;

  # gnomad's package wraps git/gowall/tinty/glib into its PATH; tinty itself
  # comes from modules/tinty.nix. The ChromaLeon bridge is installed as well
  # so it can be called by name — gnomad's `on_wallpaper_apply` hook is the
  # deterministic way to re-derive the scheme when gnomad changes the
  # wallpaper.
  home.packages = [
    gnomad.packages.${pkgs.stdenv.hostPlatform.system}.gnomad
    chromaleonBridge
  ];

  home.file = lib.mapAttrs' (name: _: {
    name = ".config/gnomad/schemes/${name}";
    value = {
      force = true;
      source = schemesDir + "/${name}";
    };
  }) schemes;

  # ChromaLeon integration (silver-hour only). The path unit fires whenever
  # ChromaLeon rewrites its generated Shell stylesheets (accent pick, tint
  # settings); the login oneshot applies the scheme at session start (--force
  # so an unchanged scheme still re-runs the tinty hooks); the variant service
  # watches GNOME's color-scheme key and the wallpaper, so the palette follows
  # a wallpaper change even when ChromaLeon does not restyle the shell.
  systemd.user.paths.gnomad-chromaleon = {
    Unit.Description = "Watch ChromaLeon stylesheets for accent changes";

    Path = {
      PathModified = [
        "%h/.cache/chromaleon/chromaleon-shell.css"
        "%h/.cache/chromaleon/chromaleon-shell-dark.css"
      ];
      Unit = "gnomad-chromaleon.service";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.gnomad-chromaleon = {
    Unit.Description = "Generate and apply the ChromaLeon tinted8 scheme";

    Service = {
      Type = "oneshot";
      ExecStart = "${chromaleonBridge}/bin/chromaleon_tinty --force";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.gnomad-chromaleon-variant = {
    Unit = {
      Description = "Re-apply the ChromaLeon tinted8 scheme on wallpaper/light-dark changes";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${chromaleonBridge}/bin/chromaleon_tinty_watch";
      Restart = "always";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
  };
}
