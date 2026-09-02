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

  # Per-host override scaffold (~/.config/zsh/extra.zsh): the zsh twin of
  # nu's env.local.nu (modules/nushell.nix). Materialized ONCE by the
  # activation below, then never touched again — user-owned thereafter.
  extraScaffold = ''
    # Per-host zsh overrides: env vars, secrets, aliases.
    #
    # Managed by Home Manager ONLY on first apply: materialized here from the
    # scaffold, then never touched again. Edit freely — your changes are safe.
    # To reset to the scaffold, delete this file and re-run
    # `home-manager switch`. Sourced from ~/.zshrc on every interactive start.
  '';
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

    # CARAPACE_BRIDGES mirrors the value nushell sets in its own env.nu
    # (modules/nushell.nix). Order defines precedence (carapace's own specs
    # always win): framework bridges first — they drive the target binary
    # itself (cobra's `__complete`, argcomplete/clap env protocols), so they
    # need no extra installs and beat shell-script completions — then shells
    # by completion quality (zsh > fish > bash). Re-add "inshellisense" at
    # the end if the npm binary is ever installed.
    # DOCKER_HOST mirrors modules/nushell.nix's podman-alias.nu — same
    # runtime `$(id -u)` lookup, evaluated at shell-init time.
    sessionVariables = {
      CARAPACE_BRIDGES = "cobra,argcomplete,clap,zsh,fish,bash";
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
      # Session env mirroring nu's env.nu (modules/nushell.nix): SSH-agent
      # fallback + the per-host override file. Runs before everything else
      # so env-vars secrets/overrides land before any plugin reads them.
      (lib.mkOrder 550 ''
        # SSH agent: if no socket is set (or points at nothing), fall back to
        # the well-known user-agent path — services.ssh-agent exports it on
        # WSL; gcr-ssh-agent sets SSH_AUTH_SOCK via the systemd user env on
        # the desktop. Same semantics as nu's env.nu fallback.
        if [[ -z "''${SSH_AUTH_SOCK:-}" || ! -e "''${SSH_AUTH_SOCK:-}" ]]; then
          : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        fi

        # Per-host overrides (env vars, secrets) — scaffolded once by
        # materializeZshExtra below, then user-owned.
        [[ -f "$HOME/.config/zsh/extra.zsh" ]] && source "$HOME/.config/zsh/extra.zsh"
      '')

      # Custom functions ported from files/nushell/config.nu
      # (get-os-release-field, distro-glyph, fastfetch wrapper, l., mkcd,
      # home, notebook, backup, copy, the dotnet completion shim). After
      # compinit (needed by the dotnet compdef), before the plugins below.
      (lib.mkOrder 600 (builtins.readFile ../files/zsh/functions.zsh))

      # fzf-tab — fzf-powered Tab menu (Aloxaf/fzf-tab, packaged in nixpkgs as
      # zsh-fzf-tab). Upstream requires loading AFTER compinit but BEFORE
      # plugins that wrap widgets (autosuggestions at 700,
      # fast-syntax-highlighting at 1210, zsh-vi-mode at 1300) — this slot
      # satisfies both. It wraps `expand-or-complete`, so Tab runs it from
      # every keymap, zvm included. Tune with zstyles here, e.g.
      #   zstyle ':fzf-tab:*' show-group full
      #   zstyle ':completion:*:descriptions' format '[%d]'
      (lib.mkOrder 610 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
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

      # zsh-vi-mode: define zvm's documented post-init hook BEFORE the plugin
      # is sourced. zvm does NOT init at source time — by default (lazy
      # ZVM_INIT_MODE) zvm_init runs at the first prompt, i.e. after this
      # whole .zshrc — where its `bindkey -v` + viins bindings clobber any
      # ^R/^T binds made statically (verified via `zsh -x` in a pty:
      # zvm_init's `bindkey -M viins '^R' history-incremental-search-backward`
      # lands AFTER our earlier rebinds). zvm_after_init runs at the end of
      # zvm_init, so rebinding here wins regardless of when zvm initializes.
      # Guarded on the widget, so this is a no-op without the fzf
      # integration. https://github.com/jeffreytse/zsh-vi-mode#-execute-extra-commands
      (lib.mkOrder 1290 ''
        zvm_after_init() {
          # fzf's ^R history / ^T file widgets.
          if (( $+widgets[fzf-history-widget] )); then
            bindkey -M emacs '^R' fzf-history-widget
            bindkey -M viins '^R' fzf-history-widget
            bindkey -M emacs '^T' fzf-file-widget
            bindkey -M viins '^T' fzf-file-widget
          fi
          # fzf-tab: reclaim Tab. HM's fzf integration (fzf --zsh) rebinds ^I
          # to its own fzf-completion widget — sourced after fzf-tab, so it
          # wins — whose fallback runs the UNwrapped expand-or-complete,
          # silently bypassing fzf-tab. Without this, fzf-tab loads but Tab
          # never reaches it.
          if (( $+widgets[fzf-tab-complete] )); then
            bindkey -M emacs '^I' fzf-tab-complete
            bindkey -M viins '^I' fzf-tab-complete
          fi
        }
      '')

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

  # fzf — ^R history / ^T file widgets. HM sources key-bindings.zsh, whose
  # history widget lists the full in-memory history (`fc -lin 1`), including
  # entries not yet flushed to $HISTFILE. The order-1310 rebind above restores
  # the ^R/^T bindings zvm clobbers. Nushell gets no fzf integration (fzf has
  # no nu support); nu's ^R falls back to its built-in history menu.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # extra.zsh: materialize once, never overwrite (mirrors nu's
  # env.local.nu handling in modules/nushell.nix). NOT xdg.configFile —
  # that would clobber user edits on every switch.
  home.activation.materializeZshExtra = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      local target="$HOME/.config/zsh/extra.zsh"
      if [ ! -e "$target" ]; then
        mkdir -p "$(dirname "$target")"
        cp ${pkgs.writeText "extra.zsh" extraScaffold} "$target"
      fi
    }
    run
  '';
}
