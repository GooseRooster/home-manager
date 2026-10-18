{
  config,
  lib,
  pkgs,
  gnomad ? null,
  ...
}:

# silver-hour theming tooling (GNOME/tinty flow). This is the counterpart to
# modules/theming-tools.nix (which is the Noctalia/gowall flow): the two are
# mutually exclusive and selected by home.modules.silverHour.
#
# Restores the tinty + gnomad setup that predated the Noctalia migration
# (removed in c86c580): gnomad comes from its own flake (flake.nix input), the
# custom gnomad schemes live under files/gnomad/schemes, and tinty syncs the
# tinted-theming item set. `theme = "tinted-theming"` in modules/ghostty.nix
# makes the tinted-terminal ghostty hook effective.
let
  cfg = config.home.modules;

  schemesDir = ../files/gnomad/schemes;
  schemes = lib.filterAttrs (_: type: type == "regular") (builtins.readDir schemesDir);

  # Tinty scheme-sync items. The Steam Millennium hook was dropped with the
  # silver-hour move (the image's Steam skin is applied by its own systemd
  # service); the Vesktop hook stays, gaming-gated.
  tintyItems = [
    {
      path = "https://github.com/tinted-theming/tinted-shell";
      name = "tinted-shell";
      themes-dir = "scripts";
      hook = ". %f";
      supported-systems = [ "base16" "tinted8" ];
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
      hook = "cp \"$TINTY_THEME_FILE_PATH\" \"$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css\"";
    }
  ];

  # ChromaLeon -> tinty bridge. ChromaLeon only persists a single accent colour
  # (plus a per-wallpaper cache), so we re-derive the palette from the current
  # wallpaper and map it onto a tinted8 scheme. See files/scripts/chromaleon_*.
  chromaleonTinty = pkgs.writeShellApplication {
    name = "chromaleon_tinty";
    runtimeInputs = with pkgs; [
      coreutils
      dconf
      imagemagick
      python3
      tinty
      util-linux
    ];
    text = ''
      export CHROMALEON_PALETTE="${../files/scripts/chromaleon_palette.py}"
    '' + builtins.readFile ../files/scripts/chromaleon_tinty;
  };

  # Long-running dconf watcher: keeps the scheme variant in step with the
  # desktop light/dark toggle even when ChromaLeon does not rewrite its CSS.
  chromaleonTintyWatch = pkgs.writeShellApplication {
    name = "chromaleon_tinty_watch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dconf
      chromaleonTinty
    ];
    text = builtins.readFile ../files/scripts/chromaleon_tinty_watch;
  };
in
lib.mkIf cfg.silverHour.enable {
  assertions = [
    {
      assertion = gnomad != null;
      message = "home.modules.silverHour requires the gnomad flake input (see flake.nix extraSpecialArgs).";
    }
  ];

  # gnomad's package wraps git/gowall/tinty/glib into its PATH; tinty is also
  # installed directly so the user can drive scheme sync by hand.
  home.packages = [
    gnomad.packages.${pkgs.stdenv.hostPlatform.system}.gnomad
    pkgs.tinty
  ];

  home.file = lib.mapAttrs' (name: _: {
    name = ".config/gnomad/schemes/${name}";
    value = {
      force = true;
      source = schemesDir + "/${name}";
    };
  }) schemes // {
    ".config/tinted-theming/tinty/config.toml" = {
      force = true;
      source = (pkgs.formats.toml { }).generate "tinty-config" { items = tintyItems; };
    };
  };

  # Pre-create the hook output dirs, then run the initial `tinty sync` so
  # gnomad / `tinty apply` work immediately. Idempotent: sync only runs when the
  # data dir is absent. Runs after writeBoundary so the config above exists.
  home.activation.tintySetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      local dirs="$HOME/.config/ghostty/themes $HOME/.claude/themes"
      ${lib.optionalString cfg.gaming.enable ''dirs="$dirs $HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings"''}
      mkdir -p $dirs

      if [ ! -d "$HOME/.local/share/tinted-theming/tinty" ]; then
        PATH="${pkgs.git}/bin:$PATH" ${pkgs.tinty}/bin/tinty sync \
          || echo "WARN: 'tinty sync' failed (offline?), skipping." >&2
      fi
    }
    run
  '';

  # ChromaLeon integration (silver-hour only). The path unit fires whenever
  # ChromaLeon rewrites its generated Shell stylesheets (wallpaper change,
  # accent pick, tint settings); the login oneshot applies the scheme at session
  # start (--force so an unchanged scheme still re-runs the tinty hooks); the
  # variant service watches GNOME's color-scheme key for live light/dark flips.
  systemd.user.paths.tinty-chromaleon = {
    Unit.Description = "Watch ChromaLeon stylesheets for accent changes";

    Path = {
      PathModified = [
        "%h/.cache/chromaleon/chromaleon-shell.css"
        "%h/.cache/chromaleon/chromaleon-shell-dark.css"
      ];
      Unit = "tinty-chromaleon.service";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.tinty-chromaleon = {
    Unit.Description = "Generate and apply the ChromaLeon tinted8 scheme";

    Service = {
      Type = "oneshot";
      ExecStart = "${chromaleonTinty}/bin/chromaleon_tinty --force";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.tinty-chromaleon-variant = {
    Unit = {
      Description = "Re-apply the ChromaLeon tinted8 scheme on light/dark changes";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${chromaleonTintyWatch}/bin/chromaleon_tinty_watch";
      Restart = "always";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
