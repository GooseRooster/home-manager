{
  config,
  lib,
  pkgs,
  ...
}:

# zsh: prompt/completions/fuzzy-finder/navigation tools, custom functions
# (see files/zsh/functions.zsh), plus the classic zsh plugin trio for a
# modern editing experience.
#
# This module uses Home Manager's native `enableZshIntegration` flags
# throughout — simpler, well-tested, and every tool it wires up is already
# in the base bundle (pkgs/base.nix) so there's no "missing binary" case to
# guard against here.
let
  cfg = config.home.modules;

  # Per-host override scaffold (~/.config/zsh/extra.zsh). Materialized ONCE
  # by the activation below, then never touched again — user-owned
  # thereafter.
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
    # eza's own ls/ll/la/lt/lla aliases are added separately by modules/eza.nix.
    shellAliases = {
      chrome = "ungoogled-chromium";
      python = "python3";
    }
    // lib.optionalAttrs cfg.podmanAlias.enable {
      docker = "podman";
      lazypodman = "lazydocker";
    };

    # CARAPACE_BRIDGES: order defines precedence (carapace's own specs
    # always win): framework bridges first — they drive the target binary
    # itself (cobra's `__complete`, argcomplete/clap env protocols), so they
    # need no extra installs and beat shell-script completions — then shells
    # by completion quality (zsh > fish > bash). Re-add "inshellisense" at
    # the end if the npm binary is ever installed.
    sessionVariables = {
      CARAPACE_BRIDGES = "cobra,argcomplete,clap,zsh,fish,bash";
    }
    // lib.optionalAttrs cfg.podmanAlias.enable {
      DOCKER_HOST = "unix:///run/user/$(id -u)/podman/podman.sock";
    };

    # ── Plugins ───────────────────────────────────────────────────────────

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
      # SSH-agent (WSL only) + the per-host override file. Runs before
      # everything else so env-vars secrets/overrides land before any plugin
      # reads them.
      # keychain: either attach to a running agent or start a new one.
      (lib.mkOrder 550 (
        (lib.optionalString cfg.wsl.enable ''
          eval "$(keychain --eval --quiet)"
          systemctl --user import-environment SSH_AUTH_SOCK SSH_AGENT_PID 2>/dev/null
        '')
        + ''
          # Per-host overrides (env vars, secrets) — scaffolded once by
          # materializeZshExtra below, then user-owned.
          [[ -f "$HOME/.config/zsh/extra.zsh" ]] && source "$HOME/.config/zsh/extra.zsh"
        ''
      ))

      # Custom functions
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

      # Source deja, replaces autosuggestions
      (lib.mkOrder 1500 ''

        export DEJA_CYCLE_KEY='^[[Z'
        if [[ -r "$HOME/.local/share/deja/init.zsh" ]]; then
          source "$HOME/.local/share/deja/init.zsh"
        else
          eval "$(deja init zsh)"
        fi

      '')

      # greeting on interactive sessions
      (lib.mkOrder 1900 ''
        [[ $- == *i* ]] && pfetch
      '')
    ];
  };

  # carapace — completion engine.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # zoxide — smarter cd.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # fzf — ^R history / ^T file widgets. HM sources key-bindings.zsh, whose
  # history widget lists the full in-memory history (`fc -lin 1`), including
  # entries not yet flushed to $HISTFILE. The order-1310 rebind above restores
  # the ^R/^T bindings zvm clobbers.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # extra.zsh: materialize once, never overwrite. NOT xdg.configFile — that
  # would clobber user edits on every switch.
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
