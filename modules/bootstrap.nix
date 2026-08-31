{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
  # tinty theming is a gnome-session-only concern: in the noctalia session
  # Noctalia's builtin templates own app theming (see modules/misc-config.nix),
  # and non-desktop hosts never set theming. Expressed as a positive gnome
  # gate so a future third session doesn't inherit tinty by accident.
  tintyEnabled = cfg.theming.enable && cfg.session == "gnome";
in
{
  # One-time, idempotent bootstrap of the mutable/network-dependent state that
  # can't live in the Nix store: `tinty sync` fetches theme repos into
  # ~/.local/share/tinted-theming. (The LazyVim starter and television
  # channels used to live here too, but both are declarative now — see
  # modules/nvim.nix and modules/television.nix.) Activation previously ran
  # at boot before networking was up, so home.activation steps failed with
  # DNS errors; a manual command is clearer. Run it once per machine (or
  # whenever it fails offline). Idempotent, safe to re-run.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "bootstrap-tinty";
      runtimeInputs = lib.optionals tintyEnabled [ pkgs.tinty ];
      text = '' '' + lib.optionalString tintyEnabled ''
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
        echo "bootstrap-tinty complete."
      '';
    })
  ];
}
