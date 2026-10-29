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
NO_ORIGIN="$TEST_DIR/no-origin"
mkdir -p "$BIN"

GH_FAILS_BIN="$TEST_DIR/bin-gh-fails"
NO_GH_BIN="$TEST_DIR/bin-no-gh"
DEV_ORIGIN="$TEST_DIR/dev-origin.git"
DEV_CLONE="$TEST_DIR/dev-clone"
mkdir -p "$GH_FAILS_BIN" "$NO_GH_BIN"

cat > "$BIN/gh" <<'SHIM'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$*" in
  "pr view"*"--json baseRefName"*) echo main ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
SHIM
chmod +x "$BIN/gh"

printf '#!/usr/bin/env bash\nexit 1\n' > "$GH_FAILS_BIN/gh"
chmod +x "$GH_FAILS_BIN/gh"

for tool in git sed bash; do ln -s "$(command -v "$tool")" "$NO_GH_BIN/$tool"; done

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

run_script_in() {
    local dir="$1"; shift
    : > "$GH_LOG"
    STATUS=0
    (cd "$dir" && PATH="${RUN_PATH:-$BIN:$PATH}" bash "$SCRIPT" "$@") > "$TEST_DIR/stdout" 2> "$TEST_DIR/stderr" || STATUS=$?
    STDOUT="$(cat "$TEST_DIR/stdout")"
    STDERR="$(cat "$TEST_DIR/stderr")"
}

run_script() { run_script_in "$CLONE" "$@"; }

build_no_origin_fixture() {
    git init --quiet -b main "$NO_ORIGIN"
    cd "$NO_ORIGIN"
    git config user.name "Test"
    git config user.email "test@example.com"
    commit C1
    git checkout --quiet -b feat-x
    commit X1
    cd "$TEST_DIR"
}

build_develop_fixture() {
    git init --quiet --bare -b main "$DEV_ORIGIN"
    git clone --quiet "$DEV_ORIGIN" "$DEV_CLONE" 2>/dev/null
    cd "$DEV_CLONE"
    git config user.name "Test"
    git config user.email "test@example.com"
    git checkout --quiet -b main
    commit C1
    git checkout --quiet -b develop
    commit D1
    git checkout --quiet main
    commit C2
    git push --quiet origin main develop
    git checkout --quiet -b feat-d develop
    commit F1
    cd "$TEST_DIR"
}

run_script_with_path() {
    RUN_PATH="$1"
    run_script_in "$DEV_CLONE"
    unset RUN_PATH
}

sha_of() { git -C "$CLONE" rev-parse "$1"; }

stdout_is() { [ "$STDOUT" = "$1" ]; }
run_was() { [ "$STATUS|$STDOUT|$STDERR" = "$1" ]; }
gh_was_called_with() { grep -qx "$1" "$GH_LOG"; }
status_is() { [ "$STATUS" -eq "$1" ]; }
stderr_contains() { printf '%s' "$STDERR" | grep -qF "$1"; }
stdout_is_empty() { [ -z "$STDOUT" ]; }
run_succeeded_with() { [ "$STATUS|$STDOUT" = "0|$1" ]; }

build_fixture
build_no_origin_fixture
build_develop_fixture

# ── Argument: user-specified branch ───────────────────────────────────────────

run_script feat-a
assert "branch argument selects merge-base of that branch with origin/main" stdout_is "$(sha_of main~1)"
assert "branch argument is passed to gh pr view" gh_was_called_with "pr view feat-a --json baseRefName --jq .baseRefName"

# ── Default: no argument ──────────────────────────────────────────────────────

run_script
assert "no argument exits 0 with only the merge-base SHA on stdout and nothing on stderr" run_was "0|$(sha_of main)|"
assert "no argument lets gh resolve the current branch's PR" gh_was_called_with "pr view --json baseRefName --jq .baseRefName"

# ── No origin remote ──────────────────────────────────────────────────────────

run_script_in "$NO_ORIGIN"
assert "no origin remote exits 2" status_is 2
assert "no origin remote explains the problem on stderr" stderr_contains "no origin remote"
assert "no origin remote leaves stdout empty" stdout_is_empty

# ── On the base branch ───────────────────────────────────────────────────────

git -C "$CLONE" checkout --quiet main
run_script
assert "on the base branch exits 3" status_is 3
assert "on the base branch says there is nothing to diff on stderr" stderr_contains "nothing to diff"
assert "on the base branch leaves stdout empty" stdout_is_empty

# ── Unreachable origin ───────────────────────────────────────────────────────

git -C "$CLONE" checkout --quiet feat-b
EXPECTED_FROM_LOCAL_REFS="$(sha_of main)"
git -C "$CLONE" remote set-url origin "$TEST_DIR/does-not-exist.git"
run_script
assert "unreachable origin exits 0 with the merge-base from local refs on stdout" run_succeeded_with "$EXPECTED_FROM_LOCAL_REFS"
assert "unreachable origin warns that the fetch failed on stderr" stderr_contains "fetch failed"

# ── gh absent or unauthenticated ─────────────────────────────────────────────

DEVELOP_BASE="$(git -C "$DEV_CLONE" rev-parse origin/develop)"
MAIN_BASE="$(git -C "$DEV_CLONE" rev-parse origin/main~1)"

git -C "$DEV_CLONE" remote set-head origin develop >/dev/null
run_script_with_path "$NO_GH_BIN"
assert "gh absent uses origin/HEAD as the base" run_succeeded_with "$DEVELOP_BASE"
run_script_with_path "$GH_FAILS_BIN:$NO_GH_BIN"
assert "gh failing uses origin/HEAD as the base" run_succeeded_with "$DEVELOP_BASE"

git -C "$DEV_CLONE" remote set-head origin -d >/dev/null
run_script_with_path "$NO_GH_BIN"
assert "gh absent and origin/HEAD unset falls back to main" run_succeeded_with "$MAIN_BASE"
run_script_with_path "$GH_FAILS_BIN:$NO_GH_BIN"
assert "gh failing and origin/HEAD unset falls back to main" run_succeeded_with "$MAIN_BASE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
