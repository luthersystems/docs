#!/usr/bin/env bash
# Fail when a pull request edits a page that is generated from
# docs.luthersystems.com, unless the PR is the sync PR itself.
#
#   site-sync-guard.sh <base-ref> <head-branch>
#
# Why: the pages listed in .site-sync/manifest.json are regenerated from
# luthersystems/frontpage-docs on every merge there. A hand edit here would
# be overwritten by the next sync without anyone noticing, so it belongs in
# frontpage-docs src/content. Pages not in the manifest (READMEs, onboarding,
# FAQ, glossary) are this repo's own and may be edited here.
set -euo pipefail

base=${1:?usage: site-sync-guard.sh <base-ref> <head-branch>}
head_branch=${2:?usage: site-sync-guard.sh <base-ref> <head-branch>}
manifest=.site-sync/manifest.json

if [[ "$head_branch" == site-sync ]]; then
  echo "The sync PR may change generated pages."
  exit 0
fi

# Read the manifest as the base branch has it, so a PR cannot drop a page
# from the list and edit it in the same change.
if ! listed=$(git show "$base:$manifest" 2>/dev/null | jq -r '.pages | keys[]'); then
  echo "No $manifest on $base; nothing is generated yet."
  exit 0
fi
listed+=$'\n'"$manifest"

bad=0
while IFS= read -r file; do
  if grep -qxF -- "$file" <<<"$listed"; then
    echo "::error file=$file::$file is generated from docs.luthersystems.com. Edit it in luthersystems/frontpage-docs src/content; the next sync brings the change here."
    bad=1
  fi
done < <(git diff --name-only "$base"...HEAD)
exit "$bad"
