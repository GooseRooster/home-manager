#!/usr/bin/env bash
# Mirror the upstream LazyVim starter into vendor/lazyvim-starter.
#
# Locally runnable:  bash scripts/update-starter.sh
# Needs: git, standard coreutils. No auth (public repo).
#
# The vendor dir is a pure upstream mirror — merge-time decisions (layering
# the files/nvim/lua overlay, dropping the inert example plugin) happen in
# modules/nvim.nix, so this script can never lose a tweak.
#
# CI runs this weekly (.github/workflows/update-starter.yml), builds the home
# config as a gate, and opens a PR when anything changed.
set -euo pipefail

UPSTREAM="https://github.com/LazyVim/starter"
DEST="vendor/lazyvim-starter"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git clone --depth 1 "$UPSTREAM" "$tmp/starter"
new_rev=$(git -C "$tmp/starter" rev-parse HEAD)
rm -rf "$tmp/starter/.git"

if [ -d "$DEST" ] && diff -r "$tmp/starter" "$DEST" >/dev/null 2>&1; then
  echo "LazyVim starter is up to date."
  exit 0
fi

rm -rf "$DEST"
cp -r "$tmp/starter" "$DEST"

echo "- LazyVim starter: synced to [\`${new_rev:0:7}\`](https://github.com/LazyVim/starter/commit/${new_rev})"
echo
echo "Build gate: nix build .#homeConfigurations.wsl.activationPackage"
