#!/usr/bin/env bash
# Fork-only: merge upstream (conorbronsdon/avoid-ai-writing) into this fork's
# main, regenerate the bundled plugin copies, and run the same checks CI runs.
# See FORK.md for why the fork exists.
#
# Commits locally but never pushes. Review, then push and reinstall by hand:
#   git push origin main
#   claude plugin uninstall avoid-ai-writing@conorbronsdon-skills
#   claude plugin install avoid-ai-writing@conorbronsdon-skills
# Reinstall, not update: upstream often keeps the same version number, and
# the plugin cache is keyed by version, so `claude plugin update` reports
# "already at latest" and leaves stale files in place.
#
# TMPDIR defaults to a directory under $HOME because some hosts mount /tmp
# noexec, which breaks rewrite-eval-opencode.test.js (it execs a fake binary).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ "$(git branch --show-current)" != "main" ]; then
  echo "fork-sync: switch to main first" >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "fork-sync: working tree is dirty; commit or stash first" >&2
  exit 1
fi

git fetch upstream
behind="$(git rev-list --count HEAD..upstream/main)"
if [ "$behind" -eq 0 ]; then
  echo "fork-sync: already up to date with upstream/main"
  exit 0
fi
echo "fork-sync: merging $behind upstream commit(s)"
git merge --no-edit upstream/main

bash scripts/sync-plugin-skill.sh
bash scripts/sync-cursor-rules.sh

python3 skills/avoid-ai-writing-router/scripts/validate_connections.py . > /dev/null
python3 skills/avoid-ai-writing-router/scripts/validate_connections.py plugins/avoid-ai-writing > /dev/null

tmp_dir="${FORK_SYNC_TMPDIR:-$HOME/.cache/avoid-ai-writing-fork-sync}"
mkdir -p "$tmp_dir"
TMPDIR="$tmp_dir" npm test
rm -rf "$tmp_dir"

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "Regenerate bundled plugin skills after upstream sync"
fi

echo
echo "fork-sync: done. Commits ahead of upstream/main:"
git --no-pager log --oneline upstream/main..HEAD
echo
echo "Next: git push origin main, then reinstall the plugin (see header)."
