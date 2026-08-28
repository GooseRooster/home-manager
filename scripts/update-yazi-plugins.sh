#!/usr/bin/env bash
# Bump the pinned rev/hash of every yazi plugin in modules/yazi.nix to the
# latest commit on each repo's default branch.
#
# Locally runnable:  bash scripts/update-yazi-plugins.sh
# Needs: git, nix, standard coreutils. No auth (public repos).
#
# Behavior:
#   - discovers every `fetchPlugin { owner = ..; repo = ..; rev = ..; hash = .. }`
#     pin (including the yazi-rs/plugins monorepo used by full-border/mount)
#   - fetches each repo's HEAD rev via `git ls-remote`
#   - on change, computes the new hash via `nix store prefetch-file --unpack`
#     (SRI, matching fetchFromGitHub) and rewrites the pin in place
#   - prints a markdown changelog; exits 1 on any fetch failure
set -euo pipefail

FILE="${1:-modules/yazi.nix}"

# All fetchPlugin pins, whitespace-normalized so the multiline pluginsRepo
# entry and the inline ones parse the same way.
pins=$(tr '\n' ' ' < "$FILE" \
  | grep -oE 'owner = "[^"]+";[[:space:]]*repo = "[^"]+";[[:space:]]*rev = "[^"]+";[[:space:]]*hash = "[^"]+";')

if [ -z "$pins" ]; then
  echo "error: no fetchPlugin pins found in $FILE" >&2
  exit 1
fi

updated=0
while IFS= read -r pin; do
  owner=$(printf '%s' "$pin" | sed -nE 's/.*owner = "([^"]+)".*/\1/p')
  repo=$(printf '%s' "$pin" | sed -nE 's/.*repo = "([^"]+)".*/\1/p')
  rev=$(printf '%s' "$pin" | sed -nE 's/.*rev = "([^"]+)".*/\1/p')
  hash=$(printf '%s' "$pin" | sed -nE 's/.*hash = "([^"]+)".*/\1/p')

  latest=$(git ls-remote "https://github.com/${owner}/${repo}" HEAD | cut -f1)
  if [ -z "$latest" ]; then
    echo "error: could not resolve HEAD for ${owner}/${repo}" >&2
    exit 1
  fi

  if [ "$latest" = "$rev" ]; then
    echo "- ${repo} (\`${owner}\`): up to date"
    continue
  fi

  new_hash=$(nix store prefetch-file --unpack --json \
    "https://github.com/${owner}/${repo}/archive/${latest}.tar.gz" \
    | tr '\n' ' ' | grep -oE '"hash": ?"[^"]+"' | cut -d'"' -f4)
  if [ -z "$new_hash" ]; then
    echo "error: could not prefetch ${owner}/${repo}@${latest}" >&2
    exit 1
  fi

  # Base64 SRI hashes contain '/', so use '|' as the sed delimiter.
  sed -i "s|${rev}|${latest}|; s|${hash}|${new_hash}|" "$FILE"
  echo "- ${repo} (\`${owner}\`): [\`$(printf '%s' "$rev" | cut -c1-7)\`](https://github.com/${owner}/${repo}/compare/${rev}...${latest}) → \`${latest}\`"
  updated=$((updated + 1))
done <<< "$pins"

echo
if [ "$updated" -eq 0 ]; then
  echo "All yazi plugins are up to date."
else
  echo "${updated} plugin pin(s) updated. Build gate: nix build .#homeConfigurations.desktop.activationPackage"
fi
