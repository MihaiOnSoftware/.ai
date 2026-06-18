#!/bin/bash
# Get the likely parent branch for the current branch using git refs only.

set -euo pipefail

branch="${1:-$(git branch --show-current)}"

if [ -z "$branch" ]; then
  echo "Unable to determine the current branch; pass a branch name explicitly." >&2
  exit 1
fi

target_commit=$(git rev-parse --verify "${branch}^{commit}")

ref_to_branch_name() {
  local ref="$1"

  case "$ref" in
    refs/heads/*)
      echo "${ref#refs/heads/}"
      ;;
    refs/remotes/*)
      echo "${ref#refs/remotes/}"
      ;;
    *)
      echo "$ref"
      ;;
  esac
}

is_target_ref() {
  local candidate="$1"
  local branch_name="$branch"

  branch_name="${branch_name#refs/heads/}"
  branch_name="${branch_name#refs/remotes/}"
  local branch_leaf="${branch_name#origin/}"

  [ "$candidate" = "$branch_name" ] || \
    [ "$candidate" = "$branch_leaf" ] || \
    [ "$candidate" = "origin/$branch_name" ] || \
    [ "$candidate" = "origin/$branch_leaf" ]
}

default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)
default_branch="${default_branch:-main}"

fallback_branch="$default_branch"
if git show-ref --verify --quiet "refs/heads/$default_branch"; then
  fallback_branch="$default_branch"
elif git show-ref --verify --quiet "refs/remotes/origin/$default_branch"; then
  fallback_branch="origin/$default_branch"
fi

branch_name="$branch"
branch_name="${branch_name#refs/heads/}"
branch_name="${branch_name#refs/remotes/}"
if [ "${branch_name#origin/}" = "$default_branch" ]; then
  echo "$fallback_branch"
  exit 0
fi

best_branch=""
best_commit=""

while IFS= read -r ref; do
  candidate=$(ref_to_branch_name "$ref")

  if [ "$candidate" = "origin/HEAD" ] || is_target_ref "$candidate"; then
    continue
  fi

  if ! git merge-base --is-ancestor "$ref" "$target_commit" 2>/dev/null; then
    continue
  fi

  candidate_commit=$(git rev-parse --verify "${ref}^{commit}")

  if [ -z "$best_commit" ] || git merge-base --is-ancestor "$best_commit" "$candidate_commit"; then
    best_branch="$candidate"
    best_commit="$candidate_commit"
  fi
done < <(git for-each-ref --format='%(refname)' refs/heads refs/remotes)

echo "${best_branch:-$fallback_branch}"
