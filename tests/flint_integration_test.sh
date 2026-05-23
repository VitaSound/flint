#!/usr/bin/env bash
# tests/flint_integration_test.sh
#
# Drives the flint CLI against the fixture projects under
# tests/fixtures/ and asserts on the rendered output.

set -u

repo_root=$(cd "$(dirname "$0")/.." && pwd)
export FLINT_HOME="$repo_root"

fail() { echo "[FAIL] $*" >&2; exit 1; }
pass() { echo "[OK]   $*"; }

# --- Case 1: fixture without duplicates ---------------------------------
out=$(cd "$repo_root/tests/fixtures/no_dupes" && bash "$repo_root/bin/flint" 2>&1)
if ! grep -q "0 duplicate group" <<<"$out"; then
    fail "no_dupes: expected '0 duplicate group', got:\n$out"
fi
if grep -q "\[WARN\]" <<<"$out"; then
    fail "no_dupes: unexpected WARN line in output:\n$out"
fi
pass "no_dupes fixture: 0 warnings"

# --- Case 2: fixture with intentional duplicates -------------------------
out=$(cd "$repo_root/tests/fixtures/with_dupes" && bash "$repo_root/bin/flint" 2>&1)

for name in shared-thing my-var; do
    if ! grep -q "duplicate word \`${name}\`" <<<"$out"; then
        fail "with_dupes: expected to warn about ${name}; got:\n$out"
    fi
done
pass "with_dupes fixture: warns on shared-thing and my-var"

# Must NOT warn about singletons or comment-position '('
for name in only-in-a only-in-b also-from-a noisy-string '\('; do
    if grep -qF "duplicate word \`${name}\`" <<<"$out"; then
        fail "with_dupes: false positive for singleton '${name}'; got:\n$out"
    fi
done
pass "with_dupes fixture: no false positives on singletons or paren-comment names"

# Final count line: should report 2 groups.
if ! grep -q "2 duplicate group" <<<"$out"; then
    fail "with_dupes: expected '2 duplicate group', got:\n$out"
fi
pass "with_dupes fixture: reports 2 duplicate group(s)"

# --- Case 3: exit code is always 0 (warn, not error) ---------------------
( cd "$repo_root/tests/fixtures/with_dupes" && bash "$repo_root/bin/flint" >/dev/null 2>&1 )
status=$?
if [ "$status" -ne 0 ]; then
    fail "flint must exit 0 even with warnings; got $status"
fi
pass "flint exit code is 0 even with duplicates (warn, not error)"

# --- Case 4: flint version / help work -----------------------------------
out=$(bash "$repo_root/bin/flint" version 2>&1)
if ! grep -q "(flint)" <<<"$out"; then
    fail "flint version: expected '(flint)' marker; got:\n$out"
fi
pass "flint version works"

out=$(bash "$repo_root/bin/flint" help 2>&1)
if ! grep -q "Commands:" <<<"$out"; then
    fail "flint help: expected 'Commands:' header; got:\n$out"
fi
pass "flint help works"

echo
echo "flint_integration_test ok"
