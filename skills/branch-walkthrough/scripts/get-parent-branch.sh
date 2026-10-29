#!/bin/bash
# Returns the merge-base SHA between HEAD and the PR base branch (or repo default).
set -euo pipefail

target="${1:-HEAD}"

git remote get-url origin >/dev/null 2>&1 || {
  echo "get-parent-branch: no origin remote; ask the user which branch to compare against" >&2
  exit 2
}

base=$(gh pr view ${1:+"$1"} --json baseRefName --jq '.baseRefName' 2>/dev/null) || \
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || \
  base="main"

git fetch origin "$base" --quiet
git merge-base "$target" "origin/$base"
