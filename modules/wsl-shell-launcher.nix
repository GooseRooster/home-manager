{ config, lib, ... }:

# WSL only: the distro (Ubuntu/Debian/…) owns ~/.bashrc, so we can't use
# programs.bash.initExtra without HM taking over the whole file. Append an
# idempotent block that hands off from bash to the default interactive shell
# (home.modules.defaultShell — nu or zsh, see modules/flavors.nix) — but via
# PROMPT_COMMAND, not a top-level spawn.
#
# Why the deferral matters: `nix develop` sources ~/.bashrc BEFORE it
# activates the derivation env (PATH, IN_NIX_SHELL, shellHook). A naive
# `exec <shell>` at the top of bashrc therefore spawns the target shell with
# a pre-nix PATH — none of the devShell tools resolve, and `$IN_NIX_SHELL` is
# missing. The same bug bites direnv, ssh-agent handoff, and anything else
# that mutates the env after ~/.bashrc but before the first prompt.
#
# PROMPT_COMMAND fires just before bash draws its first prompt, by which
# point the full nix env + shellHook are applied, so the exec'd shell
# inherits everything. `exec` (not a plain spawn) means exiting the shell
# returns to whatever spawned bash — no orphan bash prompt in between.
let
  cfg = config.home.modules;

  # The default shell's launcher command. Currently both flavors are plain
  # PATH lookups (nu/zsh are both in the HM profile); if one ever needs
  # flags, expand this into a per-shell string here.
  launcher = if cfg.defaultShell == "zsh" then "exec zsh" else "exec nu";
in
{
  home.activation.wslShellLauncher = lib.mkIf cfg.wsl.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run() {
        local bashrc="$HOME/.bashrc"
        [ -e "$bashrc" ] || return 0
        # Strip any previously materialized block — the generic marker AND
        # the legacy "nu launcher" markers from before the launcher went
        # shell-generic — so a defaultShell switch replaces the block in
        # place instead of stacking a second one.
        sed -i \
          -e '/^# >>> home-manager: shell launcher >>>$/,/^# <<< home-manager: shell launcher <<<$/d' \
          -e '/^# >>> home-manager: nu launcher >>>$/,/^# <<< home-manager: nu launcher <<<$/d' \
          "$bashrc"
        cat >>"$bashrc" <<'EOF'

# >>> home-manager: shell launcher >>>
# Managed by modules/wsl-shell-launcher.nix (wslShellLauncher). Do not edit
# inline — change the source module and re-run `home-manager switch`; the
# block is stripped and re-appended on every apply. Delete the whole block
# (markers and all) to force a clean re-materialization.
#
# Defer the hand-off to PROMPT_COMMAND so that `nix develop`, direnv, and any
# other rc-time env setup — which runs AFTER ~/.bashrc but BEFORE the first
# prompt — is fully applied when the target shell spawns. A plain exec at the
# top of bashrc snapshots a stale PATH and can't see devShell tools.
if [[ $- == *i* ]]; then
  PROMPT_COMMAND='${launcher}'
fi
# <<< home-manager: shell launcher <<<
EOF
      }
      run
    ''
  );
}
