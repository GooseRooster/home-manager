{ config, lib, pkgs, ... }:

# mimeapps.list: the default-application registry.
#
# Why this is not xdg.mimeApps
# ---------------------------
# Home Manager's xdg.mimeApps links ~/.config/mimeapps.list into the
# read-only Nix store. GIO — which is what gnome-control-center's
# "Default Applications" panel calls — writes that file by creating a
# temporary file next to it and renaming that into place. Because the
# link resolves into the store, the temporary file is created *inside the
# store*, and the write fails:
#
#   GLib.FileError: Failed to create file
#   "/nix/store/…-home-manager-files/.config/mimeapps.list.XXXXXX":
#   Permission denied
#
# So the panel cannot set a new default app at all, and xdg-mime(1)
# fails the same way. (The same is true for
# ~/.local/share/applications/mimeapps.list, which xdg.mime writes too;
# only the config-dir copy is seeded here, since it is the one GIO reads
# first.)
#
# What this module does instead
# -----------------------------
# The file becomes runtime state, like ~/.config/gnomad/config.toml:
# this module seeds it once with the declared defaults and then leaves
# it alone, so GNOME owns it from then on and the Default Applications
# panel can rewrite it.
#
# The seeding is deliberately one-shot. Re-seeding on every switch would
# undo whatever the user picked in the panel, which is the thing this
# module exists to stop. To go back to the declared defaults, delete
# ~/.config/mimeapps.list and switch again.
let
  cfg = config.home.modules.mimeApps;

  # builtins.attrNames is lexicographically sorted, so the seeded file
  # does not churn between rebuilds.
  addedNames = lib.attrNames cfg.addedAssociations;
  defaultNames = lib.attrNames cfg.defaultApplications;

  content = ''
    [Added Associations]
    ${lib.concatMapStringsSep "\n" (mime: "${mime}=${lib.concatStringsSep ";" cfg.addedAssociations.${mime}}") addedNames}

    [Default Applications]
    ${lib.concatMapStringsSep "\n" (mime: "${mime}=${cfg.defaultApplications.${mime}}") defaultNames}

    [Removed Associations]
  '';
in
{
  options.home.modules.mimeApps = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Seed ~/.config/mimeapps.list with the declared default
        applications. Desktop hosts only.
      '';
    };

    defaultApplications = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        MIME type -> desktop file id, written to the [Default Applications]
        section. This is what "open this with…" and the Default
        Applications panel resolve to.

        Several modules may contribute to this option, so each of them
        has to use lib.mkMerge.
      '';
    };

    addedAssociations = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = ''
        MIME type -> list of desktop file ids, written to the [Added
        Associations] section. These are the handlers an application
        offers for a type, regardless of which one is the default.

        Several modules may contribute to this option, so each of them
        has to use lib.mkMerge.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.installMimeApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mimeapps="$HOME/.config/mimeapps.list"

      # Only seed when there is nothing to preserve. A regular file is
      # the user's (GNOME's) copy and is left alone; a symlink into the
      # store is a leftover from an earlier generation, which the
      # activation's cleanup step usually removes before this runs.
      seed() {
        mkdir -p "$(dirname "$mimeapps")"
        # A plain file, writable by the user: the store copy cannot be
        # written to, and copying onto a leftover symlink into the store
        # would fail with "same file".
        rm -f "$mimeapps"
        install -m 644 ${pkgs.writeText "mimeapps.list" content} "$mimeapps"
      }

      if [ ! -e "$mimeapps" ] ; then
        seed
      elif [ -L "$mimeapps" ] && [[ "$(readlink "$mimeapps")" == *-home-manager-files/* ]] ; then
        seed
      fi
    '';
  };
}
