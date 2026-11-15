#!/usr/bin/env bash
# Bring Google's latest Modern Web Guidance release into this fork.
#
# This fork has two branches:
#   main         an exact copy of GoogleChrome/modern-web-guidance
#   claude-code  main plus our changes, which Claude Code installs:
#                  - the chrome-extensions skill is removed
#                  - hooks/hooks.json turns off the tool's usage reporting to
#                    Google for commands Claude runs (Claude Code's own
#                    telemetry is not touched)
#
# Run from Git Bash:  ./scripts/update-from-upstream.sh
set -euo pipefail
cd "$(dirname "$0")/.."

git remote get-url upstream >/dev/null 2>&1 ||
  git remote add upstream https://github.com/GoogleChrome/modern-web-guidance

git fetch --quiet upstream main
git fetch --quiet origin

# Keep main an exact copy of Google's main.
git push --quiet origin upstream/main:refs/heads/main

git checkout --quiet claude-code
git merge --quiet --ff-only origin/claude-code

if git merge-base --is-ancestor upstream/main HEAD; then
  echo "Already up to date with Google's $(git log -1 --format=%s upstream/main)."
  exit 0
fi

if ! git merge --quiet --no-edit upstream/main; then
  # Google changed files we removed: keep them removed.
  git rm -r --quiet --ignore-unmatch skills/chrome-extensions
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "The merge has other conflicts. Fix them by hand, then commit and push." >&2
    exit 1
  fi
  git commit --quiet --no-edit
fi

git push --quiet origin claude-code
echo "Updated to Google's $(git log -1 --format=%s upstream/main)."
