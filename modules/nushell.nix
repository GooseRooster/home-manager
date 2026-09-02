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
    configFile.source = ../files/nushell/config.nu;
    envFile.text = ''
      # ── SSH agent ─────────────────────────────────────────────────────────────
      let existing_sock = ($env.SSH_AUTH_SOCK? | default "")
      if ($existing_sock == "") or (not ($existing_sock | path exists)) {
          let uid = (id -u | str trim)
          $env.XDG_RUNTIME_DIR = ($env.XDG_RUNTIME_DIR? | default $"/run/user/($uid)")
          $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"
      }


      # ── Shell integration bootstrap ───────────────────────────────────────────
      # Runs `exec` only if `cmd` resolves on PATH — lets a leaner host
      # (WSL / minimal install) source this file without every tool installed.
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


  # programs.nushell writes config.nu/env.nu; force them so HM replaces the
  # default files nu generates on first run.
  home.file = {
    "${config.xdg.configHome}/nushell/config.nu".force = true;
    "${config.xdg.configHome}/nushell/env.nu".force = true;
  };

  xdg.configFile = {
    # Sourced unconditionally from config.nu; a no-op comment when the flag is off.
    "nushell/podman-alias.nu" = {
      force = true;
      text = lib.optionalString cfg.podmanAlias.enable ''
        # Point Docker CLI/API clients (lazydocker, etc.) at podman's rootless
        # user socket, and make `docker` invoke podman. Both engines can stay
        # installed — use `command docker` or the full path for the real docker.
        $env.DOCKER_HOST = $"unix:///run/user/(^id -u | str trim)/podman/podman.sock"
        alias docker = podman
        alias lazypodman = lazydocker
      '';
    };
  };

  # env.local.nu: materialize once, never overwrite.
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
}
