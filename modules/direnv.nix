{
  lib,
  config,
  pkgs,
  ...
}:

# direnv + nix-direnv — auto-loads per-project .envrc files. Part of the base
# bundle so every target (devcontainer, WSL, desktop) gets it. nix-direnv
# caches flake/devshell evals, so re-entering a project is instant instead of
# re-evaluating the flake each time.
#
# Also owns the *personal* layer of a project devshell, so project flakes stay
# free of per-developer logic:
#
#   .envrc        (tracked)    use flake
#                              source_env_if_exists .envrc.local
#   .envrc.local  (gitignored) use_dotnet_personal EasyDotnet lazydotnet
#                              export NVIM_LANGS=...
#
# `source_env_if_exists` is placed AFTER `use flake` on purpose: nix-direnv
# invalidates its cache when any file watched before it is newer than the
# cache, so editing .envrc.local reloads direnv without re-evaluating the flake.
let
  # lazydotnet installed as a dotnet global tool ships an apphost that uses the
  # host's generic glibc loader and cannot start against the Nix dotnet runtime
  # inside a devshell (GLIBC_x not found). The framework-dependent DLL in the
  # tool store runs fine under the devshell's `dotnet`, so shim to that.
  lazydotnetShim = pkgs.writeShellScriptBin "lazydotnet" ''
    store="$HOME/.dotnet/tools/.store/lazydotnet"
    if [ ! -d "$store" ]; then
      echo "lazydotnet: not installed (run: dotnet tool update --global lazydotnet)" >&2
      exit 127
    fi
    dll=""
    for v in $(ls -1 "$store" | sort -V -r); do
      for candidate in "$store/$v"/lazydotnet/*/tools/*/any/lazydotnet.dll; do
        if [ -f "$candidate" ]; then
          dll="$candidate"
          break 2
        fi
      done
    done
    if [ -z "$dll" ]; then
      echo "lazydotnet: no lazydotnet.dll found under $store" >&2
      exit 127
    fi
    exec dotnet "$dll" "$@"
  '';
in
{
  config = lib.mkIf config.home.bundles.base.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;

      # Quiet by default. Nix's own build/download output is raw stderr and is
      # unaffected by either setting.
      #   * hide_env_diff: drop the giant `direnv: export +AR +AS ...` line.
      #   * log_filter: SHOW-ONLY regex for direnv's own `direnv: ...` lines
      #     (despite the docs' wording). Hides loading / using flake / cache
      #     renewed; keeps fallbacks, stale-cache and failure notices. Errors
      #     (log_error) are never filtered.
      config.global = {
        hide_env_diff = true;
        log_filter = "(?i)(fall(ing)? back|failed|fail:|out of date|does not exist|warn|taking|personal)";
      };

      stdlib = ''
        # Usage: use_dotnet_personal [<global dotnet tool id> ...]
        #
        # Personal dotnet tooling for a devshell. Call from .envrc.local, after
        # `use flake` has put the devshell's `dotnet` on PATH.
        #   * Install-or-upgrades each listed tool via `dotnet tool update
        #     --global`, at most once every 24h per distinct tool list.
        #   * Puts the lazydotnet shim ahead of ~/.dotnet/tools on PATH (see
        #     modules/direnv.nix) and appends ~/.dotnet/tools itself, so
        #     Nix-provided binaries win over stale host-installed apphosts.
        use_dotnet_personal() {
          if ! has dotnet; then
            log_error "use_dotnet_personal: dotnet not on PATH (call it after 'use flake')"
            return 0
          fi

          PATH_add "${lazydotnetShim}/bin"
          export PATH="$PATH:$HOME/.dotnet/tools"

          [ "$#" -gt 0 ] || return 0

          local key marker now last tool
          key=$(printf '%s\n' "$@" | cksum | cut -d' ' -f1)
          marker="''${XDG_CACHE_HOME:-$HOME/.cache}/devshell/dotnet-personal-tools-$key"
          now=$(date +%s)
          last=0
          [ -f "$marker" ] && last=$(stat -c %Y "$marker" 2>/dev/null || echo 0)
          if [ $((now - last)) -gt 86400 ]; then
            log_status "personal: checking dotnet global tool updates"
            mkdir -p "$(dirname "$marker")"
            for tool in "$@"; do
              # A single failed update (offline, tool pulled) must not abort
              # the whole .envrc.
              # stdin closed + timeout: a stalled NuGet call must never wedge
              # direnv (and with it your prompt).
              timeout 60 dotnet tool update --global "$tool" </dev/null >/dev/null 2>&1 ||
                log_error "personal: failed to update dotnet tool $tool (skipping)"
            done
            touch "$marker"
          fi
        }
      '';
    };
  };
}
