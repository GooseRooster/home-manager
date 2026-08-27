{ config, lib, pkgs, ... }:

{
  # devshell-init: scaffolder that drops a Nix devShell template into another
  # repo you're working on. Templates live in ../files/devshell-templates/;
  # this module also materializes them into ~/.local/share/devshell-templates/
  # so the script has a stable, XDG-ish lookup path (overridable via
  # $DEVSHELL_TEMPLATES_DIR).
  #
  # No host gate: both remaining flavors (desktop, wsl) want this.
  home.file = {
    ".local/bin/devshell-init" = {
      source = ../files/scripts/devshell-init;
      executable = true;
      force = true;
    };

    ".local/share/devshell-templates" = {
      source = ../files/devshell-templates;
      recursive = true;
    };
  };
}
