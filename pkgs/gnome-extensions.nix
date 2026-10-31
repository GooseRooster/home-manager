# User-level GNOME Shell extensions (the ones installed under
# ~/.local/share/gnome-shell/extensions), pinned to extensions.gnome.org
# builds for the silver-hour image's GNOME version.
#
# Each entry is a published EGO build:
#
#   id         extension uuid — also the directory name GNOME expects
#   name       human-readable name (informational)
#   schema     dconf path of the extension's GSettings schema, i.e. the
#              "org/gnome/shell/extensions/<x>" block the settings below
#              are written to. Verified against the build's gschema.xml.
#   version    version as reported by the build's metadata.json
#   versionTag EGO's internal version id (the `version_tag` query parameter
#              of the download URL). Shell-version specific: EGO publishes
#              one build per supported GNOME version.
#   sha256     flat SHA-256 of the downloaded zip (SRI).
#
# Bump with:  python3 scripts/update-gnome-extensions.py
# (rewrites version / versionTag / sha256 in place and reports schema
#  drift; the settings in modules/gnome-extensions.nix are never touched).
{ pkgs }:

let
  # Unpack an EGO build into a proper GNOME extension package:
  # $out/share/gnome-shell/extensions/<id> — the layout GNOME (and HM's
  # programs.gnome-shell.extensions) expects.
  #
  # The zips only ship the *.gschema.xml; GNOME needs a compiled
  # gschemas.compiled next to it (ExtensionBase.getSettings() builds a
  # Gio.SettingsSchemaSource from <extension>/schemas), so compile it here
  # rather than relying on the post-install step of gnome-extensions.
  fetchExtension =
    {
      id,
      versionTag,
      sha256,
      ...
    }:
    pkgs.runCommand "gnome-extension-${id}"
      {
        nativeBuildInputs = [
          pkgs.glib
          pkgs.unzip
        ];
      } ''
      ext="$out/share/gnome-shell/extensions/${id}"
      mkdir -p "$ext"
      unzip -q ${pkgs.fetchurl {
        url = "https://extensions.gnome.org/download-extension/${id}.shell-extension.zip?version_tag=${toString versionTag}";
        inherit sha256;
      }} -d "$ext"
      # Extensions without a GSettings schema have no schemas/ directory.
      if [ -d "$ext/schemas" ]; then
        glib-compile-schemas "$ext/schemas"
      fi
    '';
in
builtins.map (ext: ext // { package = fetchExtension ext; }) [
  {
    id = "Vitals@CoreCoding.com";
    name = "Vitals";
    schema = "org/gnome/shell/extensions/vitals";
    version = "86";
    versionTag = 76696;
    sha256 = "sha256-DH35XXrSq1Cdm9iSYi6N9QH59xnMB5ryiynJNtHYuXo=";
  }
  {
    id = "nowplaying@epogonii.github.io";
    name = "Now Playing Card";
    schema = "org/gnome/shell/extensions/nowplaying";
    version = "16";
    versionTag = 77462;
    sha256 = "sha256-2GPIMh3bT1M9z1/40H40Px3WyWCa3wCd5qbYqIltAIQ=";
  }
  {
    id = "quake-terminal@diegodario88.github.io";
    name = "Quake Terminal";
    schema = "org/gnome/shell/extensions/quake-terminal";
    version = "43";
    versionTag = 77206;
    sha256 = "sha256-u9fUaREa7YEZ+eFbInFzc3p6gVb8Wri5L+EHxJPt9aE=";
  }
  {
    id = "user-accent-colors@fabito02";
    name = "ChromaLeon";
    schema = "org/gnome/shell/extensions/chromaleon";
    version = "89";
    versionTag = 76023;
    sha256 = "sha256-bfWA3SecOZ8VJJ3baTEpf3FezosD3ZjqiTUFlMMxL40=";
  }
  {
    id = "weatherornot@somepaulo.github.io";
    name = "Weather or Not";
    schema = "org/gnome/shell/extensions/weatherornot";
    version = "24";
    versionTag = 75315;
    sha256 = "sha256-ufvvDC4UOOu5aIMPu7D8mMviqZ6GN/telL4UkpmSJwM=";
  }
  {
    id = "lock-guard@fthx";
    name = "Lock Guard";
    schema = "org/gnome/shell/extensions/lock-guard";
    version = "8";
    versionTag = 76888;
    sha256 = "sha256-NYXbMMSZEVrMIPYliFcJjRGvxgVoo1ImIrYni5bBrIM=";
  }
  {
    id = "grand-theft-focus@zalckos.github.com";
    name = "Grand Theft Focus";
    schema = "org/gnome/shell/extensions/grand-theft-focus";
    version = "12";
    versionTag = 76068;
    sha256 = "sha256-i46nPmzGmVKGKIXZ5Y+GRzkyoxCK6fAi5UoCZakLwcc=";
  }
]
