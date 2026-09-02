{ config, lib, pkgs, ... }:

# zsh: a POSIX-compliant alternative to nushell (modules/nushell.nix) with
# matching convenience — same prompt/completions/fuzzy-finder/navigation
# tools, same custom functions (see files/zsh/functions.zsh), plus the
# classic zsh plugin trio for a modern editing experience.
#
# Unlike nushell's manual `try-cmd-init`/cached-script pattern (kept there so
# a leaner host can boot even if a tool binary is missing), this module uses
# Home Manager's native `enableZshIntegration` flags throughout — simpler,
# well-tested, and every tool it wires up is already in the base bundle
# (pkgs/base.nix) so there's no "missing binary" case to guard against here.
let
  cfg = config.home.modules;
in
{
  programs.zsh = {
    enable = true;

    # ── Aliases ─────────────────────────────────────────────────────────────
    # Mirrors files/nushell/config.nu's aliases. eza's own ls/ll/la/lt/lla
    # aliases are added separately by modules/eza.nix.
    shellAliases = {
      chrome = "ungoogled-chromium";
      python = "python3";
    } // lib.optionalAttrs cfg.podmanAlias.enable {
      docker = "podman";
      lazypodman = "lazydocker";
    };

    # CARAPACE_BRIDGES mirrors the value nushell sets in its own env.nu.
    # DOCKER_HOST mirrors modules/nushell.nix's podman-alias.nu — same
    # runtime `$(id -u)` lookup, evaluated at shell-init time.
    sessionVariables = {
      CARAPACE_BRIDGES = "cobra,argcomplete,clap";
    } // lib.optionalAttrs cfg.podmanAlias.enable {
      DOCKER_HOST = "unix:///run/user/$(id -u)/podman/podman.sock";
    };

    # ── Plugins ───────────────────────────────────────────────────────────
    autosuggestion.enable = true;

    # fast-syntax-highlighting, not the plain zsh-syntax-highlighting.
    fastSyntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
    };

    # Up/Down arrow, filtered to lines matching what's already typed.
    historySubstringSearch.enable = true;

    # All hand-written .zshrc content, ordered relative to HM's own
    # plugin/completion blocks (compinit=570, autosuggestion=700,
    # zoxide=851, syntax-highlighting/fast-syntax-highlighting=1200,
    # history-substring-search=1250):
    initContent = lib.mkMerge [
      # Custom functions ported from files/nushell/config.nu
      # (get-os-release-field, distro-glyph, fastfetch wrapper, l., mkcd,
      # home, notebook, backup, copy, the dotnet completion shim). After
      # compinit (needed by the dotnet compdef), before the plugins below.
      (lib.mkOrder 600 (builtins.readFile ../files/zsh/functions.zsh))

      # tv — fuzzy finder shell integration (see modules/television.nix for
      # the cable-channel config). Guarded the zsh-native way, mirroring
      # nushell's try-cmd-init: skip gracefully if the binary isn't on PATH.
      (lib.mkOrder 900 ''
        if (( $+commands[tv] )); then
          source <(tv init zsh)
        fi
      '')

      # fast-syntax-highlighting's "base16" theme uses only ANSI slots 0-15
      # (see its themes/base16.ini), so highlighting follows whatever base16
      # scheme the terminal currently has loaded (ghostty + tinty), the same
      # as every other terminal-color-aware tool here — no extra tinty
      # wiring needed. Applied manually (rather than via the module's own
      # `fastSyntaxHighlighting.theme` option) so stderr can be silenced:
      # applying this specific theme trips a harmless upstream quirk in
      # fast-theme's ini-parsing (a stray "No such theme `none'" warning —
      # confirmed cosmetic: exit 0, styles are set correctly either way).
      (lib.mkOrder 1210 "fast-theme -q base16 2>/dev/null")

      # zsh-vi-mode has no native HM option. Sourced last (after
      # autosuggestions/fast-syntax-highlighting/history-substring-search),
      # per upstream's documented compatibility guidance for plugins that
      # register their own widgets/keybindings:
      # https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands
      (lib.mkOrder 1300 ''
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      '')

      # Greeting: same fastfetch banner nushell shows on every interactive
      # shell start (see files/zsh/functions.zsh's fastfetch() for the
      # container/CONTAINER_ID guard).
      (lib.mkOrder 1900 "fastfetch")
    ];
  };

  # carapace — completion engine. enableNushellIntegration stays off:
  # nushell wires carapace manually (see modules/nushell.nix's env.nu/config.nu),
  # so leaving the default on here would source a second, redundant init.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
  };

  # zoxide — smarter cd. Same enableNushellIntegration rationale as carapace:
  # nushell already sources `zoxide init nushell` manually (cached to
  # ~/.zoxide.nu by modules/nushell.nix's env.nu).
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
  };
}
