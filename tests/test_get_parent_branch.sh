#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${GET_PARENT_BRANCH_SCRIPT:-$SCRIPT_DIR/../skills/branch-walkthrough/scripts/get-parent-branch.sh}"

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

assert() {
    local desc="$1"; shift
    if "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
}

assert_not() {
    local desc="$1"; shift
    if ! "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
}

# ── Setup ─────────────────────────────────────────────────────────────────────
# Fixture: bare `origin` + clone. origin/main = C2.
#   feat-a branches off C1, feat-b branches off C2 and is checked out.
# `gh` is stubbed with a PATH shim that reports `main` as the PR base and logs its args.

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

export HOME="$TEST_DIR/home"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null
export GH_LOG="$TEST_DIR/gh.log"
mkdir -p "$HOME"

BIN="$TEST_DIR/bin"
ORIGIN="$TEST_DIR/origin.git"
CLONE="$TEST_DIR/clone"
mkdir -p "$BIN"

cat > "$BIN/gh" <<'SHIM'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$*" in
  "pr view"*"--json baseRefName"*) echo main ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
SHIM
chmod +x "$BIN/gh"

commit() {
    echo "$1" > "$1.txt"
    git add "$1.txt"
    git commit --quiet -m "$1"
}

build_fixture() {
    git init --quiet --bare -b main "$ORIGIN"
    git clone --quiet "$ORIGIN" "$CLONE" 2>/dev/null
    cd "$CLONE"
    git config user.name "Test"
    git config user.email "test@example.com"
    git checkout --quiet -b main
    commit C1
    git push --quiet -u origin main
    git checkout --quiet -b feat-a
    commit A1
    git checkout --quiet main
    commit C2
    git push --quiet origin main
    git checkout --quiet -b feat-b
    commit B1
    cd "$TEST_DIR"
}

run_script() {
    : > "$GH_LOG"
    (cd "$CLONE" && PATH="$BIN:$PATH" bash "$SCRIPT" "$@") > "$TEST_DIR/stdout" 2> "$TEST_DIR/stderr" || true
    STDOUT="$(cat "$TEST_DIR/stdout")"
}

sha_of() { git -C "$CLONE" rev-parse "$1"; }

stdout_is() { [ "$STDOUT" = "$1" ]; }
gh_was_called_with() { grep -qx "$1" "$GH_LOG"; }

build_fixture

# ── Argument: user-specified branch ───────────────────────────────────────────

run_script feat-a
assert "branch argument selects merge-base of that branch with origin/main" stdout_is "$(sha_of main~1)"
assert "branch argument is passed to gh pr view" gh_was_called_with "pr view feat-a --json baseRefName --jq .baseRefName"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
