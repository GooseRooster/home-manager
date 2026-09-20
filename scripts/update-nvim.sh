#!/usr/bin/env bash
# Mirror the upstream MiniMax reference config into vendor/nvim.
#
# Locally runnable:  bash scripts/update-nvim.sh
# Needs: git, standard coreutils. No auth (public repo).
#
# There is no "MiniMax" plugin to `import` — the nvim-mini/MiniMax repo's
# configs/nvim-<version>/ directory *is* the entire config, meant to be
# copied once and diverged from. This script only tracks upstream's
# reference config so you can review changes; it does not regenerate
# anything automatically (see modules/nvim.nix for how the copy here gets
# used).
#
# VERSION below must match the nvim-<version> directory that corresponds to
# the Neovim release actually in use (see pkgs/base.nix). Bump it deliberately
# when upgrading Neovim, not automatically.
set -euo pipefail

UPSTREAM="https://github.com/nvim-mini/MiniMax"
VERSION="nvim-0.12"
DEST="vendor/nvim"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git clone --depth 1 --filter=blob:none "$UPSTREAM" "$tmp/minimax"
new_rev=$(git -C "$tmp/minimax" rev-parse HEAD)

src="$tmp/minimax/configs/$VERSION"
if [ ! -d "$src" ]; then
  echo "error: '$src' does not exist upstream (VERSION=$VERSION stale?)" >&2
  exit 1
fi

if [ -d "$DEST" ] && diff -r "$src" "$DEST" >/dev/null 2>&1; then
  echo "MiniMax ($VERSION) is up to date."
  exit 0
fi

rm -rf "$DEST"
cp -r "$src" "$DEST"

echo "- MiniMax ($VERSION): synced to [\`${new_rev:0:7}\`](https://github.com/nvim-mini/MiniMax/commit/${new_rev})"
echo
echo "Review vendor/nvim's diff, then re-apply any files/nvim overlay"
echo "changes needed on top (see modules/nvim.nix)."
echo
echo "Build gate: nix build .#homeConfigurations.wsl.activationPackage"
