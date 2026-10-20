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
    version = "14";
    versionTag = 76593;
    sha256 = "sha256-S5uEck7P+qpCU/+zjoGXNr5znTAQCvCFew90vur+KPg=";
  }
  {
    id = "quake-terminal@diegodario88.github.io";
    name = "Quake Terminal";
    schema = "org/gnome/shell/extensions/quake-terminal";
    version = "41";
    versionTag = 76704;
    sha256 = "sha256-b7XmSL8J4WnalE5o33e2AWI02SQbUnoT0p4Nl7aqbpY=";
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
    version = "7";
    versionTag = 69117;
    sha256 = "sha256-6FF8x8nU7YqAYkSF/Lp52KtFhJm0rJN09WyBhw/YR7g=";
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
