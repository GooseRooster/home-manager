{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  envLocalScaffold = ''
    # Per-host / per-container secrets and env (API keys, model choices, etc.).
    #
    # Managed by Home Manager ONLY on first apply: materialized here from the
    # scaffold, then never touched again. Edit freely — your changes are safe.
    # To reset to the scaffold, delete this file and re-run `home-manager switch`.
    # You can also drop any per-host secrets or overrides here.
  '';
in
{
  programs.nushell = {
    enable = true;
    # Binary comes from nix-cli's #base bundle; HM only writes config. See the
    # matching note in modules/yazi.nix for the split-repo rationale.
    package = pkgs.emptyDirectory;
    configFile.source = ../files/nushell/config.nu;
    envFile.text = ''
      # ── SSH agent ─────────────────────────────────────────────────────────────
      let existing_sock = ($env.SSH_AUTH_SOCK? | default "")
      if ($existing_sock == "") or (not ($existing_sock | path exists)) {
          let uid = (id -u | str trim)
          $env.XDG_RUNTIME_DIR = ($env.XDG_RUNTIME_DIR? | default $"/run/user/($uid)")
          $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"
      }

      # ── Editor ────────────────────────────────────────────────────────────────
      $env.EDITOR = "${pkgs.neovim}/bin/nvim"
      $env.NVIM_PROFILE = "minimal"

      # ── Shell integration bootstrap ───────────────────────────────────────────
      # Runs `exec` only if `cmd` resolves on PATH — lets a leaner host
      # (devcontainer / WSL) source this file without every tool installed.
      def try-cmd-init [cmd: string, exec: closure] {
          if (which $cmd | is-not-empty) {
              do $exec
          }
      }

      # zoxide — smarter cd
      try-cmd-init "zoxide" { zoxide init nushell | save -f ~/.zoxide.nu }

      # carapace completions
      $env.CARAPACE_BRIDGES = 'cobra,argcomplete,clap'
      mkdir $"($nu.cache-dir)"
      try-cmd-init "carapace" { carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu" }

      # ── Local, uncommitted overrides ─────────────────────────────────────────
      const env_local = path self env.local.nu
      source $env_local
    '';
  };

  # systemd-user session env (replaces chezmoi's environment.d/10-editor.conf):
  # GUI apps launched outside nushell still get a sane $EDITOR.
  home.sessionVariables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
    VISUAL = "${pkgs.neovim}/bin/nvim";
  };

  # programs.nushell writes config.nu/env.nu; force them so HM replaces the
  # default files nu generates on first run.
  home.file = {
    "${config.xdg.configHome}/nushell/config.nu".force = true;
    "${config.xdg.configHome}/nushell/env.nu".force = true;
  };

  xdg.configFile = {
    "nushell/devcontainer.nu" = {
      source = ../files/nushell/devcontainer.nu;
      force = true;
    };

    # Sourced unconditionally from config.nu; a no-op comment when the flag is off.
    "nushell/podman-alias.nu" = {
      force = true;
      text = lib.optionalString cfg.podmanAlias.enable ''
        # Point Docker CLI/API clients (lazydocker, the devcontainer CLI, etc.) at
        # podman's rootless user socket, and make `docker` invoke podman. Both engines
        # can stay installed — use `command docker` or the full path for the real docker.
        $env.DOCKER_HOST = $"unix:///run/user/(^id -u | str trim)/podman/podman.sock"
        alias docker = podman
        alias lazypodman = lazydocker
      '';
    };
  };

  # env.local.nu: materialize once, never overwrite (chezmoi's `create_` pattern).
  home.activation.materializeEnvLocal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      local target="$HOME/.config/nushell/env.local.nu"
      if [ ! -e "$target" ]; then
        mkdir -p "$(dirname "$target")"
        cp ${pkgs.writeText "env.local.nu" envLocalScaffold} "$target"
      fi
    }
    run
  '';

  # WSL only: the distro (Ubuntu/Debian/…) owns ~/.bashrc, so we can't use
  # programs.bash.initExtra without HM taking over the whole file. Append an
  # idempotent block that hands off from bash to nu — but via PROMPT_COMMAND,
  # not a top-level `nu` call.
  #
  # Why the deferral matters: `nix develop` sources ~/.bashrc BEFORE it
  # activates the derivation env (PATH, IN_NIX_SHELL, shellHook). A naive
  # `nu` at the top of bashrc therefore spawns nu with a pre-nix PATH — none
  # of the devShell tools resolve, and `$env.IN_NIX_SHELL?` is missing. The
  # same bug bites direnv, ssh-agent handoff, and anything else that mutates
  # the env after ~/.bashrc but before the first prompt.
  #
  # PROMPT_COMMAND fires just before bash draws its first prompt, by which
  # point the full nix env + shellHook are applied, so `exec nu` inherits
  # everything. `exec` (not plain `nu`) means exiting nu returns to whatever
  # spawned bash — no orphan bash prompt between nu and the parent.
  home.activation.wslNuLauncher = lib.mkIf cfg.wsl.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run() {
        local bashrc="$HOME/.bashrc"
        local marker="# >>> home-manager: nu launcher >>>"
        [ -e "$bashrc" ] || return 0
        grep -qF "$marker" "$bashrc" && return 0
        cat >>"$bashrc" <<'EOF'

# >>> home-manager: nu launcher >>>
# Managed by modules/nushell.nix (wslNuLauncher). Do not edit inline —
# change the source and re-run `home-manager switch`. Delete the whole
# block (markers and all) to force a re-materialization.
#
# Defer `exec nu` to PROMPT_COMMAND so that `nix develop`, direnv, and any
# other rc-time env setup — which runs AFTER ~/.bashrc but BEFORE the
# first prompt — is fully applied when nu spawns. A plain `nu` at the top
# of bashrc snapshots a stale PATH and can't see devShell tools.
if [[ $- == *i* ]]; then
  PROMPT_COMMAND='exec nu'
fi
# <<< home-manager: nu launcher <<<
EOF
      }
      run
    ''
  );
}
