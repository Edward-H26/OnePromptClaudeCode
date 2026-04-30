#!/usr/bin/env bash
set -euo pipefail

# Safely merge .claude/settings.local.example.json into .claude/settings.local.json.
# Rules:
#   - User's existing values WIN on conflict (example is fill-in only)
#   - New top-level blocks (like mcpServers) get added if not present
#   - Always writes a timestamped backup before replacing
#   - Always shows the diff before applying

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE="${REPO_ROOT}/.claude/settings.local.example.json"
ACTIVE="${REPO_ROOT}/.claude/settings.local.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [[ ! -f "${EXAMPLE}" ]]; then
  echo "error: ${EXAMPLE} does not exist" >&2
  exit 1
fi

if [[ ! -f "${ACTIVE}" ]]; then
  echo "note: ${ACTIVE} does not exist yet. Copying example verbatim."
  cp "${EXAMPLE}" "${ACTIVE}"
  echo "created: ${ACTIVE}"
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup="${ACTIVE}.bak.${timestamp}"
cp "${ACTIVE}" "${backup}"
echo "backup: ${backup}"

# jq -s '.[0] * .[1]' does a RECURSIVE deep merge where the right file wins on conflict.
# We pass example first, active second, so existing user values override example defaults.
merged="$(jq -s '.[0] * .[1]' "${EXAMPLE}" "${ACTIVE}")"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
printf "%s\n" "${merged}" > "${tmp}"

if [[ ! -s "${tmp}" ]]; then
  echo "error: merged output is empty (likely jq failure). aborting." >&2
  exit 1
fi

echo ""
echo "=== diff (active -> merged) ==="
diff -u "${ACTIVE}" "${tmp}" || true
echo "=== end diff ==="
echo ""

read -r -p "Apply this merge? (y/N) " reply
if [[ "${reply}" =~ ^[Yy]$ ]]; then
  mv "${tmp}" "${ACTIVE}"
  trap - EXIT
  echo "merged: ${ACTIVE}"
  echo "rollback with: mv ${backup} ${ACTIVE}"
else
  echo "aborted. no changes made."
fi
