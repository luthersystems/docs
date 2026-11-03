#!/usr/bin/env bash
# Fail when a pull request edits a page that is generated from
# docs.luthersystems.com, unless the PR is the sync PR itself.
#
#   site-sync-guard.sh <base-ref> <head-branch> [<head-repo>]
#
# Why: the pages listed in .site-sync/manifest.json are regenerated from
# luthersystems/frontpage-docs on every merge there. A hand edit here would
# be overwritten by the next sync without anyone noticing, so it belongs in
# frontpage-docs src/content. Pages not in the manifest (READMEs, onboarding,
# FAQ, glossary) are this repo's own and may be edited here.
set -euo pipefail

base=${1:?usage: site-sync-guard.sh <base-ref> <head-branch>}
head_branch=${2:?usage: site-sync-guard.sh <base-ref> <head-branch> [<head-repo>]}
head_repo=${3:-${GITHUB_REPOSITORY:-}}
manifest=.site-sync/manifest.json

# Only this repo's own site-sync branch is exempt: a fork can name a branch
# site-sync too, and only people with write access here can push this one.
if [[ "$head_branch" == site-sync && "$head_repo" == "${GITHUB_REPOSITORY:-$head_repo}" ]]; then
  echo "The sync PR may change generated pages."
  exit 0
fi

# Read the manifest as the base branch has it, so a PR cannot drop a page
# from the list and edit it in the same change.
# A missing manifest means nothing is generated yet. A manifest that does
# not parse fails the check, so a broken file never lets every edit through.
if ! git cat-file -e "$base:$manifest" 2>/dev/null; then
  echo "No $manifest on $base; nothing is generated yet."
  exit 0
fi
if ! listed=$(git show "$base:$manifest" | jq -er '.pages | keys[]'); then
  echo "::error file=$manifest::$manifest on $base does not parse."
  exit 1
fi
listed+=$'\n'"$manifest"

# --no-renames lists both sides of a rename, so moving a generated page
# away counts as editing it.
bad=0
while IFS= read -r file; do
  if grep -qxF -- "$file" <<<"$listed"; then
    echo "::error file=$file::$file is generated from docs.luthersystems.com. Edit it in luthersystems/frontpage-docs src/content; the next sync brings the change here."
    bad=1
  fi
done < <(git diff --name-only --no-renames "$base"...HEAD)
exit "$bad"
