#!/usr/bin/env bash
# Open, update or close the sync PR from site-sync. Run by
# .github/workflows/site-sync-pr.yml on each push to site-sync.
set -euo pipefail

open=$(gh pr list --head site-sync --base main --state open --json number --jq '.[0].number // empty')

# frontpage-docs resets site-sync to main when main already matches the site
# (the site reverted a change before its sync PR merged). Then the open PR
# has nothing left to merge, so close it rather than leave an empty PR.
ahead=$(gh api "repos/$GITHUB_REPOSITORY/compare/main...site-sync" --jq .ahead_by)
if [[ "$ahead" == 0 ]]; then
  if [[ -n "$open" ]]; then
    gh pr close "$open" --comment "main already matches docs.luthersystems.com; nothing to sync."
  fi
  echo "site-sync has no commits beyond main."
  exit 0
fi

# The sync commit's message names the frontpage-docs commit it came from.
body=$(cat <<EOT
$(git log -1 --format=%b)

Each changed page is a copy of a page on [docs.luthersystems.com](https://docs.luthersystems.com), converted by \`scripts/docs-repo-sync\` in luthersystems/frontpage-docs. To change the text, edit it there. Review this PR for the conversion only.

A new site page shows up here only after it is added to \`scripts/docs-repo-sync/map.json\` in frontpage-docs. Add it to an index page here (README.md or common-operation-script/README.md) in a separate PR.
EOT
)
if [[ -n "$open" ]]; then
  # The push replaced the commit; refresh the body so it names the new source commit.
  gh pr edit "$open" --body "$body"
  echo "Updated sync PR #$open."
  exit 0
fi
gh pr create --base main --head site-sync --title "Sync the guides from docs.luthersystems.com" --body "$body"
