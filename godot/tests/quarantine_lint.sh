#!/usr/bin/env bash
# [S16.2-006] Quarantine registry drift lint.
# Fails if a TestUtil.skip_with_reason("test_name", ...) call exists in
# godot/tests/ without a matching test_name entry in quarantines.json,
# or vice-versa. Keeps the JSON registry in lockstep with source.
#
# Hard cap (Gizmo invariant): keep this under ~50 lines. If lint logic
# starts parsing GDScript ASTs or growing schema fields, stop and surface.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_DIR="$REPO_ROOT/godot/tests"
REGISTRY="$TESTS_DIR/quarantines.json"

if [ ! -f "$REGISTRY" ]; then
  echo "ERROR: registry missing at $REGISTRY" >&2
  exit 1
fi

# Extract test_name from each TestUtil.skip_with_reason("name", ...) call.
# Source-of-truth: grep first arg as a quoted string. Excludes test_util.gd
# (defines the helper; its docstring contains the call form in prose).
SOURCE_NAMES=$(grep -hE 'TestUtil\.skip_with_reason\(\s*"' "$TESTS_DIR"/test_*.gd 2>/dev/null \
  | sed -E 's/.*TestUtil\.skip_with_reason\(\s*"([^"]+)".*/\1/' \
  | sort -u)

# Extract test_name from registry entries.
REGISTRY_NAMES=$(python3 -c "import json; print('\n'.join(sorted(set(e['test_name'] for e in json.load(open('$REGISTRY'))))))")

MISSING_IN_REGISTRY=$(comm -23 <(echo "$SOURCE_NAMES") <(echo "$REGISTRY_NAMES") || true)
MISSING_IN_SOURCE=$(comm -13 <(echo "$SOURCE_NAMES") <(echo "$REGISTRY_NAMES") || true)

EXIT=0
if [ -n "$MISSING_IN_REGISTRY" ]; then
  echo "DRIFT: skip_with_reason() calls present in source but missing from quarantines.json:" >&2
  echo "$MISSING_IN_REGISTRY" | sed 's/^/  - /' >&2
  EXIT=1
fi
if [ -n "$MISSING_IN_SOURCE" ]; then
  echo "DRIFT: quarantines.json entries with no matching skip_with_reason() call:" >&2
  echo "$MISSING_IN_SOURCE" | sed 's/^/  - /' >&2
  EXIT=1
fi

if [ $EXIT -eq 0 ]; then
  echo "quarantine_lint: OK ($(echo "$REGISTRY_NAMES" | wc -l | tr -d ' ') entries in sync)"
fi
exit $EXIT
