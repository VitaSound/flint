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

# --- Case 3b: --strict exits non-zero ------------------------------------
( cd "$repo_root/tests/fixtures/with_dupes" && bash "$repo_root/bin/flint" lint . --strict >/dev/null 2>&1 )
status=$?
if [ "$status" -eq 0 ]; then
    fail "flint --strict must exit non-zero with duplicates; got $status"
fi
pass "flint --strict exits non-zero with duplicates"

( cd "$repo_root/tests/fixtures/no_dupes" && bash "$repo_root/bin/flint" lint . --strict >/dev/null 2>&1 )
status=$?
if [ "$status" -ne 0 ]; then
    fail "flint --strict must exit 0 when clean; got $status"
fi
pass "flint --strict exits 0 when clean"

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

# --- Case 5: version-check is warn-only ---------------------------------
#
# In each of these fixtures the project pins flint in a way the
# installed flint doesn't fully satisfy (or uses the legacy form).
# Expected behaviour: a WARN line surfaces, the linter still finishes
# its work, exit code stays 0.

out=$(cd "$repo_root/tests/fixtures/wants_future_flint" && bash "$repo_root/bin/flint" 2>&1)
if ! grep -q "\\[WARN\\] This project requires flint ~> 99.0" <<<"$out"; then
    fail "wants_future_flint: missing WARN for ~> 99.0; got:\n$out"
fi
if ! grep -q "scanned " <<<"$out"; then
    fail "wants_future_flint: linter did not run after warning; got:\n$out"
fi
( cd "$repo_root/tests/fixtures/wants_future_flint" && bash "$repo_root/bin/flint" >/dev/null 2>&1 )
status=$?
if [ "$status" -ne 0 ]; then
    fail "wants_future_flint: exit code must stay 0 (warn-only); got $status"
fi
pass "wants_future_flint: warn-only, lint still runs (exit=0)"

out=$(cd "$repo_root/tests/fixtures/legacy_flint_dep" && bash "$repo_root/bin/flint" 2>&1)
if ! grep -q "uses pre-0.2 form" <<<"$out"; then
    fail "legacy_flint_dep: missing legacy-form WARN; got:\n$out"
fi
if ! grep -q "key-value flint ~>" <<<"$out"; then
    fail "legacy_flint_dep: WARN didn't show migration target; got:\n$out"
fi
if ! grep -q "scanned " <<<"$out"; then
    fail "legacy_flint_dep: linter did not run after warning; got:\n$out"
fi
pass "legacy_flint_dep: warn-only with migration hint, lint still runs"

out=$(cd "$repo_root/tests/fixtures/invalid_flint_req" && bash "$repo_root/bin/flint" 2>&1)
if ! grep -q "Invalid flint version requirement" <<<"$out"; then
    fail "invalid_flint_req: missing parse-error WARN; got:\n$out"
fi
if ! grep -q "scanned " <<<"$out"; then
    fail "invalid_flint_req: linter did not run after warning; got:\n$out"
fi
pass "invalid_flint_req: warn-only with parse error, lint still runs"

# --- Case 6: unit tests for the req parser / matcher --------------------
out=$(FLINT_HOME="$repo_root" gforth "$repo_root/tests/flint_version_check_test.4th" 2>&1)
status=$?
if [ "$status" -ne 0 ] || ! grep -q "flint_version_check_test ok" <<<"$out"; then
    fail "flint_version_check_test unit tests failed (status=$status):\n$out"
fi
pass "flint_version_check_test: wiring smoke-test ok (fsemver carries the 71-case truth-table)"

echo
echo "flint_integration_test ok"
