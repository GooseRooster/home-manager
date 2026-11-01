{ config, lib, pkgs, ... }:

# appimage: a generic launcher for AppImages, sanitized for a Nix host.
#
# Why this exists
# ---------------
# AppImages are foreign artifacts: they bundle their own payload, but assume
# the host provides a *system* runtime for anything they dlopen() by soname
# (libGL.so.1, libEGL.so.1, libssl.so.1, …) and, some of them, an
# interpreter. A Nix install breaks both assumptions:
#
#   * Home Manager links the whole transitive closure of home.packages into
#     ~/.nix-profile, and ~/.nix-profile/bin precedes /usr/bin on PATH — so
#     `python3` resolves to a Nix CPython even when the user never asked for
#     one. (On this machine it arrives as a transitive dependency of
#     `gnomad`, pulled in by modules/theming-tools-silver-hour.nix.)
#   * Nix builds its own glibc. That loader does not read /etc/ld.so.cache
#     and its built-in system search path is the Nix glibc directory, so it
#     cannot see any distribution library at all.
#
# Jackify.AppImage hit exactly that: it bundles PySide6 6.7.3, uses the first
# `python3` on PATH, and died with
#
#     ImportError: libGL.so.1: cannot open shared object file
#
# …even though libGL.so.1 was installed. The distribution's python3 loads it
# fine; the Nix one cannot, because the Nix loader never consults the system
# library cache.
#
# The wrapper is a *host* concern, not an application concern: it fixes the
# environment the AppImage is launched into rather than patching any app's
# source. It also falls back to --appimage-extract-and-run when the FUSE
# mount fails, and has a --check mode that reports exactly which of these
# invariants is broken on the current host.
#
# Desktop targets only: the container and WSL flavors have neither FUSE nor
# a GUI stack to run AppImages against.
let
  cfg = config.home.modules;
in
{
  options.home.modules.appImages = {
    desktopEntries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Display name of the menu entry.";
          };

          exec = lib.mkOption {
            type = lib.types.str;
            description = ''
              Full command line for the menu entry. It must invoke the
              sanitizing wrapper, not the AppImage directly — e.g.

                  ${config.home.homeDirectory}/.local/bin/appimage "${config.home.homeDirectory}/Games/Foo.AppImage" %u

              The AppImage path has to be quoted: it routinely contains
              spaces. Use an absolute path for the wrapper too: a desktop
              entry is not started from a login shell, so $PATH is not
              guaranteed to include ~/.local/bin.
            '';
          };

          icon = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Icon name (looked up in the icon theme) or absolute path.";
          };

          comment = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Human-readable description shown in the menu.";
          };

          categories = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Menu categories (e.g. [ \"Game\" \"Utility\" ]).";
          };

          mimeType = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "MIME types this entry handles (e.g. [ \"x-scheme-handler/nxm\" ]).";
          };
        };
      });
      default = { };
      description = ''
        Desktop entries for AppImage-based applications, launched through
        the sanitizing wrapper. The attribute name becomes the .desktop
        filename, so use the reverse-DNS application id (e.g.
        "com.example.foo") rather than a display name.
      '';
    };
  };

  config = lib.mkIf cfg.appImages.enable {
    home.sessionPath = [ "$HOME/.local/bin" ];

    home.file.".local/bin/appimage" = {
      source = ../files/scripts/appimage;
      executable = true;
      force = true;
    };

    # Drop the unset (null) options so the generated .desktop file simply
    # omits those keys instead of writing empty ones.
    xdg.desktopEntries = lib.mapAttrs (
      _name: entry: lib.filterAttrs (_key: value: value != null) entry
    ) cfg.appImages.desktopEntries;
  };
}
