{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  # One-time, idempotent bootstrap of the mutable/network-dependent state that
  # used to live in `home.activation` steps (LazyVim clone, `tinty sync`,
  # television channels). Activation ran at boot before networking was up, so
  # those steps failed with DNS errors — and the LazyVim clone never retried
  # because its `[ ! -e "$dir" ]` guard was defeated by the overlay creating the
  # directory anyway. A manual `bootstrap` command is clearer: run it once per
  # machine (or whenever a step fails offline). Each step is idempotent and
  # safe to re-run.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "bootstrap";
      # tinty is only used outside the noctalia session (Noctalia templates own
      # app theming there) — see modules/misc-config.nix.
      runtimeInputs = [ pkgs.git pkgs.television ]
        ++ lib.optionals (cfg.theming.enable && cfg.session != "noctalia") [ pkgs.tinty ];
      text = ''
        # Neovim: clone LazyVim starter (keyed on init.lua, not the directory, so
        # a partial/offline failure is retried on the next run), then overlay our
        # lua/ config on top. Overlay is store-path sourced, so it needs no git.
        echo "==> nvim: LazyVim starter + lua overlay"
        if [ -f "$HOME/.config/nvim/init.lua" ]; then
          echo "    LazyVim already present, skipping clone."
        else
          rm -rf "$HOME/.config/nvim"
          mkdir -p "$HOME/.config"
          if git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"; then
            rm -rf "$HOME/.config/nvim/.git"
            echo "    cloned LazyVim starter."
          else
            echo "ERROR: 'git clone LazyVim/starter' failed (offline?)." >&2
            exit 1
          fi
        fi
        mkdir -p "$HOME/.config/nvim/lua"
        # cp preserves the read-only store mode (444), which would make the next
        # run fail on overwrite; make the tree owner-writable first.
        chmod -R u+w "$HOME/.config/nvim/lua"
        cp -rf ${../files/nvim/lua}/. "$HOME/.config/nvim/lua/"

      '' + lib.optionalString (cfg.theming.enable && cfg.session != "noctalia") ''
        # tinty: pre-create hook output dirs, then fetch theme repos once.
        echo "==> tinty: theme repos + hook dirs"
        mkdir -p "$HOME/.config/ghostty/themes" "$HOME/.claude/themes"
        ${lib.optionalString cfg.gaming.enable ''mkdir -p "$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings"''}
        if [ -d "$HOME/.local/share/tinted-theming/tinty" ]; then
          echo "    tinty data dir already present, skipping sync."
        else
          if tinty sync; then
            echo "    tinty synced."
          else
            echo "ERROR: 'tinty sync' failed (offline?)." >&2
            exit 1
          fi
        fi
      '' + ''
        # television: fetch the community channel prototypes.
        echo "==> television: community channels"
        if tv update-channels; then
          echo "    channels updated."
        else
          echo "ERROR: 'tv update-channels' failed (offline?)." >&2
          exit 1
        fi
        echo "bootstrap complete."
      '';
    })
  ];
}
