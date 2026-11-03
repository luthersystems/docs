#!/usr/bin/env bash
# Open the sync PR from site-sync, or leave the open one in place (the push
# that ran this already updated it). Run by .github/workflows/site-sync-pr.yml.
set -euo pipefail

open=$(gh pr list --head site-sync --base main --state open --json number --jq '.[0].number // empty')
if [[ -n "$open" ]]; then
  echo "Sync PR #$open is open; the push updated it."
  exit 0
fi

# The sync commit's message names the frontpage-docs commit it came from.
body=$(cat <<EOT
$(git log -1 --format=%b)

Each changed page is a copy of a page on [docs.luthersystems.com](https://docs.luthersystems.com), converted by \`scripts/docs-repo-sync\` in luthersystems/frontpage-docs. To change the text, edit it there. Review this PR for the conversion only.

A new site page shows up here only after it is added to \`scripts/docs-repo-sync/map.json\` in frontpage-docs. Add it to an index page here (README.md or common-operation-script/README.md) in a separate PR.
EOT
)
gh pr create --base main --head site-sync --title "Sync the guides from docs.luthersystems.com" --body "$body"
