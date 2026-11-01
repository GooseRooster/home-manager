{ config, lib, pkgs, ... }:

# jackify: the Wabbajack modlist manager, installed from its GitHub release
# as an AppImage.
#
# Why an AppImage at all
# ----------------------
# Jackify has no Nix expression upstream — the repo is a plain Python project
# (pyproject.toml, requirements.txt, jackify/) whose only distributable is a
# prebuilt AppImage attached to each GitHub release. There is nothing to
# callPackage, so the release asset is fetched directly.
#
# Two things make that more than a plain download:
#
#   * The AppImage has to be launched through the sanitizing wrapper
#     (modules/appimages.nix). Its AppRun runs the bundled PySide6 under the
#     FIRST python3 on PATH, which on this machine is the Nix CPython from
#     ~/.nix-profile — and the Nix loader cannot see distribution libraries,
#     so the GUI dies with "ImportError: libGL.so.1: cannot open shared
#     object file" even though libGL.so.1 is installed.
#   * The AppImage is 269 MB. Fetching it into the Nix store (rather than
#     leaving a loose copy in $HOME) makes it content-addressed, verifiable
#     against the checksum upstream published with the release, and
#     garbage-collected like everything else.
#
# Version resolution
# ------------------
# "Latest release" is resolved at eval time from the GitHub API, so the
# config always tracks upstream. That makes evaluation impure — but this
# flake is applied with --impure regardless, because hosts/*.nix read
# $USER/$HOME at eval time.
#
# The AppImage itself is fetched with the sha256 that upstream published in
# the release's SHA256SUMS file, so the download is content-verified even
# though the version is not pinned here. Note what that does and does not
# buy: it protects against a corrupted or truncated download, but a
# compromised release would still be trusted, because the metadata and the
# checksum come from the same place. For a hard pin, replace the eval-time
# lookup below with a literal version and hash.
let
  cfg = config.home.modules;

  repo = "Omni-guides/Jackify";
  assetName = "Jackify.AppImage";

  release = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://api.github.com/repos/${repo}/releases/latest";
  }));

  # A GitHub rate-limit or outage reply is still valid JSON, but not a
  # release object — fail with something readable rather than a bare
  # "attribute 'assets' missing".
  assets =
    if release ? assets then release.assets
    else throw "Jackify: could not read the release list from ${repo} (GitHub API replied: ${builtins.toJSON release})";

  assetList = builtins.filter (a: a.name == assetName) assets;
  asset =
    if assetList == [ ] then
      throw "Jackify: release ${if release ? tag_name then release.tag_name else "?"} has no ${assetName} asset"
    else builtins.head assetList;

  # Upstream publishes SHA256SUMS next to the asset. Pick our asset's line
  # ("<sha256>  Jackify.AppImage") and take the hash out of it. sha256sum
  # separates the hash from the name with two spaces (or a tab, or " *" in
  # binary mode), so split on whitespace generally.
  sums = builtins.readFile (builtins.fetchurl {
    url = "https://github.com/${repo}/releases/download/${release.tag_name}/SHA256SUMS";
  });
  sumLines = builtins.filter (l: lib.hasSuffix " ${assetName}" l) (lib.splitString "\n" sums);
  sumLine =
    if sumLines == [ ] then
      throw "Jackify: no ${assetName} entry in the release's SHA256SUMS"
    else builtins.head sumLines;
  sumFields = lib.filter (f: f != "") (lib.splitString " " (lib.replaceStrings [ "\t" ] [ " " ] sumLine));
  sha256 =
    if sumFields == [ ] then throw "Jackify: could not parse a hash from SHA256SUMS line: ${sumLine}"
    else builtins.head sumFields;

  # The download, verified against the sha256 upstream published in the
  # release's SHA256SUMS file.
  #
  # It is deliberately left non-executable. fetchurl's `executable` option
  # flips outputHashMode to "recursive", which would make Nix expect the
  # hash of the output *tree* rather than the flat file hash upstream
  # published — and the recursive hash cannot be derived from the published
  # one. (derivationArgs cannot override it either: fetchurl merges
  # `derivationArgs // { … }`, so its own value always wins.)
  src = pkgs.fetchurl {
    url = asset.browser_download_url;
    inherit sha256;
  };

  # The runnable copy, as a separate normal derivation.
  #
  # It could not simply be `executable = true` on the fetch above: the
  # execute bit of a *flat* fixed-output derivation is not part of its store
  # path identity (the path is keyed on the content hash alone), so a chmod
  # applied there is not reproducible — and would not even re-run if the
  # path already existed from an earlier build. As a normal derivation the
  # mode is part of the NAR hash, so this output is deterministic and can be
  # symlinked into place by Home Manager.
  appimage = pkgs.runCommand assetName { } ''
    cp ${src} $out
    chmod 0755 $out
  '';

  appimagePath = "${config.home.homeDirectory}/${cfg.jackify.installDir}/${assetName}";
in
{
  options.home.modules.jackify = {
    installDir = lib.mkOption {
      type = lib.types.str;
      default = "Modding/General Tools/Jackify";
      description = ''
        Directory the AppImage is installed into, relative to $HOME. The
        parent directories are created on activation.
      '';
    };
  };

  config = lib.mkIf cfg.jackify.enable {
    # Jackify has to be launched through the sanitizing wrapper, so the
    # generic launcher is a hard requirement here, not a convenience.
    home.modules.appImages.enable = true;

    # No `executable` option: it defaults to null ("inherit"), which makes
    # Home Manager symlink the store path into place instead of copying it.
    # The source is already executable, so the symlink is runnable and the
    # 269 MB payload is not duplicated into the generic home-files tree (which
    # is rebuilt whenever any other home.file entry changes).
    home.file."${cfg.jackify.installDir}/${assetName}" = {
      source = appimage;
    };

    home.modules.appImages.desktopEntries."com.jackify.app" = {
      name = "Jackify";
      # lib.removeSuffix: a Nix indented string always ends in a newline, and
      # makeDesktopItem writes the value verbatim — the stray newline would
      # leave a blank line in the generated .desktop file.
      exec = lib.removeSuffix "\n" ''
        "${config.home.homeDirectory}/.local/bin/appimage" "${appimagePath}" %u
      '';
      icon = "com.jackify.app";
      comment = "Wabbajack modlist manager for Linux";
      categories = [ "Game" "Utility" ];
      mimeType = [ "x-scheme-handler/jackify" "x-scheme-handler/nxm" ];
    };

    # Make Jackify the default handler for the URL schemes it owns:
    #   x-scheme-handler/nxm    — "Download from Nexus Mods" links on the web
    #   x-scheme-handler/jackify — the app's own OAuth callback scheme
    #
    # Declaring these here rather than letting Jackify self-register matters.
    # The app registers itself by writing ~/.local/share/applications/
    # com.jackify.app.desktop and ~/.config/mimeapps.list at startup — but
    # both paths are Home Manager's, so its own attempts fail with
    # "Permission denied" (visible in Jackify's log as a warning from
    # nexus_oauth_protocol). Worse, the desktop file it writes points Exec
    # straight at $APPIMAGE, bypassing the sanitizing wrapper, so it would
    # break the launcher: see modules/appimages.nix for the details.
    #
    # The entry itself is owned by the appimages module, which installs it
    # into ~/.local/share/applications — the same path the app tries to
    # write. Home Manager links it into the read-only store, so the app's
    # write attempt fails harmlessly and our Exec line survives.
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/nxm" = "com.jackify.app.desktop";
        "x-scheme-handler/jackify" = "com.jackify.app.desktop";
      };
      associations.added = {
        "x-scheme-handler/nxm" = [ "com.jackify.app.desktop" ];
        "x-scheme-handler/jackify" = [ "com.jackify.app.desktop" ];
      };
    };
  };
}
