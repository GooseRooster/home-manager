#!/usr/bin/env python3
"""Bump the pinned GNOME Shell extension builds in pkgs/gnome-extensions.nix.

The extensions live in ~/.local/share/gnome-shell/extensions, so they belong
to the user, not the image — but they are shipped as pinned, hash-checked
builds from extensions.gnome.org, and those pins have to be refreshed by
hand whenever upstream publishes a new version.

This script automates that refresh:

  * asks extensions.gnome.org which builds exist for the target GNOME
    version (default: the running shell's major version),
  * compares them against the pins in pkgs/gnome-extensions.nix,
  * downloads the new build and diffs it against the pinned one — metadata
    (shell support, session modes) and GSettings schema (added/removed
    keys, changed types),
  * flags anything that would break the settings declared in
    modules/gnome-extensions.nix (a managed key that disappeared or changed
    type, a schema that moved, a build that dropped the target GNOME),
  * rewrites version / versionTag / sha256 in place.

The *values* of the managed settings are never touched: they are opinions,
not pins. The script only tells you when upstream made them invalid.

Usage:
    python3 scripts/update-gnome-extensions.py            # update the pins
    python3 scripts/update-gnome-extensions.py --check    # report only
    python3 scripts/update-gnome-extensions.py --shell 51 # target GNOME 51
"""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PINS_FILE = REPO / "pkgs" / "gnome-extensions.nix"
SETTINGS_FILE = REPO / "modules" / "gnome-extensions.nix"

EGO = "https://extensions.gnome.org"
UA = "Mozilla/5.0 (X11; Linux x86_64) home-manager-extension-updater"

# gsettings schema types that a managed value can have. The schema side may
# also be an enum, which is 'i' for integer enums and 's' for string enums.
NIX_TYPE = {
    bool: "b",
    int: "i",
    str: "s",
}


def log(msg: str) -> None:
    print(msg)


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def fetch_text(url: str) -> str:
    return fetch(url).decode("utf-8", "replace")


def version_key(version: str) -> tuple:
    """Order EGO version strings ('86', '1.0.11', '2.4.2') numerically."""
    parts = re.split(r"[._-]", str(version))
    return tuple((0, int(p)) if p.isdigit() else (1, 0) for p in parts)


def sha256_sri(data: bytes) -> str:
    import base64
    import hashlib

    digest = hashlib.sha256(data).hexdigest()
    return "sha256-" + base64.b64encode(bytes.fromhex(digest)).decode()


# --------------------------------------------------------------------------
# pins


class Extension:
    def __init__(self, uuid: str, name: str, schema: str, version: str,
                 version_tag: int, sha256: str):
        self.uuid = uuid
        self.name = name
        self.schema = schema
        self.version = version
        self.version_tag = version_tag
        self.sha256 = sha256

    def __str__(self) -> str:
        return f"{self.name} ({self.uuid})"


def parse_pins(text: str) -> list[Extension]:
    entries = []
    pattern = re.compile(
        r'id = "(?P<uuid>[^"]+)";'
        r'(?:.|\n)*?name = "(?P<name>[^"]*)";'
        r'(?:.|\n)*?schema = "(?P<schema>[^"]*)";'
        r'(?:.|\n)*?version = "(?P<version>[^"]*)";'
        r'(?:.|\n)*?versionTag = (?P<version_tag>\d+);'
        r'(?:.|\n)*?sha256 = "(?P<sha256>[^"]*)";'
    )
    for match in pattern.finditer(text):
        groups = match.groupdict()
        groups["version_tag"] = int(groups["version_tag"])
        entries.append(Extension(**groups))
    if not entries:
        raise SystemExit(f"error: no extension pins found in {PINS_FILE}")
    return entries


def rewrite_pins(text: str, updates: dict[str, dict]) -> str:
    """Replace version / versionTag / sha256 of the given extensions."""
    result = text
    for uuid, values in updates.items():
        # Isolate the block of this extension, then patch the three fields.
        start = result.find(f'id = "{uuid}";')
        if start < 0:
            raise SystemExit(f"error: pin for {uuid} vanished while rewriting")
        next_start = result.find('id = "', start + 1)
        end = len(result) if next_start < 0 else next_start
        block = result[start:end]

        block = re.sub(r'(version = )"[^"]*"(;)',
                       lambda m: f'{m.group(1)}"{values["version"]}"{m.group(2)}',
                       block, count=1)
        block = re.sub(r'(versionTag = )\d+(;)',
                       lambda m: f'{m.group(1)}{values["versionTag"]}{m.group(2)}',
                       block, count=1)
        block = re.sub(r'(sha256 = )"[^"]*"(;)',
                       lambda m: f'{m.group(1)}"{values["sha256"]}"{m.group(2)}',
                       block, count=1)

        result = result[:start] + block + result[end:]
    return result


# --------------------------------------------------------------------------
# extensions.gnome.org


def ego_versions(uuid: str) -> dict:
    """The per-shell-version build table of an extension.

    The v1 API exposes the extension record but not the internal version
    ids the download URL needs; those live in the page's data-versions
    attribute, which is what the site's own frontend reads.
    """
    quoted = urllib.parse.quote(uuid, safe="")
    record = json.loads(fetch_text(f"{EGO}/api/v1/extensions/{quoted}/"))
    page = fetch_text(f"{EGO}{record['link']}")

    match = re.search(r'data-versions="([^"]*)"', page)
    if not match:
        raise RuntimeError(f"could not find the version table of {uuid}")
    return json.loads(html.unescape(match.group(1)))


def builds_for_shell(versions: dict, shell: str) -> dict:
    """{version_tag: version} of the builds published for `shell`."""
    return {
        int(entry["pk"]): entry["version"]
        for entry in versions.get(shell, {}).values()
    }


def download_build(uuid: str, version_tag: int) -> bytes:
    quoted = urllib.parse.quote(uuid, safe="")
    url = f"{EGO}/download-extension/{quoted}.shell-extension.zip?version_tag={version_tag}"
    return fetch(url)


# --------------------------------------------------------------------------
# build contents


def read_metadata(data: bytes) -> dict:
    with zipfile.ZipFile(__import__("io").BytesIO(data)) as archive:
        return json.loads(archive.read("metadata.json"))


def read_schema(data: bytes) -> tuple[str | None, dict[str, str]]:
    """The schema path and {key: type} of a build's GSettings schema."""
    with zipfile.ZipFile(__import__("io").BytesIO(data)) as archive:
        names = [n for n in archive.namelist() if n.endswith(".gschema.xml")]
        if not names:
            return None, {}
        xml = archive.read(names[0]).decode("utf-8", "replace")

    path = None
    schema_match = re.search(r'<schema [^>]*path="([^"]*)"', xml)
    if schema_match:
        path = schema_match.group(1).strip("/")

    keys: dict[str, str] = {}
    for key in re.finditer(r'<key\b([^>]*)>', xml):
        attrs = dict(re.findall(r'(\w[\w-]*)="([^"]*)"', key.group(1)))
        name = attrs.get("name")
        if not name:
            continue
        if "type" in attrs:
            keys[name] = attrs["type"]
        elif "enum" in attrs:
            # An enum key is a string of nicks ("left", "center", ...); the
            # numeric values in the schema are just indices.
            keys[name] = "s"
    return path, keys


# --------------------------------------------------------------------------
# the settings we manage


def parse_managed_settings(text: str) -> dict[str, dict[str, str]]:
    """{schema path: {key: gvariant type}} from modules/gnome-extensions.nix."""
    managed: dict[str, dict[str, str]] = {}
    pattern = re.compile(
        r'"(org/gnome/shell/extensions/[^"]+)"\s*=\s*\{(.*?)\n\s*\};',
        re.S,
    )
    for match in pattern.finditer(text):
        schema = match.group(1)
        keys: dict[str, str] = {}
        for key in re.finditer(r'^\s*([\w-]+)\s*=\s*((?:.|\n)*?);', match.group(2), re.M):
            name, value = key.group(1), key.group(2).strip()
            if value.startswith("["):
                keys[name] = "as"
            elif value in ("true", "false"):
                keys[name] = "b"
            elif value.startswith('"'):
                keys[name] = "s"
            elif re.fullmatch(r"-?\d+", value):
                keys[name] = "i"
        managed[schema] = keys
    return managed


# --------------------------------------------------------------------------
# main


def target_shell_version(explicit: str | None) -> str:
    if explicit:
        return explicit
    try:
        out = subprocess.run(["gnome-shell", "--version"], capture_output=True,
                             text=True, timeout=30).stdout
    except (OSError, subprocess.SubprocessError):
        out = ""
    match = re.search(r"(\d+)\.", out)
    if not match:
        raise SystemExit("error: could not detect the GNOME version; pass --shell")
    return match.group(1)


def relative(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true",
                        help="only report; do not rewrite the pins")
    parser.add_argument("--dry-run", action="store_true",
                        help="report the changes without writing them")
    parser.add_argument("--shell", help="target GNOME major version "
                                         "(default: the running shell's)")
    parser.add_argument("--file", default=str(PINS_FILE),
                        help="pin file to read/write")
    args = parser.parse_args()

    pins_path = Path(args.file)
    pins_text = pins_path.read_text()
    extensions = parse_pins(pins_text)
    managed = parse_managed_settings(SETTINGS_FILE.read_text())
    shell = target_shell_version(args.shell)

    log(f"GNOME target: {shell}   extensions: {len(extensions)}")
    log("")

    updates: dict[str, dict] = {}
    blocking: list[str] = []
    notes: list[str] = []

    for ext in extensions:
        try:
            versions = ego_versions(ext.uuid)
        except (urllib.error.URLError, RuntimeError, json.JSONDecodeError) as error:
            notes.append(f"{ext}: could not query extensions.gnome.org ({error})")
            continue

        shell_builds = builds_for_shell(versions, shell)
        if not shell_builds:
            notes.append(f"{ext}: no build published for GNOME {shell} — "
                         "left untouched")
            continue

        best_tag = max(shell_builds, key=lambda tag: version_key(shell_builds[tag]))
        best_version = shell_builds[best_tag]

        if best_tag == ext.version_tag:
            log(f"- {ext.name} (`{ext.uuid}`): up to date (v{ext.version})")
            continue

        # Newer upstream release than the one published for our shell?
        every_build = {int(e["pk"]): e["version"]
                       for shell_v in versions.values() for e in shell_v.values()}
        newest = max(every_build, key=lambda tag: version_key(every_build[tag]))
        if newest != best_tag:
            notes.append(
                f"{ext.name}: upstream's newest release (v{every_build[newest]}) has "
                f"no GNOME {shell} build — staying on v{best_version}")

        try:
            new_data = download_build(ext.uuid, best_tag)
            old_data = download_build(ext.uuid, ext.version_tag)
        except (urllib.error.URLError, OSError) as error:
            notes.append(f"{ext}: download failed ({error})")
            continue

        new_meta = read_metadata(new_data)
        old_meta = read_metadata(old_data)
        new_path, new_keys = read_schema(new_data)
        _, old_keys = read_schema(old_data)

        # The pin must match the bytes it points at.
        if sha256_sri(old_data) != ext.sha256:
            notes.append(f"{ext.name}: pinned sha256 does not match the published "
                         f"build v{ext.version} (upstream re-uploaded it?)")

        # Shell support of the build we are about to pin.
        if shell not in new_meta.get("shell-version", []):
            blocking.append(f"{ext.name}: v{new_meta.get('version')} does not list "
                            f"GNOME {shell} in its shell-version")

        # Schema drift.
        removed = sorted(set(old_keys) - set(new_keys))
        added = sorted(set(new_keys) - set(old_keys))
        retyped = sorted(k for k in set(old_keys) & set(new_keys)
                         if old_keys[k] != new_keys[k])

        for key in removed:
            if key in managed.get(ext.schema, {}):
                blocking.append(f"{ext.name}: the setting '{key}' is gone upstream "
                                f"— drop it from {SETTINGS_FILE.name}")
        for key in retyped:
            if key in managed.get(ext.schema, {}):
                blocking.append(f"{ext.name}: the setting '{key}' changed type "
                                f"({old_keys[key]} -> {new_keys[key]})")
        if new_path and ext.schema and new_path.strip("/") != ext.schema:
            blocking.append(f"{ext.name}: the schema moved "
                            f"('{ext.schema}' -> '{new_path}')")

        # Every managed key must still exist with the type we write.
        for key, expected in managed.get(ext.schema, {}).items():
            actual = new_keys.get(key)
            if actual is None:
                blocking.append(f"{ext.name}: the setting '{key}' is not in the new "
                                f"schema — drop it from {SETTINGS_FILE.name}")
            elif actual != expected:
                blocking.append(f"{ext.name}: the setting '{key}' is now '{actual}' "
                                f"but we write '{expected}'")

        if old_meta.get("session-modes") != new_meta.get("session-modes"):
            notes.append(f"{ext.name}: session modes changed "
                         f"({old_meta.get('session-modes')} -> "
                         f"{new_meta.get('session-modes')})")

        updates[ext.uuid] = {
            "version": str(new_meta.get("version", best_version)),
            "versionTag": best_tag,
            "sha256": sha256_sri(new_data),
        }

        detail = []
        if added:
            detail.append(f"+{len(added)} key(s)")
        if removed:
            detail.append(f"-{len(removed)} key(s)")
        if retyped:
            detail.append(f"~{len(retyped)} retyped")
        log(f"- {ext.name} (`{ext.uuid}`): v{ext.version} -> "
            f"v{new_meta.get('version', best_version)}"
            + (f"  [{', '.join(detail)}]" if detail else ""))

    if updates and not (args.check or args.dry_run):
        pins_path.write_text(rewrite_pins(pins_text, updates))
        log("")
        log(f"Updated {len(updates)} pin(s) in {relative(pins_path)}.")
    elif updates:
        log("")
        log(f"{len(updates)} pin(s) would be updated in {relative(pins_path)}.")

    for note in notes:
        log(f"note: {note}")
    for problem in blocking:
        log(f"BLOCKING: {problem}")

    if blocking:
        log("")
        log("Resolve the blocking issues before switching.")
        return 1
    if args.check and updates:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
