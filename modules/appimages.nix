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

        The entries are installed into ~/.local/share/applications — i.e.
        XDG_DATA_HOME — rather than the profile's share/applications, for two
        reasons:

          * XDG_DATA_HOME is searched BEFORE the XDG_DATA_DIRS, so an entry
            there takes precedence over one in the profile. Applications that
            register themselves write exactly there (Jackify does, on every
            launch), so this is where such an entry can shadow ours.
          * Owning the path also makes the entry authoritative. Home Manager
            links it into the read-only store, so an application's own
            attempt to rewrite it fails with EACCES — it catches that and
            logs a warning — instead of silently replacing it with an Exec
            line that bypasses the sanitizing wrapper.

        Note that mimeType only declares what the entry can handle; making a
        type the *default* handler is done separately with xdg.mimeApps.
      '';
    };
  };

  config = lib.mkIf cfg.appImages.enable {
    home.sessionPath = [ "$HOME/.local/bin" ];

    home.file = {
      ".local/bin/appimage" = {
        source = ../files/scripts/appimage;
        executable = true;
        force = true;
      };
    } // lib.mapAttrs' (
      id: entry:
      lib.nameValuePair ".local/share/applications/${id}.desktop" {
        # makeDesktopItem renders the entry with nixpkgs' own desktop-entry
        # writer and validates it with desktop-file-validate at build time.
        source = "${pkgs.makeDesktopItem {
          name = id;
          desktopName = entry.name;
          exec = entry.exec;
          icon = entry.icon;
          comment = entry.comment;
          terminal = false;
          categories = entry.categories;
          mimeTypes = entry.mimeType;
        }}/share/applications/${id}.desktop";
        force = true;
      }
    ) cfg.appImages.desktopEntries;
  };
}
